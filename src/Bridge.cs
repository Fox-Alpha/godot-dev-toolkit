using System.Net.Sockets;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;

namespace GodotLspBridge;

/// <summary>
/// stdio ↔ TCP bridge for Godot's GDScript Language Server.
/// Reads LSP messages from stdin, forwards them to Godot via TCP and vice versa.
/// </summary>
public static class Bridge
{
    private static readonly int[] DefaultPorts = [6005, 6007, 6008];
    private const int ReconnectDelayMs = 5000;
    private const int WarmupDelayMs = 1000;
    private const int ConnectionTimeoutMs = 2000;
    private const int MaxInitialRetries = 5;
    private const int MaxBufferBytes = 10 * 1024 * 1024; // 10 MB

    private static readonly string LogFile = Environment.GetEnvironmentVariable("GODOT_LSP_BRIDGE_LOG")
        ?? (OperatingSystem.IsWindows()
            ? Path.Combine(Path.GetTempPath(), "godot-lsp-bridge.log")
            : "/tmp/godot-lsp-bridge.log");

    private static readonly bool DebugEnabled =
        Environment.GetEnvironmentVariable("GODOT_LSP_BRIDGE_DEBUG") == "true";

    private static readonly string GodotHost =
        Environment.GetEnvironmentVariable("GODOT_LSP_HOST") ?? "127.0.0.1";

    private static readonly int? FixedPort = int.TryParse(
        Environment.GetEnvironmentVariable("GODOT_LSP_PORT"), out int p) ? p : null;

    // Bridge state
    private static TcpClient? _tcp;
    private static NetworkStream? _tcpStream;
    private static bool _connected;
    private static int _connectedPort;

    private static readonly List<byte[]> _pendingMessages = [];
    private static readonly List<(string Content, int Length)> _bufferedNotifications = [];

    private static bool _waitingForInitialize;
    private static string? _initializeRequestId;
    private static bool _wasInitialized;
    private static bool _isReconnecting;
    private static bool _isWarmingUp;
    private static bool _shouldRun = true;

    // Track which file URIs Godot already knows about
    private static readonly HashSet<string> _openedUris = [];

    // textDocument methods that require the file to be open first
    private static readonly HashSet<string> _requiresOpenMethods =
    [
        "textDocument/hover",
        "textDocument/definition",
        "textDocument/declaration",
        "textDocument/typeDefinition",
        "textDocument/implementation",
        "textDocument/references",
        "textDocument/documentSymbol",
        "textDocument/completion",
        "textDocument/signatureHelp",
        "textDocument/codeAction",
        "textDocument/codeLens",
        "textDocument/documentHighlight",
        "textDocument/documentLink",
        "textDocument/formatting",
        "textDocument/rangeFormatting",
        "textDocument/rename",
        "textDocument/prepareRename",
        "textDocument/foldingRange",
        "textDocument/selectionRange",
    ];

    private static readonly SemaphoreSlim _stdoutLock = new(1, 1);

    public static async Task RunAsync(string[] _)
    {
        Log("=== Godot LSP Bridge starting ===");

        Console.CancelKeyPress += (_, e) => { e.Cancel = true; Shutdown("SIGINT"); };
        AppDomain.CurrentDomain.ProcessExit += (_, _) => Shutdown("ProcessExit");

        var stdinTask = Task.Run(ReadStdinLoop);

        await ConnectWithInitialRetryAsync();

        await stdinTask;
    }

    // -------------------------------------------------------------------------
    // Stdin reader
    // -------------------------------------------------------------------------

    private static async Task ReadStdinLoop()
    {
        var stream = Console.OpenStandardInput();
        var buffer = new List<byte>(64 * 1024);

        try
        {
            var chunk = new byte[8192];
            while (_shouldRun)
            {
                int read = await stream.ReadAsync(chunk);
                if (read == 0) break;

                buffer.AddRange(chunk.AsSpan(0, read));

                if (buffer.Count > MaxBufferBytes)
                {
                    LogWarn("stdin buffer exceeded limit, clearing");
                    buffer.Clear();
                    continue;
                }

                ProcessBuffer(buffer);
            }
        }
        catch (Exception ex)
        {
            Log($"stdin error: {ex.Message}");
        }

        Shutdown("stdin-closed");
    }

    private static void ProcessBuffer(List<byte> buffer)
    {
        while (true)
        {
            int headerEnd = IndexOfHeaderDelimiter(buffer);
            if (headerEnd == -1) break;

            string header = Encoding.UTF8.GetString(buffer.ToArray(), 0, headerEnd);
            int contentLength = ParseContentLength(header);
            if (contentLength <= 0)
            {
                buffer.RemoveRange(0, headerEnd + 4);
                continue;
            }

            int bodyStart = headerEnd + 4;
            int bodyEnd = bodyStart + contentLength;

            if (buffer.Count < bodyEnd) break;

            string content = Encoding.UTF8.GetString(buffer.ToArray(), bodyStart, contentLength);
            buffer.RemoveRange(0, bodyEnd);

            DispatchToGodot(content);
        }
    }

    // -------------------------------------------------------------------------
    // Send to Godot
    // -------------------------------------------------------------------------

    private static void DispatchToGodot(string content)
    {
        string normalized = NormalizeAndTrackMessage(content);
        byte[] framed = FrameMessage(normalized);

        // Inject textDocument/didOpen before the first request for each file
        byte[]? didOpenFrame = TryBuildDidOpen(normalized);

        if (_connected && _tcpStream != null && !_isWarmingUp)
        {
            try
            {
                if (didOpenFrame != null)
                {
                    Log("Injecting textDocument/didOpen");
                    _tcpStream.Write(didOpenFrame);
                }
                _tcpStream.Write(framed);
            }
            catch (Exception ex)
            {
                Log($"TCP write error: {ex.Message}");
                if (didOpenFrame != null) BufferPending(didOpenFrame);
                BufferPending(framed);
            }
        }
        else
        {
            if (didOpenFrame != null) BufferPending(didOpenFrame);
            BufferPending(framed);
        }
    }

    /// <summary>
    /// If the message is a textDocument request that requires the file to be open,
    /// and Godot hasn't seen a didOpen for this URI yet, build and return the
    /// didOpen frame. Returns null if injection is not needed.
    /// </summary>
    private static byte[]? TryBuildDidOpen(string content)
    {
        try
        {
            var node = JsonNode.Parse(content);
            if (node is not JsonObject obj) return null;

            string? method = obj["method"]?.GetValue<string>();
            if (method == null || !_requiresOpenMethods.Contains(method)) return null;

            string? uri = obj["params"]?["textDocument"]?["uri"]?.GetValue<string>();
            if (uri == null || _openedUris.Contains(uri)) return null;

            string? filePath = FileUriToPath(uri);
            if (filePath == null || !File.Exists(filePath)) return null;

            string fileText = File.ReadAllText(filePath, Encoding.UTF8);
            string languageId = Path.GetExtension(filePath).ToLowerInvariant() switch
            {
                ".gd" => "gdscript",
                ".tscn" => "godot-scene",
                ".tres" => "godot-resource",
                _ => "gdscript"
            };

            var didOpen = new JsonObject
            {
                ["jsonrpc"] = "2.0",
                ["method"] = "textDocument/didOpen",
                ["params"] = new JsonObject
                {
                    ["textDocument"] = new JsonObject
                    {
                        ["uri"] = uri,
                        ["languageId"] = languageId,
                        ["version"] = 1,
                        ["text"] = fileText
                    }
                }
            };

            _openedUris.Add(uri);
            Log($"Auto-opening: {uri}");
            return FrameMessage(didOpen.ToJsonString());
        }
        catch (Exception ex)
        {
            Log($"TryBuildDidOpen error: {ex.Message}");
            return null;
        }
    }

    /// <summary>
    /// Converts a file:// URI to a local file system path.
    /// </summary>
    private static string? FileUriToPath(string uri)
    {
        if (!uri.StartsWith("file://")) return null;
        string path = uri[7..]; // strip "file://"

        if (OperatingSystem.IsWindows())
        {
            // file:///C:/path → C:\path
            if (path.StartsWith('/')) path = path[1..];
            return path.Replace('/', '\\');
        }

        // file:///home/user/... → /home/user/...
        return path;
    }

    private static string NormalizeAndTrackMessage(string content)
    {
        try
        {
            var node = JsonNode.Parse(content);
            if (node is JsonObject obj)
            {
                string? method = obj["method"]?.GetValue<string>();

                if (method == "initialize" && obj["id"] is JsonNode idNode)
                {
                    _waitingForInitialize = true;
                    _wasInitialized = false;
                    _initializeRequestId = idNode.ToJsonString();
                    Log($"Initialize request id: {_initializeRequestId}");
                }

                NormalizeUris(obj);
                return obj.ToJsonString();
            }
        }
        catch { /* forward as-is */ }

        return content;
    }

    // -------------------------------------------------------------------------
    // Receive from Godot (TCP reader loop)
    // -------------------------------------------------------------------------

    private static async Task ReadTcpLoopAsync()
    {
        var buffer = new List<byte>(64 * 1024);
        var chunk = new byte[8192];

        try
        {
            while (_shouldRun && _tcpStream != null)
            {
                int read = await _tcpStream.ReadAsync(chunk);
                if (read == 0) break;

                buffer.AddRange(chunk.AsSpan(0, read));

                if (buffer.Count > MaxBufferBytes)
                {
                    LogWarn("TCP receive buffer exceeded limit, clearing");
                    buffer.Clear();
                    continue;
                }

                ProcessTcpBuffer(buffer);
            }
        }
        catch (Exception ex)
        {
            Log($"TCP read error: {ex.Message}");
        }

        if (_shouldRun)
            _ = Task.Run(ScheduleReconnectAsync);
    }

    private static void ProcessTcpBuffer(List<byte> buffer)
    {
        while (true)
        {
            int headerEnd = IndexOfHeaderDelimiter(buffer);
            if (headerEnd == -1) break;

            string header = Encoding.UTF8.GetString(buffer.ToArray(), 0, headerEnd);
            int contentLength = ParseContentLength(header);
            if (contentLength <= 0)
            {
                buffer.RemoveRange(0, headerEnd + 4);
                continue;
            }

            int bodyStart = headerEnd + 4;
            int bodyEnd = bodyStart + contentLength;

            if (buffer.Count < bodyEnd) break;

            string content = Encoding.UTF8.GetString(buffer.ToArray(), bodyStart, contentLength);
            buffer.RemoveRange(0, bodyEnd);

            HandleGodotMessage(content);
        }
    }

    private static void HandleGodotMessage(string content)
    {
        Log($"tcp <- {content[..Math.Min(100, content.Length)]}");

        try
        {
            var node = JsonNode.Parse(content);
            if (node is JsonObject obj && _waitingForInitialize)
            {
                string? idJson = obj["id"]?.ToJsonString();
                bool isInitResponse = idJson == _initializeRequestId && obj["result"] != null;

                if (isInitResponse)
                {
                    WriteToStdout(content);
                    _waitingForInitialize = false;
                    _wasInitialized = true;

                    foreach (var (notifContent, _) in _bufferedNotifications)
                        WriteToStdout(notifContent);
                    _bufferedNotifications.Clear();
                    return;
                }

                // Notification (has method, no id) → buffer until after initialize response
                if (obj["method"] != null && obj["id"] == null)
                {
                    Log($"Buffering notification: {obj["method"]}");
                    _bufferedNotifications.Add((content, Encoding.UTF8.GetByteCount(content)));
                    return;
                }
            }
        }
        catch { /* forward as-is */ }

        WriteToStdout(content);
    }

    // -------------------------------------------------------------------------
    // Connection management
    // -------------------------------------------------------------------------

    private static async Task ConnectWithInitialRetryAsync()
    {
        for (int i = 0; i < MaxInitialRetries; i++)
        {
            if (await TryConnectAsync()) return;
            await Task.Delay(100);
        }

        Console.Error.WriteLine("Could not connect to Godot LSP. Waiting for Godot to become available...");
        await ScheduleReconnectAsync();
    }

    private static async Task<bool> TryConnectAsync()
    {
        int[] ports = FixedPort.HasValue ? [FixedPort.Value] : DefaultPorts;

        foreach (int port in ports)
        {
            Log($"Trying {GodotHost}:{port}...");
            try
            {
                var tcp = new TcpClient();
                var connectTask = tcp.ConnectAsync(GodotHost, port);
                if (await Task.WhenAny(connectTask, Task.Delay(ConnectionTimeoutMs)) != connectTask
                    || !tcp.Connected)
                {
                    tcp.Dispose();
                    continue;
                }

                _tcp = tcp;
                _tcpStream = tcp.GetStream();
                _connected = true;
                _connectedPort = port;

                Console.Error.WriteLine($"Godot LSP Bridge connected (port {port})");
                Log($"Connected on port {port}");

                if (_isReconnecting)
                    await HandleReconnectionAsync();
                else
                    FlushPendingMessages();

                _ = Task.Run(ReadTcpLoopAsync);
                return true;
            }
            catch (Exception ex)
            {
                Log($"Connection failed on port {port}: {ex.Message}");
            }
        }

        return false;
    }

    private static void FlushPendingMessages()
    {
        Log($"Flushing {_pendingMessages.Count} pending messages");
        foreach (var msg in _pendingMessages)
            _tcpStream?.Write(msg);
        _pendingMessages.Clear();
    }

    private static async Task HandleReconnectionAsync()
    {
        _pendingMessages.Clear();
        _isReconnecting = false;
        _isWarmingUp = true;

        Log($"Warmup {WarmupDelayMs}ms...");
        await Task.Delay(WarmupDelayMs);
        _isWarmingUp = false;

        FlushPendingMessages();

        if (_wasInitialized)
            SendNotificationToClient(
                "window/showMessage",
                """{"type":2,"message":"Godot LSP server restarted. You may need to reopen files for diagnostics."}""");
    }

    private static async Task ScheduleReconnectAsync()
    {
        _connected = false;
        _tcpStream?.Dispose();
        _tcp?.Dispose();
        _tcpStream = null;
        _tcp = null;
        _isReconnecting = true;
        _waitingForInitialize = false;
        _bufferedNotifications.Clear();
        _openedUris.Clear(); // Godot doesn't know any files after reconnect

        Console.Error.WriteLine($"Connection lost. Reconnecting in {ReconnectDelayMs / 1000}s...");

        while (_shouldRun)
        {
            await Task.Delay(ReconnectDelayMs);
            if (await TryConnectAsync()) return;
            Console.Error.WriteLine($"Reconnect failed. Retrying in {ReconnectDelayMs / 1000}s...");
        }
    }

    // -------------------------------------------------------------------------
    // LSP framing helpers
    // -------------------------------------------------------------------------

    private static byte[] FrameMessage(string content)
    {
        int byteLen = Encoding.UTF8.GetByteCount(content);
        string header = $"Content-Length: {byteLen}\r\n\r\n";
        return Encoding.UTF8.GetBytes(header + content);
    }

    private static void WriteToStdout(string content)
    {
        byte[] framed = FrameMessage(content);
        _stdoutLock.Wait();
        try
        {
            var stdout = Console.OpenStandardOutput();
            stdout.Write(framed);
            stdout.Flush();
        }
        finally
        {
            _stdoutLock.Release();
        }
    }

    private static void SendNotificationToClient(string method, string paramsJson)
    {
        string content = $$"""{"jsonrpc":"2.0","method":"{{method}}","params":{{paramsJson}}}""";
        WriteToStdout(content);
    }

    private static int IndexOfHeaderDelimiter(List<byte> buffer)
    {
        for (int i = 0; i < buffer.Count - 3; i++)
        {
            if (buffer[i] == '\r' && buffer[i + 1] == '\n' &&
                buffer[i + 2] == '\r' && buffer[i + 3] == '\n')
                return i;
        }
        return -1;
    }

    private static int ParseContentLength(string header)
    {
        foreach (string line in header.Split('\n'))
        {
            if (line.TrimStart().StartsWith("Content-Length:", StringComparison.OrdinalIgnoreCase))
            {
                string value = line.Split(':')[1].Trim();
                if (int.TryParse(value, out int len)) return len;
            }
        }
        return -1;
    }

    // -------------------------------------------------------------------------
    // URI normalization (Windows cross-platform compatibility)
    // -------------------------------------------------------------------------

    private static void NormalizeUris(JsonNode? node)
    {
        if (node is JsonObject obj)
        {
            foreach (var key in obj.Select(kv => kv.Key).ToList())
            {
                if (obj[key] is JsonValue val && val.TryGetValue(out string? str) && str?.StartsWith("file://") == true)
                    obj[key] = NormalizeFileUri(str);
                else
                    NormalizeUris(obj[key]);
            }
        }
        else if (node is JsonArray arr)
        {
            for (int i = 0; i < arr.Count; i++)
            {
                if (arr[i] is JsonValue val && val.TryGetValue(out string? str) && str?.StartsWith("file://") == true)
                    arr[i] = NormalizeFileUri(str);
                else
                    NormalizeUris(arr[i]);
            }
        }
    }

    private static string NormalizeFileUri(string uri)
    {
        string path = uri[7..].Replace('\\', '/'); // strip "file://"
        if (path.Length > 0 && path[0] != '/')
            path = '/' + path;
        return "file://" + path;
    }

    // -------------------------------------------------------------------------
    // Misc helpers
    // -------------------------------------------------------------------------

    private static void BufferPending(byte[] framed)
    {
        if (_pendingMessages.Count >= 1000)
            _pendingMessages.RemoveAt(0);
        _pendingMessages.Add(framed);
    }

    private static void Shutdown(string reason)
    {
        if (!_shouldRun) return;
        _shouldRun = false;
        Log($"Shutdown: {reason}");
        _tcpStream?.Dispose();
        _tcp?.Dispose();
        Environment.Exit(0);
    }

    private static void Log(string msg)
    {
        if (!DebugEnabled) return;
        string line = $"[{DateTime.UtcNow:O}] {msg}";
        try { File.AppendAllText(LogFile, line + '\n'); } catch { }
        Console.Error.WriteLine(line);
    }

    private static void LogWarn(string msg) =>
        Console.Error.WriteLine($"[WARN] {msg}");
}

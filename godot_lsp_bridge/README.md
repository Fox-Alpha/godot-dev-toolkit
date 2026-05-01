# godot-lsp-bridge

A stdio ↔ TCP bridge for Godot's GDScript Language Server, written in C# as a self-contained native binary.

## Why?

AI coding tools (GitHub Copilot CLI, Claude Code, Cursor, etc.) expect LSP servers to communicate via **stdio**. Godot's LSP only supports **TCP** (port 6005). This bridge sits between the two.

```
┌─────────────┐   stdio   ┌──────────────────┐   TCP    ┌─────────────┐
│  AI Tool    │ ────────► │ godot-lsp-bridge │ ───────► │ Godot LSP   │
│ (Copilot,…) │ ◄──────── │                  │ ◄─────── │ (port 6005) │
└─────────────┘           └──────────────────┘          └─────────────┘
```

## Features

- stdio ↔ TCP bridging
- Auto port discovery (tries 6005, 6007, 6008)
- Initialize-notification buffering (fixes Godot's non-standard LSP ordering)
- Auto-reconnect when Godot restarts
- Windows file URI normalization
- 10 MB buffer limit against memory exhaustion
- No runtime dependency — single native binary via NativeAOT

## Requirements

- **Godot Editor** must be running with your project open (the LSP server is only active in the editor)

## Build

```bash
# Debug build
dotnet build

# Self-contained native binary (Linux x64)
dotnet publish -r linux-x64 -c Release

# Self-contained native binary (Windows x64)
dotnet publish -r win-x64 -c Release
```

The binary is placed in `bin/Release/net10.0/<rid>/publish/godot-lsp-bridge`.

## Configuration

### GitHub Copilot CLI (`lsp.json`)

```json
{
  "lspServers": {
    "godot": {
      "command": "/path/to/godot-lsp-bridge",
      "args": [],
      "fileExtensions": {
        ".gd": "GDScript",
        ".tscn": "GD Scene",
        ".tres": "GD Text Resource"
      },
      "rootUri": "godot_towns/"
    }
  }
}
```

### Environment Variables

| Variable | Default | Description |
|---|---|---|
| `GODOT_LSP_PORT` | auto-discover | Fix to a specific port |
| `GODOT_LSP_HOST` | `127.0.0.1` | Godot LSP host |
| `GODOT_LSP_BRIDGE_DEBUG` | `false` | Enable debug logging |
| `GODOT_LSP_BRIDGE_LOG` | `/tmp/godot-lsp-bridge.log` | Log file path |

## Acknowledgements

Inspired by [godot-lsp-stdio-bridge](https://github.com/code-xhyun/godot-lsp-stdio-bridge) by code-xhyun (MIT).  
The original Node.js implementation served as the reference for the LSP framing logic and Godot's non-standard initialize ordering.

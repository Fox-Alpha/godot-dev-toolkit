# Build & Deployment — godot-lsp-bridge

## Voraussetzungen

- .NET 10 SDK: [dotnet.microsoft.com](https://dotnet.microsoft.com/download)

## Build

```bash
# Debug-Build (für Entwicklung)
dotnet build

# Self-contained Binary (Linux x64)
dotnet publish -r linux-x64 -c Release

# Self-contained Binary (Windows x64)
dotnet publish -r win-x64 -c Release
```

Die Binary liegt nach dem Build unter:
```
bin/Release/net10.0/<rid>/publish/godot-lsp-bridge
```

## Deployment

```bash
# Linux — ins Benutzer-Bin
cp bin/Release/net10.0/linux-x64/publish/godot-lsp-bridge ~/.local/bin/

# Oder systemweit
sudo cp bin/Release/net10.0/linux-x64/publish/godot-lsp-bridge /usr/local/bin/
```

Die Binary ist **self-contained** — kein .NET Runtime auf dem Zielsystem nötig.

---

## Debugging

Debug-Log aktivieren:

```bash
GODOT_LSP_BRIDGE_DEBUG=true godot-lsp-bridge
```

Oder in der `lsp.json`:
```json
"env": {
  "GODOT_LSP_BRIDGE_DEBUG": "true",
  "GODOT_LSP_BRIDGE_LOG": "/tmp/lsp-bridge-debug.log"
}
```

Log lesen:
```bash
tail -f /tmp/godot-lsp-bridge.log
```

---

## Minimales Test-Projekt

Im Repo liegt unter `minimum-lsp-project/` ein minimales Godot-Projekt zum Testen der LSP-Integration.

```bash
# Godot Editor mit dem Test-Projekt starten
godot --path minimum-lsp-project/

# In einer zweiten Shell: Bridge testen
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}' | godot-lsp-bridge
```

---

## Fehlerbehebung

**Bridge startet, aber Godot-LSP antwortet nicht**
→ Godot Editor muss geöffnet sein und das Projekt muss aktiv sein (kein Minimieren/Schließen)

**Port nicht erreichbar**
→ `GODOT_LSP_PORT` manuell setzen und prüfen ob der Port in Godot (Einstellungen → Network) korrekt ist

**Verbindung bricht bei Godot-Neustart ab**
→ Normal — die Bridge reconnectet automatisch. Kurz warten.

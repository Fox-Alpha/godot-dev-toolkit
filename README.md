# godot-lsp-bridge

stdio ↔ TCP Bridge für Godots GDScript Language Server. Ermöglicht die Verwendung von Godots LSP mit AI Coding Tools wie GitHub Copilot CLI, Claude Code oder Cursor.

```
┌─────────────┐   stdio   ┌──────────────────┐   TCP    ┌─────────────┐
│  AI Tool    │ ────────► │ godot-lsp-bridge │ ───────► │ Godot LSP   │
│ (Copilot,…) │ ◄──────── │                  │ ◄─────── │ (port 6005) │
└─────────────┘           └──────────────────┘          └─────────────┘
```

## Features

- stdio ↔ TCP Bridging
- Automatische Port-Erkennung (probiert 6005, 6007, 6008)
- Initialize-Notification Pufferung (Workaround für Godots nicht-standardkonformes LSP-Verhalten)
- Auto-Reconnect bei Neustart von Godot
- Windows File URI Normalisierung
- 10 MB Buffer-Limit (Schutz gegen Speicherüberlastung)
- Keine Runtime-Abhängigkeit — einzelne native Binary via NativeAOT (C#)

## Voraussetzungen

- **Godot Editor** muss laufen mit geöffnetem Projekt (der LSP-Server ist nur im Editor aktiv)
- **.NET 10 SDK** (nur für den Build — die fertige Binary läuft ohne .NET Runtime)

## Installation

```bash
# Binary lokal verfügbar machen (Linux)
cp bin/Release/net10.0/linux-x64/publish/godot-lsp-bridge ~/.local/bin/
# oder: sudo cp ... /usr/local/bin/
```

Die Binary ist selbst-enthalten — kein .NET Runtime nötig.

## Verwendung

Die Bridge wird nicht direkt aufgerufen, sondern über die Konfiguration des AI Tools eingebunden.
Die Bridge startet und verbindet sich automatisch mit dem laufenden Godot Editor.

Schnelltest:
```bash
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}' | godot-lsp-bridge
```

## Dokumentation

- [Build-Anleitung & Deployment](docs/usage.md)
- [Konfiguration (lsp.json, Umgebungsvariablen)](docs/configuration.md)

## Part of godot-dev-toolkit

Dieses Tool ist Teil des [godot-dev-toolkit](https://github.com/Fox-Alpha/godot-dev-toolkit) Hubs.

Inspired by [godot-lsp-stdio-bridge](https://github.com/code-xhyun/godot-lsp-stdio-bridge) by code-xhyun (MIT).

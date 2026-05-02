# Konfiguration — godot-lsp-bridge

## GitHub Copilot CLI (`lsp.json`)

Die Datei `lsp.json` konfiguriert die LSP-Integration für GitHub Copilot CLI.
Sie wird im Projektverzeichnis unter `.github/lsp.json` abgelegt.

### Minimale Konfiguration

```json
{
  "lspServers": {
    "godot": {
      "command": "godot-lsp-bridge",
      "args": [],
      "fileExtensions": {
        ".gd": "GDScript",
        ".tscn": "GD Scene",
        ".tres": "GD Text Resource"
      },
      "rootUri": "<godot-projektverzeichnis>/"
    }
  }
}
```

**`rootUri`** — Pfad zum Godot-Projektverzeichnis, relativ zur Git-Root.
- Monorepo: `"rootUri": "mein_godot_projekt/"` (Unterverzeichnis)
- Einzelprojekt: `"rootUri": "."` (ganzes Repo ist das Godot-Projekt)

### Mit Debug-Logging

```json
{
  "lspServers": {
    "godot": {
      "command": "godot-lsp-bridge",
      "args": [],
      "env": {
        "GODOT_LSP_BRIDGE_DEBUG": "true"
      },
      "fileExtensions": {
        ".gd": "GDScript",
        ".tscn": "GD Scene",
        ".tres": "GD Text Resource"
      },
      "rootUri": "."
    }
  }
}
```

Das `env`-Feld unterstützt `${VAR}` und `${VAR:-default}` Expansion.

---

## Umgebungsvariablen

| Variable | Standard | Beschreibung |
|---|---|---|
| `GODOT_LSP_HOST` | `127.0.0.1` | Godot LSP Host |
| `GODOT_LSP_PORT` | auto (6005, 6007, 6008) | Port fixieren, wenn auto-discovery nicht funktioniert |
| `GODOT_LSP_BRIDGE_DEBUG` | `false` | Debug-Log aktivieren |
| `GODOT_LSP_BRIDGE_LOG` | `/tmp/godot-lsp-bridge.log` | Log-Dateipfad |

---

## Andere AI Tools

Die Bridge funktioniert mit jedem Tool, das einen LSP-Server per stdio erwartet.
Die Konfiguration ist tool-spezifisch — typisch wird die Binary als `command` angegeben:

```
command: godot-lsp-bridge
args:    []
```

Weitere Tool-spezifische Setups: bei Interesse im [godot-dev-toolkit Wiki](https://github.com/Fox-Alpha/godot-dev-toolkit/wiki) nachschauen.

---

## Bekannte Ports

Godot verwendet je nach Version und Instanz unterschiedliche Ports:

| Port | Verwendung |
|---|---|
| `6005` | Standard (Godot 4.x, erste Instanz) |
| `6007` | Zweite Godot-Instanz |
| `6008` | Dritte Godot-Instanz |

Die Bridge versucht diese Ports automatisch der Reihe nach.

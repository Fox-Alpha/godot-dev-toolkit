# godot-export-gui

Kleine GUI zum Exportieren von Godot-Projekten — gebaut mit PySimpleGUI.

## Features

- Projektordner auswählen und Godot-Binary angeben
- Export-Profil und Build-Typ wählen (`export-debug` / `export-release`)
- Konfiguration pro Projekt in `.export_config.json` speichern
- Ressourcen-Import und Export per Godot-CLI ausführen
- Godot-Binaries im System suchen (`Scan Engines`, `Scan Folder`)
- Versionsprüfung mit `Probe Versions`
- Export-Pfad automatisch aus `export_presets.cfg` lesen (`Auto Set Export Folder`)

## Voraussetzungen

- **Python 3.8+**
- **PySimpleGUI** (spezielle Installation erforderlich — privater PyPI-Index)
- **Godot Engine 4.x**

## Installation

```bash
python3 -m venv .venv
source .venv/bin/activate

# PySimpleGUI vom offiziellen Index installieren
python -m pip uninstall PySimpleGUI -y 2>/dev/null || true
python -m pip install --upgrade --extra-index-url https://PySimpleGUI.net/install PySimpleGUI

pip install -r requirements.txt
```

## Verwendung

```bash
source .venv/bin/activate
python export_gui.py
```

1. Projektordner auswählen
2. Godot-Binary angeben (oder per `Scan Engines` suchen)
3. Profil und Build-Typ wählen
4. `Save Config` — speichert `.export_config.json` im Projektordner
5. `Import` — Godot-Ressourcen importieren
6. `Export` — Projekt exportieren (Logs im Export-Ordner)

Detaillierte Bedienung → [docs/usage.md](docs/usage.md)

## Konfiguration

| Datei | Speicherort | Inhalt |
|---|---|---|
| `.export_config.json` | Projektordner | Projektspezifische Export-Einstellungen |
| `engines.json` | `~/.config/godot_export_gui/` | Globale Engine-Liste |

## Dokumentation

- [docs/usage.md](docs/usage.md) — Bedienung, Engine-Verwaltung, Konfigurationsformat

## Part of godot-dev-toolkit

Dieses Tool ist Teil des [godot-dev-toolkit](https://github.com/Fox-Alpha/godot-dev-toolkit) — einer Sammlung von Entwicklungswerkzeugen für Godot-Projekte.

> **Hinweis:** Dieses Tool gilt als feature-complete. Eine Neuentwicklung mit C#/Avalonia ist unter [godot-export-app](https://github.com/Fox-Alpha/godot-export-app) geplant.

# godot-export-builder

Bash-Script zur Automatisierung von Godot-Projekt-Exporten mit Multi-Profile-Unterstützung, Template-basierten Dateinamen und intelligenter Konfiguration.

## Features

- **Auto-Erkennung** — findet Godot-Executable und Projektverzeichnis automatisch
- **Multi-Profile-Exporte** — mehrere Build-Ziele in einer Konfigurationsdatei
- **Template-Dateinamen** — Platzhalter für Datum, Version, Plattform, Buildtyp
- **Projekt-relative Pfade** — Script aus beliebigem Verzeichnis ausführbar
- **JSON-Konfiguration** — strukturierte `build_config.json` pro Projekt
- **Versionsvalidierung** — prüft Godot-Version vor dem Build
- **Plattformunterstützung** — Windows (.exe), Linux (.x86_64), Web

## Voraussetzungen

- **Bash** 4.0+
- **jq** JSON-Parser
- **Godot Engine** 4.x

```bash
# jq installieren (Debian/Ubuntu)
sudo apt install jq

# jq installieren (macOS)
brew install jq
```

## Installation

```bash
# Script ausführbar machen
chmod +x cli_work.sh

# Konfiguration für dein Projekt initialisieren
./cli_work.sh --init
```

`--init` erstellt `build_config.json` mit automatisch erkanntem Godot-Pfad, Godot-Version, Projektname und aktuellem Betriebssystem als Standard-Profil.

## Verwendung

```bash
# Hilfe anzeigen
./cli_work.sh --help

# Konfiguration generieren
./cli_work.sh --init

# Build ausführen (nutzt build_config.json)
./cli_work.sh

# Script-Version anzeigen
./cli_work.sh --version
```

Das Script führt automatisch durch: Konfigurationsvalidierung → Godot-Versionsprüfung → Ressourcen-Import → Export aller Profile.

## Konfiguration

Minimales Beispiel für `build_config.json`:

```json
{
  "godot": {
    "path": "gd4",
    "version": "4.6"
  },
  "build": {
    "project_name": "MeinProjekt",
    "export_root": ".exports",
    "output_filename": "{project}_{date}_{os}_{type}"
  },
  "profiles": [
    {
      "name": "Linux",
      "type": "export-debug"
    }
  ]
}
```

Alle Parameter → [docs/configuration.md](docs/configuration.md)

## Dokumentation

- [docs/configuration.md](docs/configuration.md) — JSON-Parameter, Platzhalter, Profil-Overrides
- [docs/usage.md](docs/usage.md) — Multi-Profile, CLI-Parameter, Beispiele
- [docs/troubleshooting.md](docs/troubleshooting.md) — Fehlerbehebung, FAQ

## Part of godot-dev-toolkit

Dieses Tool ist Teil des [godot-dev-toolkit](https://github.com/Fox-Alpha/godot-dev-toolkit) — einer Sammlung von Entwicklungswerkzeugen für Godot-Projekte.

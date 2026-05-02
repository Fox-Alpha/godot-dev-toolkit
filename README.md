# godot-export-win-batch

> ⚠️ **Archiviert** — Windows-only, nicht mehr aktiv weiterentwickelt.
> Nachfolger für Linux: [godot-export-builder](https://github.com/Fox-Alpha/godot-export-builder)

Windows Batch-Script zur automatisierten Erstellung und Export von Godot-Projekten.

## Features

- Mehrere Godot-Versionen unterstützt (4.3-rc3, 4.4-dev6, 4.4-beta4)
- Automatische Verzeichniserstellung und Validierung
- Detailliertes Logging in `[Projektname]_export.log.txt`
- Debug und Release Export-Typen
- Optionale Ausführung der exportierten Binary

## Voraussetzungen

- **Windows** (Batch-Script, kein Linux/macOS)
- **Godot Engine** 4.3+ (Windows-Installation)
- Gültiges Godot-Projekt mit `project.godot`

## Installation

1. `export_godot.bat` in den Root-Ordner des Godot-Projekts legen
2. Godot-Pfad in der Konfigurationssektion anpassen:

```batch
set "gdpath=C:\Proggen\Godot\Godot_v4.4-beta"
set "godotexe=Godot_v4.4-beta4_win64.exe"
set "build_version=_alpha9"
```

## Verwendung

```batch
export_godot.bat
```

Ablauf: Validierung → Assets importieren → Exportieren → Binary optional starten.

## Dokumentation

- [docs/README.de.md](docs/README.de.md) — Vollständige Dokumentation (Deutsch)
- [docs/README.en.md](docs/README.en.md) — Full documentation (English)

## Archivstatus

Dieses Script war der Ausgangspunkt für den godot-export-builder. Es ist funktional und nutzbar, wird aber nicht mehr weiterentwickelt, da:
- Kein Windows-System mehr aktiv genutzt
- Bash-Version ([godot-export-builder](https://github.com/Fox-Alpha/godot-export-builder)) bietet mehr Features

## Part of godot-dev-toolkit

Dieses Tool ist Teil des [godot-dev-toolkit](https://github.com/Fox-Alpha/godot-dev-toolkit) — archiviert im Branch `archive/build_export_win_batch`.

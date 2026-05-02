# Changelog

## [Unreleased]

## [1.1.0] - 2026-05-01
### Added
- Hinweis auf godot-dev-toolkit Hub und geplantes godot-export-app Nachfolgeprojekt (C#/Avalonia)

## [1.0.0] - 2026-02-27
### Added
- GUI für Godot-Projekt-Exporte auf Basis von PySimpleGUI
- Projektordner-Auswahl und Godot-Binary-Konfiguration
- Export-Profil und Build-Typ-Auswahl (`export-debug` / `export-release`)
- Konfiguration per Projekt in `.export_config.json`
- `Save Config` — persistiert Einstellungen im Projektordner
- `Import` und `Export` führen Godot-CLI-Befehle aus, Logs im Export-Ordner
- `Scan Engines` — sucht Godot-Binaries in PATH und üblichen Installationsorten
- `Probe Versions` — prüft Versionen gefundener Binaries via `--version`
- `Scan Folder` — manuelles Durchsuchen eines Verzeichnisses nach Godot-Binaries
- `Save Engine` — speichert Engines dauerhaft in `~/.config/godot_export_gui/engines.json`
- `Auto Set Export Folder` — liest Export-Pfad aus `export_presets.cfg`
- Entwickelt mit AI-Unterstützung, in 5 Iterationen verfeinert

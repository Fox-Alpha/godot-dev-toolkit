# Changelog

## [Unreleased]

## [1.1.0] - 2026-05-01
### Removed
- Interne AI-Session-Log-Datei aus dem Repository entfernt

## [1.0.0] - 2026-04-19
### Fixed
- Fehlerhaften Debug-Commit revertiert (Debug-Modus funktionierte nicht wie erwartet)
- CRLF → LF Zeilenenden korrigiert

### Added
- Debug-Flag `--debug` zum Script hinzugefügt
- Godot-Symlink-Auflösung: falls Godot-Aufruf ein Symlink ist, wird der reale Pfad ermittelt
- Sicherheitsprüfung beim Generieren der Standard-Konfiguration

## [0.1.0] - 2026-02-27
### Added
- Bash-Script `cli_work.sh` zum Exportieren von Godot-Projekten unter Linux
- Basis: Windows Batch-Script (`build_export_win_batch`) mit umfangreichen Verbesserungen
- Multi-Profile-Unterstützung via `build_config.json`
- Template-basierte Ausgabedateinamen mit Platzhaltern (`{project}`, `{date}`, `{os}`, `{type}` etc.)
- Auto-Erkennung von Godot-Executable und Projektverzeichnis
- Godot-Versionsprüfung vor dem Build
- Profil-Overrides (pro Profil eigene Pfad- und Dateiname-Einstellungen)
- `--init`, `--help`, `--version` CLI-Flags
- Farbige Konsolenausgabe und Export-Logging
- Vollständige Dokumentation (DE + EN)

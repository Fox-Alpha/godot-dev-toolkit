# Changelog

## [Unreleased]

---

## [1.0.0] - 2026-05-01

### Added
- README mit vollständiger Nutzungsdokumentation

### Changed
- Ausgabepfad basiert jetzt immer auf dem Repository-Root
- Kurzflags (`-p`, `-o`, `-b`, `-s`, `-u`, `-t`), `--help` und automatischer Titel (Repo-Name + Branch) hinzugefügt
- Positionsargumente durch benannte Flags (`--path`, `--output`, `--branch`, `--since`, `--until`) ersetzt
- `-` als Platzhalter für gesamtes Repository mit benutzerdefiniertem Ausgabepfad

### Fixed
- CRLF → LF Zeilenenden

---

## [0.1.0] - 2026-02-27

### Added
- Initiales Bash-Script zur Generierung eines Markdown-Changelogs aus der Git-Historie
- Commit-Gruppierung nach Datum
- Sortierung nach Commit-Typ (Add → Fix → Upd → ...)

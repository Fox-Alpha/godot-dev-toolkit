# Changelog

## [Unreleased]

---

## [1.1.0] - 2026-05-01

### Added
- `lsp.json` ins Repo aufgenommen (aus godot-tool-sammelsurium verschoben, `rootUri` korrigiert)
- Git Styleguide Instruction und `game_manager` UID-Datei im Minimalprojekt
- `game_manager.gd` und zugehörige UID-Datei im Minimalprojekt

### Changed
- Leeren `TrimmerRootDescriptor` aus `.csproj` entfernt

### Fixed
- Node-Referenzen aus Test-Script entfernt
- `lsp.json` `rootUri` korrigiert (von projektspezifischem Pfad auf `minimum-lsp-project/`)

---

## [1.0.0] - 2026-04-01

### Added
- Minimales Godot-Projekt für LSP-Test (`minimum-lsp-project/`)
- `.gitignore` für Godot-Dateien und Build-Artefakte
- Erzwungener Prozessausstieg bei Ctrl+C / Shutdown
- Automatisches Einfügen von `textDocument/didOpen` vor LSP-Anfragen
- Initialer C# stdio-to-TCP LSP Bridge (`godot-lsp-bridge`)
  - stdio ↔ TCP Bridging
  - Auto Port-Erkennung (6005, 6007, 6008)
  - Initialize-Notification Pufferung
  - Auto-Reconnect
  - Windows File URI Normalisierung
  - 10 MB Buffer-Limit
  - NativeAOT Self-contained Binary

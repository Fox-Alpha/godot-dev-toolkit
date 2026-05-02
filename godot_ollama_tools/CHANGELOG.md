# Changelog

## [Unreleased]

## [1.0.0] - 2026-05-01
### Added
- README mit Tool-Übersicht und Kontextinformationen

## [0.2.0] - 2026-04-12
### Added
- Auto-Load von Ollama-Umgebungsvariablen aus `.env`

### Fixed
- Docker-Auto-Check auf lokale API-Ziele beschränkt (kein Docker-Check bei Remote-API)
- Docker-Check optional gemacht — deaktivierbar via `OLLAMA_USE_DOCKER=false`

### Changed
- Ollama-Portabilitäts-Defaults verbessert

### Docs
- Hilfe-Ausgabe und Dokumentation vereinheitlicht

## [0.1.0] - 2026-04-12
### Added
- Zentrales Script `ollama_helper.sh` mit `check`, `test`, `batch` Befehlen
- Modellkatalog via `models.json` und `modellkatalog.md`
- Standard-Testprofile für CSharp und GDScript (smoke, function, strict)
- Batch-Modus: Mehrere Modelle vergleichen, Run-Logs schreiben
- Persistenz: Ergebnisse direkt in `models.json` übernehmen
- `render_model_catalog.py` — Katalog als Markdown rendern
- `render_run_summary.py` — Batch-Logs auswerten
- `ollama-skill.md` — Skill-Definition für AI Coding Assistenten
- Docker-Support (`OLLAMA_USE_DOCKER=auto|true|false`)

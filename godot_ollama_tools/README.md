# godot-ollama-tools

Lokales Ollama-Toolkit für Godot-Entwicklung — generisch gehalten und erweiterbar für Godot-spezifische Aufgaben.

## Aktueller Stand

- Das allgemeine lokale Ollama-Tooling ist umgesetzt und bleibt bewusst generisch.
- Eine Godot-spezifische Erweiterung ist in Planung (Klassendokumentation, API-Lookup, Auswertung von Godot-Toolscripten).

## Enthaltene Dateien

| Datei | Beschreibung |
|---|---|
| `ollama_helper.sh` | Zentrales Script — unterstützt `check`, `test`, `batch` |
| `models.json` | Modellkatalog als JSON-Quelle |
| `modellkatalog.md` | Gerenderte Markdown-Übersicht der Modelle |
| `ollama-skill.md` | Skill-Definition für AI Coding Assistenten |
| `render_model_catalog.py` | Rendert `modellkatalog.md` aus `models.json` |
| `render_run_summary.py` | Wertet Run-Logs unter `runs/` aus |
| `runs/` | Reviewbare Ausführungs-Logs |

## Konfiguration

- `.env` wird automatisch aus dem Repo-Root geladen
- `.env.example` mit allen Default-Variablen vorhanden (im Hub-Repo)
- Docker ist optional, steuerbar über `OLLAMA_USE_DOCKER=auto|true|false`
  - `auto`: Docker wird nur bei lokalem API-Ziel verwendet

## Abgrenzung

Deterministische Aufgaben (Formatter, Linter, Exporter) bleiben normale Tools/Skripte.
Lokale Modelle werden primär für Dokumentation, Zusammenfassung, API-Lookup und leichte generative Aufgaben eingesetzt.

## Geplante Erweiterungen (Godot-spezifisch)

- Godot-Klassendokumentation via Ollama
- Godot API-Lookup
- Auswertung bestehender Godot-Tool-Skripte
- Optionale Delegation kleinerer Aufgaben an lokale Ollama-Modelle

## Part of godot-dev-toolkit

Dieses Tool ist Teil des [godot-dev-toolkit](https://github.com/Fox-Alpha/godot-dev-toolkit) Hubs — einer Sammlung von Godot-Entwicklungstools.

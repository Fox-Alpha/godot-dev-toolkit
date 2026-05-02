# godot-ollama-tools

Lokales Ollama-Toolkit für Godot-Entwicklung — generisch und erweiterbar für Godot-spezifische Aufgaben wie Dokumentation, API-Lookup und Modellvergleiche.

## Features

- **`check`** — Ollama-Umgebung prüfen (API, Docker, Modelle) ohne Seiteneffekte
- **`test`** — Einzelnes Modell mit definierten Testprofilen testen (CSharp, GDScript, frei)
- **`batch`** — Mehrere Modelle mit demselben Profil vergleichen, Run-Logs schreiben
- **Modellkatalog** — `models.json` als persistente Quelle, `modellkatalog.md` als Übersicht
- **Docker-Support** — optional (`auto|true|false`), greift nur bei lokalem API-Ziel
- **`.env`-Integration** — lokale Konfiguration aus `.env` im Repo-Root
- **Run-Logs** — reviewbare Ausführungsprotokolle unter `runs/`

## Voraussetzungen

- **Ollama** — lokal installiert oder per Docker
- **Bash** 4.0+
- **curl** und **jq** (optional für strukturierte Ausgabe)
- **Docker** (optional, nur bei Container-Setup)
- **Python 3** (optional, für `render_model_catalog.py` und `render_run_summary.py`)

```bash
# Ollama installieren
curl -fsSL https://ollama.com/install.sh | sh

# jq installieren (Debian/Ubuntu)
sudo apt install jq
```

## Installation

```bash
# Script ausführbar machen
chmod +x ollama_helper.sh

# Optional: .env aus Vorlage anlegen
cp .env.example .env
# .env anpassen (OLLAMA_HOST, OLLAMA_CONTAINER, etc.)
```

## Verwendung

```bash
# Umgebung prüfen
./ollama_helper.sh check

# Modell testen (Standard: smoke-csharp)
./ollama_helper.sh test qwen2.5-coder:7b

# Modell mit explizitem Profil testen
./ollama_helper.sh test qwen2.5-coder:7b gdscript function

# Batch-Vergleich aller Modelle
./ollama_helper.sh batch

# Batch auf Gruppe beschränken
./ollama_helper.sh batch csharp function --group code_generation
```

## Konfiguration

`.env` wird automatisch aus dem Repo-Root geladen:

```bash
OLLAMA_HOST=http://localhost:11434
OLLAMA_USE_DOCKER=auto       # auto | true | false
OLLAMA_CONTAINER=intel-llm   # Docker-Container-Name
```

Alle Umgebungsvariablen → [docs/configuration.md](docs/configuration.md)

## Enthaltene Dateien

| Datei | Beschreibung |
|---|---|
| `ollama_helper.sh` | Zentrales Script (`check`, `test`, `batch`) |
| `models.json` | Modellkatalog und Testprofile |
| `modellkatalog.md` | Gerenderte Modellübersicht |
| `ollama-skill.md` | Skill-Definition für AI Coding Assistenten |
| `render_model_catalog.py` | Rendert `modellkatalog.md` aus `models.json` |
| `render_run_summary.py` | Wertet Batch-Logs aus `runs/` aus |
| `runs/` | Run-Logs (Einzel- und Batch-Läufe) |

## Dokumentation

- [docs/commands/check.md](docs/commands/check.md) — `check`-Befehl Referenz
- [docs/commands/test.md](docs/commands/test.md) — `test`-Befehl Referenz
- [docs/commands/batch.md](docs/commands/batch.md) — `batch`-Befehl Referenz
- [docs/configuration.md](docs/configuration.md) — Umgebungsvariablen und Docker-Konfiguration

## Part of godot-dev-toolkit

Dieses Tool ist Teil des [godot-dev-toolkit](https://github.com/Fox-Alpha/godot-dev-toolkit) — einer Sammlung von Entwicklungswerkzeugen für Godot-Projekte.

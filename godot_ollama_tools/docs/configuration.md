# Konfiguration — godot-ollama-tools

## .env-Datei

`.env` wird automatisch aus dem Repo-Root geladen. Vorlage: `.env.example`.

```bash
# Ollama API-Endpunkt
OLLAMA_HOST=http://localhost:11434

# Docker-Modus: auto | true | false
# auto: Docker nur bei lokalem API-Ziel (localhost, 127.0.0.1, ::1)
OLLAMA_USE_DOCKER=auto

# Name des Docker-Containers
OLLAMA_CONTAINER=intel-llm
```

## Tool-spezifische Variablen

| Variable | Standard | Beschreibung |
|---|---|---|
| `OLLAMA_USE_DOCKER` | `auto` | Docker-Check aktivieren (`auto`/`true`/`false`) |
| `OLLAMA_CONTAINER` | `intel-llm` | Docker-Container-Name für Ollama |

### OLLAMA_USE_DOCKER

- `auto` — Docker wird nur geprüft, wenn `docker` verfügbar **und** `OLLAMA_HOST` auf ein lokales Ziel zeigt (`localhost`, `127.0.0.1`, `::1`, lokaler Hostname)
- `true` — Docker wird immer geprüft (Pflicht)
- `false` — Docker-Check wird komplett übersprungen

---

## Ollama-Umgebungsvariablen (Standard-Ollama)

Diese Variablen werden von Ollama selbst ausgewertet:

| Variable | Beschreibung |
|---|---|
| `OLLAMA_HOST` | IP/Host des Ollama-Servers (Standard: `127.0.0.1:11434`) |
| `OLLAMA_MODELS` | Pfad zum Modell-Verzeichnis |
| `OLLAMA_KEEP_ALIVE` | Wie lange Modelle im Speicher bleiben (Standard: `5m`) |
| `OLLAMA_CONTEXT_LENGTH` | Kontextlänge (Standard: abhängig vom VRAM) |
| `OLLAMA_MAX_LOADED_MODELS` | Max. gleichzeitig geladene Modelle pro GPU |
| `OLLAMA_NUM_PARALLEL` | Max. parallele Anfragen |
| `OLLAMA_DEBUG` | Debug-Ausgaben aktivieren (`1` = ein) |
| `OLLAMA_FLASH_ATTENTION` | Flash Attention aktivieren |
| `OLLAMA_KV_CACHE_TYPE` | Quantisierung des K/V-Cache (Standard: `f16`) |
| `OLLAMA_NO_CLOUD` | Cloud-Features deaktivieren |
| `OLLAMA_ORIGINS` | Erlaubte Origins (kommagetrennt) |
| `OLLAMA_LOAD_TIMEOUT` | Max. Wartezeit beim Modell-Laden (Standard: `5m`) |
| `OLLAMA_GPU_OVERHEAD` | VRAM-Reserve pro GPU (Bytes) |
| `OLLAMA_LLM_LIBRARY` | LLM-Bibliothek explizit setzen (überschreibt Auto-Erkennung) |
| `OLLAMA_NOPRUNE` | Modell-Blobs beim Start nicht bereinigen |

Vollständige Referenz: `ollama --help` oder [ollama.com/docs](https://ollama.com/docs)

---

## models.json

Zentrale Konfigurationsdatei für Modellkatalog und Testprofile.

```json
{
  "models": [
    {
      "name": "qwen2.5-coder:7b",
      "group": "code_generation",
      "last_run": null
    }
  ],
  "test_profiles": {
    "smoke-csharp": {
      "prompt": "Write a minimal C# Hello World..."
    }
  }
}
```

Modellkatalog als Markdown rendern:
```bash
python3 render_model_catalog.py
```

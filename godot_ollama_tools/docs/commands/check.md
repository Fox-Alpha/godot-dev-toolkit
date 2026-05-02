# check — Ollama-Umgebung prüfen

Prüft die lokale Ollama-Umgebung ohne Seiteneffekte (kein Modell-Download, kein Container-Start).

## Verwendung

```bash
./ollama_helper.sh check

# Docker-Check explizit deaktivieren
OLLAMA_USE_DOCKER=false ./ollama_helper.sh check
```

## Was geprüft wird

1. **Docker-Status** (optional) — Container-Zustand per `docker inspect`
2. **API-Erreichbarkeit** — `curl http://localhost:11434/api/tags`
3. **Geladene Modelle** — `ollama ps`
4. **Verfügbare Modelle** — `ollama list`

## Ausgabeformat

```
**Ollama-Status:** erreichbar | nicht erreichbar
**Container:** <name> (running | stopped | missing | not used)

| Model | Size | Status | Notes |
|---|---|---|---|
```

## Fehlerklassifikation

| Situation | Status |
|---|---|
| API erreichbar | `ok` |
| Container vorhanden, aber gestoppt | `container_stopped` |
| Container nicht gefunden | `missing` |
| API nicht erreichbar, Container läuft | `api_error` |
| `ollama list`/`ollama ps` schlägt trotz API fehl | `cli_error` |

## Regeln

- Startet den Container **nicht** ungefragt
- Lädt **keine** Modelle herunter
- Unterscheidet zwischen `container_stopped`, `missing` und sonstigen Fehlern

## Umgebungsvariablen

| Variable | Bedeutung |
|---|---|
| `OLLAMA_USE_DOCKER` | `auto` / `true` / `false` — Docker-Check steuern |
| `OLLAMA_CONTAINER` | Docker-Container-Name (Standard: `intel-llm`) |
| `OLLAMA_HOST` | API-Ziel (Standard: `http://localhost:11434`) |

Alle Variablen → [../configuration.md](../configuration.md)

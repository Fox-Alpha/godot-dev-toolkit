# Modellkatalog

Diese Datei wird aus `ollama-tooling/models.json` generiert.
JSON ist die kanonische Quelle; passe Aenderungen zuerst dort an.
Katalog zuletzt aktualisiert: `2026-04-11 23:02 CEST (+02:00)`.
JSON-Zeitstempel bleiben in UTC, Markdown zeigt lokale Zeit mit Zeitzone (`+02:00`).
Review-Logs liegen unter `ollama-tooling/runs` mit `single/` und `batch/`-Unterordnern.
Tabellen-Sortierung: `metrics.last_duration_ms asc, name asc`.

Statuswerte:

| Status | Bedeutung |
|---|---|
| `untested` | Modell vorhanden, aber noch nicht bewertet |
| `ok` | Modell geladen und einfacher Test erfolgreich |
| `container_stopped` | Ollama war wegen gestopptem Container nicht erreichbar |
| `load_failed` | Modell konnte nicht geladen werden |
| `pull_failed` | Download/Import fehlgeschlagen |
| `timeout` | Test lief in ein Timeout |
| `syntax_issue` | Ergebnis war formal unplausibel oder fehlerhaft |
| `godot4_insufficient` | Antwort deutet auf unzureichendes Wissen zu Godot 4 hin |

## Test-Zusammenfassung

| Metrik | Wert |
|---|---|
| Modelle insgesamt | `21` |
| `ok` | `18` |
| `syntax_issue` | `2` |
| `load_failed` | `1` |
| Schnellstes Modell (letzter Lauf) | `gemma3:latest` - `4223ms` |
| Hoechster Durchsatz | `llama2:latest` - `75.26 tok/s` |

## 💻 Code-Generierung

| Model | ID | Size | Release | Status | Last test | Profile | Duration | Tokens (P/E) | Tok/s | Notes |
|---|---|---|---|---|---|---|---|---|---|---|
| **opencoder:8b** | `cd882db52297` | `4,7 GB` | `2024` | `ok` | `2026-04-11 22:57 CEST (+02:00)` | `smoke-csharp` | `17640ms` | `57 / 33` | `63.38 tok/s` | contains markdown fences |
| **starcoder2:7b** | `1550ab21b10d` | `4,0 GB` | `2024` | `syntax_issue` | `2026-04-11 22:58 CEST (+02:00)` | `smoke-csharp` | `21818ms` | `45 / 2` | `107.98 tok/s` | empty response |
| **dolphincoder:7b** | `677555f1f316` | `4,2 GB` | `2024` | `ok` | `2026-04-11 22:58 CEST (+02:00)` | `smoke-csharp` | `24461ms` | `62 / 38` | `58.72 tok/s` | contains markdown fences |
| **codegemma:7b** | `0c96700aaada` | `5,0 GB` | `2024` | `ok` | `2026-04-11 22:57 CEST (+02:00)` | `smoke-csharp` | `27187ms` | `56 / 43` | `55.53 tok/s` | contains markdown fences |
| **yi-coder:9b** | `39c63e7675d7` | `5,0 GB` | `2024` | `ok` | `2026-04-11 22:57 CEST (+02:00)` | `smoke-csharp` | `28444ms` | `54 / 47` | `55.04 tok/s` | contains markdown fences |
| **deepcoder:14b** | `12bdda054d23` | `9,0 GB` | `2024` | `ok` | `2026-04-11 22:54 CEST (+02:00)` | `smoke-csharp` | `41478ms` | `34 / 332` | `33.05 tok/s` | contains markdown fences;contains reasoning tags |
| **deepseek-coder-v2:16b** | `63fb193b3a9b` | `8,9 GB` | `2024` | `ok` | `2026-04-11 22:54 CEST (+02:00)` | `smoke-csharp` | `49635ms` | `42 / 37` | `59.95 tok/s` | contains markdown fences |
| **dolphincoder:15b** | `1102380927c2` | `9,1 GB` | `2024` | `ok` | `2026-04-11 22:56 CEST (+02:00)` | `smoke-csharp` | `50676ms` | `62 / 31` | `32.83 tok/s` | contains markdown fences |
| **starcoder2:15b** | `21ae152d49e0` | `9,1 GB` | `2024` | `syntax_issue` | `2026-04-11 22:55 CEST (+02:00)` | `smoke-csharp` | `51783ms` | `45 / 1` | `98.48 tok/s` | empty response |
| **codestral:latest** | `0898a8b286d5` | `12 GB` | `2024` | `ok` | `2026-04-11 22:53 CEST (+02:00)` | `smoke-csharp` | `71784ms` | `42 / 52` | `25.28 tok/s` | pass |

## 🧠 Reasoning & Problemlösung

| Model | ID | Size | Release | Status | Last test | Profile | Duration | Tokens (P/E) | Tok/s | Notes |
|---|---|---|---|---|---|---|---|---|---|---|
| **phi4:14b** | `ac896e5b8b34` | `9,1 GB` | `2024` | `ok` | `2026-04-11 22:59 CEST (+02:00)` | `smoke-csharp` | `29641ms` | `41 / 29` | `35.09 tok/s` | contains markdown fences |
| **deepseek-r1:14b** | `c333b7232bdb` | `9,0 GB` | `2024` | `ok` | `2026-04-11 22:59 CEST (+02:00)` | `smoke-csharp` | `40797ms` | `34 / 317` | `33.07 tok/s` | contains reasoning tags |

## 🌐 Allrounder & Sprache

| Model | ID | Size | Release | Status | Last test | Profile | Duration | Tokens (P/E) | Tok/s | Notes |
|---|---|---|---|---|---|---|---|---|---|---|
| **mistral:7b** | `6577803aa9a0` | `4,4 GB` | `2023` | `ok` | `2026-04-11 23:01 CEST (+02:00)` | `smoke-csharp` | `17264ms` | `41 / 49` | `67.10 tok/s` | pass |
| **dolphin3:8b** | `d5ab9ae8e1f2` | `4,9 GB` | `2024` | `ok` | `2026-04-11 23:01 CEST (+02:00)` | `smoke-csharp` | `20021ms` | `54 / 29` | `60.89 tok/s` | contains markdown fences |
| **llama2:latest** | `78e26419b446` | `3,8 GB` | `2023` | `ok` | `2026-04-11 23:02 CEST (+02:00)` | `smoke-csharp` | `21619ms` | `57 / 44` | `75.26 tok/s` | contains markdown fences |
| **dolphin-mistral:7b** | `5dc8c5a2be65` | `4,1 GB` | `2024` | `ok` | `2026-04-11 23:01 CEST (+02:00)` | `smoke-csharp` | `23732ms` | `65 / 39` | `68.52 tok/s` | pass |
| **llama3:latest** | `365c0bd3c000` | `4,7 GB` | `2024` | `ok` | `2026-04-11 23:00 CEST (+02:00)` | `smoke-csharp` | `28457ms` | `41 / 31` | `66.82 tok/s` | pass |
| **qwen3:14b** | `bdbd181c33f2` | `9,3 GB` | `2024` | `ok` | `2026-04-11 23:00 CEST (+02:00)` | `smoke-csharp` | `43782ms` | `39 / 452` | `33.93 tok/s` | contains reasoning tags |

## ⚡ Ressourcenschonend / Edge

| Model | ID | Size | Release | Status | Last test | Profile | Duration | Tokens (P/E) | Tok/s | Notes |
|---|---|---|---|---|---|---|---|---|---|---|
| **gemma3:latest** | `a2af6cc3eb7f` | `3,3 GB` | `2024` | `ok` | `2026-04-11 23:02 CEST (+02:00)` | `smoke-csharp` | `4223ms` | `43 / 45` | `63.82 tok/s` | contains markdown fences |
| **gemma3n:e4b** | `15cb39fd9394` | `7,5 GB` | `2024` | `ok` | `2026-04-11 23:02 CEST (+02:00)` | `smoke-csharp` | `9954ms` | `53 / 37` | `24.87 tok/s` | pass |

## 🔍 Spezialisiert

| Model | ID | Size | Release | Status | Last test | Profile | Duration | Tokens (P/E) | Tok/s | Notes |
|---|---|---|---|---|---|---|---|---|---|---|
| **deepseek-ocr:latest** | `0e7b018b8a22` | `6,7 GB` | `2024` | `load_failed` | `2026-04-11 23:02 CEST (+02:00)` | `smoke-csharp` | `175ms` | `-/-` | `-` | HTTP 500 during generate request |

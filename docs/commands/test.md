# test — Modell testen

Führt einen nicht-interaktiven Test gegen ein lokales Ollama-Modell aus, misst Metriken und schreibt einen reviewbaren Run-Log.

## Verwendung

```bash
# Standard: smoke-csharp
./ollama_helper.sh test <modell>

# Explizites Profil
./ollama_helper.sh test <modell> [testtyp] [profil]

# Freier Prompt
./ollama_helper.sh test <modell> --prompt "Write a GDScript function..."
./ollama_helper.sh test <modell> --prompt-file /tmp/prompt.txt --profile-name my-test
```

## Parameter

| Parameter | Optionen | Standard |
|---|---|---|
| Modellname | z.B. `qwen2.5-coder:7b` | — (Pflicht) |
| Testtyp | `csharp`, `gdscript` | `csharp` |
| Profil | `smoke`, `function`, `strict` | `smoke` |
| Profil-ID | `smoke-csharp`, `function-gdscript`, … | — |

## Standard-Profile

Profile werden aus `models.json` unter `test_profiles` gelesen. Prompt-Texte können dort direkt angepasst werden.

### smoke-csharp
```
Write a minimal C# Hello World program as a single file.
Return plain source code only. No explanations. No markdown code fences.
```

### function-csharp
```
Write a minimal C# static int SumPositive(int[] values) method.
Must return the sum of all positive integers. Return plain source code only.
```

### smoke-gdscript
```
Write a minimal GDScript function that prints "Hello World".
Return plain source code only. No explanations.
```

### function-gdscript
```
Write a GDScript function func sum_positive(values: Array) -> int.
Must return the sum of all positive integers. Return plain source code only.
```

## Ausgabe

```
**Model:** qwen2.5-coder:7b
**Profile:** smoke-csharp
**Status:** ok | error
**Duration:** 3.2s
**Tok/s:** 42.1
**Run log:** runs/single/<run-id>.json
```

## Persistenz

Ergebnis wird in `models.json` übernommen (aktualisiert `last_run`).
`--no-persist` deaktiviert das Schreiben.

## Run-Logs

```
runs/
└── single/
    └── <run-id>.json
```

Nachrendern:
```bash
python3 render_run_summary.py runs/single/<run-id>.json
```

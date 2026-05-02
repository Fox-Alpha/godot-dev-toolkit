# batch — Mehrere Modelle vergleichen

Führt denselben Test gegen mehrere Modelle aus, schreibt reviewbare Run-Logs und aktualisiert optional den Modellkatalog.

## Verwendung

```bash
# Alle Modelle aus models.json
./ollama_helper.sh batch

# Mit Testtyp und Profil
./ollama_helper.sh batch csharp function

# Auf Kataloggruppe einschränken
./ollama_helper.sh batch csharp function --group code_generation

# Explizite Modellliste
./ollama_helper.sh batch --models opencoder:8b,qwen3:14b --profile-name sentiment-short --prompt-file /tmp/prompt.txt

# Ohne Persistenz
./ollama_helper.sh batch csharp smoke --models opencoder:8b --no-persist
```

## Verhalten

- Nutzt standardmäßig alle Modelle aus `models.json`
- Profile werden ebenfalls aus `models.json` gelesen — Prompt-Änderungen wirken automatisch für `test` und `batch`
- Schreibt pro Modell einen Run-Log und eine Batch-Zusammenfassung

## Ausgabe

```
**Batch:** <batch-id>
**Profile:** <profile>
**Persisted:** yes | no
**Started:** <Zeit mit Zeitzone>
**Finished:** <Zeit mit Zeitzone>
**Batch log:** <path>
**Summary:** <path>

| Model | Status | Duration | Tok/s | Run log |
|---|---|---|---|---|
```

## Log-Struktur

```
runs/
└── batch/
    └── <batch-id>/
        ├── batch.json
        ├── summary.md
        ├── <model-a>.json
        └── <model-b>.json
```

`summary.md` enthält die Ergebnistabelle und einklappbare Detailbereiche pro Modell.

## Nachrendern

```bash
python3 render_run_summary.py runs/batch/<batch-id>/batch.json
```

## Persistenz

Ohne `--no-persist`:
1. Jeder Lauf wird in `models.json` übernommen (`last_run` aktualisiert)
2. `modellkatalog.md` wird am Ende neu gerendert
3. Run-Logs bleiben unter `runs/`

# Verwendung — godot-export-gui

## Starten

```bash
source .venv/bin/activate
python export_gui.py
```

## Workflow

### 1. Projekt einrichten

1. **Projektordner auswählen** — Verzeichnis mit `project.godot`
2. **Godot-Binary angeben** — entweder manuell eintragen oder `Scan Engines` verwenden
3. **Export-Profil auswählen** — Profile werden aus `export_presets.cfg` gelesen
4. **Build-Typ wählen** — `export-debug` oder `export-release`

### 2. Konfiguration speichern

- `Save Config` — speichert alle Einstellungen in `.export_config.json` im Projektordner
- Konfiguration wird beim nächsten Start automatisch geladen

### 3. Exportieren

- `Import` — führt `godot --import` für das Projekt aus (Ressourcen-Import)
- `Export` — führt `godot --export-debug` / `--export-release` aus
- Logs werden im Export-Ordner gespeichert

---

## Engine-Verwaltung

### Scan Engines

Sucht automatisch nach Godot-Binaries in PATH und üblichen Installationsorten.

### Scan Folder

Manuelles Durchsuchen eines angegebenen Verzeichnisses nach Godot-Binaries.

### Probe Versions

Führt `--version` für gefundene Binaries aus und zeigt die Godot-Versionen in der Liste an.

### Save Engine

Speichert gefundene/ausgewählte Engines dauerhaft unter `~/.config/godot_export_gui/engines.json`.

---

## Auto Set Export Folder

Liest `export_presets.cfg` im Projektverzeichnis und setzt den Export-Zielordner automatisch basierend auf dem gewählten Profil.

---

## Konfigurationsformat

### .export_config.json (pro Projekt)

```json
{
  "project_path": "/pfad/zum/projekt",
  "godot_binary": "gd4",
  "export_profile": "Linux",
  "export_type": "export-debug",
  "export_folder": ".exports/Linux"
}
```

### engines.json (global)

```json
{
  "engines": [
    {
      "path": "/usr/local/bin/godot",
      "version": "4.6"
    }
  ]
}
```

Speicherort: `~/.config/godot_export_gui/engines.json`

---

## PySimpleGUI-Lizenz

PySimpleGUI erfordert eine kostenlose Registrierung unter [PySimpleGUI.com](https://www.pysimplegui.com) für die Nutzung. Bei der ersten Ausführung erscheint ein Login-Dialog.

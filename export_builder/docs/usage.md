# Verwendung — godot-export-builder

Erweiterte Beispiele, Multi-Profile, CLI-Parameter und Fehlerbehandlung.

## Inhaltsverzeichnis

- [Grundbefehle](#grundbefehle)
- [Script aus verschiedenen Verzeichnissen](#script-aus-verschiedenen-verzeichnissen)
- [CLI-Parameter](#cli-parameter)
- [Multi-Profile-Exporte](#multi-profile-exporte)
- [Profil-Overrides](#profil-overrides)
- [Beispiele](#beispiele)
- [Fehlerbehandlung](#fehlerbehandlung)

---

## Grundbefehle

```bash
# Hilfe anzeigen
./cli_work.sh --help

# Konfiguration generieren
./cli_work.sh --init

# Build ausführen (nutzt build_config.json)
./cli_work.sh

# Script-Version anzeigen
./cli_work.sh --version
```

---

## Script aus verschiedenen Verzeichnissen

Das Script sucht automatisch nach `project.godot` in der Verzeichnishierarchie:

```bash
# Vom Projekt-Root
cd /pfad/zum/MeinProjekt
/pfad/zum/cli_work.sh

# Aus einem Unterverzeichnis
cd /pfad/zum/MeinProjekt/scripts
../../cli_work.sh

# Aus dem übergeordneten Verzeichnis
cd /pfad/zum
MeinProjekt/cli_work.sh
```

---

## CLI-Parameter

### `--init`

Generiert `build_config.json` mit automatisch erkannten Werten:

```bash
./cli_work.sh --init
```

Auto-Erkennung:
- Godot-Executable-Pfad (aus PATH)
- Godot-Version (aus `godot --version`)
- Projektname (aus Verzeichnisname)
- Betriebssystem (Linux, Mac, Windows)

Beispielausgabe:
```json
{
  "godot": { "path": "gd4", "version": "4.6" },
  "build": {
    "project_name": "MeinProjekt",
    "version_suffix": "dev",
    "export_root": ".exports",
    "output_filename": "{project}_{date}_{os}_{type}",
    "use_separators": true
  },
  "profiles": [
    { "name": "Linux", "type": "export-debug", "platform": "x86_64" }
  ]
}
```

### `--help`

Zeigt Verwendungshinweise und alle verfügbaren Optionen.

### `--version`

Gibt die Script-Version aus: `Godot Project Build Script v1.0`

---

## Multi-Profile-Exporte

Mehrere Plattformen in einem Durchlauf exportieren:

```json
{
  "godot": { "path": "gd4", "version": "4.6" },
  "build": {
    "project_name": "MeinSpiel",
    "version_suffix": "_v1.0",
    "export_root": ".exports",
    "output_filename": "{project}_{date}_{os}_{type}"
  },
  "profiles": [
    { "name": "Windows Desktop", "type": "export-release", "platform": "x86_64" },
    { "name": "Linux",           "type": "export-release", "platform": "x86_64" },
    { "name": "Web",             "type": "export-debug",   "platform": "web" }
  ]
}
```

Ausführung:
```bash
./cli_work.sh
```

Ausgabestruktur:
```
.exports/
├── Windows Desktop/
│   ├── MeinSpiel_20260227_Win_release_v1.0.exe
│   └── MeinSpiel_export.log.txt
├── Linux/
│   ├── MeinSpiel_20260227_Lin_release_v1.0.x86_64
│   └── MeinSpiel_export.log.txt
└── Web/
    ├── MeinSpiel_20260227_Lin_debug_v1.0/
    └── MeinSpiel_export.log.txt
```

---

## Profil-Overrides

Jedes Profil kann globale Einstellungen überschreiben:

```json
{
  "build": {
    "project_name": "MeinSpiel",
    "version_suffix": "dev",
    "output_filename": "{project}_{date}_{type}"
  },
  "profiles": [
    {
      "name": "Windows Desktop",
      "type": "export-debug",
      "platform": "x86_64",
      "output_filename": "{project}_windows_{godot_version}",
      "export_path": "./windows_builds"
    },
    {
      "name": "Linux",
      "type": "export-release",
      "platform": "x86_64",
      "export_path": "./linux_builds"
    }
  ]
}
```

**Vorrangordnung:** Profilwert > globaler `build`-Wert > eingebauter Standard

---

## Beispiele

### Einzelner Export (minimal)

```json
{
  "godot": { "path": "gd4", "version": "4.6" },
  "build": { "project_name": "MeinSpiel", "version_suffix": "dev" },
  "profiles": [{ "name": "Linux", "type": "export-debug", "platform": "x86_64" }]
}
```

### Multi-Plattform Release

```json
{
  "godot": { "path": "gd4", "version": "4.6" },
  "build": {
    "project_name": "ShooterGame",
    "version_suffix": "_v1.0",
    "export_root": ".exports",
    "output_filename": "{project}_{godot_version}_{os}_{platform}_{type}"
  },
  "profiles": [
    { "name": "Windows Desktop", "type": "export-release", "platform": "x86_64" },
    { "name": "Linux",           "type": "export-release", "platform": "x86_64" },
    { "name": "Web",             "type": "export-release", "platform": "web" }
  ]
}
```

Ausgabe:
```
.exports/
├── Windows Desktop/ShooterGame_4.6_Win_x86_64_release_v1.0.exe
├── Linux/ShooterGame_4.6_Lin_x86_64_release_v1.0.x86_64
└── Web/ShooterGame_4.6_Lin_web_release_v1.0/
```

### Debug + Release vom gleichen Profil

```json
{
  "build": { "project_name": "Spiel", "output_filename": "{project}_{date}_{type}" },
  "profiles": [
    { "name": "Windows Desktop", "type": "export-debug",   "export_path": "./win_debug" },
    { "name": "Windows Desktop", "type": "export-release", "export_path": "./win_release",
      "output_filename": "{project}_final" }
  ]
}
```

---

## Fehlerbehandlung

Das Script gibt klare Fehlermeldungen aus und bricht mit Exit-Code ab.

### Konfigurationsfehler (Exit 1)

```
[ERROR] build_config.json nicht gefunden
[ERROR] Führen Sie './cli_work.sh --init' aus, um eine Standard-Konfiguration zu generieren
```

```
[ERROR] build_config.json hat ungültige JSON-Syntax
```

```
[ERROR] jq wird benötigt, um build_config.json zu analysieren
[ERROR] Installieren Sie es mit: apt install jq (Debian/Ubuntu) oder brew install jq (macOS)
```

### Validierungsfehler (Exit 1)

```
[ERROR] Godot-Versionsnichtübereinstimmung!
[ERROR]   Erwartet: 4.6
[ERROR]   Erhalten: 4.5
```

```
[ERROR] Godot-Executable nicht gefunden unter: /pfad/zum/godot
```

### Laufzeitfehler (Exit 99)

```
[ERROR] project.godot konnte nicht gefunden werden
[ERROR] Führen Sie dieses Script vom Projektverzeichnis oder einem Unterverzeichnis aus
```

```
[ERROR] Export mit Exit-Code 1 fehlgeschlagen
```

Export-Logs für Debugging:
```bash
cat .exports/Linux/MeinSpiel_export.log.txt
```

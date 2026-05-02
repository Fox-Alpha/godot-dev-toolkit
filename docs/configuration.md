# Konfiguration — godot-export-builder

Vollständige Referenz aller Parameter in `build_config.json`.

## Inhaltsverzeichnis

- [Dateispeicherort](#dateispeicherort)
- [godot-Sektion](#godot-sektion)
- [build-Sektion](#build-sektion)
- [profiles-Sektion](#profiles-sektion)
- [Dateiname-Platzhalter](#dateiname-platzhalter)

---

## Dateispeicherort

```
project_root/
├── project.godot
├── build_config.json          ← Konfigurationsdatei
├── cli_work.sh                ← Das Script
└── .exports/                  ← Standard-Export-Verzeichnis (von Godot ignoriert)
    ├── Windows/
    ├── Linux/
    └── Web/
```

Konfiguration generieren (empfohlen):
```bash
./cli_work.sh --init
```

Oder manuell erstellen:
```bash
cat > build_config.json << 'EOF'
{
  "godot": {
    "path": "gd4",
    "version": "4.6"
  },
  "build": {
    "project_name": "MeinProjekt",
    "version_suffix": "dev",
    "export_root": ".exports",
    "output_filename": "{project}_{date}_{os}_{type}",
    "use_separators": true
  },
  "profiles": [
    {
      "name": "Linux",
      "type": "export-debug",
      "platform": "x86_64"
    }
  ]
}
EOF
```

---

## godot-Sektion

Definiert Godot-Engine-Einstellungen (global).

### `godot.path` (String, optional)

Pfad zur Godot-Executable.

- **Standard**: Automatische Erkennung aus PATH
- **Beispiele**: `"gd4"`, `"godot"`, `"/usr/local/bin/godot"`, `"/Applications/Godot.app/Contents/MacOS/Godot"`

```json
{ "godot": { "path": "gd4" } }
```

### `godot.version` (String, optional)

Erwartete Godot-Version (Major.Minor). Wird vor dem Build validiert.

- **Standard**: Versionsprüfung übersprungen
- **Format**: `"X.Y"` — z.B. `"4.6"`, `"4.5"`
- **Fehler bei Nichtübereinstimmung**: Script bricht ab mit Fehlermeldung

```json
{ "godot": { "path": "gd4", "version": "4.6" } }
```

---

## build-Sektion

Globale Build-Einstellungen — gelten für alle Profile, sofern nicht pro Profil überschrieben.

### `build.project_name` (String)

Projektname für Dateinamen und Logging.

- **Standard**: `"DefaultProject"`
- **Von `--init` gesetzt**: Verzeichnisname des Projekts
- **Verwendet in**: `{project}` Platzhalter

```json
{ "build": { "project_name": "MeinSpiel" } }
```

### `build.version_suffix` (String)

Suffix, das an alle Ausgabedateien angehängt wird.

- **Standard**: `"dev"`
- **Beispiele**: `"_alpha9"`, `"_beta"`, `"_release"`, `"_1.0"`
- **Position**: Vor der Dateierweiterung (`.exe`, `.x86_64`)

```json
{ "build": { "version_suffix": "_v1.0" } }
```

Ergebnis: `MeinSpiel_v1.0.exe`

### `build.export_root` (String)

Stammverzeichnis für alle Exporte (relativ zum Projektverzeichnis).

- **Standard**: `".exports"` (beginnt mit `.` → von Godot-Editor ignoriert)
- **Exporte landen in**: `{export_root}/{profile_name}/`
- **Tipp**: Verzeichnisse mit `.` werden von Godot automatisch ignoriert

```json
{ "build": { "export_root": ".exports" } }
```

### `build.export_path` (String, optional)

Überschreibt `export_root` — absoluter oder relativer Pfad.

- **Vorrang**: Höher als `export_root`

```json
{ "build": { "export_path": "../builds" } }
```

### `build.output_filename` (String)

Dateiname-Template (ohne Erweiterung). Unterstützt Platzhalter.

- **Standard**: `"{project}_{date}_{os}_{type}"`
- **Platzhalter**: Siehe [Dateiname-Platzhalter](#dateiname-platzhalter)
- **Pro-Profil überschreibbar**: via `profiles[].output_filename`

```json
{ "build": { "output_filename": "{project}_{godot_version}_{date}_{os}_{type}" } }
```

### `build.use_separators` (Boolean)

Ob Unterstriche zwischen Dateinamenkomponenten erhalten bleiben.

- **Standard**: `true`
- **Bei `false`**: Alle Unterstriche werden entfernt

```json
{ "build": { "output_filename": "{project}_{date}_{type}", "use_separators": true } }
```

Ergebnis mit `true`: `MeinSpiel_20260227_debug`
Ergebnis mit `false`: `MeinSpiel20260227debug`

---

## profiles-Sektion

Array von Build-Profilen. Jedes Profil = ein Exportziel.

### Profil-Parameter

| Parameter | Typ | Pflicht | Beschreibung |
|---|---|---|---|
| `name` | String | ✅ | Profilname aus `export_presets.cfg` |
| `type` | String | — | `"export-debug"` oder `"export-release"` |
| `platform` | String | — | Zielarchitektur, z.B. `"x86_64"`, `"arm64"`, `"web"` |
| `output_filename` | String | — | Überschreibt globales `build.output_filename` |
| `export_path` | String | — | Überschreibt globales `build.export_root` |

### `profiles[].name`

Muss exakt dem Profilnamen in Godots `export_presets.cfg` entsprechen.

```json
{ "profiles": [{ "name": "Windows Desktop" }, { "name": "Linux" }] }
```

### `profiles[].type`

```json
{ "profiles": [
  { "name": "Linux", "type": "export-debug" },
  { "name": "Linux", "type": "export-release" }
] }
```

### Vorrangordnung

1. Profilspezifischer Wert (höchste Priorität)
2. Globaler `build`-Wert (Fallback)
3. Eingebauter Standard (niedrigste Priorität)

---

## Dateiname-Platzhalter

Verfügbar in `build.output_filename` und `profiles[].output_filename`:

| Platzhalter | Beispielwert | Quelle |
|---|---|---|
| `{project}` | `MeinSpiel` | `build.project_name` |
| `{version_suffix}` | `_v1.0` | `build.version_suffix` |
| `{godot_version}` | `4.6` | `godot.version` oder Laufzeit |
| `{date}` | `20260227` | Aktuelles Datum (YYYYMMDD) |
| `{os}` | `Win`, `Lin`, `Mac` | Vom System erkannt |
| `{type}` | `debug`, `release` | Aus `export-debug` / `export-release` |
| `{platform}` | `x86_64`, `arm64`, `web` | `profiles[].platform` |

### Beispiel-Templates

```
{project}_{date}_{os}_{type}
→ MeinSpiel_20260227_Win_debug

{project}_{godot_version}_{type}
→ MeinSpiel_4.6_debug

{project}_v{godot_version}_{date}_{os}_{platform}_{type}
→ MeinSpiel_v4.6_20260227_Win_x86_64_debug

{project}_{type}
→ MeinSpiel_debug
```

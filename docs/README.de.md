# Godot Export Builder

**Unified Windows Batch Script for Godot Game Builds**

## Inhaltsverzeichnis

- [Überblick](#überblick)
- [Funktionen](#funktionen)
- [Voraussetzungen](#voraussetzungen)
- [Installation & Konfiguration](#installation--konfiguration)
- [Verwendung](#verwendung)
- [Konfigurierbare Parameter](#konfigurierbare-parameter)
- [Fehlerbehandlung](#fehlerbehandlung)
- [Konsolidierung der Versionen](#konsolidierung-der-versionen)
- [FAQ](#faq)

---

## Überblick

Die `export_godot.bat` ist ein konsolidiertes Windows Batch-Skript für die automatisierte Erstellung von exportierten Godot-Spielen. Es kombiniert die Funktionalität von drei separaten Versionen:

- **cli.cmd** (Godot 4.3-rc3)
- **cli_work.cmd** (Godot 4.4-dev6)
- **cli_work_44b4.bat** (Godot 4.4-beta4) ← **Neueste Features**

Das Skript ermöglicht einen einfachen, wartbaren Workflow mit minimaler Konfiguration.

---

## Funktionen

✅ **Mehrere Godot-Versionen unterstützt**
- Einfaches Wechseln zwischen Godot 4.3-rc3, 4.4-dev6 und 4.4-beta4
- Nur eine Zeile ändern zum Aktivieren einer anderen Version

✅ **Intelligente Validierung**
- Prüft auf Godot Engine-Installation
- Prüft auf gültiges Godot-Projekt (`project.godot`)
- Prüft auf Export-Verzeichnisse

✅ **Automatische Ordnererstellung**
- Erstellt fehlende Export-Verzeichnisse automatisch
- Keine manuellen Vorbereitungen nötig

✅ **Dynamische Pfadgenerierung**
- Erzeugt Exportpfade automatisch basierend auf Godot-Version
- Strukturierte Ablage: `export/[Version]/[Projektname]/`

✅ **Detaillierte Logging**
- Umfangreiche Log-Datei: `[Projektname]_export.log.txt`
- Aussagekräftige Konsolen-Ausgabe mit Statusmeldungen

✅ **Optionale Ausführung**
- Nach erfolgreichem Export: Spielen oder Abbrechen

---

## Voraussetzungen

1. **Windows** (Batch-Skript nur für Windows)
2. **Godot Engine** installiert (mindestens eine der folgenden Versionen):
   - 4.3-rc3
   - 4.4-dev6
   - 4.4-beta4
3. **Gültiges Godot-Projekt** mit `project.godot`-Datei
4. **Export-Konfiguration** in `export_presets.cfg` (oder automatisch erstellt)

---

## Installation & Konfiguration

### 1. Skript herunterladen
Platziere `export_godot.bat` im Root-Verzeichnis deines Godot-Projekts.

### 2. Godot-Version konfigurieren
Öffne `export_godot.bat` im Editor und suche den Abschnitt **"CONFIGURATION"**:

```batch
:: ===== GODOT 4.4-beta4 (DEFAULT - LATEST) =====
set "gdpath=C:\Proggen\Godot\Godot_v4.4-beta"
set "godotexe=Godot_v4.4-beta4_win64.exe"
set "godotver=Godot_v4.4-beta4_win64.exe --version"
set "build_version=_alpha9"
```

Passe an:
- `gdpath`: Pfad zu deiner Godot-Installation
- `godotexe`: Genaue Exe-Dateiname deiner Installation
- `build_version`: Versionssuffix für die Binary (z.B. `_v1.0`, `_beta1`)

### 3. Common Variables anpassen (optional)
```batch
set "build_profile=Windows"           # Export-Profil
set "build_type=export-release"      # Debug/Release/Pack
set "build_project_name=MiniShooterGame"  # Projektname
```

### 4. Speichern und bereit!
Das Skript ist einsatzbereit.

---

## Verwendung

### Einfaches Starten
```batch
export_godot.bat
```

Das Skript wird dann:
1. ✓ Godot-Installation überprüfen
2. ✓ Projekt-Datei überprüfen
3. ✓ Export-Ordner (ggf. erstellen)
4. ✓ Alte Exporte löschen (falls vorhanden)
5. ✓ Assets importieren
6. ✓ Spiel exportieren
7. ✓ Ergebnis überprüfen und optional ausführen

### Log-Datei
Alle Ausgaben werden in folgende Datei geschrieben:
```
[build_folder]/MiniShooterGame_export.log.txt
```

### Bei Problemen
1. Überprüfe die Log-Datei auf Fehler
2. Prüfe, ob die Godot-Installation korrekt konfiguriert ist
3. Stellen Sie sicher, dass `project.godot` im Verzeichnis existiert

---

## Konfigurierbare Parameter

| Parameter | Standard | Beschreibung |
|-----------|----------|-------------|
| `gdpath` | `C:\Proggen\Godot\Godot_v4.4-beta` | Pfad zur Godot-Installation |
| `godotexe` | `Godot_v4.4-beta4_win64.exe` | Name der Godot-Ausführungsdatei |
| `build_profile` | `Windows` | Export-Profil aus `export_presets.cfg` |
| `build_type` | `export-release` | `export-debug`, `export-release`, oder `export-pack` |
| `build_version` | `_alpha9` | Versionssuffix für die finale Binary |
| `build_project_name` | `MiniShooterGame` | Name des Projekts (für Pfade & Dateien) |
| `project` | `%~dp0` | Pfad zum Godot-Projekt (automatisch) |

---

## Fehlerbehandlung

Das Skript überprüft automatisch:

| Fehler | Prüfung | Lösung |
|--------|---------|---------|
| **Engine nicht gefunden** | Prüft auf `%build_godot%` | Passe `gdpath` und `godotexe` an |
| **Projekt nicht gefunden** | Sucht nach `project.godot` | Platziere `export_godot.bat` im Projekt-Verzeichnis |
| **Export-Ordner nicht vorhanden** | Prüft auf Verzeichnis | Wird automatisch erstellt |
| **Export fehlgeschlagen** | Vergleicht Binary nach Export | Überprüfe Log-Datei auf Godot-Fehler |

### Fehlercodes

- `0` = Erfolg
- `-1` = Validierungsfehler (Engine, Projekt oder Ordner)
- `-99` = Kritischer Fehler in Subroutine

---

## Konsolidierung der Versionen

Dieses Skript konsolidiert die Funktionalität von drei separaten Versionen:

| Version | Originaldatei | Features | Status |
|---------|---------------|----------|--------|
| 4.3-rc3 | `cli.cmd` | Basis-Build | ✓ Unterstützt |
| 4.4-dev6 | `cli_work.cmd` | Erweiterungen | ✓ Unterstützt |
| 4.4-beta4 | `cli_work_44b4.bat` | Dynamische Pfade, Auto-Ordner | ✓ Basis (neueste) |

**Neue Features aus Beta4 Version:**
- Automatische Ordnererstellung
- Dynamische Exportpfad-Generierung
- Bessere Versionsverwaltung
- Verbesserte Log-Benennung

---

## FAQ

### F: Wie wechsle ich die Godot-Version?
A: Öffne `export_godot.bat`, gehe zum Abschnitt "CONFIGURATION" und kommentiere deine gewünschte Version aus/ein.
```batch
REM set "gdpath=C:\...\Godot_v4.4-beta"      # Auskommentiert
set "gdpath=C:\...\Godot_v4.3-rc"            # Einkommentiert
```

### F: Kann ich mehrere Projekte mit diesem Skript bauen?
A: Ja! Ändere einfach `build_project_name`. Das Skript erstellt dann entsprechende Ordnerstrukturen.

### F: Was ist der Unterschied zwischen export-debug und export-release?
A: 
- `export-debug`: Enthält Debug-Informationen, größer, voll debugbar
- `export-release`: Optimiert, schneller, für Endnutzer

### F: Wo finde ich die exportierte Binary?
A: Im Ordner `%build_folder%`:
```
C:\Proggen\Godot\Projekte\export\[Version]\[Projektname]\Windows\[Binary]
```

### F: Das alte Skript `cli.cmd` wird nicht mehr benötigt?
A: Nein, `export_godot.bat` ersetzt alle drei Versionen. Die alten Dateien können als Backup behalten werden.

### F: Kann ich Custom-Pfade verwenden?
A: Ja, ändere die Variablen im Abschnitt "COMMON VARIABLES". Das Skript ist flexible genug für beliebige Projektstrukturen.

---

## Lizenz

Verwendbar unter den gleichen Bedingungen wie die Godot Engine.

---

**Fragen?** Überprüfe die Log-Datei oder konsultiere die Godot-Export-Dokumentation.

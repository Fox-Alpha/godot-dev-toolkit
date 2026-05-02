# Fehlerbehebung — godot-export-builder

## Häufige Probleme

### `jq: command not found`

`jq` ist nicht installiert — wird zum Parsen der JSON-Konfiguration benötigt.

```bash
# Debian/Ubuntu
sudo apt install jq

# macOS
brew install jq
```

---

### Godot-Versionsnichtübereinstimmung

**Fehlermeldung:**
```
[ERROR] Godot-Versionsnichtübereinstimmung!
[ERROR]   Erwartet: 4.6
[ERROR]   Erhalten: 4.5
```

**Aktuelle Version prüfen:**
```bash
godot --version
# oder falls als gd4:
gd4 --version
```

**Lösung:** `build_config.json` anpassen:
```json
{ "godot": { "version": "4.5" } }
```

Oder `godot.version` weglassen — dann wird die Versionsprüfung übersprungen.

---

### `project.godot nicht gefunden`

Das Script konnte das Godot-Projektverzeichnis nicht lokalisieren.

**Speicherort prüfen:**
```bash
find . -name "project.godot"
```

**Lösung:** Script aus dem Projektverzeichnis oder einem Unterverzeichnis ausführen. Das Script sucht rekursiv nach oben.

---

### Godot-Executable nicht gefunden

**Fehlermeldung:**
```
[ERROR] Godot-Executable nicht gefunden unter: gd4
```

**Lösung 1:** Godot-Pfad explizit in `build_config.json` setzen:
```json
{ "godot": { "path": "/usr/local/bin/godot" } }
```

**Lösung 2:** Godot-Binary als `godot` oder `gd4` in PATH verfügbar machen:
```bash
which godot    # oder
which gd4
```

---

### Export schlägt fehl ohne klare Fehlermeldung

Das Export-Log enthält die vollständige Godot-Ausgabe:

```bash
cat .exports/Linux/MeinSpiel_export.log.txt
```

Häufige Ursachen:
- Export-Template für die Zielplattform nicht installiert (Editor → Export → Templates installieren)
- Profilname in `build_config.json` stimmt nicht mit `export_presets.cfg` überein
- Godot-Editor muss für den ersten Import geöffnet sein

---

### Linux-Binary nicht ausführbar

Das Script setzt die Executable-Berechtigung automatisch. Falls nötig manuell:

```bash
chmod +x .exports/Linux/spiel_name.x86_64
```

---

### Export-Template nicht gefunden

**Godot-Editor öffnen:**
1. Editor → Export (`Ctrl+Alt+E`)
2. „Manage Export Templates" → Templates für die gewünschte Plattform herunterladen

---

## FAQ

**F: Kann ich das Script aus einem übergeordneten Verzeichnis ausführen?**  
A: Ja. Das Script sucht nach `project.godot` aufwärts in der Verzeichnishierarchie.

**F: Was passiert, wenn ich `godot.version` weglasse?**  
A: Die Versionsprüfung wird übersprungen. Das Script funktioniert trotzdem.

**F: Wie ändere ich das Export-Verzeichnis?**  
A: `build.export_root` (global) oder `profiles[].export_path` (pro Profil).

**F: Kann ich dasselbe Profil mit Debug und Release exportieren?**  
A: Ja — zwei Einträge mit gleichem `name`, aber unterschiedlichem `type`.

**F: Welche Dateierweiterungen werden automatisch hinzugefügt?**  
A: Windows → `.exe`, Linux → `.x86_64`, Web → keine (Verzeichnis).

**F: Wie füge ich das Datum in Dateinamen ein?**  
A: Platzhalter `{date}` in `output_filename`. Format: `YYYYMMDD`.

**F: Kann ich das Datumsformat anpassen?**  
A: Nein, aktuell ist `YYYYMMDD` fest. Geplant für zukünftige Versionen.

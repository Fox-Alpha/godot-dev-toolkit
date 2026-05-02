# Verwendung — godot-changelog-generator

Erweiterte Beispiele und Ausgabe-Format für `generate_changelog.sh`.

## Commit-Typen und Sortierung

Commits werden innerhalb eines Datums nach folgendem Schema sortiert (entsprechend dem [Git Styleguide](https://github.com/Fox-Alpha/godot-dev-toolkit/blob/development/.github/instructions/git.instructions.md)):

`Add` → `Fix` → `Upd` → `Chg` → `Del` → `Docs` → `Ref` → `Mve` → `Rem` → `Ren` → sonstige

Commits ohne erkannten Typ erscheinen am Ende jedes Datumsblocks.

## Beispiele

### 1. Gesamtes Repository (kein Argument)

```bash
cd <projektverzeichnis>
bash generate_changelog.sh
```

Erzeugt: `docs/CHANGELOG.md` mit allen Commits des Repos.

---

### 2. Nur ein Unterverzeichnis

```bash
bash generate_changelog.sh -p src/player/
```

Erzeugt: `docs/CHANGELOG_player.md` mit allen Commits, die Dateien in `src/player/` betreffen.

---

### 3. Nur eine bestimmte Datei

```bash
bash generate_changelog.sh -p src/player/player.gd
```

Erzeugt: `docs/CHANGELOG_player.md` mit allen Commits, die `player.gd` betreffen.

---

### 4. Benutzerdefinierter Ausgabepfad

```bash
bash generate_changelog.sh -o releases/CHANGELOG_v1.0.md
```

Der Titel wird automatisch auf `<Repo-Name> (<Branch>)` gesetzt.

---

### 5. Bestimmter Branch

```bash
bash generate_changelog.sh -b development -o docs/CHANGELOG_dev.md
```

---

### 6. Commits in einem Zeitraum

```bash
bash generate_changelog.sh -s 2026-01-01 -u 2026-03-31 -o docs/CHANGELOG_Q1.md
```

---

### 7. Commits zwischen zwei Tags

```bash
bash generate_changelog.sh --since v1.0.0 --until v1.1.0 -o docs/CHANGELOG_v1.1.md
```

---

### 8. Benutzerdefinierter Titel

```bash
bash generate_changelog.sh -t "Release v2.0" -o docs/CHANGELOG_v2.0.md
```

Erzeugt eine Datei mit `# Release v2.0` als Überschrift.

---

### 9. Verzeichnis + Branch + benutzerdefinierter Ausgabepfad

```bash
bash generate_changelog.sh -p src/player/ -b development -o docs/changelogs/player_history.md
```

Das Ausgabeverzeichnis wird automatisch angelegt, falls es noch nicht existiert.

---

## Ausgabe-Format

```markdown
# godot-changelog-generator (main)

Die folgenden Einträge wurden automatisch aus der Git-Historie generiert. Die Reihenfolge
der Typen ist Add → Fix → Upd → Chg → Del → Docs → Ref → Mve → Rem → Ren → sonstige.

## 2026-04-19

- Add: initial player movement system [a1b2c3d](https://github.com/owner/repo/commit/a1b2c3d)
- Fix: collision not detected on steep slopes [d4e5f6a](...)
- Upd: rework jump parameters for Godot 4.3 [...]
- Chg: increase default speed from 200 to 250 [...]
```

Commit-Links werden automatisch generiert, wenn eine Remote-URL konfiguriert ist
(`git remote get-url origin`). Unterstützt GitHub und GitLab.

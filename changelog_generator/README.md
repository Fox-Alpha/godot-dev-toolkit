# generate_changelog.sh

Bash-Script zur automatischen Generierung eines Markdown-Changelogs aus der Git-Historie.  
Die Commits werden nach Datum gruppiert und innerhalb jedes Datums nach Typ sortiert.

## Voraussetzungen

- Bash
- Python 3
- Git-Repository (das Script muss innerhalb eines Repos ausgeführt werden)

## Usage

```bash
./generate_changelog.sh [OPTIONEN]
```

### Optionen

| Option | Kurzform | Beschreibung | Standard |
|---|---|---|---|
| `--path <Pfad>` | `-p` | Datei oder Verzeichnis filtern. `-` steht als Platzhalter für das gesamte Repo. | *(kein Filter — gesamtes Repo)* |
| `--output <Datei>` | `-o` | Ausgabepfad für die generierte Markdown-Datei. | Abhängig von `--path` — siehe Tabelle unten |
| `--branch <Ref>` | `-b` | Nur Commits auf diesem Branch oder Tag berücksichtigen. | *(aktueller Branch)* |
| `--since <Ref>` | `-s` | Nur Commits nach diesem Datum (`2026-01-01`) oder ab diesem Tag (`v1.0.0`). | *(kein Filter)* |
| `--until <Ref>` | `-u` | Nur Commits bis zu diesem Datum oder Tag. | *(kein Filter)* |
| `--title <Titel>` | `-t` | Überschrift in der Ausgabedatei. | Repo-Name + Branch (kein `--path`), sonst Pfad |
| `--help` | `-h` | Hilfe anzeigen und beenden. | — |

### Standard-Ausgabepfade

| Aufruf | Ausgabepfad |
|---|---|
| Kein Argument | `<repo-root>/docs/CHANGELOG.md` |
| `--path -` | `<repo-root>/docs/CHANGELOG.md` |
| `--path foo/` | `<repo-root>/docs/CHANGELOG_foo.md` |
| `--path bar.sh` | `<repo-root>/docs/CHANGELOG_bar.md` |

> Der Ausgabepfad ist immer relativ zum **Repository-Root** (`git rev-parse --show-toplevel`), unabhängig vom Aufrufverzeichnis. Bei `--output` wird der angegebene Pfad unverändert verwendet.

## Commit-Typen und Sortierung

Die Ausgabe sortiert Commits innerhalb eines Datums nach folgendem Schema (entsprechend dem [Git Styleguide](https://github.com/Fox-Alpha/godot-dev-toolkit/blob/development/.github/instructions/git.instructions.md)):

`Add` → `Fix` → `Upd` → `Chg` → `Del` → `Docs` → `Ref` → `Mve` → `Rem` → `Ren` → sonstige

Commits, die keinem dieser Typen zugeordnet werden können, erscheinen am Ende jedes Datumsblocks.

## Beispiele

### 1. Gesamtes Repository (kein Argument)

```bash
cd /mein/projekt
bash tools/generate_changelog.sh
```

Erzeugt: `../docs/CHANGELOG.md` mit allen Commits des Repos.

---

### 2. Nur ein Unterverzeichnis

```bash
cd /mein/projekt
bash tools/generate_changelog.sh -p src/player/
```

Erzeugt: `../docs/CHANGELOG_player.md` mit allen Commits, die Dateien in `src/player/` betreffen.

---

### 3. Nur eine bestimmte Datei

```bash
cd /mein/projekt
bash tools/generate_changelog.sh -p src/player/player.gd
```

Erzeugt: `../docs/CHANGELOG_player.md` mit allen Commits, die `player.gd` betreffen.

---

### 4. Gesamtes Repository mit benutzerdefiniertem Ausgabepfad

```bash
cd /mein/projekt
bash tools/generate_changelog.sh -o releases/CHANGELOG_v1.0.md
```

Erzeugt: `releases/CHANGELOG_v1.0.md` — Titel wird automatisch auf `<Repo-Name> (<Branch>)` gesetzt.

---

### 5. Nur einen bestimmten Branch

```bash
cd /mein/projekt
bash tools/generate_changelog.sh -b development -o docs/CHANGELOG_dev.md
```

---

### 6. Commits in einem Zeitraum

```bash
cd /mein/projekt
bash tools/generate_changelog.sh -s 2026-01-01 -u 2026-03-31 -o docs/CHANGELOG_Q1.md
```

---

### 7. Commits zwischen zwei Tags

```bash
cd /mein/projekt
bash tools/generate_changelog.sh --since v1.0.0 --until v1.1.0 -o docs/CHANGELOG_v1.1.md
```

---

### 8. Benutzerdefinierter Titel

```bash
cd /mein/projekt
bash tools/generate_changelog.sh -t "Release v2.0" -o docs/CHANGELOG_v2.0.md
```

Erzeugt eine Datei mit `# Release v2.0` als Überschrift.

---

### 9. Verzeichnis gefiltert auf Branch mit benutzerdefiniertem Ausgabepfad

```bash
cd /mein/projekt
bash tools/generate_changelog.sh -p src/player/ -b development -o docs/changelogs/player_history.md
```

Das Verzeichnis wird automatisch angelegt, falls es noch nicht existiert.

## Ausgabe-Format

```markdown
# Changelog für src/player/

Die folgenden Einträge wurden automatisch aus der Git-Historie generiert. ...

## 2026-04-19

- Add: initial player movement system [a1b2c3d](https://github.com/.../commit/a1b2c3d)
- Fix: collision not detected on steep slopes [d4e5f6a](...)
- Upd: rework jump parameters for Godot 4.3 [...]
- Chg: increase default speed from 200 to 250 [...]
```

Links zu Commits werden automatisch generiert, wenn eine Remote-URL konfiguriert ist (`git remote get-url origin`).

---

## Part of godot-dev-toolkit

Dieses Tool ist Teil des [godot-dev-toolkit](https://github.com/Fox-Alpha/godot-dev-toolkit) Hubs — einer Sammlung von Godot-Entwicklungstools.

> **Hinweis:** Ein C#/Avalonia-Port ist optional für die Zukunft geplant, aber aktuell nicht priorisiert.

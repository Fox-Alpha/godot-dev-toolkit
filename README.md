# godot-changelog-generator

Bash-Script zur automatischen Generierung eines Markdown-Changelogs aus der Git-Historie.
Commits werden nach Datum gruppiert und innerhalb jedes Datums nach Typ sortiert.

## Features

- Filterung nach Datei, Verzeichnis oder gesamtem Repository
- Filterung nach Branch, Datum oder Tag
- Automatische Commit-Link-Generierung (GitHub, GitLab)
- Sortierung nach Commit-Typ (Add → Fix → Upd → ...)
- Ausgabepfad automatisch aus Pfad-Argument abgeleitet

## Voraussetzungen

- Bash
- Python 3
- Git-Repository (Script muss innerhalb eines Repos ausgeführt werden)

## Installation

```bash
# Repository klonen oder Script herunterladen
chmod +x generate_changelog.sh
```

## Verwendung

```bash
./generate_changelog.sh [OPTIONEN]
```

| Option | Kurzform | Beschreibung | Standard |
|---|---|---|---|
| `--path <Pfad>` | `-p` | Datei oder Verzeichnis filtern. `-` = gesamtes Repo. | *(gesamtes Repo)* |
| `--output <Datei>` | `-o` | Ausgabepfad für die Markdown-Datei. | Abgeleitet aus `--path` |
| `--branch <Ref>` | `-b` | Nur Commits auf diesem Branch oder Tag. | *(aktueller Branch)* |
| `--since <Ref>` | `-s` | Commits nach Datum (`2026-01-01`) oder ab Tag (`v1.0.0`). | *(kein Filter)* |
| `--until <Ref>` | `-u` | Commits bis zu Datum oder Tag. | *(kein Filter)* |
| `--title <Titel>` | `-t` | Überschrift in der Ausgabedatei. | Repo-Name + Branch |
| `--help` | `-h` | Hilfe anzeigen. | — |

**Standard-Ausgabepfade:**

| Aufruf | Ausgabepfad |
|---|---|
| Kein Argument | `<repo-root>/docs/CHANGELOG.md` |
| `--path foo/` | `<repo-root>/docs/CHANGELOG_foo.md` |
| `--path bar.sh` | `<repo-root>/docs/CHANGELOG_bar.md` |

> Der Ausgabepfad ist immer relativ zum Repository-Root, unabhängig vom Aufrufverzeichnis.

## Dokumentation

- [Erweiterte Beispiele und Ausgabe-Format](docs/usage.md)

## Part of godot-dev-toolkit

Dieses Tool ist Teil des [godot-dev-toolkit](https://github.com/Fox-Alpha/godot-dev-toolkit) Hubs.

> Ein C#/Avalonia-Port ist optional für die Zukunft geplant, aber aktuell nicht priorisiert.

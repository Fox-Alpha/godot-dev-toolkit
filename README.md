# godot-dev-toolkit

Hub-Repository für Godot-Entwicklungstools — Hub-and-Spoke-Architektur mit Git Subtrees.

Jedes Tool lebt in einem **eigenen GitHub-Repo** und ist hier per Git Subtree eingebunden. Änderungen können direkt in diesem Hub-Repo gemacht und per `git subtree push` in die jeweiligen Tool-Repos zurückgespielt werden.

---

## Tools

| Tool | Verzeichnis | Repo | Beschreibung |
|---|---|---|---|
| Export Builder | `export_builder/` | [godot-export-builder](https://github.com/Fox-Alpha/godot-export-builder) | Bash-Script für Godot CLI-Exporte |
| Changelog Generator | `changelog_generator/` | [godot-changelog-generator](https://github.com/Fox-Alpha/godot-changelog-generator) | Generiert Markdown-Changelogs aus Git-Historie |
| Export GUI | `py_export_gui/` | [godot-export-gui](https://github.com/Fox-Alpha/godot-export-gui) | Python/PySimpleGUI Export-Oberfläche |
| LSP Bridge | `godot_lsp_bridge/` | [godot-lsp-bridge](https://github.com/Fox-Alpha/godot-lsp-bridge) | Verbindet Copilot mit Godot's GDScript LSP |
| Ollama Tools | `godot_ollama_tools/` | [godot-ollama-tools](https://github.com/Fox-Alpha/godot-ollama-tools) | Lokales Ollama-Toolkit für Godot-Entwicklung |
| AI Instructions | `godot_ai_instructions/` | [godot-ai-instructions](https://github.com/Fox-Alpha/godot-ai-instructions) | Skills, Rules, Styleguides für AI Assistenten |

## Verwandte Repos (kein Subtree)

| Repo | Beschreibung |
|---|---|
| [godot-export-app](https://github.com/Fox-Alpha/godot-export-app) | C#/Avalonia-Port von Export GUI (in Planung) |

## Archiv

- `archive/build_export_win_batch` — Windows Batch Export Script, nicht weiterentwickelt, siehe [Wiki](https://github.com/Fox-Alpha/godot-dev-toolkit/wiki/build-export-win-batch)

---

## Git Subtree Workflow

```bash
# Änderungen aus Tool-Repo in Hub holen:
git subtree pull --prefix=export_builder export-builder main --squash

# Änderungen aus Hub ins Tool-Repo pushen:
git subtree push --prefix=export_builder export-builder main
```

Remotes sind mit Kurzname registriert (`export-builder`, `changelog-gen`, `export-gui`, `lsp-bridge`, `ollama-tools`, `ai-instructions`).

---

## Dokumentation

→ [Wiki](https://github.com/Fox-Alpha/godot-dev-toolkit/wiki)

Styleguides und AI-Instructions: `.github/instructions/`

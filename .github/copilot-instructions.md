# Copilot Instructions

## Language

Always communicate in **German** — in responses, explanations, code comments, and clarifying questions. Exceptions: code, identifiers, commit messages, and established technical terms stay in English.

## User Context

- **Primary languages**: C# / .NET (experienced), Powershell, GDScript / Godot (preferred for game projects), plus broad scripting knowledge (PHP, Lua, VBScript/VBA, Python, Bash, and others)
- **Main project types**: game development and tooling
- **Background**: experienced developer with exposure to many languages and paradigms — no need to explain basic programming concepts

## Communication Style

- Address the user informally (**"du"**)
- Keep responses **concise but complete** — explain where it adds value, skip obvious filler
- When introducing a concept or technology that may be unfamiliar, briefly explain it without being asked
- Prefer bullet points and short paragraphs over walls of text
- Don't add praise or affirmations before answering ("Great question!", "Sure!" etc.)

## Purpose

This repository is a personal AI tooling template. It serves as a reusable base for future projects and a learning resource for working effectively with AI assistants (Copilot, Claude, Cursor, etc.).

## Repository Goals

- Collect and refine **best practices** for AI-assisted development
- Provide **starter files** that can be copied into new projects (rules, styleguides, agent configs, commands, skills)
- Document **patterns** for interacting with AI tools across different contexts

## Expected Structure

```
.github/
  copilot-instructions.md   ← this file
agents/
  AGENTS.md                 ← instructions for agentic AI sessions (Jules, OpenCode, etc.)
rules/
  <tool>.md or <tool>/      ← tool-specific rules (e.g. cursor.md, aider.md)
skills/
  <skill-name>.md           ← reusable skill definitions
commands/
  <command-name>.md         ← custom slash commands or prompt templates
styleguides/
  <language-or-domain>.md   ← coding conventions per language or domain
```

> This structure is a convention, not enforced by tooling. Add, rename, or merge directories as the project evolves. **Directories are created incrementally** — only add a directory when the first file for it is needed.

## File Conventions

- **Markdown only** — all template files are `.md`
- **Frontmatter** (optional) — YAML block at the top of a file, enclosed in `---` delimiters. Use it to tag files with metadata that aids discoverability (e.g. which tool, language, or category a file belongs to). Not required, but useful when the repository grows.

  ```yaml
  ---
  tool: cursor
  language: gdscript
  category: rules
  ---
  ```

  Supported fields (all optional):
  | Field | Purpose | Examples |
  |---|---|---|
  | `tool` | Target AI tool | `copilot`, `cursor`, `aider`, `claude` |
  | `language` | Programming language | `csharp`, `gdscript`, `python` |
  | `category` | File type | `rules`, `styleguide`, `skill`, `command` |

- **Self-contained** — each file should be usable standalone when dropped into a target project
- **Prescriptive, not descriptive** — write instructions that tell an AI *what to do*, not just what the project is about

## Writing Effective AI Instructions

- Use imperative language: *"Always use named exports"*, not *"Named exports are preferred"*
- Be specific about exceptions: *"Use default exports only for Next.js pages"*
- Keep rules atomic — one rule per bullet where possible
- Avoid restating things any competent developer already knows
- Test instructions by actually using them in a session and iterating

## Git Workflow

See [`styleguides/git.md`](../styleguides/git.md) for branch strategy, commit message format, and workflow examples.

### Key rules at a glance

- Default working branch: `development` — never commit directly to `master`
- Each session: create a `feature/<name>` branch from `development`, delete it after merging
- **Never merge autonomously** — always wait for explicit approval
- Commit in small, atomic steps

## Session Behavior

### Session Start

At the beginning of every session:
1. Enable **plan mode** if the model or tool supports it
2. Check the current Git status (`git status`, current branch, uncommitted changes) and report it briefly
3. Create a new `feature/<name>` branch from `development` if not already on one
4. Ask for clarification if the task or scope is unclear before doing anything

### During a Session

- Before implementing anything, briefly describe the planned approach and wait for confirmation
- Commit progress in small steps after each logical change — do not batch everything into one final commit
- If a task turns out to be larger than expected, pause and re-confirm scope before continuing

### Session End

When wrapping up a session, always provide a short summary:
- What was changed (files, commits)
- What is still open or unfinished
- Suggested next steps

## Project Structure

These rules apply when starting a new project in an empty repository.

### Naming Conventions

- **Root-level meta files** use **UPPERCASE** names with lowercase extension — these are recognized and highlighted by GitHub/GitLab (e.g. `README.md`, `CHANGELOG.md`, `CONTRIBUTING.md`, `AGENTS.md`)
- **All other files and directories** use **lowercase** names with **underscores** instead of spaces (e.g. `style_guide.md`, `user_auth/`)
- No camelCase or PascalCase for file or folder names

### Standard Directory Layout

```
<project-root>/
  src/              ← all source code
  docs/             ← project documentation
    style_guide.md  ← coding style and conventions for this project
  tests/            ← test suite (ask before creating if not yet present)
  README.md         ← project overview, setup instructions, usage
```

### Rules

- Always create a `src/` directory for source code at project start
- Always create a `docs/` directory with a `style_guide.md` at project start
- Always create a `README.md` in the repository root at project start
- Before creating a `tests/` directory, ask if one is needed — place it in the repository root if yes
- Before adding further files to `docs/` (e.g. `architecture.md`, `api.md`), ask which documentation files are needed
- Never place source code directly in the repository root

## Autonomy & Decision Making

- Always ask before creating new files, directories, or making structural/architectural changes
- For small, clearly scoped changes, proceed directly without asking
- If a better solution or alternative is spotted during implementation, briefly mention it and give a recommendation — but do not implement it without confirmation
- If an unrelated bug or problem is discovered while working, report it immediately and suggest a fix — do not silently fix it
- Never make assumptions about ambiguous requirements; ask instead

## Adapting Files for a Target Project

When copying a template file into a real project:
1. Remove placeholder sections that don't apply
2. Replace example paths/names with real ones
3. Add project-specific context (tech stack, constraints, team conventions)

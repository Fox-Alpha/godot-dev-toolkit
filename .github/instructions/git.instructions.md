---
category: styleguide
language: any
tool: git
---

# Git Style Guide

> **For AI models:** Read this file completely before making any commits or merges.
> The commit type table and atomic commit rule are mandatory — not optional suggestions.

---

## Commit Messages

### Format

```
<Type>: <short description>
```

- Written in **English**
- Short description is imperative, lowercase after the colon
- **One logical change per commit — never batch unrelated changes into one commit**
  -- commit often and short changes
- **This project uses its own commit types (see below) — never use Conventional Commits (`feat:`, `chore:`, `fix:` etc.)**

### Types

| Type | Meaning |
|---|---|
| `Add:` | New files or features |
| `Chg:` | Small changes (e.g. values, flags, minor adjustments) |
| `Ref:` | Refactoring (no functional change) |
| `Fix:` | Bug fixes |
| `Upd:` | Updates / changes to existing code |
| `Del:` | Deletion of code or logic |
| `Docs:` | Documentation changes |
| `Mve:` | File moves |
| `Rem:` | File deletions |
| `Ren:` | Renames |

### Examples

```
Add: player inventory system
Fix: collision not detected on steep slopes
Upd: increase jump force from 400 to 500
Docs: add setup instructions to README
Ref: extract damage calculation into separate function
```

### Merge Commits

Merge commits use the `Merge:` prefix and describe what was merged and why:

```
Merge: <feature description>

- bullet summary of what the feature contains

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>
```

Example:
```
Merge: phase 2 world and terrain system

- isometric TileMap with terrain atlas
- procedural map generation (threaded)
- SQLite persistence via WorldDB
- camera with WASD and zoom

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>
```

---

## Branches

| Branch | Purpose |
|---|---|
| `master` | Stable, reviewed releases only — **never commit directly** |
| `development` | Ongoing development — default working branch |
| `feature/<name>` | Short-lived branches per session/feature — always branch off `development` |

### Rules
- First step, look if the working directory is a git repository
  - if not, initialize with **master** branch.
  - if there are files, make a initial commit to master. Commit in small, atomic steps.
  - Then create the development branch and checkout for further working
- At the start of each session, create a new `feature/<name>` branch from `development`
- Delete feature branches after merging into `development`
- **Never merge into `development` or `master` autonomously** — always wait for explicit approval
- Merges into `master` happen **only on explicit instruction** and only when the state is complete and error-free
- Releases on `master` are marked with a **version tag** (e.g. `v0.1.0`, `v1.0.0`)

### Workflows

#### Standard development

```bash
git checkout development
git pull origin development
git checkout -b feature/my-feature

# ... make changes, commit using types above ...

git checkout development
git merge --no-ff feature/my-feature -m "Merge: ..."
git branch -d feature/my-feature
```

#### Create a release

```bash
git checkout master
git merge development
git tag -a v1.0.0 -m "Release version 1.0.0" ## Ask for Version Tag
git push origin master --tags
git checkout development
```


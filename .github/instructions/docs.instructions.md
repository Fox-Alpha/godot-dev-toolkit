---
applyTo: "docs/**/*"
category: rules
tool: copilot
---

# docs — Documentation

## CHANGELOG.md

- `docs/CHANGELOG.md` is auto-generated from the Git history — do not edit manually
- Regenerate using the changelog tool:
> Symbolic link exists as gitchggen
  ```bash
  bash tools/generate_changelog.sh
  ```
- Run this at the end of every session and before every merge
- Commit the result as a separate `Docs:` commit or include it in the merge commit
- The skill `skills/changelog-generator.md` documents all available options (branch filter, date range, path filter)

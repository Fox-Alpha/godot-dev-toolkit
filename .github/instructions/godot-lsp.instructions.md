---
category: rules
tool: copilot
language: gdscript
---

# Godot LSP Bridge — Usage Rules

The Godot LSP Bridge connects GitHub Copilot to Godot's GDScript Language Server via stdio ↔ TCP.
Use the LSP tool actively when working with GDScript — do not rely on static text analysis alone.

## When to use the LSP tool

| Situation | Operation |
|---|---|
| Unknown method/property signature | `hover` |
| Does this class/autoload exist in the project? | `workspaceSymbol` |
| Where is this function/variable defined? | `goToDefinition` |
| Which files/lines use this symbol? | `findReferences` |
| What members does this type expose? | `documentSymbol` or `completion` |
| Rename a symbol across the project | `rename` |
| What functions does this call / what calls this? | `outgoingCalls` / `incomingCalls` |

Use LSP proactively — especially before writing code that touches Godot built-in APIs or autoloads.
The LSP reflects the **running engine version**, not training data.

## When LSP is not needed

- Trivial edits (comments, string changes, formatting)
- Files outside `.gd`, `.tscn`, `.tres`
- When the symbol is already visible in the current file context

## Diagnostics

Godot sends `textDocument/publishDiagnostics` automatically after each file open.
If diagnostics contain errors, address them before suggesting further edits.
Common false positives: autoloads from other projects loaded into the test project.

## Setup

### Bridge binary

The bridge is installed as a single native binary (NativeAOT, no runtime dependencies):

```
/home/buckdi/Projekte/godot/godot_tools/bin/godot-lsp-bridge
~/.local/bin/godot-lsp-bridge  ← symlink, available in PATH
```

Rebuild after source changes:
```bash
cd godot_lsp_bridge
dotnet publish -r linux-x64 -c Release
cp bin/Release/net10.0/linux-x64/publish/godot-lsp-bridge \
   /home/buckdi/Projekte/godot/godot_tools/bin/godot-lsp-bridge
```

### lsp.json (repo-level)

Located at `.github/lsp.json`. The `rootUri` is relative to the Git root.

```json
{
  "lspServers": {
    "godot": {
      "command": "godot-lsp-bridge",
      "args": [],
      "env": {
        "GODOT_LSP_BRIDGE_DEBUG": "true"
      },
      "fileExtensions": {
        ".gd": "GDScript",
        ".tscn": "GD Scene",
        ".tres": "GD Text Resource"
      },
      "rootUri": "."
    }
  }
}
```

For monorepos where the Godot project is a subdirectory, set `rootUri` to that path
(e.g. `"godot_lsp_bridge/minimum-lsp-project/"`).

### lsp.json (global)

For a global config at `~/.copilot/lsp.json` that works across all Godot projects,
use `"rootUri": "."` — Copilot resolves it against the Git root of the active workspace.

### Environment variables

| Variable | Default | Description |
|---|---|---|
| `GODOT_LSP_BRIDGE_DEBUG` | `false` | Write debug log to `GODOT_LSP_BRIDGE_LOG` |
| `GODOT_LSP_BRIDGE_LOG` | `/tmp/godot-lsp-bridge.log` | Log file path |
| `GODOT_LSP_HOST` | `127.0.0.1` | Godot LSP host |
| `GODOT_LSP_PORT` | auto (6005, 6007, 6008) | Fix to a specific port |

`env` in `lsp.json` supports `${VAR}` and `${VAR:-default}` expansion syntax.

## Requirements

- **Godot Editor must be running** with the project open — the LSP server is only active in the editor
- The bridge auto-reconnects if Godot restarts during a session

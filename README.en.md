# Godot Export Builder

**Unified Windows Batch Script for Godot Game Builds**

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Requirements](#requirements)
- [Installation & Configuration](#installation--configuration)
- [Usage](#usage)
- [Configurable Parameters](#configurable-parameters)
- [Error Handling](#error-handling)
- [Consolidation of Versions](#consolidation-of-versions)
- [FAQ](#faq)

---

## Overview

The `export_godot.bat` is a consolidated Windows batch script for automated creation of exported Godot games. It combines the functionality of three separate versions:

- **cli.cmd** (Godot 4.3-rc3)
- **cli_work.cmd** (Godot 4.4-dev6)
- **cli_work_44b4.bat** (Godot 4.4-beta4) ← **Latest Features**

The script enables a simple, maintainable workflow with minimal configuration.

---

## Features

✅ **Multiple Godot Versions Supported**
- Easy switching between Godot 4.3-rc3, 4.4-dev6, and 4.4-beta4
- Change only one line to enable a different version

✅ **Intelligent Validation**
- Checks for Godot Engine installation
- Verifies valid Godot project (`project.godot`)
- Validates export directories

✅ **Automatic Folder Creation**
- Creates missing export directories automatically
- No manual setup required

✅ **Dynamic Path Generation**
- Generates export paths automatically based on Godot version
- Structured storage: `export/[Version]/[ProjectName]/`

✅ **Detailed Logging**
- Comprehensive log file: `[ProjectName]_export.log.txt`
- Informative console output with status messages

✅ **Optional Execution**
- After successful export: Play or abort

---

## Requirements

1. **Windows** (Batch script Windows-only)
2. **Godot Engine** installed (at least one of the following versions):
   - 4.3-rc3
   - 4.4-dev6
   - 4.4-beta4
3. **Valid Godot Project** with `project.godot` file
4. **Export Configuration** in `export_presets.cfg` (or auto-created)

---

## Installation & Configuration

### 1. Download Script
Place `export_godot.bat` in your Godot project root directory.

### 2. Configure Godot Version
Open `export_godot.bat` in an editor and locate the **"CONFIGURATION"** section:

```batch
:: ===== GODOT 4.4-beta4 (DEFAULT - LATEST) =====
set "gdpath=C:\Proggen\Godot\Godot_v4.4-beta"
set "godotexe=Godot_v4.4-beta4_win64.exe"
set "godotver=Godot_v4.4-beta4_win64.exe --version"
set "build_version=_alpha9"
```

Adjust:
- `gdpath`: Path to your Godot installation
- `godotexe`: Exact executable filename of your installation
- `build_version`: Version suffix for the binary (e.g., `_v1.0`, `_beta1`)

### 3. Adjust Common Variables (optional)
```batch
set "build_profile=Windows"           # Export profile
set "build_type=export-release"      # Debug/Release/Pack
set "build_project_name=MiniShooterGame"  # Project name
```

### 4. Save and Ready!
Script is ready to use.

---

## Usage

### Simple Start
```batch
export_godot.bat
```

The script will then:
1. ✓ Verify Godot installation
2. ✓ Verify project file
3. ✓ Create export folders (if needed)
4. ✓ Delete old exports (if present)
5. ✓ Import assets
6. ✓ Export game
7. ✓ Verify result and optionally execute

### Log File
All output is written to:
```
[build_folder]/MiniShooterGame_export.log.txt
```

### If Problems Occur
1. Check log file for errors
2. Verify Godot installation is correctly configured
3. Ensure `project.godot` exists in directory

---

## Configurable Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `gdpath` | `C:\Proggen\Godot\Godot_v4.4-beta` | Path to Godot installation |
| `godotexe` | `Godot_v4.4-beta4_win64.exe` | Name of Godot executable |
| `build_profile` | `Windows` | Export profile from `export_presets.cfg` |
| `build_type` | `export-release` | `export-debug`, `export-release`, or `export-pack` |
| `build_version` | `_alpha9` | Version suffix for final binary |
| `build_project_name` | `MiniShooterGame` | Project name (for paths & files) |
| `project` | `%~dp0` | Path to Godot project (automatic) |

---

## Error Handling

The script automatically checks:

| Error | Check | Solution |
|-------|-------|----------|
| **Engine Not Found** | Checks for `%build_godot%` | Adjust `gdpath` and `godotexe` |
| **Project Not Found** | Searches for `project.godot` | Place `export_godot.bat` in project directory |
| **Export Folder Missing** | Checks for directory | Created automatically |
| **Export Failed** | Compares binary after export | Check log file for Godot errors |

### Error Codes

- `0` = Success
- `-1` = Validation error (engine, project, or folder)
- `-99` = Critical error in subroutine

---

## Consolidation of Versions

This script consolidates the functionality of three separate versions:

| Version | Original File | Features | Status |
|---------|---------------|----------|--------|
| 4.3-rc3 | `cli.cmd` | Basic build | ✓ Supported |
| 4.4-dev6 | `cli_work.cmd` | Extensions | ✓ Supported |
| 4.4-beta4 | `cli_work_44b4.bat` | Dynamic paths, auto-folders | ✓ Base (latest) |

**New Features from Beta4 Version:**
- Automatic folder creation
- Dynamic export path generation
- Improved version management
- Better log file naming

---

## FAQ

### Q: How do I switch Godot versions?
A: Open `export_godot.bat`, go to "CONFIGURATION" section, and uncomment/comment your desired version.
```batch
REM set "gdpath=C:\...\Godot_v4.4-beta"      # Commented out
set "gdpath=C:\...\Godot_v4.3-rc"            # Uncommented
```

### Q: Can I build multiple projects with this script?
A: Yes! Simply change `build_project_name`. The script will create corresponding folder structures.

### Q: What's the difference between export-debug and export-release?
A: 
- `export-debug`: Contains debug info, larger, fully debuggable
- `export-release`: Optimized, faster, for end users

### Q: Where can I find the exported binary?
A: In the `%build_folder%` directory:
```
C:\Proggen\Godot\Projekte\export\[Version]\[ProjectName]\Windows\[Binary]
```

### Q: Do I still need the old script `cli.cmd`?
A: No, `export_godot.bat` replaces all three versions. Old files can be kept as backup.

### Q: Can I use custom paths?
A: Yes, modify the variables in the "COMMON VARIABLES" section. The script is flexible enough for any project structure.

---

## License

Usable under the same terms as the Godot Engine.

---

**Questions?** Check the log file or consult the Godot export documentation.

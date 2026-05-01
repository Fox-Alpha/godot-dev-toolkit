#!/bin/bash
# Generiert ein Markdown-Changelog aus der Git-Historie.

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONEN]

Generiert ein Markdown-Changelog aus der Git-Historie.
Commits werden nach Datum gruppiert und innerhalb eines Datums nach Typ sortiert.

Optionen:
  -p, --path <Pfad>     Datei oder Verzeichnis filtern; '-' steht fuer gesamtes Repo
  -o, --output <Datei>  Ausgabepfad der Markdown-Datei
                        Standard: abhaengig von --path (siehe unten)
  -b, --branch <Ref>    Branch oder Tag (Standard: aktueller Branch)
  -s, --since <Ref>     Commits nach Datum (2026-01-01) oder ab Tag (v1.0.0)
  -u, --until <Ref>     Commits bis Datum oder Tag
  -t, --title <Titel>   Ueberschrift in der Ausgabedatei
                        Standard: Repo-Name + Branch (kein --path), sonst Pfad
  -h, --help            Diese Hilfe anzeigen

Standard-Ausgabepfade:
  Kein --path           <repo-root>/docs/CHANGELOG.md
  --path foo/           <repo-root>/docs/CHANGELOG_foo.md
  --path bar.sh         <repo-root>/docs/CHANGELOG_bar.md

Beispiele:
  $(basename "$0")
  $(basename "$0") -p src/player/ -b development
  $(basename "$0") -s 2026-01-01 -u 2026-03-31 -o docs/CHANGELOG_Q1.md
  $(basename "$0") --since v1.0.0 --until v1.1.0 -o docs/CHANGELOG_v1.1.md
  $(basename "$0") -t "Release v2.0" -o docs/CHANGELOG_v2.0.md
EOF
}

PATH_ARG=""
OUTPUT_ARG=""
BRANCH_ARG=""
SINCE_ARG=""
UNTIL_ARG=""
TITLE_ARG=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -p|--path)   PATH_ARG="$2";   shift 2 ;;
        -o|--output) OUTPUT_ARG="$2"; shift 2 ;;
        -b|--branch) BRANCH_ARG="$2"; shift 2 ;;
        -s|--since)  SINCE_ARG="$2";  shift 2 ;;
        -u|--until)  UNTIL_ARG="$2";  shift 2 ;;
        -t|--title)  TITLE_ARG="$2";  shift 2 ;;
        -h|--help)   usage; exit 0 ;;
        *) echo "Unbekannte Option: $1" >&2; usage >&2; exit 1 ;;
    esac
done

REMOTE=$(git config --get remote.origin.url 2>/dev/null || true)
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
REPO_NAME=$(basename "$REPO_ROOT")
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "")
DOCS_DIR="${REPO_ROOT}/docs"

if [ -d "$PATH_ARG" ]; then
    TARGET_TYPE="dir"
    TARGET="$PATH_ARG"
    DIRNAME=$(basename "${PATH_ARG%/}")
    OUTPUT=${OUTPUT_ARG:-${DOCS_DIR}/CHANGELOG_${DIRNAME}.md}
elif [ -n "$PATH_ARG" ] && [ "$PATH_ARG" != "-" ]; then
    TARGET_TYPE="file"
    TARGET="$PATH_ARG"
    OUTPUT=${OUTPUT_ARG:-${DOCS_DIR}/CHANGELOG_$(basename "${PATH_ARG%.*}").md}
else
    TARGET_TYPE="all"
    TARGET=""
    OUTPUT=${OUTPUT_ARG:-${DOCS_DIR}/CHANGELOG.md}
fi

python3 - "$TARGET_TYPE" "$TARGET" "$OUTPUT" "$REMOTE" "$BRANCH_ARG" "$SINCE_ARG" "$UNTIL_ARG" "$TITLE_ARG" "$REPO_NAME" "$CURRENT_BRANCH" <<'PYTHON'
import sys, subprocess, os, re
target_type    = sys.argv[1]
target         = sys.argv[2]
output         = sys.argv[3]
remote         = sys.argv[4]
branch         = sys.argv[5]
since          = sys.argv[6]
until          = sys.argv[7]
title_arg      = sys.argv[8]
repo_name      = sys.argv[9]
current_branch = sys.argv[10]

cmd = ['git','log','--pretty=format:%ad|%h|%s','--date=short']
if branch:
    cmd += [branch]
if since:
    cmd += [f'--since={since}'] if re.match(r'^\d{4}-\d{2}-\d{2}$', since) else [f'{since}..HEAD']
if until:
    if re.match(r'^\d{4}-\d{2}-\d{2}$', until):
        cmd += [f'--until={until}']
    else:
        cmd = [f'{since}..{until}' if since and not re.match(r'^\d{4}-\d{2}-\d{2}$', since)
               else c for c in cmd]
        if not since or re.match(r'^\d{4}-\d{2}-\d{2}$', since):
            cmd += [until]
if target_type == "dir":
    cmd += ['--', target + '/']
elif target_type == "file":
    cmd += ['--', target]

proc = subprocess.run(cmd, capture_output=True, text=True)
if proc.returncode != 0 or not proc.stdout.strip():
    label = target if target else "das Repository"
    print(f"Keine Git-Einträge für '{label}' gefunden.")
    sys.exit(0)

entries = []
for line in proc.stdout.splitlines():
    parts = line.split('|',2)
    if len(parts) < 3: continue
    entries.append({'date':parts[0],'hash':parts[1],'msg':parts[2]})

# group by date preserving order
from collections import OrderedDict
groups = OrderedDict()
for e in entries:
    groups.setdefault(e['date'], []).append(e)

prefix_order = ['Add','Fix','Upd','Chg','Del','Docs','Ref','Mve','Rem','Ren']

# Determine title
if title_arg:
    title = title_arg
elif target_type == "all":
    br = branch if branch else current_branch
    title = f"{repo_name} ({br})" if br else repo_name
else:
    title = f"Changelog für {target}"

lines = []
lines.append(f"# {title}\n")
lines.append("Die folgenden Einträge wurden automatisch aus der Git-Historie generiert. Die Reihenfolge der Typen ist Add → Fix → Upd → Chg → Del → Docs → Ref → Mve → Rem → Ren → sonstige.\n")

for date, ents in groups.items():
    lines.append(f"## {date}\n")
    for pref in prefix_order:
        for e in ents:
            if e['msg'].startswith(pref + ':') or e['msg'].startswith(pref + ' '):
                msg = e['msg'].replace('===', '\n  - ===')
                link = f" [{e['hash']}]({remote}/commit/{e['hash']})" if remote else f" {e['hash']}"
                lines.append(f"- {msg}{link}\n")
    for e in ents:
        if not re.match(r'^(Add|Fix|Upd|Chg|Del|Docs|Ref|Mve|Rem|Ren)[: ]', e['msg']):
            msg = e['msg'].replace('===', '\n  - ===')
            link = f" [{e['hash']}]({remote}/commit/{e['hash']})" if remote else f" {e['hash']}"
            lines.append(f"- {msg}{link}\n")
    lines.append("\n")

os.makedirs(os.path.dirname(os.path.abspath(output)), exist_ok=True)
with open(output, 'w', encoding='utf-8') as f:
    f.writelines(lines)
print(f"Changelog generiert: {output}")
PYTHON

exit 0


REMOTE=$(git config --get remote.origin.url 2>/dev/null || true)

if [ -d "$PATH_ARG" ]; then
    TARGET_TYPE="dir"
    TARGET="$PATH_ARG"
    DIRNAME=$(basename "${PATH_ARG%/}")
    OUTPUT=${OUTPUT_ARG:-../docs/CHANGELOG_${DIRNAME}.md}
elif [ -n "$PATH_ARG" ] && [ "$PATH_ARG" != "-" ]; then
    TARGET_TYPE="file"
    TARGET="$PATH_ARG"
    OUTPUT=${OUTPUT_ARG:-../docs/CHANGELOG_$(basename "${PATH_ARG%.*}").md}
else
    TARGET_TYPE="all"
    TARGET=""
    OUTPUT=${OUTPUT_ARG:-../docs/CHANGELOG.md}
fi

python3 - "$TARGET_TYPE" "$TARGET" "$OUTPUT" "$REMOTE" "$BRANCH_ARG" "$SINCE_ARG" "$UNTIL_ARG" <<'PYTHON'
import sys, subprocess, os, re
target_type = sys.argv[1]
target      = sys.argv[2]
output      = sys.argv[3]
remote      = sys.argv[4]
branch      = sys.argv[5]
since       = sys.argv[6]
until       = sys.argv[7]

cmd = ['git','log','--pretty=format:%ad|%h|%s','--date=short']
if branch:
    cmd += [branch]
if since:
    cmd += [f'--since={since}'] if re.match(r'^\d{4}-\d{2}-\d{2}$', since) else [f'{since}..HEAD']
if until:
    # until as date
    if re.match(r'^\d{4}-\d{2}-\d{2}$', until):
        cmd += [f'--until={until}']
    else:
        # replace HEAD in a potential since..HEAD range, or add as upper bound
        cmd = [f'{since}..{until}' if since and not re.match(r'^\d{4}-\d{2}-\d{2}$', since)
               else c for c in cmd]
        if not since or re.match(r'^\d{4}-\d{2}-\d{2}$', since):
            cmd += [until]
if target_type == "dir":
    cmd += ['--', target + '/']
elif target_type == "file":
    cmd += ['--', target]

proc = subprocess.run(cmd, capture_output=True, text=True)
if proc.returncode != 0 or not proc.stdout.strip():
    label = target if target else "das Repository"
    print(f"Keine Git-Einträge für '{label}' gefunden.")
    sys.exit(0)

entries = []
for line in proc.stdout.splitlines():
    parts = line.split('|',2)
    if len(parts) < 3: continue
    entries.append({'date':parts[0],'hash':parts[1],'msg':parts[2]})

# group by date preserving order
from collections import OrderedDict
groups = OrderedDict()
for e in entries:
    groups.setdefault(e['date'], []).append(e)

prefix_order = ['Add','Fix','Upd','Chg','Del','Docs','Ref','Mve','Rem','Ren']

lines = []
if target_type == "all":
    lines.append("# Changelog\n")
else:
    lines.append(f"# Changelog für {target}\n")
lines.append("Die folgenden Einträge wurden automatisch aus der Git-Historie generiert. Die Reihenfolge der Typen ist Add → Fix → Upd → Chg → Del → Docs → Ref → Mve → Rem → Ren → sonstige.\n")

for date, ents in groups.items():
    lines.append(f"## {date}\n")
    for pref in prefix_order:
        for e in ents:
            if e['msg'].startswith(pref + ':') or e['msg'].startswith(pref + ' '):
                msg = e['msg'].replace('===', '\n  - ===')
                link = f" [{e['hash']}]({remote}/commit/{e['hash']})" if remote else f" {e['hash']}"
                lines.append(f"- {msg}{link}\n")
    for e in ents:
        if not re.match(r'^(Add|Fix|Upd|Chg|Del|Docs|Ref|Mve|Rem|Ren)[: ]', e['msg']):
            msg = e['msg'].replace('===', '\n  - ===')
            link = f" [{e['hash']}]({remote}/commit/{e['hash']})" if remote else f" {e['hash']}"
            lines.append(f"- {msg}{link}\n")
    lines.append("\n")

os.makedirs(os.path.dirname(os.path.abspath(output)), exist_ok=True)
with open(output, 'w', encoding='utf-8') as f:
    f.writelines(lines)
print(f"Changelog generiert: {output}")
PYTHON

exit 0


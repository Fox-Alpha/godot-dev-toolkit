#!/usr/bin/env bash

set -o pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$REPO_ROOT/.env"

if [ -f "$ENV_FILE" ]; then
    set -a
    # shellcheck disable=SC1090
    . "$ENV_FILE"
    set +a
fi

OLLAMA_API="${OLLAMA_API:-http://localhost:11434}"
OLLAMA_CONTAINER="${OLLAMA_CONTAINER:-intel-llm}"
OLLAMA_USE_DOCKER="${OLLAMA_USE_DOCKER:-auto}"
OLLAMA_MAX_TIME="${OLLAMA_MAX_TIME:-180}"
OLLAMA_STOP_AFTER_TEST="${OLLAMA_STOP_AFTER_TEST:-true}"
OLLAMA_PERSIST_RESULTS="${OLLAMA_PERSIST_RESULTS:-true}"
CATALOG_PATH="${OLLAMA_MODEL_CATALOG_JSON:-$REPO_ROOT/ollama-tooling/models.json}"
RENDER_SCRIPT="${OLLAMA_RENDER_SCRIPT:-$REPO_ROOT/ollama-tooling/render_model_catalog.py}"
RUN_SUMMARY_SCRIPT="${OLLAMA_RUN_SUMMARY_SCRIPT:-$REPO_ROOT/ollama-tooling/render_run_summary.py}"
OLLAMA_RUN_LOG_DIR="${OLLAMA_RUN_LOG_DIR:-$REPO_ROOT/ollama-tooling/runs}"

log() {
    printf '%s\n' "$1"
}

err() {
    printf '%s\n' "$1" >&2
}

usage() {
    cat <<'EOF'
Ollama Helper

Usage:
  ollama-tooling/ollama_helper.sh check
  ollama-tooling/ollama_helper.sh test <model> [csharp|gdscript|<profile-id>] [smoke|function|strict] [--no-persist]
  ollama-tooling/ollama_helper.sh test <model> --profile-name <name> --prompt "<text>" [--no-persist]
  ollama-tooling/ollama_helper.sh test <model> --profile-name <name> --prompt-file <path> [--no-persist]
  ollama-tooling/ollama_helper.sh batch [csharp|gdscript|<profile-id>] [smoke|function|strict] [--group <group-id>] [--models <csv>] [--no-persist]
  ollama-tooling/ollama_helper.sh batch --profile-name <name> --prompt "<text>" [--group <group-id>|--models <csv>] [--no-persist]

Examples:
  ollama-tooling/ollama_helper.sh test opencoder:8b
  ollama-tooling/ollama_helper.sh test opencoder:8b strict-csharp
  ollama-tooling/ollama_helper.sh test opencoder:8b csharp strict
  ollama-tooling/ollama_helper.sh test qwen3:14b --profile-name reasoning-short --prompt "Answer in one short paragraph: What is composition?"
  ollama-tooling/ollama_helper.sh batch csharp function --group code_generation
  ollama-tooling/ollama_helper.sh batch --models opencoder:8b,qwen3:14b --profile-name sentiment-short --prompt-file /tmp/prompt.txt

Profile IDs:
EOF
    list_profile_ids | sed 's/^/  /'
    cat <<'EOF'

Custom prompt options:
  --prompt <text>         Use a custom inline prompt
  --prompt-file <path>    Read a custom prompt from file
  --profile-name <name>   Label for custom prompt results

Batch selectors:
  --group <group-id>      Use models from one catalog group
  --models <csv>          Use an explicit comma-separated model list

Flags:
  --no-persist            Do not update models.json or render markdown

Environment:
  .env                    Loaded automatically from repo root if present
  OLLAMA_API              Default: http://localhost:11434
  OLLAMA_CONTAINER        Default: intel-llm
  OLLAMA_USE_DOCKER       Default: auto (auto|true|false)
  OLLAMA_MAX_TIME         Default: 180
  OLLAMA_STOP_AFTER_TEST  Default: true
  OLLAMA_PERSIST_RESULTS  Default: true
  OLLAMA_MODEL_CATALOG_JSON  Default: ollama-tooling/models.json
  OLLAMA_RENDER_SCRIPT    Default: ollama-tooling/render_model_catalog.py
  OLLAMA_RUN_LOG_DIR      Default: ollama-tooling/runs
  OLLAMA_RUN_SUMMARY_SCRIPT  Default: ollama-tooling/render_run_summary.py
EOF
}

list_profile_ids() {
    CATALOG_PATH="$CATALOG_PATH" python3 - <<'PY'
import json
import os
from pathlib import Path

catalog = json.loads(Path(os.environ["CATALOG_PATH"]).read_text(encoding="utf-8"))
for profile_id in sorted(catalog.get("test_profiles", {})):
    print(profile_id)
PY
}

profile_exists() {
    local profile_id="$1"
    PROFILE_ID="$profile_id" CATALOG_PATH="$CATALOG_PATH" python3 - <<'PY'
import json
import os
from pathlib import Path

catalog = json.loads(Path(os.environ["CATALOG_PATH"]).read_text(encoding="utf-8"))
raise SystemExit(0 if os.environ["PROFILE_ID"] in catalog.get("test_profiles", {}) else 1)
PY
}

validate_runtime_config() {
    case "$OLLAMA_USE_DOCKER" in
        auto|true|false)
            ;;
        *)
            err "Invalid OLLAMA_USE_DOCKER value: $OLLAMA_USE_DOCKER (expected: auto|true|false)"
            return 1
            ;;
    esac
}

api_target_is_local() {
    OLLAMA_API="$OLLAMA_API" python3 - <<'PY'
import ipaddress
import os
import socket
from urllib.parse import urlparse


api = os.environ["OLLAMA_API"].strip()
parsed = urlparse(api if "://" in api else f"http://{api}")
host = parsed.hostname
if not host:
    raise SystemExit(1)

host = host.rstrip(".").lower()
local_names = {"localhost"}

for candidate in (
    os.environ.get("HOSTNAME", "").strip(),
    socket.gethostname().strip(),
    socket.getfqdn().strip(),
):
    if not candidate:
        continue
    normalized = candidate.rstrip(".").lower()
    if not normalized:
        continue
    local_names.add(normalized)
    local_names.add(normalized.split(".", 1)[0])

if host in local_names:
    raise SystemExit(0)

try:
    address = ipaddress.ip_address(host)
except ValueError:
    raise SystemExit(1)

raise SystemExit(0 if address.is_loopback else 1)
PY
}

docker_enabled() {
    case "$OLLAMA_USE_DOCKER" in
        true)
            return 0
            ;;
        false)
            return 1
            ;;
        auto)
            command -v docker >/dev/null 2>&1 || return 1
            api_target_is_local
            return $?
            ;;
    esac
}

container_status() {
    if ! docker_enabled; then
        echo "not_used"
        return 0
    fi
    docker inspect -f '{{.State.Status}}' "$OLLAMA_CONTAINER" 2>/dev/null || echo "missing"
}

api_reachable() {
    curl -fsS "$OLLAMA_API/api/tags" >/dev/null 2>&1
}

stop_model() {
    local model="$1"
    [ "$OLLAMA_STOP_AFTER_TEST" = "true" ] || return 0
    timeout 20s ollama stop "$model" >/dev/null 2>&1 || true
}

check_dependencies() {
    local missing=0
    validate_runtime_config || return 1
    for cmd in curl ollama python3; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            err "Missing dependency: $cmd"
            missing=1
        fi
    done
    if [ "$OLLAMA_USE_DOCKER" = "true" ] && ! command -v docker >/dev/null 2>&1; then
        err "Missing dependency: docker"
        missing=1
    fi
    [ "$missing" -eq 0 ]
}

ensure_run_log_dir() {
    mkdir -p "$OLLAMA_RUN_LOG_DIR/single" "$OLLAMA_RUN_LOG_DIR/batch"
}

print_check_summary() {
    local status="$1"
    local api_status="$2"
    local container_label="$OLLAMA_CONTAINER"
    local display_status="$status"

    if [ "$status" = "not_used" ]; then
        container_label="-"
        display_status="not used"
    fi

    log "**Ollama-Status:** $api_status"
    log "**Container:** $container_label ($display_status)"
    log
}

run_check() {
    check_dependencies || return 2

    local status
    status="$(container_status)"

    if api_reachable; then
        print_check_summary "$status" "erreichbar"
        log "| Model | Size | Status | Notes |"
        log "|---|---|---|---|"
        python3 - <<'PY'
import subprocess

proc = subprocess.run(["ollama", "list"], capture_output=True, text=True)
if proc.returncode != 0:
    print("| `-` | `-` | `cli_error` | `ollama list failed` |")
    raise SystemExit(0)

lines = [line.rstrip() for line in proc.stdout.splitlines() if line.strip()]
if len(lines) <= 1:
    print("| `-` | `-` | `ok` | `No models listed` |")
    raise SystemExit(0)

for line in lines[1:]:
    parts = line.split()
    if len(parts) < 4:
        continue
    model = parts[0]
    size = " ".join(parts[2:4])
    print(f"| `{model}` | `{size}` | `ok` | `-` |")
PY
        return 0
    fi

    print_check_summary "$status" "nicht erreichbar"

    case "$status" in
        running)
            log "| Model | Size | Status | Notes |"
            log "|---|---|---|---|"
            log '| `-` | `-` | `api_error` | `Container running, but API not reachable` |'
            return 3
            ;;
        exited|created)
            log "| Model | Size | Status | Notes |"
            log "|---|---|---|---|"
            log '| `-` | `-` | `container_stopped` | `Container exists but is not running` |'
            return 4
            ;;
        missing)
            log "| Model | Size | Status | Notes |"
            log "|---|---|---|---|"
            log '| `-` | `-` | `missing` | `Container not found` |'
            return 5
            ;;
        not_used)
            log "| Model | Size | Status | Notes |"
            log "|---|---|---|---|"
            log '| `-` | `-` | `api_error` | `API not reachable; Docker check disabled or unavailable` |'
            return 6
            ;;
        *)
            log "| Model | Size | Status | Notes |"
            log "|---|---|---|---|"
            log "| \`-\` | \`-\` | \`api_error\` | \`Unknown container state: $status\` |"
            return 7
            ;;
    esac
}

normalize_profile() {
    local raw_kind="${1:-}"
    local raw_profile="${2:-}"
    local kind="csharp"
    local profile="smoke"

    case "$raw_kind" in
        '')
            ;;
        csharp|gdscript)
            kind="$raw_kind"
            ;;
        *)
            if profile_exists "$raw_kind"; then
                printf '%s\n' "$raw_kind"
                return 0
            fi
            err "Unknown kind or profile: $raw_kind"
            return 1
            ;;
    esac

    case "${raw_profile:-smoke}" in
        smoke|function|strict)
            profile="${raw_profile:-smoke}"
            ;;
        *)
            err "Unknown profile: $raw_profile"
            return 1
            ;;
    esac

    printf '%s-%s\n' "$profile" "$kind"
}

reset_parsed_test_args() {
    PARSED_RAW_KIND=""
    PARSED_RAW_PROFILE=""
    PARSED_CUSTOM_PROMPT=""
    PARSED_PROMPT_FILE=""
    PARSED_CUSTOM_PROFILE_NAME=""
    PARSED_NO_PERSIST="false"
}

parse_test_args() {
    reset_parsed_test_args

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --prompt)
                [ "$#" -ge 2 ] || {
                    err "Missing value for --prompt"
                    return 1
                }
                PARSED_CUSTOM_PROMPT="$2"
                shift 2
                ;;
            --prompt-file)
                [ "$#" -ge 2 ] || {
                    err "Missing value for --prompt-file"
                    return 1
                }
                PARSED_PROMPT_FILE="$2"
                shift 2
                ;;
            --profile-name)
                [ "$#" -ge 2 ] || {
                    err "Missing value for --profile-name"
                    return 1
                }
                PARSED_CUSTOM_PROFILE_NAME="$2"
                shift 2
                ;;
            --no-persist)
                PARSED_NO_PERSIST="true"
                shift
                ;;
            csharp|gdscript)
                if [ -z "$PARSED_RAW_KIND" ]; then
                    PARSED_RAW_KIND="$1"
                elif [ -z "$PARSED_RAW_PROFILE" ]; then
                    PARSED_RAW_PROFILE="$1"
                else
                    err "Unexpected extra profile argument: $1"
                    return 1
                fi
                shift
                ;;
            smoke|function|strict)
                if [ -z "$PARSED_RAW_PROFILE" ]; then
                    PARSED_RAW_PROFILE="$1"
                else
                    err "Unexpected extra profile argument: $1"
                    return 1
                fi
                shift
                ;;
            *)
                if profile_exists "$1"; then
                    if [ -z "$PARSED_RAW_KIND" ]; then
                        PARSED_RAW_KIND="$1"
                    elif [ -z "$PARSED_RAW_PROFILE" ]; then
                        PARSED_RAW_PROFILE="$1"
                    else
                        err "Unexpected extra profile argument: $1"
                        return 1
                    fi
                    shift
                    continue
                fi
                err "Unknown argument: $1"
                return 1
                ;;
        esac
    done

    if [ -n "$PARSED_CUSTOM_PROMPT" ] && [ -n "$PARSED_PROMPT_FILE" ]; then
        err "Use either --prompt or --prompt-file, not both"
        return 1
    fi

    if [ -n "$PARSED_CUSTOM_PROFILE_NAME" ] && [ -z "$PARSED_CUSTOM_PROMPT" ] && [ -z "$PARSED_PROMPT_FILE" ]; then
        err "--profile-name requires --prompt or --prompt-file"
        return 1
    fi
}

parse_batch_args() {
    BATCH_GROUP=""
    BATCH_MODELS=""
    local passthrough=()

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --group)
                [ "$#" -ge 2 ] || {
                    err "Missing value for --group"
                    return 1
                }
                BATCH_GROUP="$2"
                shift 2
                ;;
            --models)
                [ "$#" -ge 2 ] || {
                    err "Missing value for --models"
                    return 1
                }
                BATCH_MODELS="$2"
                shift 2
                ;;
            *)
                passthrough+=("$1")
                shift
                ;;
        esac
    done

    if [ -n "$BATCH_GROUP" ] && [ -n "$BATCH_MODELS" ]; then
        err "Use either --group or --models, not both"
        return 1
    fi

    parse_test_args "${passthrough[@]}"
}

build_prompt() {
    local profile_id="$1"
    PROFILE_ID="$profile_id" CATALOG_PATH="$CATALOG_PATH" python3 - <<'PY'
import json
import os
from pathlib import Path

catalog = json.loads(Path(os.environ["CATALOG_PATH"]).read_text(encoding="utf-8"))
profile = catalog.get("test_profiles", {}).get(os.environ["PROFILE_ID"])
if not profile:
    raise SystemExit(1)
prompt = profile.get("prompt")
if not prompt:
    raise SystemExit(2)
print(prompt, end="")
PY
    case "$?" in
        0) ;;
        1)
            err "Unknown profile: $profile_id"
            return 1
            ;;
        2)
            err "Profile has no prompt configured: $profile_id"
            return 1
            ;;
        *)
            err "Failed to load prompt for profile: $profile_id"
            return 1
            ;;
    esac
}

resolve_current_test_spec() {
    CURRENT_KIND=""
    CURRENT_PROFILE_ID=""
    CURRENT_PROMPT=""
    CURRENT_PERSIST_RESULTS="$OLLAMA_PERSIST_RESULTS"

    if [ "$PARSED_NO_PERSIST" = "true" ]; then
        CURRENT_PERSIST_RESULTS="false"
    fi

    if [ -n "$PARSED_CUSTOM_PROMPT" ] || [ -n "$PARSED_PROMPT_FILE" ]; then
        CURRENT_KIND="custom"
        CURRENT_PROFILE_ID="${PARSED_CUSTOM_PROFILE_NAME:-custom}"
        if [ -n "$PARSED_CUSTOM_PROMPT" ]; then
            CURRENT_PROMPT="$PARSED_CUSTOM_PROMPT"
        else
            [ -f "$PARSED_PROMPT_FILE" ] || {
                err "Prompt file not found: $PARSED_PROMPT_FILE"
                return 1
            }
            CURRENT_PROMPT="$(<"$PARSED_PROMPT_FILE")"
        fi
        return 0
    fi

    CURRENT_PROFILE_ID="$(normalize_profile "$PARSED_RAW_KIND" "$PARSED_RAW_PROFILE")" || return 1
    CURRENT_KIND="${CURRENT_PROFILE_ID##*-}"
    CURRENT_PROMPT="$(build_prompt "$CURRENT_PROFILE_ID")" || return 1
}

generate_payload() {
    local model="$1"
    local prompt_file="$2"
    MODEL="$model" PROMPT_FILE="$prompt_file" python3 - <<'PY'
import json
import os
from pathlib import Path

prompt = Path(os.environ["PROMPT_FILE"]).read_text(encoding="utf-8")
print(json.dumps({"model": os.environ["MODEL"], "prompt": prompt, "stream": False}))
PY
}

extract_response() {
    local file="$1"
    python3 - "$file" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as handle:
    data = json.load(handle)
print(data.get("response", ""))
PY
}

extract_metrics() {
    local file="$1"
    python3 - "$file" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as handle:
    data = json.load(handle)

prompt_eval_count = data.get("prompt_eval_count")
eval_count = data.get("eval_count")
prompt_eval_duration = data.get("prompt_eval_duration")
eval_duration = data.get("eval_duration")
total_duration = data.get("total_duration")
load_duration = data.get("load_duration")

tokens_per_second = ""
if isinstance(eval_count, int) and isinstance(eval_duration, int) and eval_duration > 0:
    tokens_per_second = f"{eval_count / (eval_duration / 1_000_000_000):.2f}"

for value in (
    prompt_eval_count,
    eval_count,
    prompt_eval_duration,
    eval_duration,
    total_duration,
    load_duration,
    tokens_per_second,
):
    print("" if value is None else value)
PY
}

evaluate_response() {
    local kind="$1"
    local profile_id="$2"
    local response="$3"
    local result="pass"
    local suggested_status="ok"
    local notes=()

    if [ -z "$response" ]; then
        printf 'fail\nsyntax_issue\nempty response\n'
        return 0
    fi

    if grep -q '```' <<<"$response"; then
        notes+=("contains markdown fences")
    fi

    if grep -q '<think>' <<<"$response"; then
        notes+=("contains reasoning tags")
    fi

    if grep -qiE '^(here|in this code|this script|explanation)' <<<"$response"; then
        notes+=("contains explanation text")
    fi

    case "$profile_id" in
        smoke-csharp)
            if ! grep -q 'Console.WriteLine' <<<"$response"; then
                result="fail"
                suggested_status="syntax_issue"
                notes+=("missing Console.WriteLine")
            fi
            ;;
        function-csharp)
            if ! grep -q 'SumPositive' <<<"$response"; then
                result="fail"
                suggested_status="syntax_issue"
                notes+=("missing SumPositive")
            fi
            if ! grep -q 'return' <<<"$response"; then
                result="fail"
                suggested_status="syntax_issue"
                notes+=("missing return")
            fi
            ;;
        strict-csharp)
            if ! grep -q 'IsEven' <<<"$response"; then
                result="fail"
                suggested_status="syntax_issue"
                notes+=("missing IsEven")
            fi
            if ! grep -q 'bool' <<<"$response"; then
                result="fail"
                suggested_status="syntax_issue"
                notes+=("missing bool return type")
            fi
            if grep -qE '\bclass\b' <<<"$response"; then
                result="fail"
                suggested_status="syntax_issue"
                notes+=("wrapped in class")
            fi
            ;;
        smoke-gdscript)
            if ! grep -q 'extends Node' <<<"$response"; then
                result="fail"
                suggested_status="godot4_insufficient"
                notes+=("missing extends Node")
            fi
            if ! grep -q 'func _ready() -> void:' <<<"$response"; then
                result="fail"
                suggested_status="godot4_insufficient"
                notes+=("missing typed _ready signature")
            fi
            ;;
        function-gdscript)
            if ! grep -q 'extends Node' <<<"$response"; then
                result="fail"
                suggested_status="godot4_insufficient"
                notes+=("missing extends Node")
            fi
            if ! grep -q 'func sum_positive(values: Array\[int\]) -> int:' <<<"$response"; then
                result="fail"
                suggested_status="godot4_insufficient"
                notes+=("missing typed sum_positive signature")
            fi
            ;;
        strict-gdscript)
            if ! grep -q 'func is_even(value: int) -> bool:' <<<"$response"; then
                result="fail"
                suggested_status="godot4_insufficient"
                notes+=("missing typed is_even signature")
            fi
            if grep -q 'extends ' <<<"$response"; then
                result="fail"
                suggested_status="godot4_insufficient"
                notes+=("contains extends")
            fi
            if grep -q '_ready' <<<"$response"; then
                result="fail"
                suggested_status="godot4_insufficient"
                notes+=("contains _ready")
            fi
            ;;
        *)
            if [ "$kind" = "custom" ]; then
                notes+=("custom prompt")
                notes+=("manual review recommended")
            else
                result="fail"
                suggested_status="syntax_issue"
                notes+=("unknown profile")
            fi
            ;;
    esac

    if [ "${#notes[@]}" -eq 0 ]; then
        notes+=("pass")
    fi

    printf '%s\n%s\n%s\n' "$result" "$suggested_status" "$(IFS='; '; echo "${notes[*]}")"
}

note_for_error_file() {
    local error_file="$1"
    local curl_status="$2"
    local stderr_text
    stderr_text="$(<"$error_file")"

    if [ "$curl_status" -eq 28 ]; then
        printf 'request hit configured timeout\n'
        return 0
    fi

    if grep -q ' 500' <<<"$stderr_text"; then
        printf 'HTTP 500 during generate request\n'
        return 0
    fi

    if grep -q 'unknown model' <<<"$stderr_text"; then
        printf 'unknown model in local Ollama instance\n'
        return 0
    fi

    printf 'generate request failed\n'
}

relative_path() {
    local target="$1"
    python3 - "$REPO_ROOT" "$target" <<'PY'
from pathlib import Path
import sys

root = Path(sys.argv[1]).resolve()
target = Path(sys.argv[2]).resolve()
try:
    print(target.relative_to(root).as_posix())
except ValueError:
    print(target.as_posix())
PY
}

sanitize_name() {
    printf '%s' "$1" | tr '/: ' '___' | tr -cd '[:alnum:]_.-'
}

create_single_log_path() {
    local model="$1"
    local profile_id="$2"
    local run_id="$3"
    local safe_model safe_profile run_dir

    safe_model="$(sanitize_name "$model")"
    safe_profile="$(sanitize_name "$profile_id")"
    run_dir="$OLLAMA_RUN_LOG_DIR/single/${run_id}-${safe_profile}-${safe_model}"
    mkdir -p "$run_dir"
    printf '%s\n' "$run_dir/run.json"
}

write_run_log() {
    local log_path="$1"
    local model="$2"
    local kind="$3"
    local profile_id="$4"
    local prompt_file="$5"
    local response_file="$6"
    local error_file="$7"
    local started_at="$8"
    local finished_at="$9"
    local duration_ms="${10}"
    local result="${11}"
    local suggested_status="${12}"
    local notes_joined="${13}"
    local prompt_eval_count="${14}"
    local eval_count="${15}"
    local prompt_eval_duration_ns="${16}"
    local eval_duration_ns="${17}"
    local total_duration_ns="${18}"
    local load_duration_ns="${19}"
    local tokens_per_second="${20}"
    local run_id="${21}"

    LOG_PATH="$log_path" \
    MODEL="$model" \
    KIND="$kind" \
    PROFILE_ID="$profile_id" \
    PROMPT_FILE="$prompt_file" \
    RESPONSE_FILE="$response_file" \
    ERROR_FILE="$error_file" \
    STARTED_AT="$started_at" \
    FINISHED_AT="$finished_at" \
    DURATION_MS="$duration_ms" \
    RESULT="$result" \
    SUGGESTED_STATUS="$suggested_status" \
    NOTES_JOINED="$notes_joined" \
    PROMPT_EVAL_COUNT="$prompt_eval_count" \
    EVAL_COUNT="$eval_count" \
    PROMPT_EVAL_DURATION_NS="$prompt_eval_duration_ns" \
    EVAL_DURATION_NS="$eval_duration_ns" \
    TOTAL_DURATION_NS="$total_duration_ns" \
    LOAD_DURATION_NS="$load_duration_ns" \
    TOKENS_PER_SECOND="$tokens_per_second" \
    RUN_ID="$run_id" \
    RUN_LOG_DIR="$OLLAMA_RUN_LOG_DIR" \
    REPO_ROOT="$REPO_ROOT" \
    python3 - <<'PY'
import json
import os
from pathlib import Path


def split_notes(raw: str) -> list[str]:
    return [item.strip() for item in raw.split(";") if item.strip()]


def issue_for_note(note: str) -> str:
    mapping = {
        "contains markdown fences": "markdown_fences",
        "contains explanation text": "explanation_text",
        "contains reasoning tags": "reasoning_tags",
        "empty response": "empty_response",
        "custom prompt": "custom_prompt",
        "manual review recommended": "manual_review_recommended",
        "request hit configured timeout": "timeout",
        "HTTP 500 during generate request": "http_500",
        "unknown model in local Ollama instance": "unknown_model",
        "generate request failed": "generate_request_failed",
        "container exists but is not running": "container_stopped",
        "container not found": "container_missing",
        "API not reachable": "api_not_reachable",
        "pass": "pass",
    }
    if note in mapping:
        return mapping[note]
    lowered = note.lower().replace("-", " ")
    sanitized = "_".join(part for part in lowered.split() if part)
    return sanitized or "unspecified"


def parse_int(name: str):
    raw = os.environ.get(name, "")
    return int(raw) if raw not in ("", "-") else None


def parse_float(name: str):
    raw = os.environ.get(name, "")
    return float(raw) if raw not in ("", "-") else None


prompt = Path(os.environ["PROMPT_FILE"]).read_text(encoding="utf-8")
raw_response = Path(os.environ["RESPONSE_FILE"]).read_text(encoding="utf-8")
stderr = Path(os.environ["ERROR_FILE"]).read_text(encoding="utf-8")
notes = split_notes(os.environ.get("NOTES_JOINED", "")) or ["pass"]
issues = [issue_for_note(note) for note in notes if note != "pass"]

response = raw_response
try:
    parsed = json.loads(raw_response)
    if isinstance(parsed, dict) and "response" in parsed:
        response = parsed.get("response") or ""
except json.JSONDecodeError:
    pass

repo_root = Path(os.environ["REPO_ROOT"]).resolve()
log_path = Path(os.environ["LOG_PATH"]).resolve()
try:
    relative_log_path = log_path.relative_to(repo_root).as_posix()
except ValueError:
    relative_log_path = log_path.as_posix()

try:
    relative_log_dir = Path(os.environ["RUN_LOG_DIR"]).resolve().relative_to(repo_root).as_posix()
except ValueError:
    relative_log_dir = Path(os.environ["RUN_LOG_DIR"]).resolve().as_posix()

payload = {
    "run_id": os.environ["RUN_ID"],
    "started_at": os.environ["STARTED_AT"],
    "finished_at": os.environ["FINISHED_AT"],
    "model": os.environ["MODEL"],
    "kind": os.environ["KIND"],
    "profile": os.environ["PROFILE_ID"],
    "result": os.environ["RESULT"],
    "suggested_status": os.environ["SUGGESTED_STATUS"],
    "notes": notes,
    "issues": issues,
    "duration_ms": parse_int("DURATION_MS"),
    "metrics": {
        "last_duration_ms": parse_int("DURATION_MS"),
        "prompt_eval_count": parse_int("PROMPT_EVAL_COUNT"),
        "eval_count": parse_int("EVAL_COUNT"),
        "prompt_eval_duration_ns": parse_int("PROMPT_EVAL_DURATION_NS"),
        "eval_duration_ns": parse_int("EVAL_DURATION_NS"),
        "total_duration_ns": parse_int("TOTAL_DURATION_NS"),
        "load_duration_ns": parse_int("LOAD_DURATION_NS"),
        "tokens_per_second": parse_float("TOKENS_PER_SECOND"),
    },
    "prompt": prompt,
    "response": response,
    "raw_response": raw_response,
    "stderr": stderr,
    "log_path": relative_log_path,
    "run_log_dir": relative_log_dir,
}

log_path.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
PY
}

persist_result_from_log() {
    local log_path="$1"

    LOG_PATH="$log_path" CATALOG_PATH="$CATALOG_PATH" python3 - <<'PY'
import json
import os
from pathlib import Path


catalog_path = Path(os.environ["CATALOG_PATH"])
run_path = Path(os.environ["LOG_PATH"])
catalog = json.loads(catalog_path.read_text(encoding="utf-8"))
run = json.loads(run_path.read_text(encoding="utf-8"))

models = catalog.setdefault("models", [])
entry = None
for item in models:
    if item.get("name") == run["model"]:
        entry = item
        break

if entry is None:
    entry = {
        "name": run["model"],
        "id": "-",
        "size_gb": None,
        "size_label": "-",
        "release_year": "-",
        "group": "general",
        "status": "untested",
        "last_test": "-",
        "notes": "-",
        "issues": [],
        "tags": ["local"],
        "tested_kinds": [],
        "agent_selection": {
            "auto_select": False,
            "strict_code_only_safe": False,
        },
    }
    models.append(entry)

entry["status"] = run["suggested_status"]
entry["last_test"] = run["finished_at"][:10]
entry["last_test_at"] = run["finished_at"]
entry["notes"] = ";".join(run["notes"]) if run["notes"] else "-"
entry["issues"] = run["issues"]
entry["last_profile"] = run["profile"]
entry["last_kind"] = run["kind"]
entry["last_result"] = run["result"]
entry["last_run_id"] = run["run_id"]
entry["last_run_log"] = run["log_path"]
entry["metrics"] = run["metrics"]

tested_kinds = entry.setdefault("tested_kinds", [])
if run["kind"] not in tested_kinds:
    tested_kinds.append(run["kind"])

if run["kind"] != "custom":
    agent = entry.setdefault("agent_selection", {})
    agent["auto_select"] = run["suggested_status"] == "ok"
    blocked_issues = {"markdown_fences", "explanation_text", "reasoning_tags"}
    agent["strict_code_only_safe"] = run["suggested_status"] == "ok" and not any(issue in blocked_issues for issue in run["issues"])

catalog["updated_at"] = run["finished_at"]
catalog["run_log_dir"] = run["run_log_dir"]

catalog_path.write_text(json.dumps(catalog, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
PY
}

render_catalog() {
    python3 "$RENDER_SCRIPT"
}

render_run_summary() {
    local log_path="$1"
    python3 "$RUN_SUMMARY_SCRIPT" "$log_path" >/dev/null
}

write_batch_log() {
    local batch_log_path="$1"
    local batch_id="$2"
    local started_at="$3"
    local finished_at="$4"
    local selector_group="$5"
    local selector_models="$6"
    local kind="$7"
    local profile="$8"
    local persist_flag="$9"
    local runs_file="${10}"

    BATCH_LOG_PATH="$batch_log_path" \
    BATCH_ID="$batch_id" \
    STARTED_AT="$started_at" \
    FINISHED_AT="$finished_at" \
    SELECTOR_GROUP="$selector_group" \
    SELECTOR_MODELS="$selector_models" \
    KIND="$kind" \
    PROFILE="$profile" \
    PERSIST_FLAG="$persist_flag" \
    RUNS_FILE="$runs_file" \
    REPO_ROOT="$REPO_ROOT" \
    python3 - <<'PY'
import json
import os
from pathlib import Path


repo_root = Path(os.environ["REPO_ROOT"]).resolve()
run_paths = [line.strip() for line in Path(os.environ["RUNS_FILE"]).read_text(encoding="utf-8").splitlines() if line.strip()]
runs = []
summary = {}

for path_text in run_paths:
    run_path = Path(path_text).resolve()
    run = json.loads(run_path.read_text(encoding="utf-8"))
    summary[run["suggested_status"]] = summary.get(run["suggested_status"], 0) + 1
    runs.append(
        {
            "model": run["model"],
            "result": run["result"],
            "suggested_status": run["suggested_status"],
            "duration_ms": run.get("duration_ms"),
            "tokens_per_second": run.get("metrics", {}).get("tokens_per_second"),
            "log_path": run["log_path"],
        }
    )

batch_log_path = Path(os.environ["BATCH_LOG_PATH"]).resolve()
try:
    relative_batch_log = batch_log_path.relative_to(repo_root).as_posix()
except ValueError:
    relative_batch_log = batch_log_path.as_posix()

payload = {
    "batch_id": os.environ["BATCH_ID"],
    "started_at": os.environ["STARTED_AT"],
    "finished_at": os.environ["FINISHED_AT"],
    "kind": os.environ["KIND"],
    "profile": os.environ["PROFILE"],
    "persisted_to_catalog": os.environ["PERSIST_FLAG"] == "true",
    "selector": {
        "group": os.environ["SELECTOR_GROUP"] or None,
        "models": [item for item in os.environ["SELECTOR_MODELS"].split(",") if item],
    },
    "summary": summary,
    "runs": runs,
    "log_path": relative_batch_log,
}

batch_log_path.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
PY
}

resolve_batch_models() {
    GROUP_FILTER="$BATCH_GROUP" MODELS_CSV="$BATCH_MODELS" CATALOG_PATH="$CATALOG_PATH" python3 - <<'PY'
import json
import os
from pathlib import Path


catalog = json.loads(Path(os.environ["CATALOG_PATH"]).read_text(encoding="utf-8"))
group_filter = os.environ.get("GROUP_FILTER", "")
models_csv = os.environ.get("MODELS_CSV", "")

if models_csv:
    for model in [item.strip() for item in models_csv.split(",") if item.strip()]:
        print(model)
    raise SystemExit(0)

for model in catalog.get("models", []):
    if group_filter and model.get("group") != group_filter:
        continue
    print(model["name"])
PY
}

print_test_report_from_log() {
    local log_path="$1"

    LOG_PATH="$log_path" python3 - <<'PY'
import json
import os
from datetime import datetime
from pathlib import Path


def parse_timestamp(value):
    if not value:
        return None
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None


def format_local_timestamp(value):
    timestamp = parse_timestamp(value)
    if timestamp is None:
        return value or "-"
    local = timestamp.astimezone()
    raw_offset = local.strftime("%z")
    offset = f"{raw_offset[:3]}:{raw_offset[3:]}"
    return f"{local:%Y-%m-%d %H:%M:%S} {local.tzname()} ({offset})"

run = json.loads(Path(os.environ["LOG_PATH"]).read_text(encoding="utf-8"))
metrics = run.get("metrics", {})
summary_path = Path(run["log_path"]).parent / "summary.md"

print(f"**Model:** `{run['model']}`")
print(f"**Test:** `{run['kind']}`")
print(f"**Profile:** `{run['profile']}`")
print(f"**Started:** `{format_local_timestamp(run.get('started_at'))}`")
print(f"**Finished:** `{format_local_timestamp(run.get('finished_at'))}`")
print(f"**Duration:** `{run.get('duration_ms', '-') }ms`" if run.get("duration_ms") is not None else "**Duration:** `-`")
print(f"**Result:** `{run['result']}`")
print(f"**Suggested status:** `{run['suggested_status']}`")
print(f"**Notes:** {';'.join(run.get('notes', [])) or '-'}")
print(f"**Prompt eval count:** `{metrics.get('prompt_eval_count', '-') if metrics.get('prompt_eval_count') is not None else '-'}`")
print(f"**Eval count:** `{metrics.get('eval_count', '-') if metrics.get('eval_count') is not None else '-'}`")
print(f"**Total duration (ns):** `{metrics.get('total_duration_ns', '-') if metrics.get('total_duration_ns') is not None else '-'}`")
print(f"**Load duration (ns):** `{metrics.get('load_duration_ns', '-') if metrics.get('load_duration_ns') is not None else '-'}`")
tokens_per_second = metrics.get("tokens_per_second")
print(f"**Tokens/s:** `{tokens_per_second:.2f}`" if isinstance(tokens_per_second, float) else "**Tokens/s:** `-`")
print(f"**Prompt eval duration (ns):** `{metrics.get('prompt_eval_duration_ns', '-') if metrics.get('prompt_eval_duration_ns') is not None else '-'}`")
print(f"**Eval duration (ns):** `{metrics.get('eval_duration_ns', '-') if metrics.get('eval_duration_ns') is not None else '-'}`")
print(f"**Run log:** `{run['log_path']}`")
print(f"**Summary:** `{summary_path.as_posix()}`")
print()
if run.get("response"):
    print(run["response"])
elif run.get("stderr"):
    print(run["stderr"])
PY
}

print_batch_report_from_log() {
    local batch_log_path="$1"

    LOG_PATH="$batch_log_path" python3 - <<'PY'
import json
import os
from datetime import datetime
from pathlib import Path


def parse_timestamp(value):
    if not value:
        return None
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None


def format_local_timestamp(value):
    timestamp = parse_timestamp(value)
    if timestamp is None:
        return value or "-"
    local = timestamp.astimezone()
    raw_offset = local.strftime("%z")
    offset = f"{raw_offset[:3]}:{raw_offset[3:]}"
    return f"{local:%Y-%m-%d %H:%M:%S} {local.tzname()} ({offset})"

batch = json.loads(Path(os.environ["LOG_PATH"]).read_text(encoding="utf-8"))
summary_path = Path(batch["log_path"]).parent / "summary.md"

print(f"**Batch:** `{batch['batch_id']}`")
print(f"**Profile:** `{batch['profile']}`")
print(f"**Persisted:** `{'yes' if batch['persisted_to_catalog'] else 'no'}`")
print(f"**Started:** `{format_local_timestamp(batch.get('started_at'))}`")
print(f"**Finished:** `{format_local_timestamp(batch.get('finished_at'))}`")
print(f"**Batch log:** `{batch['log_path']}`")
print(f"**Summary:** `{summary_path.as_posix()}`")
print()
print("| Model | Status | Duration | Tok/s | Run log |")
print("|---|---|---|---|---|")
for run in batch["runs"]:
    duration = f"{run['duration_ms']}ms" if run.get("duration_ms") is not None else "-"
    tokens_per_second = run.get("tokens_per_second")
    tps = f"{tokens_per_second:.2f}" if isinstance(tokens_per_second, float) else "-"
    print(f"| `{run['model']}` | `{run['suggested_status']}` | `{duration}` | `{tps}` | `{run['log_path']}` |")

print()
print("**Summary:**")
for key in sorted(batch["summary"]):
    print(f"- `{key}`: `{batch['summary'][key]}`")
PY
}

execute_test() {
    local model="$1"
    local log_path_override="${2:-}"
    local run_id_override="${3:-}"
    local kind="$CURRENT_KIND"
    local profile_id="$CURRENT_PROFILE_ID"
    local prompt="$CURRENT_PROMPT"
    local prompt_file response_file error_file payload
    local response prompt_eval_count eval_count prompt_eval_duration_ns eval_duration_ns total_duration_ns load_duration_ns tokens_per_second
    local started_at finished_at duration_ms curl_status result suggested_status notes_joined status
    local run_id log_path

    ensure_run_log_dir

    prompt_file="$(mktemp)"
    response_file="$(mktemp)"
    error_file="$(mktemp)"
    printf '%s' "$prompt" >"$prompt_file"

    started_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    run_id="${run_id_override:-$(date -u +"%Y%m%dT%H%M%S%3NZ")}"
    if [ -n "$log_path_override" ]; then
        log_path="$log_path_override"
        mkdir -p "$(dirname "$log_path")"
    else
        log_path="$(create_single_log_path "$model" "$profile_id" "$run_id")"
    fi

    status="$(container_status)"
    if ! api_reachable; then
        finished_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
        duration_ms=0
        result="fail"
        case "$status" in
            exited|created)
                suggested_status="container_stopped"
                notes_joined="container exists but is not running"
                printf '%s\n' "Container exists but is not running." >"$error_file"
                ;;
            missing)
                suggested_status="container_stopped"
                notes_joined="container not found"
                printf '%s\n' "Container not found." >"$error_file"
                ;;
            *)
                suggested_status="load_failed"
                notes_joined="API not reachable"
                printf '%s\n' "API not reachable." >"$error_file"
                ;;
        esac
        write_run_log "$log_path" "$model" "$kind" "$profile_id" "$prompt_file" "$response_file" "$error_file" "$started_at" "$finished_at" "$duration_ms" "$result" "$suggested_status" "$notes_joined" "" "" "" "" "" "" "" "$run_id"
        rm -f "$prompt_file" "$response_file" "$error_file"
        stop_model "$model"
        printf '%s\n' "$log_path"
        return 0
    fi

    payload="$(generate_payload "$model" "$prompt_file")" || {
        rm -f "$prompt_file" "$response_file" "$error_file"
        return 2
    }

    local start_ms end_ms
    start_ms="$(date +%s%3N)"
    curl --max-time "$OLLAMA_MAX_TIME" -fsS "$OLLAMA_API/api/generate" \
        -H 'Content-Type: application/json' \
        -d "$payload" \
        >"$response_file" 2>"$error_file"
    curl_status=$?
    end_ms="$(date +%s%3N)"
    duration_ms=$((end_ms - start_ms))
    finished_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

    if [ "$curl_status" -ne 0 ]; then
        result="fail"
        if [ "$curl_status" -eq 28 ]; then
            suggested_status="timeout"
        else
            suggested_status="load_failed"
        fi
        notes_joined="$(note_for_error_file "$error_file" "$curl_status")"
        write_run_log "$log_path" "$model" "$kind" "$profile_id" "$prompt_file" "$response_file" "$error_file" "$started_at" "$finished_at" "$duration_ms" "$result" "$suggested_status" "$notes_joined" "" "" "" "" "" "" "" "$run_id"
        rm -f "$prompt_file" "$response_file" "$error_file"
        stop_model "$model"
        printf '%s\n' "$log_path"
        return 0
    fi

    response="$(extract_response "$response_file")"
    mapfile -t evaluation < <(evaluate_response "$kind" "$profile_id" "$response")
    result="${evaluation[0]}"
    suggested_status="${evaluation[1]}"
    notes_joined="${evaluation[2]}"

    mapfile -t metrics < <(extract_metrics "$response_file")
    prompt_eval_count="${metrics[0]}"
    eval_count="${metrics[1]}"
    prompt_eval_duration_ns="${metrics[2]}"
    eval_duration_ns="${metrics[3]}"
    total_duration_ns="${metrics[4]}"
    load_duration_ns="${metrics[5]}"
    tokens_per_second="${metrics[6]}"

    write_run_log "$log_path" "$model" "$kind" "$profile_id" "$prompt_file" "$response_file" "$error_file" "$started_at" "$finished_at" "$duration_ms" "$result" "$suggested_status" "$notes_joined" "$prompt_eval_count" "$eval_count" "$prompt_eval_duration_ns" "$eval_duration_ns" "$total_duration_ns" "$load_duration_ns" "$tokens_per_second" "$run_id"

    rm -f "$prompt_file" "$response_file" "$error_file"
    stop_model "$model"
    printf '%s\n' "$log_path"
}

run_test() {
    local model="$1"
    shift || true

    [ -n "$model" ] || {
        err "Missing model name"
        usage
        return 2
    }

    parse_test_args "$@" || return 2
    resolve_current_test_spec || return 2

    local run_log_path
    run_log_path="$(execute_test "$model")" || return $?

    if [ "$CURRENT_PERSIST_RESULTS" = "true" ]; then
        persist_result_from_log "$run_log_path"
        render_catalog
    fi

    render_run_summary "$run_log_path"
    print_test_report_from_log "$run_log_path"
}

run_batch() {
    parse_batch_args "$@" || return 2
    resolve_current_test_spec || return 2

    local models_output
    models_output="$(resolve_batch_models)" || return 2
    [ -n "$models_output" ] || {
        err "No models selected for batch run"
        return 2
    }

    ensure_run_log_dir

    local runs_file batch_id batch_dir batch_log_path started_at finished_at
    runs_file="$(mktemp)"
    batch_id="$(date -u +"batch-%Y%m%dT%H%M%S%3NZ")-$(sanitize_name "$CURRENT_PROFILE_ID")"
    batch_dir="$OLLAMA_RUN_LOG_DIR/batch/$batch_id"
    mkdir -p "$batch_dir"
    batch_log_path="$batch_dir/batch.json"
    started_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

    while IFS= read -r model; do
        [ -n "$model" ] || continue
        local run_log_path safe_model
        safe_model="$(sanitize_name "$model")"
        run_log_path="$(execute_test "$model" "$batch_dir/${safe_model}.json" "${batch_id}-${safe_model}")" || {
            rm -f "$runs_file"
            return $?
        }
        printf '%s\n' "$run_log_path" >>"$runs_file"
        if [ "$CURRENT_PERSIST_RESULTS" = "true" ]; then
            persist_result_from_log "$run_log_path"
        fi
    done <<<"$models_output"

    if [ "$CURRENT_PERSIST_RESULTS" = "true" ]; then
        render_catalog
    fi

    finished_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    write_batch_log "$batch_log_path" "$batch_id" "$started_at" "$finished_at" "$BATCH_GROUP" "$BATCH_MODELS" "$CURRENT_KIND" "$CURRENT_PROFILE_ID" "$CURRENT_PERSIST_RESULTS" "$runs_file"
    render_run_summary "$batch_log_path"
    print_batch_report_from_log "$batch_log_path"
    rm -f "$runs_file"
}

main() {
    local command="${1:-}"

    case "$command" in
        check)
            run_check
            ;;
        test)
            shift
            run_test "$@"
            ;;
        batch)
            shift
            run_batch "$@"
            ;;
        -h|--help|help|'')
            usage
            ;;
        *)
            err "Unknown command: $command"
            usage
            return 2
            ;;
    esac
}

main "$@"

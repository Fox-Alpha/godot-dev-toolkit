#!/usr/bin/env python3

import json
from datetime import datetime
from functools import cmp_to_key
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
CATALOG_PATH = REPO_ROOT / "ollama-tooling/models.json"

GROUP_HEADINGS = {
    "code_generation": "## 💻 Code-Generierung",
    "reasoning": "## 🧠 Reasoning & Problemlösung",
    "general": "## 🌐 Allrounder & Sprache",
    "edge": "## ⚡ Ressourcenschonend / Edge",
    "specialized": "## 🔍 Spezialisiert",
}


def format_metric(value, suffix=""):
    if value in (None, "", 0):
        return "-"
    if isinstance(value, float):
        return f"{value:.2f}{suffix}"
    return f"{value}{suffix}"


def parse_timestamp(value):
    if not value or not isinstance(value, str):
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
    return f"{local:%Y-%m-%d %H:%M} {local.tzname()} ({format_local_offset(value)})"


def format_local_offset(value):
    timestamp = parse_timestamp(value)
    if timestamp is None:
        return "-"
    raw = timestamp.astimezone().strftime("%z")
    return f"{raw[:3]}:{raw[3:]}"


def model_last_test_label(model):
    if model.get("last_test_at"):
        return format_local_timestamp(model["last_test_at"])
    return model.get("last_test", "-")


def get_nested_value(data, path):
    current = data
    for part in path.split("."):
        if not isinstance(current, dict):
            return None
        current = current.get(part)
    return current


def normalize_sort_value(value, value_type):
    if value is None:
        return None
    if value_type == "number":
        try:
            return float(value)
        except (TypeError, ValueError):
            return None
    if value_type == "string":
        return str(value).lower()
    return value


def compare_sort_values(left, right, spec):
    left_value = normalize_sort_value(get_nested_value(left, spec["path"]), spec.get("type", "string"))
    right_value = normalize_sort_value(get_nested_value(right, spec["path"]), spec.get("type", "string"))
    missing = spec.get("missing", "last")

    if left_value is None and right_value is None:
        return 0
    if left_value is None:
        return -1 if missing == "first" else 1
    if right_value is None:
        return 1 if missing == "first" else -1

    if left_value < right_value:
        result = -1
    elif left_value > right_value:
        result = 1
    else:
        result = 0

    if spec.get("direction", "asc") == "desc":
        result *= -1
    return result


def sort_models(models, render_options):
    table_sort = render_options.get("table_sort", {})
    if not table_sort.get("enabled", False):
        return list(models)

    fields = table_sort.get("fields", [])
    if not fields:
        return list(models)

    def compare(left, right):
        for spec in fields:
            result = compare_sort_values(left, right, spec)
            if result != 0:
                return result
        return 0

    return sorted(models, key=cmp_to_key(compare))


def describe_sort(render_options):
    table_sort = render_options.get("table_sort", {})
    if not table_sort.get("enabled", False) or not table_sort.get("fields"):
        return "keine feste Sortierung"
    parts = []
    for spec in table_sort["fields"]:
        parts.append(f"{spec['path']} {spec.get('direction', 'asc')}")
    return ", ".join(parts)


def compute_summary(models):
    counts = {}
    fastest = None
    highest_tps = None

    for model in models:
        counts[model["status"]] = counts.get(model["status"], 0) + 1

        metrics = model.get("metrics", {})
        duration_ms = metrics.get("last_duration_ms")
        tokens_per_second = metrics.get("tokens_per_second")

        if model["status"] != "ok":
            continue

        if isinstance(duration_ms, (int, float)):
            if fastest is None or duration_ms < fastest["duration_ms"]:
                fastest = {"name": model["name"], "duration_ms": duration_ms}

        if isinstance(tokens_per_second, (int, float)):
            if highest_tps is None or tokens_per_second > highest_tps["tokens_per_second"]:
                highest_tps = {
                    "name": model["name"],
                    "tokens_per_second": tokens_per_second,
                }

    return counts, fastest, highest_tps


def render() -> str:
    data = json.loads(CATALOG_PATH.read_text(encoding="utf-8"))
    groups = {group["id"]: group for group in data["groups"]}
    render_options = data.get("render_options", {})
    counts, fastest, highest_tps = compute_summary(data["models"])
    updated_at = data.get("updated_at")

    lines = [
        "# Modellkatalog",
        "",
        "Diese Datei wird aus `ollama-tooling/models.json` generiert.",
        "JSON ist die kanonische Quelle; passe Aenderungen zuerst dort an.",
        f"Katalog zuletzt aktualisiert: `{format_local_timestamp(updated_at)}`." if updated_at else "Katalog zuletzt aktualisiert: `-`.",
        f"JSON-Zeitstempel bleiben in UTC, Markdown zeigt lokale Zeit mit Zeitzone (`{format_local_offset(updated_at)}`)." if updated_at else "JSON-Zeitstempel bleiben in UTC, Markdown zeigt lokale Zeit mit Zeitzone.",
        f"Review-Logs liegen unter `{data.get('run_log_dir', 'ollama-tooling/runs')}` mit `single/` und `batch/`-Unterordnern.",
        f"Tabellen-Sortierung: `{describe_sort(render_options)}`.",
        "",
        "Statuswerte:",
        "",
        "| Status | Bedeutung |",
        "|---|---|",
    ]

    for status in data["status_order"]:
        lines.append(f"| `{status}` | {data['status_definitions'][status]} |")

    lines.extend(
        [
            "",
            "## Test-Zusammenfassung",
            "",
            "| Metrik | Wert |",
            "|---|---|",
            f"| Modelle insgesamt | `{len(data['models'])}` |",
            f"| `ok` | `{counts.get('ok', 0)}` |",
            f"| `syntax_issue` | `{counts.get('syntax_issue', 0)}` |",
            f"| `load_failed` | `{counts.get('load_failed', 0)}` |",
            f"| Schnellstes Modell (letzter Lauf) | `{fastest['name']}` - `{fastest['duration_ms']}ms` |" if fastest else "| Schnellstes Modell (letzter Lauf) | `-` |",
            f"| Hoechster Durchsatz | `{highest_tps['name']}` - `{highest_tps['tokens_per_second']:.2f} tok/s` |" if highest_tps else "| Hoechster Durchsatz | `-` |",
            "",
        ]
    )

    for group in data["groups"]:
        group_models = [model for model in data["models"] if model["group"] == group["id"]]
        group_models = sort_models(group_models, render_options)
        if not group_models:
            continue

        lines.extend(
            [
                GROUP_HEADINGS.get(group["id"], f"## {groups[group['id']]['title']}"),
                "",
                "| Model | ID | Size | Release | Status | Last test | Profile | Duration | Tokens (P/E) | Tok/s | Notes |",
                "|---|---|---|---|---|---|---|---|---|---|---|",
            ]
        )

        for model in group_models:
            metrics = model.get("metrics", {})
            token_summary = "-/-"
            prompt_eval_count = metrics.get("prompt_eval_count")
            eval_count = metrics.get("eval_count")
            if prompt_eval_count is not None or eval_count is not None:
                token_summary = f"{prompt_eval_count if prompt_eval_count is not None else '-'} / {eval_count if eval_count is not None else '-'}"
            lines.append(
                "| **{name}** | `{id}` | `{size}` | `{release}` | `{status}` | `{last_test}` | `{profile}` | `{duration}` | `{token_summary}` | `{tokens_per_second}` | {notes} |".format(
                    name=model["name"],
                    id=model["id"],
                    size=model["size_label"],
                    release=model["release_year"],
                    status=model["status"],
                    last_test=model_last_test_label(model),
                    profile=model.get("last_profile", "-"),
                    duration=format_metric(metrics.get("last_duration_ms"), "ms"),
                    token_summary=token_summary,
                    tokens_per_second=format_metric(metrics.get("tokens_per_second"), " tok/s"),
                    notes=model["notes"],
                )
            )

        lines.append("")

    return "\n".join(lines).rstrip() + "\n"


def main() -> None:
    data = json.loads(CATALOG_PATH.read_text(encoding="utf-8"))
    markdown_path = REPO_ROOT / data["markdown_output"]
    markdown_path.write_text(render(), encoding="utf-8")


if __name__ == "__main__":
    main()

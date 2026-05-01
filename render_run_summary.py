#!/usr/bin/env python3

import argparse
import json
import os
from datetime import datetime
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]


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
    raw_offset = local.strftime("%z")
    offset = f"{raw_offset[:3]}:{raw_offset[3:]}"
    return f"{local:%Y-%m-%d %H:%M:%S} {local.tzname()} ({offset})"


def relative_link(summary_dir: Path, log_path: str) -> str:
    target = Path(log_path)
    if not target.is_absolute():
        target = (REPO_ROOT / target).resolve()
    return os.path.relpath(target, summary_dir)


def fenced_block(text: str, language: str = "text") -> list[str]:
    content = text.rstrip("\n")
    if not content:
        content = "(leer)"
    return [f"````{language}", content, "````"]


def language_for_kind(kind: str) -> str:
    mapping = {
        "csharp": "csharp",
        "gdscript": "gdscript",
    }
    return mapping.get(kind, "text")


def render_single(run: dict, summary_path: Path) -> str:
    metrics = run.get("metrics", {})
    summary_dir = summary_path.parent
    run_log_link = relative_link(summary_dir, run["log_path"])
    lines = [
        "# Run-Zusammenfassung",
        "",
        f"Quelle: [`{Path(run_log_link).name}`]({run_log_link})",
        "",
        "## Metadaten",
        "",
        "| Feld | Wert |",
        "|---|---|",
        f"| Run-ID | `{run['run_id']}` |",
        f"| Modell | `{run['model']}` |",
        f"| Typ | `{run['kind']}` |",
        f"| Profil | `{run['profile']}` |",
        f"| Ergebnis | `{run['result']}` |",
        f"| Suggested status | `{run['suggested_status']}` |",
        f"| Start | `{format_local_timestamp(run['started_at'])}` |",
        f"| Ende | `{format_local_timestamp(run['finished_at'])}` |",
        f"| Dauer | `{format_metric(run.get('duration_ms'), 'ms')}` |",
        "",
        "## Hinweise",
        "",
    ]

    if run.get("notes"):
        for note in run["notes"]:
            lines.append(f"- {note}")
    else:
        lines.append("- -")

    lines.extend(["", "## Issues", ""])
    if run.get("issues"):
        for issue in run["issues"]:
            lines.append(f"- `{issue}`")
    else:
        lines.append("- `-`")

    lines.extend(
        [
            "",
            "## Metriken",
            "",
            "| Metrik | Wert |",
            "|---|---|",
            f"| Duration | `{format_metric(run.get('duration_ms'), 'ms')}` |",
            f"| Prompt eval count | `{format_metric(metrics.get('prompt_eval_count'))}` |",
            f"| Eval count | `{format_metric(metrics.get('eval_count'))}` |",
            f"| Tokens/s | `{format_metric(metrics.get('tokens_per_second'), ' tok/s')}` |",
            f"| Prompt eval duration | `{format_metric(metrics.get('prompt_eval_duration_ns'), ' ns')}` |",
            f"| Eval duration | `{format_metric(metrics.get('eval_duration_ns'), ' ns')}` |",
            f"| Total duration | `{format_metric(metrics.get('total_duration_ns'), ' ns')}` |",
            f"| Load duration | `{format_metric(metrics.get('load_duration_ns'), ' ns')}` |",
            "",
            "## Prompt",
            "",
        ]
    )
    lines.extend(fenced_block(run.get("prompt", ""), "text"))
    lines.extend(["", "## Antwort", ""])
    lines.extend(fenced_block(run.get("response", ""), language_for_kind(run.get("kind", ""))))

    stderr = run.get("stderr", "").strip()
    if stderr:
        lines.extend(["", "## stderr", ""])
        lines.extend(fenced_block(stderr, "text"))

    raw_response = run.get("raw_response", "").strip()
    response = run.get("response", "").strip()
    if raw_response and raw_response != response:
        lines.extend(["", "<details>", "<summary>Raw response</summary>", ""])
        lines.extend(fenced_block(raw_response, "json"))
        lines.extend(["", "</details>"])

    return "\n".join(lines).rstrip() + "\n"


def load_run_details(batch: dict) -> list[dict]:
    detailed_runs = []
    for entry in batch.get("runs", []):
        item = dict(entry)
        log_path = REPO_ROOT / entry["log_path"]
        if log_path.exists():
            item["details"] = json.loads(log_path.read_text(encoding="utf-8"))
        detailed_runs.append(item)
    return detailed_runs


def render_batch(batch: dict, summary_path: Path) -> str:
    summary_dir = summary_path.parent
    batch_log_link = relative_link(summary_dir, batch["log_path"])
    detailed_runs = load_run_details(batch)
    selector = batch.get("selector", {})
    selector_value = []
    if selector.get("group"):
        selector_value.append(f"group={selector['group']}")
    if selector.get("models"):
        selector_value.append("models=" + ",".join(selector["models"]))
    lines = [
        "# Batch-Zusammenfassung",
        "",
        f"Quelle: [`{Path(batch_log_link).name}`]({batch_log_link})",
        "",
        "## Metadaten",
        "",
        "| Feld | Wert |",
        "|---|---|",
        f"| Batch-ID | `{batch['batch_id']}` |",
        f"| Typ | `{batch['kind']}` |",
        f"| Profil | `{batch['profile']}` |",
        f"| Persistiert | `{'ja' if batch.get('persisted_to_catalog') else 'nein'}` |",
        f"| Start | `{format_local_timestamp(batch['started_at'])}` |",
        f"| Ende | `{format_local_timestamp(batch['finished_at'])}` |",
        f"| Auswahl | `{'; '.join(selector_value) if selector_value else '-'}` |",
        "",
        "## Status-Summary",
        "",
        "| Status | Anzahl |",
        "|---|---|",
    ]

    for status in sorted(batch.get("summary", {})):
        lines.append(f"| `{status}` | `{batch['summary'][status]}` |")

    lines.extend(["", "## Ergebnisse", "", "| Model | Result | Status | Duration | Tok/s | Log |", "|---|---|---|---|---|---|"])

    for run in detailed_runs:
        log_link = relative_link(summary_dir, run["log_path"])
        duration = format_metric(run.get("duration_ms"), "ms")
        tps = format_metric(run.get("tokens_per_second"), " tok/s")
        lines.append(f"| `{run['model']}` | `{run['result']}` | `{run['suggested_status']}` | `{duration}` | `{tps}` | [`{Path(log_link).name}`]({log_link}) |")

    lines.extend(["", "## Details", ""])

    for run in detailed_runs:
        details = run.get("details")
        if not details:
            continue
        log_link = relative_link(summary_dir, run["log_path"])
        lines.extend([f"<details>", f"<summary>{run['model']}</summary>", ""])
        lines.append(f"- Result: `{details['result']}`")
        lines.append(f"- Suggested status: `{details['suggested_status']}`")
        lines.append(f"- Duration: `{format_metric(details.get('duration_ms'), 'ms')}`")
        lines.append(f"- Tokens/s: `{format_metric(details.get('metrics', {}).get('tokens_per_second'), ' tok/s')}`")
        lines.append(f"- Log: [`{Path(log_link).name}`]({log_link})")
        lines.append(f"- Notes: {'; '.join(details.get('notes', [])) if details.get('notes') else '-'}")
        lines.append(f"- Issues: {', '.join(f'`{issue}`' for issue in details.get('issues', [])) if details.get('issues') else '`-`'}")
        lines.extend(["", "Prompt:", ""])
        lines.extend(fenced_block(details.get("prompt", ""), "text"))
        lines.extend(["", "Antwort:", ""])
        lines.extend(fenced_block(details.get("response", ""), language_for_kind(details.get("kind", ""))))
        stderr = details.get("stderr", "").strip()
        if stderr:
            lines.extend(["", "stderr:", ""])
            lines.extend(fenced_block(stderr, "text"))
        lines.extend(["", "</details>", ""])

    return "\n".join(lines).rstrip() + "\n"


def render_log(log_path: Path) -> Path:
    payload = json.loads(log_path.read_text(encoding="utf-8"))
    summary_path = log_path.parent / "summary.md"
    if "batch_id" in payload:
        markdown = render_batch(payload, summary_path)
    elif "run_id" in payload:
        markdown = render_single(payload, summary_path)
    else:
        raise ValueError(f"Unsupported log format: {log_path}")
    summary_path.write_text(markdown, encoding="utf-8")
    return summary_path


def main() -> None:
    parser = argparse.ArgumentParser(description="Render Ollama run logs to summary.md files.")
    parser.add_argument("log_paths", nargs="+", help="Path to run.json or batch.json")
    args = parser.parse_args()

    for raw_path in args.log_paths:
        log_path = Path(raw_path).resolve()
        summary_path = render_log(log_path)
        print(summary_path)


if __name__ == "__main__":
    main()

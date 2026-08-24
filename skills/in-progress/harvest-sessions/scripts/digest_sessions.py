#!/usr/bin/env python3
"""Emit compact digests of recent Claude Code and Codex sessions.

Transcripts are mostly tool traffic. A digest keeps only the human turns and the
agent's prose replies, which is what capture judgement actually reads, and drops
the reasoning, tool calls, and tool output that make a raw transcript unreadable
at any useful volume.
"""

from __future__ import annotations

import argparse
import json
import os
import pathlib
import re
import sys
import time

CLAUDE_ROOT = pathlib.Path.home() / ".claude" / "projects"
CODEX_ROOTS = [
    pathlib.Path.home() / ".codex" / "sessions",
    pathlib.Path.home() / ".codex" / "archived_sessions",
]
DEFAULT_WATERMARK = pathlib.Path.home() / ".local/state/secondbrain-harvest/watermark"

# Ordered most-specific first so a token is not partly consumed by a looser rule.
SECRET_PATTERNS = [
    re.compile(r"\b(?:sk|rk)-[A-Za-z0-9_-]{16,}"),
    re.compile(r"\bgh[pousr]_[A-Za-z0-9]{16,}"),
    re.compile(r"\bgithub_pat_[A-Za-z0-9_]{20,}"),
    re.compile(r"\bxox[abposr]-[A-Za-z0-9-]{10,}"),
    re.compile(r"\bAKIA[0-9A-Z]{16}\b"),
    re.compile(r"\bAIza[0-9A-Za-z_-]{30,}"),
    re.compile(r"\beyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}"),
    re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----[\s\S]*?-----END [A-Z ]*PRIVATE KEY-----"),
    re.compile(r"(?i)\b(?:authorization|bearer)\b[:=\s]+[A-Za-z0-9._~+/-]{20,}"),
    re.compile(r"(?i)\b\w*(?:api[_-]?key|secret|passwd|password|token)\w*\b\s*[:=]\s*[\"']?[A-Za-z0-9._~+/-]{12,}[\"']?"),
]


def redact(text: str) -> str:
    for pattern in SECRET_PATTERNS:
        text = pattern.sub("[REDACTED]", text)
    return text


def clip(text: str, limit: int) -> str:
    text = re.sub(r"\n{3,}", "\n\n", text.strip())
    if len(text) <= limit:
        return text
    return text[:limit] + f"\n[... {len(text) - limit} more chars]"


def _is_harvest_session(text: str) -> bool:
    return bool(
        re.search(
            r"^(?:Use\s+)?[$/]harvest-sessions\b|<command-name>/harvest-sessions</command-name>",
            text.strip(),
        )
    )


def read_jsonl(path: pathlib.Path):
    with path.open(encoding="utf-8", errors="replace") as handle:
        for line in handle:
            line = line.strip()
            if not line:
                continue
            try:
                yield json.loads(line)
            except json.JSONDecodeError:
                continue


def extract_claude(path: pathlib.Path) -> dict | None:
    title, cwd, turns = None, None, []
    for record in read_jsonl(path):
        kind = record.get("type")
        if kind == "ai-title" and record.get("aiTitle"):
            title = record["aiTitle"]
        if not cwd and record.get("cwd"):
            cwd = record["cwd"]
        if kind not in ("user", "assistant"):
            continue
        content = (record.get("message") or {}).get("content")
        if isinstance(content, str):
            text = content
        elif isinstance(content, list):
            # tool_result blocks also arrive under role "user"; only text is a real turn.
            text = "\n".join(b.get("text", "") for b in content if isinstance(b, dict) and b.get("type") == "text")
        else:
            continue
        if text.strip():
            turns.append((kind, text))
    if not turns:
        return None
    return {"agent": "claude", "path": str(path), "title": title, "cwd": cwd, "turns": turns}


def extract_codex(path: pathlib.Path) -> dict | None:
    cwd, turns = None, []
    for record in read_jsonl(path):
        if record.get("type") == "session_meta":
            cwd = cwd or (record.get("payload") or {}).get("cwd")
            continue
        if record.get("type") != "response_item":
            continue
        payload = record.get("payload") or {}
        if payload.get("type") != "message":
            continue
        role = payload.get("role")
        if role not in ("user", "assistant"):
            continue
        text = "\n".join(
            b.get("text", "")
            for b in payload.get("content") or []
            if isinstance(b, dict) and b.get("type") in ("input_text", "output_text")
        )
        if text.strip():
            turns.append((role, text))
    if not turns:
        return None
    return {"agent": "codex", "path": str(path), "title": None, "cwd": cwd, "turns": turns}


def find_sessions(since: float):
    for root, extractor, glob in (
        (CLAUDE_ROOT, extract_claude, "*/*.jsonl"),
        *((r, extract_codex, "**/rollout-*.jsonl") for r in CODEX_ROOTS),
    ):
        if not root.exists():
            continue
        for path in root.glob(glob):
            try:
                if path.stat().st_mtime <= since:
                    continue
            except OSError:
                continue
            yield path, extractor


def load_since(args) -> float:
    if args.since:
        return time.mktime(time.strptime(args.since, "%Y-%m-%dT%H:%M:%S"))
    if args.watermark.exists():
        return args.watermark.stat().st_mtime
    return time.time() - args.default_window_hours * 3600


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--since", help="local ISO time (YYYY-MM-DDTHH:MM:SS); overrides the watermark")
    parser.add_argument("--watermark", type=pathlib.Path, default=DEFAULT_WATERMARK)
    parser.add_argument("--default-window-hours", type=float, default=24.0)
    parser.add_argument("--min-user-turns", type=int, default=2, help="skip sessions shorter than this")
    parser.add_argument("--max-turn-chars", type=int, default=1200)
    parser.add_argument("--max-session-chars", type=int, default=12000)
    parser.add_argument("--list", action="store_true", help="one metadata line per session, no bodies")
    parser.add_argument("--count", action="store_true", help="print how many transcripts are newer than the watermark; parses nothing")
    parser.add_argument("--only", help="digest just this transcript path, ignoring every filter")
    parser.add_argument("--commit-watermark", action="store_true", help="stamp the watermark to now and exit 0")
    args = parser.parse_args()

    if args.commit_watermark:
        args.watermark.parent.mkdir(parents=True, exist_ok=True)
        args.watermark.touch()
        print(f"watermark stamped: {args.watermark}")
        return 0

    if args.count:
        # A scheduler gate runs this every tick, so it stops at mtime and never opens a file.
        print(sum(1 for _ in find_sessions(load_since(args))))
        return 0

    if args.only:
        path = pathlib.Path(args.only)
        extractor = extract_claude if ".claude" in path.parts else extract_codex
        candidates = [(path, extractor)]
    else:
        candidates = sorted(find_sessions(load_since(args)), key=lambda c: c[0].stat().st_mtime)

    emitted = 0
    for path, extractor in candidates:
        session = extractor(path)
        if not session:
            continue
        user_turns = [t for t in session["turns"] if t[0] == "user"]
        first_user = user_turns[0][1].strip() if user_turns else ""
        # The harvest job's own sessions would otherwise recycle their findings forever.
        if _is_harvest_session(first_user):
            continue
        if not args.only and len(user_turns) < args.min_user_turns:
            continue

        emitted += 1
        header = f"session: {path}\nagent: {session['agent']}  cwd: {session['cwd']}  turns: {len(session['turns'])}"
        if session["title"]:
            header += f"\ntitle: {session['title']}"
        if args.list:
            print(header + "\n" + "-" * 72)
            continue

        body, budget = [], args.max_session_chars
        for role, text in session["turns"]:
            chunk = f"[{role}] {clip(redact(text), args.max_turn_chars)}"
            if budget - len(chunk) < 0:
                body.append(f"[... {len(session['turns']) - len(body)} further turns omitted]")
                break
            budget -= len(chunk)
            body.append(chunk)
        print("=" * 72)
        print(header)
        print("-" * 72)
        print("\n\n".join(body))
        print()

    print(f"[{emitted} session(s) digested]", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())

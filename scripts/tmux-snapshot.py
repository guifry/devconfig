#!/usr/bin/env python3
from __future__ import annotations
import json
import os
import re
import shlex
import sqlite3
import subprocess
import sys
from dataclasses import asdict, dataclass, field
from datetime import datetime
from pathlib import Path

HOME = Path.home()
STATE = HOME / ".local/state/tmux-snapshots"
CLAUDE_SESSIONS = HOME / ".claude/sessions"
OPENCODE_DB = HOME / ".local/share/opencode/opencode.db"
PANE_FORMAT = "#{session_name}\t#{window_index}\t#{window_name}\t#{window_layout}\t#{pane_index}\t#{pane_id}\t#{pane_pid}\t#{pane_current_path}\t#{pane_current_command}\t#{pane_title}\t#{window_active}\t#{pane_active}"


@dataclass
class Pane:
    session: str
    window_index: int
    window_name: str
    layout: str
    pane_index: int
    pane_id: str
    pane_pid: int
    cwd: str
    command: str
    title: str
    window_active: bool
    pane_active: bool
    program: str = "shell"
    resume_dir: str = ""
    resume: str = ""
    note: str = ""


@dataclass
class Snapshot:
    taken_at: str
    panes: list[Pane] = field(default_factory=list)


class ProcessTree:
    def __init__(self) -> None:
        output = subprocess.run(["ps", "-Ao", "pid=,ppid=,args="], capture_output=True, text=True).stdout
        self.children: dict[int, list[int]] = {}
        self.args: dict[int, str] = {}
        for line in output.splitlines():
            parts = line.strip().split(None, 2)
            if len(parts) < 2:
                continue
            pid, ppid = int(parts[0]), int(parts[1])
            self.args[pid] = parts[2] if len(parts) > 2 else ""
            self.children.setdefault(ppid, []).append(pid)

    def descendants(self, pid: int) -> list[int]:
        found, stack = [], list(self.children.get(pid, []))
        while stack:
            current = stack.pop()
            found.append(current)
            stack.extend(self.children.get(current, []))
        return found


class ClaudeSessions:
    def __init__(self) -> None:
        self.by_pid: dict[int, dict] = {}
        for path in CLAUDE_SESSIONS.glob("*.json"):
            try:
                record = json.loads(path.read_text())
                self.by_pid[int(record["pid"])] = record
            except (ValueError, KeyError, OSError):
                continue

    def find(self, pids: list[int]) -> dict | None:
        return next((self.by_pid[pid] for pid in pids if pid in self.by_pid), None)


class OpencodeSessions:
    def __init__(self) -> None:
        self.rows: list[tuple[str, str, str, int]] = []
        if not OPENCODE_DB.exists():
            return
        connection = sqlite3.connect(f"file:{OPENCODE_DB}?mode=ro", uri=True)
        try:
            self.rows = connection.execute(
                "select id, title, directory, time_updated from session_v2 union all "
                "select id, title, directory, time_updated from session order by time_updated desc"
            ).fetchall()
        finally:
            connection.close()

    def find(self, title: str, cwd: str) -> tuple[str, str] | None:
        wanted = re.sub(r"^OC \| ", "", title).rstrip("…").strip()
        if not wanted:
            return None
        matches = [row for row in self.rows if row[1] and row[1].startswith(wanted)]
        preferred = [row for row in matches if row[2] == cwd] or matches
        return (preferred[0][0], preferred[0][2]) if preferred else None


class CodexSessions:
    PATTERN = re.compile(r"rollout-[0-9T:-]+-([0-9a-f-]{36})")
    ROOT = HOME / ".codex/sessions"

    def __init__(self) -> None:
        self.latest: dict[str, tuple[float, str]] = {}
        for path in self.ROOT.glob("*/*/*/rollout-*.jsonl"):
            try:
                with path.open() as handle:
                    meta = json.loads(handle.readline())["payload"]
            except (ValueError, KeyError, OSError):
                continue
            if meta.get("parent_thread_id") or not meta.get("cwd") or not meta.get("id"):
                continue
            modified = path.stat().st_mtime
            if modified > self.latest.get(meta["cwd"], (0.0, ""))[0]:
                self.latest[meta["cwd"]] = (modified, meta["id"])

    def find(self, pids: list[int], cwd: str) -> str | None:
        for pid in pids:
            output = subprocess.run(["lsof", "-p", str(pid)], capture_output=True, text=True).stdout
            match = self.PATTERN.search(output)
            if match:
                return match.group(1)
        return self.latest.get(cwd, (0.0, None))[1]


class PaneClassifier:
    SWITCHES = {"--dangerously-skip-permissions"}
    VALUED = {"--model", "--effort", "--permission-mode"}

    def __init__(self) -> None:
        self.tree = ProcessTree()
        self.claude = ClaudeSessions()
        self.opencode = OpencodeSessions()
        self.codex = CodexSessions()

    def classify(self, pane: Pane) -> Pane:
        pids = self.tree.descendants(pane.pane_pid)
        claude = self.claude.find(pids)
        if claude is not None:
            return self._claude(pane, pids, claude)
        if self._runs(pids, r"(^|/)opencode( |$)"):
            return self._opencode(pane)
        if self._runs(pids, r"(^|/)codex( |$)") or pane.command == "codex":
            return self._codex(pane, pids)
        if pane.command == "nvim":
            named = Path(pane.window_name).expanduser()
            pane.program = "nvim"
            pane.resume = shlex.join(["nvim", str(named)]) if named.is_file() else "nvim"
            return pane
        if pane.command not in {"zsh", "bash", "sh", "fish"}:
            pane.program, pane.note = "other", self._first_args(pids)
        return pane

    def _claude(self, pane: Pane, pids: list[int], record: dict) -> Pane:
        args = self.tree.args.get(record["pid"], "claude").split()
        flags: list[str] = []
        for position, token in enumerate(args[1:], 1):
            if token in self.SWITCHES:
                flags.append(token)
            elif token in self.VALUED and position + 1 < len(args):
                flags.extend([token, args[position + 1]])
        pane.program, pane.resume_dir = "claude", record.get("cwd", pane.cwd)
        pane.resume = shlex.join(["claude", *flags, "--resume", record["sessionId"]])
        return pane

    def _opencode(self, pane: Pane) -> Pane:
        pane.program = "opencode"
        found = self.opencode.find(pane.title, pane.cwd)
        if found is None:
            pane.resume, pane.note = "opencode", "session not identified from title"
            return pane
        pane.resume_dir, pane.resume = pane.cwd, shlex.join(["opencode", "--session", found[0]])
        return pane

    def _codex(self, pane: Pane, pids: list[int]) -> Pane:
        pane.program = "codex"
        session = self.codex.find(pids, pane.cwd)
        pane.resume = shlex.join(["codex", "resume", session]) if session else "codex resume --last"
        pane.note = "" if session else "session not identified; resumes the last one"
        return pane

    def _runs(self, pids: list[int], pattern: str) -> bool:
        return any(re.search(pattern, self.tree.args.get(pid, "")) for pid in pids)

    def _first_args(self, pids: list[int]) -> str:
        return self.tree.args.get(pids[0], "") if pids else ""


class TmuxSnapshot:
    def __init__(self, classifier: PaneClassifier) -> None:
        self.classifier = classifier

    def take(self) -> Snapshot:
        output = subprocess.run(["tmux", "list-panes", "-a", "-F", PANE_FORMAT], capture_output=True, text=True, check=True).stdout
        snapshot = Snapshot(datetime.now().isoformat(timespec="seconds"))
        for line in output.splitlines():
            values = line.split("\t")
            pane = Pane(values[0], int(values[1]), values[2], values[3], int(values[4]), values[5], int(values[6]),
                        values[7], values[8], values[9], values[10] == "1", values[11] == "1")
            snapshot.panes.append(self.classifier.classify(pane))
        return snapshot


class RestoreScript:
    def render(self, snapshot: Snapshot) -> str:
        lines = ["#!/bin/zsh", f"# tmux snapshot taken {snapshot.taken_at}", ""]
        windows: dict[tuple[str, int], list[Pane]] = {}
        for pane in snapshot.panes:
            windows.setdefault((pane.session, pane.window_index), []).append(pane)
        created: set[str] = set()
        for (session, index), panes in sorted(windows.items()):
            panes.sort(key=lambda pane: pane.pane_index)
            first, target = panes[0], f"{session}:{index}"
            if session not in created:
                lines.append(f"tmux has-session -t {shlex.quote(session)} 2>/dev/null || tmux new-session -d -s {shlex.quote(session)} -n {shlex.quote(first.window_name)} -c {shlex.quote(first.cwd)}")
                lines.append(f"tmux move-window -s {shlex.quote(session)}:$(tmux list-windows -t {shlex.quote(session)} -F '#{{window_index}}' | head -1) -t {shlex.quote(target)} 2>/dev/null")
                created.add(session)
            else:
                lines.append(f"tmux new-window -d -t {shlex.quote(target)} -n {shlex.quote(first.window_name)} -c {shlex.quote(first.cwd)}")
            for pane in panes[1:]:
                lines.append(f"tmux split-window -d -t {shlex.quote(target)} -c {shlex.quote(pane.cwd)}")
            lines.append(f"tmux select-layout -t {shlex.quote(target)} {shlex.quote(first.layout)}")
            for position, pane in enumerate(panes):
                command = self._command(pane)
                if command:
                    lines.append(f"tmux send-keys -t {shlex.quote(f'{target}.{position}')} {shlex.quote(command)} Enter")
            lines.append("")
        return "\n".join(lines) + "\n"

    @staticmethod
    def _command(pane: Pane) -> str:
        if not pane.resume:
            return ""
        directory = pane.resume_dir or pane.cwd
        return f"cd {shlex.quote(directory)} && {pane.resume}"


class SnapshotStore:
    def save(self, snapshot: Snapshot, script: str) -> Path:
        folder = STATE / snapshot.taken_at.replace(":", "")
        folder.mkdir(parents=True, exist_ok=True)
        (folder / "snapshot.json").write_text(json.dumps([asdict(pane) for pane in snapshot.panes], indent=2))
        restore = folder / "restore.sh"
        restore.write_text(script)
        restore.chmod(0o755)
        latest = STATE / "latest"
        if latest.is_symlink() or latest.exists():
            latest.unlink()
        latest.symlink_to(folder)
        return folder


class Report:
    def print(self, snapshot: Snapshot, folder: Path) -> None:
        for pane in snapshot.panes:
            label = f"{pane.session}:{pane.window_index}.{pane.pane_index} {pane.window_name}"
            detail = pane.resume or pane.note or "shell"
            warning = f"  [{pane.note}]" if pane.note and pane.resume else ""
            print(f"{label[:45]:45} {pane.program:9} {Path(pane.resume_dir or pane.cwd).name[:32]:32} {detail[:90]}{warning}")
        print(f"\nSaved {len(snapshot.panes)} panes to {folder}\nRestore after reboot: {folder}/restore.sh")


if __name__ == "__main__":
    taken = TmuxSnapshot(PaneClassifier()).take()
    saved = SnapshotStore().save(taken, RestoreScript().render(taken))
    Report().print(taken, saved)
    sys.exit(0)

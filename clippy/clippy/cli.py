import os
import signal
import subprocess
import sys
from datetime import datetime
from pathlib import Path

import typer

from clippy import clipboard, storage


app = typer.Typer(help="Clipboard history manager")

PLIST_NAME = "com.clippy.daemon.plist"
PLIST_PATH = Path.home() / "Library" / "LaunchAgents" / PLIST_NAME
PID_FILE = storage.CLIPPY_DIR / "daemon.pid"


def _get_daemon_pid() -> int | None:
    if not PID_FILE.exists():
        return None
    try:
        pid = int(PID_FILE.read_text().strip())
        os.kill(pid, 0)
        return pid
    except (ValueError, ProcessLookupError, PermissionError):
        PID_FILE.unlink(missing_ok=True)
        return None


@app.command()
def start() -> None:
    """Start the clipboard daemon."""
    if _get_daemon_pid():
        typer.echo("Daemon already running")
        raise typer.Exit(1)

    storage.ensure_dir()

    env = os.environ.copy()
    proc = subprocess.Popen(
        [sys.executable, "-m", "clippy.daemon"],
        start_new_session=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        env=env,
    )

    PID_FILE.write_text(str(proc.pid))
    typer.echo(f"Daemon started (pid {proc.pid})")


@app.command()
def stop() -> None:
    """Stop the clipboard daemon."""
    pid = _get_daemon_pid()
    if not pid:
        typer.echo("Daemon not running")
        raise typer.Exit(1)

    try:
        os.kill(pid, signal.SIGTERM)
        PID_FILE.unlink(missing_ok=True)
        typer.echo("Daemon stopped")
    except ProcessLookupError:
        PID_FILE.unlink(missing_ok=True)
        typer.echo("Daemon was not running")


@app.command()
def status() -> None:
    """Check daemon status."""
    pid = _get_daemon_pid()
    if pid:
        typer.echo(f"Running (pid {pid})")
    else:
        typer.echo("Not running")


@app.command("list")
def list_history(limit: int = typer.Option(10, help="Number of items")) -> None:
    """List clipboard history."""
    items = storage.get_items(limit=limit)
    if not items:
        typer.echo("No history")
        return

    for i, item in enumerate(items):
        ts = datetime.fromtimestamp(item["ts"]).strftime("%H:%M:%S")
        content = item["content"].replace("\n", "\\n")[:60]
        typer.echo(f"{i + 1}. [{ts}] {content}")


@app.command()
def get(n: int = typer.Argument(..., help="History item number (1-based)")) -> None:
    """Print history item to stdout."""
    items = storage.get_items()
    if n < 1 or n > len(items):
        typer.echo(f"Invalid index: {n}", err=True)
        raise typer.Exit(1)
    typer.echo(items[n - 1]["content"], nl=False)


@app.command()
def yank(n: int = typer.Argument(..., help="History item number (1-based)")) -> None:
    """Copy history item to clipboard."""
    items = storage.get_items()
    if n < 1 or n > len(items):
        typer.echo(f"Invalid index: {n}", err=True)
        raise typer.Exit(1)
    clipboard.write(items[n - 1]["content"])
    typer.echo(f"Yanked item {n} to clipboard")


@app.command()
def clear() -> None:
    """Clear clipboard history."""
    storage.clear_history()
    typer.echo("History cleared")


if __name__ == "__main__":
    app()

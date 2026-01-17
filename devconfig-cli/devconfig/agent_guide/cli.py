"""Agent Guide CLI subcommands."""

from pathlib import Path
from typing import Annotated, Optional

import typer

app = typer.Typer(
    name="agent-guide",
    help="Manage coding agent guidelines across repos",
    no_args_is_help=True,
)


@app.command("build")
def build_guide(
    output_dir: Annotated[
        Path, typer.Option("--output", "-o", help="Output directory")
    ] = Path("."),
    formats: Annotated[
        Optional[list[str]],
        typer.Option("--format", "-f", help="Output formats: claude, cursor, windsurf"),
    ] = None,
):
    """Interactive TUI to build agent.md from guideline database."""
    from .tui.app import AgentGuideApp

    formats = formats or ["claude"]
    tui_app = AgentGuideApp(output_dir=output_dir, formats=formats)
    tui_app.run()


def _resolve_path(path: Path) -> Path:
    """Resolve path relative to original CWD (before uv changed it)."""
    import os
    orig_cwd = os.environ.get("DEVCONFIG_ORIG_CWD")
    if orig_cwd and not path.is_absolute():
        return (Path(orig_cwd) / path).resolve()
    return path.resolve()


@app.command("collect")
def collect_guide(
    path: Annotated[Path, typer.Argument(help="Path to repo with agent configs")],
    dry_run: Annotated[
        bool, typer.Option("--dry-run", "-n", help="Preview without saving")
    ] = False,
    verbose: Annotated[
        bool, typer.Option("--verbose", "-v", help="Show debug info")
    ] = False,
):
    """Collect guidelines from existing agent configs in a repo."""
    import os
    from .tui.app import CollectorApp

    resolved = _resolve_path(path)

    if verbose:
        typer.echo(f"Original CWD: {os.environ.get('DEVCONFIG_ORIG_CWD', 'not set')}")
        typer.echo(f"Input path: {path}")
        typer.echo(f"Resolved path: {resolved}")
        typer.echo(f"Exists: {resolved.exists()}")

    if not resolved.exists():
        typer.echo(f"Error: Path does not exist: {resolved}", err=True)
        raise typer.Exit(1)

    tui_app = CollectorApp(repo_path=resolved, dry_run=dry_run)
    tui_app.run()


@app.command("list")
def list_blocks(
    category: Annotated[
        Optional[str], typer.Option("--category", "-c", help="Filter by category")
    ] = None,
    language: Annotated[
        Optional[str], typer.Option("--language", "-l", help="Filter by language")
    ] = None,
):
    """List blocks in the guideline database."""
    from .db import BlockStore

    store = BlockStore()
    blocks = store.get_all_blocks(category)

    if language:
        lang_filter = None if language == "generic" else language
        blocks = [b for b in blocks if b.tags.language == lang_filter]

    if not blocks:
        typer.echo("No blocks found.")
        return

    for block in blocks:
        lang = block.tags.language or "generic"
        repos = ", ".join(block.used_by_repos) if block.used_by_repos else block.origin_repo
        typer.echo(f"[{lang}] {block.id} (from: {repos})")
        preview = block.content[:80].replace("\n", " ")
        if len(block.content) > 80:
            preview += "..."
        typer.echo(f"  {preview}\n")

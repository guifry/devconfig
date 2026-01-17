"""Main devconfig CLI - registers all sub-features."""

import typer

from .agent_guide import agent_guide_app

app = typer.Typer(
    name="devconfig",
    help="Developer configuration tools",
    no_args_is_help=True,
)

# Register sub-features
app.add_typer(agent_guide_app, name="agent-guide")


if __name__ == "__main__":
    app()

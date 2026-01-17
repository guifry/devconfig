"""Diff resolution screen for handling block nuances."""

from textual.app import ComposeResult
from textual.containers import Horizontal, ScrollableContainer, Vertical
from textual.screen import Screen
from textual.widgets import Button, Footer, Header, Label, Static

from ...models import Block, DedupMatch, ExtractedBlock


class DiffResolveScreen(Screen):
    """Screen for resolving differences between new and existing blocks."""

    CSS = """
    DiffResolveScreen {
        layout: vertical;
    }

    .diff-container {
        layout: horizontal;
        height: 1fr;
        margin: 1 2;
    }

    .block-panel {
        width: 1fr;
        margin: 0 1;
        padding: 1;
        border: solid $surface;
    }

    .block-panel.selected {
        border: solid $primary;
    }

    .panel-title {
        text-style: bold;
        background: $primary;
        padding: 0 1;
        margin-bottom: 1;
    }

    .block-content {
        height: auto;
    }

    #nuances {
        margin: 1 2;
        padding: 1;
        background: $warning 20%;
        border: solid $warning;
    }

    #nuances-title {
        text-style: bold;
        margin-bottom: 1;
    }

    #button-bar {
        dock: bottom;
        height: 3;
        padding: 1;
    }
    """

    def __init__(
        self,
        new_block: ExtractedBlock,
        existing_block: Block,
        match: DedupMatch,
        *args,
        **kwargs,
    ):
        super().__init__(*args, **kwargs)
        self.new_block = new_block
        self.existing_block = existing_block
        self.match = match

    def compose(self) -> ComposeResult:
        yield Header()

        with Vertical(id="nuances"):
            yield Label("Differences detected:", id="nuances-title")
            yield Label(self.match.nuances or "Blocks are similar but have different wording.")

        with Horizontal(classes="diff-container"):
            with Vertical(classes="block-panel", id="existing-panel"):
                yield Label(f"Existing: {self.existing_block.id}", classes="panel-title")
                yield Label(f"From: {self.existing_block.origin_repo}", classes="block-origin")
                yield Static(self.existing_block.content, classes="block-content")

            with Vertical(classes="block-panel", id="new-panel"):
                yield Label(f"New: {self.new_block.suggested_id}", classes="panel-title")
                yield Label("From: current repo", classes="block-origin")
                yield Static(self.new_block.content, classes="block-content")

        with Horizontal(id="button-bar"):
            yield Button("Keep Existing", id="keep-existing-btn")
            yield Button("Use New", id="use-new-btn", variant="primary")
            yield Button("Skip Both", id="skip-btn")

        yield Footer()

    def on_button_pressed(self, event: Button.Pressed) -> None:
        """Handle button presses."""
        if event.button.id == "keep-existing-btn":
            self.dismiss({"action": "keep_existing"})
        elif event.button.id == "use-new-btn":
            self.dismiss({"action": "use_new"})
        elif event.button.id == "skip-btn":
            self.dismiss({"action": "skip"})

"""Block selection screen with checkboxes."""

from textual.app import ComposeResult
from textual.containers import Container, Horizontal, ScrollableContainer, Vertical
from textual.screen import Screen
from textual.widgets import Button, Checkbox, Footer, Header, Label, Static

from ...models import Block


class BlockCard(Static):
    """Widget displaying a single block with checkbox."""

    DEFAULT_CSS = """
    BlockCard {
        layout: horizontal;
        height: auto;
        margin: 0 0 1 0;
        padding: 1;
        border: solid $surface;
    }

    BlockCard:hover {
        border: solid $primary;
    }

    BlockCard .block-content {
        width: 1fr;
        padding-left: 1;
    }

    BlockCard .block-id {
        text-style: bold;
    }

    BlockCard .block-origin {
        color: $text-muted;
    }

    BlockCard .block-preview {
        margin-top: 1;
    }
    """

    def __init__(self, block: Block, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.block = block

    def compose(self) -> ComposeResult:
        yield Checkbox("", id=f"block-{self.block.id}", classes="block-checkbox")
        with Vertical(classes="block-content"):
            origin = self.block.origin_repo
            if len(self.block.used_by_repos) > 1:
                origin += f" +{len(self.block.used_by_repos) - 1}"
            yield Label(f"{self.block.id}  [dim](from: {origin})[/dim]", classes="block-id")
            preview = self.block.content[:100].replace("\n", " ")
            if len(self.block.content) > 100:
                preview += "..."
            yield Label(preview, classes="block-preview")


class BlockSelectScreen(Screen):
    """Screen for selecting blocks to include in output."""

    CSS = """
    BlockSelectScreen {
        layout: vertical;
    }

    .category-section {
        margin: 1 2;
        padding: 1;
    }

    .category-title {
        text-style: bold;
        background: $primary;
        padding: 0 1;
        margin-bottom: 1;
    }

    #block-container {
        height: 1fr;
    }

    #button-bar {
        dock: bottom;
        height: 3;
        padding: 1;
    }
    """

    def __init__(
        self,
        blocks_by_category: dict[str, list[Block]],
        preferences: dict,
        *args,
        **kwargs,
    ):
        super().__init__(*args, **kwargs)
        self.blocks_by_category = blocks_by_category
        self.preferences = preferences
        self.selected_block_ids: set[str] = set()

    def compose(self) -> ComposeResult:
        yield Header()

        with ScrollableContainer(id="block-container"):
            # Always show generic first
            if "generic" in self.blocks_by_category:
                with Vertical(classes="category-section"):
                    yield Label("── Generic ──", classes="category-title")
                    for block in self.blocks_by_category["generic"]:
                        yield BlockCard(block)

            # Then language-specific
            for category, blocks in self.blocks_by_category.items():
                if category == "generic":
                    continue
                with Vertical(classes="category-section"):
                    yield Label(f"── {category.capitalize()} ──", classes="category-title")
                    for block in blocks:
                        yield BlockCard(block)

        with Horizontal(id="button-bar"):
            yield Button("← Back", id="back-btn")
            yield Button("Generate →", id="generate-btn", variant="primary")

        yield Footer()

    def on_checkbox_changed(self, event: Checkbox.Changed) -> None:
        """Track selected blocks."""
        checkbox_id = event.checkbox.id
        if checkbox_id.startswith("block-"):
            block_id = checkbox_id[6:]
            if event.value:
                self.selected_block_ids.add(block_id)
            else:
                self.selected_block_ids.discard(block_id)

    def on_button_pressed(self, event: Button.Pressed) -> None:
        """Handle button presses."""
        if event.button.id == "generate-btn":
            if not self.selected_block_ids:
                self.notify("Select at least one block", severity="error")
                return
            self.dismiss({"selected_ids": list(self.selected_block_ids)})
        elif event.button.id == "back-btn":
            self.dismiss(None)  # Signal to go back

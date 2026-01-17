"""Review screen for collected blocks."""

from textual.app import ComposeResult
from textual.containers import Container, Horizontal, ScrollableContainer, Vertical
from textual.screen import Screen
from textual.widgets import Button, Footer, Header, Input, Label, Select, Static, TextArea

from ...models import ExtractedBlock, BlockTags
from ...config import CATEGORIES, ARCHITECTURES


class ReviewScreen(Screen):
    """Screen for reviewing and editing a single extracted block."""

    CSS = """
    ReviewScreen {
        layout: vertical;
    }

    .field {
        margin: 1 2;
    }

    .field-label {
        text-style: bold;
        margin-bottom: 1;
    }

    #content-area {
        height: 10;
        margin: 1 2;
    }

    .tag-row {
        layout: horizontal;
        height: auto;
        margin: 1 2;
    }

    .tag-field {
        width: 1fr;
        margin-right: 2;
    }

    #progress {
        dock: top;
        height: 1;
        background: $surface;
        padding: 0 2;
    }

    #button-bar {
        dock: bottom;
        height: 3;
        padding: 1;
    }
    """

    def __init__(
        self,
        block: ExtractedBlock,
        block_index: int,
        total_blocks: int,
        repo_name: str,
        *args,
        **kwargs,
    ):
        super().__init__(*args, **kwargs)
        self.block = block
        self.block_index = block_index
        self.total_blocks = total_blocks
        self.repo_name = repo_name

    def compose(self) -> ComposeResult:
        yield Header()

        yield Label(
            f"Block {self.block_index + 1}/{self.total_blocks} from {self.repo_name}",
            id="progress",
        )

        with ScrollableContainer():
            with Vertical(classes="field"):
                yield Label("Block ID", classes="field-label")
                yield Input(value=self.block.suggested_id, id="block-id-input")

            with Vertical(classes="field"):
                yield Label("Content", classes="field-label")
            yield TextArea(self.block.content, id="content-area")

            with Horizontal(classes="tag-row"):
                with Vertical(classes="tag-field"):
                    yield Label("Language", classes="field-label")
                    options = [("generic", "generic")] + [(c, c) for c in CATEGORIES if c != "generic"]
                    current = self.block.suggested_tags.language or "generic"
                    yield Select(options, value=current, id="lang-select")

                with Vertical(classes="tag-field"):
                    yield Label("Architecture", classes="field-label")
                    arch_opts = [("any", "any")] + [(a, a) for a in ARCHITECTURES]
                    current_arch = self.block.suggested_tags.architecture[0] if self.block.suggested_tags.architecture else "any"
                    yield Select(arch_opts, value=current_arch, id="arch-select")

            with Vertical(classes="field"):
                yield Label("Scope (comma-separated)", classes="field-label")
                scope_str = ", ".join(self.block.suggested_tags.scope)
                yield Input(value=scope_str, id="scope-input", placeholder="e.g., domain, testing, imports")

        with Horizontal(id="button-bar"):
            yield Button("Skip", id="skip-btn")
            yield Button("Edit", id="edit-btn")
            yield Button("Accept →", id="accept-btn", variant="primary")

        yield Footer()

    def _get_edited_block(self) -> ExtractedBlock:
        """Get block with current edits applied."""
        block_id = self.query_one("#block-id-input", Input).value
        content = self.query_one("#content-area", TextArea).text
        lang_select = self.query_one("#lang-select", Select)
        arch_select = self.query_one("#arch-select", Select)
        scope_input = self.query_one("#scope-input", Input)

        language = None if lang_select.value == "generic" else lang_select.value
        architecture = [] if arch_select.value == "any" else [arch_select.value]
        scope = [s.strip() for s in scope_input.value.split(",") if s.strip()]

        return ExtractedBlock(
            suggested_id=block_id,
            content=content,
            suggested_tags=BlockTags(
                language=language,
                architecture=architecture,
                scope=scope,
            ),
        )

    def on_button_pressed(self, event: Button.Pressed) -> None:
        """Handle button presses."""
        if event.button.id == "accept-btn":
            self.dismiss({"action": "accept", "block": self._get_edited_block()})
        elif event.button.id == "skip-btn":
            self.dismiss({"action": "skip"})
        elif event.button.id == "edit-btn":
            # Focus the content area for editing
            self.query_one("#content-area", TextArea).focus()

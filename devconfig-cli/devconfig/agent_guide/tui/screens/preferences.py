"""Preferences screen for architecture and language selection."""

from textual.app import ComposeResult
from textual.containers import Container, Horizontal, Vertical
from textual.screen import Screen
from textual.widgets import Button, Checkbox, Footer, Header, Label, RadioButton, RadioSet, Static

from ...config import ARCHITECTURES, CATEGORIES, OUTPUT_FORMATS


class PreferencesScreen(Screen):
    """Screen for selecting architecture style, languages, and output formats."""

    CSS = """
    PreferencesScreen {
        layout: vertical;
    }

    .section {
        margin: 1 2;
        padding: 1;
        border: solid $primary;
    }

    .section-title {
        text-style: bold;
        margin-bottom: 1;
    }

    .checkbox-group {
        layout: horizontal;
        height: auto;
    }

    .checkbox-item {
        width: auto;
        margin-right: 2;
    }

    #button-bar {
        dock: bottom;
        height: 3;
        padding: 1;
    }
    """

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.selected_arch: str = "clean-architecture"
        self.selected_languages: list[str] = []
        self.selected_formats: list[str] = ["claude"]

    def compose(self) -> ComposeResult:
        yield Header()

        with Container():
            # Architecture selection
            with Vertical(classes="section"):
                yield Label("Architecture Style", classes="section-title")
                with RadioSet(id="arch-radio"):
                    for arch in ARCHITECTURES:
                        yield RadioButton(arch, value=arch == "clean-architecture")

            # Language selection
            with Vertical(classes="section"):
                yield Label("Languages (select multiple)", classes="section-title")
                with Horizontal(classes="checkbox-group"):
                    for lang in CATEGORIES:
                        if lang != "generic":
                            yield Checkbox(lang.capitalize(), id=f"lang-{lang}", classes="checkbox-item")

            # Output format selection
            with Vertical(classes="section"):
                yield Label("Output Formats", classes="section-title")
                with Horizontal(classes="checkbox-group"):
                    for fmt in OUTPUT_FORMATS:
                        checked = fmt == "claude"
                        yield Checkbox(fmt.upper() + ".md" if fmt == "claude" else f".{fmt}/", id=f"fmt-{fmt}", value=checked, classes="checkbox-item")

        with Horizontal(id="button-bar"):
            yield Button("Next →", id="next-btn", variant="primary")
            yield Button("Cancel", id="cancel-btn")

        yield Footer()

    def on_radio_set_changed(self, event: RadioSet.Changed) -> None:
        """Handle architecture radio selection."""
        if event.radio_set.id == "arch-radio":
            self.selected_arch = ARCHITECTURES[event.index]

    def on_checkbox_changed(self, event: Checkbox.Changed) -> None:
        """Handle checkbox changes."""
        checkbox_id = event.checkbox.id
        if checkbox_id.startswith("lang-"):
            lang = checkbox_id[5:]
            if event.value:
                if lang not in self.selected_languages:
                    self.selected_languages.append(lang)
            else:
                if lang in self.selected_languages:
                    self.selected_languages.remove(lang)
        elif checkbox_id.startswith("fmt-"):
            fmt = checkbox_id[4:]
            if event.value:
                if fmt not in self.selected_formats:
                    self.selected_formats.append(fmt)
            else:
                if fmt in self.selected_formats:
                    self.selected_formats.remove(fmt)

    def on_button_pressed(self, event: Button.Pressed) -> None:
        """Handle button presses."""
        if event.button.id == "next-btn":
            if not self.selected_formats:
                self.notify("Select at least one output format", severity="error")
                return
            self.dismiss({
                "architecture": self.selected_arch,
                "languages": self.selected_languages,
                "formats": self.selected_formats,
            })
        elif event.button.id == "cancel-btn":
            self.app.exit()

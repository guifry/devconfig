"""Main Textual apps for agent guide TUI."""

from datetime import datetime
from pathlib import Path

from textual.app import App
from textual.widgets import Footer, Header, Label, LoadingIndicator, Static
from textual.containers import Container

from ..agents import AgentRunner
from ..db import BlockStore
from ..models import Block, BlockTags, ExtractedBlock
from .screens import BlockSelectScreen, DiffResolveScreen, PreferencesScreen, ReviewScreen


class AgentGuideApp(App):
    """TUI app for building agent.md from guideline database."""

    TITLE = "Agent Guide Builder"
    CSS = """
    #loading {
        align: center middle;
    }
    """

    def __init__(self, output_dir: Path, formats: list[str], *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.output_dir = output_dir
        self.formats = formats
        self.store = BlockStore()
        self.runner = AgentRunner()
        self.preferences: dict = {}
        self.selected_blocks: list[Block] = []

    def on_mount(self) -> None:
        """Start with preferences screen."""
        self.push_screen(PreferencesScreen(), self._on_preferences_done)

    def _on_preferences_done(self, result: dict | None) -> None:
        """Handle preferences screen result."""
        if result is None:
            self.exit()
            return

        self.preferences = result
        self._show_block_selection()

    def _show_block_selection(self) -> None:
        """Show block selection screen with filtered blocks."""
        # Get blocks filtered by preferences
        arch = self.preferences.get("architecture", "clean-architecture")
        languages = self.preferences.get("languages", [])

        # Always include generic
        categories = ["generic"] + languages

        blocks_by_category: dict[str, list[Block]] = {}
        for cat in categories:
            blocks = self.store.get_all_blocks(cat)
            # Filter by architecture
            filtered = [
                b for b in blocks
                if not b.tags.architecture or arch in b.tags.architecture
            ]
            if filtered:
                blocks_by_category[cat] = filtered

        if not blocks_by_category:
            self.notify("No blocks found matching your preferences", severity="warning")
            self.exit()
            return

        self.push_screen(
            BlockSelectScreen(blocks_by_category, self.preferences),
            self._on_block_selection_done,
        )

    def _on_block_selection_done(self, result: dict | None) -> None:
        """Handle block selection result."""
        if result is None:
            # Go back to preferences
            self.push_screen(PreferencesScreen(), self._on_preferences_done)
            return

        selected_ids = result.get("selected_ids", [])

        # Get full block objects
        all_blocks = self.store.get_all_blocks()
        self.selected_blocks = [b for b in all_blocks if b.id in selected_ids]

        # Generate output
        self._generate_output()

    def _generate_output(self) -> None:
        """Generate output files using Claude agent."""
        self.notify("Generating output files...")

        for fmt in self.formats:
            try:
                content = self.runner.generate_output(self.selected_blocks, fmt)
                output_path = self._get_output_path(fmt)
                output_path.parent.mkdir(parents=True, exist_ok=True)
                output_path.write_text(content)
                self.notify(f"Created: {output_path}")
            except Exception as e:
                self.notify(f"Error generating {fmt}: {e}", severity="error")

        self.exit()

    def _get_output_path(self, fmt: str) -> Path:
        """Get output file path for a format."""
        if fmt == "claude":
            return self.output_dir / "CLAUDE.md"
        elif fmt == "cursor":
            return self.output_dir / ".cursor" / "rules" / "devconfig-rules.mdc"
        elif fmt == "windsurf":
            return self.output_dir / ".windsurf" / "rules" / "devconfig-rules.md"
        return self.output_dir / f"agent-guide-{fmt}.md"


class CollectorApp(App):
    """TUI app for collecting guidelines from existing agent configs."""

    TITLE = "Agent Guide Collector"
    CSS = """
    #status-container {
        height: 100%;
        align: center middle;
    }

    #status {
        text-align: center;
        padding: 1 2;
    }

    #substatus {
        text-align: center;
        color: $text-muted;
    }

    LoadingIndicator {
        margin: 1;
    }
    """

    def __init__(self, repo_path: Path, dry_run: bool = False, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.repo_path = repo_path
        self.repo_name = repo_path.name
        self.dry_run = dry_run
        self.store = BlockStore()
        self.runner = AgentRunner()
        self.extracted_blocks: list[ExtractedBlock] = []
        self.current_block_index: int = 0
        self.accepted_blocks: list[tuple[ExtractedBlock, str]] = []  # (block, category)

    def compose(self):
        yield Header()
        yield Container(
            Static(f"Scanning: {self.repo_path}", id="status"),
            Static("Initializing...", id="substatus"),
            LoadingIndicator(),
            id="status-container",
        )
        yield Footer()

    def on_mount(self) -> None:
        """Start discovery process."""
        # Use thread=True for blocking subprocess calls
        self.run_worker(self._discover_and_extract, thread=True)

    def _update_status(self, main: str, sub: str = "") -> None:
        """Update status display (thread-safe via call_from_thread)."""
        self.call_from_thread(self._do_update_status, main, sub)

    def _do_update_status(self, main: str, sub: str) -> None:
        """Actually update the status widgets."""
        self.query_one("#status", Static).update(main)
        self.query_one("#substatus", Static).update(sub)

    def _discover_and_extract(self) -> None:
        """Discover files and extract blocks (runs in thread)."""
        # Step 1: Discover relevant files
        self._update_status(
            f"Discovering agent config files...",
            f"Scanning {self.repo_path}"
        )
        try:
            relevant_files = self.runner.discover_files(self.repo_path)
        except Exception as e:
            self.call_from_thread(self.notify, f"Discovery failed: {e}", severity="error")
            self.call_from_thread(self.exit)
            return

        if not relevant_files:
            self.call_from_thread(self.notify, "No agent config files found", severity="warning")
            self.call_from_thread(self.exit)
            return

        self._update_status(
            f"Found {len(relevant_files)} config file(s)",
            "Extracting blocks..."
        )

        # Step 2: Extract blocks from each file
        for i, rf in enumerate(relevant_files):
            self._update_status(
                f"Extracting blocks ({i+1}/{len(relevant_files)})",
                f"File: {rf.path}"
            )
            file_path = self.repo_path / rf.path
            try:
                content = file_path.read_text()
                blocks = self.runner.extract_blocks(file_path, content, rf.agent_type)
                self.extracted_blocks.extend(blocks)
            except Exception as e:
                self.call_from_thread(
                    self.notify, f"Error extracting from {rf.path}: {e}", severity="warning"
                )

        if not self.extracted_blocks:
            self.call_from_thread(self.notify, "No guideline blocks extracted", severity="warning")
            self.call_from_thread(self.exit)
            return

        self._update_status(
            f"Extracted {len(self.extracted_blocks)} block(s)",
            "Starting review..."
        )

        # Start review process on main thread
        self.call_from_thread(self._review_next_block)

    def _review_next_block(self) -> None:
        """Show review screen for next block."""
        if self.current_block_index >= len(self.extracted_blocks):
            # All blocks reviewed, save accepted ones
            self._save_accepted_blocks()
            return

        block = self.extracted_blocks[self.current_block_index]
        self.push_screen(
            ReviewScreen(
                block,
                self.current_block_index,
                len(self.extracted_blocks),
                self.repo_name,
            ),
            self._on_review_done,
        )

    def _on_review_done(self, result: dict | None) -> None:
        """Handle review screen result."""
        if result is None:
            self.exit()
            return

        action = result.get("action")
        if action == "accept":
            edited_block = result.get("block")
            self._check_dedup(edited_block)
        elif action == "skip":
            self.current_block_index += 1
            self._review_next_block()

    def _check_dedup(self, block: ExtractedBlock) -> None:
        """Check for duplicate blocks."""
        category = block.suggested_tags.language or "generic"
        existing_blocks = self.store.get_all_blocks(category)

        if not existing_blocks:
            # No existing blocks, just save
            self._accept_block(block, category)
            return

        try:
            match = self.runner.check_dedup(block, existing_blocks)
        except Exception as e:
            self.notify(f"Dedup check failed: {e}", severity="warning")
            self._accept_block(block, category)
            return

        if match is None:
            # No match, just save
            self._accept_block(block, category)
        elif match.identical:
            # Identical match, merge used_by_repos
            self.notify(f"Merged with existing block: {match.id}")
            if not self.dry_run:
                self.store.add_repo_usage(match.id, category, self.repo_name)
            self.current_block_index += 1
            self._review_next_block()
        else:
            # Has nuances, show diff resolution
            existing_block = next(
                (b for b in existing_blocks if b.id == match.id), None
            )
            if existing_block:
                self.push_screen(
                    DiffResolveScreen(block, existing_block, match),
                    lambda r: self._on_diff_resolved(r, block, existing_block, category),
                )
            else:
                self._accept_block(block, category)

    def _on_diff_resolved(
        self,
        result: dict | None,
        new_block: ExtractedBlock,
        existing_block: Block,
        category: str,
    ) -> None:
        """Handle diff resolution result."""
        if result is None:
            self.current_block_index += 1
            self._review_next_block()
            return

        action = result.get("action")
        if action == "use_new":
            # Update existing block with new content
            existing_block.content = new_block.content
            existing_block.tags = new_block.suggested_tags
            if self.repo_name not in existing_block.used_by_repos:
                existing_block.used_by_repos.append(self.repo_name)
            if not self.dry_run:
                self.store.update_block(existing_block, category)
            self.notify(f"Updated block: {existing_block.id}")
        elif action == "keep_existing":
            # Just add repo usage
            if not self.dry_run:
                self.store.add_repo_usage(existing_block.id, category, self.repo_name)
            self.notify(f"Kept existing block: {existing_block.id}")

        self.current_block_index += 1
        self._review_next_block()

    def _accept_block(self, block: ExtractedBlock, category: str) -> None:
        """Accept a block and queue for saving."""
        self.accepted_blocks.append((block, category))
        self.current_block_index += 1
        self._review_next_block()

    def _save_accepted_blocks(self) -> None:
        """Save all accepted blocks to database."""
        if self.dry_run:
            self.notify(f"Dry run: would save {len(self.accepted_blocks)} block(s)")
            self.exit()
            return

        saved = 0
        for block, category in self.accepted_blocks:
            try:
                full_block = Block(
                    id=block.suggested_id,
                    content=block.content,
                    tags=block.suggested_tags,
                    origin_repo=self.repo_name,
                    used_by_repos=[self.repo_name],
                    source_agent=getattr(block, "source_agent", "unknown"),
                    created_at=datetime.now(),
                    updated_at=datetime.now(),
                )
                self.store.add_block(full_block, category)
                saved += 1
            except ValueError as e:
                self.notify(f"Error saving {block.suggested_id}: {e}", severity="warning")

        self.notify(f"Saved {saved} block(s) to database")
        self.exit()

"""JSON file storage for guideline blocks."""

import json
from datetime import datetime
from pathlib import Path

from ..config import AGENT_GUIDE_DB_DIR, ensure_db_dir, get_category_file
from ..models import Block, BlockTags, CategoryFile


class BlockStore:
    """CRUD operations for guideline blocks stored in JSON files."""

    def __init__(self):
        ensure_db_dir()

    def _load_category(self, category: str) -> CategoryFile:
        """Load a category file, create if doesn't exist."""
        path = get_category_file(category)
        if not path.exists():
            return CategoryFile(category=category, blocks=[])

        with open(path) as f:
            data = json.load(f)
        return CategoryFile.model_validate(data)

    def _save_category(self, cat_file: CategoryFile) -> None:
        """Save a category file."""
        path = get_category_file(cat_file.category)
        with open(path, "w") as f:
            json.dump(cat_file.model_dump(mode="json"), f, indent=2, default=str)

    def get_all_blocks(self, category: str | None = None) -> list[Block]:
        """Get all blocks, optionally filtered by category."""
        if category:
            return self._load_category(category).blocks

        # Load all categories
        all_blocks = []
        for path in AGENT_GUIDE_DB_DIR.glob("*.json"):
            if path.stem == "schema":
                continue
            cat_file = self._load_category(path.stem)
            all_blocks.extend(cat_file.blocks)
        return all_blocks

    def get_block(self, block_id: str) -> Block | None:
        """Get a block by ID."""
        for block in self.get_all_blocks():
            if block.id == block_id:
                return block
        return None

    def add_block(self, block: Block, category: str) -> None:
        """Add a new block to a category."""
        cat_file = self._load_category(category)

        # Check for duplicate ID
        if any(b.id == block.id for b in cat_file.blocks):
            raise ValueError(f"Block with ID '{block.id}' already exists")

        cat_file.blocks.append(block)
        self._save_category(cat_file)

    def update_block(self, block: Block, category: str) -> None:
        """Update an existing block."""
        cat_file = self._load_category(category)

        for i, b in enumerate(cat_file.blocks):
            if b.id == block.id:
                block.updated_at = datetime.now()
                cat_file.blocks[i] = block
                self._save_category(cat_file)
                return

        raise ValueError(f"Block with ID '{block.id}' not found")

    def delete_block(self, block_id: str, category: str) -> None:
        """Delete a block by ID."""
        cat_file = self._load_category(category)
        cat_file.blocks = [b for b in cat_file.blocks if b.id != block_id]
        self._save_category(cat_file)

    def add_repo_usage(self, block_id: str, category: str, repo: str) -> None:
        """Add a repo to block's used_by_repos list."""
        cat_file = self._load_category(category)

        for block in cat_file.blocks:
            if block.id == block_id:
                if repo not in block.used_by_repos:
                    block.used_by_repos.append(repo)
                    block.updated_at = datetime.now()
                self._save_category(cat_file)
                return

        raise ValueError(f"Block with ID '{block_id}' not found")

    def get_blocks_by_language(self, language: str | None) -> list[Block]:
        """Get blocks for a specific language (None = generic)."""
        return [b for b in self.get_all_blocks() if b.tags.language == language]

    def get_blocks_by_architecture(self, architecture: str) -> list[Block]:
        """Get blocks matching an architecture style."""
        return [
            b for b in self.get_all_blocks()
            if architecture in b.tags.architecture or not b.tags.architecture
        ]

    def get_categories(self) -> list[str]:
        """Get list of available categories."""
        return [p.stem for p in AGENT_GUIDE_DB_DIR.glob("*.json") if p.stem != "schema"]

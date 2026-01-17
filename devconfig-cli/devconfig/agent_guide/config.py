"""Configuration and paths for agent guide."""

from pathlib import Path

# Base paths
DEVCONFIG_DIR = Path(__file__).parent.parent.parent.parent.parent  # devconfig repo root
AGENT_GUIDE_DB_DIR = DEVCONFIG_DIR / "agent-guide-db"
HOME_SYMLINK_DIR = Path.home() / ".devconfig" / "agent-guide-db"

# Category files
CATEGORIES = ["generic", "python", "typescript", "rust", "go", "java"]

# Architecture options
ARCHITECTURES = ["rapid-prototype", "clean-architecture", "hexagonal"]

# Output formats
OUTPUT_FORMATS = ["claude", "cursor", "windsurf"]

# Ensure DB directory exists
def ensure_db_dir() -> Path:
    """Ensure agent-guide-db directory exists, return path."""
    AGENT_GUIDE_DB_DIR.mkdir(parents=True, exist_ok=True)
    return AGENT_GUIDE_DB_DIR


def get_category_file(category: str) -> Path:
    """Get path to category JSON file."""
    return AGENT_GUIDE_DB_DIR / f"{category}.json"

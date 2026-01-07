import json
import time
from pathlib import Path
from typing import TypedDict


class HistoryItem(TypedDict):
    content: str
    ts: float


CLIPPY_DIR = Path.home() / ".clippy"
HISTORY_FILE = CLIPPY_DIR / "history.json"
MAX_ITEMS = 50


def ensure_dir() -> None:
    CLIPPY_DIR.mkdir(exist_ok=True)


def load_history() -> list[HistoryItem]:
    ensure_dir()
    if not HISTORY_FILE.exists():
        return []
    try:
        with open(HISTORY_FILE) as f:
            return json.load(f)
    except (json.JSONDecodeError, OSError):
        return []


def save_history(history: list[HistoryItem]) -> None:
    ensure_dir()
    tmp = HISTORY_FILE.with_suffix(".tmp")
    with open(tmp, "w") as f:
        json.dump(history, f)
    tmp.rename(HISTORY_FILE)


def add_item(content: str) -> None:
    if not content or not content.strip():
        return
    history = load_history()
    if history and history[0]["content"] == content:
        return
    item: HistoryItem = {"content": content, "ts": time.time()}
    history.insert(0, item)
    history = history[:MAX_ITEMS]
    save_history(history)


def get_items(limit: int = MAX_ITEMS) -> list[HistoryItem]:
    return load_history()[:limit]


def clear_history() -> None:
    ensure_dir()
    save_history([])

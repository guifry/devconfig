"""Generate CLAUDE.md format output."""

from ..models import Block


def generate_claude_md(blocks: list[Block]) -> str:
    """Generate CLAUDE.md content from blocks.

    This is a fallback generator - the agent runner is preferred
    for more intelligent formatting.
    """
    # Group blocks by language
    generic_blocks = [b for b in blocks if b.tags.language is None]
    lang_blocks: dict[str, list[Block]] = {}
    for b in blocks:
        if b.tags.language:
            lang_blocks.setdefault(b.tags.language, []).append(b)

    lines = ["# Project Guidelines", ""]

    # Generic first
    if generic_blocks:
        lines.append("## General")
        lines.append("")
        for b in generic_blocks:
            lines.append(f"### {b.id}")
            lines.append("")
            lines.append(b.content)
            lines.append("")

    # Then by language
    for lang, lang_block_list in sorted(lang_blocks.items()):
        lines.append(f"## {lang.capitalize()}")
        lines.append("")
        for b in lang_block_list:
            lines.append(f"### {b.id}")
            lines.append("")
            lines.append(b.content)
            lines.append("")

    return "\n".join(lines)

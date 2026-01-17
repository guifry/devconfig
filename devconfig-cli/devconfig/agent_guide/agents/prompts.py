"""Prompts for Claude agent interactions."""

DISCOVERY_PROMPT = """Scan these files and identify which are coding agent configuration files.
Could be: CLAUDE.md, .windsurf/rules/, .cursor/rules/, .aiassistant/rules/, or any custom format containing coding guidelines.

Files (with first 500 chars preview):
{file_list_with_previews}

Return ONLY valid JSON (no markdown, no explanation):
{{"relevant_files": [{{"path": "relative/path", "agent_type": "windsurf|cursor|claude|custom", "reason": "brief reason"}}]}}

If no relevant files found, return: {{"relevant_files": []}}"""


EXTRACTION_PROMPT = """Extract discrete guideline blocks from this agent config file.
Each block = one self-contained rule/convention/guideline.
Split large files into multiple focused blocks.

File: {file_path}
Content:
{content}

Return ONLY valid JSON (no markdown, no explanation):
{{"blocks": [
  {{
    "suggested_id": "short-kebab-case-id",
    "content": "the guideline text, can be multiple lines",
    "suggested_tags": {{
      "language": "python|typescript|rust|go|java|null",
      "architecture": ["clean-architecture", "rapid-prototype", "hexagonal"],
      "scope": ["domain", "testing", "ci", "docs", "imports", "comments", "naming", "errors"]
    }}
  }}
]}}

Guidelines:
- language: null if generic/language-agnostic
- architecture: empty list [] if applies to all styles
- scope: pick relevant tags, can be empty
- suggested_id: use prefix like "py-", "ts-", "gen-" based on language"""


DEDUP_PROMPT = """Compare this new block against existing DB blocks. Find if any are semantically similar (same topic/guideline, even if worded differently).

New block to add:
ID: {new_id}
Content: {new_content}

Existing blocks in same category:
{existing_blocks}

Return ONLY valid JSON (no markdown, no explanation):
If no match: {{"match": null}}
If match found: {{"match": {{"id": "existing-block-id", "identical": true, "nuances": null}}}}
If similar but different: {{"match": {{"id": "existing-block-id", "identical": false, "nuances": "explanation of differences"}}}}"""


GENERATION_PROMPT = """Generate a {format} agent configuration file from these guideline blocks.

Requirements:
- Order: generic/language-agnostic guidelines FIRST, then language-specific grouped by language
- Each block should be clearly separated
- Use appropriate formatting for the target format

Selected blocks:
{blocks_json}

Output format requirements:
{format_instructions}

Return ONLY the file content, no explanation."""


FORMAT_INSTRUCTIONS = {
    "claude": """CLAUDE.md format:
- Markdown file
- Use ## headers to group sections (e.g., ## General, ## Python, ## TypeScript)
- Each guideline as a bullet point or paragraph
- Can include code examples in fenced blocks""",

    "cursor": """.cursor/rules/*.mdc format:
- YAML frontmatter with: description, globs (optional), alwaysApply
- Then markdown content
- Example:
---
description: Python coding conventions
globs: "**/*.py"
alwaysApply: false
---

# Python Guidelines
...""",

    "windsurf": """.windsurf/rules/*.md format:
- Markdown file
- Can have YAML frontmatter with trigger: always_on or trigger: manual
- Simple markdown with headers and bullet points
- Example:
---
trigger: always_on
---

# Guidelines
..."""
}


PROMPTS = {
    "discovery": DISCOVERY_PROMPT,
    "extraction": EXTRACTION_PROMPT,
    "dedup": DEDUP_PROMPT,
    "generation": GENERATION_PROMPT,
    "format_instructions": FORMAT_INSTRUCTIONS,
}

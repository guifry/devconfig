"""Runner for Claude CLI subprocess calls."""

import json
import re
import subprocess
from pathlib import Path
from typing import Any

from ..models import Block, DedupMatch, ExtractedBlock, RelevantFile
from .prompts import PROMPTS, FORMAT_INSTRUCTIONS


class AgentRunner:
    """Execute Claude CLI commands and parse responses."""

    def __init__(self, model: str = "sonnet"):
        self.model = model

    def _run_claude(self, prompt: str) -> str:
        """Run claude CLI with prompt, return response."""
        result = subprocess.run(
            ["claude", "-p", prompt, "--model", self.model, "--output-format", "text"],
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            raise RuntimeError(f"Claude CLI failed: {result.stderr}")
        return result.stdout.strip()

    def _parse_json(self, response: str, retry_count: int = 0) -> dict:
        """Extract JSON from response. If parsing fails, ask Claude to fix it."""
        text = response.strip()

        # Quick extraction attempts
        # Try markdown code block
        if "```json" in text:
            start = text.find("```json") + 7
            end = text.find("```", start)
            if end != -1:
                text = text[start:end].strip()
        elif "```" in text:
            start = text.find("```") + 3
            newline = text.find("\n", start)
            if newline != -1 and newline - start < 15:
                start = newline + 1
            end = text.find("```", start)
            if end != -1:
                text = text[start:end].strip()

        # Try to find JSON object/array
        if not text.startswith("{") and not text.startswith("["):
            obj_start = text.find("{")
            arr_start = text.find("[")
            if obj_start == -1:
                obj_start = len(text)
            if arr_start == -1:
                arr_start = len(text)
            start = min(obj_start, arr_start)
            if start < len(text):
                text = text[start:]

        try:
            return json.loads(text)
        except json.JSONDecodeError as e:
            if retry_count >= 1:
                raise RuntimeError(f"Failed to parse JSON after retry: {e}\nResponse: {text[:500]}")

            # Agentic fix: ask Claude to extract/fix the JSON
            fix_prompt = f"""The following text should contain JSON but it's malformed or has extra content.
Extract and return ONLY the valid JSON object/array, fixing any syntax errors.

Text:
{response[:2000]}

Return ONLY the corrected JSON, nothing else."""

            fixed_response = self._run_claude(fix_prompt)
            return self._parse_json(fixed_response, retry_count + 1)

    def discover_files(self, folder: Path) -> list[RelevantFile]:
        """Discover agent config files in a folder."""
        # Collect files with previews
        file_previews = []
        for path in folder.rglob("*"):
            if path.is_file() and not path.name.startswith(".git"):
                # Skip binary files and large files
                try:
                    content = path.read_text(errors="ignore")[:500]
                    rel_path = path.relative_to(folder)
                    file_previews.append(f"--- {rel_path} ---\n{content}\n")
                except Exception:
                    continue

        if not file_previews:
            return []

        prompt = PROMPTS["discovery"].format(
            file_list_with_previews="\n".join(file_previews[:50])  # Limit to 50 files
        )

        response = self._run_claude(prompt)
        data = self._parse_json(response)

        return [RelevantFile(**f) for f in data.get("relevant_files", [])]

    def extract_blocks(self, file_path: Path, content: str, source_agent: str = "unknown") -> list[ExtractedBlock]:
        """Extract guideline blocks from a file."""
        prompt = PROMPTS["extraction"].format(
            file_path=str(file_path),
            content=content,
        )

        response = self._run_claude(prompt)
        data = self._parse_json(response)

        blocks = []
        for b in data.get("blocks", []):
            b["source_agent"] = source_agent
            blocks.append(ExtractedBlock(**b))
        return blocks

    def check_dedup(
        self, new_block: ExtractedBlock, existing_blocks: list[Block]
    ) -> DedupMatch | None:
        """Check if new block is duplicate of existing."""
        if not existing_blocks:
            return None

        existing_str = "\n\n".join(
            f"ID: {b.id}\nContent: {b.content}" for b in existing_blocks
        )

        prompt = PROMPTS["dedup"].format(
            new_id=new_block.suggested_id,
            new_content=new_block.content,
            existing_blocks=existing_str,
        )

        response = self._run_claude(prompt)
        data = self._parse_json(response)

        match = data.get("match")
        if match is None:
            return None
        return DedupMatch(**match)

    def generate_output(
        self, blocks: list[Block], output_format: str
    ) -> str:
        """Generate agent config file from blocks."""
        blocks_json = json.dumps(
            [b.model_dump(mode="json") for b in blocks],
            indent=2,
            default=str,
        )

        format_instructions = FORMAT_INSTRUCTIONS.get(
            output_format, FORMAT_INSTRUCTIONS["claude"]
        )

        prompt = PROMPTS["generation"].format(
            format=output_format,
            blocks_json=blocks_json,
            format_instructions=format_instructions,
        )

        return self._run_claude(prompt)

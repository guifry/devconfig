"""Pydantic models for agent guide blocks and database."""

from datetime import datetime
from typing import Literal
from pydantic import BaseModel, Field


class BlockTags(BaseModel):
    """Tags for categorizing a guideline block."""

    language: str | None = None  # python, typescript, rust, None=generic
    architecture: list[str] = Field(default_factory=list)  # clean-architecture, rapid-prototype, hexagonal
    scope: list[str] = Field(default_factory=list)  # domain, testing, ci, docs, imports, etc.


class Block(BaseModel):
    """A single guideline block."""

    id: str  # unique slug, e.g. "py-pydantic-domain"
    content: str  # the guideline text
    tags: BlockTags = Field(default_factory=BlockTags)
    origin_repo: str  # repo where block was first collected
    used_by_repos: list[str] = Field(default_factory=list)  # repos using this block
    source_agent: Literal["windsurf", "cursor", "claude", "custom", "unknown"] = "unknown"
    created_at: datetime = Field(default_factory=datetime.now)
    updated_at: datetime = Field(default_factory=datetime.now)


class CategoryFile(BaseModel):
    """A category file containing multiple blocks."""

    category: str  # e.g. "python", "generic", "typescript"
    blocks: list[Block] = Field(default_factory=list)


class ExtractedBlock(BaseModel):
    """Block extracted by agent, before saving to DB."""

    suggested_id: str
    content: str
    suggested_tags: BlockTags = Field(default_factory=BlockTags)
    source_agent: Literal["windsurf", "cursor", "claude", "custom", "unknown"] = "unknown"


class RelevantFile(BaseModel):
    """File identified as agent config by discovery agent."""

    path: str
    agent_type: Literal["windsurf", "cursor", "claude", "custom"]
    reason: str


class DedupMatch(BaseModel):
    """Result of dedup comparison."""

    id: str  # existing block id
    identical: bool
    nuances: str | None = None  # explanation if not identical

# PR Report Command

You are being invoked as the `/pr-report` command to generate a comprehensive pull request report.

## User Input
The user may have provided a time range specification: "{{prompt}}"

## Task
Generate a comprehensive PR report for this git repository with the following structure:

### 1. Determine Time Range
- Default: last 7 days if no user input or "{{prompt}}" is empty
- Otherwise: parse user input to determine the time range (e.g., "last 3 days", "last month", "last 2 weeks")
- Calculate the appropriate date for the `created:>=YYYY-MM-DD` filter
- Today's date is 2026-01-13

### 2. Fetch All PRs
Use `gh pr list --state all --limit 100 --json number,title,author,isDraft,state,createdAt,url --search "created:>=YYYY-MM-DD"` where YYYY-MM-DD is the calculated start date.

### 3. Analyze Each PR with Sub-Agents
**CRITICAL**: For each PR, spawn a separate sub-agent using the Task tool to avoid context pollution.

Launch ALL sub-agents in PARALLEL in a single message using multiple Task tool calls.

Each sub-agent task:
- Use `subagent_type: "general-purpose"`
- Do NOT specify model parameter (will inherit from parent to avoid API issues)
- Prompt: "Analyze PR #{number}. Fetch PR details with `gh pr view {number} --json body,title,author,createdAt,state`. Fetch the code diff with `gh pr diff {number}`. Analyze the changes and provide a concise summary (2-3 sentences) covering: what was changed, why, and any notable technical details (files/modules affected, patterns used, architectural decisions). Sacrifice grammar for conciseness."
- Description: "Analyze PR #{number}"

Wait for all sub-agents to complete and collect their summaries.

### 4. Generate Report

#### Section 1: Chronological PR List
List all PRs chronologically (newest first), grouped by status:
- **Open PRs** (including drafts)
- **Merged PRs**

Format:
```
**[#{number}](url)** ({author}, {date}) - {summary from sub-agent analysis}
```

Example: `**[#689](https://github.com/Kpler/chartering-fast-api/pull/689)** (Germain, 2026-01-13) - ...`

#### Section 2: Per-User Summary
Group PRs by GitHub user and provide a paragraph summary for each user describing:
- What they've been working on
- Key themes/areas of focus
- Notable features or changes

Use the sub-agent analysis summaries to understand the technical details of each PR.
Use bullet points within the paragraph to organize information.

Format:
```
**{Author Name} (@{username})**
{Paragraph describing their work with bullet points, based on sub-agent analysis}
```

#### Section 3: Notable Changes
Summarize significant changes across all PRs based on sub-agent analysis:
- New features
- Refactorings
- Cleanups/removals
- Bug fixes
- Infrastructure changes
- Breaking changes or migrations
- Database schema changes
- API changes

Organize by category with bullet points. Be specific about what changed.

## Important
- Use sub-agent summaries as the primary source of information
- Be concise but informative
- Focus on what was actually done, not how it was tested
- Sacrifice grammar for conciseness
- No emojis
- The sub-agents analyze code diffs, so you have detailed technical context
- **CRITICAL**: Format ALL PR numbers as clickable links throughout the entire report. Every time you mention a PR number (e.g., #689), format it as `[#689](url)` not just `#689`. This applies to all three sections.

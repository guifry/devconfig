#!/usr/bin/env python3
"""
Review loop orchestrator for batch-execute skill.

Spawns fresh Claude Code reviewer agents with zero context.
Passes review back to caller. Dumb plumbing — no intelligence.

Usage:
    python3 review_loop.py \
        --repo-path /path/to/repo \
        --task-spec /path/to/task_spec.md \
        --diff /path/to/diff.patch \
        --max-cycles 2 \
        --model sonnet

Output: JSON to stdout with structure:
    {
        "reviews": [
            {"cycle": 1, "review": "...reviewer output..."},
            {"cycle": 2, "review": "...reviewer output..."}
        ],
        "cycles_used": 2,
        "status": "completed" | "max_cycles_reached" | "error"
    }

The caller (worker agent) reads each review, fixes issues, then
calls this script again if needed — or the worker can request
all cycles upfront and process them sequentially.

Mode of operation:
    --mode single   (default) Run one review cycle, return it.
    --mode all      Run up to max-cycles, pausing between for
                    worker input via --worker-response file.
"""

import argparse
import json
import subprocess
import sys
from pathlib import Path


def load_review_protocol() -> str:
    protocol_path = Path(__file__).parent.parent / "review-protocol.md"
    if not protocol_path.exists():
        sys.exit(f"review-protocol.md not found at {protocol_path}")
    return protocol_path.read_text()


def build_reviewer_prompt(task_spec: str, diff: str, repo_path: str, protocol: str) -> str:
    template_start = protocol.find("```", protocol.find("## Reviewer prompt template"))
    template_end = protocol.find("```", template_start + 3)
    template = protocol[template_start + 3 : template_end].strip()

    prompt = template.replace("{task_spec}", task_spec).replace("{diff}", diff).replace("{repo_path}", repo_path)
    return prompt


def run_reviewer(prompt: str, repo_path: str, model: str) -> str:
    cmd = [
        "claude",
        "--print",
        f"--model={model}",
        f"--allowedTools=Read,Glob,Grep",
        "--permission-mode=bypassPermissions",
        "--bare",
        "--no-session-persistence",
        prompt,
    ]

    result = subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        cwd=repo_path,
        timeout=300,
    )

    if result.returncode != 0:
        return f"[REVIEWER ERROR] exit code {result.returncode}\nstderr: {result.stderr[:500]}"

    return result.stdout


def run_single_cycle(
    task_spec: str, diff: str, repo_path: str, model: str, protocol: str, cycle: int
) -> dict:
    prompt = build_reviewer_prompt(task_spec, diff, repo_path, protocol)
    review = run_reviewer(prompt, repo_path, model)
    return {"cycle": cycle, "review": review}


def main():
    parser = argparse.ArgumentParser(description="Review loop orchestrator")
    parser.add_argument("--repo-path", required=True, help="Path to the repository")
    parser.add_argument("--task-spec", required=True, help="Path to task spec file")
    parser.add_argument("--diff", required=True, help="Path to diff file")
    parser.add_argument("--max-cycles", type=int, default=2, help="Maximum review cycles")
    parser.add_argument("--model", default="sonnet", help="Model for reviewer agent")
    parser.add_argument(
        "--mode",
        choices=["single", "all"],
        default="single",
        help="single: one cycle and return. all: run cycles with worker-response files between.",
    )
    parser.add_argument(
        "--worker-response",
        help="Path to worker response file (mode=all, cycles 2+). "
        "Contains 'CONTINUE' or 'DONE' on first line, optional updated diff path on second.",
    )
    args = parser.parse_args()

    task_spec = Path(args.task_spec).read_text()
    diff = Path(args.diff).read_text()
    protocol = load_review_protocol()

    if args.mode == "single":
        result = run_single_cycle(task_spec, diff, args.repo_path, args.model, protocol, cycle=1)
        output = {
            "reviews": [result],
            "cycles_used": 1,
            "status": "completed",
        }
        print(json.dumps(output, indent=2))
        return

    reviews = []
    for cycle in range(1, args.max_cycles + 1):
        if cycle > 1:
            if not args.worker_response or not Path(args.worker_response).exists():
                output = {
                    "reviews": reviews,
                    "cycles_used": cycle - 1,
                    "status": "waiting_for_worker",
                }
                print(json.dumps(output, indent=2))
                return

            response = Path(args.worker_response).read_text().strip().split("\n")
            decision = response[0].strip().upper()

            if decision == "DONE":
                output = {
                    "reviews": reviews,
                    "cycles_used": cycle - 1,
                    "status": "completed",
                }
                print(json.dumps(output, indent=2))
                return

            if len(response) > 1:
                updated_diff_path = response[1].strip()
                if Path(updated_diff_path).exists():
                    diff = Path(updated_diff_path).read_text()

        result = run_single_cycle(task_spec, diff, args.repo_path, args.model, protocol, cycle)
        reviews.append(result)

    output = {
        "reviews": reviews,
        "cycles_used": len(reviews),
        "status": "max_cycles_reached",
    }
    print(json.dumps(output, indent=2))


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
import shutil
import subprocess
import sys
from pathlib import Path

KPLER_DIR = Path.home() / "kpler"
WEB_APP_REPO = KPLER_DIR / "web-app"
CHARTERING_REPO = KPLER_DIR / "chartering-fast-api"
FIXING_REPO = KPLER_DIR / "chartering-fixing-api"
WT_PREFIX = "FST-"
REPO_DIRS = {"web-app", "chartering-fast-api", "chartering-fixing-api"}
CONVENTION_SYMLINKS = {
    "CLAUDE.md": Path.home() / "projects/devconfig/conventions/chartering/CLAUDE.md",
    "CHARTERING_AGENT_GUIDE.md": Path.home() / "projects/devconfig/conventions/chartering/CHARTERING_AGENT_GUIDE.md",
}


def log(msg: str) -> None:
    print(msg, file=sys.stderr)


def get_branch_numbers(repo: Path) -> list[int]:
    result = subprocess.run(
        ["git", "branch", "--list", f"{WT_PREFIX}*"],
        cwd=repo, capture_output=True, text=True
    )
    numbers = []
    for line in result.stdout.splitlines():
        branch = line.strip().lstrip("* ")
        match = re.search(rf"{WT_PREFIX}(\d+)(?:-|$)", branch)
        if match:
            numbers.append(int(match.group(1)))
    return numbers


def get_next_wt_number() -> int:
    numbers = []
    for d in KPLER_DIR.iterdir():
        if d.is_dir() and d.name.startswith(WT_PREFIX):
            match = re.search(rf"{WT_PREFIX}(\d+)(?:-|$)", d.name)
            if match:
                numbers.append(int(match.group(1)))
    for repo in (WEB_APP_REPO, CHARTERING_REPO, FIXING_REPO):
        if repo.exists():
            numbers.extend(get_branch_numbers(repo))
    return max(numbers, default=0) + 1


def get_previous_wt_dir(current_num: int) -> Path | None:
    for n in range(current_num - 1, 0, -1):
        for d in KPLER_DIR.iterdir():
            if d.is_dir() and re.match(rf"{WT_PREFIX}{n}(?:-|$)", d.name):
                return d
    return None


def get_default_branch(repo: Path) -> str:
    result = subprocess.run(
        ["git", "symbolic-ref", "refs/remotes/origin/HEAD"],
        cwd=repo, capture_output=True, text=True
    )
    if result.returncode == 0:
        return result.stdout.strip().replace("refs/remotes/origin/", "")
    for branch in ["main", "develop", "master"]:
        result = subprocess.run(
            ["git", "rev-parse", "--verify", f"origin/{branch}"],
            cwd=repo, capture_output=True
        )
        if result.returncode == 0:
            return branch
    return "main"


def create_worktree(repo: Path, target_dir: Path, base_branch: str, new_branch: str) -> None:
    subprocess.run(
        ["git", "worktree", "add", "-b", new_branch, str(target_dir), base_branch],
        cwd=repo, check=True, stdout=sys.stderr
    )


def copy_extra_files(src_dir: Path, dst_dir: Path) -> None:
    exclude = REPO_DIRS | set(CONVENTION_SYMLINKS.keys())
    for item in src_dir.iterdir():
        if item.name in exclude:
            continue
        dst = dst_dir / item.name
        if item.is_dir():
            shutil.copytree(item, dst)
        else:
            shutil.copy2(item, dst)
    log(f"Copied extra files from {src_dir}")


def create_convention_symlinks(wt_dir: Path) -> None:
    for name, source in CONVENTION_SYMLINKS.items():
        target = wt_dir / name
        if source.exists() and not target.exists():
            target.symlink_to(source)
            log(f"Created symlink {target} -> {source}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("suffix", nargs="?", default="", help="optional suffix for worktree name")
    args = parser.parse_args()

    for repo in (WEB_APP_REPO, CHARTERING_REPO, FIXING_REPO):
        if not repo.exists():
            raise SystemExit(f"{repo.name} not found at {repo}")

    wt_num = get_next_wt_number()
    suffix_part = f"-{args.suffix}" if args.suffix else ""
    wt_name = f"{WT_PREFIX}{wt_num}{suffix_part}"
    wt_dir = KPLER_DIR / wt_name
    wt_dir.mkdir()
    log(f"Created {wt_dir}")

    for repo, name in ((WEB_APP_REPO, "web-app"), (CHARTERING_REPO, "chartering-fast-api"), (FIXING_REPO, "chartering-fixing-api")):
        base = get_default_branch(repo)
        log(f"Creating {name} worktree (branch {wt_name} from {base})...")
        create_worktree(repo, wt_dir / name, base, wt_name)

    prev_wt = get_previous_wt_dir(wt_num)
    if prev_wt:
        copy_extra_files(prev_wt, wt_dir)
    else:
        log("No previous worktree to copy files from")

    create_convention_symlinks(wt_dir)

    log(f"\nDone! Worktree ready at: {wt_dir}")
    print(wt_dir)


if __name__ == "__main__":
    main()

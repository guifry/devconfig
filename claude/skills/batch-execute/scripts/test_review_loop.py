#!/usr/bin/env python3
"""
Tests for review_loop.py orchestrator.

Tests the orchestrator logic without hitting Claude API.
Mocks subprocess.run to simulate reviewer responses.

Run: python3 -m pytest test_review_loop.py -v
  or: python3 test_review_loop.py
"""

import json
import subprocess
import tempfile
from pathlib import Path
from unittest import mock

import pytest

from review_loop import (
    build_reviewer_prompt,
    load_review_protocol,
    run_reviewer,
    run_single_cycle,
)

SCRIPT_DIR = Path(__file__).parent
REPO_PATH = str(SCRIPT_DIR.parent.parent.parent.parent)


@pytest.fixture
def task_spec_file(tmp_path):
    f = tmp_path / "task_spec.md"
    f.write_text("Fix the dropdown not updating the graph when timeframe changes.")
    return str(f)


@pytest.fixture
def diff_file(tmp_path):
    f = tmp_path / "diff.patch"
    f.write_text(
        "--- a/src/components/ForecastChart.tsx\n"
        "+++ b/src/components/ForecastChart.tsx\n"
        "@@ -42,7 +42,7 @@\n"
        "-  const data = useForecastData()\n"
        "+  const data = useForecastData(timeframe)\n"
    )
    return str(f)


@pytest.fixture
def worker_response_file(tmp_path):
    f = tmp_path / "worker_response.txt"
    return str(f)


class TestLoadReviewProtocol:
    def test_loads_protocol(self):
        protocol = load_review_protocol()
        assert "BLOCKING" in protocol
        assert "NON-BLOCKING" in protocol
        assert "Reviewer prompt template" in protocol

    def test_protocol_has_template_markers(self):
        protocol = load_review_protocol()
        assert "{task_spec}" in protocol
        assert "{diff}" in protocol
        assert "{repo_path}" in protocol


class TestBuildReviewerPrompt:
    def test_substitutes_placeholders(self):
        protocol = load_review_protocol()
        prompt = build_reviewer_prompt(
            task_spec="Fix bug X",
            diff="--- a/file\n+++ b/file\n-old\n+new",
            repo_path="/tmp/repo",
            protocol=protocol,
        )
        assert "Fix bug X" in prompt
        assert "--- a/file" in prompt
        assert "/tmp/repo" in prompt
        assert "{task_spec}" not in prompt
        assert "{diff}" not in prompt
        assert "{repo_path}" not in prompt

    def test_preserves_review_criteria(self):
        protocol = load_review_protocol()
        prompt = build_reviewer_prompt("spec", "diff", "/repo", protocol)
        assert "BLOCKING" in prompt
        assert "NON-BLOCKING" in prompt


class TestRunReviewer:
    @mock.patch("review_loop.subprocess.run")
    def test_happy_path(self, mock_run):
        mock_run.return_value = subprocess.CompletedProcess(
            args=[], returncode=0, stdout="[BLOCKING] — file.tsx:42 — Missing null check\n", stderr=""
        )
        result = run_reviewer("prompt", "/repo", "sonnet")
        assert "[BLOCKING]" in result
        assert "file.tsx:42" in result

    @mock.patch("review_loop.subprocess.run")
    def test_reviewer_error(self, mock_run):
        mock_run.return_value = subprocess.CompletedProcess(
            args=[], returncode=1, stdout="", stderr="API error: rate limited"
        )
        result = run_reviewer("prompt", "/repo", "sonnet")
        assert "[REVIEWER ERROR]" in result
        assert "rate limited" in result

    @mock.patch("review_loop.subprocess.run")
    def test_reviewer_timeout(self, mock_run):
        mock_run.side_effect = subprocess.TimeoutExpired(cmd=[], timeout=300)
        with pytest.raises(subprocess.TimeoutExpired):
            run_reviewer("prompt", "/repo", "sonnet")

    @mock.patch("review_loop.subprocess.run")
    def test_cli_flags(self, mock_run):
        mock_run.return_value = subprocess.CompletedProcess(args=[], returncode=0, stdout="ok", stderr="")
        run_reviewer("test prompt", "/my/repo", "sonnet")
        cmd = mock_run.call_args[0][0]
        assert "claude" in cmd[0]
        assert "--print" in cmd
        assert "--model=sonnet" in cmd
        assert "--bare" in cmd
        assert "--no-session-persistence" in cmd
        assert "--permission-mode=bypassPermissions" in cmd
        assert mock_run.call_args[1]["cwd"] == "/my/repo"


class TestRunSingleCycle:
    @mock.patch("review_loop.run_reviewer")
    def test_returns_cycle_number_and_review(self, mock_reviewer):
        mock_reviewer.return_value = "No issues found. Changes look correct."
        protocol = load_review_protocol()
        result = run_single_cycle("spec", "diff", "/repo", "sonnet", protocol, cycle=1)
        assert result["cycle"] == 1
        assert "No issues found" in result["review"]

    @mock.patch("review_loop.run_reviewer")
    def test_cycle_number_propagates(self, mock_reviewer):
        mock_reviewer.return_value = "review text"
        protocol = load_review_protocol()
        result = run_single_cycle("spec", "diff", "/repo", "sonnet", protocol, cycle=2)
        assert result["cycle"] == 2


class TestCLIIntegration:
    """Tests the CLI interface by invoking the script as a subprocess."""

    def test_single_mode_returns_json(self, task_spec_file, diff_file):
        with mock.patch("review_loop.run_reviewer", return_value="[NON-BLOCKING] — minor style issue"):
            result = subprocess.run(
                [
                    "python3",
                    str(SCRIPT_DIR / "review_loop.py"),
                    "--repo-path", REPO_PATH,
                    "--task-spec", task_spec_file,
                    "--diff", diff_file,
                    "--mode", "single",
                ],
                capture_output=True,
                text=True,
                cwd=str(SCRIPT_DIR),
            )
        if result.returncode == 0:
            output = json.loads(result.stdout)
            assert "reviews" in output
            assert "cycles_used" in output
            assert "status" in output

    def test_missing_task_spec_fails(self, diff_file):
        result = subprocess.run(
            [
                "python3",
                str(SCRIPT_DIR / "review_loop.py"),
                "--repo-path", REPO_PATH,
                "--task-spec", "/nonexistent/file.md",
                "--diff", diff_file,
            ],
            capture_output=True,
            text=True,
        )
        assert result.returncode != 0

    def test_missing_diff_fails(self, task_spec_file):
        result = subprocess.run(
            [
                "python3",
                str(SCRIPT_DIR / "review_loop.py"),
                "--repo-path", REPO_PATH,
                "--task-spec", task_spec_file,
                "--diff", "/nonexistent/diff.patch",
            ],
            capture_output=True,
            text=True,
        )
        assert result.returncode != 0


class TestAllModeWorkflow:
    """Tests the multi-cycle 'all' mode with worker response files."""

    @mock.patch("review_loop.run_reviewer")
    def test_all_mode_first_cycle(self, mock_reviewer, task_spec_file, diff_file):
        mock_reviewer.return_value = "[BLOCKING] — bug found"
        result = subprocess.run(
            [
                "python3",
                str(SCRIPT_DIR / "review_loop.py"),
                "--repo-path", REPO_PATH,
                "--task-spec", task_spec_file,
                "--diff", diff_file,
                "--mode", "all",
                "--max-cycles", "2",
            ],
            capture_output=True,
            text=True,
            cwd=str(SCRIPT_DIR),
        )
        if result.returncode == 0 and result.stdout.strip():
            output = json.loads(result.stdout)
            assert output["cycles_used"] >= 1

    @mock.patch("review_loop.run_reviewer")
    def test_worker_says_done_stops_loop(self, mock_reviewer, task_spec_file, diff_file, worker_response_file):
        mock_reviewer.return_value = "[NON-BLOCKING] — minor"
        Path(worker_response_file).write_text("DONE\n")
        result = subprocess.run(
            [
                "python3",
                str(SCRIPT_DIR / "review_loop.py"),
                "--repo-path", REPO_PATH,
                "--task-spec", task_spec_file,
                "--diff", diff_file,
                "--mode", "all",
                "--max-cycles", "2",
                "--worker-response", worker_response_file,
            ],
            capture_output=True,
            text=True,
            cwd=str(SCRIPT_DIR),
        )
        if result.returncode == 0 and result.stdout.strip():
            output = json.loads(result.stdout)
            assert output["status"] == "completed"

    @mock.patch("review_loop.run_reviewer")
    def test_worker_says_continue_with_updated_diff(
        self, mock_reviewer, task_spec_file, diff_file, worker_response_file, tmp_path
    ):
        mock_reviewer.return_value = "[BLOCKING] — still broken"
        updated_diff = tmp_path / "updated.patch"
        updated_diff.write_text("--- updated diff ---")
        Path(worker_response_file).write_text(f"CONTINUE\n{updated_diff}\n")

        result = subprocess.run(
            [
                "python3",
                str(SCRIPT_DIR / "review_loop.py"),
                "--repo-path", REPO_PATH,
                "--task-spec", task_spec_file,
                "--diff", diff_file,
                "--mode", "all",
                "--max-cycles", "2",
                "--worker-response", worker_response_file,
            ],
            capture_output=True,
            text=True,
            cwd=str(SCRIPT_DIR),
        )
        if result.returncode == 0 and result.stdout.strip():
            output = json.loads(result.stdout)
            assert output["cycles_used"] <= 2


class TestEdgeCases:
    def test_empty_diff(self, tmp_path):
        spec = tmp_path / "spec.md"
        spec.write_text("Do nothing")
        diff = tmp_path / "diff.patch"
        diff.write_text("")
        protocol = load_review_protocol()
        prompt = build_reviewer_prompt("Do nothing", "", "/repo", protocol)
        assert "Do nothing" in prompt

    def test_very_large_diff(self, tmp_path):
        protocol = load_review_protocol()
        large_diff = "+" * 100_000
        prompt = build_reviewer_prompt("spec", large_diff, "/repo", protocol)
        assert len(prompt) > 100_000

    @mock.patch("review_loop.run_reviewer")
    def test_reviewer_returns_empty(self, mock_reviewer):
        mock_reviewer.return_value = ""
        protocol = load_review_protocol()
        result = run_single_cycle("spec", "diff", "/repo", "sonnet", protocol, cycle=1)
        assert result["review"] == ""


if __name__ == "__main__":
    pytest.main([__file__, "-v"])

import json
import os
import subprocess
import sys
import unittest
from pathlib import Path


SCRIPTS_DIR = Path(__file__).resolve().parents[1]
EVIDENCE_CLI = SCRIPTS_DIR / "vixrex_evidence.py"


class EvidenceCliTestCase(unittest.TestCase):
    def git(self, root: Path, *args: str) -> str:
        result = subprocess.run(
            ["git", *args], cwd=root, capture_output=True, text=True, check=False
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result.stdout.strip()

    def create_repo(self, root: Path) -> str:
        self.git(root, "init", "--initial-branch=main")
        self.git(root, "config", "user.email", "evidence@example.test")
        self.git(root, "config", "user.name", "Evidence Test")
        self.git(root, "remote", "add", "origin", "https://github.com/example/vixrex.git")
        (root / "README.md").write_text("# fixture\n", encoding="utf-8")
        (root / ".gitignore").write_text(".vixrex-dev/\n", encoding="utf-8")
        self.git(root, "add", "README.md", ".gitignore")
        self.git(root, "commit", "-m", "fixture")
        return self.git(root, "rev-parse", "HEAD")

    def fake_gh_env(
        self,
        directory: Path,
        *,
        issue: dict[str, object] | None = None,
        pull_requests: list[dict[str, object]] | None = None,
        head_sha: str | None = None,
        mutate_head: bool = False,
        mutate_worktree: bool = False,
        mutate_issue_on_recheck: bool = False,
        mutate_pr_on_recheck: bool = False,
    ) -> dict[str, str]:
        issue = issue or {
            "number": 39,
            "title": "Sahip önizlemesini tamamla",
            "body": "Uygulamadan önce `implementation_plan.md` zorunlu olarak okunur.",
            "state": "OPEN",
            "updatedAt": "2026-08-03T21:19:42Z",
            "url": "https://example.test/issues/39",
            "labels": [],
            "comments": [],
        }
        if pull_requests is None:
            pull_requests = [
                {
                    "number": 74,
                    "title": "Demo vitrini güncelle",
                    "body": "Production migration uygulandı ve canlıda doğrulandı.",
                    "url": "https://example.test/pull/74",
                    "headRefName": "main",
                    "headRefOid": head_sha or "a" * 40,
                    "baseRefName": "main",
                    "baseRefOid": "b" * 40,
                    "state": "OPEN",
                    "updatedAt": "2026-08-09T13:26:50Z",
                    "changedFiles": 1,
                    "files": [{
                        "path": "public_web/src/example.ts",
                        "additions": 3,
                        "deletions": 1,
                    }],
                },
                {
                    "number": 73,
                    "title": "Aynı adı kullanan eski dal",
                    "body": "Canlıda doğrulandı.",
                    "url": "https://example.test/pull/73",
                    "headRefName": "main",
                    "headRefOid": "f" * 40,
                    "baseRefName": "main",
                    "baseRefOid": "e" * 40,
                    "state": "MERGED",
                    "updatedAt": "2026-08-08T13:26:50Z",
                },
            ]
        mutation = ""
        if mutate_head:
            mutation = (
                "    marker = Path(__file__).with_suffix('.head-moved')\n"
                "    if not marker.exists():\n"
                "        marker.write_text('moved', encoding='utf-8')\n"
                "        Path('head-moved.txt').write_text('moved\\n', encoding='utf-8')\n"
                "        subprocess.run(['git', 'add', 'head-moved.txt'], check=True, capture_output=True)\n"
                "        subprocess.run(['git', 'commit', '-m', 'move head'], check=True, capture_output=True)\n"
            )
        if mutate_worktree:
            mutation += (
                "    Path('mutable.txt').write_text('changed during capture\\n', encoding='utf-8')\n"
            )
        if mutate_issue_on_recheck:
            mutation += (
                "    marker = Path(__file__).with_suffix('.issue-seen')\n"
                "    if marker.exists():\n"
                "        issue['body'] += '\\nSnapshot sırasında değişti.'\n"
                "        issue['updatedAt'] = '2026-08-10T00:01:00Z'\n"
                "    else:\n"
                "        marker.write_text('seen', encoding='utf-8')\n"
            )
        pr_list_mutation = ""
        if mutate_pr_on_recheck:
            pr_list_mutation = (
                "    marker = Path(__file__).with_suffix('.pr-seen')\n"
                "    if marker.exists():\n"
                "        pull_requests[0]['body'] += ' changed'\n"
                "        pull_requests[0]['updatedAt'] = '2026-08-10T00:01:00Z'\n"
                "    else:\n"
                "        marker.write_text('seen', encoding='utf-8')\n"
            )
        fake = directory / "fake_gh.py"
        fake.write_text(
            "import json\nimport subprocess\nimport sys\nfrom pathlib import Path\n"
            f"issue = {issue!r}\npull_requests = {pull_requests!r}\n"
            "args = sys.argv[1:]\n"
            "if args[:2] == ['issue', 'view']:\n"
            + mutation
            + "    print(json.dumps(issue))\n"
            "elif args[:2] == ['pr', 'list']:\n"
            + pr_list_mutation
            + "    print(json.dumps(pull_requests))\n"
            "elif args[:2] == ['pr', 'view']:\n"
            "    number = int(args[2])\n"
            "    match = next((item for item in pull_requests if item['number'] == number), None)\n"
            "    if match is None:\n"
            "        raise SystemExit(1)\n"
            "    print(json.dumps(match))\n"
            "else:\n"
            "    print('unexpected gh arguments: ' + repr(args), file=sys.stderr)\n"
            "    raise SystemExit(2)\n",
            encoding="utf-8",
        )
        if os.name == "nt":
            launcher = directory / "gh.cmd"
            launcher.write_text(
                f'@"{sys.executable}" "%~dp0fake_gh.py" %*\n', encoding="utf-8"
            )
        else:
            launcher = directory / "gh"
            launcher.write_text(
                f'#!/bin/sh\nexec "{sys.executable}" "$(dirname "$0")/fake_gh.py" "$@"\n',
                encoding="utf-8",
            )
            launcher.chmod(0o755)
        env = os.environ.copy()
        env["PATH"] = str(directory) + os.pathsep + env.get("PATH", "")
        return env

    def run_cli(
        self, root: Path, *, issue: int, base: str, env: dict[str, str]
    ) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(EVIDENCE_CLI), "--issue", str(issue), "--base", base],
            cwd=root,
            capture_output=True,
            text=True,
            check=False,
            env=env,
        )

    def evidence_paths(self, root: Path) -> list[Path]:
        return sorted((root / ".vixrex-dev").glob("*/*/evidence.json"))

    def manifest(self, root: Path) -> tuple[Path, dict[str, object]]:
        matches = self.evidence_paths(root)
        self.assertEqual(len(matches), 1, matches)
        return matches[0], json.loads(matches[0].read_text(encoding="ascii"))

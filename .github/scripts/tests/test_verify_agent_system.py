import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


SCRIPTS_DIR = Path(__file__).resolve().parents[1]
DOCTOR = SCRIPTS_DIR / "verify_agent_system.py"
FIXTURES = Path(__file__).resolve().parent / "fixtures"


class VerifyAgentSystemCliTest(unittest.TestCase):
    def run_doctor(
        self,
        root: Path,
        *extra_args: str,
        env: dict[str, str] | None = None,
    ) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(DOCTOR), "--root", str(root), *extra_args],
            capture_output=True,
            text=True,
            check=False,
            env=env,
        )

    def fake_gh_env(
        self,
        directory: Path,
        *,
        labels: list[str],
        contexts: list[str],
    ) -> dict[str, str]:
        fake = directory / "fake_gh.py"
        fake.write_text(
            "import json\n"
            "import sys\n"
            f"labels = {labels!r}\n"
            f"contexts = {contexts!r}\n"
            "if sys.argv[1:3] == ['label', 'list']:\n"
            "    print(json.dumps([{'name': name} for name in labels]))\n"
            "elif len(sys.argv) > 1 and sys.argv[1] == 'api':\n"
            "    print(json.dumps({'contexts': contexts, 'checks': []}))\n"
            "else:\n"
            "    print('unexpected gh arguments', file=sys.stderr)\n"
            "    raise SystemExit(2)\n",
            encoding="utf-8",
        )

        if os.name == "nt":
            launcher = directory / "gh.cmd"
            launcher.write_text(
                f'@"{sys.executable}" "%~dp0fake_gh.py" %*\n',
                encoding="utf-8",
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

    def test_valid_fixture_passes(self) -> None:
        result = self.run_doctor(FIXTURES / "valid")

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("[OK] Ajan sistemi", result.stdout)

    def test_invalid_fixtures_fail_with_their_reason(self) -> None:
        cases = json.loads((FIXTURES / "failure_cases.json").read_text(encoding="utf-8"))

        for name, case in cases.items():
            with self.subTest(case=name), tempfile.TemporaryDirectory() as temp_dir:
                root = Path(temp_dir) / "repo"
                shutil.copytree(FIXTURES / "valid", root)

                if path := case.get("delete"):
                    (root / path).unlink()

                if replacement := case.get("replace"):
                    path = root / replacement["path"]
                    content = path.read_text(encoding="utf-8")
                    self.assertIn(replacement["old"], content)
                    path.write_text(
                        content.replace(replacement["old"], replacement["new"], 1),
                        encoding="utf-8",
                    )

                if created := case.get("create"):
                    path = root / created["path"]
                    path.parent.mkdir(parents=True, exist_ok=True)
                    path.write_text(created["content"], encoding="utf-8")

                result = self.run_doctor(root)

                self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
                self.assertIn(case["expect"], result.stdout)

    def test_github_labels_and_optional_protection(self) -> None:
        required_labels = [
            "needs-triage",
            "needs-info",
            "ready-for-agent",
            "ready-for-human",
            "wontfix",
            "wayfinder:map",
            "wayfinder:research",
            "wayfinder:prototype",
            "wayfinder:grilling",
            "wayfinder:task",
        ]
        with tempfile.TemporaryDirectory() as temp_dir:
            directory = Path(temp_dir)

            complete_env = self.fake_gh_env(
                directory,
                labels=required_labels,
                contexts=["verify-protected-tests"],
            )
            complete = self.run_doctor(
                FIXTURES / "valid",
                "--github-repo",
                "xpodiumyours/vixrex",
                "--require-protection",
                env=complete_env,
            )
            self.assertEqual(complete.returncode, 0, complete.stdout + complete.stderr)

            missing_label_env = self.fake_gh_env(
                directory,
                labels=[name for name in required_labels if name != "needs-info"],
                contexts=["verify-protected-tests"],
            )
            missing_label = self.run_doctor(
                FIXTURES / "valid",
                "--github-repo",
                "xpodiumyours/vixrex",
                env=missing_label_env,
            )
            self.assertEqual(missing_label.returncode, 1)
            self.assertIn("needs-info", missing_label.stdout)

            missing_protection_env = self.fake_gh_env(
                directory,
                labels=required_labels,
                contexts=["CodeQL"],
            )
            missing_protection = self.run_doctor(
                FIXTURES / "valid",
                "--github-repo",
                "xpodiumyours/vixrex",
                "--require-protection",
                env=missing_protection_env,
            )
            self.assertEqual(missing_protection.returncode, 1)
            self.assertIn("verify-protected-tests", missing_protection.stdout)


if __name__ == "__main__":
    unittest.main()

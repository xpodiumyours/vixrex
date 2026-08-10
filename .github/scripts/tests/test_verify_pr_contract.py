import os
import subprocess
import sys
import unittest
from pathlib import Path


SCRIPTS_DIR = Path(__file__).resolve().parents[1]
VERIFIER = SCRIPTS_DIR / "verify_pr_contract.py"
FIXTURES = Path(__file__).resolve().parent / "fixtures" / "pr_contract"


class VerifyPrContractCliTest(unittest.TestCase):
    def run_verifier(
        self,
        fixture: str,
        *,
        use_environment: bool = False,
    ) -> subprocess.CompletedProcess[str]:
        event = FIXTURES / fixture
        command = [sys.executable, str(VERIFIER)]
        env = os.environ.copy()
        if use_environment:
            env["GITHUB_EVENT_PATH"] = str(event)
        else:
            command.extend(["--event", str(event)])
        return subprocess.run(
            command,
            capture_output=True,
            text=True,
            check=False,
            env=env,
        )

    def test_valid_contract_passes_from_argument_and_environment(self) -> None:
        for use_environment in (False, True):
            with self.subTest(use_environment=use_environment):
                result = self.run_verifier("valid.json", use_environment=use_environment)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertIn("[OK] PR sözleşmesi", result.stdout)

    def test_invalid_contract_fixtures_fail(self) -> None:
        expected = {
            "missing-section.json": "Geri Dönüş",
            "placeholders.json": "Kırmızı Kanıt",
            "unlinked-issue.json": "Fixes #",
        }
        for fixture, message in expected.items():
            with self.subTest(fixture=fixture):
                result = self.run_verifier(fixture)
                self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
                self.assertIn(message, result.stdout)


if __name__ == "__main__":
    unittest.main()

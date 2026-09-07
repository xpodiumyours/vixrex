import importlib.util
import unittest
from pathlib import Path
from unittest.mock import patch


SCRIPT = Path(__file__).resolve().parents[1] / "parity_delivery_guard.py"
SPEC = importlib.util.spec_from_file_location("parity_delivery_guard", SCRIPT)
assert SPEC and SPEC.loader
guard = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(guard)


def approved_pr() -> dict:
    return {
        "number": 431,
        "draft": False,
        "labels": [{"name": "merge-approved"}],
        "head": {"sha": "abc123"},
    }


class ParityDeliveryGuardTest(unittest.TestCase):
    def setUp(self) -> None:
        self.repo_patcher = patch.object(guard, "DEPO", "xpodiumyours/vixrex")
        self.token_patcher = patch.object(guard, "TOKEN", "token")
        self.repo_patcher.start()
        self.token_patcher.start()

    def tearDown(self) -> None:
        self.repo_patcher.stop()
        self.token_patcher.stop()

    def test_no_approved_pr_passes(self) -> None:
        with patch.object(guard, "istek", return_value=[]):
            self.assertEqual(guard.main(), 0)

    def test_missing_parity_check_blocks_delivery(self) -> None:
        with patch.object(
            guard, "istek", side_effect=[[approved_pr()], {"check_runs": []}]
        ):
            self.assertEqual(guard.main(), 1)

    def test_pending_parity_check_blocks_delivery(self) -> None:
        checks = {
            "check_runs": [
                {
                    "id": 10,
                    "name": guard.PARITE_KAPISI,
                    "status": "in_progress",
                    "conclusion": None,
                }
            ]
        }
        with patch.object(guard, "istek", side_effect=[[approved_pr()], checks]):
            self.assertEqual(guard.main(), 1)

    def test_completed_success_allows_delivery_script_to_decide(self) -> None:
        checks = {
            "check_runs": [
                {
                    "id": 10,
                    "name": guard.PARITE_KAPISI,
                    "status": "completed",
                    "conclusion": "success",
                }
            ]
        }
        with patch.object(guard, "istek", side_effect=[[approved_pr()], checks]):
            self.assertEqual(guard.main(), 0)

    def test_completed_failure_is_not_hidden(self) -> None:
        checks = {
            "check_runs": [
                {
                    "id": 10,
                    "name": guard.PARITE_KAPISI,
                    "status": "completed",
                    "conclusion": "failure",
                }
            ]
        }
        with patch.object(guard, "istek", side_effect=[[approved_pr()], checks]):
            self.assertEqual(guard.main(), 0)


if __name__ == "__main__":
    unittest.main()

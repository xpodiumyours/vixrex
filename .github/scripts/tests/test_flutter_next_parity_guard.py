import importlib.util
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[1] / "flutter_next_parity_guard.py"
SPEC = importlib.util.spec_from_file_location("flutter_next_parity_guard", SCRIPT)
assert SPEC and SPEC.loader
guard = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(guard)


class FlutterNextParityGuardTest(unittest.TestCase):
    def test_next_change_alone_is_allowed(self) -> None:
        self.assertEqual(
            guard.mixed_change_violations(
                ["public_web/src/components/landing/LandingApkAssistant.tsx"],
                enforce=True,
            ),
            [],
        )

    def test_next_cannot_move_flutter_reference_in_same_pr(self) -> None:
        violations = guard.mixed_change_violations(
            [
                "public_web/src/components/landing/LandingApkAssistant.tsx",
                "lib/screens/vixrex_onboarding_chat_screen.dart",
                "test/onboarding_niyet_akis_test.dart",
            ],
            enforce=True,
        )
        self.assertEqual(
            violations,
            [
                "lib/screens/vixrex_onboarding_chat_screen.dart",
                "test/onboarding_niyet_akis_test.dart",
            ],
        )

    def test_next_cannot_rewrite_its_own_parity_gate(self) -> None:
        violations = guard.mixed_change_violations(
            [
                "public_web/src/app/page.tsx",
                "parity/flutter_next_contract.json",
                ".github/scripts/flutter_next_parity_guard.py",
            ],
            enforce=True,
        )
        self.assertEqual(
            violations,
            [
                ".github/scripts/flutter_next_parity_guard.py",
                "parity/flutter_next_contract.json",
            ],
        )

    def test_flutter_reference_change_without_next_is_separate_and_allowed(self) -> None:
        self.assertEqual(
            guard.mixed_change_violations(
                [
                    "lib/screens/vixrex_onboarding_chat_screen.dart",
                    "parity/flutter_reference.lock.json",
                ],
                enforce=True,
            ),
            [],
        )

    def test_bootstrap_is_the_only_mixed_change_exception(self) -> None:
        self.assertEqual(
            guard.mixed_change_violations(
                [
                    "public_web/src/app/page.tsx",
                    "parity/flutter_next_contract.json",
                ],
                enforce=False,
            ),
            [],
        )


if __name__ == "__main__":
    unittest.main()

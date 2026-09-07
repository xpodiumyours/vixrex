import importlib.util
import json
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[1] / "parity_guard.py"
SPEC = importlib.util.spec_from_file_location("parity_guard", SCRIPT)
assert SPEC and SPEC.loader
parity_guard = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(parity_guard)


class ParityGuardTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)

        (self.root / ".github/parity").mkdir(parents=True)
        (self.root / "shared").mkdir(parents=True)
        (self.root / "test").mkdir(parents=True)
        (self.root / "public_web/src/components/landing").mkdir(parents=True)

        self.shared = self.root / "shared/vixrex_mesajlar.json"
        self.widget_test = self.root / "test/onboarding_niyet_akis_test.dart"
        self.target = self.root / "public_web/src/components/landing/LandingApkAssistant.tsx"

        labels = "Hazır Vitrin Seç\nSıfırdan Oluştur\nBakınıyorum\n"
        self.shared.write_text(labels, encoding="utf-8")
        self.widget_test.write_text(labels, encoding="utf-8")
        self.target.write_text("implementation", encoding="utf-8")
        self._write_manifest()

    def tearDown(self) -> None:
        self.temp.cleanup()

    def _write_manifest(self) -> None:
        manifest = {
            "version": 1,
            "reference": "Flutter Web",
            "policy": {
                "allow_unlisted_differences": False,
                "implementation_may_edit_oracle": False,
                "implementation_may_edit_gate": False,
                "unverified_behavior": "BLOCK",
                "contract_required_prefixes": [
                    "public_web/src/components/landing/"
                ],
            },
            "contracts": [
                {
                    "id": "landing-onboarding-welcome",
                    "target_paths": [
                        "public_web/src/components/landing/LandingApkAssistant.tsx"
                    ],
                    "oracle_git_blobs": {
                        "shared/vixrex_mesajlar.json": parity_guard.git_blob_sha(self.shared),
                        "test/onboarding_niyet_akis_test.dart": parity_guard.git_blob_sha(self.widget_test),
                    },
                    "oracle_assertions": {
                        "shared/vixrex_mesajlar.json": [
                            "Hazır Vitrin Seç",
                            "Sıfırdan Oluştur",
                            "Bakınıyorum",
                        ],
                        "test/onboarding_niyet_akis_test.dart": [
                            "Hazır Vitrin Seç",
                            "Sıfırdan Oluştur",
                            "Bakınıyorum",
                        ],
                    },
                    "flutter_tests": ["test/onboarding_niyet_akis_test.dart"],
                    "browser": {
                        "enabled": True,
                        "route": "/",
                        "scope_text": "Hızlı Seçenekler",
                        "button_oracle_paths": [
                            "shared/vixrex_mesajlar.json",
                            "test/onboarding_niyet_akis_test.dart",
                        ],
                        "expected_buttons": [
                            "Hazır Vitrin Seç",
                            "Sıfırdan Oluştur",
                            "Bakınıyorum",
                        ],
                        "forbidden_buttons": ["Evet, Oluşturalım"],
                    },
                }
            ],
        }
        (self.root / ".github/parity/contracts.json").write_text(
            json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )

    def test_valid_manifest_is_locked_to_flutter_oracle(self) -> None:
        manifest = parity_guard.validate_manifest(self.root)
        self.assertEqual(manifest["reference"], "Flutter Web")

    def test_policy_cannot_allow_unverified_behavior(self) -> None:
        path = self.root / ".github/parity/contracts.json"
        manifest = json.loads(path.read_text(encoding="utf-8"))
        manifest["policy"]["unverified_behavior"] = "PASS"
        path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
        with self.assertRaisesRegex(parity_guard.ParityError, "BLOCK"):
            parity_guard.validate_manifest(self.root)

    def test_target_only_change_is_parity_affected(self) -> None:
        manifest = parity_guard.validate_manifest(self.root)
        affected, ids = parity_guard.evaluate_changes(
            ["public_web/src/components/landing/LandingApkAssistant.tsx"],
            manifest,
            self.root,
        )
        self.assertTrue(affected)
        self.assertEqual(ids, ["landing-onboarding-welcome"])

    def test_uncontracted_landing_change_is_blocked(self) -> None:
        manifest = parity_guard.validate_manifest(self.root)
        with self.assertRaisesRegex(parity_guard.ParityError, "CONTRACT_REQUIRED"):
            parity_guard.evaluate_changes(
                ["public_web/src/components/landing/HeroSection.tsx"],
                manifest,
                self.root,
            )

    def test_outside_required_prefix_does_not_need_contract(self) -> None:
        manifest = parity_guard.validate_manifest(self.root)
        affected, ids = parity_guard.evaluate_changes(
            ["public_web/src/app/privacy/page.tsx"],
            manifest,
            self.root,
        )
        self.assertFalse(affected)
        self.assertEqual(ids, [])

    def test_target_cannot_change_with_gate_in_same_pr(self) -> None:
        manifest = parity_guard.validate_manifest(self.root)
        with self.assertRaisesRegex(parity_guard.ParityError, "parite kapısı/manifesti"):
            parity_guard.evaluate_changes(
                [
                    "public_web/src/components/landing/LandingApkAssistant.tsx",
                    ".github/parity/contracts.json",
                ],
                manifest,
                self.root,
            )

    def test_bootstrap_allows_gate_and_target_once(self) -> None:
        manifest = parity_guard.validate_manifest(self.root)
        affected, ids = parity_guard.evaluate_changes(
            [
                "public_web/src/components/landing/LandingApkAssistant.tsx",
                ".github/parity/contracts.json",
            ],
            manifest,
            self.root,
            enforce_gate_separation=False,
        )
        self.assertTrue(affected)
        self.assertEqual(ids, ["landing-onboarding-welcome"])

    def test_bootstrap_still_blocks_target_plus_flutter_oracle(self) -> None:
        manifest = parity_guard.validate_manifest(self.root)
        with self.assertRaisesRegex(parity_guard.ParityError, "Flutter oracle"):
            parity_guard.evaluate_changes(
                [
                    "public_web/src/components/landing/LandingApkAssistant.tsx",
                    "test/onboarding_niyet_akis_test.dart",
                    ".github/parity/contracts.json",
                ],
                manifest,
                self.root,
                enforce_gate_separation=False,
            )

    def test_oracle_change_requires_manifest_lock_update(self) -> None:
        manifest = parity_guard.validate_manifest(self.root)
        with self.assertRaisesRegex(parity_guard.ParityError, "kilidi güncellenmedi"):
            parity_guard.evaluate_changes(
                ["test/onboarding_niyet_akis_test.dart"],
                manifest,
                self.root,
            )

    def test_browser_buttons_must_come_from_flutter_oracle(self) -> None:
        manifest_path = self.root / ".github/parity/contracts.json"
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        manifest["contracts"][0]["browser"]["expected_buttons"][0] = "Uydurma Buton"
        manifest_path.write_text(
            json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )

        with self.assertRaisesRegex(parity_guard.ParityError, "Flutter oracle"):
            parity_guard.validate_manifest(self.root)


if __name__ == "__main__":
    unittest.main()

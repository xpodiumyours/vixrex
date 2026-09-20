import importlib.util
import unittest
from pathlib import Path
from unittest.mock import patch


SCRIPT = Path(__file__).resolve().parents[1] / "teslimat.py"
SPEC = importlib.util.spec_from_file_location("teslimat", SCRIPT)
assert SPEC and SPEC.loader
teslimat = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(teslimat)


class TeslimatSecurityGatesTest(unittest.TestCase):
    def test_security_gates_are_required(self) -> None:
        self.assertIn("Supabase auth security config check", teslimat.ZORUNLU_KAPILAR)
        self.assertIn(
            "Supabase yerel doğrulama — GRANT güvenlik bekçisi",
            teslimat.ZORUNLU_KAPILAR,
        )

    def test_pending_grant_gate_blocks_merge(self) -> None:
        checks = [
            {"name": "Secret sızıntı taraması", "status": "completed", "conclusion": "success"},
            {"name": "Supabase auth security config check", "status": "completed", "conclusion": "success"},
            {"name": "Değişiklik yüzeyi", "status": "completed", "conclusion": "success"},
            {"name": "Supabase yerel doğrulama — GRANT güvenlik bekçisi", "status": "in_progress", "conclusion": None},
            {"name": "Next.js — lint, tip, test, build", "status": "completed", "conclusion": "success"},
            {"name": "Flutter — analiz ve testler", "status": "completed", "conclusion": "success"},
            {"name": "Şema üretim hattı — sapma kontrolü", "status": "completed", "conclusion": "success"},
        ]
        merge_calls = []

        def fake_request(path, method="GET", body=None):
            if "/compare/main..." in path:
                return {"behind_by": 0}
            if "/merge" in path:
                merge_calls.append((path, method, body))
                return {"merged": True}
            return {}

        pr = {"number": 999, "head": {"sha": "abc123"}, "title": "test"}

        with (
            patch.object(teslimat, "istek", side_effect=fake_request),
            patch.object(teslimat, "kontrolleri_al", return_value=checks),
            patch.object(teslimat, "durum_yaz"),
        ):
            result = teslimat.bir_pr_teslim_et(pr)

        self.assertEqual(result, "BEKLIYOR")
        self.assertEqual(merge_calls, [])


if __name__ == "__main__":
    unittest.main()

import importlib.util
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[1] / "preview_kaniti.py"
SPEC = importlib.util.spec_from_file_location("preview_kaniti", SCRIPT)
assert SPEC and SPEC.loader
preview_kaniti = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(preview_kaniti)


class PreviewKanitiTest(unittest.TestCase):
    def test_belge_dalinda_kanit_aranmaz(self) -> None:
        gecti, gerekli, adres = preview_kaniti.denetle(
            ["AGENTS.md", "docs/not.md"],
            ["docs: yazım düzeltmesi"],
        )
        self.assertTrue(gecti)
        self.assertFalse(gerekli)
        self.assertIsNone(adres)

    def test_kod_var_kanit_yoksa_kalir(self) -> None:
        gecti, gerekli, adres = preview_kaniti.denetle(
            ["public_web/src/app/api/create-store/route.ts"],
            ["fix(yayin): bir şey düzeltildi"],
        )
        self.assertFalse(gecti)
        self.assertTrue(gerekli)
        self.assertIsNone(adres)

    def test_kanit_satiri_gecirir(self) -> None:
        gecti, gerekli, adres = preview_kaniti.denetle(
            ["public_web/src/app/api/create-store/route.ts"],
            ["fix(yayin): zincir onarıldı\n\nPreview-Kanit: https://ornek.vercel.app/v/deneme"],
        )
        self.assertTrue(gecti)
        self.assertTrue(gerekli)
        self.assertEqual(adres, "https://ornek.vercel.app/v/deneme")

    def test_sondaki_noktalama_temizlenir(self) -> None:
        self.assertEqual(
            preview_kaniti.kanit_adresi(["iş bitti.\n\nPreview-Kanit: https://ornek.vercel.app/."]),
            "https://ornek.vercel.app/",
        )

    def test_http_kabul_edilmez(self) -> None:
        self.assertIsNone(
            preview_kaniti.kanit_adresi(["Preview-Kanit: http://ornek.internal/deneme"])
        )

    def test_supabase_degisimde_de_kanit_gerekir(self) -> None:
        gecti, gerekli, _ = preview_kaniti.denetle(
            ["supabase/migrations/20261002000000_ornek.sql"],
            ["chore: migration"],
        )
        self.assertFalse(gecti)
        self.assertTrue(gerekli)


if __name__ == "__main__":
    unittest.main()

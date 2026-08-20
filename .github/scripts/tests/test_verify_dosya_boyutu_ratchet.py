import importlib.util
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[1] / "verify_dosya_boyutu_ratchet.py"
SPEC = importlib.util.spec_from_file_location("verify_dosya_boyutu_ratchet", SCRIPT)
assert SPEC and SPEC.loader
ratchet = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(ratchet)


class DosyaBoyutuRatchetTest(unittest.TestCase):
    def test_tavanin_altindaki_dosya_hata_vermez(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            kok = Path(tmp)
            dosya = kok / "ornek.dart"
            dosya.write_text("\n".join(f"satir {i}" for i in range(10)))

            hatalar = ratchet.kontrol_et({"ornek.dart": {"tavan": 20}}, kok)
            self.assertEqual(hatalar, [])

    def test_tavani_asan_dosya_hata_verir(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            kok = Path(tmp)
            dosya = kok / "ornek.dart"
            dosya.write_text("\n".join(f"satir {i}" for i in range(30)))

            hatalar = ratchet.kontrol_et({"ornek.dart": {"tavan": 20}}, kok)
            self.assertEqual(len(hatalar), 1)
            self.assertIn("ornek.dart", hatalar[0])
            self.assertIn("tavan: 20", hatalar[0])

    def test_sayisal_kisayol_da_calisir(self) -> None:
        """`{"yol": 20}` biçimi de (obje değil, doğrudan sayı) desteklenir."""
        with tempfile.TemporaryDirectory() as tmp:
            kok = Path(tmp)
            dosya = kok / "ornek.dart"
            dosya.write_text("\n".join(f"satir {i}" for i in range(30)))

            hatalar = ratchet.kontrol_et({"ornek.dart": 20}, kok)
            self.assertEqual(len(hatalar), 1)

    def test_olmayan_dosya_sessizce_atlanir(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            kok = Path(tmp)
            hatalar = ratchet.kontrol_et({"yok.dart": {"tavan": 5}}, kok)
            self.assertEqual(hatalar, [])

    def test_jsonda_olmayan_yeni_buyuk_dosya_hata_verir(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            kok = Path(tmp)
            yol = "lib/services/yeni_servis.dart"
            dosya = kok / yol
            dosya.parent.mkdir(parents=True)
            dosya.write_text("\n".join(f"satir {i}" for i in range(401)))

            hatalar = ratchet.kontrol_et({}, kok, [yol])
            self.assertEqual(len(hatalar), 1)
            self.assertIn(yol, hatalar[0])
            self.assertIn("varsayılan tavan: 400", hatalar[0])

    def test_gercek_ratchet_dosyasi_gecerli_json(self) -> None:
        """Repodaki gerçek .github/dosya_boyutu_ratchet.json'ı da doğrular —
        bu, kayıtlı dosyaların şu an gerçekten tavanın altında olduğunu
        kanıtlar (bu test PR'ın kendisi tavanı aşıyorsa da kırmızıya
        düşer)."""
        import json

        repo_kok = SCRIPT.resolve().parents[2]
        ratchet_dosyasi = repo_kok / ".github" / "dosya_boyutu_ratchet.json"
        kayitlar = json.loads(ratchet_dosyasi.read_text(encoding="utf-8"))

        hatalar = ratchet.kontrol_et(kayitlar, repo_kok)
        self.assertEqual(hatalar, [], msg="; ".join(hatalar))


if __name__ == "__main__":
    unittest.main()

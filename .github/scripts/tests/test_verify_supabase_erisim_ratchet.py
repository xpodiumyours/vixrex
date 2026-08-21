import importlib.util
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[1] / "verify_supabase_erisim_ratchet.py"
SPEC = importlib.util.spec_from_file_location("verify_supabase_erisim_ratchet", SCRIPT)
assert SPEC and SPEC.loader
ratchet = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(ratchet)


class SupabaseErisimRatchetTest(unittest.TestCase):
    def test_erisim_yoksa_hata_vermez(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            self.assertEqual(ratchet.kontrol_et({"mevcut_sayi": 0}, Path(tmp)), [])

    def test_repository_disindaki_erisim_sayilir(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            kok = Path(tmp)
            servis = kok / "lib/services/ornek.dart"
            repository = kok / "lib/repositories/ornek.dart"
            servis.parent.mkdir(parents=True)
            repository.parent.mkdir(parents=True)
            servis.write_text("final client = Supabase.instance.client;")
            repository.write_text("final client = Supabase.instance.client;")

            self.assertEqual(
                ratchet.erisim_dosyalarini_bul(kok),
                ["lib/services/ornek.dart"],
            )

    def test_sayi_artarsa_hata_verir_artmazsa_vermez(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            kok = Path(tmp)
            dosya = kok / "lib/main.dart"
            dosya.parent.mkdir(parents=True)
            dosya.write_text("final supabase = Supabase.instance;")

            self.assertEqual(ratchet.kontrol_et({"mevcut_sayi": 1}, kok), [])
            self.assertEqual(len(ratchet.kontrol_et({"mevcut_sayi": 0}, kok)), 1)


if __name__ == "__main__":
    unittest.main()

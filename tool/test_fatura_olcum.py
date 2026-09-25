import copy
import importlib.util
import unittest
from pathlib import Path

MODULE_PATH = Path(__file__).with_name("fatura_olcum.py")
SPEC = importlib.util.spec_from_file_location("fatura_olcum", MODULE_PATH)
MOD = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MOD)


class FaturaOlcumTest(unittest.TestCase):
    def setUp(self):
        self.beklenen = {
            "invoice_id": "ornek",
            "products": [
                {
                    "model": "ABC100",
                    "barcode": "8680000000001",
                    "name": "Örnek Ürün",
                    "variant": "Siyah",
                    "size": "L",
                    "qty": 2,
                    "buy": 100.0,
                    "total": 200.0,
                },
                {
                    "model": "ABC200",
                    "barcode": "8680000000002",
                    "name": "İkinci Ürün",
                    "variant": "Beyaz",
                    "size": "M",
                    "qty": 3,
                    "buy": 50.0,
                    "total": 150.0,
                },
            ],
        }

    def test_mukemmel_sonuc_yuzde_yuz(self):
        gercek = copy.deepcopy(self.beklenen)
        sonuc = MOD.olc(self.beklenen, gercek)
        self.assertEqual(sonuc["matched_product_count"], 2)
        self.assertEqual(sonuc["missing_product_count"], 0)
        self.assertEqual(sonuc["extra_product_count"], 0)
        self.assertEqual(sonuc["expected_quantity"], 5)
        self.assertEqual(sonuc["actual_quantity"], 5)
        self.assertEqual(sonuc["expected_total"], 350.0)
        self.assertEqual(sonuc["actual_total"], 350.0)
        self.assertEqual(sonuc["overall_score"], 100.0)

    def test_eksik_barkod_ve_yanlis_adet_ayri_gorunur(self):
        gercek = copy.deepcopy(self.beklenen)
        gercek["products"][0]["barcode"] = ""
        gercek["products"][0]["qty"] = 1
        sonuc = MOD.olc(self.beklenen, gercek)
        self.assertEqual(sonuc["matched_product_count"], 2)
        self.assertEqual(sonuc["fields"]["barcode"]["dogru"], 1)
        self.assertEqual(sonuc["fields"]["qty"]["dogru"], 1)
        self.assertEqual(sonuc["actual_quantity"], 4)
        self.assertLess(sonuc["overall_score"], 100.0)

    def test_eksik_ve_fazla_urun_ayri_sayilir(self):
        gercek = {"products": [copy.deepcopy(self.beklenen["products"][0])]}
        gercek["products"].append(
            {
                "model": "FAZLA1",
                "barcode": "9999999999999",
                "name": "Fazla Ürün",
                "variant": "",
                "size": "",
                "qty": 1,
                "buy": 10,
                "total": 10,
            }
        )
        sonuc = MOD.olc(self.beklenen, gercek)
        self.assertEqual(sonuc["matched_product_count"], 1)
        self.assertEqual(sonuc["missing_product_count"], 1)
        self.assertEqual(sonuc["extra_product_count"], 1)


if __name__ == "__main__":
    unittest.main()

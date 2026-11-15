import { readFileSync } from "node:fs";
import path from "node:path";
import { expect, it } from "vitest";

const depoKoku = path.resolve(__dirname, "../..");
const okumaYolu = path.join(depoKoku, "public_web/tests/fixtures/fatura-kart/gercek-okuma.json");
const olcumYolu = path.join(depoKoku, "tool/fatura_olcum/veri/2026-09-15-satis-teklif-beklenen.json");
const sayiyaCevir = (deger: string) => Number(deger.replace(/\s/g, "").replace(",", "."));

it("sentetik okuma fixture'ında ham satır, birim fiyat ve satır toplamı birbirini tutar", () => {
  const belge = JSON.parse(readFileSync(okumaYolu, "utf8")) as {
    satirlar: Array<{ hamSatir: string; adet: number; birimFiyat: number; tutar: number }>;
  };

  expect(belge.satirlar).toHaveLength(5);
  for (const [index, satir] of belge.satirlar.entries()) {
    const eslesme = satir.hamSatir.match(/(\d+(?:[.,]\d+)?)\s*TL\s*(\d+(?:[.,]\d+)?)\s*TL$/);
    expect(eslesme, `${index + 1}. satırın sonunda birim ve toplam fiyat olmalı`).not.toBeNull();
    const [, hamBirim, hamToplam] = eslesme!;
    expect(sayiyaCevir(hamBirim), `${index + 1}. satır ham birim fiyat`).toBe(satir.birimFiyat);
    expect(sayiyaCevir(hamToplam), `${index + 1}. satır ham toplam`).toBe(satir.tutar);
    expect(satir.adet * satir.birimFiyat, `${index + 1}. satır aritmetiği`).toBe(satir.tutar);
  }
});

it("fatura ölçüm bekleneni satır aritmetiği ve genel toplamlarla uyumlu", () => {
  const belge = JSON.parse(readFileSync(olcumYolu, "utf8")) as {
    expected_product_count: number;
    expected_quantity: number;
    expected_total: number;
    products: Array<{ qty: number; buy: number; total: number }>;
  };

  expect(belge.products).toHaveLength(belge.expected_product_count);
  for (const [index, urun] of belge.products.entries()) {
    expect(urun.qty * urun.buy, `${index + 1}. ürün aritmetiği`).toBe(urun.total);
  }
  expect(belge.products.reduce((toplam, urun) => toplam + urun.qty, 0)).toBe(belge.expected_quantity);
  expect(belge.products.reduce((toplam, urun) => toplam + urun.total, 0)).toBe(belge.expected_total);
});

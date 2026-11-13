import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { describe, expect, it } from "vitest";
import { gorselIzinBekliyorMu } from "@/lib/faturaGorselHakDenetimi";

describe("gorselIzinBekliyorMu", () => {
  it("kayit yoksa bilinmiyor doner", () => {
    expect(gorselIzinBekliyorMu(null)).toBeUndefined();
    expect(gorselIzinBekliyorMu({})).toBeUndefined();
    expect(gorselIzinBekliyorMu({ gorselKaynaklari: [] })).toBeUndefined();
    expect(gorselIzinBekliyorMu({ gorselKaynaklari: "metin" })).toBeUndefined();
  });

  it("dogrulanmis izin varsa beklemiyor", () => {
    expect(
      gorselIzinBekliyorMu({
        gorselKaynaklari: [
          { hakKayitDurumu: "verified_supplier_permission" },
          { hakKayitDurumu: "verified_supplier_permission" },
        ],
      }),
    ).toBe(false);
  });

  it("belirsiz veya ret varsa bekliyor", () => {
    expect(gorselIzinBekliyorMu({ gorselKaynaklari: [{ hakKayitDurumu: "unknown" }] })).toBe(true);
    expect(gorselIzinBekliyorMu({ gorselKaynaklari: [{ hakKayitDurumu: "denied" }] })).toBe(true);
    expect(
      gorselIzinBekliyorMu({
        gorselKaynaklari: [
          { hakKayitDurumu: "verified_supplier_permission" },
          { hakKayitDurumu: "kayit_yok" },
        ],
      }),
    ).toBe(true);
  });

  it("durum alani okunamayan kayit beklemede kalir", () => {
    expect(gorselIzinBekliyorMu({ gorselKaynaklari: [{}] })).toBe(true);
    expect(gorselIzinBekliyorMu({ gorselKaynaklari: [{ hakKayitDurumu: 42 }] })).toBe(true);
  });
});

describe("üretici izni görünürlük sınırı", () => {
  const kaynak = (yol: string) => readFileSync(fileURLToPath(new URL(`../${yol}`, import.meta.url)), "utf8");

  it("iç izin durumu tüketici kartlarına basılmaz", () => {
    for (const yol of [
      "src/app/v/[slug]/ProductCatalog.tsx",
      "src/components/ProductDetailExperienceBase.tsx",
    ]) {
      const icerik = kaynak(yol);
      expect(icerik).not.toContain("gorselIzinBekliyor");
      expect(icerik).not.toContain("İzin belgesi bekleniyor");
    }
  });

  it("esnafın mevcut izin uyarısı korunur", () => {
    expect(kaynak("src/components/owner/InvoiceToProducts.tsx"))
      .toContain("üretici fotoğrafı — izin doğrulanınca vitrinde görünür");
  });
});

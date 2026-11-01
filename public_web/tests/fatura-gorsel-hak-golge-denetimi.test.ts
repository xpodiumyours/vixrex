import { describe, expect, it } from "vitest";
import {
  gorselHakKaydiniRaporla,
  gorselHakKayitlariniDerle,
} from "@/lib/faturaGorselHakDenetimi";

describe("P0-01: fatura gorsel haklarinin yayini kilitlemeyen golge denetimi", () => {
  it("unknown kaydi bilinmiyor diye raporlar; onayli izin uydurmaz", () => {
    const haklar = gorselHakKayitlariniDerle([
      { image_url: "https://uretici.example/1.jpg", usage_status: "unknown" },
    ]);
    expect(gorselHakKaydiniRaporla("https://uretici.example/1.jpg", haklar))
      .toEqual({ hakKayitDurumu: "unknown", hakIncelemeGerekiyor: true });
  });

  it("dogrulanmis kaydi ayri, kayitsiz gorseli incelemede tutar", () => {
    const haklar = gorselHakKayitlariniDerle([
      { image_url: " https://uretici.example/2.jpg ", usage_status: "verified_supplier_permission" },
    ]);
    expect(gorselHakKaydiniRaporla("https://uretici.example/2.jpg", haklar))
      .toEqual({ hakKayitDurumu: "verified_supplier_permission", hakIncelemeGerekiyor: false });
    expect(gorselHakKaydiniRaporla("https://esnaf.example/kendi.jpg", haklar))
      .toEqual({ hakKayitDurumu: "kayit_yok", hakIncelemeGerekiyor: true });
  });

  it("tekrarlanan adreste denied, unknown ve verified durumlarindan baskindir", () => {
    const adres = "https://uretici.example/3.jpg";
    const haklar = gorselHakKayitlariniDerle([
      { image_url: adres, usage_status: "unknown" },
      { image_url: adres, usage_status: "denied" },
      { image_url: adres, usage_status: "verified_supplier_permission" },
    ]);
    expect(gorselHakKaydiniRaporla(adres, haklar).hakKayitDurumu).toBe("denied");
  });

  it("beklenmedik durum ve bos URL dogrulanmis izne donusmez", () => {
    const haklar = gorselHakKayitlariniDerle([
      { image_url: "", usage_status: "verified_supplier_permission" },
      { image_url: "https://uretici.example/4.jpg", usage_status: "new_state" },
    ]);
    expect(haklar.has("")).toBe(false);
    expect(gorselHakKaydiniRaporla("https://uretici.example/4.jpg", haklar).hakKayitDurumu)
      .toBe("unknown");
  });

  it("bos liste de mevcut fatura karti akisini bloke etmez", () => {
    expect(gorselHakKaydiniRaporla("https://uretici.example/5.jpg"))
      .toEqual({ hakKayitDurumu: "kayit_yok", hakIncelemeGerekiyor: true });
  });
});

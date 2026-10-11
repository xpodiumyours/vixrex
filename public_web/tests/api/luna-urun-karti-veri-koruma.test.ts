import { describe, expect, it } from "vitest";
import { satirAramaCevabi } from "@/lib/faturaGoru";
import { eslesmeyenSatir, siteAdayiniKoru, siteKartiniUygula } from "@/lib/faturaEslestir";

describe("Luna kaynak verisi ürün kartına kayıpsız aktarım", () => {
  it("kategori, özellikler, varyantlar ve tüm resmî görselleri aday taslağa taşır", () => {
    const girdi = { alan: "uretici.example", model: "M100", ad: "Ürün", barkod: "" };
    const cevap = satirAramaCevabi(girdi, {
      status: "completed",
      output_text: JSON.stringify({
        eslesti: true, urun_adi: "Üretici Ürünü", aciklama: "Resmî açıklama",
        kaynak_sayfa: "https://uretici.example/urun",
        gorsel_adresi: "https://cdn.example/1.jpg",
        gorsel_adresleri: ["https://cdn.example/1.jpg", "https://cdn.example/2.jpg"],
        kategori: "İç Giyim",
        ozellikler: [{ key: "material", label: "Malzeme", value: "Pamuk" }],
        urun_varyantlari: [{
          id: "M100-S", secenekler: [{ key: "size", value: "S" }],
          barkod: "", gorseller: ["https://cdn.example/2.jpg"],
        }],
        kanit: "Resmî ürün sayfası", eslesme_dayanagi: "kod",
        site_kodu: "M100", site_barkodu: "", site_markasi: "",
        site_rengi: "", site_bedeni: "", fotograf_rengi_dogrulandi: false,
      }),
    });
    expect(cevap?.gorseller).toEqual(["https://cdn.example/1.jpg", "https://cdn.example/2.jpg"]);
    expect(cevap?.kategori).toBe("İç Giyim");
    expect(cevap?.ozellikler).toEqual([{ key: "material", label: "Malzeme", value: "Pamuk" }]);

    const satir = siteAdayiniKoru(siteKartiniUygula(eslesmeyenSatir({
      model: "M100", ad: "Ürün", barkod: "", varyant: "", beden: "",
      adet: 2, alisBirimFiyat: 40, satirToplam: 80, guven: 1,
      siteAd: cevap?.ad, siteDayanak: cevap?.dayanak ?? undefined,
      siteAciklama: cevap?.aciklama, siteGorsel: cevap?.gorsel,
      siteGorseller: cevap?.gorseller, siteKategori: cevap?.kategori,
      siteOzellikler: cevap?.ozellikler,
      siteUrunVaryantlari: cevap?.urunVaryantlari, siteSayfa: cevap?.sayfa,
    })));
    expect(satir.katalog?.gorseller).toHaveLength(2);
    expect(satir.katalog?.kategori).toBe("İç Giyim");
    expect(satir.katalog?.ozellikler?.[0]?.value).toBe("Pamuk");
    expect(satir.katalog?.urunVaryantlari?.[0]?.secenekler[0]?.value).toBe("S");
    expect(satir.sonuc).toBe("eksik");
  });
});

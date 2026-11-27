import { describe, expect, it, vi } from "vitest";
import sharp from "sharp";
import { faturaIstekGovdesi, faturaYanitiniOku, type GoruSatiri } from "@/lib/faturaGoru";
import { kaynakGorseliniDogrula, logoVeyaTemaGorseliMi } from "@/lib/faturaGorsel";
import { FATURA_JSON_ISTEGI } from "@/lib/faturaPresetSozlesmesi";
import {
  gorselAdaylariniSuz,
  kural32MetinTemizle,
  kural32NesneTemizle,
  resmiAlanAdiUygunMu,
} from "@/lib/faturaUrunHazirlama";
import { faturaSatiriniAktar } from "@/lib/faturaPresetAktarimi";
import { kartDegerlendir } from "@/lib/faturaKartDurumu";
import {
  DOGRULANMIS_HAK_DURUMLARI,
  gorselHakKaydiniRaporla,
  gorselHakKayitlariniDerle,
  gorselIzinBekliyorMu,
} from "@/lib/faturaGorselHakDenetimi";
import { belgeParmakIzi } from "@/lib/faturaIslemKaydi";
import { kartPresetIstekGovdesi } from "@/lib/faturaKartPreset";

describe("Aşama 1 — Fatura Altın Koruma Paketi", () => {
  it("Kilit 1: faturaYanitiniOku model, barkod, adet, birimFiyat, tutar ve tedarikciSite alanlarını korur; model kodu sözleşmede zorunludur", async () => {
    const yanit = new Response(
      JSON.stringify({
        choices: [
          {
            finish_reason: "stop",
            message: {
              content: JSON.stringify({
                tedarikci: "Güler Bebe Tekstil",
                tedarikci_site: "www.gulerbebe.com",
                satirlar: [
                  {
                    satir_no: 1,
                    ham_satir: "GB-1042 Yenidoğan Hastane Çıkışı 5 ADET 240,00 1.200,00",
                    model: "GB-1042",
                    ad: "Yenidoğan Hastane Çıkışı",
                    barkod: "8691234567890",
                    marka: "Güler Bebe",
                    adet: 5,
                    birim: "adet",
                    birim_fiyat: 240,
                    tutar: 1200,
                    okuma_guveni: 0.96,
                  },
                ],
              }),
            },
          },
        ],
      }),
      { status: 200, headers: { "content-type": "application/json" } },
    );

    const sonuc = await faturaYanitiniOku(yanit);
    expect(sonuc.tedarikciSite).toBe("www.gulerbebe.com");
    expect(sonuc.satirlar).toHaveLength(1);
    expect(sonuc.satirlar[0]).toMatchObject({
      model: "GB-1042",
      barkod: "8691234567890",
      adet: 5,
      birimFiyat: 240,
      tutar: 1200,
    });
    expect(FATURA_JSON_ISTEGI).toContain("Model Kodu");
    expect(FATURA_JSON_ISTEGI).toContain("Stok Kodu");
    expect(FATURA_JSON_ISTEGI).toContain("model alanına aynen yaz");
  });

  it("Kilit 2: pazaryeri ve aracı URL'leri reddedilir, onaylı e-ticaret CDN adresleri kabul edilir", () => {
    const yasakliUrller = [
      "https://www.trendyol.com/marka/urun-p-123",
      "https://cdn.dsmcdn.com/mnresize/1200/1800/urun.jpg",
      "https://www.hepsiburada.com/urun-p-HBV00001",
      "https://productimages.hepsiburada.net/s/100/500/1.jpg",
      "https://www.n11.com/urun/test-urun-1",
      "https://www.amazon.com.tr/dp/B00TEST123",
      "https://www.instagram.com/p/test123/",
    ];
    const onayliCdnUrlleri = [
      "https://gulerbebe.sercdn.com/products/gb-1042.jpg",
      "https://static.ticimax.cloud/550/uploads/urun.jpg",
      "https://cdn.akinoncdn.com/products/2026/01/urun.webp",
    ];

    for (const url of yasakliUrller) {
      expect(resmiAlanAdiUygunMu(url, "gulerbebe.com", { gorsel: true })).toBe(false);
    }
    for (const url of onayliCdnUrlleri) {
      expect(resmiAlanAdiUygunMu(url, "gulerbebe.com", { gorsel: true })).toBe(true);
    }

    const suzulen = gorselAdaylariniSuz({
      adaylar: [...yasakliUrller, ...onayliCdnUrlleri],
      tespitEdilenAlan: "gulerbebe.com",
    });
    expect(suzulen).toEqual(onayliCdnUrlleri);
  });

  it("Kilit 3: web sitesi, barkodu ve görseli olmayan yerel ürün sahte URL/görsel üretmez", () => {
    const yerelSatir = {
      satirNo: 1,
      hamSatir: "EL YAPIMI BEBEK PATİĞİ 3 ADET 75",
      model: "PATIK-01",
      ad: "El Yapımı Bebek Patiği",
      barkod: "",
      varyant: "Ekru",
      beden: "0-3 Ay",
      marka: "Yerel Atölye",
      adet: 3,
      birim: "adet",
      birimFiyat: 75,
      tutar: 225,
      okumaGuveni: 0.9,
      siteSayfa: "",
      siteGorsel: "",
      siteGorseller: [],
      siteAciklama: "",
      siteKategori: "",
      dogrulamaDurumu: "✗ Bulunamadı",
      eksikler: ["Resmî üretici sitesi yok"],
    } as unknown as GoruSatiri;

    const aktarilan = faturaSatiriniAktar(yerelSatir, "Yerel Toptancı");
    expect(aktarilan.sonuc).toBe("iz-yok");
    expect(aktarilan.siteSayfa).toBe("");
    expect(aktarilan.siteGorsel).toBe("");
    expect(aktarilan.siteGorseller).toEqual([]);
    expect(aktarilan.katalog?.kaynak).toBe("");
    expect(aktarilan.katalog?.izinDurumu).toBe("yok");
    expect(aktarilan.katalog?.gorseller).toEqual([]);

    const degerlendirme = kartDegerlendir({ satir: aktarilan });
    expect(degerlendirme.durum).toBe("iz-yok");
    expect(degerlendirme.gorseller).toEqual([]);
    expect(degerlendirme.yayinaHazir).toBe(false);
  });

  it("Kilit 4: kural32NesneTemizle 4 sutunlu ticari sirlari siler, alis fiyatini kar marji verisi olarak korur ve telif kalkani fail-closed kalir", () => {
    const temiz = kural32NesneTemizle({
      name: "Bebek Zıbın",
      vkn: "1234567890",
      tckn: "12345678901",
      ettn: "11111111-2222-3333-4444-555555555555",
      iban: "TR330006100519786457841326",
      alisFiyati: 120,
      unit_price: 120,
      purchase_price: 120,
      iskonto: 15,
      discount: 15,
      nested: { faturaNo: "FTR2026001", model: "GB-1042" },
      attributes: [
        { key: "vkn", value: "1234567890" },
        { key: "fabric", label: "Kumaş", value: "%100 Pamuk" },
      ],
    });

    expect(temiz.name).toBe("Bebek Zıbın");
    expect(temiz).not.toHaveProperty("vkn");
    expect(temiz).not.toHaveProperty("tckn");
    expect(temiz).not.toHaveProperty("ettn");
    expect(temiz).not.toHaveProperty("iban");
    expect(temiz.alisFiyati).toBe(120);
    expect(temiz.unit_price).toBe(120);
    expect(temiz.purchase_price).toBe(120);
    expect(temiz).not.toHaveProperty("iskonto");
    expect(temiz).not.toHaveProperty("discount");
    expect(temiz.nested).toEqual({ model: "GB-1042" });
    expect(temiz.attributes).toEqual([{ key: "fabric", label: "Kumaş", value: "%100 Pamuk" }]);
    expect(kural32MetinTemizle("Bebek Zıbın VKN 1234567890 Alış fiyatı 120 TL")).toBe(
      "Bebek Zıbın VKN Alış fiyatı 120 TL",
    );

    const durumHaritasi = gorselHakKayitlariniDerle([
      { image_url: "https://cdn.example.com/unknown.jpg", usage_status: "unknown" },
      { image_url: "https://cdn.example.com/denied.jpg", usage_status: "verified_supplier_permission" },
      { image_url: "https://cdn.example.com/denied.jpg", usage_status: "denied" },
      { image_url: "https://cdn.example.com/izinli-supplier.jpg", usage_status: "verified_supplier_permission" },
      { image_url: "https://cdn.example.com/izinli-feed.jpg", usage_status: "verified_feed_terms" },
      { image_url: "https://cdn.example.com/izinli-merchant.jpg", usage_status: "merchant_owned_media" },
    ]);

    expect(gorselHakKaydiniRaporla("https://cdn.example.com/unknown.jpg", durumHaritasi)).toEqual({
      hakKayitDurumu: "unknown",
      hakIncelemeGerekiyor: true,
    });
    expect(gorselHakKaydiniRaporla("https://cdn.example.com/denied.jpg", durumHaritasi)).toEqual({
      hakKayitDurumu: "denied",
      hakIncelemeGerekiyor: true,
    });
    expect(gorselHakKaydiniRaporla("https://cdn.example.com/eksik.jpg", durumHaritasi)).toEqual({
      hakKayitDurumu: "kayit_yok",
      hakIncelemeGerekiyor: true,
    });

    for (const url of [
      "https://cdn.example.com/izinli-supplier.jpg",
      "https://cdn.example.com/izinli-feed.jpg",
      "https://cdn.example.com/izinli-merchant.jpg",
    ]) {
      const rapor = gorselHakKaydiniRaporla(url, durumHaritasi);
      expect(DOGRULANMIS_HAK_DURUMLARI).toContain(rapor.hakKayitDurumu);
      expect(rapor.hakIncelemeGerekiyor).toBe(false);
    }

    expect(
      gorselIzinBekliyorMu({
        gorselKaynaklari: [{ hakKayitDurumu: "unknown" }],
      }),
    ).toBe(true);
    expect(
      gorselIzinBekliyorMu({
        gorselKaynaklari: [{ hakKayitDurumu: "denied" }],
      }),
    ).toBe(true);
    expect(
      gorselIzinBekliyorMu({
        gorselKaynaklari: [{ hakKayitDurumu: "kayit_yok" }],
      }),
    ).toBe(true);
    expect(
      gorselIzinBekliyorMu({
        gorselKaynaklari: [
          { hakKayitDurumu: "verified_supplier_permission" },
          { hakKayitDurumu: "verified_feed_terms" },
          { hakKayitDurumu: "merchant_owned_media" },
        ],
      }),
    ).toBe(false);
  });

  it("Kilit 5: belgeParmakIzi deterministiktir ve kartPresetIstekGovdesi 20 satırı eksiksiz ve tam tool limitleriyle taşır", () => {
    const baytA = new TextEncoder().encode("fatura-belge-a");
    const baytB = new TextEncoder().encode("fatura-belge-b");
    const hashA1 = belgeParmakIzi(baytA);
    const hashA2 = belgeParmakIzi(baytA);
    const hashB = belgeParmakIzi(baytB);

    expect(hashA1).toMatch(/^[0-9a-f]{64}$/);
    expect(hashA1).toBe(hashA2);
    expect(hashA1).not.toBe(hashB);

    const markalar = ["Güler Bebe", "Tutku", "Mavi", "Koton"];
    const satirlar = Array.from({ length: 20 }, (_, i) => ({
      satirNo: i + 1,
      hamSatir: `MDL-${i + 1} Ürün ${i + 1}`,
      model: `MDL-${i + 1}`,
      ad: `Ürün ${i + 1}`,
      barkod: "",
      varyant: "Standart",
      beden: "M",
      gramaj: "",
      marka: markalar[i % markalar.length],
      adet: i + 1,
      birim: "adet",
      birimFiyat: 50,
      tutar: (i + 1) * 50,
      okumaGuveni: 0.95,
    }));

    const govde = kartPresetIstekGovdesi(
      {
        tedarikci: "Çok Markalı Toptancı",
        tedarikciSite: "www.toptanci.example",
        satirlar,
      } as Parameters<typeof kartPresetIstekGovdesi>[0],
      "yeni",
    );

    const tools = govde.tools as Array<{
      type: string;
      parameters: { max_results?: number; max_uses?: number; max_total_results?: number };
    }>;
    const webSearch = tools.find((t) => t.type === "openrouter:web_search");
    const webFetch = tools.find((t) => t.type === "openrouter:web_fetch");
    expect(webSearch?.parameters.max_results).toBeGreaterThanOrEqual(8);
    expect(webSearch?.parameters.max_uses).toBeGreaterThanOrEqual(35);
    expect(webFetch?.parameters.max_uses).toBeGreaterThanOrEqual(35);
    expect(govde.response_format).toMatchObject({
      type: "json_schema",
      json_schema: { strict: true },
    });
    expect(govde.provider).toEqual({ require_parameters: true });
    expect(govde.reasoning).toEqual({ effort: "low" });
    expect(faturaIstekGovdesi("data:image/png;base64,TEST").reasoning).toEqual({ effort: "low" });

    const content = (govde.messages as Array<{ content: string }>)[0].content;
    const payload = JSON.parse(content.slice(content.lastIndexOf("\n") + 1)) as {
      groups: Array<{ brand: string; rows: Array<{ row_id: string }> }>;
    };
    const rowIds = payload.groups
      .flatMap((g) => g.rows.map((r) => r.row_id))
      .sort((a, b) => Number(a) - Number(b));
    expect(rowIds).toEqual(Array.from({ length: 20 }, (_, i) => String(i + 1)));
  });

  it("Kilit 6: logo/tema/favicon/SVG/banner URL'leri reddedilir, urun fotograflari yanlis pozitif olmadan korunur", () => {
    const reddedilecekler = [
      "https://www.berrak.com.tr/theme-images/logo.png",
      "https://www.berrak.com.tr/theme_images/site-logo-dark.png",
      "https://www.berrak.com.tr/assets/berrak-logo.png",
      "https://www.berrak.com.tr/assets/header_logo_200x60.webp",
      "https://www.berrak.com.tr/favicon.ico",
      "https://www.berrak.com.tr/icons/cart.png",
      "https://www.berrak.com.tr/banners/kampanya.jpg",
      "https://www.berrak.com.tr/img/no-image.jpg",
      "https://www.berrak.com.tr/img/marka-vector.svg",
    ];
    const korunacaklar = [
      "https://www.mavi.com/products/mavi-logo-baskili-tisort-065123.jpg",
      "https://brandname.com/products/atlet-1001.jpg",
    ];

    for (const url of reddedilecekler) {
      expect(logoVeyaTemaGorseliMi(url)).toBe(true);
    }
    for (const url of korunacaklar) {
      expect(logoVeyaTemaGorseliMi(url)).toBe(false);
    }

    const suzulenMavi = gorselAdaylariniSuz({
      adaylar: [
        "https://www.mavi.com/theme-images/site-logo.png",
        "https://www.mavi.com/products/mavi-logo-baskili-tisort-065123.jpg",
      ],
      seciliGorsel: "https://www.mavi.com/assets/mavi-logo.svg",
      tespitEdilenAlan: "mavi.com",
    });
    expect(suzulenMavi).toEqual(["https://www.mavi.com/products/mavi-logo-baskili-tisort-065123.jpg"]);

    const suzulenBrand = gorselAdaylariniSuz({
      adaylar: ["https://brandname.com/products/atlet-1001.jpg"],
      tespitEdilenAlan: "brandname.com",
    });
    expect(suzulenBrand).toEqual(["https://brandname.com/products/atlet-1001.jpg"]);
  });

  it("Kilit 7: kaynakGorseliniDogrula 500x100 banner PNG, gecerli SVG ve tema logo URL'ini reddeder; 600x800 urun PNG'sini kabul eder", async () => {
    const bannerPng = await sharp({
      create: { width: 500, height: 100, channels: 3, background: { r: 220, g: 40, b: 40 } },
    })
      .png()
      .toBuffer();
    const urunPng = await sharp({
      create: { width: 600, height: 800, channels: 3, background: { r: 40, g: 120, b: 220 } },
    })
      .png()
      .toBuffer();
    const svgBayt = Buffer.from(
      '<svg xmlns="http://www.w3.org/2000/svg" width="400" height="400"><rect width="400" height="400" fill="#111"/></svg>',
      "utf8",
    );

    const pngYanit = (buf: Buffer, contentType: string) =>
      new Response(new Uint8Array(buf), {
        status: 200,
        headers: { "content-type": contentType, "content-length": String(buf.byteLength) },
      });

    const bannerSonuc = await kaynakGorseliniDogrula("https://www.ornek.com/products/serit.png", {
      fetcher: vi.fn(async () => pngYanit(bannerPng, "image/png")),
    });
    expect(bannerSonuc).toEqual({ tamam: false, sebep: "logo-veya-yer-tutucu" });

    const svgSonuc = await kaynakGorseliniDogrula("https://www.ornek.com/products/vektor-gorsel", {
      fetcher: vi.fn(async () => pngYanit(svgBayt, "image/svg+xml")),
    });
    expect(svgSonuc).toEqual({ tamam: false, sebep: "logo-veya-yer-tutucu" });

    const urunSonuc = await kaynakGorseliniDogrula("https://www.ornek.com/products/atlet-600x800.png", {
      fetcher: vi.fn(async () => pngYanit(urunPng, "image/png")),
    });
    expect(urunSonuc.tamam).toBe(true);
    expect(urunSonuc.genislik).toBe(600);
    expect(urunSonuc.yukseklik).toBe(800);

    const cagrilmamaliFetcher = vi.fn();
    const temaLogoSonuc = await kaynakGorseliniDogrula("https://www.ornek.com/theme-images/logo.png", {
      fetcher: cagrilmamaliFetcher,
    });
    expect(cagrilmamaliFetcher).not.toHaveBeenCalled();
    expect(temaLogoSonuc).toEqual({ tamam: false, sebep: "logo-veya-yer-tutucu" });
  });
});

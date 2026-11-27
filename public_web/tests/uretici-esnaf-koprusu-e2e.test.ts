import { describe, expect, it } from "vitest";
import {
  kural32MetinTemizle,
  kural32NesneTemizle,
  faturaRenginiCoz,
  resmiAlanAdiUygunMu,
} from "@/lib/faturaUrunHazirlama";
import { logoVeyaTemaGorseliMi } from "@/lib/faturaGorsel";
import { kartDegerlendir } from "@/lib/faturaKartDurumu";
import { gorselIzinBekliyorMu } from "@/lib/faturaGorselHakDenetimi";
import { normalizeSupplierPermissionPayload } from "@/lib/supplierPermissionRequest";
import {
  faturaVitrinTaslagiCikar,
  mevcutVitriniEzmedenBirlestir,
} from "@/lib/faturaVitrinTaslagi";
import { resmiMarkaRaflariniDerle } from "@/lib/resmiMarkaRafi";
import {
  b2bStokYenileMesajiOlustur,
  b2bStokYenileWhatsappUrl,
} from "@/lib/b2bWhatsappSiparis";
import type { EslesmisFaturaSatiri } from "@/lib/faturaEslestir";
import type { RichProductItem } from "@/lib/richProductItem";

const SENTETIK_SIRLAR = {
  vkn: "9876543210",
  tckn: "12345678901",
  iban: "TR120006200000000012345678",
  ettn: "a1b2c3d4-e5f6-4789-abcd-1234567890ab",
  faturaNo: "ANL2026000001234",
  iskonto: "%15 özel iskonto",
  vade: "60 gün vade",
  alisFiyat1: "420.50",
  alisFiyat2: "310.00",
  alisFiyat3: "585.00",
  acikAdresSokak: "Atatürk Mah. Alemdağ Cad. No:142 Daire:7",
};

const SENTETIK_URUNLER: EslesmisFaturaSatiri[] = [
  {
    hamSatir: "ANL-101 Keten Gömlek SYH M 10 AD 420.50",
    model: "ANL-101",
    ad: "AnadoluLine Keten Gömlek",
    barkod: "8690001001011",
    varyant: "SYH",
    beden: "M",
    marka: "AnadoluLine",
    adet: 10,
    alisBirimFiyat: 420.5,
    satirToplam: 4205,
    guven: 0.96,
    sonuc: "kanitli",
    katalog: {
      firma: "Anadolu Tekstil A.Ş.",
      kaynakFirma: "anadoluline.com.tr",
      dayanak: "kod",
      izinDurumu: "bekliyor",
      resmiAd: "AnadoluLine Keten Gömlek Siyah",
      marka: "AnadoluLine",
      aciklama: "Doğal keten dokuma erkek gömlek.",
      gorseller: ["https://anadoluline.com.tr/cdn/products/anl-101-siyah.jpg"],
      gorselAdaylari: ["https://anadoluline.com.tr/cdn/products/anl-101-siyah.jpg"],
      kategori: "Giyim & Tekstil",
      kaynak: "https://anadoluline.com.tr/urun/anl-101",
    },
  },
  {
    hamSatir: "ANL-102 Pamuk Pantolon LCV L 8 AD 310.00",
    model: "ANL-102",
    ad: "AnadoluLine Pamuk Pantolon",
    barkod: "8690001001028",
    varyant: "LCV",
    beden: "L",
    marka: "AnadoluLine",
    adet: 8,
    alisBirimFiyat: 310,
    satirToplam: 2480,
    guven: 0.95,
    sonuc: "kanitli",
    katalog: {
      firma: "Anadolu Tekstil A.Ş.",
      kaynakFirma: "anadoluline.com.tr",
      dayanak: "barkod",
      izinDurumu: "bekliyor",
      resmiAd: "AnadoluLine Pamuk Pantolon Lacivert",
      marka: "AnadoluLine",
      aciklama: "Nefes alan pamuk kumaş klasik pantolon.",
      gorseller: ["https://anadoluline.com.tr/cdn/products/anl-102-lacivert.jpg"],
      gorselAdaylari: ["https://anadoluline.com.tr/cdn/products/anl-102-lacivert.jpg"],
      kategori: "Giyim & Tekstil",
      kaynak: "https://anadoluline.com.tr/urun/anl-102",
    },
  },
  {
    hamSatir: "ANL-103 Triko Kazak BYZ S 6 AD 585.00",
    model: "ANL-103",
    ad: "AnadoluLine Triko Kazak",
    barkod: "8690001001035",
    varyant: "BYZ",
    beden: "S",
    marka: "AnadoluLine",
    adet: 6,
    alisBirimFiyat: 585,
    satirToplam: 3510,
    guven: 0.94,
    sonuc: "kanitli",
    katalog: {
      firma: "Anadolu Tekstil A.Ş.",
      kaynakFirma: "anadoluline.com.tr",
      dayanak: "kod",
      izinDurumu: "bekliyor",
      resmiAd: "AnadoluLine Triko Kazak Beyaz",
      marka: "AnadoluLine",
      aciklama: "Yumuşak dokulu mevsimlik triko kazak.",
      gorseller: ["https://anadoluline.com.tr/cdn/products/anl-103-beyaz.jpg"],
      gorselAdaylari: ["https://anadoluline.com.tr/cdn/products/anl-103-beyaz.jpg"],
      kategori: "Giyim & Tekstil",
      kaynak: "https://anadoluline.com.tr/urun/anl-103",
    },
  },
];

describe("Üretici-Esnaf Köprüsü Sentetik Fatura 4 Adımlı E2E Kilidi", () => {
  it("Adım 1: Kural 32 gizlilik maskelemesi ve fatura renk açılımı eksiksiz çalışır", () => {
    const kirliMetin = [
      "AnadoluLine Keten Gömlek",
      `VKN ${SENTETIK_SIRLAR.vkn}`,
      `TCKN ${SENTETIK_SIRLAR.tckn}`,
      SENTETIK_SIRLAR.iban,
      SENTETIK_SIRLAR.ettn,
      SENTETIK_SIRLAR.iskonto,
      SENTETIK_SIRLAR.vade,
    ].join(" ");
    const temizMetin = kural32MetinTemizle(kirliMetin);

    expect(temizMetin).toContain("AnadoluLine Keten Gömlek");
    expect(temizMetin).not.toContain(SENTETIK_SIRLAR.vkn);
    expect(temizMetin).not.toContain(SENTETIK_SIRLAR.tckn);
    expect(temizMetin).not.toContain(SENTETIK_SIRLAR.iban);
    expect(temizMetin).not.toContain(SENTETIK_SIRLAR.ettn);
    expect(temizMetin).not.toMatch(/iskonto/i);
    expect(temizMetin).not.toMatch(/vade/i);

    const temizNesne = kural32NesneTemizle({
      ad: "AnadoluLine Keten Gömlek",
      vkn: SENTETIK_SIRLAR.vkn,
      tckn: SENTETIK_SIRLAR.tckn,
      iban: SENTETIK_SIRLAR.iban,
      ettn: SENTETIK_SIRLAR.ettn,
      fatura_no: SENTETIK_SIRLAR.faturaNo,
      iskonto: 15,
      vade: "60 gün",
      supplier_name: "Anadolu Tekstil A.Ş.",
      attributes: [
        { key: "kumas", label: "Kumaş", value: "%100 Keten" },
        { key: "vkn", label: "VKN", value: SENTETIK_SIRLAR.vkn },
      ],
    });

    expect(temizNesne).toEqual({
      ad: "AnadoluLine Keten Gömlek",
      attributes: [{ key: "kumas", label: "Kumaş", value: "%100 Keten" }],
    });
    expect(faturaRenginiCoz("SYH")).toBe("Siyah");
    expect(faturaRenginiCoz("LCV")).toBe("Lacivert");
    expect(faturaRenginiCoz("BYZ")).toBe("Beyaz");
  });

  it("Adım 2: Logo/banner görselleri reddedilir ve resmi alan adı kilidi çalışır", () => {
    expect(logoVeyaTemaGorseliMi("https://anadoluline.com.tr/assets/logo/site-logo.png")).toBe(true);
    expect(logoVeyaTemaGorseliMi("https://anadoluline.com.tr/banners/sezon-banner.jpg")).toBe(true);
    expect(logoVeyaTemaGorseliMi("https://anadoluline.com.tr/favicon.ico")).toBe(true);
    expect(logoVeyaTemaGorseliMi("https://anadoluline.com.tr/cdn/products/anl-101-siyah.jpg")).toBe(false);

    expect(
      resmiAlanAdiUygunMu("https://anadoluline.com.tr/urun/anl-101", "anadoluline.com.tr"),
    ).toBe(true);
    expect(
      resmiAlanAdiUygunMu("https://www.trendyol.com/anadoluline/keten-gomlek-p-123", "anadoluline.com.tr"),
    ).toBe(false);
    expect(
      resmiAlanAdiUygunMu("https://vertexaisearch.cloud.google.com/grounding-api-redirect/xyz", "anadoluline.com.tr"),
    ).toBe(false);
  });

  it("Adım 3: Satış fiyatı girilmeden kart yayına hazır olmaz; alış fiyatı kâr marjı korunur", () => {
    const fiyatEksik = kartDegerlendir({
      satir: SENTETIK_URUNLER[0],
      satisFiyati: null,
      stok: 10,
      stokOnaylandi: true,
      onaylandi: true,
    });
    expect(fiyatEksik.yayinaHazir).toBe(false);
    expect(fiyatEksik.onaylanabilir).toBe(false);

    const fiyatliHazir = kartDegerlendir({
      satir: SENTETIK_URUNLER[0],
      satisFiyati: 899,
      stok: 10,
      stokOnaylandi: true,
      onaylandi: true,
    });
    expect(fiyatliHazir.yayinaHazir).toBe(true);
    expect(JSON.stringify(fiyatliHazir)).not.toContain(SENTETIK_SIRLAR.alisFiyat1);
  });

  it("Adım 4: Vitrin taslağı, marka rafı ve üretici izin çıktısında 4 sütun sırrı 0 kez geçer ve hak kaydı yokken telif kalkanı aktif kalır", () => {
    const vitrinTaslagi = faturaVitrinTaslagiCikar({
      aliciUnvan: `Yıldız Butik VKN ${SENTETIK_SIRLAR.vkn} ${SENTETIK_SIRLAR.ettn} ${SENTETIK_SIRLAR.faturaNo}`,
      aliciAdres: `${SENTETIK_SIRLAR.acikAdresSokak} Ümraniye / İstanbul`,
      urunKategorileri: ["Giyim & Tekstil"],
      markalar: ["AnadoluLine"],
    });

    const vitrinUrunleri: RichProductItem[] = SENTETIK_URUNLER.map((satir, idx) => ({
      id: `urun-${idx + 1}`,
      slug: `anadoluline-${idx + 1}`,
      name: satir.katalog!.resmiAd,
      brand: satir.katalog!.marka,
      priceAmount: 899 + idx * 100,
      isVisible: true,
      source: "invoice",
      metadata: {
        lunaInvoice: true,
        manufacturerSource: {
          url: satir.katalog!.kaynak,
          verificationStatus: "doğrulandı",
        },
      },
    }));

    const raflar = resmiMarkaRaflariniDerle(vitrinUrunleri);
    expect(raflar).toHaveLength(1);
    expect(raflar[0].marka).toBe("AnadoluLine");
    expect(raflar[0].resmiAlanAdi).toBe("anadoluline.com.tr");
    expect(raflar[0].urunSayisi).toBe(3);

    const izinCiktisi = normalizeSupplierPermissionPayload({
      store_name: `Yıldız Butik ${SENTETIK_SIRLAR.iban} ${SENTETIK_SIRLAR.vkn} alış fiyatı ${SENTETIK_SIRLAR.alisFiyat1}`,
      store_slug: "yildiz-butik",
      brand: `AnadoluLine ${SENTETIK_SIRLAR.iskonto} ${SENTETIK_SIRLAR.vade}`,
      status: "bekliyor",
      created_at: "2026-11-27T10:00:00Z",
      expires_at: "2026-12-04T10:00:00Z",
      product_count: 3,
      line_count: 3,
      products: vitrinUrunleri.map((u, i) => ({
        id: u.id,
        name: `${u.name} toptan ${SENTETIK_SIRLAR.alisFiyat1}`,
        slug: u.slug,
        brand: u.brand,
        model: `ANL-10${i + 1}`,
        image_urls: [SENTETIK_URUNLER[i].katalog!.gorseller[0]],
        permission_status: "bekliyor",
      })),
    });

    expect(izinCiktisi).not.toBeNull();

    const tumDisCikti = JSON.stringify({ vitrinTaslagi, raflar, izinCiktisi });
    for (const sir of [
      SENTETIK_SIRLAR.vkn,
      SENTETIK_SIRLAR.tckn,
      SENTETIK_SIRLAR.iban,
      SENTETIK_SIRLAR.ettn,
      SENTETIK_SIRLAR.faturaNo,
      SENTETIK_SIRLAR.alisFiyat1,
      SENTETIK_SIRLAR.alisFiyat2,
      SENTETIK_SIRLAR.alisFiyat3,
      "Alemdağ",
      "Daire:7",
      "iskonto",
      "vade",
    ]) {
      expect(tumDisCikti.toLocaleLowerCase("tr-TR")).not.toContain(sir.toLocaleLowerCase("tr-TR"));
    }

    expect(
      gorselIzinBekliyorMu({
        gorselKaynaklari: [
          {
            kaynakGorsel: SENTETIK_URUNLER[0].katalog!.gorseller[0],
            hakKayitDurumu: "kayit_yok",
          },
        ],
      }),
    ).toBe(true);
  });
});

describe("faturaVitrinTaslagi pozitif ve negatif durumlar", () => {
  it("sokak ve bina adresini sızdırmadan yalnız doğrulanmış il ve ilçeyi çıkarır", () => {
    const taslak = faturaVitrinTaslagiCikar({
      aliciUnvan: "Yıldız Butik Ltd. Şti. 0532 111 22 33 info@yildizbutik.com",
      aliciAdres: "Atatürk Mah. Alemdağ Cad. No:142 Kat:3 Ümraniye / İstanbul",
      urunKategorileri: ["Giyim"],
      markalar: ["AnadoluLine"],
    });

    expect(taslak).toEqual({
      name: "Yıldız Butik Ltd. Şti",
      province_name: "İstanbul",
      district_name: "Ümraniye",
      kategori: "giyim",
      ilkMarka: "AnadoluLine",
      kaynak: "fatura",
    });
    expect(JSON.stringify(taslak)).not.toContain("Alemdağ");
    expect(JSON.stringify(taslak)).not.toContain("0532");
    expect(JSON.stringify(taslak)).not.toContain("info@yildizbutik.com");
  });

  it("mevcut dolu vitrinin hiçbir alanını ve kişisel iletişim alanlarını ezmez", () => {
    const mevcut = {
      name: "Mevcut Mağaza",
      province_name: "Ankara",
      district_name: "",
      kategori: "",
      address: "Eski Adres",
      whatsapp: "905301112233",
      phone: "02123334455",
      email: "sahip@ornek.com",
      products: [{ id: "1" }],
      latitude: 39.9,
      longitude: 32.8,
    };
    const taslak = faturaVitrinTaslagiCikar({
      aliciUnvan: "Fatura Alıcısı",
      aliciAdres: "Ümraniye İstanbul",
      urunKategorileri: ["Giyim"],
    });

    const birlesik = mevcutVitriniEzmedenBirlestir(mevcut, taslak);
    expect(birlesik.name).toBe("Mevcut Mağaza");
    expect(birlesik.province_name).toBe("Ankara");
    expect(birlesik.district_name).toBe("");
    expect(birlesik.kategori).toBe("giyim");
    expect(birlesik.address).toBe("Eski Adres");
    expect(birlesik.whatsapp).toBe("905301112233");
    expect(birlesik.phone).toBe("02123334455");
    expect(birlesik.email).toBe("sahip@ornek.com");
    expect(birlesik.products).toEqual([{ id: "1" }]);
    expect(birlesik.latitude).toBe(39.9);
    expect(birlesik.longitude).toBe(32.8);
  });

  it("belirsiz ilçede district_name üretmez ve kirli/boş girdide null döner", () => {
    const belirsiz = faturaVitrinTaslagiCikar({
      aliciUnvan: "Kemer Mağazası",
      aliciAdres: "Kemer",
    });
    expect(belirsiz?.district_name).toBeUndefined();
    expect(belirsiz?.province_name).toBeUndefined();

    expect(faturaVitrinTaslagiCikar(null)).toBeNull();
    expect(
      faturaVitrinTaslagiCikar({
        aliciUnvan: "TR120006200000000012345678 9876543210",
        aliciAdres: "Bilinmeyen Sokak No:5",
        urunKategorileri: ["bilinmeyen_xyz_999"],
        markalar: ["a"],
      }),
    ).toBeNull();
  });
});

describe("resmiMarkaRafi pozitif ve negatif durumlar", () => {
  it("doğrulanmış markaları gruplar, ürün sayısına göre sıralar ve IBAN/VKN temizler", () => {
    const urunler: RichProductItem[] = [
      {
        id: "1",
        name: "Keten Gömlek",
        brand: "AnadoluLine TR120006200000000012345678 9876543210",
        isVisible: true,
        source: "invoice",
        metadata: {
          lunaInvoice: true,
          manufacturerSource: { url: "https://anadoluline.com.tr/urun/1", verificationStatus: "doğrulandı" },
        },
      },
      {
        id: "2",
        name: "Pamuk Pantolon",
        brand: "AnadoluLine",
        isVisible: true,
        source: "invoice",
        metadata: {
          lunaInvoice: true,
          manufacturerSource: { url: "https://anadoluline.com.tr/urun/2", verificationStatus: "verified" },
        },
      },
      {
        id: "3",
        name: "Seramik Kupa",
        brand: "BursaPorselen",
        isVisible: true,
        metadata: {
          manufacturerSource: { url: "https://bursaporselen.com.tr/kupa", verificationStatus: "onaylandi" },
        },
      },
    ];

    const raflar = resmiMarkaRaflariniDerle(urunler);
    expect(raflar).toHaveLength(2);
    expect(raflar[0].marka).toBe("AnadoluLine");
    expect(raflar[0].urunSayisi).toBe(2);
    expect(raflar[0].resmiAlanAdi).toBe("anadoluline.com.tr");
    expect(raflar[1].marka).toBe("BursaPorselen");
    expect(raflar[1].urunSayisi).toBe(1);
  });

  it("pazaryeri, javascript, http, boş marka, gizli ürün ve boş listeyi fail-closed reddeder", () => {
    const gecersizler: RichProductItem[] = [
      {
        id: "p1",
        name: "Pazaryeri Ürünü",
        brand: "MarkaA",
        isVisible: true,
        source: "invoice",
        metadata: { manufacturerSource: { url: "https://www.trendyol.com/urun/1", verificationStatus: "verified" } },
      },
      {
        id: "p2",
        name: "Vertex Redirect",
        brand: "MarkaB",
        isVisible: true,
        source: "invoice",
        metadata: {
          manufacturerSource: {
            url: "https://vertexaisearch.cloud.google.com/grounding-api-redirect/abc",
            verificationStatus: "verified",
          },
        },
      },
      {
        id: "p3",
        name: "XSS URL",
        brand: "MarkaC",
        isVisible: true,
        source: "invoice",
        metadata: { manufacturerSource: { url: "javascript:alert(1)", verificationStatus: "verified" } },
      },
      {
        id: "p4",
        name: "HTTP URL",
        brand: "MarkaD",
        isVisible: true,
        source: "invoice",
        metadata: { manufacturerSource: { url: "http://anadoluline.com.tr/urun", verificationStatus: "verified" } },
      },
      {
        id: "p5",
        name: "Boş Marka",
        brand: "   ",
        isVisible: true,
        source: "invoice",
        metadata: { manufacturerSource: { url: "https://anadoluline.com.tr/urun", verificationStatus: "verified" } },
      },
      {
        id: "p6",
        name: "Gizli Ürün",
        brand: "AnadoluLine",
        isVisible: false,
        source: "invoice",
        metadata: { manufacturerSource: { url: "https://anadoluline.com.tr/urun", verificationStatus: "verified" } },
      },
    ];

    expect(resmiMarkaRaflariniDerle(gecersizler)).toEqual([]);
    expect(resmiMarkaRaflariniDerle([])).toEqual([]);
  });
});

describe("b2bWhatsappSiparis pozitif ve negatif durumlar", () => {
  it("geçerli TR telefon ve adet ile güvenli wa.me URL üretir", () => {
    const url = b2bStokYenileWhatsappUrl({
      toptanciWhatsapp: "0532 111 22 33",
      urunAdi: "AnadoluLine Keten Gömlek",
      marka: "AnadoluLine",
      modelKodu: "ANL-101",
      barkod: "8690001001011",
      varyantVeyaBeden: "Siyah / M",
      adet: 12,
      esnafMagazaAdi: "Yıldız Butik",
      esnafKonum: "Ümraniye / İstanbul",
      not: "Cuma sevkiyatına eklenebilir",
    });

    expect(url).not.toBeNull();
    expect(url!.startsWith("https://wa.me/905321112233?text=")).toBe(true);
    const decoded = decodeURIComponent(url!.split("?text=")[1]);
    expect(decoded).toContain("Yıldız Butik");
    expect(decoded).toContain("AnadoluLine Keten Gömlek");
    expect(decoded).toContain("8690001001011");
    expect(decoded).toContain("Adet: 12");
  });

  it("kısa/geçersiz telefon, geçersiz adet ve boş ürün/mağaza adını reddeder", () => {
    const baz = {
      toptanciWhatsapp: "05321112233",
      urunAdi: "Keten Gömlek",
      adet: 5,
      esnafMagazaAdi: "Yıldız Butik",
    };

    expect(b2bStokYenileWhatsappUrl({ ...baz, toptanciWhatsapp: "12345" })).toBeNull();
    expect(b2bStokYenileWhatsappUrl({ ...baz, toptanciWhatsapp: "abc" })).toBeNull();
    expect(b2bStokYenileWhatsappUrl({ ...baz, adet: 0 })).toBeNull();
    expect(b2bStokYenileWhatsappUrl({ ...baz, adet: -5 })).toBeNull();
    expect(b2bStokYenileWhatsappUrl({ ...baz, adet: Number.NaN })).toBeNull();
    expect(b2bStokYenileWhatsappUrl({ ...baz, adet: 1.5 })).toBeNull();
    expect(b2bStokYenileWhatsappUrl({ ...baz, adet: 10000 })).toBeNull();
    expect(b2bStokYenileWhatsappUrl({ ...baz, urunAdi: "   " })).toBeNull();
    expect(b2bStokYenileWhatsappUrl({ ...baz, esnafMagazaAdi: "" })).toBeNull();
  });

  it("satır enjeksiyonunu, IBAN/VKN/iskonto sırlarını temizler ve emoji UTF-16 bütünlüğünü korur", () => {
    const mesaj = b2bStokYenileMesajiOlustur({
      toptanciWhatsapp: "+90 532 111 22 33",
      urunAdi: `Keten Gömlek\r\nSahte Satır ${SENTETIK_SIRLAR.iban} ${SENTETIK_SIRLAR.vkn} %15 özel iskonto`,
      esnafMagazaAdi: "Yıldız Butik\u2028Enjeksiyon",
      adet: 20,
      not: "🧵".repeat(250),
    });

    expect(mesaj).not.toBeNull();
    expect(mesaj!.isWellFormed()).toBe(true);
    expect(mesaj).not.toContain(SENTETIK_SIRLAR.iban);
    expect(mesaj).not.toContain(SENTETIK_SIRLAR.vkn);
    expect(mesaj).not.toMatch(/iskonto/i);
    const satirlar = mesaj!.split("\n");
    expect(satirlar.some((s) => s.startsWith("Sahte Satır"))).toBe(false);
    expect(satirlar.some((s) => s.startsWith("Enjeksiyon"))).toBe(false);
  });
});

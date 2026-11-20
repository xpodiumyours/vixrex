import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it, vi } from "vitest";

const state = vi.hoisted(() => ({ index: 0, values: {} as Record<number, unknown> }));
vi.mock("react", async (importOriginal) => {
  const actual = await importOriginal<typeof import("react")>();
  return {
    ...actual,
    useState(initial: unknown) {
      const index = state.index++;
      return actual.useState(Object.hasOwn(state.values, index) ? state.values[index] : initial);
    },
  };
});

import InvoiceToProducts, {
  faturaSatiriDurumunuHazirla,
  izinTalebiIstekGovdesi,
  izinWhatsappPaylasimLinki,
  tamIzinBaglantisi,
} from "@/components/owner/InvoiceToProducts";
import { faturaSatiriniAktar } from "@/lib/faturaPresetAktarimi";
import { katalogJsonunuOku } from "@/lib/faturaGoru";

const LINE_UUID_1 = "11111111-1111-4111-8111-111111111111";
const LINE_UUID_2 = "22222222-2222-4222-8222-222222222222";
const PRODUCT_UUID_1 = "33333333-3333-4333-8333-333333333333";

function ornekSatir() {
  const parsed = katalogJsonunuOku(
    JSON.stringify({
      satirlar: [
        {
          ad: "Örnek Erkek Fanila",
          uretici: "Tutku İç Giyim",
          adet: 10,
          birim: "adet",
          alis_birim_fiyat: 85.5,
          satir_toplam: 855,
          site_sayfa: "https://manufacturer.example/fanila",
        },
      ],
    }),
  );
  const aktarilan = faturaSatiriniAktar(parsed.satirlar[0], "Örnek Toptancı A.Ş.");
  return {
    ...faturaSatiriDurumunuHazirla(
      { ...aktarilan, satirId: LINE_UUID_1, urunId: PRODUCT_UUID_1 },
      "",
    ),
    satirId: LINE_UUID_1,
  };
}

function renderEkran(args: {
  adim: string;
  tedarikci: string;
  satirlar: ReturnType<typeof ornekSatir>[];
  izinLinki?: string | null;
  izinHata?: string | null;
}) {
  state.index = 0;
  state.values = {
    0: args.adim,
    2: {
      satirlar: args.satirlar,
      belgeAdedi: null,
      belgeToplami: null,
      tedarikci: args.tedarikci,
      tedarikciVergiNo: "1234567890",
    },
    3: args.satirlar,
    ...(args.izinLinki !== undefined ? { 17: args.izinLinki } : {}),
    ...(args.izinHata !== undefined ? { 19: args.izinHata } : {}),
  };
  return renderToStaticMarkup(
    createElement(InvoiceToProducts, {
      storeSlug: "ornek-butik",
      onUploaded: async () => {},
    }),
  );
}

describe("InvoiceToProducts Üretici İzin Köprüsü UI", () => {
  it("urunler adiminda tedarikci ve satirlar varken ilk izin talep butonunu gosterir", () => {
    const html = renderEkran({
      adim: "urunler",
      tedarikci: "Örnek Toptancı A.Ş.",
      satirlar: [ornekSatir()],
    });
    expect(html).toContain("Üretici İzin Köprüsü");
    expect(html).toContain("Üretici İzni Talep Et (WhatsApp / Link)");
    expect(html).not.toContain("Onay Linki Hazır");
    const kopru = html.match(/<section[^>]*aria-label="Üretici İzin Köprüsü"[\s\S]*?<\/section>/)?.[0] ?? "";
    expect(kopru).not.toBe("");
    expect(kopru).not.toContain("1234567890");
  });

  it("link olustugunda Onay Linki Hazir, Linki Kopyala ve WhatsApp linkini gosterir", () => {
    const url = "https://www.vixrex.com/izin-talebi/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
    const html = renderEkran({
      adim: "urunler",
      tedarikci: "Tutku İç Giyim",
      satirlar: [ornekSatir()],
      izinLinki: url,
    });
    expect(html).toContain("Onay Linki Hazır");
    expect(html).toContain("Linki Kopyala");
    expect(html).toContain("WhatsApp ile Üreticiye İlet");
    expect(html).toContain("https://wa.me/?text=");
    expect(html).toContain(url);
    expect(html).not.toContain("Üretici İzni Talep Et (WhatsApp / Link)");
  });

  it("negatif uc durum: tedarikci bos veya satirlar bossa kutu gosterilmez", () => {
    const tedarikciBos = renderEkran({
      adim: "urunler",
      tedarikci: "   ",
      satirlar: [ornekSatir()],
    });
    expect(tedarikciBos).not.toContain("Üretici İzin Köprüsü");

    const satirlarBos = renderEkran({
      adim: "urunler",
      tedarikci: "Tutku İç Giyim",
      satirlar: [],
    });
    expect(satirlarBos).not.toContain("Üretici İzin Köprüsü");
  });

  it("negatif uc durum: sec veya okunuyor adiminda kutu gosterilmez", () => {
    const secHtml = renderEkran({
      adim: "sec",
      tedarikci: "Tutku İç Giyim",
      satirlar: [ornekSatir()],
    });
    expect(secHtml).not.toContain("Üretici İzin Köprüsü");

    const okunuyorHtml = renderEkran({
      adim: "okunuyor",
      tedarikci: "Tutku İç Giyim",
      satirlar: [ornekSatir()],
    });
    expect(okunuyorHtml).not.toContain("Üretici İzin Köprüsü");
  });

  it("negatif uc durum: hata durumunda alert basar ve sahte Onay Linki Hazir gostermez", () => {
    const html = renderEkran({
      adim: "urunler",
      tedarikci: "Tutku İç Giyim",
      satirlar: [ornekSatir()],
      izinLinki: null,
      izinHata: "İzin talebi bağlantısı oluşturulamadı.",
    });
    expect(html).toContain('role="alert"');
    expect(html).toContain("İzin talebi bağlantısı oluşturulamadı.");
    expect(html).not.toContain("Onay Linki Hazır");
  });

  it("belge.tedarikci bos iken satir markasindan Uretici Izin Koprusunu gosterir ve marka ile link paylasir", () => {
    const satirMarkali = {
      ...ornekSatir(),
      marka: "Tutku",
      katalog: { ...ornekSatir().katalog!, marka: "Tutku" },
    };
    const ilkHtml = renderEkran({
      adim: "urunler",
      tedarikci: "",
      satirlar: [satirMarkali],
    });
    expect(ilkHtml).toContain("Üretici İzin Köprüsü");
    expect(ilkHtml).toContain("Üretici İzni Talep Et (WhatsApp / Link)");

    const url = "https://www.vixrex.com/izin-talebi/bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb";
    const linkHtml = renderEkran({
      adim: "urunler",
      tedarikci: "",
      satirlar: [satirMarkali],
      izinLinki: url,
    });
    const waHref = linkHtml.match(/href="(https:\/\/wa\.me\/\?text=[^"]+)"/)?.[1] ?? "";
    expect(waHref).not.toBe("");
    const decoded = decodeURIComponent(waHref.replace("https://wa.me/?text=", ""));
    expect(decoded).toContain("Tutku");
    expect(decoded).not.toContain("Yetkili");
    expect(decoded).not.toContain("1234567890");
  });

  it("sec adiminda tedarikci bos gelen onceki islemlerde Firma okunamadi yazmaz", () => {
    state.index = 0;
    state.values = {
      0: "sec",
      10: [
        {
          islemKimligi: LINE_UUID_1,
          durum: "inceleme",
          tedarikci: "",
          olusturma: "2026-11-19T10:00:00Z",
          satirSayisi: 4,
          asama: "hazir",
        },
      ],
    };
    const html = renderToStaticMarkup(
      createElement(InvoiceToProducts, {
        storeSlug: "ornek-butik",
        onUploaded: async () => {},
      }),
    );
    expect(html).toContain("Fatura kaydı");
    expect(html).not.toContain("Firma okunamadı");
  });
});

describe("Kural 32 izin talebi payload ve link yardimcilari", () => {
  it("gecerli satirId ve urunId ile Kural 32 temizlenmis payload uretir ve UUID tekillestirir", () => {
    const payload = izinTalebiIstekGovdesi(
      "ornek-butik",
      "Tutku A.Ş. VKN 1234567890 ETTN-9999",
      [
        {
          satirId: LINE_UUID_1,
          urunId: PRODUCT_UUID_1,
          marka: "Tutku",
          katalog: { marka: "Tutku İç Giyim iskonto %20" },
        },
        {
          satirId: LINE_UUID_1,
          urunId: "gecersiz-id",
          marka: "Tutku",
          katalog: null,
        },
        {
          satirId: LINE_UUID_2,
          urunId: null,
          marka: "",
          katalog: null,
        },
      ],
    );

    expect(payload).toEqual({
      slug: "ornek-butik",
      supplierName: "Tutku A.Ş.",
      brand: "Tutku İç Giyim",
      lineIds: [LINE_UUID_1, LINE_UUID_2],
      productIds: [PRODUCT_UUID_1],
    });
    const raw = JSON.stringify(payload);
    expect(raw).not.toContain("1234567890");
    expect(raw).not.toContain("ETTN-9999");
    expect(raw).not.toContain("iskonto");
    expect(raw).not.toContain("supplierTaxId");
    expect(raw).not.toContain("alisBirimFiyat");
  });

  it("negatif uc durumlar: eksik slug, bos tedarikci veya gecersiz UUID listesinde null doner", () => {
    expect(
      izinTalebiIstekGovdesi("", "Tutku", [{ satirId: LINE_UUID_1, urunId: PRODUCT_UUID_1 }]),
    ).toBeNull();
    expect(
      izinTalebiIstekGovdesi("ornek-butik", "1234567890", [{ satirId: LINE_UUID_1 }]),
    ).toBeNull();
    expect(
      izinTalebiIstekGovdesi("ornek-butik", "Tutku", [
        { satirId: "not-a-uuid", urunId: "still-bad" },
      ]),
    ).toBeNull();
    expect(izinTalebiIstekGovdesi("ornek-butik", "Tutku", [])).toBeNull();
    expect(
      izinTalebiIstekGovdesi("ornek-butik", "", [
        { satirId: LINE_UUID_1, marka: "VKN 1234567890" },
      ]),
    ).toBeNull();
  });

  it("tedarikci bos iken satir markasindan Kural 32 uyumlu izin talebi payloadu uretir", () => {
    const payload = izinTalebiIstekGovdesi("ornek-butik", "", [
      {
        satirId: LINE_UUID_1,
        urunId: PRODUCT_UUID_1,
        marka: "Tutku",
        katalog: null,
      },
    ]);
    expect(payload).toEqual({
      slug: "ornek-butik",
      supplierName: "Tutku",
      brand: "Tutku",
      lineIds: [LINE_UUID_1],
      productIds: [PRODUCT_UUID_1],
    });
  });

  it("tamIzinBaglantisi ve izinWhatsappPaylasimLinki temiz URL uretir", () => {
    const full = tamIzinBaglantisi("/izin-talebi/abc123", "https://www.vixrex.com/");
    expect(full).toBe("https://www.vixrex.com/izin-talebi/abc123");
    expect(tamIzinBaglantisi("https://vixrex.com/izin-talebi/xyz", "https://ignored.local")).toBe(
      "https://vixrex.com/izin-talebi/xyz",
    );

    const wa = izinWhatsappPaylasimLinki("Tutku VKN 1234567890", full);
    expect(wa.startsWith("https://wa.me/?text=")).toBe(true);
    const decoded = decodeURIComponent(wa.replace("https://wa.me/?text=", ""));
    expect(decoded).toContain("Tutku");
    expect(decoded).toContain(full);
    expect(decoded).not.toContain("1234567890");
    expect(decoded).not.toContain("VKN");
  });
});

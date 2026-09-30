import { NextRequest } from "next/server";
import { beforeEach, describe, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => ({
  admin: vi.fn(),
  yetki: vi.fn(),
}));
vi.mock("@/lib/supabaseAdmin", () => ({ getSupabaseAdmin: mocks.admin }));
vi.mock("@/lib/faturaYetki", () => ({ sahipYetkisi: mocks.yetki }));

import { GET, PUT } from "@/app/api/fatura-islem/route";
import { islemiYukle, sahipDurumunuTemizle } from "@/lib/faturaIslemOku";

const ISLEM = "22222222-2222-4222-8222-222222222222";

interface TabloVerisi {
  tekil?: unknown;
  liste?: unknown[];
  sayi?: number;
  hata?: { message: string } | null;
}

function sahteAdmin(tablolar: Record<string, TabloVerisi>, guncellemeler: unknown[] = []) {
  return {
    from: (tablo: string) => {
      const veri = tablolar[tablo] ?? {};
      const z: Record<string, unknown> = {};
      z.select = () => z;
      z.eq = () => z;
      z.order = () => z;
      z.limit = () => z;
      z.update = (govde: unknown) => {
        guncellemeler.push({ tablo, govde });
        return z;
      };
      z.maybeSingle = async () => ({ data: veri.tekil ?? null, error: null });
      z.then = (basari: never, alici: never) =>
        Promise.resolve({
          data: veri.liste ?? null,
          count: veri.sayi ?? (veri.liste ? veri.liste.length : 0),
          error: veri.hata ?? null,
        }).then(basari, alici);
      return z;
    },
  } as never;
}

const KATALOG = {
  firma: "Işılay",
  kaynakFirma: "Işılay",
  dayanak: "kod",
  izinDurumu: "yok",
  resmiAd: "IŞILAY 16747 İnterlok Penye Erkek Takım",
  marka: "Işılay",
  aciklama: "Pamuklu",
  gorseller: ["https://isilay.example/16747.jpg"],
  gorselAdaylari: ["https://isilay.example/16747.jpg"],
  kaynak: "https://isilay.example/urun/16747",
};

describe("işlemi kapatıp yeniden açma", () => {
  it("kayıtlı satır kart, uyarı ve esnaf girdileriyle birlikte aynı haliyle döner", async () => {
    const admin = sahteAdmin({
      invoice_jobs: {
        tekil: {
          id: ISLEM,
          status: "inceleme",
          supplier_name: "Glisa Tekstil",
          supplier_tax_id: "1234567890",
          supplier_address: "",
          supplier_site: "",
          document_adet: 8,
          document_total: 3600,
          document_warning: "",
          document_type: "e-arsiv",
          document_no: "GLS2026000123",
          document_date: "2026-09-29",
          goods_total: 3600,
          vat_total: 360,
          discount_total: null,
          payable_total: 3960,
        },
      },
      invoice_job_lines: {
        liste: [
          {
            id: "satir-1",
            line_index: 0,
            raw_line: "16747 Interlok 8 450,00 3600,00",
            model: "16747",
            product_name: "Interlok Penye Erkek Takım",
            barcode: "",
            variant_name: "",
            size_text: "",
            brand: "Işılay",
            qty: 8,
            unit_price: 450,
            line_total: 3600,
            confidence: 0.9,
            outcome: "kanitli",
            warning: "",
            catalog_snapshot: KATALOG,
            conflict_snapshot: null,
            owner_state: {
              satisFiyati: "599",
              stok: "8",
              stokOnaylandi: true,
              kategoriId: "kategori-1",
              onayli: false,
              esnafGorselleri: [],
            },
            product_id: "urun-7",
          },
        ],
      },
    });

    const islem = await islemiYukle(admin, "store-1", ISLEM);

    expect(islem?.tedarikci).toBe("Glisa Tekstil");
    expect(islem?.belge.malBedeli).toBe(3600);
    expect(islem?.belge.odenecekToplam).toBe(3960);
    expect(islem?.satirlar[0].katalog?.resmiAd).toContain("16747");
    expect(islem?.satirlar[0].sonuc).toBe("kanitli");
    expect(islem?.satirlar[0].sahipDurumu?.satisFiyati).toBe("599");
    expect(islem?.satirlar[0].urunId).toBe("urun-7");
  });

  it("başka vitrinin ya da olmayan işlem açılmaz", async () => {
    const admin = sahteAdmin({ invoice_jobs: {} });
    expect(await islemiYukle(admin, "store-1", ISLEM)).toBeNull();
  });

  it("esnaf girdileri temizlenir: uzun metin kesilir, https olmayan görsel atılır", () => {
    const temiz = sahipDurumunuTemizle({
      satisFiyati: "5".repeat(50),
      stok: "12",
      stokOnaylandi: "evet",
      kategoriId: "k1",
      onayli: true,
      esnafGorselleri: ["https://depo.example/a.jpg", "http://kotu.example/b.jpg", 42],
    });

    expect(temiz?.satisFiyati).toHaveLength(20);
    expect(temiz?.stokOnaylandi).toBe(false);
    expect(temiz?.onayli).toBe(true);
    expect(temiz?.esnafGorselleri).toEqual(["https://depo.example/a.jpg"]);
    expect(sahipDurumunuTemizle("x")).toBeNull();
  });
});

describe("fatura-islem ucu", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mocks.yetki.mockResolvedValue({ tamam: true, storeId: "store-1", slug: "deneme-vitrin" });
  });

  it("yetkisiz istek reddedilir", async () => {
    mocks.yetki.mockResolvedValue({ tamam: false, durum: 401, hata: "Oturumun geçersiz veya süresi dolmuş." });
    mocks.admin.mockReturnValue(sahteAdmin({}));

    const cevap = await GET(new NextRequest("http://localhost/api/fatura-islem?slug=deneme-vitrin"));

    expect(cevap.status).toBe(401);
  });

  it("işlem kimliği verilmezse son işlemler listelenir", async () => {
    mocks.admin.mockReturnValue(
      sahteAdmin({
        invoice_jobs: {
          liste: [{ id: ISLEM, status: "inceleme", supplier_name: "Glisa", created_at: "2026-09-30T10:00:00Z" }],
        },
        invoice_job_lines: { sayi: 3 },
      }),
    );

    const govde = await (
      await GET(new NextRequest("http://localhost/api/fatura-islem?slug=deneme-vitrin"))
    ).json();

    expect(govde.islemler).toHaveLength(1);
    expect(govde.islemler[0]).toMatchObject({ islemKimligi: ISLEM, tedarikci: "Glisa", satirSayisi: 3 });
  });

  it("esnaf girdileri satıra kaydedilir", async () => {
    const guncellemeler: unknown[] = [];
    mocks.admin.mockReturnValue(
      sahteAdmin({ invoice_jobs: { tekil: { id: ISLEM } }, invoice_job_lines: {} }, guncellemeler),
    );

    const cevap = await PUT(
      new NextRequest("http://localhost/api/fatura-islem", {
        method: "PUT",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({
          slug: "deneme-vitrin",
          islemKimligi: ISLEM,
          satirlar: [
            {
              satirSirasi: 0,
              sahipDurumu: { satisFiyati: "599", stok: "8", stokOnaylandi: true, onayli: false },
            },
          ],
        }),
      }),
    );

    expect(cevap.status).toBe(200);
    expect(guncellemeler).toHaveLength(1);
    expect((guncellemeler[0] as { govde: { owner_state: { satisFiyati: string } } }).govde.owner_state.satisFiyati).toBe(
      "599",
    );
  });

  it("geçersiz satır sırası ya da boş liste reddedilir", async () => {
    mocks.admin.mockReturnValue(sahteAdmin({}));
    const istek = (satirlar: unknown) =>
      new NextRequest("http://localhost/api/fatura-islem", {
        method: "PUT",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ slug: "deneme-vitrin", islemKimligi: ISLEM, satirlar }),
      });

    expect((await PUT(istek([]))).status).toBe(422);
    expect((await PUT(istek([{ satirSirasi: -1, sahipDurumu: {} }]))).status).toBe(422);
  });
});

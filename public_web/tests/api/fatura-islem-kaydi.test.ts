import { describe, expect, it, vi } from "vitest";
import { belgeParmakIzi, islemKaydet, type IslemKaydiGirdisi } from "@/lib/faturaIslemKaydi";
import type { EslesmisFaturaSatiri } from "@/lib/faturaEslestir";

interface YazilanKayit {
  tablo: string;
  yollar: string[];
  govde: unknown;
  secenek: unknown;
}

const durum = vi.hoisted(() => {
  const yazilan: Array<{
    tablo: string;
    yollar: string[];
    govde: unknown;
    secenek: unknown;
  }> = [];
  let hata: Error | null = null;

  const zincir = (tablo: string) => {
    const kayit: (typeof yazilan)[number] = { tablo, yollar: [], govde: undefined, secenek: undefined };
    yazilan.push(kayit);

    const z: Record<string, unknown> = {};
    const sarmala = (yol: string) => (..._args: unknown[]) => {
      kayit.yollar.push(yol);
      return z;
    };
    z.select = sarmala("select");
    z.eq = sarmala("eq");
    z.order = sarmala("order");
    z.delete = sarmala("delete");
    z.insert = (govde: unknown) => {
      kayit.yollar.push("insert");
      kayit.govde = govde;
      return z;
    };
    z.upsert = (govde: unknown, secenek: unknown) => {
      kayit.yollar.push("upsert");
      kayit.govde = govde;
      kayit.secenek = secenek;
      return z;
    };
    z.maybeSingle = async () => ({ data: { id: "magaza-1" }, error: null });
    z.single = async () => ({ data: { id: `is-${yazilan.length}` }, error: null });
    z.then = (basari: unknown, alici: unknown) => {
      const dizi = Array.isArray(kayit.govde) ? kayit.govde : [];
      const veri = dizi.map((_og, indeks) => ({ id: `satir-${indeks}` }));
      return Promise.resolve({ data: veri, error: null }).then(basari as never, alici as never);
    };
    return z;
  };

  return {
    yazilan,
    zincir,
    setHata: (yeni: Error | null) => {
      hata = yeni;
    },
    getHata: () => hata,
  };
});

vi.mock("@/lib/supabaseAdmin", () => ({
  getSupabaseAdmin: () => {
    const hata = durum.getHata();
    if (hata) throw hata;
    return { from: (tablo: string) => durum.zincir(tablo) };
  },
}));

function satir(uzeler: Partial<EslesmisFaturaSatiri>): EslesmisFaturaSatiri {
  return {
    hamSatir: "ELT1302 Elit Erkek 2 137,00 274,00",
    model: "ELT1302",
    ad: "Elit Erkek Elastan",
    barkod: "8681128321677",
    varyant: "Siyah",
    beden: "L",
    adet: 2,
    alisBirimFiyat: 137,
    satirToplam: 274,
    guven: 0.9,
    katalog: null,
    sonuc: "eksik",
    ...uzeler,
  };
}

function girdi(satirlar: EslesmisFaturaSatiri[]): IslemKaydiGirdisi {
  return {
    slug: "deneme-vitrin",
    parmakIzi: "a".repeat(64),
    belgeAdedi: 2,
    belgeToplami: 400,
    tedarikci: "Seher Mensucat",
    tedarikciVergiNo: "1234567890",
    tedarikciAdres: "İstanbul",
    tedarikciSite: "sehermensucat.com",
    tedarikciIz: {
      anahtar: "seher-mensucat",
      firma: "Seher Mensucat",
      alan: "sehermensucat.com",
      platform: "",
      izinDurumu: "yok",
      kaynak: "https://sehermensucat.com",
      havuzda: true,
    },
    satirlar,
  };
}

const izinliTablolar = new Set([
  "stores",
  "invoice_jobs",
  "invoice_job_lines",
  "invoice_line_evidence",
  "invoice_line_candidates",
  "invoice_image_rights",
]);

function kaydiBul(tablo: string): YazilanKayit | undefined {
  return durum.yazilan.find((kayit) => kayit.tablo === tablo);
}

describe("fatura islem kaydi", () => {
  it("fotografin ozeti ayniysa ayni is kaydini acar", () => {
    const bayt = new Uint8Array([1, 2, 3]);
    expect(belgeParmakIzi(bayt)).toBe(belgeParmakIzi(bayt));
    expect(belgeParmakIzi(bayt)).toHaveLength(64);
  });

  it("is, satirlar, kanit, aday kaynak ve gorsel iznini yazar", async () => {
    durum.yazilan.length = 0;
    durum.setHata(null);

    const kataloglu = satir({
      sonuc: "kanitli",
      katalog: {
        firma: "Seher Mensucat",
        kaynakFirma: "Seher Mensucat",
        dayanak: "kod",
        izinDurumu: "yok",
        resmiAd: "Elit Erkek Elastan Sıfır Yaka",
        marka: "Elit",
        aciklama: "Pamuklu",
        gorseller: [],
        gorselAdaylari: ["https://sehermensucat.com/elt1302.jpg"],
        kaynak: "https://sehermensucat.com/elt1302",
      },
    });

    const islemKimligi = await islemKaydet(girdi([kataloglu, satir({ sonuc: "eksik" })]));

    expect(islemKimligi).toBeTruthy();
    expect(durum.yazilan.every((kayit) => izinliTablolar.has(kayit.tablo))).toBe(true);

    const is = kaydiBul("invoice_jobs");
    expect(is?.yollar).toContain("upsert");
    expect(is?.secenek).toEqual({ onConflict: "store_id,document_fingerprint" });
    expect((is?.govde as Record<string, unknown>).status).toBe("inceleme");
    expect((is?.govde as Record<string, unknown>).document_fingerprint).toHaveLength(64);

    const silme = durum.yazilan.find(
      (kayit) => kayit.tablo === "invoice_job_lines" && kayit.yollar.includes("delete"),
    );
    const satirlar = durum.yazilan.find(
      (kayit) => kayit.tablo === "invoice_job_lines" && kayit.yollar.includes("insert"),
    );
    expect(silme?.yollar).toContain("delete");
    expect(satirlar?.yollar).toContain("insert");
    expect((satirlar?.govde as Array<Record<string, unknown>>).map((satirKaydi) => satirKaydi.outcome)).toEqual([
      "kanitli",
      "eksik",
    ]);
    expect((satirlar?.govde as Array<Record<string, unknown>>)[0].unit_price).toBe(137);

    const kanit = kaydiBul("invoice_line_evidence");
    const kanitSatillari = kanit?.govde as Array<Record<string, unknown>>;
    expect(kanit?.secenek).toEqual({ onConflict: "line_id,field_name,source" });
    expect(kanitSatillari.some((satirKaydi) => satirKaydi.field_name === "urun_adi")).toBe(true);
    expect(kanitSatillari.filter((satirKaydi) => satirKaydi.strength === "strong")).toHaveLength(2);

    const aday = kaydiBul("invoice_line_candidates");
    expect((aday?.govde as Array<Record<string, unknown>>)[0].url).toBe(
      "https://sehermensucat.com/elt1302",
    );

    const gorsel = kaydiBul("invoice_image_rights");
    expect((gorsel?.govde as Array<Record<string, unknown>>)[0].usage_status).toBe("denied");
  });

  it("tumu kanitliysa is durumu eslestirme olur", async () => {
    durum.yazilan.length = 0;
    durum.setHata(null);

    await islemKaydet(
      girdi([
        satir({
          sonuc: "kanitli",
          katalog: {
            firma: "Seher Mensucat",
            kaynakFirma: "Seher Mensucat",
            dayanak: "kod",
            izinDurumu: "var",
            resmiAd: "Elit Erkek Elastan",
            marka: "Elit",
            aciklama: "",
            gorseller: ["https://sehermensucat.com/elt1302.jpg"],
            gorselAdaylari: ["https://sehermensucat.com/elt1302.jpg"],
            kaynak: "https://sehermensucat.com/elt1302",
          },
        }),
      ]),
    );

    const is = kaydiBul("invoice_jobs");
    expect((is?.govde as Record<string, unknown>).status).toBe("eslestirme");

    const gorsel = kaydiBul("invoice_image_rights");
    expect((gorsel?.govde as Array<Record<string, unknown>>)[0].usage_status).toBe(
      "verified_supplier_permission",
    );
  });

  it("veritabanina yazilamazsa hata uretmez, okuma devam eder", async () => {
    durum.yazilan.length = 0;
    durum.setHata(new Error("baglanti yok"));

    const sonuc = await islemKaydet(girdi([satir({})]));

    expect(sonuc).toBeNull();
    expect(durum.yazilan).toHaveLength(0);
  });
});

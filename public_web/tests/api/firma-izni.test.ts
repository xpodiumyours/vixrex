import { describe, expect, it } from "vitest";
import {
  cevapKaydet,
  izinEtiketi,
  izinGecerliMi,
  izinOzetiOku,
  talepMetniOlustur,
  talepOlustur,
  type IzinKaydi,
} from "@/lib/firmaIzni";

type Satir = Record<string, unknown>;

function sahteVeritabani(tablolar: Record<string, Satir[]>) {
  const cagrilar: Array<{ tablo: string; islem: string; govde?: unknown }> = [];
  let sayac = 0;

  const admin = {
    from(tablo: string) {
      tablolar[tablo] ??= [];
      let islem: "select" | "insert" | "upsert" | "update" = "select";
      let govde: unknown;
      let sadeceSayim = false;
      let tek = false;
      let sinir = Infinity;
      const filtreler: Array<(satir: Satir) => boolean> = [];

      const calistir = () => {
        const eslesen = tablolar[tablo].filter((satir) => filtreler.every((f) => f(satir)));
        cagrilar.push({ tablo, islem, govde });
        if (islem === "insert") {
          const yeni: Satir = { id: `kayit-${++sayac}`, created_at: "2026-09-30T10:00:00Z", ...(govde as Satir) };
          const cakisma =
            tablo === "supplier_permission_requests" &&
            ["hazirlandi", "gonderim_bekliyor", "gonderildi"].includes(String(yeni.status)) &&
            tablolar[tablo].some(
              (s) =>
                s.store_id === yeni.store_id &&
                s.supplier_key === yeni.supplier_key &&
                s.scope === yeni.scope &&
                ["hazirlandi", "gonderim_bekliyor", "gonderildi"].includes(String(s.status)),
            );
          if (cakisma) return { data: null, error: { message: "duplicate" }, count: 0 };
          tablolar[tablo].push(yeni);
          return { data: yeni, error: null, count: 1 };
        }
        if (islem === "upsert") {
          const kayitlar = (Array.isArray(govde) ? govde : [govde]) as Satir[];
          for (const kayit of kayitlar) {
            const varolan = tablolar[tablo].find((s) =>
              tablo === "supplier_permissions"
                ? s.supplier_key === kayit.supplier_key && s.scope === kayit.scope
                : s.request_id === kayit.request_id && s.product_id === kayit.product_id,
            );
            if (varolan) Object.assign(varolan, kayit);
            else tablolar[tablo].push({ ...kayit });
          }
          return { data: null, error: null, count: kayitlar.length };
        }
        if (islem === "update") {
          for (const satir of eslesen) Object.assign(satir, govde as Satir);
          return { data: null, error: null, count: eslesen.length };
        }
        const liste = eslesen.slice(0, sinir);
        return {
          data: sadeceSayim ? null : tek ? (liste[0] ?? null) : liste,
          error: null,
          count: eslesen.length,
        };
      };

      const z: Record<string, unknown> = {};
      z.select = (_kolonlar?: string, secenek?: { head?: boolean }) => {
        if (islem === "select") sadeceSayim = secenek?.head === true;
        return z;
      };
      z.insert = (g: unknown) => ((islem = "insert"), (govde = g), z);
      z.upsert = (g: unknown) => ((islem = "upsert"), (govde = g), z);
      z.update = (g: unknown) => ((islem = "update"), (govde = g), z);
      z.eq = (kolon: string, deger: unknown) => (filtreler.push((s) => s[kolon] === deger), z);
      z.in = (kolon: string, degerler: unknown[]) => (filtreler.push((s) => degerler.includes(s[kolon])), z);
      z.order = () => z;
      z.limit = (n: number) => ((sinir = n), z);
      z.maybeSingle = async () => ((tek = true), calistir());
      z.single = async () => ((tek = true), calistir());
      z.then = (basari: never, alici: never) => Promise.resolve(calistir()).then(basari, alici);
      return z;
    },
  };
  return { admin: admin as never, tablolar, cagrilar };
}

const ISLEM = "33333333-3333-4333-8333-333333333333";

function temelVeri(): Record<string, Satir[]> {
  return {
    invoice_jobs: [
      {
        id: ISLEM,
        store_id: "store-1",
        supplier_name: "Işılay Tekstil",
        supplier_site: "isilaytekstil.com",
        supplier_trace: { anahtar: "isilay", alan: "isilaytekstil.com" },
      },
    ],
    invoice_job_lines: [
      {
        job_id: ISLEM,
        product_id: "urun-1",
        catalog_snapshot: {
          resmiAd: "IŞILAY 16747 İnterlok Penye Erkek Takım",
          kaynakFirma: "Işılay Tekstil",
          marka: "Işılay",
          kaynak: "https://isilaytekstil.com/urun/16747",
        },
      },
      { job_id: ISLEM, product_id: null, catalog_snapshot: null },
    ],
    supplier_permissions: [],
    supplier_permission_requests: [],
    supplier_permission_products: [],
    products: [
      { id: "urun-1", is_visible: true, fatura_kanit: { ureticiGorsel: true } },
      { id: "urun-2", is_visible: true, fatura_kanit: { ureticiGorsel: false } },
    ],
  };
}

const ORTAK = {
  storeId: "store-1",
  magazaAdi: "Deneme Butik",
  magazaSlug: "deneme-vitrin",
  islemKimligi: ISLEM,
  kapsam: "data_and_images" as const,
  siteOrigin: "https://vixrex.example",
};

describe("firma izni: metin ve durum kuralları", () => {
  it("talep metni firmayı, örnek vitrini ve ürünleri içerir; izin alınmış gibi konuşmaz", () => {
    const metin = talepMetniOlustur({
      firmaAdi: "Işılay Tekstil",
      esnafAdi: "Deneme Butik",
      urunAdlari: ["IŞILAY 16747 Takım"],
      ornekAdres: "https://vixrex.example/v/deneme-vitrin",
      kapsam: "data_and_images",
    });

    expect(metin).toContain("Işılay Tekstil");
    expect(metin).toContain("https://vixrex.example/v/deneme-vitrin");
    expect(metin).toContain("IŞILAY 16747 Takım");
    expect(metin).toContain("izin verilmedikçe başka bir kullanım yapılmaz");
  });

  it("süresi dolan izin geçerli sayılmaz", () => {
    const simdi = new Date("2026-10-15T00:00:00Z");
    expect(izinGecerliMi("izin_verildi", null, simdi)).toBe(true);
    expect(izinGecerliMi("izin_verildi", "2026-12-31", simdi)).toBe(true);
    expect(izinGecerliMi("izin_verildi", "2026-10-01", simdi)).toBe(false);
    expect(izinGecerliMi("reddedildi", null, simdi)).toBe(false);
  });

  it("etiketler durumları birbirine çevirmez: kayıt yok ≠ ret, gönderim bekliyor ≠ gönderildi", () => {
    const yok: IzinKaydi = { durum: "izin_yok", kapsam: "data_and_images", gecerli: false, gecerlilik: null, cevapZamani: null, not: "" };
    const talep = (durum: "hazirlandi" | "gonderim_bekliyor" | "gonderildi") => ({
      talepKimligi: "t", durum, isteyen: "vixrex" as const, kapsam: "data_and_images" as const,
      mesaj: "", ornekAdres: "", gonderimZamani: null, olusturma: "", urunSayisi: 0,
    });

    expect(izinEtiketi(yok, null)).toBe("İzin henüz sorulmadı");
    expect(izinEtiketi(yok, talep("gonderim_bekliyor"))).toContain("henüz gönderilmedi");
    expect(izinEtiketi(yok, talep("gonderildi"))).toContain("cevabı bekleniyor");
    expect(izinEtiketi({ ...yok, durum: "reddedildi" }, null)).toBe("Firma izni reddetti");
  });
});

describe("firma izni talebi", () => {
  it("'Ben isteyeceğim' hazır metinli talep açar ve ilgili ürünleri bağlar", async () => {
    const { admin, tablolar } = sahteVeritabani(temelVeri());

    const sonuc = await talepOlustur(admin, { ...ORTAK, secim: "owner" });

    expect(sonuc.durum).toBe("olustu");
    expect(tablolar.supplier_permission_requests).toHaveLength(1);
    expect(tablolar.supplier_permission_requests[0]).toMatchObject({
      status: "hazirlandi",
      requested_by: "owner",
      supplier_key: "ışılaytekstil:isilaytekstil.com",
    });
    expect(String(tablolar.supplier_permission_requests[0].message)).toContain("16747");
    expect(tablolar.supplier_permission_products).toHaveLength(1);
  });

  it("'Vixrex istesin' talebi gönderilmedi durumunda bekler; arayüz 'gönderildi' demez", async () => {
    const { admin, tablolar } = sahteVeritabani(temelVeri());

    const sonuc = await talepOlustur(admin, { ...ORTAK, secim: "vixrex" });

    expect(sonuc.durum).toBe("olustu");
    if (sonuc.durum === "olustu") {
      expect(sonuc.ozet.talep?.durum).toBe("gonderim_bekliyor");
      expect(sonuc.ozet.etiket).toContain("henüz gönderilmedi");
    }
    expect(tablolar.supplier_permission_requests[0].sent_at).toBeUndefined();
  });

  it("aynı firmaya ikinci talep açılmaz, aynı talep döner", async () => {
    const { admin, tablolar } = sahteVeritabani(temelVeri());
    await talepOlustur(admin, { ...ORTAK, secim: "owner" });

    const ikinci = await talepOlustur(admin, { ...ORTAK, secim: "vixrex" });

    expect(ikinci.durum).toBe("mevcut");
    expect(tablolar.supplier_permission_requests).toHaveLength(1);
  });

  it("firma izni zaten geçerliyse talep açılmaz", async () => {
    const veri = temelVeri();
    veri.supplier_permissions.push({
      supplier_key: "ışılaytekstil:isilaytekstil.com",
      scope: "data_and_images",
      status: "izin_verildi",
      valid_until: null,
      responded_at: "2026-09-30T09:00:00Z",
      response_note: "",
    });
    const { admin, tablolar } = sahteVeritabani(veri);

    const sonuc = await talepOlustur(admin, { ...ORTAK, secim: "owner" });

    expect(sonuc.durum).toBe("izin-var");
    expect(tablolar.supplier_permission_requests).toHaveLength(0);
  });

  it("firma reddettiyse her faturada yeniden talep yağdırılmaz", async () => {
    const veri = temelVeri();
    veri.supplier_permissions.push({
      supplier_key: "ışılaytekstil:isilaytekstil.com",
      scope: "data_and_images",
      status: "reddedildi",
      valid_until: null,
    });
    const { admin, tablolar } = sahteVeritabani(veri);

    const sonuc = await talepOlustur(admin, { ...ORTAK, secim: "vixrex" });

    expect(sonuc.durum).toBe("reddedilmis");
    expect(tablolar.supplier_permission_requests).toHaveLength(0);
  });

  it("başka vitrinin işlemi için talep açılamaz", async () => {
    const { admin } = sahteVeritabani(temelVeri());

    const sonuc = await talepOlustur(admin, { ...ORTAK, storeId: "baska-vitrin", secim: "owner" });

    expect(sonuc.durum).toBe("hata");
  });
});

describe("firma cevabı", () => {
  it("esnafın talebi izin sayılmaz: cevap gelene kadar izin durumu 'izin yok' kalır", async () => {
    const { admin } = sahteVeritabani(temelVeri());
    await talepOlustur(admin, { ...ORTAK, secim: "owner" });

    const ozet = await izinOzetiOku(admin, "store-1", ISLEM);

    expect(ozet?.izin.durum).toBe("izin_yok");
    expect(ozet?.izin.gecerli).toBe(false);
  });

  it("izin verilince mevcut kartlar olduğu gibi kalır", async () => {
    const { admin, tablolar } = sahteVeritabani(temelVeri());
    await talepOlustur(admin, { ...ORTAK, secim: "owner" });

    const sonuc = await cevapKaydet(admin, {
      firmaAnahtari: "ışılaytekstil:isilaytekstil.com",
      firmaAdi: "Işılay Tekstil",
      kapsam: "data_and_images",
      durum: "izin_verildi",
      gecerlilik: "2027-09-30",
      not: "E-posta ile onay",
      dogrulayan: "Casper",
    });

    expect(sonuc).toEqual({ tamam: true, gizlenen: 0 });
    expect(tablolar.products.every((urun) => urun.is_visible === true)).toBe(true);
    expect(tablolar.supplier_permissions[0]).toMatchObject({ status: "izin_verildi", verified_by: "Casper" });
    expect(tablolar.supplier_permission_requests[0].status).toBe("cevaplandi");
  });

  it("ret gelince yalnız o firmanın görselini taşıyan bağlı ürünler gizlenir, ilgisiz ürün silinmez", async () => {
    const { admin, tablolar } = sahteVeritabani(temelVeri());
    await talepOlustur(admin, { ...ORTAK, secim: "owner" });

    const sonuc = await cevapKaydet(admin, {
      firmaAnahtari: "ışılaytekstil:isilaytekstil.com",
      firmaAdi: "Işılay Tekstil",
      kapsam: "data_and_images",
      durum: "reddedildi",
      gecerlilik: null,
      not: "Firma yazılı ret verdi",
      dogrulayan: "Casper",
    });

    expect(sonuc).toEqual({ tamam: true, gizlenen: 1 });
    expect(tablolar.products.find((urun) => urun.id === "urun-1")?.is_visible).toBe(false);
    expect(tablolar.products.find((urun) => urun.id === "urun-2")?.is_visible).toBe(true);
    expect(tablolar.products).toHaveLength(2);
    expect(tablolar.supplier_permission_products[0].action).toBe("gizlendi");
  });
});

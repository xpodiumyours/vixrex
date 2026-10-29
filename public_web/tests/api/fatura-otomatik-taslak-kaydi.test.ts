import type { SupabaseClient } from "@supabase/supabase-js";
import { beforeEach, describe, expect, it, vi } from "vitest";
import type { KayitliIslem, SahipDurumu } from "@/lib/faturaIslemOku";

const m = vi.hoisted(() => ({ load: vi.fn(), save: vi.fn(), row: vi.fn(), catalog: vi.fn(), media: vi.fn() }));
vi.mock("@/lib/faturaIslemOku", async (original) => ({
  ...await original<typeof import("@/lib/faturaIslemOku")>(), islemiYukle: m.load,
}));
vi.mock("@/lib/faturaUrunBaglantisi", () => ({ faturaUrununuKaydet: m.save, satiriDogrula: m.row }));
vi.mock("@/lib/faturaUrunHazirlama", () => ({ kayitliFaturaKatalogunuUygula: m.catalog, faturaUrunGorselleriniAktar: m.media }));
import { faturaTaslakYanitiniHazirla } from "@/lib/faturaOtomatikTaslakKaydi";

const jobId = "11111111-1111-4111-8111-111111111111";
const owner = (price = ""): SahipDurumu => ({
  satisFiyati: price, stok: "2", kategoriId: "", onayli: Boolean(price), stokOnaylandi: false, esnafGorselleri: [],
});
function invoice(count = 1): KayitliIslem {
  return {
    islemKimligi: jobId, durum: "inceleme", tedarikci: "Firma", tedarikciVergiNo: "", tedarikciAdres: "", tedarikciSite: "",
    belgeAdedi: 2, belgeToplami: 200, belgeUyarisi: null,
    belge: { belgeTuru: "fatura", belgeNo: "1", belgeTarihi: null, malBedeli: 200, kdvTutari: null, indirimTutari: null, odenecekToplam: 200 },
    satirlar: Array.from({ length: count }, (_, i) => ({
      satirId: `line-${i}`, hamSatir: "Ürün 2 100", model: `M${i}`, ad: "Ürün", barkod: "", varyant: "", beden: "", marka: "",
      adet: 2, birim: "adet", alisBirimFiyat: 100, satirToplam: 200, guven: 1, sonuc: "eksik", katalog: null,
      sahipDurumu: null, urunId: null, birlestirmeAdayi: null,
    })),
  };
}
function client(kayit = invoice(), duplicate = false) {
  const products: Array<{ id: string; is_visible: boolean; fatura_kanit: Record<string, unknown> }> = [];
  let errorCode: unknown = null;
  const ownerWrites: unknown[] = [];
  const from = vi.fn((table: string) => {
    const filters = new Map<string, unknown>();
    let update: Record<string, unknown> | null = null;
    const q = {
      select: () => q,
      eq: (key: string, value: unknown) => { filters.set(key, value); return q; },
      is: (key: string, value: unknown) => { filters.set(key, value); return q; },
      in: (key: string, value: unknown) => { filters.set(key, value); return q; },
      update: (value: Record<string, unknown>) => { update = value; return q; },
      maybeSingle: async () => {
        if (table === "invoice_jobs") return { data: filters.get("store_id") === "store" ? { same_purchase_of: duplicate ? "previous-job" : null } : null, error: null };
        if (table === "stores") return { data: filters.get("id") === "store" ? { id: "store", edit_token: "edit", name: "Mağaza" } : null, error: null };
        const line = kayit.satirlar.find((row) => row.satirId === filters.get("id"));
        if (update && line && !line.sahipDurumu && !line.urunId) {
          line.sahipDurumu = update.owner_state as SahipDurumu;
          ownerWrites.push(update.owner_state);
        }
        return { data: line ? { owner_state: line.sahipDurumu, product_id: line.urunId } : null, error: null };
      },
      then: (resolve: (value: unknown) => unknown) => {
        if (table === "invoice_provider_runs") errorCode = update?.error_code;
        return Promise.resolve(resolve({ data: table === "products" ? products : null, error: null }));
      },
    };
    return q;
  });
  m.row.mockImplementation(async (_admin, _store, identity) => {
    const line = kayit.satirlar[identity.satirSirasi];
    return { satirId: line.satirId, sonuc: line.sonuc, urunId: line.urunId, katalog: line.katalog, izinliGorseller: new Set(), alisBirimFiyati: line.alisBirimFiyat };
  });
  m.save.mockImplementation(async (_admin, args) => {
    const line = kayit.satirlar.find((row) => row.satirId === args.satirId)!;
    line.urunId = `product-${line.satirId}`;
    products.push({ id: line.urunId, is_visible: false, fatura_kanit: args.kanit });
    return { durum: "kaydedildi", id: line.urunId, created: true, kayit: "yeni" };
  });
  m.load.mockImplementation(async () => structuredClone(kayit));
  return { admin: { from } as unknown as SupabaseClient, kayit, products, ownerWrites, errorCode: () => errorCode };
}

beforeEach(() => {
  vi.clearAllMocks();
  m.catalog.mockResolvedValue(null);
  m.media.mockResolvedValue({ urunGorselleri: [], gorselDurumu: "", gorselKaynaklari: [] });
});

describe("sunucuda kalıcı görünmez fatura taslağı", () => {
  it("tarayıcı veya satış fiyatı olmadan var olan kayıt yoluyla ürün oluşturur", async () => {
    const c = client();
    const reply = await faturaTaslakYanitiniHazirla(c.admin, "store", "demo", structuredClone(c.kayit));
    expect(m.save).toHaveBeenCalledWith(c.admin, expect.objectContaining({
      girdi: expect.objectContaining({ priceAmount: null, priceText: "", stockQuantity: 2 }),
      kanit: expect.objectContaining({ automaticDraft: true, esnafOnayladi: false }),
    }));
    expect(c.ownerWrites).toEqual([owner()]);
    expect(c.products[0].is_visible).toBe(false);
    expect(reply).toMatchObject({ tamam: true, hazirlaniyor: false, otomatikTaslakRaporu: { kaydedildi: 1, atlandi: 0 } });
  });

  it("önceden girilmiş fiyat ve açık onayı değiştirmez", async () => {
    const kayit = invoice(); kayit.satirlar[0].sahipDurumu = owner("149,90");
    const c = client(kayit);
    await faturaTaslakYanitiniHazirla(c.admin, "store", "demo", structuredClone(kayit));
    expect(c.ownerWrites).toEqual([]);
    expect(m.save.mock.calls[0][1]).toMatchObject({
      girdi: { priceAmount: 149.9 }, kanit: { esnafOnayladi: true, automaticDraft: true },
    });
    expect(kayit.satirlar[0].sahipDurumu).toEqual(owner("149,90"));
  });

  it("yeniden açılış bağlı yayınlanmış ürüne veya görsellerine dokunmaz; gizli taslak diye saymaz", async () => {
    const kayit = invoice(); kayit.satirlar[0].urunId = "published";
    const c = client(kayit); c.products.push({ id: "published", is_visible: true, fatura_kanit: {} });
    const reply = await faturaTaslakYanitiniHazirla(c.admin, "store", "demo", kayit);
    expect(m.save).not.toHaveBeenCalled(); expect(m.media).not.toHaveBeenCalled(); expect(m.catalog).not.toHaveBeenCalled();
    expect(reply).toMatchObject({ otomatikTaslakRaporu: { kaydedildi: 0 }, hazirlaniyor: false });
  });

  it("üç satırlık parçadan sonra aynı kayıtla devam eder; ikinci ürünü kopyalamaz", async () => {
    const c = client(invoice(4));
    const simdi = { an: Date.now() };
    const saat = vi.spyOn(Date, "now").mockImplementation(() => simdi.an);
    const asilKaydet = m.save.getMockImplementation()!;
    let kayitSayisi = 0;
    m.save.mockImplementation(async (...args) => {
      const sonuc = await asilKaydet(...args);
      kayitSayisi += 1;
      if (kayitSayisi === 3) simdi.an += 231_000;
      return sonuc;
    });
    const first = await faturaTaslakYanitiniHazirla(c.admin, "store", "demo", structuredClone(c.kayit));
    expect(first).toMatchObject({ hazirlaniyor: true, otomatikTaslakRaporu: { bekleyen: 1, kaydedildi: 3 } });
    const second = await faturaTaslakYanitiniHazirla(c.admin, "store", "demo", structuredClone(c.kayit));
    expect(second).toMatchObject({ hazirlaniyor: false, otomatikTaslakRaporu: { bekleyen: 0, kaydedildi: 4 } });
    expect(m.save).toHaveBeenCalledTimes(4);
    saat.mockRestore();
  });

  it("kalıcı yazma hatasında faturayı korur, otomatik tekrarı durdurur ve sebebi gösterir", async () => {
    const c = client(); m.save.mockRejectedValue(new Error("Kayıt başarısız."));
    const reply = await faturaTaslakYanitiniHazirla(c.admin, "store", "demo", structuredClone(c.kayit));
    expect(reply).toMatchObject({ tamam: true, hazirlaniyor: false, satirlar: [{ urunId: null }], taslakKayitUyarisi: "Kayıt başarısız." });
    expect(c.errorCode()).toBe("FATURA_TASLAKLARI_EKSIK");
  });

  it("fotoğraf aktarım hatasını kaydedilmiş taslağı silmeden sonraki açılışta da gösterir", async () => {
    const c = client();
    m.media.mockResolvedValue({ urunGorselleri: [], gorselDurumu: "aktarim-bekliyor", gorselKaynaklari: [] });
    await faturaTaslakYanitiniHazirla(c.admin, "store", "demo", structuredClone(c.kayit));
    const reopened = await faturaTaslakYanitiniHazirla(c.admin, "store", "demo", structuredClone(c.kayit));
    expect(m.save).toHaveBeenCalledTimes(1);
    expect(reopened.taslakKayitUyarisi).toContain("fotoğraf");
    expect(c.errorCode()).toBe("FATURA_TASLAKLARI_EKSIK");
  });

  it("aynı alışveriş olarak doğrulanmış belgeyi tekrar ürüne dönüştürmez", async () => {
    const c = client(invoice(), true);
    const reply = await faturaTaslakYanitiniHazirla(c.admin, "store", "demo", c.kayit);
    expect(m.save).not.toHaveBeenCalled(); expect(reply.hazirlaniyor).toBe(false);
  });

  it("başka mağaza için kayıt yapmaz", async () => {
    const c = client();
    const reply = await faturaTaslakYanitiniHazirla(c.admin, "other-store", "demo", c.kayit);
    expect(m.save).not.toHaveBeenCalled(); expect(reply.taslakKayitUyarisi).toContain("doğrulanamadı");
  });
});

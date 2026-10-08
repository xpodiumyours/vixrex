import { beforeEach, describe, expect, it, vi } from "vitest";
import { belgeParmakIzi, islemKaydet, satirKanitKayitlari, type IslemKaydiGirdisi } from "@/lib/faturaIslemKaydi";
import type { EslesmisFaturaSatiri } from "@/lib/faturaEslestir";
const m = vi.hoisted(() => ({ rpc: vi.fn(), from: vi.fn() }));
vi.mock("@/lib/supabaseAdmin", () => ({ getSupabaseAdmin: () => ({ from: m.from, rpc: m.rpc }) }));
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


beforeEach(() => {
  vi.clearAllMocks();
  m.from.mockImplementation(() => {
    const q = { select: () => q, eq: () => q, maybeSingle: async () => ({ data: { id: "magaza-1" }, error: null }) };
    return q;
  });
  m.rpc.mockResolvedValue({ data: { success: true, id: "is-1" }, error: null });
});
describe("fatura işlem kaydı tek transaction", () => {
  it("fotoğraf parmak izi içerikle sabittir", () => {
    expect(belgeParmakIzi(new Uint8Array([1, 2, 3]))).toBe(belgeParmakIzi(new Uint8Array([1, 2, 3])));
    expect(belgeParmakIzi(new Uint8Array([1, 2, 3]))).not.toBe(belgeParmakIzi(new Uint8Array([1, 2, 4])));
  });
  it("ham satır, adet ve alış bilgisi tek atomik istekle yazılır", async () => {
    const result = await islemKaydet(girdi([satir({})]));
    expect(result).toBe("is-1");
    expect(m.rpc).toHaveBeenCalledOnce();
    expect(m.rpc).toHaveBeenCalledWith("save_invoice_job", expect.objectContaining({
      p_store_id: "magaza-1",
      p_job: expect.objectContaining({ document_fingerprint: "a".repeat(64), supplier_name: "Seher Mensucat" }),
      p_lines: [expect.objectContaining({ line_index: 0, raw_line: "ELT1302 Elit Erkek 2 137,00 274,00", qty: 2, unit_price: 137, outcome: "eksik" })],
    }));
    expect(m.from).toHaveBeenCalledTimes(1);
    expect(m.from).toHaveBeenCalledWith("stores");
  });
  it("dört satır sonucu kaybolmadan aynı transaction'a gider", async () => {
    await islemKaydet(girdi([satir({sonuc:"kanitli"}),satir({sonuc:"eksik"}),satir({sonuc:"celiski"}),satir({sonuc:"iz-yok"})]));
    expect(m.rpc.mock.calls[0][1].p_lines.map((s: {outcome: string}) => s.outcome)).toEqual(["kanitli","eksik","celiski","iz-yok"]);
  });
  it("veritabanı satır veya kanıt yazım hatası başarılı işlem kimliği dönmez", async () => {
    m.rpc.mockResolvedValue({ data: null, error: { message: "evidence write failed" } });
    expect(await islemKaydet(girdi([satir({})]))).toBeNull();
    expect(m.from).toHaveBeenCalledTimes(1);
  });
  it("eksik veya başarısız RPC yanıtı başarılı sayılmaz", async () => {
    m.rpc.mockResolvedValue({ data: { success: false, id: "is-1" }, error: null });
    expect(await islemKaydet(girdi([satir({})]))).toBeNull();
    m.rpc.mockResolvedValue({ data: { success: true }, error: null });
    expect(await islemKaydet(girdi([satir({})]))).toBeNull();
  });
  it("katalog kanıtı ve izin belirsizliği doğru kayda hazırlanır", () => {
    const kayit = satirKanitKayitlari("line-1", satir({ sonuc: "kanitli", katalog: {
      firma: "Seher", kaynakFirma: "Seher", dayanak: "kod", izinDurumu: "bekliyor", resmiAd: "Resmî model",
      marka: "Seher", aciklama: "Ürün bilgisi", kaynak: "https://firma.example/ELT1302",
      gorseller: ["https://firma.example/model.jpg"], gorselAdaylari: ["https://firma.example/model.jpg"],
    }}), "site");
    expect(kayit.kanit).toContainEqual(expect.objectContaining({ field_name: "urun_adi", value_text: "Resmî model", strength: "strong" }));
    expect(kayit.gorsel).toEqual([expect.objectContaining({ usage_status: "unknown", line_id: "line-1" })]);
  });
});

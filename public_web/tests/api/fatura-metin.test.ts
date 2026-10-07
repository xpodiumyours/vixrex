import { NextRequest } from "next/server";
import { beforeEach, describe, expect, it, vi } from "vitest";
const m = vi.hoisted(() => ({ admin: vi.fn(), yetki: vi.fn(), rpc: vi.fn(), kaydet: vi.fn(), yukle: vi.fn(), bul: vi.fn(), aday: vi.fn() }));
vi.mock("@/lib/supabaseAdmin", () => ({ getSupabaseAdmin: m.admin }));
vi.mock("@/lib/faturaYetki", () => ({ sahipYetkisi: m.yetki }));
vi.mock("@/lib/rentDemoSecurity", () => ({ fingerprintClient: () => "ip", getClientIp: () => "ip" }));
vi.mock("@/lib/faturaIslemKaydi", () => ({ belgeParmakIzi: () => "hash", islemKaydet: m.kaydet, ayniAlisverisAdaylari: m.aday }));
vi.mock("@/lib/faturaIslemOku", () => ({ islemiYukle: m.yukle, parmakIzindenIslemBul: m.bul, islemYaniti: (kayit: unknown) => kayit }));
import { POST } from "@/app/api/fatura-metin/route";
const girdi = { slug: "dukkan", satirlar: [{ model: "123", ad: "Pamuklu ürün", adet: 2, alisBirimFiyat: "1.250,50", marka: "Üretici" }] };
const istek = (body: unknown) => new NextRequest("http://localhost/api/fatura-metin", { method: "POST", body: JSON.stringify(body) });
describe("metinden aynı fatura zinciri", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    m.admin.mockReturnValue({ rpc: m.rpc });
    m.yetki.mockResolvedValue({ tamam: true, slug: "dukkan", storeId: "store" });
    m.rpc.mockResolvedValue({ data: [{ allowed: true }], error: null });
    m.bul.mockResolvedValue(null);
    m.kaydet.mockResolvedValue("job");
    m.yukle.mockResolvedValue({ tamam: true, satirlar: [{ sahipDurumu: { satisFiyati: "1500" } }], islemKimligi: "job" });
    m.aday.mockResolvedValue([]);
  });
  it("okuyucu anahtarı olmadan kayıtlı kartı döndürür ve Türkçe fiyatı korur", async () => {
    const cevap = await POST(istek(girdi));
    expect(cevap.status).toBe(200);
    expect((await cevap.json()).satirlar[0].sahipDurumu.satisFiyati).toBe("1500");
    expect(m.kaydet.mock.calls[0][0].satirlar[0]).toMatchObject({
      alisBirimFiyat: 1250.5,
      marka: "Üretici",
      katalog: null,
      sonuc: "eksik",
    });
    expect(m.yukle).toHaveBeenCalledWith(expect.anything(), "store", "job");
    expect(m.rpc).toHaveBeenNthCalledWith(1, "consume_assistant_request", { p_client_key: "fatura_oku:dukkan", p_max_requests: 20, p_window_seconds: 3600 });
    expect(m.aday).toHaveBeenCalledWith({ slug: "dukkan", islemKimligi: "job", girdi: expect.objectContaining({ slug: "dukkan" }) });
  });
  it("yetkisiz mağazada eşleştirme ve kayıt yapmaz", async () => {
    m.yetki.mockResolvedValue({ tamam: false, durum: 401, hata: "Yetki yok" });
    expect((await POST(istek(girdi))).status).toBe(401);
    expect(m.kaydet).not.toHaveBeenCalled();
  });
  it("200 satır sınırında belgeyi kesip başarı sunmaz", async () => {
    expect((await POST(istek({ ...girdi, satirlar: Array(201).fill(girdi.satirlar[0]) }))).status).toBe(413);
    expect(m.kaydet).not.toHaveBeenCalled();
  });
  it("5 MB sınırını uygular", async () => {
    expect((await POST(istek({ slug: "dukkan", metin: "a".repeat(5 * 1024 * 1024) }))).status).toBe(413);
  });
  it("hız sınırı dolunca kayıt yapmaz", async () => {
    m.rpc.mockResolvedValue({ data: { allowed: false }, error: null });
    expect((await POST(istek(girdi))).status).toBe(429);
    expect(m.kaydet).not.toHaveBeenCalled();
  });
  it("atomik kayıt başarısızlığını başarı diye göstermez", async () => {
    m.kaydet.mockResolvedValue(null);
    expect((await POST(istek(girdi))).status).toBe(503);
  });
  it("kaydedilen işlem yeniden okunamazsa başarı döndürmez", async () => {
    m.yukle.mockResolvedValue(null);
    expect((await POST(istek(girdi))).status).toBe(503);
  });
  it("aynı belge kayıtlı sahip kararlarıyla açılır ve yeniden eşleştirilmez", async () => {
    m.bul.mockResolvedValue("job");
    const cevap = await POST(istek(girdi));
    expect(cevap.status).toBe(200);
    expect(m.kaydet).not.toHaveBeenCalled();
  });
});

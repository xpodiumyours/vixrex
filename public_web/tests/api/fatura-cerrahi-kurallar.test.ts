import { afterEach, describe, expect, it, vi } from "vitest";
import { firmaAlaniniKilitle, satirAramaCevabi } from "@/lib/faturaGoru";

afterEach(() => {
  vi.unstubAllEnvs();
});

function kaynakCevabi(degisiklik: Record<string, unknown> = {}) {
  return {
    status: "completed",
    usage: { server_tool_use: { web_fetch_requests: 1 } },
    output_text: JSON.stringify({
      eslesti: true,
      urun_adi: "Siyah Pamuk Atlet",
      aciklama: "Üreticinin siyah pamuklu atleti",
      kaynak_sayfa: "https://uretim.example/urun/atlet",
      gorsel_adresi: "https://cdn.example/atlet.jpg",
      kanit: "Markanın resmî ürün kaydında renk ve ürün adı yer alıyor.",
      eslesme_dayanagi: "ad-ve-ozellik",
      site_kodu: "",
      site_barkodu: "",
      site_markasi: "Elit",
      site_rengi: "Siyah",
      site_bedeni: "",
      fotograf_rengi_dogrulandi: true,
      ...degisiklik,
    }),
  };
}

describe("fatura kimlik ve üretici doğrulama kapısı", () => {
  const girdi = { alan: "uretim.example", model: "", barkod: "", ad: "Siyah Pamuk Atlet", marka: "Elit", varyant: "Siyah", beden: "" };

  it("isim ve tek genel özellik kesin ürün kanıtı değildir", () => {
    const eksik = kaynakCevabi({ site_rengi: "", fotograf_rengi_dogrulandi: false });
    expect(satirAramaCevabi({ ...girdi, varyant: "" }, eksik)).toBeNull();
  });

  it("kimlik kodu faturada varsa yalnız ad-varyant benzerliği yetmez", () => {
    expect(satirAramaCevabi({ ...girdi, model: "A-123" }, kaynakCevabi())).toBeNull();
  });

  it("kod çelişirse kanıtlı sayılmaz", () => {
    const satir = { ...girdi, model: "A-123" };
    expect(satirAramaCevabi(satir, kaynakCevabi({
      eslesme_dayanagi: "kod", site_kodu: "B-999",
    }))).toBeNull();
  });

  it("resmî sayfada kod uyuşuyorsa eşleşme geçebilir", () => {
    const satir = { ...girdi, model: "A-123" };
    expect(satirAramaCevabi(satir, kaynakCevabi({
      eslesme_dayanagi: "kod", site_kodu: "A-123",
    }))?.dayanak).toBe("kod");
  });

  it("kod yoksa aynı ad ile iki kaynak özelliği birlikte aranır", () => {
    expect(satirAramaCevabi(girdi, kaynakCevabi())?.dayanak).toBe("ad");
  });

  it("belgede yazan alan adı doğrulanmadan resmî üretici sayılmaz", async () => {
    vi.stubEnv("OPENROUTER_API_KEY", "");
    expect(await firmaAlaniniKilitle({
      belgedeYazan: "bayi.example", esnafIpucu: "toptanci.example",
      tedarikciAdi: "Üretici", vergiNo: "", adres: "",
    })).toBe("");
  });
});

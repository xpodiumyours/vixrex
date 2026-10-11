import { afterEach, describe, expect, it, vi } from "vitest";
import { satirAramaIstegi, satirAramaCevabi, satirSitesindeAra } from "@/lib/faturaGoru";

const urun = { alan: "uretici.example", model: "", ad: "", barkod: "8681128321677" };
const kart = { eslesti: true, urun_adi: "Ürün", kaynak_sayfa: "https://uretici.example/urun", eslesme_dayanagi: "barkod" };

afterEach(() => { vi.unstubAllGlobals(); vi.unstubAllEnvs(); });

describe("Luna araştırma verisi ve devam sınırı", () => {
  it("üretici sitesi ipucu olmadan da ürün barkodu veya adıyla araştırılır", () => {
    const barkod = satirAramaIstegi({ ...urun, alan: "" });
    const ad = satirAramaIstegi({ ...urun, alan: "", barkod: "", ad: "Pamuklu atlet 2 adet" });
    expect(barkod?.input).toContain(urun.barkod);
    expect(ad?.input).toContain("Pamuklu atlet 2 adet");
  });

  it.each([
    { status: "incomplete", output_text: JSON.stringify(kart) },
    { status: "completed", output_text: "{broken" },
    { status: "completed", output_text: "{}" },
  ])("yarım veya bozuk araştırma yok sonucuna çevrilmez", async (govde) => {
    vi.stubEnv("OPENROUTER_API_KEY", "test");
    vi.stubGlobal("fetch", async () => new Response(JSON.stringify(govde)));
    await expect(satirSitesindeAra(urun)).rejects.toThrow(/ARASTIRMA_/);
  });

  it("geçici HTTP hatası üretici bulunamadı sayılmaz", async () => {
    vi.stubEnv("OPENROUTER_API_KEY", "test");
    vi.stubGlobal("fetch", async () => new Response(null, { status: 503 }));
    await expect(satirSitesindeAra(urun)).rejects.toThrow("OKUYUCU_CEVAP_VERMEDI");
  });

  it("Luna'nın açık eşleşmedi kararı korunur", () => {
    expect(satirAramaCevabi(urun, { status: "completed", output_text: JSON.stringify({ eslesti: false }) })).toBeNull();
  });

  it("resmî teknik kimlik olmayan varyantların seçenekleri kararlı kimlikle korunur", () => {
    const secenekler = [{ key: "color", value: "Siyah" }, { key: "size", value: "L" }];
    const cevap = (options: typeof secenekler) => satirAramaCevabi(urun, { status: "completed", output_text: JSON.stringify({
      ...kart, urun_varyantlari: [{ id: "", secenekler: options, barkod: "", gorseller: [] }],
    }) })!.urunVaryantlari![0];
    expect(cevap(secenekler).secenekler).toEqual(secenekler);
    expect(cevap(secenekler).id).toMatch(/^luna-/);
    expect(cevap(secenekler).id).toBe(cevap([...secenekler].reverse()).id);
  });
});

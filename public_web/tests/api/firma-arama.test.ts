import { describe, expect, it, vi } from "vitest";

// Firma arama (kilitli kapsam): firmanın resmi sitesi internette aranır;
// bulunursa aynı keşif oradan yürür. Arama sonucu kalıcı saklanmaz;
// anahtar yoksa akış durmaz.

import { firmaSitesiniAra } from "@/lib/firmaArama";

function aramaYaniti(sonuclar: Array<{ url: string; title?: string }>) {
  return vi.fn(async () => ({
    ok: true,
    json: async () => ({ web: { results: sonuclar } }),
  })) as unknown as typeof fetch;
}

describe("firma resmi site arama", () => {
  it("anahtar yoksa arama kapalıdır, akış durmaz", async () => {
    const sonuc = await firmaSitesiniAra("Eti Gıda", { apiAnahtari: "" });

    expect(sonuc.durum).toBe("kapali");
  });

  it("firma adıyla uyumlu resmi alanı bulur", async () => {
    const sonuc = await firmaSitesiniAra("Eti Gıda Sanayi", {
      apiAnahtari: "test-anahtar",
      kimlik: { vergiNo: "1234567890", adres: "" },
      dogrula: { resolveHost: async () => ["8.8.8.8"] },
      fetcher: async (input: string) => {
        const adres = String(input);
        if (adres.includes("api.search.brave.com")) {
          return aramaYaniti([
            { url: "https://www.trendyol.com/eti-gida", title: "Trendyol Eti" },
            { url: "https://www.etigida.com.tr/kurumsal", title: "Eti Resmi Site" },
          ])("https://api.search.brave.com/res/v1/web/search");
        }
        return new Response("<html><title>Eti Gıda</title><body>Vergi No 1234567890</body></html>", {
          status: 200,
          headers: { "content-type": "text/html" },
        });
      },
    });

    expect(sonuc.durum).toBe("bulundu");
    if (sonuc.durum === "bulundu") {
      expect(sonuc.alan).toBe("etigida.com.tr");
    }
  });

  it("pazar yeri ve sosyal ağ adreslerini resmi site saymaz", async () => {
    const sonuc = await firmaSitesiniAra("Tutku Tuhafiye", {
      apiAnahtari: "test-anahtar",
      kimlik: { vergiNo: "1234567890", adres: "" },
      dogrula: { resolveHost: async () => ["8.8.8.8"] },
      fetcher: async (input: string) => {
        const adres = String(input);
        if (adres.includes("api.search.brave.com")) {
          return aramaYaniti([
            { url: "https://www.instagram.com/tutkutuhafiye", title: "Tutku Instagram" },
            { url: "https://tutkutuhafiye.com/urunler", title: "Tutku Tuhafiye" },
          ])("https://api.search.brave.com/res/v1/web/search");
        }
        return new Response("<html><title>Tutku Tuhafiye</title><body>Vergi No 1234567890</body></html>", {
          status: 200,
          headers: { "content-type": "text/html" },
        });
      },
    });

    expect(sonuc.durum).toBe("bulundu");
    if (sonuc.durum === "bulundu") {
      expect(sonuc.alan).toBe("tutkutuhafiye.com");
    }
  });

  it("alakasız alan adlarını eleyip bulunamadı döner", async () => {
    const sonuc = await firmaSitesiniAra("Berrak İç Giyim", {
      apiAnahtari: "test-anahtar",
      kimlik: { vergiNo: "1234567890", adres: "" },
      dogrula: { resolveHost: async () => ["8.8.8.8"] },
      fetcher: async (input: string) => {
        const adres = String(input);
        if (adres.includes("api.search.brave.com")) {
          return aramaYaniti([
            { url: "https://www.ornekpazar.com/magaza", title: "Pazar yeri" },
            { url: "https://www.baska-firma.com", title: "Başka firma" },
          ])("https://api.search.brave.com/res/v1/web/search");
        }
        return new Response("<html><title>Başka firma</title><body>Vergi No 9999999999</body></html>", {
          status: 200,
          headers: { "content-type": "text/html" },
        });
      },
    });

    expect(sonuc.durum).toBe("bulunamadi");
  });

  it("arama servisine ulaşılamazsa bulunamadı döner, hata fırlatmaz", async () => {
    const sonuc = await firmaSitesiniAra("Ülker Çikolata", {
      apiAnahtari: "test-anahtar",
      fetcher: (async () => {
        throw new Error("ağ yok");
      }) as unknown as typeof fetch,
    });

    expect(sonuc.durum).toBe("bulunamadi");
  });

  it("çok kısa firma adıyla arama yapılmaz", async () => {
    const sonuc = await firmaSitesiniAra("AB", { apiAnahtari: "test-anahtar" });

    expect(sonuc.durum).toBe("bulunamadi");
  });
});

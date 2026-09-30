import { describe, expect, it, vi } from "vitest";

// Firma arama (kilitli kapsam): havuz SADECE hızlı yoldur. Listede olmayan
// firmanın resmi sitesi internette aranır; bulunursa aynı keşif oradan yürür.
// Arama sonucu kalıcı saklanmaz; anahtar yoksa akış durmaz.

import { firmaSitesiniAra } from "@/lib/firmaArama";
import { faturaSatirlariniDijitalIzle } from "@/lib/faturaEslestir";

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
      fetcher: aramaYaniti([
        { url: "https://www.trendyol.com/eti-gida", title: "Trendyol Eti" },
        { url: "https://www.etigida.com.tr/kurumsal", title: "Eti Resmi Site" },
      ]),
    });

    expect(sonuc.durum).toBe("bulundu");
    if (sonuc.durum === "bulundu") {
      expect(sonuc.alan).toBe("etigida.com.tr");
    }
  });

  it("pazar yeri ve sosyal ağ adreslerini resmi site saymaz", async () => {
    const sonuc = await firmaSitesiniAra("Tutku Tuhafiye", {
      apiAnahtari: "test-anahtar",
      fetcher: aramaYaniti([
        { url: "https://www.instagram.com/tutkutuhafiye", title: "Tutku Instagram" },
        { url: "https://tutkutuhafiye.com/urunler", title: "Tutku Tuhafiye" },
      ]),
    });

    expect(sonuc.durum).toBe("bulundu");
    if (sonuc.durum === "bulundu") {
      expect(sonuc.alan).toBe("tutkutuhafiye.com");
    }
  });

  it("alakasız alan adlarını eleyip bulunamadı döner", async () => {
    const sonuc = await firmaSitesiniAra("Berrak İç Giyim", {
      apiAnahtari: "test-anahtar",
      fetcher: aramaYaniti([
        { url: "https://www.ornekpazar.com/magaza", title: "Pazar yeri" },
        { url: "https://www.baska-firma.com", title: "Başka firma" },
      ]),
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

  it("havuz-dışı ad Brave mock bulundu -> havuzda:false iz kurulur (köprü)", async () => {
    // Kilitli kapsam: havuz SADECE hızlı yoldur. Tutku Tuhafiye listede yoksa
    // adı aratılır; 2 jeton (tutku+tuhafiye) eşleşince aynı keşif oradan yürür.
    const brave = aramaYaniti([
      { url: "https://tutkutuhafiye.com/urunler", title: "Tutku Tuhafiye" },
    ]);
    const birlesik = (async (input: string, init?: RequestInit) => {
      if (typeof input === "string" && input.includes("api.search.brave.com")) {
        return brave(input, init);
      }
      return new Response("{}", { status: 404 });
    }) as unknown as typeof fetch;

    const sonuc = await faturaSatirlariniDijitalIzle(
      [
        {
          model: "",
          ad: "Bilinmeyen Ürün",
          barkod: "",
          varyant: "",
          beden: "",
          adet: 1,
          alisBirimFiyat: null,
          satirToplam: null,
          guven: 0.9,
        },
      ],
      "Tutku Tuhafiye",
      "",
      {
        fetcher: birlesik,
        resolveHost: async () => ["8.8.8.8"],
        firmaArama: { apiAnahtari: "test-anahtar", fetcher: birlesik },
      },
    );

    expect(sonuc.tedarikciIz?.havuzda).toBe(false);
    expect(sonuc.tedarikciIz?.alan).toBe("tutkutuhafiye.com");
    expect(sonuc.tedarikciIz?.kaynak).toBe("https://tutkutuhafiye.com");
  });

  it("anahtarsız kapalı yol dürüst mesaj verir, akışı durdurmaz", async () => {
    const kapali = await firmaSitesiniAra("Tutku Tuhafiye", { apiAnahtari: "" });

    expect(kapali.durum).toBe("kapali");
    if (kapali.durum === "kapali") {
      expect(kapali.sebep).toBe(
        "Arama servisi bağlı değil; firmanın sitesini yazarak devam edilebilir.",
      );
    }

    const sonuc = await faturaSatirlariniDijitalIzle(
      [
        {
          model: "",
          ad: "Bilinmeyen Ürün",
          barkod: "",
          varyant: "",
          beden: "",
          adet: 1,
          alisBirimFiyat: null,
          satirToplam: null,
          guven: 0.9,
        },
      ],
      "Tutku Tuhafiye",
      "",
      {
        resolveHost: async () => ["8.8.8.8"],
        firmaArama: { apiAnahtari: "" },
      },
    );

    expect(sonuc.tedarikciIz).toBeNull();
  });
});

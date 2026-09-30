import { describe, expect, it, vi } from "vitest";
import { siteFirmayaAitMi } from "@/lib/firmaDogrula";
import { firmaSitesiniAra } from "@/lib/firmaArama";

const resolveHost = async () => ["8.8.8.8"];

function siteFetcher(sayfalar: Record<string, string>) {
  return async (input: string) => {
    const yol = new URL(input).pathname;
    const html = sayfalar[yol];
    if (html === undefined) return new Response("yok", { status: 404 });
    return new Response(html, { status: 200, headers: { "content-type": "text/html" } });
  };
}

const ISILAY_SAYFASI = `
  <html><head><title>Işılay Tekstil | Resmi Site</title>
  <meta property="og:site_name" content="Işılay Tekstil"></head>
  <body>
    <a href="https://www.instagram.com/isilaytekstil">Instagram</a>
    <a href="/dosyalar/urun-katalog-2026.pdf">Katalog</a>
    <p>Vergi No: 123 456 7890 — Merter Mahallesi Fabrika Sokak, Zeytinburnu</p>
  </body></html>`;

describe("resmi site firma kimliği doğrulaması", () => {
  it("vergi numarası sitede geçiyorsa güçlü doğrulama ve bağlı hesaplar döner", async () => {
    const sonuc = await siteFirmayaAitMi(
      "isilaytekstil.com",
      { ad: "Işılay Tekstil Sanayi", vergiNo: "1234567890", adres: "" },
      { fetcher: siteFetcher({ "/": ISILAY_SAYFASI }), resolveHost },
    );

    expect(sonuc.guc).toBe("guclu");
    expect(sonuc.kanitlar).toContain("vergi_no");
    expect(sonuc.bagliHesaplar).toContain("https://instagram.com/isilaytekstil");
    expect(sonuc.katalogDosyalari).toEqual(["https://isilaytekstil.com/dosyalar/urun-katalog-2026.pdf"]);
  });

  it("alan adı uysa bile faturadaki vergi no ve adresle çelişen site reddedilir", async () => {
    const baskaFirma = `<html><head><title>Baska Sirket</title></head><body>Vergi No: 9999999999 Ankara Cankaya</body></html>`;
    const sonuc = await siteFirmayaAitMi(
      "isilaytekstil.com",
      { ad: "Işılay Tekstil", vergiNo: "1234567890", adres: "Merter Zeytinburnu İstanbul" },
      { fetcher: siteFetcher({ "/": baskaFirma }), resolveHost },
    );

    expect(sonuc.guc).toBe("celisiyor");
  });

  it("faturada vergi no ve adres yoksa çelişki kurulamaz, zayıf sayılır", async () => {
    const sonuc = await siteFirmayaAitMi(
      "isilaytekstil.com",
      { ad: "Işılay Tekstil", vergiNo: "", adres: "" },
      { fetcher: siteFetcher({ "/": "<html><title>Anasayfa</title></html>" }), resolveHost },
    );

    expect(sonuc.guc).toBe("zayif");
  });

  it("siteye hiç ulaşılamazsa 'doğrulanamadı' denir, çelişiyor denmez", async () => {
    const sonuc = await siteFirmayaAitMi(
      "isilaytekstil.com",
      { ad: "Işılay Tekstil", vergiNo: "1234567890", adres: "" },
      {
        fetcher: async () => {
          throw new Error("ag");
        },
        resolveHost,
      },
    );

    expect(sonuc.guc).toBe("dogrulanamadi");
  });

  it("aramada çelişen ilk site atlanır, kimliği tutan ikinci site seçilir", async () => {
    const arama = vi.fn(async () => ({
      ok: true,
      json: async () => ({
        web: {
          results: [
            { url: "https://isilay-tekstil-outlet.com/" },
            { url: "https://isilaytekstil.com/" },
          ],
        },
      }),
    })) as unknown as typeof fetch;
    const siteler: Record<string, Record<string, string>> = {
      "isilay-tekstil-outlet.com": { "/": "<html><title>Outlet</title><body>Vergi No 5555555555</body></html>" },
      "isilaytekstil.com": { "/": ISILAY_SAYFASI },
    };

    const sonuc = await firmaSitesiniAra("Işılay Tekstil", {
      apiAnahtari: "anahtar",
      fetcher: arama,
      kimlik: { vergiNo: "1234567890", adres: "" },
      dogrula: {
        fetcher: async (input: string) => {
          const url = new URL(input);
          const html = siteler[url.hostname]?.[url.pathname];
          return html === undefined
            ? new Response("yok", { status: 404 })
            : new Response(html, { status: 200 });
        },
        resolveHost,
      },
    });

    expect(sonuc.durum).toBe("bulundu");
    if (sonuc.durum === "bulundu") {
      expect(sonuc.alan).toBe("isilaytekstil.com");
      expect(sonuc.dogrulama?.guc).toBe("guclu");
    }
  });
});

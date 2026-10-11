import { describe, expect, it } from "vitest";
import sharp from "sharp";
import { satirAramaIstegi, CIKTI_TOKEN_TAVANI } from "@/lib/faturaGoru";
import { kaynakGorseliniDogrula, kaynakGorselleriniHazirla } from "@/lib/faturaGorsel";

const resolveHost = async () => ["8.8.8.8"];
const kaynak = "https://firma.example/foto";

describe("Luna'nın kartına kalan aktarım engelleri", () => {
  it.each(["apex.com", "phoenix.com", "vixrex.com"])("%s alanı araştırmada zorunlu filtre olmaz", (alan) => {
    const istek = satirAramaIstegi({ alan, model: "M1", ad: "Ürün", barkod: "" });
    expect(istek?.max_output_tokens).toBe(CIKTI_TOKEN_TAVANI);
    expect(istek?.tools.every((tool) => !("allowed_domains" in tool.parameters))).toBe(true);
    expect(istek?.input).toContain(alan);
  });

  it.each(["avif", "svg"])("%s kaynağı gerçek webp dosyası olarak aktarılır", async (format) => {
    const bayt = format === "svg"
      ? Buffer.from('<svg xmlns="http://www.w3.org/2000/svg" width="240" height="180"><rect width="240" height="180" fill="red"/></svg>')
      : await sharp({ create: { width: 240, height: 180, channels: 3, background: "red" } }).avif().toBuffer();
    const sonuc = await kaynakGorseliniDogrula(kaynak, {
      fetcher: async () => new Response(new Uint8Array(bayt)), resolveHost,
    });
    expect(sonuc.tamam).toBe(true);
    expect(sonuc.tur).toBe("image/webp");
    expect((await sharp(Buffer.from(sonuc.bayt!)).metadata()).format).toBe("webp");
  });

  it("güvenli CDN yönlendirmesini izler ve ilk kaynakla kalıcı kayda taşır", async () => {
    const hedef = "https://cdn.example/urun.jpg";
    const bayt = await sharp({ create: { width: 240, height: 180, channels: 3, background: "red" } }).jpeg().toBuffer();
    const indirilen: string[] = [];
    const sonuc = await kaynakGorselleriniHazirla({
      slug: "deneme", kaynakSayfa: "https://firma.example/urun", adaylar: [kaynak],
      bagimliliklar: {
        resolveHost, fetcher: async (adres) => {
          indirilen.push(adres);
          return adres === kaynak
            ? new Response(null, { status: 302, headers: { location: hedef } })
            : new Response(new Uint8Array(bayt));
        },
      },
      admin: { storage: { from: () => ({ upload: async () => ({ error: null }),
        getPublicUrl: () => ({ data: { publicUrl: "https://depo.example/urun.jpg" } }) }) } },
    });
    expect(indirilen).toEqual([kaynak, hedef]);
    expect(sonuc.gorseller[0]).toMatchObject({ kaynakGorsel: kaynak, url: "https://depo.example/urun.jpg" });
  });

  it.each(["https://127.0.0.1/secret", "http://cdn.example/urun.jpg", "https://user:pass@cdn.example/urun.jpg"])(
    "yönlendirmeyle güvenli ağ sınırı aşılamaz: %s", async (hedef) => {
      let cagrilar = 0;
      const sonuc = await kaynakGorseliniDogrula(kaynak, {
        resolveHost: async (host) => host === "127.0.0.1" ? ["127.0.0.1"] : ["8.8.8.8"],
        fetcher: async () => { cagrilar++; return new Response(null, { status: 302, headers: { location: hedef } }); },
      });
      expect(sonuc.tamam).toBe(false);
      expect(cagrilar).toBe(1);
    },
  );

  it("yönlendirme döngüsü sonraki isteği başlatmadan durur", async () => {
    let cagrilar = 0;
    const sonuc = await kaynakGorseliniDogrula(kaynak, {
      resolveHost, fetcher: async () => {
        cagrilar++;
        return new Response(null, { status: 302, headers: { location: "/foto" } });
      },
    });
    expect(sonuc.tamam).toBe(false);
    expect(cagrilar).toBe(1);
  });
});

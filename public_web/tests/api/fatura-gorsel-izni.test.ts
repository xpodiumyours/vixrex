import type { SupabaseClient } from "@supabase/supabase-js";
import { describe, expect, it } from "vitest";
import { satiriDogrula } from "@/lib/faturaUrunBaglantisi";

const ISLEM = "11111111-1111-4111-8111-111111111111";

const DENIED = "https://firma.example/izin-yok.jpg";
const UNKNOWN = "https://firma.example/izin-bekliyor.jpg";
const VERIFIED = "https://firma.example/izin-var.jpg";
const DURUM_YOK = "https://firma.example/durum-yazilmamis.jpg";

interface GorselKaydi {
  image_url: string;
  usage_status: string | null;
}

/**
 * PostgREST davranışını taklit eden sahte admin istemcisi: `select(...)` ile
 * istenen alanlar dışında sütun DÖNMEZ. Yani `usage_status` okunmuyorsa
 * kayıtlar `usage_status` alanı olmadan döner — testin kodu okumadığı an
 * hemen görünür.
 */
function adminMock(gorseller: GorselKaydi[]): SupabaseClient {
  const from = (tablo: string) => {
    let projeksiyon = "";
    const zincir: Record<string, unknown> = {};
    zincir.select = (alanlar: string) => {
      projeksiyon = alanlar;
      return zincir;
    };
    zincir.eq = () => zincir;
    zincir.maybeSingle = async () =>
      tablo === "invoice_jobs"
        ? { data: { id: ISLEM }, error: null }
        : { data: { id: "satir-1", outcome: "kanitli", product_id: null }, error: null };
    zincir.then = (basari: (deger: unknown) => unknown) => {
      const veri = projeksiyon.includes("usage_status")
        ? gorseller
        : gorseller.map((kayit) => ({ image_url: kayit.image_url }));
      return Promise.resolve({ data: veri, error: null }).then(basari);
    };
    return zincir;
  };
  return { from } as unknown as SupabaseClient;
}

function dogrula(gorseller: GorselKaydi[]) {
  return satiriDogrula(adminMock(gorseller), "store-1", { islemKimligi: ISLEM, satirSirasi: 0 }, "kanitli");
}

describe("fatura görseli kullanım izni", () => {
  it("usage_status='denied' görsel izinli kümesine girmez", async () => {
    const satir = await dogrula([
      { image_url: DENIED, usage_status: "denied" },
      { image_url: VERIFIED, usage_status: "verified_supplier_permission" },
    ]);

    expect(satir?.izinliGorseller.has(DENIED)).toBe(false);
    expect(satir?.izinliGorseller.has(VERIFIED)).toBe(true);
  });

  it("usage_status='unknown' görsel kümede kalır: izin turu sonra yürür, kart yine de yayınlanır", async () => {
    const satir = await dogrula([{ image_url: UNKNOWN, usage_status: "unknown" }]);

    expect(satir?.izinliGorseller.has(UNKNOWN)).toBe(true);
  });

  it("doğrulanmış tedarikçi izni kümede kalır", async () => {
    const satir = await dogrula([{ image_url: VERIFIED, usage_status: "verified_supplier_permission" }]);

    expect(satir?.izinliGorseller.has(VERIFIED)).toBe(true);
  });

  it("usage_status yazılmamış (NULL) satır 'denied' sayılmaz, kümede kalır", async () => {
    const satir = await dogrula([{ image_url: DURUM_YOK, usage_status: null }]);

    expect(satir?.izinliGorseller.has(DURUM_YOK)).toBe(true);
  });

  it("esnafın kendi fotoğrafı ve diğer izinli durumlar elenmez", async () => {
    const satir = await dogrula([
      { image_url: "https://magaza.example/esnaf.jpg", usage_status: "merchant_owned_media" },
      { image_url: "https://firma.example/beyan.jpg", usage_status: "merchant_attestation" },
      { image_url: "https://firma.example/feed.jpg", usage_status: "verified_feed_terms" },
      { image_url: DENIED, usage_status: "denied" },
    ]);

    expect([...(satir?.izinliGorseller ?? [])].sort()).toEqual(
      [
        "https://firma.example/beyan.jpg",
        "https://firma.example/feed.jpg",
        "https://magaza.example/esnaf.jpg",
      ].sort(),
    );
  });
});

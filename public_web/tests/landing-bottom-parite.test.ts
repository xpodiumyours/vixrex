import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const oku = (relativePath: string) =>
  readFileSync(resolve(__dirname, relativePath), "utf-8");

describe("Landing alt çağrı paritesi", () => {
  const flutterCta = oku("../../lib/widgets/landing/landing_bottom_cta.dart");
  const webCta = oku("../src/components/landing/BottomCta.tsx");

  it("başlık, alt metin ve buton yazısı iki tarafta aynıdır", () => {
    expect(flutterCta).toContain("İşletmenizi tek linkte müşterilerinizle buluşturun");
    expect(webCta).toContain("İşletmenizi tek linkte müşterilerinizle buluşturun");
    expect(flutterCta).toContain("QR kodunu ve WhatsApp iletişimini");
    expect(webCta).toContain("QR kodunu ve WhatsApp iletişimini");
    expect(flutterCta).toContain("Vixrex Oluştur");
    expect(webCta).toContain("Vixrex Oluştur");
  });

  it("kabuk ve başlık ölçüleri Flutter ile aynıdır", () => {
    expect(flutterCta).toContain("vertical: 88");
    expect(webCta).toContain("py-[88px]");
    expect(flutterCta).toContain("maxWidth: 800");
    expect(webCta).toContain("max-w-[800px]");
    expect(flutterCta).toContain("fontSize: 36");
    expect(webCta).toContain("text-[36px]");
    expect(flutterCta).toContain("height: 1.2");
    expect(webCta).toContain("leading-[1.2]");
  });

  it("buton geometrisi Flutter ile aynıdır", () => {
    expect(flutterCta).toContain("horizontal: 40");
    expect(flutterCta).toContain("vertical: 24");
    expect(webCta).toContain("px-10 py-6");
    expect(flutterCta).toContain("BorderRadius.circular(24)");
    expect(webCta).toContain("rounded-3xl");
    expect(flutterCta).toContain("fontSize: 18");
    expect(webCta).toContain("text-[18px]");
  });

  it("metin aralıkları Flutter ile aynıdır", () => {
    expect(flutterCta).toContain("height: 24");
    expect(webCta).toContain("mt-6");
    expect(flutterCta).toContain("height: 48");
    expect(webCta).toContain("mt-12");
  });

  it("bilinçli sapmalar belgeli kalır", () => {
    // Gradient: web 3 duraklı, Flutter 2 duraklı — dosyada gerekçesiyle belgeli.
    expect(webCta).toContain("via-lp-turquoise-surface");
    // Alt metin rengi: okunabilirlik için text-alt — dosyada gerekçesiyle belgeli.
    expect(webCta).toContain("text-lp-text-alt");
  });
});

describe("Landing altbilgi paritesi", () => {
  const flutterCta = oku("../../lib/widgets/landing/landing_bottom_cta.dart");
  const webFooter = oku("../src/components/site/SiteFooter.tsx");

  it("marka bloğu iki tarafta aynıdır", () => {
    expect(flutterCta).toContain("VIXREX");
    expect(webFooter).toContain("VIXREX");
    expect(flutterCta).toContain("letterSpacing: 8");
    expect(webFooter).toContain("tracking-[8px]");
    expect(flutterCta).toContain("fontSize: 16");
    expect(webFooter).toContain("text-[16px]");
    expect(flutterCta).toContain("paylaşılabilir dijital vitrini");
    expect(webFooter).toContain("dijital vitrini");
    expect(flutterCta).toContain("fontSize: 14");
    expect(webFooter).toContain("text-[14px]");
  });

  it("altbilgi ölçüleri Flutter ile aynıdır", () => {
    expect(flutterCta).toContain("vertical: 60");
    expect(webFooter).toContain("py-[60px]");
    expect(flutterCta).toContain("spacing: 8");
    expect(webFooter).toContain("gap-2");
    expect(flutterCta).toContain("fontSize: 13");
    expect(webFooter).toContain("text-[13px]");
    expect(flutterCta).toContain("horizontal: 12");
    expect(flutterCta).toContain("vertical: 8");
    expect(webFooter).toContain("px-3 py-2");
  });

  it("yasal bağlantılar iki tarafta aynıdır", () => {
    expect(flutterCta).toContain("KVKK ve Gizlilik Politikası");
    expect(webFooter).toContain("KVKK ve Gizlilik Politikas");
    expect(flutterCta).toContain("Kullanım Şartları");
    expect(webFooter).toContain("/legal/terms");
  });

  it("veri silme bağlantısı bilinçli dışarıda tutulur", () => {
    // /data-deletion dizini 404 — kırık bağlantı eklenmez (SiteFooter açıklamasına bak).
    // Sayfa açılınca bu test bilinçli güncellenir.
    expect(webFooter).not.toContain('href="/data-deletion"');
  });
});

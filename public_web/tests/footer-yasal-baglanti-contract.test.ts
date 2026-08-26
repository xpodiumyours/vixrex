import { existsSync, readFileSync } from "fs";
import { resolve } from "path";
import { describe, expect, it } from "vitest";

const footer = readFileSync(
  resolve(__dirname, "../src/components/site/SiteFooter.tsx"),
  "utf-8"
);
const siteLayout = readFileSync(
  resolve(__dirname, "../src/app/(site)/layout.tsx"),
  "utf-8"
);
const rootLayout = readFileSync(
  resolve(__dirname, "../src/app/layout.tsx"),
  "utf-8"
);

/**
 * #346 — yasal sayfalara sitenin hiçbir yerinden bağlantı yoktu.
 *
 * Sayfalar yayındaydı ama ne kullanıcı ne de arama motoru onlara
 * ulaşabiliyordu: iç bağlantı olmayan sayfa, pratikte olmayan sayfadır.
 *
 * Ayrıca burada bir tuzak kilitleniyor: Flutter altbilgisi `/terms`
 * adresine bağlanıyor ama public_web'de öyle bir rota YOK — doğrusu
 * `/legal/terms` (src/app/legal/[type]).
 */
describe("altbilgi yasal bağlantıları (#346)", () => {
  it("Gizlilik ve Kullanım Şartları bağlantıları var", () => {
    expect(footer).toContain('href="/privacy"');
    expect(footer).toContain('href="/legal/terms"');
  });

  it("var olmayan /terms rotasına bağlanmaz", () => {
    expect(footer).not.toContain('href="/terms"');
    expect(existsSync(resolve(__dirname, "../src/app/terms"))).toBe(false);
  });

  it("kırık /data-deletion bağlantısı eklenmez", () => {
    // Yalnız /data-deletion/status/[code] var; dizinin kendisi 404.
    // Sayfa açılınca bu iddia ters çevrilip bağlantı eklenmeli.
    expect(footer).not.toContain('href="/data-deletion"');
    expect(
      existsSync(resolve(__dirname, "../src/app/data-deletion/page.tsx"))
    ).toBe(false);
  });

  it("başlık/altbilgi yalnız (site) grubunda, vitrin sayfalarında değil", () => {
    expect(siteLayout).toContain("SiteHeader");
    expect(siteLayout).toContain("SiteFooter");
    expect(rootLayout).not.toContain("SiteHeader");
    expect(rootLayout).not.toContain("SiteFooter");
  });
});

import { readFileSync } from "fs";
import { resolve } from "path";
import { describe, expect, it } from "vitest";

const viewSource = readFileSync(
  resolve(__dirname, "../src/app/v/[slug]/VitrinProfileView.tsx"),
  "utf-8"
);

const ctaBlock = viewSource.slice(
  viewSource.indexOf('id="kirala"'),
  viewSource.indexOf("===== FOOTER =====")
);

/**
 * Demo vitrindeki "Bu vitrini kirala" CTA'sı. Casper (2026-08-14):
 * "şimdilik ücretsiz kalsın, ödeme altyapısı bağlanmadı" — buton daha
 * önce hiç çalışan bir akışa bağlı değildi (getAppUrl(), genel uygulama
 * sayfası) ama "499 TL/ay" yazan bir fiyat gösteriyordu. Bu, gerçekte
 * çalışmayan bir vaaddi.
 *
 * 2026-08-15 (güvenlik açığı kapatılırken): CTA artık doğrudan
 * /api/rent-demo'ya değil, güvenli köprü sayfası /rent-demo'ya gidiyor —
 * orası reCAPTCHA doğrulamasını yapıp asıl POST'u gönderiyor (bkz.
 * app/rent-demo/page.tsx, app/api/rent-demo/route.ts).
 */
describe("demo vitrin 'Bu vitrini kirala' CTA — ücretsiz, güvenli köprü sayfasına bağlı", () => {
  it("güvenli köprü sayfasına (/rent-demo) bağlanır, doğrudan API'ye veya getAppUrl()'e değil", () => {
    expect(ctaBlock).toContain("/rent-demo?slug=");
    expect(ctaBlock).not.toContain("/api/rent-demo?slug=");
    expect(ctaBlock).not.toContain("getAppUrl()");
  });

  it("sahte fiyat (499 TL/ay) artık gösterilmiyor", () => {
    expect(ctaBlock).not.toContain("499 TL");
    expect(ctaBlock).not.toContain("+ KDV");
  });

  it("dürüst 'şimdilik ücretsiz' mesajı var", () => {
    expect(ctaBlock).toContain("Şimdilik ücretsiz");
  });
});

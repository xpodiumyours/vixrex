import { readFileSync } from "fs";
import { resolve } from "path";
import { describe, expect, it } from "vitest";
import { AYLIK_PREMIUM_BEDEL } from "@/lib/fiyatlandirma";

const viewSource = readFileSync(
  resolve(__dirname, "../src/app/v/[slug]/VitrinProfileView.tsx"),
  "utf-8"
);

const ctaBlock = viewSource.slice(
  viewSource.indexOf('id="kirala"'),
  viewSource.indexOf("===== FOOTER =====")
);

/**
 * Demo vitrindeki "Bu vitrini kirala" CTA'sı. 2026-08-14'teki geçici
 * karar ("şimdilik ücretsiz kalsın, ödeme altyapısı bağlanmadı") yerini
 * fiyat modeline bıraktı (spec 2026-08-17): 14 gün ücretsiz deneme,
 * sonra aylık 299 TL. Buton daha önce hiç çalışan bir akışa bağlı
 * değildi (getAppUrl(), genel uygulama sayfası) ve "499 TL/ay" yazan
 * bir fiyat gösteriyordu — gerçekte çalışmayan bir vaat.
 *
 * 2026-08-15 (güvenlik açığı kapatılırken): CTA artık doğrudan
 * /api/rent-demo'ya değil, güvenli köprü sayfası /rent-demo'ya gidiyor —
 * orası reCAPTCHA doğrulamasını yapıp asıl POST'u gönderiyor (bkz.
 * app/rent-demo/page.tsx, app/api/rent-demo/route.ts).
 */
describe("demo vitrin 'Bu vitrini kirala' CTA — Aylık 299 TL, 14 gün deneme, güvenli köprü", () => {
  it("güvenli köprü sayfasına (/rent-demo) bağlanır, doğrudan API'ye veya getAppUrl()'e değil", () => {
    expect(ctaBlock).toContain("/rent-demo?slug=");
    expect(ctaBlock).not.toContain("/api/rent-demo?slug=");
    expect(ctaBlock).not.toContain("getAppUrl()");
  });

  it("sahte fiyat (499 TL/ay) gösterilmiyor", () => {
    expect(ctaBlock).not.toContain("499 TL");
    expect(ctaBlock).not.toContain("+ KDV");
  });

  it("dürüst fiyat bilgisi var: tek kaynaktan gelen aylık bedel + 'İlk 14 gün ücretsiz deneme'", () => {
    expect(AYLIK_PREMIUM_BEDEL).toBe("Aylık 299 TL");
    expect(ctaBlock).toContain("{AYLIK_PREMIUM_BEDEL}");
    expect(ctaBlock).toContain("İlk 14 gün ücretsiz deneme");
  });

  it("vitrindeki fiyatların örnek ürün fiyatı olduğunu söyler", () => {
    expect(ctaBlock).toContain("örnek ürün fiyatlarıdır");
  });
});

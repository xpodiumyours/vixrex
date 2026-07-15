import { describe, it, expect } from "vitest";
import { readFileSync } from "fs";
import { resolve } from "path";

/**
 * Sözleşme testi: Public kök navigasyonu.
 *
 * - `/` kök isteği (`/?_rsc=...` dahil) 307 ile app hosta redirect eder.
 * - `_rsc` istisnası (missing) bulunmamalıdır; redirect tüm query değerlerine uygulanır.
 * - `/v/:slug` rotası Next.js tarafından serve edilir; redirect'e yakalanmaz.
 * - Sayfadaki kök bağlantısı `<a href="/">` (tam sayfa navigasyon) olmalıdır.
 */

const nextConfigPath = resolve(__dirname, "../../next.config.ts");
const configSource = readFileSync(nextConfigPath, "utf-8");

const pagePath = resolve(__dirname, "../../src/app/v/[slug]/page.tsx");
const pageSource = readFileSync(pagePath, "utf-8");

describe("Public kök navigasyon sözleşmesi", () => {
  it("next.config.ts redirect config'i barındırır", () => {
    expect(configSource).toContain("redirects");
    expect(configSource).toContain('source: "/"');
  });

  it("redirect hedefi getAppUrl() fonksiyonunu kullanır", () => {
    expect(configSource).toContain("getAppUrl()");
  });

  it("permanent: false kullanır (307 geçici redirect)", () => {
    expect(configSource).toContain("permanent: false");
  });

  it("_rsc missing istisnası yoktur — kök redirect tüm sorgulara uygulanır", () => {
    expect(configSource).not.toContain("_rsc");
    expect(configSource).not.toContain("missing");
  });

  it("sayfadaki kök bağlantısı <a href=\"/\"> tam sayfa navigasyonudur", () => {
    expect(pageSource).toContain('<a href="/"');
    expect(pageSource).not.toContain('<Link href="/"');
  });
});

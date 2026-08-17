import { describe, it, expect } from "vitest";
import { readFileSync } from "fs";
import { resolve } from "path";

/**
 * Güvenlik başlıkları sözleşmesi (2026-08-15 taraması: CSP eksikti).
 * Sıkı/nonce'lı CSP DEĞİL — savunma katmanı. Amaç: rastgele üçüncü parti
 * script/iframe enjeksiyonuna karşı temel koruma.
 */

const configSource = readFileSync(
  resolve(__dirname, "../next.config.ts"),
  "utf-8"
);

describe("Content-Security-Policy — mevcut", () => {
  it("securityHeaders içinde Content-Security-Policy anahtarı var", () => {
    expect(configSource).toContain("Content-Security-Policy");
  });

  it("frame-ancestors 'none' — clickjacking'e karşı (X-Frame-Options'ın CSP karşılığı)", () => {
    expect(configSource).toContain("frame-ancestors 'none'");
  });

  it("gerçekten kullanılan üçüncü parti kaynaklar izinli: reCAPTCHA + GA4", () => {
    expect(configSource).toContain("https://www.google.com");
    expect(configSource).toContain("https://www.gstatic.com");
    expect(configSource).toContain("https://www.googletagmanager.com");
  });

  it("Supabase'e connect-src'ten izin var (RPC/storage çağrıları)", () => {
    expect(configSource).toContain("https://*.supabase.co");
  });

  it("Google Fonts'a izin var — globals.css'teki @import gerçekten kullanılıyor (Outfit + Instrument Serif)", () => {
    expect(configSource).toContain("https://fonts.googleapis.com");
    expect(configSource).toContain("https://fonts.gstatic.com");
  });

  it("img-src remotePatterns ile aynı genişlikte (** host) — çelişmez", () => {
    expect(configSource).toContain("img-src * data: blob:");
  });

  it("form-action 'self' — /rent-demo köprü sayfasının POST'u dahil kendi origin'ine kısıtlı", () => {
    expect(configSource).toContain("form-action 'self'");
  });
});

describe("CI — secret sızıntı taraması (2026-08-15 taraması: eksikti)", () => {
  const ciSource = readFileSync(
    resolve(__dirname, "../../.github/workflows/ci.yml"),
    "utf-8"
  );

  it("gitleaks adımı her PR/push'ta çalışır (needs/if koşulu yok — her zaman)", () => {
    expect(ciSource).toContain("gitleaks/gitleaks-action");
  });

  it("secret-tarama job'ı changes job'ına bağımlı değil — yüzey sınıflandırmasından bağımsız her zaman koşar", () => {
    const jobBlock = ciSource.slice(
      ciSource.indexOf("secret-tarama:"),
      ciSource.indexOf("changes:")
    );
    expect(jobBlock).not.toContain("needs:");
  });
});

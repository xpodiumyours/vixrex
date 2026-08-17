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

  it("img-src AÇIK allowlist — wildcard '*' YOK (2026-08-16 sıkılaştırma)", () => {
    // img-src artık her host'a izin vermiyor; yalnız gerçekten kullanılan
    // kaynaklar (supabase storage, instagram CDN, recaptcha/turnstile/GA).
    expect(configSource).not.toMatch(/img-src\s+\*/);
    expect(configSource).toContain(
      "img-src 'self' data: blob: https://*.supabase.co"
    );
    expect(configSource).toContain("https://*.cdninstagram.com");
  });

  it("form-action 'self' — /rent-demo köprü sayfasının POST'u dahil kendi origin'ine kısıtlı", () => {
    expect(configSource).toContain("form-action 'self'");
  });
});

describe("Content-Security-Policy — 2026-08-16 sıkılaştırma (kanıta dayalı)", () => {
  const cspSource = configSource;

  it("'unsafe-eval' prod CSP'sinde YOK — yalnız dev koşuluna bırakıldı", () => {
    // Üretim CSP'si (NODE_ENV!=='development') 'unsafe-eval' içermez.
    // Statik kaynakta: yorumları ve isDev koşulunu (dev'e bırakılan tek
    // gerçekleşme) çıkardığımızda geriye 'unsafe-eval' kalmamalı.
    const withoutComments = configSource
      .split("\n")
      .filter((line) => !line.trim().startsWith("//"))
      .join("\n");
    const withoutDevGuard = withoutComments.replace(
      /\(isDev \? "[^"]*'unsafe-eval'[^"]*" : ""\)/,
      ""
    );
    expect(withoutDevGuard).not.toContain("'unsafe-eval'");
  });

  it("Cloudflare Turnstile script/frame hostu (challenges.cloudflare.com) izinli", () => {
    expect(cspSource).toContain("https://challenges.cloudflare.com");
  });

  it("Instagram medya hostu (cdninstagram.com) img-src'te izinli", () => {
    expect(cspSource).toContain("https://*.cdninstagram.com");
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

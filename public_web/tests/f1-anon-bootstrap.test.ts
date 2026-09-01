import { readFileSync } from "fs";
import { resolve } from "path";
import { describe, expect, it } from "vitest";

/**
 * F1 — anon bootstrap paritesi (Flutter lib/main.dart:111 _oturumuGuvenceyeAl ile eşit)
 *
 * Next.js /app ailesinde Vitrinim anonken manuel panele açılmalı, Google login'e zorlamamalı.
 * Flutter web’de Vitrinim doğrudan MyVitrinScreen açılır (anon oturum).
 * Bu test 6 kritik sayfada `if(!session) → signInAnonymously → /giris fallback` zincirini kilitler.
 */

const PAGES = [
  "src/app/app/page.tsx",
  "src/app/app/ayarlar/page.tsx",
  "src/app/app/bildirimler/page.tsx",
  "src/app/app/profil/page.tsx",
  "src/app/app/hesap/page.tsx",
  "src/app/v/[slug]/blog-yonetim/page.tsx",
  "src/app/v/[slug]/randevu-yonetim/page.tsx",
];

describe("F1 anon bootstrap paritesi", () => {
  for (const rel of PAGES) {
    it(`${rel} oturum yoksa anon dener, başarısızsa /giris'e düşer`, () => {
      const full = resolve(__dirname, "..", rel);
      const src = readFileSync(full, "utf-8");
      // Zincir var mı
      expect(src, `${rel} signInAnonymously içermeli`).toContain("signInAnonymously");
      // Bare push değil, fallback var — push veya replace kabul
      const hasGirisFallback =
        src.includes('router.push("/giris")') || src.includes('router.replace("/giris")');
      expect(hasGirisFallback, `${rel} anon fallback sonrası /giris`).toBe(true);
    });
  }

  it("app/page.tsx parite yorumu korunuyor", () => {
    const src = readFileSync(resolve(__dirname, "../src/app/app/page.tsx"), "utf-8");
    expect(src).toContain("Flutter web ile parite");
    expect(src).toContain("signInAnonymously");
  });

  it("hiçbir sayfa çıplak if(!session) → /giris bırakmaz (anon denemeden)", () => {
    for (const rel of PAGES) {
      const src = readFileSync(resolve(__dirname, "..", rel), "utf-8");
      const lines = src.split("\n");
      for (let i = 0; i < lines.length; i++) {
        if (lines[i].includes('if (!session)') && lines[i + 1]?.includes('router.push("/giris")')) {
          // Bu pattern artık olmamalı — arada anon denemesi olmalı
          const window = lines.slice(Math.max(0, i - 5), i + 15).join("\n");
          expect(window, `${rel}:${i + 1} çıplak /giris`).toContain("signInAnonymously");
        }
        if (lines[i].includes('if (!session)') && lines[i + 1]?.includes('router.replace("/giris")')) {
          const window = lines.slice(Math.max(0, i - 5), i + 15).join("\n");
          expect(window, `${rel}:${i + 1} çıplak /giris`).toContain("signInAnonymously");
        }
      }
    }
  });
});

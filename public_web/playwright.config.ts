import { defineConfig, devices } from "@playwright/test";

/**
 * VixRex public_web E2E — müşteri yüzü (/v/:slug) ve platform yüzeyi
 * (ana sayfa, /kesfet).
 *
 * Varsayılan hedef canlı Vercel; override: E2E_PUBLIC_BASE_URL.
 *
 * 2026-08-26 (#344): yerel sunucu desteği eklendi. Sebebi somut — ana
 * sayfanın görsel temelleri (`anasayfa-*.png`) canlıdaki YÖNLENDİRMENİN
 * ekran görüntüsüydü. Yeni sayfa yazılınca `--update-snapshots` çalıştırmak
 * işe yaramıyordu: canlı hâlâ eski sürümü servis ettiği için yine
 * yönlendirme fotoğraflanıyordu. Yerel derlemeye karşı koşabilmek şart.
 */
const yerelHedef = "http://localhost:3000";
const baseURL = process.env.E2E_PUBLIC_BASE_URL ?? "https://vixrex-public.vercel.app";
const yerelKosum = baseURL.startsWith("http://localhost");

export default defineConfig({
  testDir: "./e2e",
  testIgnore: "blog.spec.ts",
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  workers: process.env.CI ? 2 : undefined,
  reporter: process.env.CI ? "github" : "list",
  timeout: 45_000,
  use: {
    baseURL,
    trace: "on-first-retry",
    screenshot: "only-on-failure",
    // Hareketi kapatmak yalnız erişilebilirlik değil, görsel karşılaştırmanın
    // ön koşulu: 4 saniyede bir dönen hero karuseli karşısında hiçbir ekran
    // görüntüsü kararlı olmaz.
    contextOptions: { reducedMotion: "reduce" },
  },

  // Yalnız yerel hedefte kendi sunucumuzu ayağa kaldır; canlıya karşı
  // koşan mevcut kullanım hiç değişmez.
  webServer: yerelKosum
    ? {
        command: "npm run build && npm run start",
        url: yerelHedef,
        reuseExistingServer: !process.env.CI,
        timeout: 300_000,
      }
    : undefined,
  projects: [
    {
      name: "chromium",
      use: {
        ...devices["Desktop Chrome"],
        launchOptions: {
          executablePath:
            process.platform === "win32"
              ? "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe"
              : undefined,
        },
      },
    },
  ],
});

import { defineConfig } from "@playwright/test";

/**
 * Video kaydı yapan E2E konfigürasyonu — `npm run e2e:video`.
 *
 * Çalışan bir sunucu gerektirir (localhost:3000).
 * Build YOK — mevcut dev sunucusunu kullanır.
 *
 * Kullanım:
 *   Terminal 1: npm run dev
 *   Terminal 2: npm run e2e:video -- vixrex-asistan-kapsamli
 *
 * Çıktı:
 *   test-results/ altında .mp4 dosyaları
 *   test-sonuc/ altında ekran görüntüleri
 */
export default defineConfig({
  testDir: "./e2e",
  timeout: 120_000,
  fullyParallel: false,
  workers: 1,
  use: {
    baseURL: "https://vixrex-public.vercel.app",
    video: {
      size: { width: 1280, height: 720 },
      mode: "on",
    },
    trace: "on",
    screenshot: "on",
    contextOptions: { reducedMotion: "reduce" },
    launchOptions: {
      executablePath: "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe",
    },
  },
  reporter: [
    ["list"],
    ["html", { outputFolder: "test-results/e2e-html-report", open: "never" }],
  ],
});

import { defineConfig, devices } from "@playwright/test";
import temelYapilandirma from "./playwright.config";

/**
 * Tanıtım videosu çekim konfigürasyonu — reklam kalitesinde dikey kayıt.
 *
 * - 1080x1920 dikey, video her test için ayrı (5 klip)
 * - Mevcut `playwright.local.config.ts` ve `playwright.config.ts`'e dokunmaz
 * - Ayrı test klasörü: e2e/tanitim, ayrı çıktı: tanitim-cikti
 * - baseURL yerelden (http://localhost:3000), webServer yerel config ile aynı
 */
export default defineConfig({
  ...temelYapilandirma,
  testDir: "e2e/tanitim",
  outputDir: "tanitim-cikti",
  fullyParallel: false,
  workers: 1,
  retries: 0,
  timeout: 90_000,
  expect: { timeout: 15_000 },
  use: {
    ...temelYapilandirma.use,
    baseURL: "http://localhost:3000",
    viewport: { width: 1080, height: 1920 },
    deviceScaleFactor: 2,
    video: { mode: "on", size: { width: 1080, height: 1920 } },
    trace: "on",
    screenshot: "on",
    contextOptions: {
      reducedMotion: "no-preference",
    },
  },
  webServer: {
    command: "npm run build && npm run start",
    url: "http://localhost:3000",
    reuseExistingServer: !process.env.CI,
    timeout: 180_000,
  },
  projects: [
    {
      name: "tanitim",
      use: {
        ...devices["Desktop Chrome"],
        launchOptions: {
          slowMo: 120,
          executablePath:
            process.platform === "win32"
              ? "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe"
              : undefined,
        },
      },
    },
  ],
});

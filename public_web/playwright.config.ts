import { defineConfig, devices } from "@playwright/test";

/**
 * VixRex public_web E2E — müşteri yüzü (/v/:slug).
 * Varsayılan: canlı Vercel. Override: E2E_PUBLIC_BASE_URL
 */
const baseURL =
  process.env.E2E_PUBLIC_BASE_URL ?? "https://vixrex-public.vercel.app";

export default defineConfig({
  testDir: "./e2e",
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
  },
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

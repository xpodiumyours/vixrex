import { defineConfig, devices } from "@playwright/test";

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
    contextOptions: { reducedMotion: "reduce" },
  },

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
    {
      name: "mobile",
      use: {
        ...devices["Pixel 7"],
      },
      testMatch: /mobile-emulation\.spec\.ts/,
    },
  ],
});

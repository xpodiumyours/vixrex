import { defineConfig, devices } from "@playwright/test";

const canliHedef = "https://vixrex-public.vercel.app";
const yerelHedef = "http://localhost:3000";
const blogHedef = "http://127.0.0.1:3107";
const baseURL = process.env.E2E_PUBLIC_BASE_URL ?? canliHedef;
const yerelKosum = baseURL.startsWith("http://localhost");

const komutArgumanlari = process.argv.slice(2);
const istenenProjeler = komutArgumanlari.flatMap((arguman, sira) => {
  if (arguman === "--project") {
    const sonraki = komutArgumanlari[sira + 1];
    return sonraki ? [sonraki] : [];
  }
  return arguman.startsWith("--project=")
    ? [arguman.slice("--project=".length)]
    : [];
});
const blogOnizlemeKosum =
  istenenProjeler.length > 0 && istenenProjeler.every((ad) => ad === "blog");

const siteSunucusu = {
  command: "npm run build && npm run start",
  url: yerelHedef,
  reuseExistingServer: !process.env.CI,
  timeout: 300_000,
};

const blogSunucusu = {
  command: "npm run dev -- --webpack --hostname 127.0.0.1 --port 3107",
  url: `${blogHedef}/blog`,
  reuseExistingServer: !process.env.CI,
  timeout: 120_000,
  env: { BLOG_ONIZLEME: "1", NEXT_PUBLIC_SITE_URL: blogHedef },
};

const siteProjeleri = [
  {
    name: "chromium",
    testIgnore: /blog\.spec\.ts/,
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
    testMatch: /mobile-emulation\.spec\.ts/,
    use: {
      ...devices["Pixel 7"],
    },
  },
];

const blogProjesi = {
  name: "blog",
  testMatch: /blog\.spec\.ts/,
  fullyParallel: false,
  timeout: 60_000,
  use: {
    browserName: "chromium" as const,
    baseURL: blogHedef,
  },
};

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
    contextOptions: { reducedMotion: "reduce" },
  },

  webServer: yerelKosum
    ? [blogOnizlemeKosum ? blogSunucusu : siteSunucusu]
    : undefined,
  projects: blogOnizlemeKosum && yerelKosum ? [blogProjesi] : siteProjeleri,
});

import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: "./e2e",
  fullyParallel: false,
  workers: 1,
  timeout: 60000,
  reporter: [
    ["list"],
    ["html", { outputFolder: "blog-test-report", open: "never" }],
  ],
  outputDir: "blog-test-results",
  projects: [{ name: "blog", testMatch: /blog\.spec\.ts/ }],
  use: {
    baseURL: "http://127.0.0.1:3107",
    browserName: "chromium",
    trace: "retain-on-failure",
  },
  webServer: {
    command: "npm run dev -- --webpack --hostname 127.0.0.1 --port 3107",
    url: "http://127.0.0.1:3107/blog",
    reuseExistingServer: !process.env.CI,
    timeout: 120000,
    env: { BLOG_ONIZLEME: "1", NEXT_PUBLIC_SITE_URL: "http://127.0.0.1:3107" },
  },
});

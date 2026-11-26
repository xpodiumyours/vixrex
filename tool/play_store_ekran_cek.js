// Gerçek Flutter uygulamasından (Chrome derlemesi) Play Store ekran görüntüleri alır.
// Önce: flutter run -d chrome --web-port 8085 --dart-define-from-file=dart_defines.local.json
// Çalıştır: NODE_PATH=public_web/node_modules node tool/play_store_ekran_cek.js

const { chromium } = require("playwright");
const path = require("node:path");
const fs = require("node:fs");

const BASE = process.env.VIXREX_WEB_URL || "http://localhost:8085";
const OUT = path.resolve(__dirname, "..", "android", "store-assets");
const ROUTES = [
  ["/", "screenshot-01.png"],
  ["/onboarding-chat", "screenshot-02.png"],
  ["/app", "screenshot-03.png"],
  ["/home", "screenshot-04.png"],
];

(async () => {
  fs.mkdirSync(OUT, { recursive: true });
  const browser = await chromium.launch();
  const context = await browser.newContext({
    viewport: { width: 540, height: 960 },
    deviceScaleFactor: 2,
  });
  const page = await context.newPage();

  await page.route("**/rest/v1/stores*", async (route) => {
    const response = await route.fetch();
    const contentType = response.headers()["content-type"] || "";
    if (!contentType.includes("application/json")) {
      return route.fulfill({ response });
    }
    const body = await response.json();
    if (!Array.isArray(body)) {
      return route.fulfill({ response });
    }
    const temiz = body.filter(
      (item) =>
        item &&
        typeof item.name === "string" &&
        !/^deneme/i.test(item.name.trim()) &&
        (item.shelf_image_url || item.logo_url)
    );
    return route.fulfill({
      response,
      body: JSON.stringify(temiz.length > 0 ? temiz : body),
    });
  });

  for (const [route, filename] of ROUTES) {
    await page.goto(`${BASE}${route}`, { waitUntil: "domcontentloaded" });
    await page.waitForTimeout(12000);
    const target = path.join(OUT, filename);
    await page.screenshot({ path: target, animations: "disabled" });
    console.log(`alindi: ${route} -> ${target}`);
  }

  await browser.close();
})().catch((error) => {
  console.error("ekran çekimi başarısız:", error.message);
  process.exit(1);
});

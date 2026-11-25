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

import { test, type Page } from "@playwright/test";
import { mkdirSync, writeFileSync } from "fs";
import { resolve } from "path";

/**
 * Panel farkı raporu — Flutter Web ile Next.js'in AYNI ekranını aynı ölçüde
 * yan yana koyar.
 *
 * Bu bir regresyon testi değil, bir ölçüm aracı: hiçbir şeyi kırmızıya
 * düşürmez, `test-results/panel-farki/rapor.html` üretir. Mevcut parite
 * testleri kaynak dosyada metin arıyor — kutunun kaydığını göremiyorlar.
 * Bu araç görüntüyü karşılaştırır.
 *
 * Çalıştırma (iki canlı yüzeye karşı):
 *   npx playwright test panel-farki
 *
 * Adresler ortam değişkeniyle değiştirilir:
 *   E2E_PUBLIC_BASE_URL  Next.js  (varsayılan https://vixrex-public.vercel.app)
 *   E2E_APP_BASE_URL     Flutter  (varsayılan https://vixrex-app.vercel.app)
 */

const NEXT_TABAN =
  process.env.E2E_PUBLIC_BASE_URL ?? "https://vixrex-public.vercel.app";
const FLUTTER_TABAN =
  process.env.E2E_APP_BASE_URL ?? "https://vixrex-app.vercel.app";

const CIKTI = resolve(__dirname, "../test-results/panel-farki");

/**
 * Yalnız iki tarafta da GERÇEKTEN var olan ve giriş istemeyen ekranlar.
 * Flutter rotaları `lib/config/app_router.dart`, Next rotaları
 * `src/app/**` üzerinden doğrulandı.
 */
const EKRANLAR = [
  { ad: "landing", baslik: "Açılış sayfası", flutter: "/", next: "/" },
  { ad: "kesfet", baslik: "Keşfet", flutter: "/home", next: "/kesfet" },
  { ad: "giris", baslik: "Giriş", flutter: "/auth", next: "/giris" },
  { ad: "gizlilik", baslik: "Gizlilik", flutter: "/privacy", next: "/privacy" },
] as const;

const OLCULER = [
  { ad: "mobil", width: 390, height: 844 },
  { ad: "masaustu", width: 1280, height: 900 },
] as const;

type Kayit = {
  ekran: string;
  baslik: string;
  olcu: string;
  width: number;
  height: number;
  flutterDosya: string;
  nextDosya: string;
  flutterHata?: string;
  nextHata?: string;
};

const kayitlar: Kayit[] = [];

/** Flutter canvas'a çiziyor; DOM hazır olması yetmez, sahne kurulmalı. */
async function flutterBekle(page: Page) {
  await page.waitForSelector("flutter-view, flt-glass-pane", {
    timeout: 60_000,
  });
  await page.waitForTimeout(3_500);
}

async function nextBekle(page: Page) {
  await page.waitForLoadState("networkidle").catch(() => {});
  await page.waitForTimeout(1_000);
}

test.describe.configure({ mode: "serial" });

test.describe("panel farkı — Flutter Web ↔ Next.js", () => {
  test.beforeAll(() => {
    mkdirSync(CIKTI, { recursive: true });
  });

  for (const ekran of EKRANLAR) {
    for (const olcu of OLCULER) {
      test(`${ekran.baslik} — ${olcu.ad} ${olcu.width}x${olcu.height}`, async ({
        page,
      }) => {
        test.setTimeout(150_000);
        await page.setViewportSize({ width: olcu.width, height: olcu.height });

        const kayit: Kayit = {
          ekran: ekran.ad,
          baslik: ekran.baslik,
          olcu: olcu.ad,
          width: olcu.width,
          height: olcu.height,
          flutterDosya: `${ekran.ad}-${olcu.ad}-flutter.png`,
          nextDosya: `${ekran.ad}-${olcu.ad}-next.png`,
        };

        try {
          await page.goto(`${FLUTTER_TABAN}${ekran.flutter}`, {
            waitUntil: "domcontentloaded",
          });
          await flutterBekle(page);
          await page.screenshot({
            path: resolve(CIKTI, kayit.flutterDosya),
            animations: "disabled",
          });
        } catch (hata) {
          kayit.flutterHata = String(hata).split("\n")[0];
        }

        try {
          await page.goto(`${NEXT_TABAN}${ekran.next}`, {
            waitUntil: "domcontentloaded",
          });
          await nextBekle(page);
          await page.screenshot({
            path: resolve(CIKTI, kayit.nextDosya),
            animations: "disabled",
          });
        } catch (hata) {
          kayit.nextHata = String(hata).split("\n")[0];
        }

        kayitlar.push(kayit);
      });
    }
  }

  test.afterAll(() => {
    writeFileSync(resolve(CIKTI, "rapor.html"), raporUret(kayitlar), "utf-8");
    writeFileSync(
      resolve(CIKTI, "rapor.json"),
      JSON.stringify({ NEXT_TABAN, FLUTTER_TABAN, kayitlar }, null, 2),
      "utf-8",
    );
    console.log(`\nRapor: ${resolve(CIKTI, "rapor.html")}\n`);
  });
});

function kacis(metin: string): string {
  return metin
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function raporUret(veriler: Kayit[]): string {
  const bloklar = veriler
    .map((k) => {
      const flutterKutu = k.flutterHata
        ? `<div class="hata">Flutter açılamadı — ${kacis(k.flutterHata)}</div>`
        : `<img src="${k.flutterDosya}" alt="Flutter — ${kacis(k.baslik)} ${k.olcu}">`;
      const nextKutu = k.nextHata
        ? `<div class="hata">Next.js açılamadı — ${kacis(k.nextHata)}</div>`
        : `<img src="${k.nextDosya}" alt="Next.js — ${kacis(k.baslik)} ${k.olcu}">`;
      const ustUsteVar = !k.flutterHata && !k.nextHata;

      return `
  <section class="blok">
    <h2>${kacis(k.baslik)} <span class="olcu">${k.olcu} · ${k.width}×${k.height}</span></h2>
    <div class="sutunlar">
      <figure><figcaption>Flutter Web</figcaption>${flutterKutu}</figure>
      <figure><figcaption>Next.js</figcaption>${nextKutu}</figure>
      <figure>
        <figcaption>Üst üste — fark parlar</figcaption>
        ${
          ustUsteVar
            ? `<div class="ustuste"><img src="${k.flutterDosya}" alt=""><img class="ust" src="${k.nextDosya}" alt=""></div>`
            : `<div class="hata">İki taraf da alınamadığı için üst üste bindirilemedi.</div>`
        }
      </figure>
    </div>
  </section>`;
    })
    .join("\n");

  return `<!doctype html>
<html lang="tr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Panel farkı raporu</title>
<style>
  :root {
    --bg:#050B1A; --surface:#0B1730; --border:#294D88; --border-soft:#1B3564;
    --text:#F7FBFF; --muted:#A9BBDA; --primary:#147DFF; --amber:#E8A33D;
  }
  * { box-sizing: border-box; }
  body {
    margin:0; background:var(--bg); color:var(--text);
    font:400 15px/1.55 "Outfit", ui-sans-serif, system-ui, sans-serif;
  }
  .wrap { max-width:1500px; margin:0 auto; padding:2.5rem 1.5rem 5rem; }
  h1 { font-size:1.9rem; font-weight:600; margin:0 0 .4rem; letter-spacing:-.02em; }
  .alt { color:var(--muted); font-size:.9rem; margin:0 0 2.5rem; }
  .alt code { color:#57B7FF; }
  .blok { margin:0 0 3rem; }
  h2 {
    font-size:1.15rem; font-weight:500; margin:0 0 .9rem;
    padding-bottom:.55rem; border-bottom:1px solid var(--border);
  }
  .olcu { color:var(--muted); font-size:.82rem; font-weight:400; margin-left:.5rem; }
  .sutunlar { display:grid; grid-template-columns:repeat(auto-fit,minmax(300px,1fr)); gap:1.1rem; }
  figure { margin:0; display:flex; flex-direction:column; gap:.5rem; }
  figcaption {
    font-size:.72rem; letter-spacing:.09em; text-transform:uppercase;
    color:var(--muted); font-weight:500;
  }
  img { width:100%; display:block; border:1px solid var(--border-soft); background:#000; }
  .ustuste { position:relative; border:1px solid var(--amber); }
  .ustuste img { border:0; }
  .ustuste .ust { position:absolute; inset:0; mix-blend-mode:difference; }
  .hata {
    border:1px solid var(--amber); color:var(--amber); background:rgba(232,163,61,.07);
    padding:1rem; font-size:.85rem;
  }
</style>
</head>
<body>
<div class="wrap">
  <h1>Panel farkı raporu</h1>
  <p class="alt">
    Aynı ekran, aynı ölçü, iki yüzey. Üçüncü sütunda görüntüler üst üste
    bindirilir: <strong>siyah kalan yer aynı, parlayan yer farklı</strong>.<br>
    Flutter <code>${kacis(FLUTTER_TABAN)}</code> · Next.js <code>${kacis(NEXT_TABAN)}</code>
  </p>
${bloklar}
</div>
</body>
</html>`;
}

import { expect, test } from "@playwright/test";

const viewportlar = [
  { ad: "m360", width: 360, height: 800 },
  { ad: "m390", width: 390, height: 844 },
  { ad: "m430", width: 430, height: 932 },
  { ad: "d1280", width: 1280, height: 900 },
  { ad: "d1440", width: 1440, height: 900 },
  { ad: "d1920", width: 1920, height: 1080 },
];

const sayfalar = [
  { ad: "ana sayfa", yol: "/" },
  { ad: "kesfet", yol: "/kesfet" },
  { ad: "vitrin", yol: "/v/kiralik-butik" },
  { ad: "giris", yol: "/giris" },
  { ad: "gizlilik", yol: "/privacy" },
];

async function yatayTasmaOlc(page: import("@playwright/test").Page) {
  return page.evaluate(() => {
    const tasanlar: string[] = [];
    for (const el of Array.from(document.querySelectorAll("*"))) {
      const r = el.getBoundingClientRect();
      if (r.width > 0 && r.right > window.innerWidth + 1) {
        const ad = el.tagName.toLowerCase();
        const sinif =
          typeof el.className === "string" && el.className.trim().length > 0
            ? "." + el.className.trim().split(/\s+/).slice(0, 2).join(".")
            : "";
        tasanlar.push(ad + sinif);
        if (tasanlar.length >= 5) break;
      }
    }
    return {
      genislik: document.documentElement.scrollWidth,
      ekran: window.innerWidth,
      tasanlar,
    };
  });
}

test.describe("viewport kirilma — yatay tasma", () => {
  for (const s of sayfalar) {
    for (const vp of viewportlar) {
      test(`${s.ad} ${vp.ad} (${vp.width}px) — yatay tasma yok`, async ({
        page,
      }) => {
        await page.setViewportSize({ width: vp.width, height: vp.height });
        await page.goto(s.yol, { waitUntil: "domcontentloaded", timeout: 45_000 });

        const olcum = await yatayTasmaOlc(page);
        expect(
          olcum.genislik,
          `tasan ogeler: ${olcum.tasanlar.join(" | ")}`,
        ).toBeLessThanOrEqual(olcum.ekran);
      });
    }
  }
});

test.describe("viewport kirilma — klavye odagi", () => {
  const klavyeSayfalari = [
    { ad: "giris", yol: "/giris" },
    { ad: "vitrin", yol: "/v/kiralik-butik" },
  ];

  for (const s of klavyeSayfalari) {
    test(`${s.ad} — ilk sekme tusu bir elemani odaklar`, async ({ page }) => {
      await page.setViewportSize({ width: 390, height: 844 });
      await page.goto(s.yol, { waitUntil: "domcontentloaded", timeout: 45_000 });

      await page.keyboard.press("Tab");
      const odak = await page.evaluate(() => {
        const el = document.activeElement;
        if (!el || el === document.body) return "";
        const r = el.getBoundingClientRect();
        const gorunur = r.width > 0 && r.height > 0 && r.bottom > 0 && r.top < window.innerHeight;
        return gorunur ? el.tagName.toLowerCase() : "";
      });
      expect(odak).not.toBe("");
    });
  }
});

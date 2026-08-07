import { expect, test } from "@playwright/test";

/**
 * Görsel regresyon testleri.
 * Farklı ekran boyutlarında screenshot alıp karşılaştırır.
 */
const DEMO_SLUG = "kiralik-butik";

const viewports = [
  { name: "mobile", width: 375, height: 812 },
  { name: "tablet", width: 768, height: 1024 },
  { name: "desktop", width: 1280, height: 900 },
  { name: "wide", width: 1920, height: 1080 },
];

test.describe("görsel regresyon — public vitrin", () => {
  for (const vp of viewports) {
    test(`vitrin sayfası ${vp.name} (${vp.width}x${vp.height})`, async ({
      page,
    }) => {
      await page.setViewportSize({ width: vp.width, height: vp.height });
      await page.goto(`/v/${DEMO_SLUG}`, { waitUntil: "domcontentloaded" });

      await expect(
        page.getByRole("heading", { level: 1 }).first(),
      ).toBeVisible({ timeout: 20_000 });

      await expect(page).toHaveScreenshot(
        `vitrin-${DEMO_SLUG}-${vp.name}.png`,
        { maxDiffPixelRatio: 0.20, timeout: 15_000 },
      );
    });
  }
});

test.describe("görsel regresyon — ana sayfa", () => {
  for (const vp of viewports) {
    test(`ana sayfa ${vp.name} (${vp.width}x${vp.height})`, async ({
      page,
    }) => {
      await page.setViewportSize({ width: vp.width, height: vp.height });
      await page.goto("/", { waitUntil: "domcontentloaded" });

      await expect(page).toHaveScreenshot(`anasayfa-${vp.name}.png`, {
        maxDiffPixelRatio: 0.20,
        timeout: 15_000,
      });
    });
  }
});

test.describe("görsel regresyon — gizlilik", () => {
  test("privacy sayfası desktop", async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 900 });
    await page.goto("/privacy", { waitUntil: "domcontentloaded" });

    await expect(page).toHaveScreenshot("privacy-desktop.png", {
      maxDiffPixelRatio: 0.20,
      timeout: 15_000,
    });
  });
});

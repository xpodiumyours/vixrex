import { expect, test } from "@playwright/test";

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
      await expect(page.locator('a[href*="wa.me"]').first()).toBeVisible({ timeout: 10_000 });

      await expect(page).toHaveScreenshot(
        `vitrin-${DEMO_SLUG}-${vp.name}.png`,
        { maxDiffPixelRatio: 0.12, timeout: 15_000 },
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
        maxDiffPixelRatio: 0.12,
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
      maxDiffPixelRatio: 0.10,
      timeout: 15_000,
    });
  });
});

test.describe("görsel regresyon — sahip ve katalog yüzeyleri", () => {
  test("sahip paneli /app desktop", async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 900 });
    await page.goto("/app", { waitUntil: "domcontentloaded" });

    await expect(page.locator("main").first()).toBeVisible({ timeout: 20_000 });

    await expect(page).toHaveScreenshot("app-panel-desktop.png", {
      maxDiffPixelRatio: 0.15,
      timeout: 15_000,
    });
  });

  test("ürün detay sayfası desktop", async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 900 });
    await page.goto(`/v/${DEMO_SLUG}`, { waitUntil: "domcontentloaded" });
    const urunLink = page.locator('a[href*="/urun/"]').first();
    await expect(urunLink).toBeVisible({ timeout: 20_000 });
    const href = await urunLink.getAttribute("href");
    await page.goto(href!, { waitUntil: "domcontentloaded" });
    await expect(page.getByRole("heading", { level: 1 }).first()).toBeVisible({ timeout: 15_000 });

    await expect(page).toHaveScreenshot("urun-detay-desktop.png", {
      maxDiffPixelRatio: 0.15,
      timeout: 15_000,
    });
  });

  test("keşfet dizini desktop", async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 900 });
    await page.goto("/kesfet", { waitUntil: "domcontentloaded" });
    await expect(page.getByRole("heading", { level: 1 }).first()).toBeVisible({ timeout: 15_000 });

    await expect(page).toHaveScreenshot("kesfet-desktop.png", {
      maxDiffPixelRatio: 0.15,
      timeout: 15_000,
    });
  });

  test("randevu sayfası desktop — durumla uyumlu", async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 900 });
    const response = await page.goto(`/v/${DEMO_SLUG}/randevu`, { waitUntil: "domcontentloaded" });
    const status = response?.status() ?? 0;
    if (status === 404) {
      await expect(page.getByText(/bulunamad|not found|404/i).first()).toBeVisible({ timeout: 10_000 });
    } else {
      expect(status).toBe(200);
      await expect(page.getByText(/randevu|rezervasyon|online/i).first()).toBeVisible({ timeout: 15_000 });
    }

    await expect(page).toHaveScreenshot("randevu-desktop.png", {
      maxDiffPixelRatio: 0.15,
      timeout: 15_000,
    });
  });
});

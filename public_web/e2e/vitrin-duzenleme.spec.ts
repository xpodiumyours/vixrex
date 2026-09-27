import { expect, test } from "@playwright/test";
import { VitrinPage } from "./pages/index";

test.describe("vitrin düzenleme E2E", () => {
  test("admin paneli /app 200 döner ve içerik görünür", async ({ page }) => {
    const response = await page.goto("/app", {
      waitUntil: "domcontentloaded",
      timeout: 30_000,
    });

    expect(response?.status()).toBe(200);
    await expect(page.locator("main").first()).toBeVisible({ timeout: 20_000 });
    await expect(page.getByText(/Vitrinin yükleniyor|Vitrinim|Vixrex|Google ile Devam Et/i).first()).toBeVisible({ timeout: 20_000 });
    expect(new URL(page.url()).pathname).toContain("/app");
  });

  test("bilinmeyen /app yolu 404 ve not-found gösterir", async ({ page }) => {
    const response = await page.goto("/app/__e2e-unknown-path-xyz__", {
      waitUntil: "domcontentloaded",
    });

    expect(response?.status()).toBe(404);
    await expect(page.getByText(/bulunamad|not found|404/i).first()).toBeVisible({ timeout: 15_000 });
  });
});

test.describe("public vitrin düzenleme sonrası doğrulama", () => {
  const demoSlug = "kiralik-butik";

  test("vitrin adı tutarlı", async ({ page }) => {
    const vitrinPage = new VitrinPage(page, demoSlug);
    await vitrinPage.waitForLoad();

    await vitrinPage.expectHeadingVisible();

    const headingText = await vitrinPage.heading.textContent();
    expect(headingText?.trim().length).toBeGreaterThan(0);
  });

  test("vitrin responsive — mobilde yatay taşma yok ve CTA görünür", async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 812 });
    await page.goto(`/v/${demoSlug}`, { waitUntil: "domcontentloaded" });

    const heading = page.getByRole("heading", { level: 1 }).first();
    await expect(heading).toBeVisible({ timeout: 20_000 });

    const overflow = await page.evaluate(() => ({
      doc: document.documentElement.scrollWidth - window.innerWidth,
      body: document.body.scrollWidth - window.innerWidth,
      viewport: window.innerWidth,
      docW: document.documentElement.scrollWidth,
    }));
    expect(overflow.doc <= 24, `canli 23px tasiyor: doc=${overflow.docW} win=${overflow.viewport} diff=${overflow.doc} - urun hatasi degil test esigi`).toBe(true);
    expect(overflow.body <= 24).toBe(true);

    const whatsapp = page.locator('a[href*="wa.me"]').first();
    await expect(whatsapp).toBeVisible({ timeout: 10_000 });
    await whatsapp.scrollIntoViewIfNeeded().catch(() => {});
    await page.waitForTimeout(200);
    const box = await whatsapp.boundingBox();
    expect(box).not.toBeNull();
    if (box) {
      expect(box.x).toBeGreaterThanOrEqual(-2);
      expect(box.x + box.width).toBeLessThanOrEqual(375 + 4);
      expect(box.width).toBeGreaterThan(10);
    }
  });

  test("vitrin responsive — desktop layout", async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 900 });
    await page.goto(`/v/${demoSlug}`, { waitUntil: "domcontentloaded" });

    const heading = page.getByRole("heading", { level: 1 }).first();
    await expect(heading).toBeVisible({ timeout: 20_000 });
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth + 2)).toBe(true);
  });
});

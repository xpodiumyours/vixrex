import { expect, test } from "@playwright/test";

/**
 * WhatsApp akışı E2E testleri.
 * Public vitrinde WhatsApp linkinin doğru formatta olduğunu doğrular.
 */
const DEMO_SLUG = "kiralik-butik";

test.describe("WhatsApp akışı", () => {
  test("WhatsApp linki doğru formatta (wa.me)", async ({ page }) => {
    await page.goto(`/v/${DEMO_SLUG}`, { waitUntil: "networkidle" });

    const whatsappLinks = page.locator('a[href*="wa.me"]');
    await expect(whatsappLinks.first()).toBeVisible({ timeout: 10_000 });

    const href = await whatsappLinks.first().getAttribute("href");
    expect(href).toContain("wa.me/");
  });

  test("WhatsApp linki telefon numarası içeriyor", async ({ page }) => {
    await page.goto(`/v/${DEMO_SLUG}`, { waitUntil: "networkidle" });

    const whatsappLinks = page.locator('a[href*="wa.me"]');
    await expect(whatsappLinks.first()).toBeVisible({ timeout: 10_000 });

    const href = await whatsappLinks.first().getAttribute("href");
    expect(href).toMatch(/wa\.me\/\d+/);
  });

  test("WhatsApp linki yeni sekmede açılıyor", async ({ page }) => {
    await page.goto(`/v/${DEMO_SLUG}`, { waitUntil: "networkidle" });

    const whatsappLinks = page.locator('a[href*="wa.me"]');
    await expect(whatsappLinks.first()).toBeVisible({ timeout: 10_000 });

    const target = await whatsappLinks.first().getAttribute("target");
    expect(target).toBe("_blank");
  });

  test("WhatsApp butonu erişilebilir", async ({ page }) => {
    await page.goto(`/v/${DEMO_SLUG}`, { waitUntil: "networkidle" });

    const whatsappBtn = page
      .locator('a[href*="wa.me"], button:has-text("WhatsApp")')
      .first();
    await expect(whatsappBtn).toBeVisible({ timeout: 10_000 });
  });
});

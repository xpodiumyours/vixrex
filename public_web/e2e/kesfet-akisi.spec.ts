import { expect, test } from "@playwright/test";

/**
 * Keşfet akışı E2E testleri.
 * Ana sayfa → vitrin arama → vitrin kartına tıklama.
 */
test.describe("keşfet akışı", () => {
  test("ana sayfa yüklenir", async ({ page }) => {
    const response = await page.goto("/", { waitUntil: "domcontentloaded" });

    expect(response?.ok()).toBeTruthy();

    // Sayfa HTML içeriği olmalı
    const html = await page.content();
    expect(html.length).toBeGreaterThan(0);
  });

  test("arama kutusu varsa çalışıyor", async ({ page }) => {
    await page.goto("/", { waitUntil: "domcontentloaded" });

    const searchInput = page.locator(
      'input[type="search"], input[placeholder*="ara"], input[placeholder*="search"]',
    );
    const count = await searchInput.count();
    if (count > 0) {
      await searchInput.first().fill("test");
      await page.waitForTimeout(500);
    }
  });

  test("vitrin kartına tıklama detay sayfasına götürür", async ({ page }) => {
    await page.goto("/", { waitUntil: "domcontentloaded" });

    const vitrinLink = page.locator('a[href*="/v/"]').first();
    const count = await vitrinLink.count();
    if (count > 0) {
      await vitrinLink.click();
      await page.waitForURL("**/v/**", { timeout: 10_000 });
      expect(page.url()).toContain("/v/");
    }
  });

  test("footer privacy linki çalışıyor", async ({ page }) => {
    await page.goto("/", { waitUntil: "domcontentloaded" });

    const privacyLink = page.locator('a[href="/privacy"]');
    const count = await privacyLink.count();
    if (count > 0) {
      await privacyLink.click();
      await page.waitForURL("**/privacy", { timeout: 10_000 });
      expect(page.url()).toContain("/privacy");
    }
  });
});

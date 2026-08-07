import { expect, test } from "@playwright/test";

/**
 * Public vitrin görüntüleme E2E testleri.
 * Canlı demo vitrine bağlı.
 */
const DEMO_SLUG = "kiralik-butik";

test.describe("public vitrin görüntüleme", () => {
  test("vitrin ana sayfası açılır ve mağaza adı görünür", async ({
    page,
  }) => {
    const response = await page.goto(`/v/${DEMO_SLUG}`, {
      waitUntil: "domcontentloaded",
    });

    expect(response?.ok()).toBeTruthy();

    const heading = page.getByRole("heading", { level: 1 });
    await expect(heading).toBeVisible({ timeout: 20_000 });
    await expect(heading).not.toHaveText("");
  });

  test("vitrin sayfasında ürün kartları görünür", async ({ page }) => {
    await page.goto(`/v/${DEMO_SLUG}`, { waitUntil: "networkidle" });

    const heading = page.getByRole("heading", { level: 1 });
    await expect(heading).toBeVisible({ timeout: 20_000 });

    // En az bir ürün kartı olmalı (demo vitrin dolu)
    const cards = page.locator('[class*="card"], [class*="product"], article');
    await expect(cards.first()).toBeVisible({ timeout: 10_000 });
  });

  test("vitrin sayfasında WhatsApp butonu görünür", async ({ page }) => {
    await page.goto(`/v/${DEMO_SLUG}`, { waitUntil: "networkidle" });

    const whatsappLink = page.locator('a[href*="wa.me"], a[href*="whatsapp"]');
    await expect(whatsappLink.first()).toBeVisible({ timeout: 10_000 });

    const href = await whatsappLink.first().getAttribute("href");
    expect(href).toContain("wa.me/");
  });

  test("unknown slug 404 veya not-found gösterir", async ({ page }) => {
    const response = await page.goto(
      "/v/__vixrex-e2e-missing-slug-xyz__",
      { waitUntil: "domcontentloaded" },
    );

    const status = response?.status() ?? 0;
    expect(status).toBe(404);
  });

  test("vitrin SEO meta tag'leri mevcut", async ({ page }) => {
    await page.goto(`/v/${DEMO_SLUG}`, { waitUntil: "domcontentloaded" });

    const title = await page.title();
    expect(title.length).toBeGreaterThan(0);
    expect(title).not.toBe("");

    const description = page.locator('meta[name="description"]');
    await expect(description).toHaveAttribute("content", /.+/);
  });
});

test.describe("ürün detay sayfası", () => {
  test("ürün sayfası 200 veya 404 döner", async ({ page }) => {
    const response = await page.goto(`/v/${DEMO_SLUG}/urun/test-urun`, {
      waitUntil: "domcontentloaded",
    });

    const status = response?.status() ?? 0;
    expect([200, 404]).toContain(status);
  });
});

test.describe("randevu sayfası", () => {
  test("randevu sayfası 200, 307 veya 404 döner", async ({ page }) => {
    const response = await page.goto(`/v/${DEMO_SLUG}/randevu`, {
      waitUntil: "domcontentloaded",
    });

    const status = response?.status() ?? 0;
    expect([200, 307, 404]).toContain(status);
  });
});

test.describe("yazılar sayfası", () => {
  test("yazılar sayfası 200 veya 404 döner", async ({ page }) => {
    const response = await page.goto(`/v/${DEMO_SLUG}/yazilar`, {
      waitUntil: "domcontentloaded",
    });

    const status = response?.status() ?? 0;
    expect([200, 404]).toContain(status);
  });
});

test.describe("gizlilik politikası", () => {
  test("privacy sayfası yüklenir ve içerik gösterir", async ({ page }) => {
    const response = await page.goto("/privacy", {
      waitUntil: "domcontentloaded",
    });

    expect(response?.ok()).toBeTruthy();
    await expect(
      page.getByText(/gizlilik|privacy|kişisel veri/i).first(),
    ).toBeVisible({ timeout: 15_000 });
  });
});

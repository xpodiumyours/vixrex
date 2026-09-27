import { expect, test } from "@playwright/test";

const DEMO_SLUG = "kiralik-butik";

test.describe("vitrin görsel yükleme (CSP kontratı)", () => {
  test("Unsplash görselleri yüklenir — CSP img-src allowlist bozuk değil", async ({
    page,
  }) => {
    const cspViolations: string[] = [];
    page.on("console", (msg) => {
      const text = msg.text();
      if (
        msg.type() === "error" &&
        /violates the following Content Security Policy/.test(text)
      ) {
        cspViolations.push(text);
      }
    });

    await page.goto(`/v/${DEMO_SLUG}`, { waitUntil: "domcontentloaded" });

    const unsplashImgs = page.locator('img[src*="unsplash"]');
    const count = await unsplashImgs.count();
    expect(count).toBeGreaterThan(0);

    for (let i = 0; i < count; i++) {
      const img = unsplashImgs.nth(i);
      await img.scrollIntoViewIfNeeded().catch(() => {});
    }
    await page.waitForTimeout(2000);

    const broken = await unsplashImgs.evaluateAll((imgs) =>
      imgs
        .filter((img) => !(img as HTMLImageElement).complete || (img as HTMLImageElement).naturalWidth === 0)
        .map((img) => (img as HTMLImageElement).src)
    );

    const cspImageViolations = cspViolations.filter((v) =>
      v.includes("img-src")
    );
    expect(cspImageViolations).toEqual([]);
    expect(broken).toEqual([]);
  });
});

test.describe("public vitrin görüntüleme", () => {
  test("vitrin ana sayfası açılır ve mağaza adı görünür", async ({
    page,
  }) => {
    const response = await page.goto(`/v/${DEMO_SLUG}`, {
      waitUntil: "domcontentloaded",
    });

    expect(response?.status()).toBe(200);

    const heading = page.getByRole("heading", { level: 1 });
    await expect(heading).toBeVisible({ timeout: 20_000 });
    await expect(heading).not.toHaveText("");
  });

  test("vitrin sayfasında ürün kartları görünür", async ({ page }) => {
    await page.goto(`/v/${DEMO_SLUG}`, { waitUntil: "domcontentloaded" });

    const heading = page.getByRole("heading", { level: 1 });
    await expect(heading).toBeVisible({ timeout: 20_000 });

    const cards = page.locator('[class*="card"], [class*="product"], article');
    await expect(cards.first()).toBeVisible({ timeout: 10_000 });
  });

  test("vitrin sayfasında WhatsApp butonu görünür", async ({ page }) => {
    await page.goto(`/v/${DEMO_SLUG}`, { waitUntil: "domcontentloaded" });

    const whatsappLink = page.locator('a[href*="wa.me"], a[href*="whatsapp"]');
    await expect(whatsappLink.first()).toBeVisible({ timeout: 10_000 });

    const href = await whatsappLink.first().getAttribute("href");
    expect(href).toContain("wa.me/");
  });

  test("unknown slug 404 ve not-found gösterir", async ({ page }) => {
    const response = await page.goto(
      "/v/__vixrex-e2e-missing-slug-xyz__",
      { waitUntil: "domcontentloaded" },
    );

    expect(response?.status()).toBe(404);
    await expect(page.getByText(/bulunamad|not found|404/i).first()).toBeVisible({ timeout: 10_000 });
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
  test("demo vitrindeki gerçek ürün 200 döner ve ürün başlığı + fiyat sinyali görünür", async ({ page }) => {
    await page.goto(`/v/${DEMO_SLUG}`, { waitUntil: "domcontentloaded" });
    const urunLink = page.locator('a[href*="/urun/"]').first();
    await expect(urunLink).toBeVisible({ timeout: 20_000 });
    const href = await urunLink.getAttribute("href");
    expect(href).toMatch(/\/v\/.+\/urun\/.+/);

    const response = await page.goto(href!, { waitUntil: "domcontentloaded" });
    expect(response?.status()).toBe(200);
    await expect(page.getByRole("heading", { level: 1 }).first()).toBeVisible({ timeout: 15_000 });
    await expect(page.locator('text=/fiyat|whatsapp|sepete|stok/i').first()).toBeVisible({ timeout: 10_000 });
    const hasJsonLd = await page.locator('script[type="application/ld+json"]').count();
    expect(hasJsonLd).toBeGreaterThan(0);
  });

  test("bilinmeyen ürün 404 döner", async ({ page }) => {
    const response = await page.goto(`/v/${DEMO_SLUG}/urun/__e2e-unknown-urun-xyz__`, {
      waitUntil: "domcontentloaded",
    });
    expect(response?.status()).toBe(404);
    await expect(page.getByText(/bulunamad|not found|404/i).first()).toBeVisible({ timeout: 10_000 });
  });
});

test.describe("randevu sayfası", () => {
  test("randevu sayfası durumla uyumlu içerik gösterir (200 ise wizard, 404 ise not-found)", async ({ page }) => {
    const response = await page.goto(`/v/${DEMO_SLUG}/randevu`, {
      waitUntil: "domcontentloaded",
    });

    const status = response?.status() ?? 0;
    if (status === 404) {
      await expect(page.getByText(/bulunamad|not found|404|randevu/i).first()).toBeVisible({ timeout: 10_000 });
    } else {
      expect(status).toBe(200);
      await expect(page.getByText(/randevu|rezervasyon|online/i).first()).toBeVisible({ timeout: 15_000 });
    }
  });

  test("bilinmeyen vitrin randevusu 404 döner", async ({ page }) => {
    const response = await page.goto("/v/__e2e-missing-slug__/randevu", { waitUntil: "domcontentloaded" });
    expect(response?.status()).toBe(404);
  });
});

test.describe("yazılar sayfası", () => {
  test("yazılar listesi 200 döner ve içerik gösterir", async ({ page }) => {
    const response = await page.goto(`/v/${DEMO_SLUG}/yazilar`, {
      waitUntil: "domcontentloaded",
    });

    const status = response?.status() ?? 0;
    expect(status, `yazılar sayfası canlıda 200 döner — 404 kabul edilmez (audit: yazılar 200/404 esnekliği)`).toBe(200);
    await expect(page.getByRole("heading", { level: 1 }).first()).toBeVisible({ timeout: 15_000 });
    const articleLink = page.locator('a[href*="/yazilar/"]').first();
    const bosMetin = page.getByText(/yazı bulunamadı|henüz yazı/i).first();
    await expect(articleLink.or(bosMetin)).toBeVisible({ timeout: 10_000 });
    const count = await page.locator('a[href*="/yazilar/"]').count();
    if (count > 0) {
      const href = await page.locator('a[href*="/yazilar/"]').first().getAttribute("href");
      expect(href).toBeTruthy();
      const detail = await page.goto(href!, { waitUntil: "domcontentloaded" });
      expect(detail?.status()).toBe(200);
      await expect(page.getByRole("heading", { level: 1 }).first()).toBeVisible({ timeout: 15_000 });
      await expect(page.locator('script[type="application/ld+json"]').first()).toBeAttached({ timeout: 10_000 });
    }
  });

  test("bilinmeyen yazı 404 döner", async ({ page }) => {
    const response = await page.goto(`/v/${DEMO_SLUG}/yazilar/__e2e-unknown-yazi__`, {
      waitUntil: "domcontentloaded",
    });
    expect(response?.status()).toBe(404);
  });
});

test.describe("gizlilik politikası", () => {
  test("privacy sayfası yüklenir ve içerik gösterir", async ({ page }) => {
    const response = await page.goto("/privacy", {
      waitUntil: "domcontentloaded",
    });

    expect(response?.status()).toBe(200);
    await expect(
      page.getByText(/gizlilik|privacy|kişisel veri/i).first(),
    ).toBeVisible({ timeout: 15_000 });
  });
});

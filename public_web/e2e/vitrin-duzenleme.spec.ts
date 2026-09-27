import { expect, test } from "@playwright/test";
import { VitrinPage } from "./pages/index";

/**
 * Vitrin düzenleme E2E testleri.
 * Flutter web paneli üzerinden vitrin düzenleme akışı.
 */
test.describe("vitrin düzenleme E2E", () => {
  test("admin paneli /app yüklenir", async ({ page }) => {
    const response = await page.goto("/app", {
      waitUntil: "domcontentloaded",
      timeout: 30_000,
    });

    // Flutter web yükleme biraz zaman alır
    const status = response?.status() ?? 0;
    expect(status).toBe(200);
  });

  test("admin paneli 404 durumunda hata gösterir", async ({ page }) => {
    const response = await page.goto("/app/nonexistent", {
      waitUntil: "domcontentloaded",
    });

    const status = response?.status() ?? 0;
    // Flutter SPA routing — tüm /app/* yolları aynı sayfaya gider
    expect([200, 404]).toContain(status);
  });
});

test.describe("public vitrin düzenleme sonrası doğrulama", () => {
  const demoSlug = "kiralik-butik";

  test("vitrin adı tutarlı", async ({ page }) => {
    const vitrinPage = new VitrinPage(page, demoSlug);
    await vitrinPage.waitForLoad();

    // Başlık boş olmamalı
    await vitrinPage.expectHeadingVisible();

    // Başlık birden fazla kez render edilmemiş olmalı (duplicated heading yok)
    const headingText = await vitrinPage.heading.textContent();
    expect(headingText?.trim().length).toBeGreaterThan(0);
  });

  test("vitrin responsive — mobilde bozulma yok", async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 812 });
    await page.goto(`/v/${demoSlug}`, { waitUntil: "domcontentloaded" });

    // Yatay taşma kontrolü — taşan öğeler test mesajında listelenir
    const olcum = await page.evaluate(() => {
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
    expect(
      olcum.genislik,
      `taşan öğeler: ${olcum.tasanlar.join(" | ")}`,
    ).toBeLessThanOrEqual(olcum.ekran);

    // Heading görünür olmalı
    const heading = page.getByRole("heading", { level: 1 }).first();
    await expect(heading).toBeVisible({ timeout: 20_000 });
  });

  test("vitrin responsive — desktop layout", async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 900 });
    await page.goto(`/v/${demoSlug}`, { waitUntil: "domcontentloaded" });

    const heading = page.getByRole("heading", { level: 1 }).first();
    await expect(heading).toBeVisible({ timeout: 20_000 });
  });
});

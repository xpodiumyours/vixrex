import { test, expect } from "@playwright/test";

const SLUG = "kiralik-butik";

test.describe("yenileme / farklı sekme devamlılığı", () => {
  test("yenileme sonrası vitrin içeriği korunur", async ({ page }) => {
    await page.goto(`/v/${SLUG}`, { waitUntil: "domcontentloaded" });
    const baslik = page.getByRole("heading", { level: 1 }).first();
    await expect(baslik).toBeVisible({ timeout: 20_000 });
    const oncekiBaslik = (await baslik.textContent())?.trim();

    await page.reload({ waitUntil: "domcontentloaded" });
    const sonrakiBaslik = page.getByRole("heading", { level: 1 }).first();
    await expect(sonrakiBaslik).toBeVisible({ timeout: 20_000 });
    expect((await sonrakiBaslik.textContent())?.trim()).toBe(oncekiBaslik);
    expect(page.url()).toContain(`/v/${SLUG}`);
  });

  test("sahip oturumu olmayan ziyaretçide sahip yüzeyi açılmaz", async ({
    page,
  }) => {
    await page.goto(`/v/${SLUG}`, { waitUntil: "domcontentloaded" });
    await expect(page.getByRole("heading", { level: 1 }).first()).toBeVisible({
      timeout: 20_000,
    });

    const sahipCerezi = (await page.context().cookies()).find(
      (c) => c.name === "vixrex_owner_session",
    );
    expect(sahipCerezi).toBeUndefined();
    await expect(page.locator('[data-testid="owner-shell"]')).toHaveCount(0);
    await expect(
      page.locator('[data-testid="owner-assistant-panel"]'),
    ).toHaveCount(0);

    await page.reload({ waitUntil: "domcontentloaded" });
    await expect(page.getByRole("heading", { level: 1 }).first()).toBeVisible({
      timeout: 20_000,
    });
    await expect(page.locator('[data-testid="owner-shell"]')).toHaveCount(0);
  });

  test("farklı sekme aynı vitrini aynı şekilde açar", async ({ browser }) => {
    const context = await browser.newContext();
    const sekme1 = await context.newPage();
    await sekme1.goto(`/v/${SLUG}`, { waitUntil: "domcontentloaded" });
    const baslik1 = sekme1.getByRole("heading", { level: 1 }).first();
    await expect(baslik1).toBeVisible({ timeout: 20_000 });

    const sekme2 = await context.newPage();
    await sekme2.goto(`/v/${SLUG}`, { waitUntil: "domcontentloaded" });
    const baslik2 = sekme2.getByRole("heading", { level: 1 }).first();
    await expect(baslik2).toBeVisible({ timeout: 20_000 });

    expect((await baslik2.textContent())?.trim()).toBe(
      (await baslik1.textContent())?.trim(),
    );
    await context.close();
  });
});

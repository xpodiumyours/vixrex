import { expect, test } from "@playwright/test";

const DEMO_SLUG = "kiralik-butik";

test("mobil cihazda vitrin yan taşma yapmaz ve ana CTA ekran içinde kalır", async ({ page }) => {
  await page.goto(`/v/${DEMO_SLUG}`, { waitUntil: "domcontentloaded" });

  const heading = page.getByRole("heading", { level: 1 }).first();
  await expect(heading).toBeVisible({ timeout: 20_000 });

  const hasHorizontalOverflow = await page.evaluate(() => {
    const doc = document.documentElement;
    return doc.scrollWidth > doc.clientWidth + 2;
  });
  expect(hasHorizontalOverflow).toBe(false);

  expect(await page.evaluate(() => document.body.scrollHeight > 0)).toBe(true);

  const whatsapp = page.locator('a[href*="wa.me"]').first();
  await expect(whatsapp).toBeVisible({ timeout: 10_000 });
  await whatsapp.scrollIntoViewIfNeeded().catch(() => {});
  await page.waitForTimeout(300);
  const box = await whatsapp.boundingBox();
  expect(box).not.toBeNull();
  if (box) {
    const viewport = page.viewportSize();
    expect(viewport).not.toBeNull();
    if (viewport) {
      expect(box.x).toBeGreaterThanOrEqual(-2);
      expect(box.x + box.width).toBeLessThanOrEqual(viewport.width + 2);
      expect(box.width).toBeGreaterThan(10);
      expect(box.height).toBeGreaterThan(10);
    }
  }

  const overlappingPairs = await page.evaluate(() => {
    const ctas = Array.from(document.querySelectorAll('a[href*="wa.me"], button'));
    let overlaps = 0;
    for (let i = 0; i < ctas.length; i++) {
      for (let j = i + 1; j < ctas.length; j++) {
        const a = (ctas[i] as HTMLElement).getBoundingClientRect();
        const b = (ctas[j] as HTMLElement).getBoundingClientRect();
        if (a.width === 0 || a.height === 0 || b.width === 0 || b.height === 0) continue;
        const overlapX = Math.max(0, Math.min(a.right, b.right) - Math.max(a.left, b.left));
        const overlapY = Math.max(0, Math.min(a.bottom, b.bottom) - Math.max(a.top, b.top));
        if (overlapX > 8 && overlapY > 8) overlaps++;
      }
    }
    return overlaps;
  });
  expect(overlappingPairs).toBe(0);
});

test("mobil cihazda ana sayfa yan taşma yapmaz", async ({ page }) => {
  await page.goto("/", { waitUntil: "domcontentloaded" });
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= document.documentElement.clientWidth + 2)).toBe(true);
  await expect(page.getByRole("heading", { level: 1 }).first()).toBeVisible({ timeout: 15_000 });
});

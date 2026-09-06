import { expect, test, type Page } from "@playwright/test";

const slug = "kuafor-icin-internet-sitesi";

async function blogAkisiniDogrula(page: Page, ad: string) {
  await page.goto("/blog");
  await expect(page.getByRole("heading", { name: "Esnaf için dijital rehber" })).toBeVisible();
  await expect(page.getByRole("link", { name: /Kuaför salonu için internet sitesi/ })).toBeVisible();
  await page.screenshot({ path: `test-results/blog-${ad}-liste.png`, fullPage: true });

  await page.goto(`/blog/${slug}`);
  await expect(page.getByRole("heading", { name: "Kuaför salonu için internet sitesi nasıl yapılır?" })).toBeVisible();
  await expect(page.getByRole("link", { name: "Keşfet'e bak" })).toBeVisible();
  await page.screenshot({ path: `test-results/blog-${ad}-detay.png`, fullPage: true });
}

test("Katman 1 blog — masaüstü", async ({ page }) => {
  await page.setViewportSize({ width: 1440, height: 1100 });
  await blogAkisiniDogrula(page, "desktop");
});

test("Katman 1 blog — mobil", async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await blogAkisiniDogrula(page, "mobile");
});

import { test, expect } from "@playwright/test";

test.describe("reload / farklı sekme devam", () => {
  const baseUrl =
    process.env.E2E_PUBLIC_BASE_URL ?? "https://vixrex-public.vercel.app";

  test("reload sonrası sahip oturumu korur", async ({ page }) => {
    await page.goto(`${baseUrl}/v/demo-umranieh`);
    const cookie1 = await page.context().cookies();
    const ownerCookie = cookie1.find((c) => c.name === "owner_session");
    expect(ownerCookie).toBeTruthy();
    await page.reload();
    const cookie2 = await page.context().cookies();
    const ownerCookie2 = cookie2.find((c) => c.name === "owner_session");
    expect(ownerCookie2).toBeTruthy();
    expect(ownerCookie2?.value).toBe(ownerCookie?.value);
    const urlAfter = page.url();
    expect(urlAfter.includes("/v/demo-umranieh")).toBeTruthy();
  });

  test("farklı sekme aynı sahip oturumunu paylaşır", async ({ browser }) => {
    const context = await browser.newContext({ baseURL: baseUrl });
    const page1 = await context.newPage();
    await page1.goto(`${baseUrl}/v/demo-umranieh`);
    const cookie1 = (await context.cookies()).find(
      (c) => c.name === "owner_session",
    );
    expect(cookie1).toBeTruthy();
    const page2 = await context.newPage();
    await page2.goto(`${baseUrl}/v/demo-umranieh`);
    await expect(
      page2.locator("[data-testid=\"owner-shell\"]"),
    ).toBeVisible({ timeout: 15000 });
    const cookie2 = (await context.cookies()).find(
      (c) => c.name === "owner_session",
    );
    expect(cookie2).toBeTruthy();
    expect(cookie2?.value).toBe(cookie1?.value);
    await context.close();
  });

  test("reload sonrası asistan konuşması devam eder", async ({ page }) => {
    await page.goto(`${baseUrl}/v/demo-umranieh`);
    await expect(
      page.locator("[data-testid=\"owner-assistant-panel\"]"),
    ).toBeVisible({ timeout: 15000 });
    const mesajlarkaBefore = await page
      .locator("[data-testid=\"assistant-message\"]")
      .count();
    await page.reload();
    const mesajlarkaAfter = await page
      .locator("[data-testid=\"assistant-message\"]")
      .count();
    expect(mesajlarkaAfter).toBeGreaterThanOrEqual(mesajlarkaBefore);
  });
});

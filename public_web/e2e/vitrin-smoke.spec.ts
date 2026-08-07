import { expect, test } from "@playwright/test";

/**
 * Canlı demo kiralanabilir vitrin (Supabase is_demo).
 * Panel HTML kalitesi / yayın yüzeyi kırılırsa burası kırmızıya düşer.
 */
const DEMO_SLUG = "kiralik-butik";

test.describe("public vitrin smoke", () => {
  test("demo slug renders store name heading", async ({ page }) => {
    const response = await page.goto(`/v/${DEMO_SLUG}`, {
      waitUntil: "domcontentloaded",
    });

    expect(response?.ok()).toBeTruthy();

    const heading = page.getByRole("heading", { level: 1 });
    await expect(heading).toBeVisible({ timeout: 20_000 });
    await expect(heading).not.toHaveText("");
  });

  test("unknown slug returns not-found (404)", async ({ page }) => {
    const response = await page.goto("/v/__vixrex-e2e-missing-slug__", {
      waitUntil: "domcontentloaded",
    });

    // Next notFound → 404; bazı deploy'larda soft 200 + not-found UI olabilir.
    const status = response?.status() ?? 0;
    if (status === 404) {
      expect(status).toBe(404);
      return;
    }

    await expect(
      page.getByText(/bulunamad|not found|404/i).first(),
    ).toBeVisible({ timeout: 15_000 });
  });
});

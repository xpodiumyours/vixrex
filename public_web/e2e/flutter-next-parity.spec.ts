import { expect, test, type Page } from "@playwright/test";
import { readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

type BrowserContract = {
  enabled?: boolean;
  route: string;
  scope_text: string;
  open_button?: string;
  viewport?: { width: number; height: number };
  expected_buttons: string[];
  forbidden_buttons?: string[];
};

type ParityContract = {
  id: string;
  browser?: BrowserContract;
};

type Manifest = {
  reference: string;
  contracts: ParityContract[];
};

const here = dirname(fileURLToPath(import.meta.url));
const manifestPath = resolve(here, "../../.github/parity/contracts.json");
const manifest = JSON.parse(readFileSync(manifestPath, "utf8")) as Manifest;

const CONSENT = JSON.stringify({
  necessary: true,
  analytics: false,
  marketing: false,
  updatedAt: "2026-09-07T00:00:00.000Z",
});

async function contractSayfasiniAc(page: Page, browser: BrowserContract) {
  await page.addInitScript((consent) => {
    window.localStorage.setItem("vixrex_cookie_consent", consent);
  }, CONSENT);

  if (browser.viewport) {
    await page.setViewportSize(browser.viewport);
  }

  await page.goto(browser.route, { waitUntil: "domcontentloaded" });

  if (browser.open_button) {
    await page.getByRole("button", { name: browser.open_button, exact: true }).click();
  }

  await expect(page.getByText(browser.scope_text, { exact: true })).toBeVisible();
}

for (const contract of manifest.contracts) {
  const browser = contract.browser;
  if (!browser?.enabled) continue;

  test(`${contract.id}: Flutter Web hızlı seçenek sözleşmesi`, async ({ page }) => {
    await contractSayfasiniAc(page, browser);

    const scopeLabel = page.getByText(browser.scope_text, { exact: true });
    const scope = scopeLabel.locator("..");
    const buttons = scope.getByRole("button");

    await expect(buttons).toHaveCount(browser.expected_buttons.length);

    for (const [index, label] of browser.expected_buttons.entries()) {
      await expect(buttons.nth(index)).toHaveText(label);
    }

    for (const label of browser.forbidden_buttons ?? []) {
      await expect(
        scope.getByRole("button", { name: label, exact: true }),
      ).toHaveCount(0);
    }
  });

  if (contract.id === "landing-onboarding-welcome") {
    test(`${contract.id}: Bakınıyorum welcome durumunda kalır`, async ({ page }) => {
      await contractSayfasiniAc(page, browser);
      await page.getByRole("button", { name: "Bakınıyorum", exact: true }).click();

      await expect(page).toHaveURL(/\/$/);
      await expect(page.getByText("Şimdilik bakınıyorum", { exact: true })).toBeVisible();
      await expect(
        page.getByText("Tamam. Hazır olunca buradayım.", { exact: true }),
      ).toBeVisible();
      await expect(page.getByText(browser.scope_text, { exact: true })).toBeVisible();
    });

    test(`${contract.id}: Hazır Vitrin Seç önce niyet sorusunu açar`, async ({ page }) => {
      await contractSayfasiniAc(page, browser);
      await page.getByRole("button", { name: "Hazır Vitrin Seç", exact: true }).click();

      await expect(page).toHaveURL(/\/$/);
      await expect(page.getByTestId("landing-template-intent")).toBeVisible();
      await expect(page.getByText(/Ne iş yapıyorsun/i)).toBeVisible();
    });

    test(`${contract.id}: Sıfırdan Oluştur işletme adı adımını açar`, async ({ page }) => {
      await contractSayfasiniAc(page, browser);
      await page.getByRole("button", { name: "Sıfırdan Oluştur", exact: true }).click();

      await expect(page).toHaveURL(/\/$/);
      await expect(page.getByTestId("landing-name-step")).toBeVisible();
      await expect(page.getByPlaceholder("İşletme adınız")).toBeVisible();
    });
  }
}

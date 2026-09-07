import { expect, test } from "@playwright/test";
import { readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

type BrowserContract = {
  enabled?: boolean;
  route: string;
  scope_text: string;
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

for (const contract of manifest.contracts) {
  const browser = contract.browser;
  if (!browser?.enabled) continue;

  test(`${contract.id}: Flutter Web hızlı seçenek sözleşmesi`, async ({ page }) => {
    if (browser.viewport) {
      await page.setViewportSize(browser.viewport);
    }

    await page.goto(browser.route, { waitUntil: "domcontentloaded" });

    const scopeLabel = page.getByText(browser.scope_text, { exact: true });
    await expect(scopeLabel).toBeVisible();

    const scope = scopeLabel.locator("..");
    const buttons = scope.getByRole("button");

    await expect(buttons).toHaveCount(browser.expected_buttons.length);

    for (const [index, label] of browser.expected_buttons.entries()) {
      const escaped = label.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
      await expect(buttons.nth(index)).toHaveText(new RegExp(escaped));
    }

    for (const label of browser.forbidden_buttons ?? []) {
      await expect(
        scope.getByRole("button", { name: label, exact: true }),
      ).toHaveCount(0);
    }
  });
}

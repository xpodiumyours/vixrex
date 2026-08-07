import { Page, expect } from "@playwright/test";

/**
 * Public vitrin sayfası için Page Object Model.
 */
export class VitrinPage {
  readonly page: Page;
  readonly slug: string;

  constructor(page: Page, slug: string) {
    this.page = page;
    this.slug = slug;
  }

  async goto() {
    await this.page.goto(`/v/${this.slug}`, {
      waitUntil: "domcontentloaded",
    });
  }

  async waitForLoad() {
    await this.page.goto(`/v/${this.slug}`, { waitUntil: "networkidle" });
  }

  get heading() {
    return this.page.getByRole("heading", { level: 1 });
  }

  get whatsappLink() {
    return this.page.locator('a[href*="wa.me"]').first();
  }

  get productCards() {
    return this.page.locator('[class*="card"], [class*="product"], article');
  }

  get seoTitle() {
    return this.page.title();
  }

  get metaDescription() {
    return this.page.locator('meta[name="description"]');
  }

  async expectHeadingVisible() {
    await expect(this.heading).toBeVisible({ timeout: 20_000 });
    await expect(this.heading).not.toHaveText("");
  }

  async expectWhatsAppFormat() {
    const count = await this.whatsappLink.count();
    if (count === 0) return;
    const href = await this.whatsappLink.getAttribute("href");
    expect(href).toContain("wa.me/");
    expect(href).toMatch(/wa\.me\/\d+/);
  }
}

/**
 * Keşfet (ana sayfa) Page Object.
 */
export class KesfetPage {
  readonly page: Page;

  constructor(page: Page) {
    this.page = page;
  }

  async goto() {
    await this.page.goto("/", { waitUntil: "domcontentloaded" });
  }

  async waitForLoad() {
    await this.page.goto("/", { waitUntil: "networkidle" });
  }

  get searchInput() {
    return this.page.locator(
      'input[type="search"], input[placeholder*="ara"], input[placeholder*="search"]',
    );
  }

  get vitrinLinks() {
    return this.page.locator('a[href*="/v/"]');
  }

  get footerPrivacyLink() {
    return this.page.locator('a[href="/privacy"]');
  }
}

/**
 * Vitrin düzenleme admin sayfası Page Object (Flutter web).
 */
export class AdminPage {
  readonly page: Page;

  constructor(page: Page) {
    this.page = page;
  }

  async gotoApp() {
    await this.page.goto("/app", { waitUntil: "domcontentloaded" });
  }

  async waitForAppLoad() {
    await this.page.goto("/app", { waitUntil: "networkidle", timeout: 30_000 });
  }
}

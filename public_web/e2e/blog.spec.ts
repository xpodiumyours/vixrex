import { test, expect } from "@playwright/test";

async function tasmaYok(page: import("@playwright/test").Page) {
  expect(
    await page.evaluate(
      () => document.documentElement.scrollWidth <= innerWidth,
    ),
  ).toBe(true);
}

test("masaüstü: arama, kategori, boş sonuç ve sıfırlama", async ({ page }) => {
  await page.setViewportSize({ width: 1440, height: 1000 });
  const hatalar: string[] = [];
  page.on("pageerror", (hata) => hatalar.push(hata.message));
  await page.goto("/blog");
  await expect(page.getByRole("heading", { level: 1 })).toContainText(
    "İşletmen için",
  );
  await expect(page.locator('meta[name="robots"]')).toHaveAttribute(
    "content",
    /noindex/,
  );
  await page.getByRole("searchbox").fill("KUAFOR");
  await expect(page.locator("article")).toHaveCount(1);
  await expect(page.locator("article")).toContainText("Kuaför");
  await page
    .getByRole("button", { name: "Google ve Keşfedilme", exact: true })
    .click();
  await expect(page.getByText("Bu aramada yazı bulunamadı.")).toBeVisible();
  await page.getByRole("button", { name: "Tüm rehberleri göster" }).click();
  await expect(page.locator("article")).toHaveCount(5);
  await page
    .getByRole("button", { name: "Müşteri İletişimi", exact: true })
    .click();
  await expect(page.locator("article")).toHaveCount(1);
  await expect(page.locator("article")).toContainText("Müşteri mesajlarına");
  await tasmaYok(page);
  expect(hatalar).toEqual([]);
});

test("320px ve 390px: taşma, kategori ve yazı içindekiler", async ({
  page,
}) => {
  for (const width of [320, 390]) {
    await page.setViewportSize({ width, height: 844 });
    await page.goto("/blog");
    await expect(
      page
        .getByRole("navigation", { name: "Ana gezinme" })
        .getByRole("link", { name: "Blog", exact: true }),
    ).toBeVisible();
    await tasmaYok(page);
    await page.getByRole("link", { name: "Rehberi oku", exact: true }).click();
    await expect(page.getByRole("heading", { level: 1 })).toContainText(
      "İlk dijital vitrinin",
    );
    await page.locator("summary").filter({ hasText: "Bu yazıda" }).click();
    await page
      .getByRole("navigation", { name: "Bu yazıda mobil", exact: true })
      .getByRole("link")
      .first()
      .click();
    await expect(page).toHaveURL(/#isletmeni-bir-cumlede-anlat/);
    await tasmaYok(page);
  }
});

test("altı yazı, kaynaklar, RSS, paylaşım görseli ve bilinmeyen yazı", async ({
  page,
  request,
}) => {
  const sluglar = [
    "dijital-vitrin-hazirlik-listesi",
    "musteri-mesajlari-icin-yanit-ornekleri",
    "kafe-dijital-menu-hazirlama",
    "urun-fotografi-cekme-rehberi",
    "kuafor-icin-internet-sitesi",
    "isletmemi-googleda-nasil-gosteririm",
  ];
  for (const slug of sluglar) {
    const response = await page.goto(`/blog/${slug}`);
    expect(response?.status()).toBe(200);
    await expect(page.locator("h1")).toHaveCount(1);
    await expect(page.locator('link[rel="canonical"]')).toHaveAttribute(
      "href",
      new RegExp(`/blog/${slug}$`),
    );
    await expect(
      page.locator('meta[property="og:image"]').first(),
    ).toHaveAttribute("content", new RegExp(`/blog/kapak/${slug}$`));
    const structured = await page
      .locator('script[type="application/ld+json"]')
      .allTextContents();
    expect(
      structured
        .map((s) => JSON.parse(s))
        .some((s) => s["@type"] === "BlogPosting"),
    ).toBe(true);
  }
  await expect(
    page.getByRole("heading", { name: "Kaynaklar", exact: true }),
  ).toBeVisible();
  const rss = await request.get("/blog/rss.xml");
  expect(rss.status()).toBe(200);
  const xml = await rss.text();
  for (const slug of sluglar) expect(xml).toContain(`/blog/${slug}`);
  const kapak = await request.get(`/blog/kapak/${sluglar[0]}`);
  expect(kapak.status()).toBe(200);
  expect(kapak.headers()["content-type"]).toContain("image/png");
  expect((await request.get("/blog/bilinmeyen-yazi")).status()).toBe(404);
  expect((await request.get("/blog/kapak/bilinmeyen-yazi")).status()).toBe(404);
});

test("paylaşım kopyalama ve başarısız kopyalama geri bildirimi", async ({
  page,
  context,
}) => {
  await context.grantPermissions(["clipboard-read", "clipboard-write"]);
  await page.goto("/blog/dijital-vitrin-hazirlik-listesi");
  await page
    .getByRole("button", { name: "Bağlantıyı kopyala", exact: true })
    .click();
  await expect(page.getByRole("status")).toContainText("Bağlantı kopyalandı.");
  expect(await page.evaluate(() => navigator.clipboard.readText())).toContain(
    "/blog/dijital-vitrin-hazirlik-listesi",
  );
  await page.evaluate(() =>
    Object.defineProperty(navigator.clipboard, "writeText", {
      value: () => Promise.reject(new Error("denied")),
      configurable: true,
    }),
  );
  await page
    .getByRole("button", { name: "Bağlantıyı kopyala", exact: true })
    .click();
  await expect(page.getByRole("status")).toContainText(
    "Bağlantı kopyalanamadı.",
  );
});

test("landing üst menü, rehber bölümü ve footer bloga ulaşır", async ({
  page,
}) => {
  await page.goto("/");
  await expect(
    page
      .getByRole("navigation", { name: "Ana gezinme" })
      .getByRole("link", { name: "Blog", exact: true }),
  ).toHaveAttribute("href", "/blog");
  await expect(
    page.getByRole("heading", { name: "İşletmen için pratik rehberler." }),
  ).toBeVisible();
  await expect(
    page.getByRole("link", { name: "Tüm rehberler" }),
  ).toHaveAttribute("href", "/blog");
  await page
    .getByRole("navigation", { name: "Ana gezinme" })
    .getByRole("link", { name: "Blog", exact: true })
    .click();
  await expect(page).toHaveURL(/\/blog$/);
  await page.getByRole("link", { name: "Yayın ilkeleri", exact: true }).click();
  await expect(page.getByRole("heading", { level: 1 })).toHaveText(
    "Yayın ilkeleri",
  );
});

import { expect, test } from "@playwright/test";

/**
 * Platform yüzeyi E2E — ana sayfa ve Keşfet dizini (#344).
 *
 * 2026-08-26'DA GERÇEK İDDİALARA ÇEVRİLDİ. Bu dosyadaki her kontrol
 * eskiden `if (count > 0)` içine sarılmıştı; yani hiçbir şey bulunmadığında
 * da yeşil yanıyordu. `/` o dönemde uygulamaya yönlendiği için dosya
 * yıllardır boş bir sayfaya karşı "geçiyor" durumdaydı.
 *
 * Buradaki asıl iddia şu: sayfa SUNUCUDA üretiliyor. `page.content()`
 * ilk HTML'i okur; metin orada görünüyorsa Google da görüyor demektir.
 * #344'ün tamamı bu tek cümleyle ilgili.
 */
test.describe("ana sayfa", () => {
  test("200 döner ve içeriği sunucuda üretilmiş HTML'de görünür", async ({
    page,
  }) => {
    const response = await page.goto("/", { waitUntil: "domcontentloaded" });
    expect(response?.ok()).toBeTruthy();

    const html = await page.content();
    expect(html).toContain("birkaç dakikada hazır");
    expect(html).toContain("Dijital vitrinini kolayca hazırla");
    expect(html).toContain("Üç adımda dijital vitrinin hazır");
  });

  test("uygulamaya yönlendirmez", async ({ page }) => {
    await page.goto("/", { waitUntil: "domcontentloaded" });
    expect(new URL(page.url()).pathname).toBe("/");
  });

  test("Keşfet ve yasal sayfalara iç bağlantı verir", async ({ page }) => {
    await page.goto("/", { waitUntil: "domcontentloaded" });

    await expect(page.locator('a[href^="/kesfet"]').first()).toBeVisible();
    // #346: yasal sayfalara sitenin hiçbir yerinden bağlantı yoktu.
    await expect(page.locator('a[href="/privacy"]')).toHaveCount(1);
    await expect(page.locator('a[href="/legal/terms"]')).toHaveCount(1);
  });

  test("platform yapılandırılmış verisi basılır", async ({ page }) => {
    await page.goto("/", { waitUntil: "domcontentloaded" });
    const html = await page.content();
    expect(html).toContain('"@type":"Organization"');
    expect(html).toContain('"@type":"WebSite"');
  });
});

test.describe("Keşfet dizini", () => {
  test("vitrin listesi ve vitrin bağlantıları görünür", async ({ page }) => {
    const response = await page.goto("/kesfet", {
      waitUntil: "domcontentloaded",
    });
    expect(response?.ok()).toBeTruthy();

    const html = await page.content();
    expect(html).toContain("Keşfet");

    const vitrinLinkleri = page.locator('a[href^="/v/"]');
    expect(await vitrinLinkleri.count()).toBeGreaterThan(0);
  });

  test("kategori süzgeçleri gerçek sayfalara bağlanır", async ({ page }) => {
    await page.goto("/kesfet", { waitUntil: "domcontentloaded" });

    const kategoriLinki = page.locator('a[href^="/kesfet/"]').first();
    await expect(kategoriLinki).toBeVisible();

    const hedef = await kategoriLinki.getAttribute("href");
    expect(hedef).toBeTruthy();

    const response = await page.goto(hedef!, { waitUntil: "domcontentloaded" });
    expect(response?.ok()).toBeTruthy();
    await expect(page.locator("h1")).toBeVisible();
  });

  test("kiralık kart diyalog + native form POST akışını sunar", async ({
    page,
  }) => {
    await page.goto("/kesfet", { waitUntil: "domcontentloaded" });

    const kiralaButonu = page.getByRole("button", { name: "Kirala" });
    const adet = await kiralaButonu.count();
    // Kiralık şablon yoksa iddia edilecek bir şey de yok; ama varsa
    // fiyat vaadi, Kirala diyaloğu ve native form POST mutlaka doğru olmalı.
    // Gerçek: "Kirala" ayrı sayfaya (/rent-demo?slug=) gitmez — useKesfetKirala
    // Keşfet içi <dialog> açar, misafir yolunda gizli form POST eder.
    if (adet > 0) {
      const html = await page.content();
      expect(html).toContain("Aylık 299 TL");
      expect(html).toContain('action="/api/rent-demo"');

      await kiralaButonu.first().click();
      await expect(page.locator("dialog").first()).toBeVisible();
    }
  });

  test("rent-demo sayfası native form POST köprüsünü içerir", async ({
    page,
  }) => {
    await page.goto("/rent-demo?slug=ornek-vitrin", {
      waitUntil: "domcontentloaded",
    });

    const html = await page.content();
    expect(html).toContain("Vitrin hazırlanıyor");
    expect(html).toContain('action="/api/rent-demo"');
    expect(html).toContain('name="slug"');
  });

  test("vitrin kartına tıklamak vitrin sayfasını açar", async ({ page }) => {
    await page.goto("/kesfet", { waitUntil: "domcontentloaded" });

    await page.locator('a[href^="/v/"]').first().click();
    await page.waitForURL("**/v/**", { timeout: 15_000 });
    expect(page.url()).toContain("/v/");
  });
});

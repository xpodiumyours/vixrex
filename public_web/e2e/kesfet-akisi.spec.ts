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

  test("kiralık kart güvenli köprüye ve fiyat vaadine bağlıdır", async ({
    page,
  }) => {
    await page.goto("/kesfet", { waitUntil: "domcontentloaded" });

    const kiralaLinki = page.locator('a[href^="/rent-demo?slug="]');
    const adet = await kiralaLinki.count();
    // Kiralık şablon yoksa iddia edilecek bir şey de yok; ama varsa
    // fiyat vaadi ve köprü mutlaka doğru olmalı.
    if (adet > 0) {
      const html = await page.content();
      expect(html).toContain("Aylık 299 TL");
      expect(html).not.toContain("/api/rent-demo");
    }
  });

  test("vitrin kartına tıklamak vitrin sayfasını açar", async ({ page }) => {
    await page.goto("/kesfet", { waitUntil: "domcontentloaded" });

    await page.locator('a[href^="/v/"]').first().click();
    await page.waitForURL("**/v/**", { timeout: 15_000 });
    expect(page.url()).toContain("/v/");
  });

  for (const senaryo of [
    { genislik: 375, yukseklik: 812, yanMenu: false, kolon: 2 },
    { genislik: 768, yukseklik: 1024, yanMenu: false, kolon: 3 },
    { genislik: 901, yukseklik: 900, yanMenu: true, kolon: 2 },
    { genislik: 1024, yukseklik: 900, yanMenu: true, kolon: 3 },
    { genislik: 1280, yukseklik: 900, yanMenu: true, kolon: 4 },
  ]) {
    test(`${senaryo.genislik}px kabuk ve kart kolonları taşmadan yerleşir`, async ({
      page,
    }) => {
      await page.setViewportSize({
        width: senaryo.genislik,
        height: senaryo.yukseklik,
      });
      const response = await page.goto("/kesfet", {
        waitUntil: "domcontentloaded",
      });
      expect(response?.ok()).toBeTruthy();

      const yanMenu = page.getByRole("complementary", {
        name: "Uygulama menüsü",
      });
      if (senaryo.yanMenu) {
        await expect(yanMenu).toBeVisible();
      } else {
        await expect(yanMenu).toBeHidden();
      }

      const sayfaOlculeri = await page.evaluate(() => ({
        icGenislik: window.innerWidth,
        belgeGenisligi: document.documentElement.scrollWidth,
      }));
      expect(sayfaOlculeri.belgeGenisligi).toBeLessThanOrEqual(
        sayfaOlculeri.icGenislik
      );

      const baslikKutusu = await page.locator("#kesfet-baslik").boundingBox();
      expect(baslikKutusu).not.toBeNull();
      if (!senaryo.yanMenu) {
        expect(baslikKutusu!.y).toBeLessThan(160);
      }

      const kartlar = page.locator('ul[aria-label="Vitrinler"] > li');
      expect(await kartlar.count()).toBeGreaterThanOrEqual(senaryo.kolon);
      const kartKutulari = await kartlar.evaluateAll((elemanlar) =>
        elemanlar.slice(0, 8).map((eleman) => {
          const kutu = eleman.getBoundingClientRect();
          return { x: kutu.x, y: kutu.y };
        })
      );
      const ilkSatirY = kartKutulari[0].y;
      const ilkSatirKolonlari = kartKutulari.filter(
        (kutu) => Math.abs(kutu.y - ilkSatirY) < 2
      ).length;
      expect(ilkSatirKolonlari).toBe(senaryo.kolon);

      const durumCubugu = page.getByTestId("kesfet-status-bar");
      if (senaryo.yanMenu) {
        await expect(durumCubugu).toBeVisible();
        const [durumKutusu, icerikKutusu] = await Promise.all([
          durumCubugu.boundingBox(),
          page.locator('section[aria-labelledby="kesfet-baslik"]').boundingBox(),
        ]);
        expect(durumKutusu).not.toBeNull();
        expect(icerikKutusu).not.toBeNull();
        expect(Math.abs(durumKutusu!.x - icerikKutusu!.x)).toBeLessThan(2);
        expect(
          Math.abs(durumKutusu!.width - icerikKutusu!.width)
        ).toBeLessThan(2);
      } else {
        await expect(durumCubugu).toBeHidden();
      }
    });
  }
});

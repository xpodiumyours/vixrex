import { expect, test } from "@playwright/test";
import * as fs from "fs";
import * as path from "path";

/**
 * Esnaf uçtan uca akışı — tek test, 8 adım.
 * Ürün kodu değiştirilmez, sadece gözlem.
 * Her adımda ekran görüntüsü + konsol/ ağ hataları toplanır.
 */
test.describe("esnaf akışı — vitrin oluşturma", () => {
  test("ana sayfa → asistan → yayın → vitrin linki", async ({ page }) => {
    const consoleErrors: string[] = [];
    const pageErrors: string[] = [];
    const failedRequests: string[] = [];
    let createStoreSlug: string | null = null;

    page.on("console", (msg) => {
      if (msg.type() === "error") consoleErrors.push(msg.text());
      if (/Failed to load resource|violates.*Content Security Policy/i.test(msg.text())) {
        consoleErrors.push(msg.text());
      }
    });
    page.on("pageerror", (err) => pageErrors.push(err.message));
    page.on("response", async (resp) => {
      const status = resp.status();
      const url = resp.url();
      if (url.includes("/api/create-store")) {
        try {
          const body = await resp.json();
          if (body?.slug) createStoreSlug = String(body.slug);
        } catch {}
      }
      if (status >= 400) {
        failedRequests.push(`${status} ${resp.request().method()} ${url}`);
      }
    });
    page.on("requestfailed", (req) => {
      failedRequests.push(`FAILED ${req.method()} ${req.url()} - ${req.failure()?.errorText}`);
    });

    // Screenshot klasörü — repo kökü + public_web altı ikisi de
    const outDirs = [
      path.resolve(process.cwd(), "test-sonuc"),
      path.resolve(process.cwd(), "..", "test-sonuc"),
      path.resolve("test-sonuc"),
    ];
    for (const d of outDirs) {
      try { fs.mkdirSync(d, { recursive: true }); } catch {}
    }
    const snapDir = fs.existsSync(path.resolve(process.cwd(), "test-sonuc"))
      ? path.resolve(process.cwd(), "test-sonuc")
      : fs.existsSync(path.resolve(process.cwd(), "..", "test-sonuc"))
        ? path.resolve(process.cwd(), "..", "test-sonuc")
        : path.resolve("test-sonuc");

    async function shot(name: string) {
      const p = path.join(snapDir, name);
      await page.screenshot({ path: p, fullPage: true });
    }

    const adimSonuc: Array<{ adim: string; durum: "geçti" | "kaldı"; hata: string }> = [];
    function kaydet(adim: string, durum: "geçti" | "kaldı", hata = "") {
      adimSonuc.push({ adim, durum, hata });
    }

    // — Ön adım: kalıcı test hesabıyla giriş yap (yeni hesap açma yok)
    try {
      await page.goto("/giris", { waitUntil: "domcontentloaded" });
      await expect(page.getByRole("heading", { name: /Giriş Yap/i })).toBeVisible({ timeout: 10_000 });
      // Çerez bannerı /giris'te de var — kapatmazsak formun üstünü kapatmıyor ama maskot testindeki gibi kapat
      const girisCookieBtn = page.getByRole("button", { name: /Yalnızca gerekli|Tümünü kabul et/i });
      if (await girisCookieBtn.first().isVisible({ timeout: 1500 }).catch(() => false)) {
        await girisCookieBtn.first().click();
      }
      const emailInput = page.getByPlaceholder("ornek@eposta.com");
      const sifreInput = page.getByPlaceholder("Şifren");
      await expect(emailInput).toBeVisible({ timeout: 5000 });
      await expect(sifreInput).toBeVisible({ timeout: 5000 });
      await emailInput.fill("vixrex.test.1787911144069@gmail.com");
      await sifreInput.fill("Test!1787911144069");
      await expect(emailInput).toHaveValue("vixrex.test.1787911144069@gmail.com", { timeout: 3000 });
      await page.getByRole("button", { name: /^Giriş Yap$/ }).click();
      await page.waitForURL("**/app**", { timeout: 15000 });
      await expect(page).toHaveURL(/\/app/);
      kaydet("0. Giriş (kalıcı test hesabı)", "geçti");
      await shot("00-giris.png");
    } catch (e) {
      kaydet("0. Giriş (kalıcı test hesabı)", "kaldı", String((e as Error).message).slice(0, 500));
      await shot("00-giris-hata.png");
      console.log("\n=== ADIM TABLOSU ==="); console.table(adimSonuc);
      console.log("\n=== KONSOL HATALARI ===", consoleErrors);
      console.log("\n=== BAŞARISIZ AĞ ===", failedRequests);
      throw e;
    }

    // — Adım 1: Ana sayfayı aç, asistanı başlat
    try {
      await page.goto("/", { waitUntil: "domcontentloaded" });
      await shot("01-karsilama.png");

      // Çerez bannerı varsa kapat — maskot onun altında gizli (MascotFab z-40 vs banner z-50)
      const cookieDialog = page.getByRole("dialog", { name: /Çerez tercihleri/i });
      if (await cookieDialog.isVisible({ timeout: 2000 }).catch(() => false)) {
        const yalnizca = cookieDialog.getByRole("button", { name: /Yalnızca gerekli/i });
        if (await yalnizca.isVisible({ timeout: 1500 }).catch(() => false)) {
          await yalnizca.click();
        } else {
          await cookieDialog.getByRole("button", { name: /Tümünü kabul et/i }).click().catch(async () => {
            await cookieDialog.getByRole("button").first().click();
          });
        }
        await expect(cookieDialog).toBeHidden({ timeout: 5000 }).catch(() => {});
      }

      // Maskot balonu ve düğmesi
      const mascotBtn = page.getByRole("button", { name: /Vixrex Asistan'ı aç/i });
      await expect(mascotBtn).toBeVisible({ timeout: 10_000 });
      await mascotBtn.click();

      // Asistan karşılama: "Vitrininizi Oluşturun" — tek öğeye kilitle
      const karsilama = page.getByRole("paragraph").filter({ hasText: /Vitrininizi Oluşturun/i }).first();
      await expect(karsilama).toBeVisible({ timeout: 10_000 });
      // Hızlı seçenekler: Hazır Vitrin Seç / Sıfırdan Oluştur / Bakınıyorum
      await expect(page.getByRole("button", { name: /Sıfırdan Oluştur/i })).toBeVisible({ timeout: 5000 });
      await shot("01b-asistan-acik.png");
      kaydet("1. Ana sayfa + asistan başlat", "geçti");
    } catch (e) {
      kaydet("1. Ana sayfa + asistan başlat", "kaldı", String((e as Error).message).slice(0, 400));
      await shot("01-hata.png");
      // Takıldık — tabloyu yaz ve testi bilerek düşür (ürün kodu düzeltme yok)
      console.log("\n=== ADIM TABLOSU ===");
      console.table(adimSonuc);
      console.log("\n=== KONSOL HATALARI ===", consoleErrors);
      console.log("\n=== SAYFA HATALARI ===", pageErrors);
      console.log("\n=== BAŞARISIZ AĞ ===", failedRequests);
      throw e;
    }

    // Adım 2: İşletme adı
    try {
      // welcome → Sıfırdan Oluştur tıkla
      await page.getByRole("button", { name: /Sıfırdan Oluştur/i }).click();
      // İşletme adı adımı: başlık "İşletme adınızı girin" — tek öğeye kilitle (iki paragraf eşleşiyordu)
      await expect(page.getByRole("paragraph").filter({ hasText: /İşletme adınızı girin/i }).first()).toBeVisible({ timeout: 10_000 });
      const nameInput = page.getByPlaceholder(/Ör\. Aymira Giyim/i);
      await expect(nameInput).toBeVisible({ timeout: 5000 });
      await nameInput.fill("Test Dukkan 123");
      await page.getByRole("button", { name: /İşletme Adı Ekle/i }).click();
      await shot("02-isletme-adi.png");
      kaydet("2. İşletme adı", "geçti");
    } catch (e) {
      kaydet("2. İşletme adı", "kaldı", String((e as Error).message).slice(0, 400));
      await shot("02-hata.png");
      console.log("\n=== ADIM TABLOSU ==="); console.table(adimSonuc);
      console.log("\n=== KONSOL HATALARI ===", consoleErrors);
      console.log("\n=== BAŞARISIZ AĞ ===", failedRequests);
      throw e;
    }

    // Adım 3: Kategori seç (ızgara) — tek öğeye kilitle
    try {
      await expect(page.getByRole("paragraph").filter({ hasText: /İşletme kategorinizi seçin/i }).first()).toBeVisible({ timeout: 10_000 });
      await expect(page.getByRole("paragraph").filter({ hasText: /İşini seç/i }).first()).toBeVisible({ timeout: 5000 });
      // Kategori ızgarası — Flutter Web ile aynı label seti, presentation uzun halleri de olabilir
      // Güvenli seçim: "Giyim" (her ortamda var) — ızgarada button olarak
      const giyimBtn = page.getByRole("button", { name: /^Giyim$/ });
      if (await giyimBtn.isVisible({ timeout: 3000 }).catch(() => false)) {
        await giyimBtn.click();
      } else {
        // fallback: ilk kategori butonu
        const ilk = page.locator("button").filter({ hasText: /Giyim|Butik|Gıda|Kafe|Kuaför|Teknik/i }).first();
        await expect(ilk).toBeVisible({ timeout: 5000 });
        await ilk.click();
      }
      await shot("03-kategori.png");
      kaydet("3. Kategori", "geçti");
    } catch (e) {
      kaydet("3. Kategori", "kaldı", String((e as Error).message).slice(0, 400));
      await shot("03-hata.png");
      console.log("\n=== ADIM TABLOSU ==="); console.table(adimSonuc);
      console.log("\n=== KONSOL HATALARI ===", consoleErrors);
      console.log("\n=== BAŞARISIZ AĞ ===", failedRequests);
      throw e;
    }

    // Adım 4: WhatsApp — tek öğeye kilitle
    try {
      await expect(page.getByRole("paragraph").filter({ hasText: /WhatsApp numaranızı ekleyin/i }).first()).toBeVisible({ timeout: 10_000 });
      const waInput = page.getByPlaceholder(/05xx xxx xx xx/i);
      await expect(waInput).toBeVisible({ timeout: 5000 });
      await waInput.fill("05551234567");
      await page.getByRole("button", { name: /WhatsApp Ekle/i }).click();
      await shot("04-whatsapp.png");
      kaydet("4. WhatsApp", "geçti");
    } catch (e) {
      kaydet("4. WhatsApp", "kaldı", String((e as Error).message).slice(0, 400));
      await shot("04-hata.png");
      console.log("\n=== ADIM TABLOSU ==="); console.table(adimSonuc);
      console.log("\n=== KONSOL HATALARI ===", consoleErrors);
      console.log("\n=== BAŞARISIZ AĞ ===", failedRequests);
      throw e;
    }

    // Adım 5: İl → ilçe → açık adres — tek öğeye kilitle
    try {
      await expect(page.getByRole("paragraph").filter({ hasText: /Adres ve konum bilgisi ekleyin/i }).first()).toBeVisible({ timeout: 10_000 });
      // İl select
      const ilSelect = page.locator("select").first();
      await expect(ilSelect).toBeVisible({ timeout: 5000 });
      await ilSelect.selectOption({ label: "İstanbul" });
      // İlçe select — İstanbul seçildikten sonra Dolmalı
      const ilceSelect = page.locator("select").nth(1);
      await expect(ilceSelect).toBeEnabled({ timeout: 5000 });
      // Kadıköy varsa onu seç, yoksa ilk ilçeyi
      const kadikoy = ilceSelect.locator("option", { hasText: "Kadıköy" });
      if (await kadikoy.count() > 0) {
        await ilceSelect.selectOption({ label: "Kadıköy" });
      } else {
        const opts = ilceSelect.locator("option");
        const second = opts.nth(1);
        if (await second.isVisible().catch(() => false)) {
          const val = await second.getAttribute("value");
          if (val) await ilceSelect.selectOption(val);
        }
      }
      // Açık adres
      const adresInput = page.getByPlaceholder(/Açık adres/i);
      await expect(adresInput).toBeVisible({ timeout: 5000 });
      await adresInput.fill("Test Mah. No:1 Kadıköy İstanbul");
      await page.getByRole("button", { name: /Adres Ekle/i }).click();
      await shot("05-konum.png");
      kaydet("5. Konum (il/ilçe/adres)", "geçti");
    } catch (e) {
      kaydet("5. Konum (il/ilçe/adres)", "kaldı", String((e as Error).message).slice(0, 400));
      await shot("05-hata.png");
      console.log("\n=== ADIM TABLOSU ==="); console.table(adimSonuc);
      console.log("\n=== KONSOL HATALARI ===", consoleErrors);
      console.log("\n=== BAŞARISIZ AĞ ===", failedRequests);
      throw e;
    }

    // Adım 6: Yasal onay — tek öğeye kilitle
    try {
      await expect(page.getByRole("paragraph").filter({ hasText: /Yasal Bilgilendirme ve Yayınlama Onayı/i }).first()).toBeVisible({ timeout: 10_000 });
      const boxes = page.getByRole("checkbox");
      await expect(boxes.first()).toBeVisible({ timeout: 5000 });
      const count = await boxes.count();
      for (let i = 0; i < Math.min(count, 3); i++) {
        const b = boxes.nth(i);
        if (!(await b.isChecked())) await b.check();
      }
      await page.getByRole("button", { name: /Onayları İncele/i }).click();
      await shot("06-legal.png");
      kaydet("6. Yasal onay", "geçti");
    } catch (e) {
      kaydet("6. Yasal onay", "kaldı", String((e as Error).message).slice(0, 400));
      await shot("06-hata.png");
      console.log("\n=== ADIM TABLOSU ==="); console.table(adimSonuc);
      console.log("\n=== KONSOL HATALARI ===", consoleErrors);
      console.log("\n=== BAŞARISIZ AĞ ===", failedRequests);
      throw e;
    }

    // Adım 7: Yayınla — tek öğeye kilitle
    try {
      await expect(page.getByRole("paragraph").filter({ hasText: /Vitrininizi yayınlayın/i }).first()).toBeVisible({ timeout: 10_000 });
      const yayinlaBtn = page.getByRole("button", { name: /^Yayınla$/ });
      await expect(yayinlaBtn).toBeVisible({ timeout: 5000 });
      await yayinlaBtn.click();
      // İki olası sonuç:
      // A) oturum yok → window.location.href = "/kayit" (sayfa /kayit'e gider)
      // B) oturum var → /api/create-store → vitrin linki "/v/…?owner=true" görünür
      // Her ikisini de bekle, hangisi gelirse kaydet — ürün kodu düzeltme yok.
      const kayitBekle = page.waitForURL("**/kayit**", { timeout: 8000 }).then(() => "kayit").catch(() => null);
      const vitrinBekle = page.waitForSelector('a[href^="/v/"]', { timeout: 8000 }).then(() => "vitrin").catch(() => null);
      // Ayrıca ağ hatasını dinle: 4xx/5xx zaten toplanıyor, burada da publish 401/422 görülebilir
      await Promise.race([kayitBekle, vitrinBekle, page.waitForTimeout(8000).then(() => "timeout")]);
      await shot("07-yayinla.png");
      kaydet("7. Yayınla", "geçti");
    } catch (e) {
      kaydet("7. Yayınla", "kaldı", String((e as Error).message).slice(0, 400));
      await shot("07-hata.png");
      console.log("\n=== ADIM TABLOSU ==="); console.table(adimSonuc);
      console.log("\n=== KONSOL HATALARI ===", consoleErrors);
      console.log("\n=== BAŞARISIZ AĞ ===", failedRequests);
      throw e;
    }

    // Adım 8: Vitrin adresi göründü mü
    try {
      // Kalıcı hesap zaten vitrini varsa create-store 409 döner ve slug createStoreSlug'da tutulur — o vitrini doğrula
      if (createStoreSlug) {
        await page.goto(`/v/${createStoreSlug}`, { waitUntil: "domcontentloaded" });
        await expect(page.getByRole("heading", { level: 1 }).first()).toBeVisible({ timeout: 10_000 });
        await shot("08-vitrin.png");
        kaydet("8. Vitrin adresi", "geçti", `Mevcut vitrin kullanıldı: /v/${createStoreSlug} (409 → var olan slug)`);
      } else {
        const url = page.url();
        if (url.includes("/kayit")) {
          await shot("08-vitrin.png");
          kaydet("8. Vitrin adresi", "kaldı", "Yayın sonrası /kayit'e yönlendi — giriş yapılmadığı için vitrin oluşturulamadı (taslak sessionStorage'da, auth gerekiyor).");
          console.log("\n=== ADIM TABLOSU ==="); console.table(adimSonuc);
          console.log("\n=== KONSOL HATALARI ===", consoleErrors);
          console.log("\n=== SAYFA HATALARI ===", pageErrors);
          console.log("\n=== BAŞARISIZ AĞ (4xx/5xx + requestfailed) ==="); for (const l of failedRequests) console.log(l);
          expect(url).toContain("/v/");
        } else {
          await expect(page.getByRole("paragraph").filter({ hasText: /İşte bu kadar!/i }).first()).toBeVisible({ timeout: 8000 });
          const vitrinLink = page.locator('a[href^="/v/"]').first();
          await expect(vitrinLink).toBeVisible({ timeout: 8000 });
          const href = await vitrinLink.getAttribute("href");
          expect(href).toMatch(/^\/v\/.+/);
          await shot("08-vitrin.png");
          kaydet("8. Vitrin adresi", "geçti");
        }
      }
    } catch (e) {
      // 08'de zaten kayıt yapıldıysa tekrar yazma, yoksa yaz
      if (!adimSonuc.some((r) => r.adim.startsWith("8."))) {
        kaydet("8. Vitrin adresi", "kaldı", String((e as Error).message).slice(0, 500));
      }
      await shot("08-hata.png");
      console.log("\n=== ADIM TABLOSU ==="); console.table(adimSonuc);
      console.log("\n=== KONSOL HATALARI ===", consoleErrors);
      console.log("\n=== SAYFA HATALARI ===", pageErrors);
      console.log("\n=== BAŞARISIZ AĞ ===", failedRequests);
      throw e;
    }

    // Son tablo + sessiz hatalar — başarılı koşuda da logla
    console.log("\n=== ADIM TABLOSU ==="); console.table(adimSonuc);
    console.log("\n=== KONSOL HATALARI ==="); for (const l of consoleErrors) console.log(l);
    console.log("\n=== SAYFA HATALARI ==="); for (const l of pageErrors) console.log(l);
    console.log("\n=== BAŞARISIZ AĞ (4xx/5xx) ==="); for (const l of failedRequests) console.log(l);
    if (consoleErrors.length) console.warn(`⚠️ ${consoleErrors.length} konsol hatası toplandı — sessiz hata en tehlikelisi`);
    if (failedRequests.length) console.warn(`⚠️ ${failedRequests.length} başarısız ağ isteği — listelendi`);

    // Final expect: tüm adımlar geçti mi?
    const kalan = adimSonuc.filter((r) => r.durum === "kaldı");
    expect(kalan, `Kalan adımlar: ${JSON.stringify(kalan, null, 2)}\nKonsol: ${consoleErrors.join("; ")}\nAğ: ${failedRequests.join("; ")}`).toEqual([]);
  });
});

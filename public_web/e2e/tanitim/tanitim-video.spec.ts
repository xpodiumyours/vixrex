import { expect, test } from "@playwright/test";
import * as fs from "fs";
import * as path from "path";

/**
 * Vixrex tanıtım videosu — 5 ayrı klip, reklam kalitesinde dikey kayıt.
 *
 * - 1080x1920 dikey, ayrı config: `playwright.tanitim.config.ts`
 * - Her `test()` ayrı video üretir — kurgu CapCut'ta birleştirilecek
 * - Ürün kodu değiştirilmez, var olan testlere dokunulmaz, commit yok
 * - Sahte imleç + insan hızı yazma + yumuşak kaydırma olmadan kayıt bot gibi durur
 *
 * Koşu: npx playwright test --config=playwright.tanitim.config.ts
 * Çıktı: public_web/tanitim-cikti/
 */

// ── Ortak yardımcılar ───────────────────────────────────────────────────────

async function installFakeCursor(page: import("@playwright/test").Page) {
  await page.addInitScript(() => {
    const style = document.createElement("style");
    style.textContent = `
      #vixrex-fake-cursor {
        position: fixed;
        width: 22px;
        height: 22px;
        border-radius: 50%;
        background: rgba(14,165,233,0.95);
        border: 2.5px solid white;
        box-shadow: 0 2px 12px rgba(0,0,0,0.35), 0 0 0 8px rgba(14,165,233,0.15);
        pointer-events: none;
        z-index: 2147483647;
        transform: translate(-50%, -50%);
        transition: transform 0.08s linear;
        will-change: left, top;
      }
      #vixrex-fake-cursor-ring {
        position: fixed;
        width: 22px;
        height: 22px;
        border-radius: 50%;
        border: 2px solid rgba(14,165,233,0.9);
        pointer-events: none;
        z-index: 2147483646;
        transform: translate(-50%, -50%) scale(1);
        opacity: 0;
      }
      @keyframes vixrex-ring {
        0% { transform: translate(-50%, -50%) scale(1); opacity: 0.9; }
        100% { transform: translate(-50%, -50%) scale(2.8); opacity: 0; }
      }
    `;
    document.documentElement.appendChild(style);

    const dot = document.createElement("div");
    dot.id = "vixrex-fake-cursor";
    dot.style.left = "-100px";
    dot.style.top = "-100px";
    document.documentElement.appendChild(dot);

    const ring = document.createElement("div");
    ring.id = "vixrex-fake-cursor-ring";
    ring.style.left = "-100px";
    ring.style.top = "-100px";
    document.documentElement.appendChild(ring);

    // Tıklamada halka efekti
    document.addEventListener("click", (e) => {
      const r = document.getElementById("vixrex-fake-cursor-ring");
      if (!r) return;
      r.style.left = `${e.clientX}px`;
      r.style.top = `${e.clientY}px`;
      r.style.animation = "none";
      // reflow
      void (r as HTMLElement).offsetWidth;
      r.style.animation = "vixrex-ring 420ms ease-out";
    });

    // Cursor pozisyonunu window üzerinden güncelle
    (window as unknown as Record<string, unknown>).__vixrexMoveCursor = (x: number, y: number) => {
      dot.style.left = `${x}px`;
      dot.style.top = `${y}px`;
      ring.style.left = `${x}px`;
      ring.style.top = `${y}px`;
    };
  });
}

async function moveCursorTo(page: import("@playwright/test").Page, x: number, y: number) {
  // Mevcut kursor pozisyonunu al, hedefe 14-18 adımda yumuşak taşı
  const start = await page.evaluate(() => {
    const el = document.getElementById("vixrex-fake-cursor") as HTMLElement | null;
    if (!el) return { x: -100, y: -100 };
    const sx = parseFloat(el.style.left) || -100;
    const sy = parseFloat(el.style.top) || -100;
    return { x: sx, y: sy };
  });
  const steps = 16;
  for (let i = 1; i <= steps; i++) {
    const t = i / steps;
    // easeOutCubic
    const eased = 1 - Math.pow(1 - t, 3);
    const cx = start.x + (x - start.x) * eased;
    const cy = start.y + (y - start.y) * eased;
    await page.evaluate(
      ({ cx, cy }) => {
        const fn = (window as unknown as Record<string, unknown>).__vixrexMoveCursor as
          | ((x: number, y: number) => void)
          | undefined;
        if (fn) fn(cx, cy);
      },
      { cx, cy },
    );
    await page.mouse.move(cx, cy);
    await page.waitForTimeout(18 + Math.random() * 10);
  }
}

async function humanClick(
  page: import("@playwright/test").Page,
  locator: import("@playwright/test").Locator,
) {
  await locator.waitFor({ state: "visible", timeout: 10_000 });
  await locator.scrollIntoViewIfNeeded();
  const box = await locator.boundingBox();
  if (!box) {
    await locator.click();
    return;
  }
  const cx = box.x + box.width / 2 + (Math.random() * 10 - 5);
  const cy = box.y + box.height / 2 + (Math.random() * 6 - 3);
  await moveCursorTo(page, cx, cy);
  await page.waitForTimeout(120 + Math.random() * 80);
  await locator.click();
  await page.waitForTimeout(150);
}

async function humanType(
  locator: import("@playwright/test").Locator,
  text: string,
) {
  await locator.waitFor({ state: "visible", timeout: 10_000 });
  await locator.click();
  await locator.press("Control+A");
  await locator.press("Backspace");
  await locator.pressSequentially(text, { delay: 70 });
  await locator.page().waitForTimeout(180);
}

async function softScroll(page: import("@playwright/test").Page, distance: number) {
  const dir = distance >= 0 ? 1 : -1;
  const total = Math.abs(distance);
  const step = 120;
  let scrolled = 0;
  while (scrolled < total) {
    const delta = Math.min(step, total - scrolled) * dir;
    await page.mouse.wheel(0, delta);
    scrolled += step;
    await page.waitForTimeout(40 + Math.random() * 20);
  }
}

async function breath(pg: import("@playwright/test").Page, min = 800, max = 1200) {
  const t = min + Math.random() * (max - min);
  await pg.waitForTimeout(t);
}

async function waitReady(page: import("@playwright/test").Page) {
  await page.waitForLoadState("networkidle", { timeout: 15_000 }).catch(() => {});
  // Skeleton yerine gerçek başlık bekle
  await page.waitForTimeout(600);
}

async function closeCookieIfVisible(page: import("@playwright/test").Page) {
  const dialog = page.getByRole("dialog", { name: /Çerez tercihleri/i });
  if (await dialog.isVisible({ timeout: 1200 }).catch(() => false)) {
    const only = dialog.getByRole("button", { name: /Yalnızca gerekli/i });
    if (await only.isVisible({ timeout: 800 }).catch(() => false)) {
      await humanClick(page, only);
    } else {
      const accept = dialog.getByRole("button", { name: /Tümünü kabul et/i });
      if (await accept.isVisible({ timeout: 800 }).catch(() => false)) {
        await humanClick(page, accept);
      } else {
        await dialog.getByRole("button").first().click().catch(() => {});
      }
    }
    await dialog.waitFor({ state: "hidden", timeout: 3000 }).catch(() => {});
    await breath(page, 500, 700);
  }
  // /giris'teki alternatif banner
  const girisBanner = page.getByRole("button", { name: /Yalnızca gerekli|Tümünü kabul et/i });
  if (await girisBanner.first().isVisible({ timeout: 800 }).catch(() => false)) {
    await girisBanner.first().click().catch(() => {});
    await page.waitForTimeout(400);
  }
}

// Slug dosyasını paylaş — sahne 4 slug üretir, sahne 5 okur
function slugFile() {
  return path.resolve(process.cwd(), "tanitim-cikti", ".slug.txt");
}

function writeSlug(slug: string) {
  try {
    fs.mkdirSync(path.dirname(slugFile()), { recursive: true });
    fs.writeFileSync(slugFile(), slug, "utf-8");
  } catch {}
}

function readSlug(): string | null {
  try {
    if (fs.existsSync(slugFile())) return fs.readFileSync(slugFile(), "utf-8").trim() || null;
  } catch {}
  return null;
}

// Ağ + konsol toplayıcı (rapor için)
function attachCollectors(page: import("@playwright/test").Page) {
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
    const url = resp.url();
    if (url.includes("/api/create-store")) {
      try {
        const body = await resp.json();
        if (body?.slug) {
          createStoreSlug = String(body.slug);
          writeSlug(createStoreSlug);
        }
      } catch {}
    }
    const s = resp.status();
    if (s >= 400) failedRequests.push(`${s} ${resp.request().method()} ${url}`);
  });
  page.on("requestfailed", (req) => {
    failedRequests.push(`FAILED ${req.method()} ${req.url()} - ${req.failure()?.errorText}`);
  });

  return { consoleErrors, pageErrors, failedRequests, getSlug: () => createStoreSlug };
}

// ── Testler ───────────────────────────────────────────────────────────────────

test.describe("tanitim videosu — 5 ayrı klip", () => {
  // Sıralı koşsun, video dosyaları sırayla üretilsin
  test.describe.configure({ mode: "serial" });

  test("01-acilis — hero açılış", async ({ page }) => {
    test.setTimeout(60_000);
    await installFakeCursor(page);
    const c = attachCollectors(page);

    await page.goto("/", { waitUntil: "domcontentloaded" });
    await waitReady(page);
    await closeCookieIfVisible(page);

    // Hero tam görünsün
    await expect(page.getByRole("heading", { name: /birkaç dakikada hazır/i })).toBeVisible({ timeout: 12_000 });
    await breath(page, 1500, 1500);

    // Yavaşça aşağı kaydır, sonra biraz geri — göz yerleşsin
    await softScroll(page, 420);
    await breath(page, 1000, 1200);
    await softScroll(page, -160);
    await breath(page, 1200, 1500);

    // Ana çağrı düğmesi görünür kalsın
    await expect(page.getByRole("button", { name: /Ücretsiz Vitrinimi Hazırla/i })).toBeVisible({ timeout: 5000 }).catch(async () => {
      await expect(page.getByRole("link", { name: /Ücretsiz/i })).toBeVisible({ timeout: 3000 });
    });

    if (c.failedRequests.length) console.log("[01-acilis] 4xx/5xx:", c.failedRequests);
    if (c.consoleErrors.length) console.log("[01-acilis] console:", c.consoleErrors);
  });

  test("02-kesfet — Keşfet'te dolaşma", async ({ page }) => {
    test.setTimeout(90_000);
    await installFakeCursor(page);
    const c = attachCollectors(page);

    await page.goto("/", { waitUntil: "domcontentloaded" });
    await waitReady(page);
    await closeCookieIfVisible(page);

    // Üst menüden Keşfet'e git — doğrudan URL değil, tıklayarak (dolaşımı göstermek için)
    const kesfetLink = page.locator('a[href^="/kesfet"]').first();
    await expect(kesfetLink).toBeVisible({ timeout: 12_000 });
    await humanClick(page, kesfetLink);
    await page.waitForURL("**/kesfet**", { timeout: 12_000 });
    await waitReady(page);
    await closeCookieIfVisible(page);

    await expect(page.getByRole("heading", { name: /Vixrex.*Keşfet|Keşfet/i })).toBeVisible({ timeout: 10_000 });
    await breath(page, 1000, 1300);

    // Görseller yüklenene kadar bekle — boş kart çekme
    await page.waitForTimeout(1200);
    // En az 6-8 kart görünsün diye yavaş kaydır
    const kartlar = page.locator('a[href^="/v/"]');
    const adet = await kartlar.count().catch(() => 0);
    expect(adet, "Keşfet’te en az 1 vitrin kartı bekleniyor").toBeGreaterThan(0);

    // Kategori şeridi — varsa kategori filtresine bir kez tıkla
    const kategoriSeridi = page.locator('a[href^="/kesfet/"]').first();
    if (await kategoriSeridi.isVisible({ timeout: 1500 }).catch(() => false)) {
      await humanClick(page, kategoriSeridi);
      await page.waitForLoadState("networkidle").catch(() => {});
      await page.waitForTimeout(1500);
      await expect(page.locator('a[href^="/v/"]').first()).toBeVisible({ timeout: 8000 });
    }

    // Izgarayı yavaşça kaydırarak geç (6-8 kart görünsün)
    await softScroll(page, 520);
    await breath(page, 800, 1000);
    await softScroll(page, 480);
    await breath(page, 800, 1000);

    // Görselleri yüklenmemiş kart ekranda kalmasın — lazy img bekle
    const imgs = page.locator('a[href^="/v/"] img');
    const imgCount = await imgs.count().catch(() => 0);
    if (imgCount > 0) {
      for (let i = 0; i < Math.min(imgCount, 6); i++) {
        const img = imgs.nth(i);
        await expect(img).toBeVisible({ timeout: 4000 }).catch(() => {});
      }
    }
    await breath(page, 1200, 1600);

    if (c.failedRequests.length) console.log("[02-kesfet] 4xx/5xx:", c.failedRequests);
    if (c.consoleErrors.length) console.log("[02-kesfet] console:", c.consoleErrors);
  });

  test("03-vitrin-ici — bir vitrinin içi", async ({ page }) => {
    test.setTimeout(90_000);
    await installFakeCursor(page);
    const c = attachCollectors(page);

    await page.goto("/kesfet", { waitUntil: "domcontentloaded" });
    await waitReady(page);
    await closeCookieIfVisible(page);

    // Ürünü ve görseli dolu bir kart seç — boş vitrin atla
    const kartlar = page.locator("article");
    const kartAdet = await kartlar.count().catch(() => 0);
    let secilenHref: string | null = null;

    for (let i = 0; i < Math.min(kartAdet, 12); i++) {
      const kart = kartlar.nth(i);
      const hasImg = (await kart.locator("img").count().catch(() => 0)) > 0;
      const text = await kart.textContent().catch(() => "");
      const hasUrun = /ürün/i.test(text || "");
      if (hasImg) {
        // Öncelik: görseli var + mümkünse ürünü var
        const link = kart.locator('a[href^="/v/"]').first();
        if (await link.isVisible({ timeout: 800 }).catch(() => false)) {
          secilenHref = await link.getAttribute("href");
          if (secilenHref) {
            // Doluya öncelik — ama boşsa da devam edecek, en azından görseli dolu
            if (hasUrun || i >= 4) break;
          }
        }
      }
    }
    // Fallback: ilk vitrin linki
    if (!secilenHref) {
      const first = page.locator('a[href^="/v/"]').first();
      await expect(first).toBeVisible({ timeout: 10_000 });
      secilenHref = await first.getAttribute("href");
    }
    expect(secilenHref, "Vitrin linki bulunamadı").toBeTruthy();

    const vitrinLink = page.locator(`a[href="${secilenHref}"]`).first();
    await humanClick(page, vitrinLink);
    await page.waitForURL("**/v/**", { timeout: 15_000 });
    await waitReady(page);
    await closeCookieIfVisible(page);

    // Kapak / işletme adı — 1.5s
    await expect(page.getByRole("heading", { level: 1 }).first()).toBeVisible({ timeout: 12_000 });
    await breath(page, 1500, 1700);

    // Kategoriler ve ürün ızgarası — yavaş kaydırma
    await softScroll(page, 420);
    await breath(page, 800, 1000);
    await softScroll(page, 380);
    await breath(page, 900, 1100);

    // Bir ürüne tıkla, detay 2sn, geri dön
    const urunLink = page.locator('a[href*="/urun/"]').first();
    if (await urunLink.isVisible({ timeout: 2000 }).catch(() => false)) {
      await humanClick(page, urunLink);
      await page.waitForURL("**/urun/**", { timeout: 10_000 }).catch(() => {});
      await waitReady(page);
      await breath(page, 2000, 2000);
      await page.goBack({ waitUntil: "domcontentloaded" }).catch(async () => {
        await page.goto(secilenHref!, { waitUntil: "domcontentloaded" });
      });
      await waitReady(page);
      await breath(page, 700, 900);
    } else {
      // Ürün detayı yoksa da 1sn bekle — boş görünmesin
      await breath(page, 1000, 1200);
    }

    // WhatsApp düğmesi üzerine imleci getir (TIKLAMA — WhatsApp'a çıkmasın), 1.5s
    const waButton =
      page.getByRole("link", { name: /WhatsApp/i }).first().or(page.getByRole("button", { name: /WhatsApp/i }).first());
    if (await waButton.isVisible({ timeout: 2500 }).catch(() => false)) {
      const box = await waButton.boundingBox();
      if (box) await moveCursorTo(page, box.x + box.width / 2, box.y + box.height / 2);
      await page.waitForTimeout(1500);
    }

    // Varsa adres/konum ve paylaş/QR alanını göster
    const adresAlani = page.locator("text=/Adres|Konum|Harita|Yol tarifi/i").first();
    if (await adresAlani.isVisible({ timeout: 1500 }).catch(() => false)) {
      await adresAlani.scrollIntoViewIfNeeded();
      await softScroll(page, 280);
      await breath(page, 1000, 1200);
    }
    const paylasAlani = page.locator("text=/Paylaş|QR|Link/i").first();
    if (await paylasAlani.isVisible({ timeout: 1200 }).catch(() => false)) {
      await paylasAlani.scrollIntoViewIfNeeded();
      await breath(page, 1000, 1300);
    }

    if (c.failedRequests.length) console.log("[03-vitrin-ici] 4xx/5xx:", c.failedRequests);
    if (c.consoleErrors.length) console.log("[03-vitrin-ici] console:", c.consoleErrors);
  });

  test("04-vitrin-kurulumu — kendi vitrinini kur (kalbin)", async ({ page }) => {
    test.setTimeout(120_000);
    await installFakeCursor(page);
    const c = attachCollectors(page);

    // Ana sayfaya dön, asistanı başlat
    await page.goto("/", { waitUntil: "domcontentloaded" });
    await waitReady(page);
    await closeCookieIfVisible(page);

    // Giriş gerekli — asistan adım 7'de /kayit'e atıyor ise öncesi giriş yap
    // Kalıcı test hesabıyla giriş: vixrex.test.1787911144069@gmail.com / Test!1787911144069 — YENİ HESAP AÇMA
    await page.goto("/giris", { waitUntil: "domcontentloaded" });
    await waitReady(page);
    await closeCookieIfVisible(page);
    await expect(page.getByRole("heading", { name: /Giriş Yap/i })).toBeVisible({ timeout: 12_000 });

    const emailInput = page.getByPlaceholder("ornek@eposta.com");
    const sifreInput = page.getByPlaceholder("Şifren");
    await expect(emailInput).toBeVisible({ timeout: 8000 });
    await expect(sifreInput).toBeVisible({ timeout: 5000 });
    await humanType(emailInput, "vixrex.test.1787911144069@gmail.com");
    await humanType(sifreInput, "Test!1787911144069");
    await expect(emailInput).toHaveValue("vixrex.test.1787911144069@gmail.com", { timeout: 4000 });
    const girisBtn = page.getByRole("button", { name: /^Giriş Yap$/ });
    await humanClick(page, girisBtn);
    await page.waitForURL("**/app**", { timeout: 20_000 });
    await expect(page).toHaveURL(/\/app/);
    await breath(page, 1200, 1500);

    // Ana sayfaya dön ve mascot ile asistanı aç
    await page.goto("/", { waitUntil: "domcontentloaded" });
    await waitReady(page);
    await closeCookieIfVisible(page);

    const mascotBtn = page.getByRole("button", { name: /Vixrex Asistan'ı aç/i });
    await expect(mascotBtn).toBeVisible({ timeout: 12_000 });
    await humanClick(page, mascotBtn);
    await breath(page, 800, 1000);

    const karsilama = page.getByRole("paragraph").filter({ hasText: /Vitrininizi Oluşturun/i }).first();
    await expect(karsilama).toBeVisible({ timeout: 10_000 });
    await breath(page, 900, 1100);

    // Sıfırdan Oluştur — welcome adımından çık
    const sifirdan = page.getByRole("button", { name: /Sıfırdan Oluştur/i });
    await expect(sifirdan).toBeVisible({ timeout: 6000 });
    await humanClick(page, sifirdan);
    await breath(page, 700, 900);

    // İşletme adı — inandırıcı isim, "test" yok
    await expect(page.getByRole("paragraph").filter({ hasText: /İşletme adınızı girin/i }).first()).toBeVisible({ timeout: 12_000 });
    const nameInput = page.getByPlaceholder(/Ör\. Aymira Giyim/i);
    await expect(nameInput).toBeVisible({ timeout: 6000 });
    await humanType(nameInput, "Kavaklıdere Kuruyemiş");
    await breath(page, 600, 800);
    await humanClick(page, page.getByRole("button", { name: /İşletme Adı Ekle/i }));
    await breath(page, 700, 900);

    // Kategori — ızgaradan uygun olanı seç (kuruyemiş → Gıda)
    await expect(page.getByRole("paragraph").filter({ hasText: /İşletme kategorinizi seçin/i }).first()).toBeVisible({ timeout: 12_000 });
    await expect(page.getByRole("paragraph").filter({ hasText: /İşini seç/i }).first()).toBeVisible({ timeout: 6000 });
    await page.waitForTimeout(600);
    const gidaBtn = page.getByRole("button", { name: /^Gıda$/ });
    if (await gidaBtn.isVisible({ timeout: 2500 }).catch(() => false)) {
      await humanClick(page, gidaBtn);
    } else {
      // fallback: Gıda yoksa ilk uygun buton
      const ilk = page.locator("button").filter({ hasText: /Gıda|Fırın|Kafe|Giyim|Teknik/i }).first();
      await expect(ilk).toBeVisible({ timeout: 6000 });
      await humanClick(page, ilk);
    }
    await breath(page, 800, 1000);

    // WhatsApp — gerçekçi ama gerçek olmayan numara, insan hızında
    await expect(page.getByRole("paragraph").filter({ hasText: /WhatsApp numaranızı ekleyin/i }).first()).toBeVisible({ timeout: 12_000 });
    const waInput = page.getByPlaceholder(/05xx xxx xx xx/i);
    await expect(waInput).toBeVisible({ timeout: 6000 });
    await humanType(waInput, "0532 417 88 03");
    await breath(page, 600, 800);
    await humanClick(page, page.getByRole("button", { name: /WhatsApp Ekle/i }));
    await breath(page, 800, 1000);

    // İl / ilçe / adres — gerçek Ankara adresi biçiminde
    await expect(page.getByRole("paragraph").filter({ hasText: /Adres ve konum bilgisi ekleyin/i }).first()).toBeVisible({ timeout: 12_000 });
    const ilSelect = page.locator("select").first();
    await expect(ilSelect).toBeVisible({ timeout: 6000 });
    // İl: Ankara (label ile seç — kodda value name olabilir, label daha güvenli)
    await ilSelect.selectOption({ label: "Ankara" }).catch(async () => {
      await ilSelect.selectOption("Ankara").catch(() => {});
    });
    await breath(page, 600, 800);

    const ilceSelect = page.locator("select").nth(1);
    await expect(ilceSelect).toBeEnabled({ timeout: 8000 });
    // İlçe: Çankaya — varsa onu seç, yoksa ilk ilçeyi
    const cankaya = ilceSelect.locator('option', { hasText: "Çankaya" });
    if ((await cankaya.count().catch(() => 0)) > 0) {
      await ilceSelect.selectOption({ label: "Çankaya" }).catch(async () => {
        await ilceSelect.selectOption("Çankaya").catch(() => {});
      });
    } else {
      const opts = ilceSelect.locator("option");
      const second = opts.nth(1);
      if (await second.isVisible({ timeout: 1500 }).catch(() => false)) {
        const val = await second.getAttribute("value");
        if (val) await ilceSelect.selectOption(val).catch(() => {});
      }
    }
    await breath(page, 500, 700);

    const adresInput = page.getByPlaceholder(/Açık adres/i);
    await expect(adresInput).toBeVisible({ timeout: 6000 });
    await humanType(adresInput, "Kavaklıdere Mah. Atatürk Bulvarı No: 112/A Çankaya/Ankara");
    await breath(page, 700, 900);
    await humanClick(page, page.getByRole("button", { name: /Adres Ekle/i }));
    await breath(page, 900, 1100);

    // Yasal onay — kutuyu işaretle, her adım arası 700-1000ms
    await expect(page.getByRole("paragraph").filter({ hasText: /Yasal Bilgilendirme ve Yayınlama Onayı/i }).first()).toBeVisible({ timeout: 12_000 });
    await breath(page, 800, 1000);
    const boxes = page.getByRole("checkbox");
    await expect(boxes.first()).toBeVisible({ timeout: 6000 });
    const boxCount = await boxes.count().catch(() => 0);
    for (let i = 0; i < Math.min(boxCount, 3); i++) {
      const b = boxes.nth(i);
      if (!(await b.isChecked().catch(() => false))) {
        await humanClick(page, b);
        await breath(page, 400, 600);
      }
    }
    await breath(page, 700, 900);
    await humanClick(page, page.getByRole("button", { name: /Onayları İncele/i }));
    await breath(page, 900, 1100);

    // Yayınla — asistanın cevabı okunacak kadar dursun, sonra bas
    await expect(page.getByRole("paragraph").filter({ hasText: /Vitrininizi yayınlayın/i }).first()).toBeVisible({ timeout: 12_000 });
    await breath(page, 1000, 1300);
    const yayinlaBtn = page.getByRole("button", { name: /^Yayınla$/ });
    await expect(yayinlaBtn).toBeVisible({ timeout: 6000 });
    await humanClick(page, yayinlaBtn);

    // 500 / 404 bilinen sorun — ürün kodu DÜZELTME, sahne kırılırsa raporla
    const kayitPromise = page.waitForURL("**/kayit**", { timeout: 9000 }).then(() => "kayit").catch(() => null);
    const vitrinPromise = page
      .waitForSelector('a[href^="/v/"]', { timeout: 9000 })
      .then(() => "vitrin")
      .catch(() => null);
    const errorPromise = page
      .waitForSelector('text=/hata|başarısız|oluşturulamadı/i', { timeout: 9000 })
      .then(() => "hata")
      .catch(() => null);

    const ilkSonuc = await Promise.race([kayitPromise, vitrinPromise, errorPromise, page.waitForTimeout(9000).then(() => "timeout")]);

    // Slug zaten response listener ile yakalandı — yoksa linkten dene
    let slug = c.getSlug() || readSlug();
    if (!slug) {
      const vitrinLink = page.locator('a[href^="/v/"]').first();
      if (await vitrinLink.isVisible({ timeout: 2500 }).catch(() => false)) {
        const href = await vitrinLink.getAttribute("href");
        const m = href?.match(/\/v\/([^/?#]+)/);
        if (m) {
          slug = m[1];
          writeSlug(slug);
        }
      }
    }

    const failed500 = c.failedRequests.some((s) => /500 .*\/api\/create-store/.test(s));
    const notFound = c.failedRequests.some((s) => /404 .*\/v\//.test(s));

    console.log(`[04-vitrin-kurulumu] sonuç: ${ilkSonuc}, slug: ${slug ?? "—"}, 500:${failed500}, 404:${notFound}`);
    if (c.failedRequests.length) console.log("[04-vitrin-kurulumu] 4xx/5xx:", c.failedRequests);
    if (c.consoleErrors.length) console.log("[04-vitrin-kurulumu] console:", c.consoleErrors);
    if (c.pageErrors.length) console.log("[04-vitrin-kurulumu] pageerror:", c.pageErrors);
    if (slug) console.log(`[04-vitrin-kurulumu] OLUŞAN SLUG: ${slug}`);

    // Bilinen kırık: 500 + 404 — sahne atlanır, test düşürülmez; diğer klipler (1-3) tam
    if (!slug && (failed500 || ilkSonuc === "hata")) {
      console.warn("[04-vitrin-kurulumu] POST /api/create-store 500 — sahne kırık, ürün kodu düzeltilmedi. Rapor: ayni istek 500 dönüyor.");
      // Bilerek düşürme — görev “atla ve 1-3’ü tam çek” diyor, ama bu testin kendisi sahne 4 olduğu için not düş ve geç
      // expect’i gevşetme; durumu logla ve testi soft-fail gibi işaretle
      test.info().annotations.push({ type: "Sahne 4 kırık — create-store 500", description: c.failedRequests.join("; ") });
      // Slug yoksa sahne 5 de çekilemeyecek — ama testi kırmızı yapmamak için burada fail değil, açıklama bırakıyoruz
      // Gerçek fail’i sahne 5 kendi raporlayacak
      await page.waitForTimeout(1500);
      return;
    }

    // Başarılı görünse de vitrin linki kontrol — yoksa hata
    if (!slug && ilkSonuc === "kayit") {
      console.warn("[04-vitrin-kurulumu] /kayit’e yönlendi — oturum kayboldu veya create-store auth istedi. Slug yok.");
      test.info().annotations.push({ type: "Sahne 4 /kayit yönlenmesi", description: page.url() });
      await page.waitForTimeout(1200);
      return;
    }

    if (slug) {
      writeSlug(slug);
      console.log(`[04-vitrin-kurulumu] SLUG KAYDEDİLDİ: ${slug}`);
    }

    await page.waitForTimeout(1200);
  });

  test("05-yayinda — kapanış: yayında", async ({ page }) => {
    test.setTimeout(90_000);
    await installFakeCursor(page);
    const c = attachCollectors(page);

    let slug = readSlug() || c.getSlug();

    // Slug yoksa sahne 4 kırık demek — ürün kodu düzeltmeden sahne atlandı raporu
    if (!slug) {
      // Son çare: /app’den mevcut vitrini bul (kalıcı hesabın zaten vitrini varsa)
      await page.goto("/app", { waitUntil: "domcontentloaded" }).catch(() => {});
      await waitReady(page);
      const appVitrinLink = page.locator('a[href^="/v/"]').first();
      if (await appVitrinLink.isVisible({ timeout: 3000 }).catch(() => false)) {
        const href = await appVitrinLink.getAttribute("href");
        const m = href?.match(/\/v\/([^/?#]+)/);
        if (m) slug = m[1];
      }
    }

    if (!slug) {
      console.warn("[05-yayinda] ATLANIYOR — sahne 4 slug üretmedi (create-store 500 / 404). 1-3 tam çekildi, 4-5 kırık raporu.");
      test.info().annotations.push({ type: "Sahne 5 atlandı — slug yok", description: "Sahne 4 create-store 500 nedeniyle vitrin oluşmadı." });
      test.skip(true, "Sahne 4 slug üretmedi — POST /api/create-store 500 / 404, 05 çekilemedi.");
      return;
    }

    // Yayın sonrası ekranı ve vitrin adresini 2s göster
    // Eğer hâlâ ana sayfadaysak vitrin linki üzerinden git; yoksa doğrudan slug’a git
    const currentUrl = page.url();
    const yayinEkraninda = /\/v\//.test(currentUrl) || (await page.locator('a[href^="/v/"]').first().isVisible({ timeout: 1200 }).catch(() => false));
    if (!yayinEkraninda) {
      await page.goto("/", { waitUntil: "domcontentloaded" }).catch(() => {});
      await waitReady(page);
      // Slug’ı ara — doğrudan gitmek daha güvenilir
      await page.goto(`/v/${slug}`, { waitUntil: "domcontentloaded" }).catch(() => {});
    } else {
      // Zaten vitrin linki görünüyor — o linke tıkla (adres gösterimi)
      const vitrinLink = page.locator(`a[href*="${slug}"]`).first().or(page.locator('a[href^="/v/"]').first());
      if (await vitrinLink.isVisible({ timeout: 2000 }).catch(() => false)) {
        await vitrinLink.scrollIntoViewIfNeeded();
        await breath(page, 1800, 2000);
        await humanClick(page, vitrinLink);
      } else {
        await page.goto(`/v/${slug}`, { waitUntil: "domcontentloaded" });
      }
    }

    await page.waitForURL(`**/v/${slug}**`, { timeout: 12_000 }).catch(async () => {
      await page.goto(`/v/${slug}`, { waitUntil: "domcontentloaded" });
    });
    await waitReady(page);
    await closeCookieIfVisible(page);

    // Vitrin adresi 2s göster (URL çubuğu değil, sayfadaki adres/paylaş alanı)
    await expect(page.getByRole("heading", { level: 1 }).first()).toBeVisible({ timeout: 12_000 }).catch(() => {});
    await page.waitForTimeout(2000);

    // Üstten alta bir kez yavaşça gez
    await softScroll(page, 480);
    await breath(page, 600, 800);
    await softScroll(page, 520);
    await breath(page, 600, 800);
    await softScroll(page, 460);
    await breath(page, 700, 900);

    // Son kare: sayfanın en üstü, logo görünür, 1.5s sabit
    await page.evaluate(() => window.scrollTo({ top: 0, behavior: "smooth" }));
    await page.waitForTimeout(800);
    await softScroll(page, 0); // duraklatma hissi
    const logo = page.locator('a[href="/"]').first().or(page.getByText("Vixrex").first());
    await expect(logo.first()).toBeVisible({ timeout: 6000 }).catch(() => {});
    await page.waitForTimeout(1500);

    console.log(`[05-yayinda] slug: ${slug}, url: ${page.url()}`);
    if (c.failedRequests.some((s) => /404/.test(s))) {
      console.warn("[05-yayinda] 404 görüldü — vitrin sayfası bulunamadı. create-store 500 şüphesi.");
    }
    if (c.failedRequests.length) console.log("[05-yayinda] 4xx/5xx:", c.failedRequests);
    if (c.consoleErrors.length) console.log("[05-yayinda] console:", c.consoleErrors);
  });
});

// Son özet — tüm klipler bittiğinde yolları listele
test.afterAll(async () => {
  const outDir = path.resolve(process.cwd(), "tanitim-cikti");
  const slug = readSlug();
  console.log("\n=== TANITIM KLİPLERİ ===");
  console.log(`Çıktı klasörü: ${outDir}`);
  console.log("Beklenen klipler (her test ayrı video):");
  console.log("  01-acilis, 02-kesfet, 03-vitrin-ici, 04-vitrin-kurulumu, 05-yayinda");
  console.log(`  Video dosyaları: ${outDir}/<test-adı>/video.webm`);
  if (fs.existsSync(outDir)) {
    const walk = (dir: string, depth = 0): void => {
      if (depth > 4) return;
      for (const ent of fs.readdirSync(dir, { withFileTypes: true })) {
        const p = path.join(dir, ent.name);
        if (ent.isDirectory()) {
          walk(p, depth + 1);
        } else if (/\.webm$/.test(ent.name)) {
          const stat = fs.statSync(p);
          console.log(`  - ${p} (${(stat.size / 1024 / 1024).toFixed(1)} MB)`);
        }
      }
    };
    walk(outDir);
  } else {
    console.log("  (tanitim-cikti henüz oluşmadı — testler koşmadı mı?)");
  }
  if (slug) {
    console.log(`\n=== OLUŞAN VİTRİN SLUG ===`);
    console.log(slug);
    console.log(`URL: /v/${slug}`);
  } else {
    console.log("\n=== OLUŞAN SLUG YOK ===");
    console.log("Sahne 4 create-store 500 / 404 nedeniyle slug üretmedi — 1-3 klipler tam, 4-5 kırık raporu yukarıda.");
  }

  // 4xx/5xx ve konsol hataları her test kendi log’unda topladı; burada genel uyarı
  console.log("\n=== NOT ===");
  console.log("Var olan e2e/*.spec.ts ve playwright.local.config.ts’e dokunulmadı. Sadece e2e/tanitim + playwright.tanitim.config.ts eklendi. Commit yok.");
});

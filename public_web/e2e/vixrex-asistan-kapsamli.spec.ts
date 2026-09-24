import { expect, test } from "@playwright/test";
import * as fs from "fs";
import * as path from "path";

const TEST_ACCOUNT = {
  email: "vixrex.test.1787911144069@gmail.com",
  password: "Test!1787911144069",
};

const SERBEST_METIN_SENARYOLARI = [
  {
    ad: "Çok günlü çalışma saatleri",
    metin: "Hafta içi 09:00-19:00, cumartesi 10:00-18:00, pazar kapalıyız",
  },
  {
    ad: "Tek cümle adres + telefon",
    metin: "Atatürk Cad. No:24, Kadıköy, İstanbul. Telefon: 0532 123 45 67",
  },
  {
    ad: "WhatsApp + çalışma saatleri",
    metin: "WhatsApp: 0542 987 65 43, her gün 08:00-22:00 arası açığız",
  },
];

interface AdimSonucu {
  adim: string;
  durum: "geçti" | "kaldı";
  hata: string;
  sure?: number;
}

function raporYaz(
  adimSonuc: AdimSonucu[],
  consoleErrors: string[],
  pageErrors: string[],
  failedRequests: string[]
) {
  console.log("\n\n═══════════════════════════════════════════════════════════");
  console.log("   VİXREX ASİSTAN — KAPSAMLI TEST RAPORU");
  console.log("═══════════════════════════════════════════════════════════\n");

  console.log("--- ADIM TABLOSU ---");
  console.table(adimSonuc);

  const gecilen = adimSonuc.filter((a) => a.durum === "geçti").length;
  const kalan = adimSonuc.filter((a) => a.durum === "kaldı");
  const toplamSure = adimSonuc.reduce((t, a) => t + (a.sure ?? 0), 0);

  console.log(
    `\nBAŞARI ORANI: ${gecilen}/${adimSonuc.length} (${Math.round((gecilen / adimSonuc.length) * 100)}%)`
  );
  console.log(`TOPLAM SÜRE: ${(toplamSure / 1000).toFixed(1)} saniye`);

  if (kalan.length > 0) {
    console.log("\n--- BAŞARISIZ ADIMLAR ---");
    kalan.forEach((k) => console.log(`✗ ${k.adim}: ${k.hata}`));
  }

  if (consoleErrors.length > 0) {
    console.log(`\n--- KONSOL HATALARI (${consoleErrors.length}) ---`);
    consoleErrors.slice(0, 10).forEach((e) => console.log(`⚠ ${e}`));
  }

  if (failedRequests.length > 0) {
    console.log(`\n--- BAŞARISIZ AĞ (${failedRequests.length}) ---`);
    failedRequests.slice(0, 10).forEach((r) => console.log(`✗ ${r}`));
  }

  if (pageErrors.length > 0) {
    console.log(`\n--- SAYFA HATALARI (${pageErrors.length}) ---`);
    pageErrors.forEach((e) => console.log(`✗ ${e}`));
  }

  console.log("\n═══════════════════════════════════════════════════════════\n");
}

function snapDirOlustur(): string {
  const candidates = [
    path.resolve(process.cwd(), "test-sonuc"),
    path.resolve(process.cwd(), "..", "test-sonuc"),
    path.resolve("test-sonuc"),
  ];
  for (const d of candidates) {
    try {
      fs.mkdirSync(d, { recursive: true });
    } catch {}
  }
  for (const d of candidates) {
    if (fs.existsSync(d)) return d;
  }
  return candidates[0];
}

async function girisYap(page: import("@playwright/test").Page): Promise<boolean> {
  await page.goto("/giris", { waitUntil: "domcontentloaded" });
  await expect(page.getByRole("heading", { name: /Giriş Yap/i })).toBeVisible({ timeout: 10_000 });

  const cookieBtn = page.getByRole("button", { name: /Yalnızca gerekli|Tümünü kabul et/i });
  if (await cookieBtn.first().isVisible({ timeout: 1500 }).catch(() => false)) {
    await cookieBtn.first().click();
  }

  const emailInput = page.getByPlaceholder("ornek@eposta.com");
  const sifreInput = page.locator('input[type="password"]');
  if (!(await emailInput.isVisible({ timeout: 3000 }).catch(() => false))) {
    return false;
  }

  await emailInput.fill(TEST_ACCOUNT.email);
  await sifreInput.fill(TEST_ACCOUNT.password);
  await page.getByRole("button", { name: /Giriş Yap|Google ile Giriş Yap/i }).first().click();
  await page.waitForTimeout(5000);
  return true;
}

async function alanSecVeGonder(
  page: import("@playwright/test").Page,
  alanAnahtarı: string,
  metin: string
): Promise<boolean> {
  const alanSecici = page.locator(`[data-vixrex-editable="${alanAnahtarı}"]`).first();
  if (await alanSecici.isVisible({ timeout: 3000 }).catch(() => false)) {
    await alanSecici.click();
    await page.waitForTimeout(500);
  }

  const mesajKutusu = page
    .locator('[data-owner-assistant"] input[type="text"], [data-owner-assistant"] textarea')
    .first();
  if (await mesajKutusu.isVisible({ timeout: 3000 }).catch(() => false)) {
    await mesajKutusu.fill(metin);
    await page.keyboard.press("Enter");
    await page.waitForTimeout(2000);
    return true;
  }
  return false;
}

test.describe("VixRex Asistan — Kapsamlı Kalite Testi", () => {
  test("Esnafor deneyimi: vitrin oluşturma ve özelleştirme", async ({ page }) => {
    const consoleErrors: string[] = [];
    const pageErrors: string[] = [];
    const failedRequests: string[] = [];

    page.on("console", (msg) => {
      if (msg.type() === "error") consoleErrors.push(msg.text());
      if (/Failed to load resource|violates.*Content Security Policy/i.test(msg.text())) {
        consoleErrors.push(msg.text());
      }
    });
    page.on("pageerror", (err) => pageErrors.push(err.message));
    page.on("response", (resp) => {
      if (resp.status() >= 400) {
        failedRequests.push(`${resp.status()} ${resp.request().method()} ${resp.url()}`);
      }
    });
    page.on("requestfailed", (req) => {
      failedRequests.push(`FAILED ${req.method()} ${req.url()}`);
    });

    const snapDir = snapDirOlustur();
    async function shot(name: string) {
      await page.screenshot({ path: path.join(snapDir, name), fullPage: true });
    }

    const adimSonuc: AdimSonucu[] = [];
    function kaydet(adim: string, durum: "geçti" | "kaldı", hata: string = "", sure?: number) {
      adimSonuc.push({ adim, durum, hata, sure });
    }

    // Adım 1: Giriş
    const a1 = Date.now();
    try {
      const girisBasarili = await girisYap(page);
      if (!girisBasarili) {
        kaydet("1. Giriş yap", "kaldı", "Zaten giriş yapılmış veya form bulunamadı");
      } else {
        await shot("01-giris.png");
        kaydet("1. Giriş yap", "geçti", "", Date.now() - a1);
      }
    } catch (e) {
      kaydet("1. Giriş yap", "kaldı", String((e as Error).message).slice(0, 300));
      await shot("01-giris-hata.png");
    }

    // Adım 2: Vitrin sayfasına git
    const a2 = Date.now();
    try {
      await page.goto("/v/kiralik-butik", { waitUntil: "domcontentloaded" });
      await page.waitForTimeout(2000);
      await shot("02-vitrin.png");
      kaydet("2. Vitrin erişimi", "geçti", "kiralik-butik demo vitrini", Date.now() - a2);
    } catch (e) {
      kaydet("2. Vitrin erişimi", "kaldı", String((e as Error).message).slice(0, 300));
    }

    // Adım 3: Asistan paneli kontrol
    const a3 = Date.now();
    try {
      const asistanPanel = page.locator('[data-owner-assistant]').first();
      const asistanVar = await asistanPanel.isVisible({ timeout: 5000 }).catch(() => false);
      await shot("03-asistan.png");
      kaydet("3. Asistan paneli", asistanVar ? "geçti" : "kaldı",
        asistanVar ? "Panel görünür" : "Panel bulunamadı (sahip modunda olmayabilir)",
        Date.now() - a3);
    } catch (e) {
      kaydet("3. Asistan paneli", "kaldı", String((e as Error).message).slice(0, 300));
    }

    // Adım 4-6: Akıllı motor testleri
    for (let i = 0; i < SERBEST_METIN_SENARYOLARI.length; i++) {
      const senaryo = SERBEST_METIN_SENARYOLARI[i];
      const aBasla = Date.now();
      try {
        const basarili = await alanSecVeGonder(page, "whatsapp", senaryo.metin);
        await shot(`0${4 + i}-motor-${senaryo.ad.toLowerCase().replace(/\s+/g, "-")}.png`);
        kaydet(`${4 + i}. Akıllı motor - ${senaryo.ad}`,
          basarili ? "geçti" : "kaldı",
          basarili ? "Metin gönderildi" : "Mesaj kutusu bulunamadı",
          Date.now() - aBasla);
      } catch (e) {
        kaydet(`${4 + i}. Akıllı motor - ${senaryo.ad}`,
          "kaldı",
          String((e as Error).message).slice(0, 300));
      }
    }

    // Adım 7: Vitrin önizleme
    const a7 = Date.now();
    try {
      const heading = page.locator("h1").first();
      await expect(heading).toBeVisible({ timeout: 10_000 });
      const vitrinAdi = await heading.textContent();
      await shot("07-vitrin-onizleme.png");
      kaydet("7. Vitrin önizleme", "geçti", `Vitrin adı: ${vitrinAdi?.slice(0, 30)}`, Date.now() - a7);
    } catch (e) {
      kaydet("7. Vitrin önizleme", "kaldı", String((e as Error).message).slice(0, 300));
    }

    // Adım 8: Mobil responsive
    const a8 = Date.now();
    try {
      await page.setViewportSize({ width: 375, height: 812 });
      await page.waitForTimeout(1000);
      const overflowX = await page.evaluate(
        () => document.documentElement.scrollWidth - document.documentElement.clientWidth
      );
      await shot("08-mobil.png");
      await page.setViewportSize({ width: 1280, height: 720 });
      kaydet("8. Mobil responsive", "geçti", `Yatay overflow: ${overflowX}px`, Date.now() - a8);
    } catch (e) {
      kaydet("8. Mobil responsive", "kaldı", String((e as Error).message).slice(0, 300));
      await page.setViewportSize({ width: 1280, height: 720 });
    }

    raporYaz(adimSonuc, consoleErrors, pageErrors, failedRequests);

    const gecilen = adimSonuc.filter((a) => a.durum === "geçti").length;
    expect(gecilen).toBeGreaterThanOrEqual(adimSonuc.length * 0.6);
  });
});

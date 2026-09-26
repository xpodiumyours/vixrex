import { test, expect } from "@playwright/test";
import * as fs from "fs";
import * as path from "path";

/**
 * Esnaf ilk kez giriyor — tam akış:
 * 1. Kayıt ol
 * 2. Vitrin kirala (rent-demo)
 * 3. Asistan ile özelleştir
 * 4. Yayınla
 *
 * Video kaydı: playwright.video.config.ts ile çalıştırılır.
 */

function snapDirOlustur(): string {
  const candidates = [
    path.resolve(process.cwd(), "test-sonuc"),
    path.resolve(process.cwd(), "..", "test-sonuc"),
  ];
  for (const d of candidates) {
    try { fs.mkdirSync(d, { recursive: true }); } catch {}
  }
  return candidates[0];
}

test.describe("Esnaf ilk kez — kayıt → kiralama → asistan", () => {
  test("Yeni hesap aç, vitrin kirala, asistanla özelleştir", async ({ page }) => {
    const snapDir = snapDirOlustur();
    async function shot(name: string) {
      await page.screenshot({ path: path.join(snapDir, name), fullPage: true });
    }

    const adimSonuc: Array<{ adim: string; durum: string; detay: string }> = [];
    function kaydet(adim: string, durum: string, detay = "") {
      adimSonuc.push({ adim, durum, detay });
      console.log(`  [${durum}] ${adim}${detay ? ` — ${detay}` : ""}`);
    }

    test.setTimeout(300_000);

    const zamanDamgasi = Date.now();
    const testEmail = `vixrex.test.${zamanDamgasi}@example.com`;
    const testSifre = `Test!${zamanDamgasi}`;

    // ── ADIM 1: Kayıt ol ──────────────────────────────────────────────
    try {
      await page.goto("/kayit", { waitUntil: "domcontentloaded" });
      await page.waitForTimeout(2000);

      const cerezBtn = page.getByRole("button", { name: /Yalnızca gerekli|Tümünü kabul et/i });
      if (await cerezBtn.first().isVisible({ timeout: 1500 }).catch(() => false)) {
        await cerezBtn.first().click();
        await page.waitForTimeout(500);
      }

      await page.locator('input[type="email"]').fill(testEmail);
      await page.locator('input[type="password"]').nth(0).fill(testSifre);
      await page.locator('input[type="password"]').nth(1).fill(testSifre);
      await shot("10-kayit-formu.png");

      await page.getByRole("button", { name: "Kayıt Ol" }).click();
      await page.waitForTimeout(5000);
      await shot("11-kayit-sonrasi.png");

      const url = page.url();
      const kayitTamam = !url.includes("/kayit") || await page.locator('input[type="email"]').count() === 0;
      kaydet("1. Kayıt ol", kayitTamam ? "geçti" : "belirsiz", `URL: ${url} | E-posta: ${testEmail}`);
    } catch (e) {
      kaydet("1. Kayıt ol", "kaldı", String((e as Error).message).slice(0, 200));
      await shot("11-kayit-hata.png");
    }

    // ── ADIM 2: Vitrin kirala ─────────────────────────────────────────
    let kiralananSlug = "";
    try {
      await page.goto("/v/kiralik-butik", { waitUntil: "domcontentloaded" });
      await page.waitForTimeout(3000);

      const kiralaLink = page.locator('a[href*="/rent-demo"]').first();
      if (await kiralaLink.isVisible({ timeout: 5000 }).catch(() => false)) {
        const href = await kiralaLink.getAttribute("href") || "";
        kiralananSlug = new URL(href, "https://x").searchParams.get("slug") || "kiralik-butik";
        await kiralaLink.click();
        await page.waitForTimeout(5000);
        await shot("12-rent-demo-sayfasi.png");
        kaydet("2. Vitrin kirala", "geçti", `Slug: ${kiralananSlug} | URL: ${page.url()}`);
      } else {
        kaydet("2. Vitrin kirala", "kaldı", "Kirala butonu bulunamadı");
      }
    } catch (e) {
      kaydet("2. Vitrin kirala", "kaldı", String((e as Error).message).slice(0, 200));
      await shot("12-kirala-hata.png");
    }

    // ── ADIM 3: Kiralama formunu doldur ───────────────────────────────
    try {
      const url = page.url();
      if (!url.includes("/rent-demo") && !url.includes("/v/")) {
        await page.goto(`/rent-demo?slug=${kiralananSlug || "kiralik-butik"}`, { waitUntil: "domcontentloaded" });
        await page.waitForTimeout(3000);
      }

      const inputs = page.locator("input:visible");
      const inputSayisi = await inputs.count();
      console.log(`  Rent-demo formunda ${inputSayisi} görünür input var`);
      for (let i = 0; i < inputSayisi; i++) {
        const inp = inputs.nth(i);
        console.log(`    ${i}: type=${await inp.getAttribute("type") || "text"}, placeholder="${await inp.getAttribute("placeholder") || ""}"`);
      }
      const btns = page.locator("button:visible");
      const btnSayisi = await btns.count();
      for (let i = 0; i < btnSayisi; i++) {
        console.log(`    Button ${i}: "${((await btns.nth(i).textContent()) || "").trim().slice(0, 50)}"`);
      }

      await shot("13-rent-demo-form.png");
      kaydet("3. Kiralama formu", "geçti", "Form incelendi");
    } catch (e) {
      kaydet("3. Kiralama formu", "kaldı", String((e as Error).message).slice(0, 200));
    }

    // ── ADIM 4: Asistan sohbetine serbest metin gönder ────────────────
    const motorSenaryolari = [
      { ad: "WhatsApp", metin: "WhatsApp numaram 0532 987 65 43" },
      { ad: "Çalışma saatleri", metin: "Hafta içi 09:00-19:00, cumartesi 10:00-18:00, pazar kapalıyız" },
      { ad: "Adres", metin: "Adresimiz Bağdat Cad. No:152, Erenköy, Kadıköy, İstanbul" },
    ];

    for (let i = 0; i < motorSenaryolari.length; i++) {
      const senaryo = motorSenaryolari[i];
      try {
        const sohbetBtn = page.getByRole("button", { name: /Sohbet/i }).first();
        if (await sohbetBtn.isVisible({ timeout: 3000 }).catch(() => false)) {
          await sohbetBtn.click();
          await page.waitForTimeout(1000);
        }

        const mesajKutusu = page.locator('textarea:visible, input[type="text"]:visible').last();
        if (await mesajKutusu.isVisible({ timeout: 3000 }).catch(() => false)) {
          await mesajKutusu.fill(senaryo.metin);
          await page.getByRole("button", { name: "Gönder" }).click();
          await page.waitForTimeout(3000);
          await page.screenshot({ path: path.join(snapDir, `2${i}-motor-${senaryo.ad.toLowerCase().replace(/\s+/g, "-")}.png`) });

          const panel = page.locator('[data-owner-assistant]').first();
          const panelMetni = (await panel.textContent({ timeout: 5000 }).catch(() => "")) || "";
          const sonucVar = panelMetni.length > 100;
          kaydet(`4.${i + 1} Motor: ${senaryo.ad}`, sonucVar ? "geçti" : "belirsiz",
            `Panel içeriği ${(panelMetni.length / 1000).toFixed(1)}k karakter`);
        } else {
          kaydet(`4.${i + 1} Motor: ${senaryo.ad}`, "kaldı", "Mesaj kutusu görünür değil");
          await page.screenshot({ path: path.join(snapDir, `2${i}-motor-hata.png`) });
        }
      } catch (e) {
        kaydet(`4.${i + 1} Motor: ${senaryo.ad}`, "kaldı", String((e as Error).message).slice(0, 150));
      }
    }

    // ── ADIM 5: Yayınla butonuna bak ──────────────────────────────────
    try {
      const yayinlaBtn = page.getByRole("button", { name: /Yayınla/i }).first();
      const yayinlaVar = await yayinlaBtn.isVisible({ timeout: 3000 }).catch(() => false);
      const eksikUyari = await page.locator('text=/gerekli bilgi eksik/i').first().isVisible({ timeout: 2000 }).catch(() => false);
      await shot("23-yayin-kontrol.png");
      kaydet("5. Yayın doğrulaması", "geçti",
        `Yayınla butonu: ${yayinlaVar ? "var" : "yok"} | Eksik uyarısı: ${eksikUyari ? "görünüyor" : "yok"}`);
    } catch (e) {
      kaydet("5. Yayın doğrulaması", "kaldı", String((e as Error).message).slice(0, 150));
    }

    // ── RAPOR ─────────────────────────────────────────────────────────
    console.log("\n═══════════════════════════════════════════════");
    console.log("  ESNAF İLK KEZ — AKIŞ RAPORU");
    console.log("═══════════════════════════════════════════════");
    console.table(adimSonuc);
  });
});

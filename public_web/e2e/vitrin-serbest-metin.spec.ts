import { expect, test } from "@playwright/test";
import * as fs from "fs";
import * as path from "path";

/**
 * Vixrex Asistan — serbest metin düzenleme akışı regresyon testi.
 * RAPOR.md (2026-09-09) gözlemlerine dayalı 2 senaryo.
 *
 * Senaryo 1: Çalışma Saatleri alanına çok günlü saat cümlesi yazıldığında
 *   - working_hours alanının üç gün grubunu da içermesi
 *   - address (açık adres) alanının değişmemesi
 *
 * Senaryo 2: WhatsApp alanına "kullanmıyorum" cümlesi yazıldığında
 *   - Sistemin gösterdiği mesaj ve alanın son değeri gözlemlenir (assert YOK)
 *
 * Giriş ve vitrin erişimi: esnaf-akisi.spec.ts adım 0 ve 8'den AYNEN kopyalanmıştır.
 */

test.describe("Vixrex Asistan — serbest metin düzenleme regresyonu", () => {
  test("mevcut vitrinde serbest metin ile çalışma saatleri ve WhatsApp düzenleme", async ({ page }) => {
    const consoleErrors: string[] = [];
    const pageErrors: string[] = [];
    const failedRequests: string[] = [];
    let vitrinSlug: string | null = null;

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
          if (body?.slug) vitrinSlug = String(body.slug);
        } catch {}
      }
      if (status >= 400) {
        failedRequests.push(`${status} ${resp.request().method()} ${url}`);
      }
    });
    page.on("requestfailed", (req) => {
      failedRequests.push(`FAILED ${req.method()} ${req.url()} - ${req.failure()?.errorText}`);
    });

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

    // ————————————————————————————————————————————————————————————————————————
    // ADIM 0: Kalıcı test hesabıyla giriş yap
    // ————————————————————————————————————————————————————————————————————————
    try {
      await page.goto("/giris", { waitUntil: "domcontentloaded" });
      await expect(page.getByRole("heading", { name: /Giriş Yap/i })).toBeVisible({ timeout: 10_000 });

      const girisCookieBtn = page.getByRole("button", { name: /Yalnızca gerekli|Tümünü kabul et/i });
      if (await girisCookieBtn.first().isVisible({ timeout: 1500 }).catch(() => false)) {
        await girisCookieBtn.first().click();
      }

      const emailInput = page.getByPlaceholder("ornek@eposta.com");
      const sifreInput = page.getByPlaceholder("••••••••");
      await expect(emailInput).toBeVisible({ timeout: 5000 });
      await expect(sifreInput).toBeVisible({ timeout: 5000 });
      await emailInput.fill("vixrex.test.1787911144069@gmail.com");
      await sifreInput.fill("Test!1787911144069");
      await expect(emailInput).toHaveValue("vixrex.test.1787911144069@gmail.com", { timeout: 3000 });
      await page.getByRole("button", { name: "Giriş Yap", exact: true }).click();
      await page.waitForURL("**/app**", { timeout: 15_000 });
      await expect(page).toHaveURL(/\/app/);
      await page.waitForTimeout(1500);
      kaydet("0. Giriş (kalıcı test hesabı)", "geçti");
      await shot("00-giris.png");
    } catch (e) {
      kaydet("0. Giriş (kalıcı test hesabı)", "kaldı", String((e as Error).message).slice(0, 500));
      await shot("00-giris-hata.png");
      throw e;
    }

    // ————————————————————————————————————————————————————————————————————————
    // ADIM 1: Vitrin slug belirleme
    // ————————————————————————————————————————————————————————————————————————
    try {
      if (!vitrinSlug) {
        vitrinSlug = "kiralik-kafe";
      }
      kaydet("1. Vitrin slug belirleme", "geçti", `Kullanılacak slug: ${vitrinSlug}`);
      await shot("01-slug.png");
    } catch (e) {
      kaydet("1. Vitrin slug belirleme", "kaldı", String((e as Error).message).slice(0, 400));
      await shot("01-hata.png");
      throw e;
    }

    // ————————————————————————————————————————————————————————————————————————
    // ADIM 2: Vitrin sayfasına owner modunda git
    // Zincir:
    //   1) Giriş sonrası Supabase access token'ı localStorage'dan al
    //   2) /api/owner-session/self POST ile sahip oturumu oluştur
    //   3) Geri dönen yonlendir URL'ini ziyaret et (cookie kurulur)
    //   4) Kullanıcıda vitrin yoksa /api/create-store ile oluştur, sonra oturum
    // ————————————————————————————————————————————————————————————————————————
    try {
      const accessToken = await page.evaluate(async () => {
        try {
          const storageKeys = Object.keys(localStorage);
          const supaKey = storageKeys.find((k) =>
            k.startsWith("sb-") && k.includes("auth")
          );
          if (supaKey) {
            const raw = localStorage.getItem(supaKey);
            if (raw) {
              const parsed = JSON.parse(raw);
              if (parsed?.access_token) return parsed.access_token;
            }
          }
          const { supabase } = await import("@/lib/supabase");
          const { data } = await supabase.auth.getSession();
          return data.session?.access_token ?? null;
        } catch {
          return null;
        }
      });

      if (!accessToken) {
        throw new Error("Supabase access token alınamadı — giriş başarısız veya oturum sunucuda yok.");
      }

      const selfResponse = await page.request.post("/api/owner-session/self", {
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        data: { slug: vitrinSlug },
      });

      if (selfResponse.ok()) {
        const selfData = await selfResponse.json();
        vitrinSlug = String(selfData.slug);
        if (selfData?.yonlendir) {
          await page.goto(selfData.yonlendir, { waitUntil: "domcontentloaded" });
        }
      } else if (selfResponse.status() === 404) {
        const createResponse = await page.request.post("/api/create-store", {
          headers: {
            Authorization: `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          data: {
            name: `Test Dukkan ${Date.now()}`,
            kategori: "Kafe",
            whatsapp: "05551234567",
            address: "Test Mah. No:1 Kadıköy İstanbul",
            province_name: "İstanbul",
            district_name: "Kadıköy",
          },
        });

        if (createResponse.ok()) {
          const createData = await createResponse.json();
          vitrinSlug = String(createData.slug);
          kaydet("1. Vitrin slug belirleme", "geçti", `Yeni vitrin oluşturuldu: /v/${vitrinSlug}`);
          const selfResponse2 = await page.request.post("/api/owner-session/self", {
            headers: {
              Authorization: `Bearer ${accessToken}`,
              "Content-Type": "application/json",
            },
            data: { slug: vitrinSlug },
          });
          if (selfResponse2.ok()) {
            const selfData2 = await selfResponse2.json();
            if (selfData2?.yonlendir) {
              await page.goto(selfData2.yonlendir, { waitUntil: "domcontentloaded" });
            }
          } else {
            throw new Error(`Owner session (create-store sonrası) başarısız: ${selfResponse2.status()}`);
          }
        } else {
          const createBody = await createResponse.text().catch(() => "");
          throw new Error(`Vitrin oluşturma başarısız: ${createResponse.status()} ${createBody}`);
        }
      } else {
        throw new Error(`Owner session başarısız: ${selfResponse.status()}`);
      }

      await page.goto(`/v/${vitrinSlug}`, { waitUntil: "domcontentloaded" });
      await expect(page.getByRole("heading", { level: 1 }).first()).toBeVisible({ timeout: 10_000 });
      await shot("02-vitrin-ziyaretci.png");

      const asistanPanel = page.locator('[data-owner-assistant="compact"]');
      await expect(asistanPanel).toBeVisible({ timeout: 10_000 });

      kaydet("2. Vitrin owner modunda açma", "geçti");
      await shot("03-vitrin-owner.png");
    } catch (e) {
      kaydet("2. Vitrin owner modunda açma", "kaldı", String((e as Error).message).slice(0, 500));
      await shot("03-hata.png");
      throw e;
    }

    // ————————————————————————————————————————————————————————————————————————
    // YARDIMCI FONKSİYON: Alan seç ve metin gönder
    // ————————————————————————————————————————————————————————————————————————
    async function alanSecVeGonder(alanAnahtar: string, metin: string) {
      const alanElement = page.locator(`[data-vixrex-editable="${alanAnahtar}"]`).first();
      await expect(alanElement).toBeVisible({ timeout: 5000 });
      await alanElement.click();

      const girisKutusu = page.getByRole("textbox", { name: /Vixrex Asistan'a yaz/i });
      await expect(girisKutusu).toBeVisible({ timeout: 5000 });

      let oncekiAdres = "";
      if (alanAnahtar === "calismaSaatleri") {
        const adresElement = page.locator('[data-vixrex-editable="adres"]').first();
        if (await adresElement.isVisible({ timeout: 2000 }).catch(() => false)) {
          oncekiAdres = await adresElement.textContent() || "";
        }
      }

      await girisKutusu.fill(metin);

      const gonderBtn = page.getByRole("button", { name: /Gönder/i });
      await expect(gonderBtn).toBeVisible({ timeout: 5000 });
      await gonderBtn.click();

      await page.waitForTimeout(2000);
      await page.reload({ waitUntil: "domcontentloaded" });
      await expect(page.getByRole("heading", { level: 1 }).first()).toBeVisible({ timeout: 10_000 });

      return oncekiAdres;
    }

    // ————————————————————————————————————————————————————————————————————————
    // SENARYO 1: Çalışma Saatleri — çok günlü saat cümlesi
    // Gönderilecek: "Hafta içi 09:00-18:00, cumartesi 10:00-16:00, pazar kapalı."
    // Beklenen: working_hours üç gün grubunu da içermeli, address değişmemeli
    // ————————————————————————————————————————————————————————————————————————
    try {
      const oncekiAdres = await alanSecVeGonder(
        "calismaSaatleri",
        "Hafta içi 09:00-18:00, cumartesi 10:00-16:00, pazar kapalı."
      );

      const calismaSaatleriElement = page.locator('[data-vixrex-editable="calismaSaatleri"]').first();
      await expect(calismaSaatleriElement).toBeVisible({ timeout: 5000 });
      const calismaSaatleriDeger = await calismaSaatleriElement.textContent() || "";

      const adresElement = page.locator('[data-vixrex-editable="adres"]').first();
      await expect(adresElement).toBeVisible({ timeout: 5000 });
      const adresDeger = await adresElement.textContent() || "";

      const haftaIciVar = /hafta\s*i[çc]i|pazartesi|salı|çarşamba|perşembe|cuma/i.test(calismaSaatleriDeger);
      const cumartesiVar = /cumartesi/i.test(calismaSaatleriDeger);
      const pazarVar = /pazar\s*kapalı|pazar\s*kapali/i.test(calismaSaatleriDeger);

      expect(haftaIciVar, "working_hours 'hafta içi' veya hafta içi günlerini içermeli").toBeTruthy();
      expect(cumartesiVar, "working_hours 'cumartesi' grubunu içermeli").toBeTruthy();
      expect(pazarVar, "working_hours 'pazar kapalı' bilgisini içermeli").toBeTruthy();

      expect(adresDeger.trim(), "address alanı çalışma saatleri düzenlemesinden etkilenmemeli").toBe(oncekiAdres.trim());

      kaydet("Senaryo 1: Çalışma saatleri çok günlü cümle", "geçti",
        `working_hours: ${calismaSaatleriDeger.slice(0, 100)} | address korundu: ${adresDeger === oncekiAdres}`);
      await shot("04-senario1-calisma-saatleri.png");
    } catch (e) {
      kaydet("Senaryo 1: Çalışma saatleri çok günlü cümle", "kaldı", String((e as Error).message).slice(0, 500));
      await shot("04-senario1-hata.png");
      console.error("Senaryo 1 hata:", e);
    }

    // ————————————————————————————————————————————————————————————————————————
    // SENARYO 2: WhatsApp — "kullanmıyorum" cümlesi
    // Gönderilecek: "WhatsApp kullanmıyorum, müşteriler beni telefonla arasın."
    // Beklenen: SADECE GÖZLEM — assert YOK
    // ————————————————————————————————————————————————————————————————————————
    try {
      await alanSecVeGonder(
        "whatsapp",
        "WhatsApp kullanmıyorum, müşteriler beni telefonla arasın."
      );

      const asistanMesajlari = page.locator('[data-owner-assistant="compact"] .vixrex-panel-kaydirici [data-message-expanded] >> text=/.*/');
      const mesajlar = await asistanMesajlari.allTextContents();
      const sonAsistanMesaji = mesajlar.filter(m => m.includes("asistan") || m.includes("Asistan") || !m.includes("kullanici"))[0] || "mesaj alınamadı";

      const whatsappElement = page.locator('[data-vixrex-editable="whatsapp"]').first();
      await expect(whatsappElement).toBeVisible({ timeout: 5000 });
      const whatsappDeger = await whatsappElement.textContent() || "";

      const telefonElement = page.locator('[data-vixrex-editable="telefon"]').first();
      let telefonDeger = "";
      if (await telefonElement.isVisible({ timeout: 2000 }).catch(() => false)) {
        telefonDeger = await telefonElement.textContent() || "";
      }

      await test.step("Senaryo 2 gözlem: WhatsApp 'kullanmıyorum' cümlesi sonrası sistem davranışı", async () => {
        // Sadece gözlem — assert yok
      });

      kaydet("Senaryo 2: WhatsApp kullanmıyorum cümlesi (gözlem)", "geçti",
        `Sistem mesajı: ${sonAsistanMesaji.slice(0, 100)} | WhatsApp: ${whatsappDeger} | Telefon: ${telefonDeger}`);
      await shot("05-senario2-whatsapp.png");
    } catch (e) {
      kaydet("Senaryo 2: WhatsApp kullanmıyorum cümlesi (gözlem)", "kaldı", String((e as Error).message).slice(0, 500));
      await shot("05-senario2-hata.png");
      console.error("Senaryo 2 hata:", e);
    }

    // ————————————————————————————————————————————————————————————————————————
    // SON: Özet rapor
    // ————————————————————————————————————————————————————————————————————————
    const kalan = adimSonuc.filter((r) => r.durum === "kaldı");
    if (kalan.length > 0) {
      console.log("\n=== KALAN (KIRMIZI) ADIMLAR ===");
      kalan.forEach(k => console.log(`- ${k.adim}: ${k.hata}`));
    }

    const senaryo1Sonuc = adimSonuc.find(r => r.adim.includes("Senaryo 1"));
    if (senaryo1Sonuc && senaryo1Sonuc.durum === "kaldı") {
      throw new Error(`Senaryo 1 (assertli) başarısız: ${senaryo1Sonuc.hata}`);
    }
  });
});

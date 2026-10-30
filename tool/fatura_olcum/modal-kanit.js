const { chromium } = require("playwright");
const path = require("path");

const KOK = path.join(__dirname, "..", "..");
const ADRES = process.env.KANIT_ADRES || "http://localhost:3005/v/elif-market-test-3-mvqfxnwm";
const CIKTI = path.join(__dirname, "ekran");

(async () => {
  const tarayici = await chromium.launch();
  const sayfa = await tarayici.newPage({ viewport: { width: 1600, height: 950 } });
  const hatalar = [];
  sayfa.on("pageerror", (hata) => hatalar.push(`pageerror: ${hata.message}`));
  sayfa.on("response", (yanit) => {
    if (yanit.status() >= 400) hatalar.push(`http ${yanit.status()}: ${yanit.url()}`);
  });

  await sayfa.goto(ADRES, { waitUntil: "domcontentloaded", timeout: 60000 });
  await sayfa.waitForTimeout(2500);

  const cerez = sayfa.getByRole("button", { name: "Tümünü kabul et" });
  if (await cerez.count()) await cerez.click().catch(() => {});

  const kart = sayfa.locator('a[aria-label^="Sütaş Ayran 300 ml ürününü"]').first();
  await kart.click();
  await sayfa.waitForSelector('[role="dialog"]', { timeout: 15000 });
  await sayfa.waitForTimeout(1200);
  await sayfa.screenshot({ path: path.join(CIKTI, "2026-10-28-yerel-modal-ust.png") });

  await sayfa.evaluate(() => {
    const diyalog = document.querySelector('[role="dialog"]');
    const panel = Array.from(diyalog.querySelectorAll("div")).find(
      (eleman) => eleman.scrollHeight > eleman.clientHeight + 20,
    );
    if (panel) panel.scrollTop = panel.scrollHeight;
  });
  await sayfa.waitForTimeout(500);
  await sayfa.screenshot({ path: path.join(CIKTI, "2026-10-28-yerel-modal-alt.png") });

  const olcum = await sayfa.evaluate(() => {
    const diyalog = document.querySelector('[role="dialog"]');
    const metin = diyalog.innerText;
    return {
      sizinti: {
        openrouter: metin.includes("OpenRouter"),
        barkod: metin.includes("Barkod") || metin.includes("GTIN"),
        aktarilan: metin.includes("(aktarılan)"),
        varsayilan: metin.includes("varsayılan"),
      },
      altDugmeler: metin.includes("Sepete ekle") && metin.includes("Beğen"),
    };
  });

  await sayfa.getByRole("button", { name: "Sepete ekle" }).click();
  await sayfa.waitForTimeout(900);
  await sayfa.screenshot({ path: path.join(CIKTI, "2026-10-28-yerel-sepete-eklendi.png") });
  const sepetMesaji = await sayfa.evaluate(() => {
    const durum = document.querySelector('[role="dialog"] [role="status"]');
    return durum ? durum.textContent : "(mesaj yok)";
  });

  await sayfa.getByRole("button", { name: /Beğen/ }).first().click();
  await sayfa.waitForTimeout(900);
  await sayfa.screenshot({ path: path.join(CIKTI, "2026-10-28-yerel-begen-mesaji.png") });
  const begenMesaji = await sayfa.evaluate(() => {
    const durum = document.querySelector('[role="dialog"] [role="status"]');
    return durum ? durum.textContent : "(mesaj yok)";
  });

  console.log(JSON.stringify({ olcum, sepetMesaji, begenMesaji, hatalar }, null, 2));
  await tarayici.close();
})();

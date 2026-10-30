#!/usr/bin/env node
const path = require("path");
const { chromium } = require(path.join(__dirname, "..", "public_web", "node_modules", "playwright"));

const VARSAYILAN = "https://vixrex.com/v/elif-market-test-3-mvqfxnwm";
const MIN_KISA_KENAR = 1200;

function katla(metin) {
  return String(metin || "")
    .toLocaleLowerCase("tr-TR")
    .replace(/[şığüöçİ]/g, (harf) => ({ ş: "s", ı: "i", ğ: "g", ü: "u", ö: "o", ç: "c", İ: "i" })[harf] || harf)
    .replace(/[^a-z0-9]+/g, " ")
    .trim();
}

function miktar(metin) {
  const eslesme = /(\d+(?:[.,]\d+)?)\s*(kg|g|gr|gram|ml|cl|lt|l|litre|adet)\b/i.exec(String(metin || ""));
  if (!eslesme) return null;
  const deger = Number(eslesme[1].replace(",", "."));
  const birim = eslesme[2].toLowerCase();
  if (birim === "kg") return `${Math.round(deger * 1000)} g`;
  if (["g", "gr", "gram"].includes(birim)) return `${Math.round(deger)} g`;
  if (birim === "ml") return `${Math.round(deger)} ml`;
  if (birim === "cl") return `${Math.round(deger * 10)} ml`;
  if (["l", "lt", "litre"].includes(birim)) return `${Math.round(deger * 1000)} ml`;
  return `${Math.round(deger)} adet`;
}

(async () => {
  const adres = process.argv[2] && !process.argv[2].startsWith("--") ? process.argv[2] : VARSAYILAN;
  const tarayici = await chromium.launch();
  const baglam = await tarayici.newContext({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 2 });
  const sayfa = await baglam.newPage();

  try {
    await sayfa.goto(`${adres}${adres.includes("?") ? "&" : "?"}t=${Date.now()}`, {
      waitUntil: "load",
      timeout: 90000,
    });
    try {
      const kabul = sayfa.getByRole("button", { name: /Tümünü kabul et/ }).first();
      await kabul.waitFor({ timeout: 4000 });
      await kabul.click();
    } catch {}
    await sayfa.waitForTimeout(2000);

    const olcum = await sayfa.evaluate(() => {
      const kartlar = Array.from(document.querySelectorAll("article")).map((kart) => {
        const gorsel = kart.querySelector("img");
        const ad = kart.querySelector("h3");
        const kutu = gorsel ? gorsel.getBoundingClientRect() : null;
        const ozellikSatiri = ad ? ad.nextElementSibling : null;
        const kesik = (oge) =>
          Boolean(oge) && (oge.scrollWidth > oge.clientWidth + 1 || oge.scrollHeight > oge.clientHeight + 1);
        return {
          ad: ad ? ad.innerText.trim() : "",
          fiyat: (kart.innerText.match(/[\d.]+,\d+ TL/) || [])[0] || null,
          gorsel: gorsel ? gorsel.currentSrc || gorsel.src : null,
          gorselPiksel: gorsel ? [gorsel.naturalWidth, gorsel.naturalHeight] : [0, 0],
          kutu: kutu ? [Math.round(kutu.width), Math.round(kutu.height)] : [0, 0],
          adKesik: kesik(ad),
          ozellikKesik: kesik(ozellikSatiri),
          metin: kart.innerText.replace(/\s+/g, " ").trim(),
        };
      });
      return {
        kartlar,
        yatayTasma: document.documentElement.scrollWidth > window.innerWidth + 1,
        dpr: window.devicePixelRatio,
      };
    });

    const gereken = olcum.kartlar[0]
      ? [Math.round(olcum.kartlar[0].kutu[0] * olcum.dpr), Math.round(olcum.kartlar[0].kutu[1] * olcum.dpr)]
      : [0, 0];

    const gruplar = new Map();
    for (const kart of olcum.kartlar) {
      const anahtar = `${katla(kart.ad)}|${miktar(kart.metin) || ""}`;
      gruplar.set(anahtar, [...(gruplar.get(anahtar) || []), kart]);
    }
    const tekrarlar = [...gruplar.values()]
      .filter((grup) => grup.length > 1)
      .map((grup) => grup.map((kart) => `${kart.ad} (${kart.fiyat || "fiyat yok"})`));

    const kucukGorsel = olcum.kartlar.filter(
      (kart) =>
        kart.gorselPiksel[0] > 0 &&
        (kart.gorselPiksel[0] < gereken[0] || kart.gorselPiksel[1] < gereken[1]),
    );
    const kartGorselAltSinir = olcum.kartlar.filter(
      (kart) => kart.gorselPiksel[0] > 0 && Math.min(...kart.gorselPiksel) < MIN_KISA_KENAR,
    );
    const kesikler = olcum.kartlar.filter((kart) => kart.adKesik || kart.ozellikKesik);
    const kategoriCift = olcum.kartlar.filter((kart) => {
      const adet = (kart.metin.match(/İçecek \/ Gazlı İçecek|Atıştırmalık \/ [A-Za-zÇĞİÖŞÜçğıöşü]+|Süt Ürünleri \/ [A-Za-zÇĞİÖŞÜçğıöşü]+|Gıda \/ [A-Za-zÇĞİÖŞÜçğıöşü]+/g) || []).length;
      return adet > 1;
    });

    const rapor = {
      adres,
      kart: olcum.kartlar.length,
      gerekenPiksel: gereken,
      tekrarlar,
      kucukGorsel: kucukGorsel.map((kart) => ({ ad: kart.ad, piksel: kart.gorselPiksel })),
      depoEşiğininAltinda: kartGorselAltSinir.map((kart) => ({ ad: kart.ad, piksel: kart.gorselPiksel })),
      kesikMetin: kesikler.map((kart) => kart.ad),
      kategoriTekrari: kategoriCift.map((kart) => kart.ad),
      yatayTasma: olcum.yatayTasma,
    };

    console.log(`Kart: ${rapor.kart} · gereken görsel: ${gereken.join("x")} px`);
    console.log(`Tekrar grubu: ${tekrarlar.length}${tekrarlar.length ? " → " + JSON.stringify(tekrarlar) : ""}`);
    console.log(`Kutuya yetmeyen görsel: ${kucukGorsel.length} / ${olcum.kartlar.length}`);
    console.log(`Depo eşiğinin (${MIN_KISA_KENAR} px) altında: ${kartGorselAltSinir.length} / ${olcum.kartlar.length}`);
    console.log(`Kesik metin (uyarı): ${kesikler.length} · Kategori tekrarı: ${kategoriCift.length} · Yatay taşma: ${olcum.yatayTasma ? "var" : "yok"}`);
    if (process.argv.includes("--json")) console.log(JSON.stringify(rapor, null, 2));

    const ihlal =
      tekrarlar.length + kucukGorsel.length + kategoriCift.length + (olcum.yatayTasma ? 1 : 0);
    if (ihlal > 0) {
      console.log(`SONUÇ: standart altı — ${ihlal} bulgu`);
      process.exitCode = 1;
    } else {
      console.log("SONUÇ: standart içinde");
    }
  } catch (hata) {
    console.error("ÖLÇÜM HATASI:", hata.message);
    process.exitCode = 2;
  } finally {
    await tarayici.close();
  }
})();

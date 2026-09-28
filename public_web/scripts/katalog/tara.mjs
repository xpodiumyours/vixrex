/**
 * Ürün havuzu tarayıcısı — ana komut.
 *
 * firmalar.json'daki firmaları gezer; her firmanın hangi platformda olduğunu
 * tespit eder, doğru okuyucuyu çalıştırır, sonucu tek standart dosyaya yazar
 * ve ölçülen sayıları rapor eder.
 *
 * Kullanım:
 *   node scripts/katalog/tara.mjs                          (hepsi)
 *   node scripts/katalog/tara.mjs --platform=woocommerce   (yalnız bu okuyucu denensin)
 *   node scripts/katalog/tara.mjs --firma=seher-mensucat   (seçili firmalar)
 *   node scripts/katalog/tara.mjs --sinir=3                (ilk 3 firma)
 *   node scripts/katalog/tara.mjs --sinir-urun=100         (firma başına ürün sınırı)
 *   node scripts/katalog/tara.mjs --paralel=4               (aynı anda 4 firma)
 *   node scripts/katalog/tara.mjs --kuru                    (yazmadan dene)
 *
 * Hiçbir ölçüm olmadan rapor yazılmaz; başarısız firma sessizce atlanmaz.
 */

import { readdir, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

import {
  firmalariOku,
  katalogYaz,
  ozet,
  raporYazdir,
  siteDurumu,
  urunleriNormalle,
} from "./_ortak.mjs";

const BURASI = path.dirname(fileURLToPath(import.meta.url));
const PLATFORM_KLASORU = path.join(BURASI, "platformlar");
const RAPOR_DOSYASI = path.join(BURASI, "rapor.json");

function argumanlariCoz() {
  const sonuc = { kuru: false, platform: "", firmalar: [], sinir: 0, sinirUrun: 0, paralel: 1 };
  for (const ham of process.argv.slice(2)) {
    const govde = ham.replace(/^--/, "");
    const esittir = govde.indexOf("=");
    const anahtar = esittir === -1 ? govde : govde.slice(0, esittir);
    const deger = esittir === -1 ? "" : govde.slice(esittir + 1);

    if (anahtar === "kuru") sonuc.kuru = true;
    else if (anahtar === "platform") sonuc.platform = deger.trim();
    else if (anahtar === "firma") {
      sonuc.firmalar = deger.split(",").map((s) => s.trim()).filter(Boolean);
    } else if (anahtar === "sinir") sonuc.sinir = Number(deger) || 0;
    else if (anahtar === "sinir-urun") sonuc.sinirUrun = Number(deger) || 0;
    else if (anahtar === "paralel") sonuc.paralel = Number(deger) || 1;
  }
  return sonuc;
}

/** platformlar/ klasöründeki tüm okuyucuları yükler. Yeni okuyucu = yeni dosya. */
async function okuyuculariYukle() {
  let dosyalar = [];
  try {
    dosyalar = await readdir(PLATFORM_KLASORU);
  } catch {
    return [];
  }

  const okuyucular = [];
  for (const dosya of dosyalar.filter((d) => d.endsWith(".mjs")).sort()) {
    const modul = await import(pathToFileURL(path.join(PLATFORM_KLASORU, dosya)).href);
    if (modul.AD && typeof modul.tespitEt === "function" && typeof modul.cek === "function") {
      okuyucular.push(modul);
    }
  }
  return okuyucular;
}

function bosSatir(firma, durum, platform = "-") {
  return { firma: firma.ad, platform, durum, urun: 0, kodsuz: 0, barkod: 0, foto: 0 };
}

async function firmayiTara(firma, okuyucular, { kuru, zorlaPlatform, sinirUrun }) {
  if (!firma.site) return bosSatir(firma, "site yok");

  const kok = `https://${firma.site}/`;

  const site = await siteDurumu(kok);
  if (!site.ulasildi) return bosSatir(firma, "ulasilamadi");
  if (site.engelli) return bosSatir(firma, "robots engeli");

  // Okuyucu seçimi: önce kilitli platform, sonra tek tek yoklama.
  let okuyucu = null;
  const istenen = zorlaPlatform || firma.platform;
  if (istenen) okuyucu = okuyucular.find((o) => o.AD === istenen) ?? null;

  if (!okuyucu) {
    for (const aday of okuyucular) {
      // Yavaş çalışan okuyucular (her ürün için ayrı sayfa okuyanlar)
      // kendiliğinden denenmez; yalnız --platform ile açıkça istendiğinde.
      if (aday.otomatik === false) continue;
      if (await aday.tespitEt(firma.site)) {
        okuyucu = aday;
        break;
      }
    }
  }

  if (!okuyucu) return bosSatir(firma, "okunamadi", "taninmadi");

  const { urunler: hamlar, kodsuz, kesildi } = await okuyucu.cek(firma.site, {
    sinir: sinirUrun || undefined,
  });
  const urunler = urunleriNormalle(hamlar, kok);
  const sayilar = ozet(urunler);

  // Hiç ürün dönmediyse bu site o platformda değil demektir. Böyle bir siteye
  // "kod yok" demek yanlış olur: kodu olmayan ürün de yok, ürünün kendisi yok.
  if (urunler.length === 0 && kodsuz === 0) return bosSatir(firma, "okunamadi", "taninmadi");

  if (urunler.length > 0 && !kuru) await katalogYaz(firma.anahtar, urunler);

  return {
    firma: firma.ad,
    platform: okuyucu.AD,
    durum:
      urunler.length === 0 ? "kod yok" : kesildi ? "ok (sinirli)" : "ok",
    urun: sayilar.urun,
    kodsuz,
    barkod: sayilar.barkodlu,
    foto: sayilar.fotografli,
  };
}

async function ana() {
  const secenekler = argumanlariCoz();
  const okuyucular = await okuyuculariYukle();
  if (okuyucular.length === 0) throw new Error("platformlar/ klasöründe okunabilir okuyucu yok.");

  let firmalar = await firmalariOku();

  if (secenekler.firmalar.length) {
    firmalar = firmalar.filter((f) => secenekler.firmalar.includes(f.anahtar));
  }
  if (secenekler.sinir > 0) firmalar = firmalar.slice(0, secenekler.sinir);

  const okuyucuAdlari = okuyucular
    .map((o) => (o.otomatik === false ? `${o.AD} (yalnız elle)` : o.AD))
    .join(", ");
  // Sınırlı çalıştırma bir ÖRNEKTİR: eksik veriyi tam katalog gibi yazmak,
  // havuza yarım ürün sokar. Bu yüzden örnek çalıştırma hiç dosya yazmaz.
  const yaz = !secenekler.kuru && secenekler.sinirUrun === 0;

  console.log(
    `${firmalar.length} firma taranıyor | okuyucular: ${okuyucuAdlari}` +
      `${secenekler.kuru ? " | KURU (dosya yazılmaz)" : ""}` +
      `${secenekler.sinirUrun > 0 ? ` | ÖRNEK: firma başına en çok ${secenekler.sinirUrun} ürün (dosya yazılmaz)` : ""}\n`,
  );

  // Nezaket kuralı site başına işlediği için farklı firmalar birbirini
  // yavaşlatmaz; birkaç firmayı aynı anda işlemek güvenlidir.
  const paralel = Math.max(1, secenekler.paralel);
  const satirlar = new Array(firmalar.length);

  for (let bas = 0; bas < firmalar.length; bas += paralel) {
    const dilim = firmalar.slice(bas, bas + paralel);
    const sonuclar = await Promise.all(
      dilim.map(async (firma) => {
        try {
          return await firmayiTara(firma, okuyucular, {
            kuru: !yaz,
            zorlaPlatform: secenekler.platform,
            sinirUrun: secenekler.sinirUrun,
          });
        } catch (hata) {
          return bosSatir(firma, `hata: ${String(hata.message).slice(0, 30)}`);
        }
      }),
    );

    sonuclar.forEach((satir, sira) => {
      satirlar[bas + sira] = satir;
      console.log(
        `  · ${String(satir.firma).padEnd(30)} ${satir.platform.padEnd(12)} ${satir.durum.padEnd(12)} ürün: ${satir.urun}`,
      );
    });
  }

  console.log("");

  raporYazdir(satirlar);

  // Tespit edilen platform firma listesine yazılır: sonraki turlar hangi
  // firmanın hangi okuyucuyu beklediğini bilir. "taninmadi" yazılmaz, yoksa
  // yeni eklenen okuyucular o firmayı bir daha denemez.
  if (yaz) {
    // Elle çalıştırılan okuyucuların adı platform değildir; yazılırsa sonraki
    // turlarda kendiliğinden seçilirler. Yalnız gerçek platformlar yazılır.
    const elleOkuyucular = new Set(
      okuyucular.filter((o) => o.otomatik === false).map((o) => o.AD),
    );

    let degisen = 0;
    firmalar.forEach((firma, i) => {
      const platform = satirlar[i]?.platform ?? "";
      if (!platform || platform === "-" || platform === "taninmadi") return;
      if (elleOkuyucular.has(platform)) return;
      if (firma.platform === platform) return;

      firma.platform = platform;
      degisen++;
    });
    if (degisen > 0) {
      const tumu = await firmalariOku();
      const guncel = tumu.map((firma) =>
        firmalar.find((f) => f.anahtar === firma.anahtar) ?? firma,
      );
      await writeFile(
        path.join(BURASI, "firmalar.json"),
        `${JSON.stringify(guncel, null, 2)}\n`,
        "utf8",
      );
      console.log(`${degisen} firmanın platformu firma listesine yazıldı.`);
    }
  }

  const toplam = satirlar.reduce((t, s) => t + s.urun, 0);
  const sinirli = satirlar.filter((s) => s.durum === "ok (sinirli)").length;
  const okunan = satirlar.filter((s) => s.durum === "ok").length + sinirli;
  console.log(
    `\nokunan firma: ${okunan}/${satirlar.length} | toplam ürün: ${toplam}` +
      (sinirli > 0 ? ` | ${sinirli} firma sınıra takıldı (katalog eksik olabilir)` : ""),
  );

  await writeFile(
    RAPOR_DOSYASI,
    `${JSON.stringify({ tarih: new Date().toISOString(), toplam, satirlar }, null, 2)}\n`,
    "utf8",
  );
  console.log(`rapor: ${RAPOR_DOSYASI}`);
}

ana().catch((hata) => {
  console.error("Tarama başarısız:", hata.message);
  process.exitCode = 1;
});

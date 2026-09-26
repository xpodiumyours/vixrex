/**
 * İzin listesi üreteci — TEK GERÇEK KAYNAK köprüsü.
 *
 * Görsel/veri kullanım izni yalnız `scripts/katalog/firmalar.json` içinde
 * tutulur. Çalışma anındaki eşleştirme kodu ise `data/katalog/` klasörünü
 * okur. Bu betik ikisini bağlar: firmalar.json'daki `izin` alanını, kataloğu
 * gerçekten var olan firmalar için `data/katalog/_firmalar.json` dosyasına
 * yazar.
 *
 * Neden gerekli: izin bilgisi iki ayrı yerde tutulursa biri güncellenip
 * diğeri unutulur ve izinsiz fotoğraf yayına sızar. Tek kaynak firmalar.json.
 *
 * Kullanım:  node scripts/katalog/izin-listesi-uret.mjs
 */
import { readFileSync, readdirSync, writeFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const BURASI = path.dirname(fileURLToPath(import.meta.url));
const FIRMALAR = path.join(BURASI, "firmalar.json");
const KATALOG_KLASORU = path.resolve(BURASI, "..", "..", "data", "katalog");
const CIKTI = path.join(KATALOG_KLASORU, "_firmalar.json");

const GECERLI_IZINLER = new Set(["yok", "bekliyor", "var"]);
const DOSYA_DUZENI = /^uretici-katalog-(.+)\.json$/;

const firmalar = JSON.parse(readFileSync(FIRMALAR, "utf8"));
const firmaHaritasi = new Map(firmalar.map((firma) => [firma.anahtar, firma]));

const katalogAnahtarlari = readdirSync(KATALOG_KLASORU)
  .map((dosya) => DOSYA_DUZENI.exec(dosya)?.[1])
  .filter((anahtar) => typeof anahtar === "string")
  .sort();

const liste = [];
const eksik = [];

for (const anahtar of katalogAnahtarlari) {
  const firma = firmaHaritasi.get(anahtar);
  if (!firma) {
    eksik.push(anahtar);
    continue;
  }

  // Tanınmayan izin değeri "var" sayılmamalı; en güvenli tarafa düşülür.
  const izinDurumu = GECERLI_IZINLER.has(firma.izin) ? firma.izin : "yok";
  if (izinDurumu !== firma.izin) {
    console.error(`UYARI: ${anahtar} için tanınmayan izin değeri "${firma.izin}" → "yok" sayıldı.`);
  }

  liste.push({ anahtar, ad: firma.ad, alan: firma.site, izinDurumu });
}

writeFileSync(CIKTI, `${JSON.stringify(liste, null, 2)}\n`, "utf8");

const izinli = liste.filter((f) => f.izinDurumu === "var").length;
console.log(`${liste.length} firma yazıldı → ${path.relative(process.cwd(), CIKTI)}`);
console.log(`Görsel izni "var" olan firma: ${izinli}`);
if (eksik.length) {
  console.error(`UYARI: firmalar.json içinde karşılığı olmayan katalog: ${eksik.join(", ")}`);
  process.exitCode = 1;
}

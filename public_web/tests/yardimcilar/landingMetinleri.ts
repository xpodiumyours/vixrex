import { readdirSync, readFileSync } from "fs";
import { resolve } from "path";

const DEPO_KOKU = resolve(__dirname, "../../..");

/** Satir sonu karakteri. Kod uretimi sirasinda ters bolu kacislari
 *  guvenilir tasinmadigi icin karakter kodundan uretiliyor. */
const SATIR_SONU = String.fromCharCode(10);

/** Dart kaynagindaki iki karakterlik satir-sonu KACISI (ters bolu + n). */
const KACIS_SATIR_SONU = String.fromCharCode(92) + "n";

/** Yorum satırlarını söker — açıklamada geçen metin kullanıcıya görünmez. */
function yorumsuz(kaynak: string): string {
  return kaynak
    .replace(/\/\*[\s\S]*?\*\//g, "")
    .replace(/^\s*\/\/.*$/gm, "");
}

function dizindekiDosyalar(dizin: string, uzantilar: string[]): string[] {
  return readdirSync(resolve(DEPO_KOKU, dizin))
    .filter((ad) => uzantilar.some((u) => ad.endsWith(u)))
    .map((ad) => readFileSync(resolve(DEPO_KOKU, dizin, ad), "utf-8"));
}

/**
 * Dize literallerini SATIR SATIR tarar.
 *
 * Tek bir çok satırlı desenle taramak iki kez bozuldu: önce çift tırnaklı
 * metinlerdeki kesme işareti ("Vixrex'e") eşleşmeyi kaydırdı, sonra da
 * desendeki satır sonu kaçışı ters bölü kaybına uğrayıp kod parçalarını
 * metin sanmaya yol açtı (ölçüldü: 116 yerine 45 metin). Satır bazlı tarama
 * kaçış gerektirmediği için ikisini de imkânsız kılar; Dart tarafında çok
 * satırlı literal kullanılmıyor.
 */
function satirdakiLiteraller(satir: string): string[] {
  const bulunanlar: string[] = [];
  for (const eslesme of satir.matchAll(/'([^']*)'|"([^"]*)"/g)) {
    bulunanlar.push(eslesme[1] ?? eslesme[2] ?? "");
  }
  return bulunanlar;
}

function kullaniciyaGorunurMu(metin: string): boolean {
  if (metin.length < 6 || metin.length > 120) return false;
  if (!metin.includes(" ")) return false; // tek kelime: anahtar/kimlik olabilir
  if (/^(package:|assets\/|http|\/)/.test(metin)) return false;
  if (/[{}$<>]/.test(metin)) return false; // interpolasyon / kod parçası
  if (!/[a-zçğıöşüA-ZÇĞİÖŞÜ]/.test(metin)) return false;
  return true;
}

/**
 * Flutter landing'inde kullanıcıya GÖRÜNEN metinler.
 *
 * Kaynak: `lib/screens/landing_screen.dart` + `lib/widgets/landing/*.dart`.
 * Flutter bu projede tanıtım yüzeyinin ASLI — web ondan eşitlenir, tersi
 * değil. Bu yüzden çıkarım Flutter tarafından yapılır.
 */
export function flutterLandingMetinleri(): Set<string> {
  const kaynaklar = [
    readFileSync(resolve(DEPO_KOKU, "lib/screens/landing_screen.dart"), "utf-8"),
    ...dizindekiDosyalar("lib/widgets/landing", [".dart"]),
    readFileSync(resolve(DEPO_KOKU, "lib/widgets/chatbot_badge.dart"), "utf-8"),
  ].map(yorumsuz);

  const metinler = new Set<string>();
  for (const kaynak of kaynaklar) {
    for (const satir of kaynak.split(SATIR_SONU)) {
      for (const literal of satirdakiLiteraller(satir)) {
        // Flutter basliklari tek bir literal icinde satir sonu KACISI
        // tasiyabiliyor (H1'in ucuncu parcasi boyle). Web tarafinda ayni
        // metin <br /> ile bolunuyor; parcalara ayirip her parcayi ayri
        // dogrulamak iki tarafi da dogru karsilastirir.
        for (const metin of literal.split(KACIS_SATIR_SONU)) {
          if (kullaniciyaGorunurMu(metin.trim())) metinler.add(metin.trim());
        }
      }
    }
  }
  return metinler;
}

/** Web platform yüzeyinin tüm kaynak metni — tek dize halinde. */
export function webPlatformKaynagi(): string {
  const dizinler = [
    "public_web/src/components/landing",
    "public_web/src/components/site",
    "public_web/src/components/kesfet",
  ];

  const sayfalar = [
    "public_web/src/app/(site)/page.tsx",
    "public_web/src/app/(site)/layout.tsx",
    "public_web/src/app/(site)/kesfet/page.tsx",
    "public_web/src/app/(site)/kesfet/[kategori]/page.tsx",
  ];

  const parcalar: string[] = [];
  for (const dizin of dizinler) {
    parcalar.push(...dizindekiDosyalar(dizin, [".tsx", ".ts"]));
  }
  for (const yol of sayfalar) {
    parcalar.push(readFileSync(resolve(DEPO_KOKU, yol), "utf-8"));
  }

  // JSX satır sonları metni bölebiliyor; karşılaştırma tek boşluğa indirgenir.
  return parcalar.join("\n").replace(/\s+/g, " ");
}

/** Web tarafındaki kategori etiketleri paylaşılan sözleşmeden gelir. */
export function paylasilanKategoriEtiketleri(): string[] {
  const sozlesme = JSON.parse(
    readFileSync(resolve(DEPO_KOKU, "shared/business_categories.json"), "utf-8")
  ) as { categories: Array<{ label: string }> };
  return sozlesme.categories.map((kategori) => kategori.label);
}

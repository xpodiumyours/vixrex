import { readdirSync, readFileSync } from "fs";
import { resolve } from "path";

const DEPO_KOKU = resolve(__dirname, "../../..");

const SATIR_SONU = String.fromCharCode(10);

/** Yorum satırlarını söker — açıklamada geçen metin kullanıcıya görünmez. */
function yorumsuz(kaynak: string): string {
  return kaynak
    .replace(/\/\*[\s\S]*?\*\//g, "")
    .replace(/^\s*\/\/.*$/gm, "")
    // Satır-içi `//` yorum artıkları (`// GAP-22: ...`) JSX içerik
    // taramasına sızıp kod parçalarını metin sanmaya yol açıyordu
    // (2026-09-03: "= ASISTAN_ADIMLARI.length; ... useRef" kırığı).
    // `://` (URL) korunur — yalnız `:` ile başlamayan `//` kesilir.
    .replace(/([^:])\/\/.*$/gm, "$1");
}

function dizindekiDosyalar(dizin: string, uzantilar: string[]): string[] {
  const tamYol = resolve(DEPO_KOKU, dizin);
  try {
    return readdirSync(tamYol)
      .filter((ad) => uzantilar.some((u) => ad.endsWith(u)))
      .map((ad) => readFileSync(resolve(tamYol, ad), "utf-8"));
  } catch {
    return [];
  }
}

function satirdakiLiteraller(satir: string): string[] {
  const bulunanlar: string[] = [];
  for (const eslesme of satir.matchAll(/'([^']*)'|"([^"]*)"/g)) {
    bulunanlar.push((eslesme[1] ?? eslesme[2] ?? "").trim());
  }
  return bulunanlar;
}

/**
 * Bir metnin Tailwind/CSS sınıf zincirleri içerip içermediğini kontrol eder.
 */
function tailwindZincirMi(metin: string): boolean {
  const parcalar = metin.split(/\s+/);
  if (parcalar.length < 2) return false;

  let cssParcaSayisi = 0;
  for (const p of parcalar) {
    if (
      /^(absolute|relative|fixed|static|sticky|block|inline|hidden|flex|grid|overflow|pointer-events|sr-only|border|rounded|shadow|opacity|z-|inset|top|bottom|left|right|w-|h-|min-|max-|p-|px-|py-|pt-|pb-|pl-|pr-|m-|mx-|my-|mt-|mb-|ml-|mr-|gap-|space-|divide|items-|justify-|self-|content-|place-|order-|col-|row-|font-|text-|leading-|tracking-|whitespace-|break-|line-|align-|bg-|from-|to-|via-|gradient|border-|outline-|ring-|transition|duration|delay|ease|transform|scale-|rotate-|translate-|skew-|origin|cursor-|select-|appearance|resize|fill-|stroke-|accent-|will-change|decoration|backdrop-|caret-|scroll-|snap-|touch-|overscroll-|object-|aspect-|auto-|normal-|asis-|group-|peer-|first-|last-|odd-|even-|hover-|focus-|active-|disabled-|checked-|required-|valid-|invalid-|placeholder-|file-|marker-|selection-|read-only-|empty-|only-|open-|closed-|enabled-|sm:|md:|lg:|xl:|2xl:)/.test(p) ||
      /^\[.+\]$/.test(p) ||
      /^[\w/.-]+$/.test(p)
    ) {
      cssParcaSayisi++;
    }
  }

  return cssParcaSayisi / parcalar.length > 0.7;
}

/**
 * Tek kelimelik CSS yardımcılarını tanır: flex-1, h-full, w-full, text-[10px] vb.
 */
/**
 * JSX ifadesinin ortasında kalan kod parçalarını eler.
 *
 * İç içe koşullu JSX'te `) : durum ? (` gibi satırlar iki blok arasında
 * düz metin gibi görünüyor ve çıkarıcı bunları kullanıcı metni sanıyordu
 * (28 Ağustos: "tek asistan" dalında eşitlik testi bu yüzden kırıldı).
 * Gerçek bir Türkçe cümle ")" ile başlamaz ya da "? (" ile bitmez.
 */
function jsxIfadeParcasiMi(metin: string): boolean {
  return /^\)\s*:/.test(metin) || /\?\s*\($/.test(metin);
}

function tekKelimeCssMi(metin: string): boolean {
  if (metin.includes(" ")) return false;
  return (
    /^(flex-\d+|h-full|w-full|h-\[|w-\[|text-\[|text-white|text-black|text-lp-|border-|bg-|rounded|shadow|opacity|pointer-events|overflow|absolute|relative|fixed|static|hidden|block|inline|flex|grid|min-w|max-w|shrink-0|grow|object-cover|object-contain|aspect-\[|font-|tracking-|leading-)/.test(metin) ||
    /^\[.+\]$/.test(metin)
  );
}

/**
 * Bir metnin kullanıcıya görünür bir metin olup olmadığını kontrol eder.
 *
 * Flutter extractor'ındaki kriter: minimum 6 karakter, boşluk içermeli
 * (tek kelime anahtar/kimlik/label olabilir, karşılaştırma için güvenilir değil),
 * harf içermeli, kod/CSS/Tailwind/prop kalıpları içermemeli.
 */
function kullaniciyaGorunurMu(metin: string): boolean {
  if (metin.length < 6 || metin.length > 120) return false;
  if (!metin.includes(" ")) return false; // tek kelime: label/anahtar olabilir
  if (!/[a-zçğıöşüA-ZÇĞİÖŞÜ]/.test(metin)) return false;

  // Kesinlikle kod olan kalıplar
  if (/^(package:|assets\/|http|\/)/.test(metin)) return false;
  if (/[{}<>]/.test(metin)) return false;
  if (/^use [a-z]/.test(metin)) return false;
  if (/^\$/.test(metin)) return false;
  if (/^#[0-9a-fA-F]{3,8}$/.test(metin)) return false;
  if (/^\d+(\.\d+)?(px|rem|em|%)$/.test(metin)) return false;
  if (/^(from|to|via)-[a-z]/.test(metin)) return false;
  if (/^\d+(?:px)? \d+(?:px)? \d+(?:px)?/.test(metin)) return false; // box-shadow
  if (/^radial-gradient/.test(metin)) return false;
  if (/^linear-gradient/.test(metin)) return false;
  if (/^\(prefers-/.test(metin)) return false;
  if (tailwindZincirMi(metin)) return false;
  if (tekKelimeCssMi(metin)) return false;
  if (jsxIfadeParcasiMi(metin)) return false;
  if (/^aria-/.test(metin)) return false;
  if (/^@?\//.test(metin)) return false;
  if (/\.(tsx|ts|dart|json|css|svg|png|jpg)$/.test(metin)) return false;
  if (/^"use (client|server)"/.test(metin)) return false;

  // React/JSX prop ve import kalıpları
  if (/^\.[\/]/.test(metin)) return false;
  if (/^next\//.test(metin)) return false;
  if (/^(button|submit|reset|text|hidden|password|email|number|tel|url|search|date|time|checkbox|radio|file|image|color|range|month|week)$/i.test(metin)) return false;
  if (/^(isletme|slug|ocode|email|password|phone|name|search|query|q)$/i.test(metin)) return false;
  if (/^null,$/m.test(metin)) return false;
  if (/^\(metin\)$/.test(metin)) return false;

  // JavaScript kod kalıpları (çok satırlı literal artıkları)
  if (/^\);/.test(metin)) return false;
  if (/^if \(!/.test(metin)) return false;
  if (/^return \(/.test(metin)) return false;
  if (/^null,/.test(metin)) return false;

  // JSX içerik taraması `>=` ile generic `<T>` arasındaki JS kodunu
  // tek parça yakalayabiliyor (2026-09-03: "= ASISTAN_ADIMLARI.length;
  // const aktif = ... useRef" kırığı). Türkçe kullanıcı metninde `=`
  // ve `?.` asla geçmez; `const/let/return/useRef/...` de geçmez —
  // geçen her aday koddur. (`;` tek başına elenemez: "Konum izni
  // alınamadı; ..." gerçek bir kullanıcı metnidir.)
  if (metin.includes("=")) return false;
  if (metin.includes("//")) return false;
  if (metin.includes("?.")) return false;
  if (
    /\b(const|let|var|return|import|typeof|useRef|useState|useEffect|null|undefined)\b/.test(
      metin
    )
  )
    return false;

  return true;
}

/**
 * JSX içerik metinlerini çıkarır: `<h1>Metin</h1>`, `<p>Metin</p>` vb.
 */
function jsxIcerikMetinleri(kaynak: string): string[] {
  const metinler: string[] = [];

  for (const eslesme of kaynak.matchAll(/>([^<>{]+)</g)) {
    const ham = eslesme[1].replace(/\s+/g, " ").trim();
    if (kullaniciyaGorunurMu(ham)) {
      metinler.push(ham);
    }
  }

  return metinler;
}

/**
 * Web landing'inde kullanıcıya GÖRÜNEN metinler.
 *
 * İki tamamlayıcı yaklaşımla çıkarım yapılır:
 * 1. String literal taraması (Flutter extractor deseni)
 * 2. JSX içerik taraması — HTML tag'ları arası metin
 */
export function webLandingMetinleri(): Set<string> {
  const kaynaklar = dizindekiDosyalar(
    "public_web/src/components/landing",
    [".tsx"]
  ).map(yorumsuz);

  const metinler = new Set<string>();

  for (const kaynak of kaynaklar) {
    for (const satir of kaynak.split(SATIR_SONU)) {
      for (const literal of satirdakiLiteraller(satir)) {
        if (kullaniciyaGorunurMu(literal)) metinler.add(literal);
      }
    }
    for (const metin of jsxIcerikMetinleri(kaynak)) {
      metinler.add(metin);
    }
  }

  return metinler;
}

/**
 * Flutter landing'inde kullanıcıya GÖRÜNEN metinler — testin andra kaynağı.
 */
export function flutterLandingMetinleriFromWeb(): Set<string> {
  const kaynaklar = [
    readFileSync(resolve(DEPO_KOKU, "lib/screens/landing_screen.dart"), "utf-8"),
    ...dizindekiDosyalar("lib/widgets/landing", [".dart"]),
    readFileSync(resolve(DEPO_KOKU, "lib/widgets/chatbot_badge.dart"), "utf-8"),
  ].map(yorumsuz);

  const KACIS_SATIR_SONU = String.fromCharCode(92) + "n";

  const metinler = new Set<string>();
  for (const kaynak of kaynaklar) {
    for (const satir of kaynak.split(SATIR_SONU)) {
      for (const literal of satirdakiLiteraller(satir)) {
        for (const metin of literal.split(KACIS_SATIR_SONU)) {
          if (kullaniciyaGorunurMu(metin.trim())) metinler.add(metin.trim());
        }
      }
    }
  }
  return metinler;
}

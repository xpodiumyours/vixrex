import { resolveVixrexIntentMatches } from "./vixrexIntentResolver";
import { VIXREX_NIYET_SOZLUGU, type VixrexNiyetAlan } from "./vixrexNiyetSozlugu";
import { vixrexNormalizeDartParity } from "./vixrexNormalizer";
import { seciliKimlikTelefonKestirmesiniCikar } from "./ownerSelectedInput";

// Dart VixrexValueExtractor ile aynı kural – parity için birebir.
function extractQuoted(input: string): string | null {
  const patterns = [/'([^']{2,})'/, /"([^"]{2,})"/, /‘([^’]{2,})’/, /“([^”]{2,})”/, /`([^`]{2,})`/];
  for (const p of patterns) {
    const m = input.match(p);
    if (m) return m[1];
  }
  return null;
}
function stripQuotes(s: string): string {
  let t = s.trim();
  if (
    (t.startsWith("'") && t.endsWith("'")) ||
    (t.startsWith('"') && t.endsWith('"')) ||
    (t.startsWith("‘") && t.endsWith("’")) ||
    (t.startsWith("“") && t.endsWith("”")) ||
    (t.startsWith("`") && t.endsWith("`"))
  ) {
    t = t.slice(1, -1).trim();
  }
  return t;
}
function extractPhone(input: string): string | null {
  const quoted = extractQuoted(input);
  if (quoted) {
    const digits = quoted.replace(/[^0-9]/g, "");
    if (digits.length >= 10 && digits.length <= 13) return quoted.trim();
  }
  const m = input.match(/(\+?90\s?)?0?\s?5\d{2}\s?\d{3}\s?\d{2}\s?\d{2}/);
  if (m) return m[0].trim();
  const mLand = input.match(/0?\d{3}\s?\d{3}\s?\d{2}\s?\d{2}/);
  if (mLand) {
    const d = mLand[0].replace(/[^0-9]/g, "");
    if (d.length >= 10 && d.length <= 11) return mLand[0].trim();
  }
  return null;
}

function isFieldOnlyWithoutValue(input: string, alan: VixrexNiyetAlan): boolean {
  const norm = vixrexNormalizeDartParity(input);
  let hasField = false;
  for (const ea of alan.esAnlamlar) {
    if (norm.includes(vixrexNormalizeDartParity(ea))) { hasField = true; break; }
  }
  if (!hasField) return false;
  const verbPattern = /\b(yap|olsun|degistir|değiştir|ekle|guncelle|güncelle|ayarla|yaz|yanlis|yanlış|hatali|hatalı|bozuk|degistirmek)\b/i;
  let rem = norm;
  for (const ea of alan.esAnlamlar) rem = rem.replaceAll(vixrexNormalizeDartParity(ea), "");
  rem = rem.replace(verbPattern, "").replace(/[^a-z0-9]+/g, "").trim();
  return rem.length < 3;
}

// Eş-anlam sözlüğü yalnız 3. tekil iyelik hâlini tutuyor ("işletme adı"),
// ama esnaf doğal olarak 1. tekil de yazar ("işletme adım"). Eşleşme "adı"
// ile bitince hemen ardından gelen "m" değere yapışıp kalıyordu ("m Konak
// Kafe" gibi). Eşleşmeden hemen sonra boşluksuz devam eden harfler varsa
// (iyelik ekinin geri kalanı) onları da atlanacak kısma dahil ederiz.
function esAnlamEslesmeSonu(input: string, m: RegExpMatchArray): number {
  let end = (m.index ?? 0) + m[0].length;
  const devam = input.slice(end).match(/^[a-zA-ZçğıöşüÇĞİÖŞÜ]+/);
  if (devam) end += devam[0].length;
  return end;
}

function extractBetweenFieldAndVerb(input: string, alan: VixrexNiyetAlan): string | null {
  const normInput = vixrexNormalizeDartParity(input);
  let bestEa: string | null = null;
  let bestLen = -1;
  for (const ea of alan.esAnlamlar) {
    const n = vixrexNormalizeDartParity(ea);
    const idx = normInput.indexOf(n);
    if (idx !== -1 && n.length > bestLen) { bestEa = ea; bestLen = n.length; }
  }
  if (!bestEa) return null;
  const m = input.match(new RegExp(bestEa.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"), "i"));
  if (!m || m.index === undefined) return null;
  let after = input.slice(esAnlamEslesmeSonu(input, m)).trim();
  after = after.replace(/^[\s:=\-–—,]+/, "").trim();
  after = after.replace(/^(nı|ni|nu|nü|mı|mi|mu|mü|yı|yi|yu|yü|sı|si|su|sü|sını|sini|sunı|adını|adimi|numaramı|numarami|imi|ımı|umu|ümü|yi|yı|u|ü|ı|i)(?=\s|$|[.,;:!?])\s*/i, "").trim();
  if (!after) return null;
  const vm = after.match(/\b(yap|olsun|degistir|değiştir|ekle|guncelle|güncelle|ayarla|yaz)\b/i);
  let cand = vm ? after.slice(0, vm.index).trim() : after;
  cand = cand.replace(/^[\s:=\-–—,]+/, "").trim().replace(/[\s.,;]+$/, "").trim();
  if (cand.length < 2) return null;
  const nc = vixrexNormalizeDartParity(cand).replace(/[^a-z0-9]+/g, "");
  if (nc.length < 3) return null;
  if (/^(yanlis|hatali|bozuk|degistir)$/.test(nc)) return null;
  return stripQuotes(cand);
}

function extractAfterColon(input: string, alan?: VixrexNiyetAlan): string | null {
  if (!alan) return null;
  const normInput = vixrexNormalizeDartParity(input);
  let bestEa: string | null = null;
  let bestLen = -1;
  let bestIdx = -1;
  for (const ea of alan.esAnlamlar) {
    const n = vixrexNormalizeDartParity(ea);
    const idx = normInput.indexOf(n);
    if (idx !== -1 && n.length > bestLen) { bestEa = ea; bestLen = n.length; bestIdx = idx; }
  }
  if (!bestEa || bestIdx === -1) return null;
  let fieldEnd = bestIdx + bestLen;
  if (fieldEnd > input.length) fieldEnd = input.length;
  let afterField = input.slice(fieldEnd).trimStart();
  if (!afterField.startsWith(":") && !afterField.startsWith("=")) {
    const altEnd = Math.max(0, fieldEnd - 2);
    const alt = input.slice(altEnd).trimStart();
    if (alt.startsWith(":") || alt.startsWith("=")) afterField = alt;
    else {
      const alt2 = fieldEnd + 2 <= input.length ? input.slice(fieldEnd + 2).trimStart() : "";
      if (alt2.startsWith(":") || alt2.startsWith("=")) afterField = alt2;
      else return null;
    }
  }
  if (!afterField.startsWith(":") && !afterField.startsWith("=")) return null;
  const sep = afterField[0];
  const after = afterField.slice(1).trim();
  if (!after) return null;
  if (sep === ":" && after.startsWith("//")) return null;
  const q = extractQuoted(after);
  if (q && q.trim()) return q.trim();
  const cleaned = stripFieldMention(after, alan);
  if (cleaned) return cleaned;
  return after;
}
function extractBeforeVerb(input: string): string | null {
  const m = input.trim().match(/^(.*)\b(yap|olsun|degistir|değiştir|ekle|guncelle|güncelle|ayarla|yaz)\b\s*[.!]?\s*$/i);
  if (m && m[1] && m[1].trim()) return m[1].trim();
  return null;
}
function stripTrailingVerb(s: string): string {
  return s.replace(/\b(yap|olsun|degistir|değiştir|ekle|guncelle|güncelle|ayarla|yaz)\b\s*[.!]?\s*$/i, "").trim();
}
function isFreeTextTip(tip: string): boolean {
  return ["metin", "uzunMetin", "telefon", "url", "gorsel", "eposta"].includes(tip);
}
function stripFieldMention(candidate: string, alan: VixrexNiyetAlan): string {
  let out = candidate;
  const sorted = [...alan.esAnlamlar].sort((a, b) => b.length - a.length);
  for (const ea of sorted) {
    out = out.replace(new RegExp(ea.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"), "gi"), "");
  }
  out = out
    .replace(/^\s*(adını|adimi|adı|adi|numaramı|numarami|numarası|numarasi|ismi|imi|ımı|umu|ümü|si|sı|su|sü|yi|yı|yu|yü|nı|ni|nu|nü|mı|mi|mu|mü)(?=\s|$|[.,;:!?])\s*/i, "")
    .replace(/\s*(adını|adimi|adı|adi)\s*$/i, "")
    .trim()
    .replace(/^[\s:=\-–—,]+/, "")
    .trim()
    .replace(/[\s.,;]+$/, "")
    .trim()
    .replace(new RegExp(alan.etiket.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"), "gi"), "")
    .trim();
  if (vixrexNormalizeDartParity(out) === vixrexNormalizeDartParity(alan.etiket)) return "";
  if (out.trim().length < 2) return out.trim().length === 0 ? "" : out.trim();
  return out.trim();
}
function remainderAfterFieldMention(input: string, alan: VixrexNiyetAlan): string | null {
  let matchedEa: string | null = null;
  let matchLen = -1;
  for (const ea of alan.esAnlamlar) {
    const normEa = vixrexNormalizeDartParity(ea);
    if (vixrexNormalizeDartParity(input).includes(normEa) && normEa.length > matchLen) {
      matchedEa = ea;
      matchLen = normEa.length;
    }
  }
  if (!matchedEa) return null;
  const m = input.match(new RegExp(matchedEa.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"), "i"));
  if (!m || m.index === undefined) return null;
  const after = input.slice(esAnlamEslesmeSonu(input, m)).trim();
  if (!after) return null;
  const cleaned = after
    .replace(/^[\s:=\-–—,]+/, "")
    .replace(/^(nı|ni|nu|nü|mı|mi|mu|mü|yı|yi|yu|yü|sı|si|su|sü|sını|sini|sunı|adını|adimi)(?=\s|$|[.,;:!?])\s*/i, "")
    .trim();
  if (cleaned.length < 2) return null;
  return stripQuotes(cleaned);
}

// 2026-09-03 (Casper canlıda buldu, kiralık-kafe vitrini): serbest metin
// alanları (işletme adı, adres gibi) bir cümlede BAŞKA bir alana ait
// bilgiyle karışabiliyordu — "işletme adım Konak Kafe, whatsapp numaram
// 0542..." yazınca isim alanına whatsapp numarası da yapışıyordu. Motor
// whatsapp'ı AYRI ve doğru buluyordu (extractPhone kendi regex'iyle), ama
// isim adayının nerede BİTMESİ gerektiğini hiç bilmiyordu — "alanın
// eş-anlamından sonra cümlenin sonuna kadar her şeyi al" mantığı buydu.
//
// Bilinçli bir "kimlik tahmin edilmez" kuralı DEĞİL bu — gözden kaçmış bir
// sınır eksikliğiydi (bkz. serbestMetinCikarim.ts'teki gerçek kasıtlı kural,
// o ayrı bir dosya/amaç). Çözüm: yalnızca SERBEST METİN tipi alanlarda
// (isim, adres, kısa tanıtım vb. — tip="metin"/"uzunMetin"), adayın içinde
// (a) bir telefon kalıbı ya da (b) bir virgül/"ve" sonrasında BAŞKA bir
// alana ait tanınan bir kelime varsa, aday oraya kadar kesilir.
//
// Virgül/"ve" şartı BİLEREK var: "il" gibi kısa/genel eş-anlamların normal
// bir cümle ortasında (virgülsüz) yanlışlıkla sınır sayılmasını önler —
// gerçek "kitchen sink" cümleler zaten virgülle listeler (bkz.
// serbest-alan-sinirlama.test.ts).
const TELEFON_SINIR_REGEX =
  /(\+?90[\s.-]?)?0?[\s.-]?5\d{2}[\s.-]?\d{3}[\s.-]?\d{2}[\s.-]?\d{2}/;

function digerAlanlarinEsAnlamlari(kendiAnahtar: string): string[] {
  const out: string[] = [];
  for (const a of VIXREX_NIYET_SOZLUGU) {
    if (a.anahtar === kendiAnahtar) continue;
    for (const ea of a.esAnlamlar) {
      // Çok kısa (≤3 harf) eş-anlamlar ("il", "tel", "ig" gibi) sınır
      // aramasında kullanılmaz — normal bir cümlede tesadüfen geçme
      // ihtimalleri çok yüksek, yanlış pozitif riski gerçek faydadan büyük.
      if (vixrexNormalizeDartParity(ea).replace(/[^a-z0-9]/g, "").length > 3) out.push(ea);
    }
  }
  return out;
}

/**
 * Bir cümlede, verilen alanın DIŞINDA tanınan başka bir alana ait güvenli
 * (kısa/genel olmayan, kelime sınırlı) bir ipucu var mı?
 *
 * `resolveVixrexIntentsAll` bunun için KULLANILMAZ — o saf substring
 * eşleştirir (word-boundary yok, uzunluk filtresi yok), "ailece" gibi
 * gündelik bir kelime içinde "il" geçtiği için "il" alanını yanlışlıkla
 * eşleştirebilir. Bu fonksiyon `serbestMetinAdayiniSinirla` ile AYNI
 * güvenli listeyi (kısa eş-anlamlar hariç) ve kelime sınırını kullanır —
 * seçili bir kutunun ham metni olduğu gibi mi kaydedileceğine (yoksa
 * dürüstçe mi sorulacağına) karar vermek için kullanılır (bkz.
 * useOwnerActions.ts → temizlenmisSeciliDeger).
 */
export function digerAlanaAitIpucuVarMi(metin: string, kendiAnahtar: string): boolean {
  const normMetin = " " + vixrexNormalizeDartParity(metin) + " ";
  return digerAlanlarinEsAnlamlari(kendiAnahtar).some((ea) => {
    const n = vixrexNormalizeDartParity(ea).replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    return new RegExp(`[^a-z0-9]${n}[^a-z0-9]`).test(normMetin);
  });
}

function serbestMetinAdayiniSinirla(aday: string, alan: VixrexNiyetAlan): string {
  if (!isFreeTextTip(alan.tip) || alan.tip === "telefon" || alan.tip === "url" || alan.tip === "eposta") {
    return aday;
  }

  let sinir = aday.length;

  const tel = aday.match(TELEFON_SINIR_REGEX);
  if (tel && tel.index !== undefined && tel.index > 0) sinir = Math.min(sinir, tel.index);

  const digerEsAnlamlar = digerAlanlarinEsAnlamlari(alan.anahtar);
  const ayracRegex = /[,;]|\bve\b/gi;
  let m: RegExpExecArray | null;
  while ((m = ayracRegex.exec(aday)) !== null) {
    if (m.index >= sinir) break;
    const kuyruk = " " + vixrexNormalizeDartParity(aday.slice(m.index + m[0].length));
    const eslesti = digerEsAnlamlar.some((ea) => {
      const n = vixrexNormalizeDartParity(ea).replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
      return new RegExp(`[^a-z0-9]${n}([^a-z0-9]|$)`).test(kuyruk);
    });
    if (eslesti) sinir = Math.min(sinir, m.index);
  }

  if (sinir >= aday.length) return aday;
  const kesilmis = aday.slice(0, sinir).trim().replace(/[\s.,;]+$/, "").trim();
  return kesilmis.length >= 2 ? kesilmis : aday;
}

/**
 * Ham metindeki kelimeleri KONUMLARIYLA döner.
 *
 * NEDEN: Değer çıkarıcı alan adını ham metinde `RegExp(..., "i")` ile arıyordu.
 * Bu Türkçede güvenilir DEĞİL — JavaScript'in `i` bayrağı "İ"yi "i"ye, "ı"yı
 * "i"ye katlamaz. Bu yüzden "İşletme adını Ada Kahve yap" cümlesinde
 * "işletme adı" kalıbı HİÇ eşleşmiyordu, ek temizleme kuralları çalışmıyordu
 * ve vitrine "nı Ada Kahve" yazılıyordu. Matcher aynı işi normalize edilmiş
 * token'larla doğru yapıyor; burada onun bulduğu aralığı kullanıyoruz.
 */
function konumluKelimeler(input: string): Array<{ start: number; end: number }> {
  const out: Array<{ start: number; end: number }> = [];
  const re = /[\p{L}\p{N}]+/gu;
  let m: RegExpExecArray | null;
  while ((m = re.exec(input)) !== null) {
    out.push({ start: m.index, end: m.index + m[0].length });
  }
  return out;
}

const DEGER_SONU_FIILLERI =
  /(\s|^)(olarak\s+)?(yap|olsun|değiştir|degistir|ekle|güncelle|guncelle|ayarla|yaz)\s*$/iu;

/** Matcher'ın bulduğu alan-adı aralığından SONRAKİ metni değer adayı sayar. */
function alanAraligindanSonrakiDeger(
  input: string,
  alan: VixrexNiyetAlan,
): string | null {
  const eslesme = resolveVixrexIntentMatches(input).find(
    (e) => e.alan.anahtar === alan.anahtar,
  );
  if (!eslesme) return null;

  const son = konumluKelimeler(input)[eslesme.endToken];
  if (!son) return null;

  let aday = input.slice(son.end).trim();
  aday = aday.replace(/^[\s:=\-–—,;]+/, "").trim();
  aday = aday.replace(DEGER_SONU_FIILLERI, "").trim();
  aday = aday.replace(/[\s.,;]+$/, "").trim();

  // Kalıntı anlamsızsa değer sayma; eski yollar denemeye devam etsin.
  return aday.length >= 2 ? aday : null;
}

export function extractVixrexValue(input: string, alan: VixrexNiyetAlan): string | null {
  const sonuc = extractVixrexValueHam(input, alan);
  return sonuc === null ? null : serbestMetinAdayiniSinirla(sonuc, alan);
}

function extractVixrexValueHam(input: string, alan: VixrexNiyetAlan): string | null {
  const raw = input.trim();
  if (!raw) return null;

  // Seçili "İşletme Adı" alanına etiketsiz biçimde "Çarşı teknik servis
  // 0542..." yazıldığında alan bağlamı, genel serbest-metin tahmininden daha
  // güçlüdür. Telefon sondaysa helper ana metni güvenle ayırır. Açıkça
  // "işletme adım / whatsapp numaram" yazılan klasik zengin cümlelerde
  // helper null döner ve aşağıdaki mevcut ayrıştırma aynen devam eder.
  if (alan.anahtar === "isletmeAdi") {
    const kestirme = seciliKimlikTelefonKestirmesiniCikar(raw);
    if (kestirme) return kestirme.anaDeger;
  }

  if (alan.tip === "telefon") {
    const p = extractPhone(raw);
    if (p) return p;
  }
  if (isFieldOnlyWithoutValue(raw, alan)) return null;

  // Tırnaklı/iki nokta gibi AÇIK biçimler önceliğini korur; onlar yoksa
  // matcher'ın bulduğu alan aralığından sonrası en güvenilir adaydır.
  if (!/["'“”‘’`:=]/.test(raw)) {
    const aralikDegeri = alanAraligindanSonrakiDeger(raw, alan);
    if (aralikDegeri) return aralikDegeri;
  }

  const quoted = extractQuoted(raw);
  if (quoted && quoted.trim()) {
    const cleaned = stripFieldMention(quoted.trim(), alan);
    if (cleaned) return cleaned;
    if (quoted.trim()) return quoted.trim();
  }
  const colon = extractAfterColon(raw, alan);
  if (colon && colon.trim()) {
    const cleaned = stripFieldMention(colon.trim(), alan);
    const cand = cleaned || colon.trim();
    const noVerb = stripTrailingVerb(cand);
    if (noVerb.trim()) return noVerb.trim();
    if (cand.trim()) return cand.trim();
  }
  const between = extractBetweenFieldAndVerb(raw, alan);
  if (between && between.trim()) {
    const noVerb = stripTrailingVerb(between.trim());
    return noVerb.trim() || between.trim();
  }
  const beforeVerb = extractBeforeVerb(raw);
  if (beforeVerb && beforeVerb.trim()) {
    const cand = stripFieldMention(beforeVerb.trim(), alan);
    if (cand.trim()) {
      const noVerb = stripTrailingVerb(cand.trim());
      if (noVerb) return noVerb;
      return cand.trim();
    }
  }
  if (isFreeTextTip(alan.tip)) {
    const rem = remainderAfterFieldMention(raw, alan);
    if (rem && rem.trim().length >= 2) {
      const noVerb = stripTrailingVerb(rem.trim());
      const wq = stripQuotes((noVerb || rem).trim());
      if (wq.length >= 2) return wq;
    }
  }
  return null;
}

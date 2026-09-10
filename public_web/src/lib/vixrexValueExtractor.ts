import { VIXREX_NIYET_SOZLUGU, type VixrexNiyetAlan } from "./vixrexNiyetSozlugu";
import { vixrexNormalizeDartParity } from "./vixrexNormalizer";
import { seciliKimlikTelefonKestirmesiniCikar } from "./ownerSelectedInput";

const KOMUT_FIILI = "yap|olsun|degistir|değiştir|ekle|guncelle|güncelle|ayarla|yaz|sec|seç";
const TR_KELIME_KARAKTERI = "a-zA-ZçğıöşüÇĞİÖŞÜ0-9";
const KOMUT_FIILI_ONCESI = `(?<![${TR_KELIME_KARAKTERI}])`;
const KOMUT_FIILI_SONRASI = `(?![${TR_KELIME_KARAKTERI}])`;
const ARA_ISIM_EKLERI = [
  "m", "im", "um", "in", "un", "min", "mun", "imin", "umun", "nin", "nun",
  "imiz", "umuz", "iniz", "unuz", "imizin", "umuzun", "inizin", "unuzun", "larin", "lerin",
] as const;

function escapeRegExp(s: string): string {
  return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

/** Yalnız alan/komut metninde Türkçe karakter ↔ ASCII toleransı. Slot değeri normalize edilmez. */
function esnekHarfPattern(ch: string): string {
  switch (ch) {
    case "c": return "[cç]";
    case "g": return "[gğ]";
    case "u": return "[uü]";
    case "s": return "[sş]";
    case "o": return "[oö]";
    case "i": return "[iıİI]";
    default: return escapeRegExp(ch);
  }
}

function esnekKelimePattern(text: string): string {
  return [...vixrexNormalizeDartParity(text)].map(esnekHarfPattern).join("");
}

const ARA_ISIM_EKI_PATTERN = `(?:${ARA_ISIM_EKLERI.map(esnekKelimePattern).join("|")})?`;

function esnekAlanPattern(ifade: string): string {
  const tokens = vixrexNormalizeDartParity(ifade).trim().split(/\s+/).filter(Boolean);
  return tokens.map((token, i) => {
    const kok = esnekKelimePattern(token);
    if (i < tokens.length - 1 && /^[a-z0-9]+$/.test(token) && token.length >= 4) {
      return `${kok}${ARA_ISIM_EKI_PATTERN}`;
    }
    return kok;
  }).join("\\s+");
}

function literalPattern(text: string): string {
  let out = "";
  let bosluk = false;
  for (const ch of text.trim()) {
    if (/\s/u.test(ch)) {
      if (!bosluk) out += "\\s+";
      bosluk = true;
      continue;
    }
    bosluk = false;
    if (ch === "'" || ch === "’") out += "['’]?";
    else out += escapeRegExp(ch);
  }
  return out;
}

/**
 * `{deger}` örnekleri intent yanında slot sözleşmesidir. Kalıp içindeki
 * boşluk bilerek korunur: "Adresi {deger}" ifadesi "Adresimi ..." başına
 * kısmi eşleşemez.
 */
function extractFromExamples(input: string, alan: VixrexNiyetAlan): string | null {
  for (const ornek of alan.ornekIfadeler) {
    const marker = ornek.indexOf("{deger}");
    if (marker < 0) continue;
    const once = ornek.slice(0, marker);
    const sonra = ornek.slice(marker + "{deger}".length);
    const onceAyiraci = /\s$/.test(once) ? "\\s+" : "\\s*";
    const sonraAyiraci = /^\s/.test(sonra) ? "\\s+" : "\\s*";
    const re = new RegExp(
      `^\\s*${literalPattern(once)}${onceAyiraci}(.+?)${sonraAyiraci}${literalPattern(sonra)}\\s*[.!]?\\s*$`,
      "iu",
    );
    const m = input.match(re);
    if (!m?.[1]) continue;
    const deger = stripQuotes(m[1].trim());
    if (deger.length >= 1) return deger;
  }
  return null;
}

function extractQuoted(input: string): string | null {
  const patterns = [
    /"([^"]{2,})"/,
    /‘([^’]{2,})’/,
    /“([^”]{2,})”/,
    /`([^`]{2,})`/,
    /'(.{2,})'/,
  ];
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
  ) t = t.slice(1, -1).trim();
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
  const verbPattern = new RegExp(`\\b(${KOMUT_FIILI}|yanlis|yanlış|hatali|hatalı|bozuk|degistirmek)\\b`, "i");
  let rem = norm;
  for (const ea of alan.esAnlamlar) rem = rem.replaceAll(vixrexNormalizeDartParity(ea), "");
  rem = rem.replace(verbPattern, "").replace(/[^a-z0-9]+/g, "").trim();
  return rem.length < 3;
}

function esAnlamEslesmeSonu(input: string, m: RegExpMatchArray): number {
  let end = (m.index ?? 0) + m[0].length;
  const devam = input.slice(end).match(/^[a-zA-ZçğıöşüÇĞİÖŞÜ]+/);
  if (devam) end += devam[0].length;
  return end;
}

function bestFieldMatch(input: string, alan: VixrexNiyetAlan): RegExpMatchArray | null {
  let best: RegExpMatchArray | null = null;
  let bestLen = -1;
  for (const ea of alan.esAnlamlar) {
    const n = vixrexNormalizeDartParity(ea);
    const m = input.match(new RegExp(esnekAlanPattern(ea), "iu"));
    if (m && n.length > bestLen) {
      best = m;
      bestLen = n.length;
    }
  }
  return best;
}

/** Fiil yalnız TAM sözcükse komuttur; "Yaptığımız" içindeki "Yap" komut değildir. */
function extractAfterLeadingVerb(input: string, alan: VixrexNiyetAlan): string | null {
  const m = bestFieldMatch(input, alan);
  if (!m || m.index === undefined) return null;
  let after = input.slice(esAnlamEslesmeSonu(input, m)).trim();
  after = after.replace(/^[\s:=\-–—,]+/, "").trim();
  const re = new RegExp(`^(?:${KOMUT_FIILI})${KOMUT_FIILI_SONRASI}(?:\\s+(?:olarak|diye|şöyle|soyle))?\\s*[:=,\-–—]?\\s*(.+)$`, "i");
  const vm = after.match(re);
  if (!vm?.[1]) return null;
  const cand = stripQuotes(vm[1].trim().replace(/[\s.,;]+$/, "").trim());
  return cand.length >= 1 ? cand : null;
}

function extractBetweenFieldAndVerb(input: string, alan: VixrexNiyetAlan): string | null {
  const m = bestFieldMatch(input, alan);
  if (!m || m.index === undefined) return null;
  let after = input.slice(esAnlamEslesmeSonu(input, m)).trim();
  after = after.replace(/^[\s:=\-–—,]+/, "").trim();
  if (!after) return null;
  const vm = after.match(new RegExp(`${KOMUT_FIILI_ONCESI}(${KOMUT_FIILI})${KOMUT_FIILI_SONRASI}`, "i"));
  let cand = vm ? after.slice(0, vm.index).trim() : after;
  cand = cand
    .replace(/\s+(?:olarak|diye)$/i, "")
    .replace(/^[\s:=\-–—,]+/, "")
    .trim()
    .replace(/[\s.,;]+$/, "")
    .trim();
  if (cand.length < 2) return null;
  const nc = vixrexNormalizeDartParity(cand).replace(/[^a-z0-9]+/g, "");
  if (nc.length < 3) return null;
  if (/^(yanlis|hatali|bozuk|degistir)$/.test(nc)) return null;
  return stripQuotes(cand);
}

function extractAfterColon(input: string, alan?: VixrexNiyetAlan): string | null {
  if (!alan) return null;
  const m = bestFieldMatch(input, alan);
  if (!m || m.index === undefined) return null;
  const afterField = input.slice(esAnlamEslesmeSonu(input, m)).trimStart();
  if (!afterField.startsWith(":") && !afterField.startsWith("=")) return null;
  const sep = afterField[0];
  const after = afterField.slice(1).trim();
  if (!after) return null;
  if (sep === ":" && after.startsWith("//")) return null;
  const q = extractQuoted(after);
  if (q && q.trim()) return q.trim();
  const cleaned = stripFieldMention(after, alan);
  return cleaned || after;
}

function extractBeforeVerb(input: string): string | null {
  const m = input.trim().match(
    new RegExp(`^(.*)${KOMUT_FIILI_ONCESI}(${KOMUT_FIILI})${KOMUT_FIILI_SONRASI}\\s*[.!]?\\s*$`, "i"),
  );
  return m?.[1]?.trim() || null;
}

function stripTrailingVerb(s: string): string {
  return s
    .replace(new RegExp(`${KOMUT_FIILI_ONCESI}(${KOMUT_FIILI})${KOMUT_FIILI_SONRASI}\\s*[.!]?\\s*$`, "i"), "")
    .trim();
}

function isFreeTextTip(tip: string): boolean {
  return ["metin", "uzunMetin", "telefon", "url", "gorsel", "eposta"].includes(tip);
}

function stripFieldMention(candidate: string, alan: VixrexNiyetAlan): string {
  let out = candidate;
  const sorted = [...alan.esAnlamlar].sort((a, b) => b.length - a.length);
  let degisti = true;
  while (degisti) {
    degisti = false;
    for (const ea of sorted) {
      const yeni = out.replace(new RegExp(`^\\s*${esnekAlanPattern(ea)}`, "iu"), "");
      if (yeni !== out) {
        out = yeni;
        degisti = true;
      }
    }
  }
  out = out
    .replace(/^\s*(adını|adimi|adı|adi|numaramı|numarami|numarası|numarasi|ismi|imi|ımı|umu|ümü|si|sı|su|sü|yi|yı|yu|yü|nı|ni|nu|nü|mı|mi|mu|mü)\b\s*/i, "")
    .replace(/\s*(adını|adimi|adı|adi)\s*$/i, "")
    .trim()
    .replace(/^[\s:=\-–—,]+/, "")
    .trim()
    .replace(/[\s.,;]+$/, "")
    .trim()
    .replace(new RegExp(`^\\s*${escapeRegExp(alan.etiket)}\\s*`, "i"), "")
    .trim();
  if (vixrexNormalizeDartParity(out) === vixrexNormalizeDartParity(alan.etiket)) return "";
  if (out.trim().length < 2) return out.trim().length === 0 ? "" : out.trim();
  return out.trim();
}

function remainderAfterFieldMention(input: string, alan: VixrexNiyetAlan): string | null {
  const m = bestFieldMatch(input, alan);
  if (!m || m.index === undefined) return null;
  const after = input.slice(esAnlamEslesmeSonu(input, m)).trim();
  if (!after) return null;
  const cleaned = after.replace(/^[\s:=\-–—,]+/, "").trim();
  if (cleaned.length < 2) return null;
  return stripQuotes(cleaned);
}

const TELEFON_SINIR_REGEX =
  /(\+?90[\s.-]?)?0?[\s.-]?5\d{2}[\s.-]?\d{3}[\s.-]?\d{2}[\s.-]?\d{2}/;

function digerAlanlarinEsAnlamlari(kendiAnahtar: string): string[] {
  const out: string[] = [];
  for (const a of VIXREX_NIYET_SOZLUGU) {
    if (a.anahtar === kendiAnahtar) continue;
    for (const ea of a.esAnlamlar) {
      if (vixrexNormalizeDartParity(ea).replace(/[^a-z0-9]/g, "").length > 3) out.push(ea);
    }
  }
  return out;
}

export function digerAlanaAitIpucuVarMi(metin: string, kendiAnahtar: string): boolean {
  const normMetin = " " + vixrexNormalizeDartParity(metin) + " ";
  return digerAlanlarinEsAnlamlari(kendiAnahtar).some((ea) => {
    const n = escapeRegExp(vixrexNormalizeDartParity(ea));
    return new RegExp(`[^a-z0-9]${n}[^a-z0-9]`).test(normMetin);
  });
}

function serbestMetinAdayiniSinirla(aday: string, alan: VixrexNiyetAlan): string {
  if (!isFreeTextTip(alan.tip) || alan.tip === "telefon" || alan.tip === "url" || alan.tip === "eposta") return aday;

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
      const n = escapeRegExp(vixrexNormalizeDartParity(ea));
      return new RegExp(`[^a-z0-9]${n}([^a-z0-9]|$)`).test(kuyruk);
    });
    if (eslesti) sinir = Math.min(sinir, m.index);
  }

  if (sinir >= aday.length) return aday;
  const kesilmis = aday.slice(0, sinir).trim().replace(/[\s.,;]+$/, "").trim();
  return kesilmis.length >= 2 ? kesilmis : aday;
}

export function extractVixrexValue(input: string, alan: VixrexNiyetAlan): string | null {
  const sonuc = extractVixrexValueHam(input, alan);
  return sonuc === null ? null : serbestMetinAdayiniSinirla(sonuc, alan);
}

function extractVixrexValueHam(input: string, alan: VixrexNiyetAlan): string | null {
  const raw = input.trim();
  if (!raw) return null;

  const kalip = extractFromExamples(raw, alan);
  if (kalip !== null) return kalip;

  if (alan.anahtar === "isletmeAdi") {
    const kestirme = seciliKimlikTelefonKestirmesiniCikar(raw);
    if (kestirme) return kestirme.anaDeger;
  }

  if (alan.tip === "telefon") {
    const p = extractPhone(raw);
    if (p) return p;
  }
  if (isFieldOnlyWithoutValue(raw, alan)) return null;

  const quoted = extractQuoted(raw);
  if (quoted && quoted.trim()) {
    const cleaned = stripFieldMention(quoted.trim(), alan);
    if (cleaned) return cleaned;
    return quoted.trim();
  }

  const fiildenSonra = extractAfterLeadingVerb(raw, alan);
  if (fiildenSonra) return fiildenSonra;

  const colon = extractAfterColon(raw, alan);
  if (colon && colon.trim()) {
    const cleaned = stripFieldMention(colon.trim(), alan);
    const cand = cleaned || colon.trim();
    const noVerb = stripTrailingVerb(cand);
    return noVerb.trim() || cand.trim();
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
      const noVerb = stripTrailingVerb(cand.trim()).replace(/\s+(?:olarak|diye)$/i, "").trim();
      return noVerb || cand.trim();
    }
  }

  if (isFreeTextTip(alan.tip)) {
    const rem = remainderAfterFieldMention(raw, alan);
    if (rem && rem.trim().length >= 2) {
      const noVerb = stripTrailingVerb(rem.trim()).replace(/\s+(?:olarak|diye)$/i, "").trim();
      const wq = stripQuotes((noVerb || rem).trim());
      if (wq.length >= 2) return wq;
    }
  }
  return null;
}

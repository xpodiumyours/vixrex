import type { VixrexNiyetAlan } from "./vixrexNiyetSozlugu";
import { vixrexNormalizeDartParity } from "./vixrexNormalizer";

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
    if (/^0?5\d{9}$/.test(digits) || /^90\d{10}$/.test(digits)) return quoted.trim();
  }
  const m = input.match(/(\+?90\s?)?0?\s?5\d{2}\s?\d{3}\s?\d{2}\s?\d{2}/);
  if (m) return m[0].trim();
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
  let after = input.slice(m.index + m[0].length).trim();
  after = after.replace(/^[\s:=\-–—,]+/, "").trim();
  after = after.replace(/^(nı|ni|nu|nü|mı|mi|mu|mü|yı|yi|yu|yü|sı|si|su|sü|sını|sini|sunı|adını|adimi|numaramı|numarami|imi|ımı|umu|ümü|yi|yı)\b\s*/i, "").trim();
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
  const idxColon = input.indexOf(":");
  const idxEq = input.indexOf("=");
  let idx = -1;
  if (idxColon !== -1 && idxEq !== -1) idx = Math.min(idxColon, idxEq);
  else if (idxColon !== -1) idx = idxColon;
  else if (idxEq !== -1) idx = idxEq;
  else return null;
  const before = input.slice(0, idx).trim();
  const after = input.slice(idx + 1).trim();
  if (!after) return null;
  if (before.toLowerCase().endsWith("no") || before.toLowerCase().endsWith("no.")) {
    if (alan) {
      const nb = vixrexNormalizeDartParity(before);
      let hasField = false;
      for (const ea of alan.esAnlamlar) if (nb.includes(vixrexNormalizeDartParity(ea))) { hasField = true; break; }
      if (!hasField) return null;
      if (before.toLowerCase().trim().endsWith("no") || before.toLowerCase().trim().endsWith("no.")) return null;
    } else {
      // adres içindeki No: – ayraç değil
      if (/no\s*$/i.test(before)) return null;
    }
  }
  if (before.length > 40) {
    // Uzun beforeColon + No değilse, yine de alan adı var mı kontrol et
    if (alan) {
      const nb = vixrexNormalizeDartParity(before);
      let hasField = false;
      for (const ea of alan.esAnlamlar) if (nb.includes(vixrexNormalizeDartParity(ea))) { hasField = true; break; }
      if (!hasField) return null;
    }
  }
  const q = extractQuoted(after);
  if (q && q.trim()) return q.trim();
  if (alan) {
    const cleaned = stripFieldMention(after, alan);
    if (cleaned) return cleaned;
  }
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
    .replace(/^\s*(adını|adimi|adı|adi|numaramı|numarami|numarası|numarasi|ismi|imi|ımı|umu|ümü|si|sı|su|sü|yi|yı|yu|yü|nı|ni|nu|nü|mı|mi|mu|mü)\b\s*/i, "")
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
  const after = input.slice(m.index + m[0].length).trim();
  if (!after) return null;
  const cleaned = after
    .replace(/^[\s:=\-–—,]+/, "")
    .replace(/^(nı|ni|nu|nü|mı|mi|mu|mü|yı|yi|yu|yü|sı|si|su|sü|sını|sini|sunı|adını|adimi)\b\s*/i, "")
    .trim();
  if (cleaned.length < 2) return null;
  return stripQuotes(cleaned);
}

export function extractVixrexValue(input: string, alan: VixrexNiyetAlan): string | null {
  const raw = input.trim();
  if (!raw) return null;
  if (alan.tip === "telefon") {
    const p = extractPhone(raw);
    if (p) return p;
  }
  if (isFieldOnlyWithoutValue(raw, alan)) return null;
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

import type { AracCagrisi } from "@/lib/openrouterYanitAkisi";

export type KurtarilanKayit = Record<string, unknown>;

function nesneMi(deger: unknown): deger is KurtarilanKayit {
  return deger !== null && typeof deger === "object" && !Array.isArray(deger);
}

export function diziNesneleriniCikar(metin: string, anahtar: string): KurtarilanKayit[] {
  const bul = metin.indexOf(`"${anahtar}"`);
  if (bul < 0) return [];
  const baslangic = metin.indexOf("[", bul);
  if (baslangic < 0) return [];
  const sonuc: KurtarilanKayit[] = [];
  let derinlik = 0, metinIcinde = false, kacis = false, bas = -1;
  for (let i = baslangic + 1; i < metin.length; i++) {
    const karakter = metin[i];
    if (metinIcinde) {
      if (kacis) kacis = false;
      else if (karakter === "\\") kacis = true;
      else if (karakter === "\"") metinIcinde = false;
      continue;
    }
    if (karakter === "\"") { metinIcinde = true; continue; }
    if (karakter === "{") { if (derinlik === 0) bas = i; derinlik++; continue; }
    if (karakter === "}") {
      derinlik--;
      if (derinlik === 0 && bas >= 0) {
        try {
          const cozulen = JSON.parse(metin.slice(bas, i + 1));
          if (nesneMi(cozulen)) sonuc.push(cozulen);
        } catch { continue; }
        bas = -1;
      }
      continue;
    }
    if (karakter === "]" && derinlik === 0) break;
  }
  return sonuc;
}

export function aracCevabiniCoz(cagrilar: AracCagrisi[]): unknown {
  for (const cagri of cagrilar) {
    const metin = cagri?.function?.arguments;
    if (typeof metin !== "string" || !metin.trim()) continue;
    const adaylar = [metin.trim(), metin.trim().replace(/^```(?:json)?\s*/i, "").replace(/```$/, "").trim()];
    for (const aday of adaylar) {
      try {
        const cozulen = JSON.parse(aday);
        if (cozulen !== null && typeof cozulen === "object") return cozulen;
      } catch { continue; }
    }
  }
  return null;
}

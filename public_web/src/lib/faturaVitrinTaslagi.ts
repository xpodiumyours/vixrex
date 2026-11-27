import { ilIlceCikar, resolveIlce } from "@/lib/turkeyPlaceMatcher";
import { resolveBusinessCategory } from "@/lib/businessCategories";
import { sanitizePermissionText } from "@/lib/supplierPermissionRequest";

export const FATURA_VITRIN_TASLAGI_ANAHTARI = "vixrex_fatura_vitrin_taslagi_v1";

export interface FaturaVitrinHamGirdi {
  aliciUnvan?: string | null;
  aliciAdres?: string | null;
  urunKategorileri?: readonly (string | null | undefined)[] | null;
  markalar?: readonly (string | null | undefined)[] | null;
}

export interface FaturaVitrinTaslagi {
  name?: string;
  province_name?: string;
  district_name?: string;
  kategori?: string;
  ilkMarka?: string;
  kaynak: "fatura";
}

function guvenliFaturaMetniTemizle(deger: unknown, azamiUzunluk = 120): string {
  if (typeof deger !== "string") return "";
  const onceki = deger
    .replace(/[\r\n\t\u0000-\u001F\u007F-\u009F\u2028\u2029]+/g, " ")
    .replace(/\bTR\d{2}(?:\s?[0-9A-Z]{4}){5}\s?[0-9A-Z]{2}\b/gi, "")
    .replace(/\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b/gi, "")
    .replace(/\b[^\s@]+@[^\s@]+\.[^\s@]+\b/gi, "")
    .replace(/(?:\+?90|0)?[\s().-]*5\d{2}[\s().-]*\d{3}[\s().-]*\d{2}[\s().-]*\d{2}\b/g, "")
    .replace(/(?:\+?90|0)?[\s().-]*[2-4]\d{2}[\s().-]*\d{3}[\s().-]*\d{2}[\s().-]*\d{2}\b/g, "")
    .replace(/\b(?:fatura\s*(?:no|numaras[iıIİ])?|inv(?:oice)?\s*(?:no|#)?)[\s:#-]*[A-Z0-9-]{4,}\b/gi, "")
    .replace(/\b[A-Z]{2,4}20\d{2}\d{6,}\b/g, "")
    .replace(/(^|[\s,.;:(\[\-])%?\s*\d+(?:[.,]\d+)?\s*%?\s*(?:[oöOÖ]zel\s+|genel\s+|sat[iıIİ]r\s+)?[iİıI]skonto(?:\s+(?:oran[iıIİ]|tutar[iıIİ]))?(?=$|[\s,.;:)\]\-])/gi, "$1")
    .replace(/\b\d+\s*(?:g[uüUÜ]n|ay|y[iıIİ]l)\s+vade(?:li|si)?(?=$|[\s,.;:)\]\-])/gi, "");
  const temiz = sanitizePermissionText(onceki)
    .replace(/^[\s,.;:\/\-–—]+|[\s,.;:\/\-–—]+$/g, "")
    .replace(/\s+/g, " ")
    .trim();
  if (temiz.length < 2) return "";
  return Array.from(temiz).slice(0, azamiUzunluk).join("").toWellFormed().trim();
}

export function faturaVitrinTaslagiCikar(
  girdi: FaturaVitrinHamGirdi | null | undefined,
): FaturaVitrinTaslagi | null {
  if (!girdi || typeof girdi !== "object") return null;

  const taslak: FaturaVitrinTaslagi = { kaynak: "fatura" };

  const temizAd = guvenliFaturaMetniTemizle(girdi.aliciUnvan, 100);
  if (temizAd.length >= 2) {
    taslak.name = temizAd;
  }

  const hamAdres = typeof girdi.aliciAdres === "string" ? girdi.aliciAdres.trim() : "";
  if (hamAdres) {
    const yer = ilIlceCikar(hamAdres);
    if (yer?.il) {
      taslak.province_name = yer.il;
      if (yer.ilce) {
        const dogrulanmisIlce = resolveIlce(yer.il, yer.ilce);
        if (dogrulanmisIlce) {
          taslak.district_name = dogrulanmisIlce;
        }
      }
    }
  }

  if (Array.isArray(girdi.urunKategorileri)) {
    for (const hamKategori of girdi.urunKategorileri) {
      if (typeof hamKategori !== "string" || !hamKategori.trim()) continue;
      const eslesen = resolveBusinessCategory(hamKategori);
      if (eslesen?.id) {
        taslak.kategori = eslesen.id;
        break;
      }
    }
  }

  if (Array.isArray(girdi.markalar)) {
    for (const hamMarka of girdi.markalar) {
      const temizMarka = guvenliFaturaMetniTemizle(hamMarka, 60);
      if (temizMarka.length >= 2) {
        taslak.ilkMarka = temizMarka;
        break;
      }
    }
  }

  const doluMu = Boolean(
    taslak.name ||
      taslak.province_name ||
      taslak.district_name ||
      taslak.kategori ||
      taslak.ilkMarka,
  );
  return doluMu ? taslak : null;
}

function doluMetinMi(deger: unknown): boolean {
  return typeof deger === "string" && deger.trim().length > 0;
}

export function mevcutVitriniEzmedenBirlestir<T extends Record<string, unknown>>(
  mevcut: T,
  taslak: FaturaVitrinTaslagi | null,
): T {
  if (!taslak) return { ...mevcut };
  const sonuc: Record<string, unknown> = { ...mevcut };

  if (!doluMetinMi(sonuc.name) && taslak.name) {
    sonuc.name = taslak.name;
  }

  const mevcutIlDolu = doluMetinMi(sonuc.province_name);
  if (!mevcutIlDolu && taslak.province_name) {
    sonuc.province_name = taslak.province_name;
  }

  const ayniIlMi =
    !mevcutIlDolu ||
    (typeof sonuc.province_name === "string" &&
      typeof taslak.province_name === "string" &&
      sonuc.province_name.trim().toLocaleLowerCase("tr-TR") ===
        taslak.province_name.trim().toLocaleLowerCase("tr-TR"));

  if (!doluMetinMi(sonuc.district_name) && taslak.district_name && ayniIlMi) {
    sonuc.district_name = taslak.district_name;
  }

  if (!doluMetinMi(sonuc.kategori) && taslak.kategori) {
    sonuc.kategori = taslak.kategori;
  }

  return sonuc as T;
}

export function faturaVitrinTaslagiOku(): FaturaVitrinTaslagi | null {
  if (typeof window === "undefined") return null;
  try {
    const ham = window.sessionStorage.getItem(FATURA_VITRIN_TASLAGI_ANAHTARI);
    if (!ham) return null;
    const parsed = JSON.parse(ham) as Record<string, unknown>;
    if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) return null;
    if (parsed.kaynak !== "fatura") return null;
    const taslak: FaturaVitrinTaslagi = { kaynak: "fatura" };
    if (typeof parsed.name === "string" && parsed.name.trim().length >= 2) {
      taslak.name = guvenliFaturaMetniTemizle(parsed.name, 100) || undefined;
    }
    if (typeof parsed.province_name === "string" && parsed.province_name.trim()) {
      const yer = ilIlceCikar(
        [parsed.district_name, parsed.province_name].filter(Boolean).join(" "),
      );
      if (yer?.il) {
        taslak.province_name = yer.il;
        if (typeof parsed.district_name === "string" && parsed.district_name.trim()) {
          const dogrulanmis = resolveIlce(yer.il, parsed.district_name);
          if (dogrulanmis) taslak.district_name = dogrulanmis;
        }
      }
    }
    if (typeof parsed.kategori === "string" && parsed.kategori.trim()) {
      const eslesen = resolveBusinessCategory(parsed.kategori);
      if (eslesen?.id) taslak.kategori = eslesen.id;
    }
    if (typeof parsed.ilkMarka === "string" && parsed.ilkMarka.trim().length >= 2) {
      taslak.ilkMarka = guvenliFaturaMetniTemizle(parsed.ilkMarka, 60) || undefined;
    }
    return taslak.name || taslak.province_name || taslak.kategori || taslak.ilkMarka
      ? taslak
      : null;
  } catch {
    return null;
  }
}

export function faturaVitrinTaslagiKaydet(taslak: FaturaVitrinTaslagi | null): void {
  if (typeof window === "undefined" || !taslak) return;
  try {
    window.sessionStorage.setItem(FATURA_VITRIN_TASLAGI_ANAHTARI, JSON.stringify(taslak));
  } catch {
  }
}

export function faturaVitrinTaslagiTemizle(): void {
  if (typeof window === "undefined") return;
  try {
    window.sessionStorage.removeItem(FATURA_VITRIN_TASLAGI_ANAHTARI);
  } catch {
  }
}

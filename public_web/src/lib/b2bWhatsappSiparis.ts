import { normalizeWhatsappDigits } from "@/lib/products";
import { sanitizePermissionText } from "@/lib/supplierPermissionRequest";

export interface B2BStokYenileGirdisi {
  toptanciWhatsapp: string;
  urunAdi: string;
  marka?: string | null;
  modelKodu?: string | null;
  barkod?: string | null;
  varyantVeyaBeden?: string | null;
  adet: number;
  esnafMagazaAdi: string;
  esnafKonum?: string | null;
  not?: string | null;
}

const TOPTANCI_HAT_ONEKI = "vixrex_b2b_tedarikci_hat:";

function b2bMetinTemizle(deger: unknown, azamiUzunluk: number): string {
  if (typeof deger !== "string") return "";
  const tekSatir = deger
    .replace(/[\r\n\t\u0000-\u001F\u007F-\u009F\u2028\u2029]+/g, " ")
    .replace(/\bTR\d{2}(?:\s?[0-9A-Z]{4}){5}\s?[0-9A-Z]{2}\b/gi, "")
    .replace(/\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b/gi, "")
    .replace(/(^|[\s,.;:(\[\-])%?\s*\d+(?:[.,]\d+)?\s*%?\s*(?:[oöOÖ]zel\s+|genel\s+|sat[iıIİ]r\s+)?[iİıI]skonto(?:\s+(?:oran[iıIİ]|tutar[iıIİ]))?(?=$|[\s,.;:)\]\-])/gi, "$1")
    .replace(/\b\d+\s*(?:g[uüUÜ]n|ay|y[iıIİ]l)\s+vade(?:li|si)?(?=$|[\s,.;:)\]\-])/gi, "");
  const temiz = sanitizePermissionText(tekSatir).replace(/\s+/g, " ").trim();
  if (!temiz) return "";
  return Array.from(temiz).slice(0, azamiUzunluk).join("").toWellFormed().trim();
}

function gecerliWhatsappRakam(telefon: unknown): string | null {
  const rakamlar = normalizeWhatsappDigits(telefon);
  if (rakamlar.length < 10 || rakamlar.length > 15) return null;
  return rakamlar;
}

function gecerliAdetMi(adet: unknown): adet is number {
  return (
    typeof adet === "number" &&
    Number.isFinite(adet) &&
    Math.trunc(adet) === adet &&
    adet >= 1 &&
    adet <= 9999
  );
}

export function b2bStokYenileMesajiOlustur(girdi: B2BStokYenileGirdisi): string | null {
  if (!girdi || typeof girdi !== "object") return null;
  if (!gecerliWhatsappRakam(girdi.toptanciWhatsapp)) return null;
  if (!gecerliAdetMi(girdi.adet)) return null;

  const urunAdi = b2bMetinTemizle(girdi.urunAdi, 120);
  const esnafMagazaAdi = b2bMetinTemizle(girdi.esnafMagazaAdi, 100);
  if (!urunAdi || !esnafMagazaAdi) return null;

  const marka = b2bMetinTemizle(girdi.marka, 60);
  const modelKodu = b2bMetinTemizle(girdi.modelKodu, 60);
  const barkod = b2bMetinTemizle(girdi.barkod, 40);
  const varyant = b2bMetinTemizle(girdi.varyantVeyaBeden, 80);
  const konum = b2bMetinTemizle(girdi.esnafKonum, 80);
  const not = b2bMetinTemizle(girdi.not, 200);

  const satirlar = [
    "Merhaba, stok yenileme talebi:",
    `Mağaza: ${esnafMagazaAdi}`,
  ];
  if (konum) satirlar.push(`Konum: ${konum}`);
  if (marka) satirlar.push(`Marka: ${marka}`);
  satirlar.push(`Ürün: ${urunAdi}`);
  if (modelKodu) satirlar.push(`Model Kodu: ${modelKodu}`);
  if (barkod) satirlar.push(`Barkod: ${barkod}`);
  if (varyant) satirlar.push(`Varyant: ${varyant}`);
  satirlar.push(`Adet: ${girdi.adet}`);
  if (not) satirlar.push(`Not: ${not}`);

  return satirlar.join("\n").toWellFormed();
}

export function b2bStokYenileWhatsappUrl(girdi: B2BStokYenileGirdisi): string | null {
  const digits = gecerliWhatsappRakam(girdi?.toptanciWhatsapp);
  if (!digits) return null;
  const mesaj = b2bStokYenileMesajiOlustur(girdi);
  if (!mesaj) return null;
  return `https://wa.me/${digits}?text=${encodeURIComponent(mesaj)}`;
}

function markaAnahtari(marka: string): string {
  return b2bMetinTemizle(marka, 60).toLocaleLowerCase("tr-TR") || "_genel";
}

function hatHaritasiOku(storeSlug: string): Record<string, string> {
  if (typeof window === "undefined" || !storeSlug.trim()) return {};
  try {
    const ham = window.localStorage.getItem(`${TOPTANCI_HAT_ONEKI}${storeSlug.trim()}`);
    if (!ham) return {};
    const parsed = JSON.parse(ham) as unknown;
    if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) return {};
    const sonuc: Record<string, string> = {};
    for (const [k, v] of Object.entries(parsed as Record<string, unknown>)) {
      if (typeof v === "string" && v.trim()) sonuc[k] = v.trim();
    }
    return sonuc;
  } catch {
    return {};
  }
}

export function toptanciHatKaydet(storeSlug: string, marka: string, telefon: string): void {
  if (typeof window === "undefined" || !storeSlug.trim()) return;
  const temizTelefon = gecerliWhatsappRakam(telefon);
  if (!temizTelefon) return;
  try {
    const harita = hatHaritasiOku(storeSlug);
    harita[markaAnahtari(marka)] = temizTelefon;
    window.localStorage.setItem(
      `${TOPTANCI_HAT_ONEKI}${storeSlug.trim()}`,
      JSON.stringify(harita),
    );
  } catch {
  }
}

export function toptanciHatOku(storeSlug: string, marka: string): string {
  if (typeof window === "undefined" || !storeSlug.trim()) return "";
  const harita = hatHaritasiOku(storeSlug);
  return harita[markaAnahtari(marka)] ?? harita._genel ?? "";
}

// Şemadan beslenen tek doğrulayıcı.
//
// Genel tip/sınır kuralları vitrinFieldSchema.ts'ten gelir. Adres ve kategori
// gibi ürün-semantik kuralları da Flutter ile aynı ortak kaynaklara bağlanır.

import { resolveBusinessCategory } from "./businessCategories";
import { FIELD_BY_KEY, type VitrinField } from "./vitrinFieldSchema";

export type FieldValue = string | number | boolean | null;

export type ValidationResult =
  | { ok: true; alan: VitrinField; deger: FieldValue }
  | { ok: false; hata: string };

const URL_PROTOKOLLERI = ["http:", "https:"];
const ADRES_YER_BELIRTECLERI = [
  "cad",
  "sok",
  "mah",
  "bulv",
  "blv",
  "apt",
  "blok",
  "sit",
  "plaza",
  "çarşı",
  "carsi",
  "pasaj",
  "sanayi",
  "osb",
  "küme",
  "kume",
];

function guvenliUrlMu(deger: string, sayfaIciCapaSerbest: boolean): boolean {
  if (deger.startsWith("#")) return sayfaIciCapaSerbest;
  try {
    const parsed = new URL(deger);
    return URL_PROTOKOLLERI.includes(parsed.protocol);
  } catch {
    return false;
  }
}

function adresHataMesaji(deger: string): string | null {
  if (deger.length < 10) {
    return "Adres çok kısa. Müşterinin seni bulabilmesi için sokak/cadde ve kapı numarası yaz. Örnek: Atatürk Cad. No:24";
  }

  const kucuk = deger.toLocaleLowerCase("tr-TR");
  const rakamVar = /\d/.test(deger);
  const yerBelirteciVar = ADRES_YER_BELIRTECLERI.some((parca) =>
    kucuk.includes(parca),
  );
  if (!rakamVar && !yerBelirteciVar) {
    return "Adres eksik görünüyor. Sokak/cadde adı veya kapı numarası ekle. Örnek: Atatürk Cad. No:24";
  }
  return null;
}

function normalizeTurkeyMobile(deger: string): string | null {
  if (/[a-zA-ZçğıöşüÇĞİÖŞÜ]/.test(deger)) return null;
  const digits = deger.replace(/\D/g, "");
  if (/^05\d{9}$/.test(digits)) return `90${digits.slice(1)}`;
  if (/^5\d{9}$/.test(digits)) return `90${digits}`;
  if (/^905\d{9}$/.test(digits)) return digits;
  return null;
}

function metinSinirlari(alan: VitrinField, deger: string): string | null {
  const uzunluk = deger.length;
  if (alan.zorunlu && uzunluk === 0) {
    return `${alan.etiket} boş bırakılamaz.`;
  }
  if (alan.minUzunluk !== undefined && uzunluk > 0 && uzunluk < alan.minUzunluk) {
    return `${alan.etiket} en az ${alan.minUzunluk} karakter olmalı.`;
  }
  if (alan.maxUzunluk !== undefined && uzunluk > alan.maxUzunluk) {
    return `${alan.etiket} en fazla ${alan.maxUzunluk} karakter olabilir.`;
  }
  return null;
}

/**
 * Bir alanın gelen değerini şemaya göre doğrular ve normalleştirir.
 *
 * Boş metin `null` olarak döner — "alanı temizle" anlamına gelir.
 * Zorunlu alanlar boş bırakılamaz.
 */
export function validateField(anahtar: string, hamDeger: unknown): ValidationResult {
  const alan = FIELD_BY_KEY.get(anahtar);
  if (!alan) {
    return { ok: false, hata: "Bilinmeyen alan." };
  }

  // acikKapali: yalnız boolean
  if (alan.tip === "acikKapali") {
    if (typeof hamDeger !== "boolean") {
      return { ok: false, hata: `${alan.etiket} yalnız açık veya kapalı olabilir.` };
    }
    return { ok: true, alan, deger: hamDeger };
  }

  // sayi: sayıya çevir, sınırları kontrol et
  if (alan.tip === "sayi") {
    if (hamDeger === null || hamDeger === "") {
      return { ok: true, alan, deger: null };
    }
    const sayi = typeof hamDeger === "number" ? hamDeger : Number(String(hamDeger).replace(",", "."));
    if (!Number.isFinite(sayi)) {
      return { ok: false, hata: `${alan.etiket} sayı olmalı.` };
    }
    if (alan.min !== undefined && sayi < alan.min) {
      return { ok: false, hata: `${alan.etiket} en az ${alan.min} olabilir.` };
    }
    if (alan.max !== undefined && sayi > alan.max) {
      return { ok: false, hata: `${alan.etiket} en fazla ${alan.max} olabilir.` };
    }
    return { ok: true, alan, deger: sayi };
  }

  // Kalan tiplerin hepsi metin tabanlı
  if (typeof hamDeger !== "string" && hamDeger !== null) {
    return { ok: false, hata: `${alan.etiket} metin olmalı.` };
  }

  const deger = (hamDeger ?? "").trim();

  const sinirHatasi = metinSinirlari(alan, deger);
  if (sinirHatasi) return { ok: false, hata: sinirHatasi };

  if (deger === "") {
    return { ok: true, alan, deger: null };
  }

  switch (alan.tip) {
    case "telefon": {
      const rakamlar = deger.replace(/\D/g, "");
      if (alan.dogrulama === "tr_mobil") {
        const normalized = normalizeTurkeyMobile(deger);
        if (!normalized) {
          return {
            ok: false,
            hata: `${alan.etiket} geçerli bir Türkiye cep telefonu olmalı.`,
          };
        }
        return { ok: true, alan, deger: normalized };
      }
      if (rakamlar.length < 10 || rakamlar.length > 13) {
        return { ok: false, hata: `${alan.etiket} 10–13 rakam olmalı.` };
      }
      return { ok: true, alan, deger: rakamlar };
    }

    case "eposta": {
      if (!/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(deger)) {
        return { ok: false, hata: `${alan.etiket} geçerli bir e-posta olmalı.` };
      }
      return { ok: true, alan, deger };
    }

    case "url":
    case "gorsel": {
      const capaSerbest = alan.anahtar === "galeriAksiyonLinki";
      if (!guvenliUrlMu(deger, capaSerbest)) {
        return {
          ok: false,
          hata: `${alan.etiket} yalnız http veya https adresi olabilir.`,
        };
      }
      return { ok: true, alan, deger };
    }

    case "secim": {
      if (alan.anahtar === "kategori") {
        const kategori = resolveBusinessCategory(deger);
        if (!kategori || (alan.secenekler && !alan.secenekler.includes(kategori.label))) {
          return { ok: false, hata: `${alan.etiket} için geçersiz seçim.` };
        }
        return { ok: true, alan, deger: kategori.label };
      }
      if (alan.secenekler && !alan.secenekler.includes(deger)) {
        return { ok: false, hata: `${alan.etiket} için geçersiz seçim.` };
      }
      return { ok: true, alan, deger };
    }

    case "metin":
    case "uzunMetin": {
      if (alan.anahtar === "adres") {
        const hata = adresHataMesaji(deger);
        if (hata) return { ok: false, hata };
      }
      return { ok: true, alan, deger };
    }

    default: {
      // Şemaya yeni bir tip eklenip burada karşılanmazsa derleme hatası verir.
      const kalan: never = alan.tip;
      return { ok: false, hata: `Desteklenmeyen alan tipi: ${String(kalan)}` };
    }
  }
}

// Şemadan beslenen tek doğrulayıcı.
//
// Alan başına ayrı doğrulayıcı YOKTUR ve yazılmaz. Yeni alan eklendiğinde
// bu dosya değişmez — yalnız vitrinFieldSchema.ts'e satır eklenir.
//
// Plan: implementation_plan.md Commit 8

import { addressHataMesaji } from "./addressValidator";
import { FIELD_BY_KEY, type VitrinField } from "./vitrinFieldSchema";

export type FieldValue = string | number | boolean | null;

export type ValidationResult =
  | { ok: true; alan: VitrinField; deger: FieldValue }
  | { ok: false; hata: string };

const URL_PROTOKOLLERI = ["http:", "https:"];
const ACIK_DEGERLER = new Set([
  "aç",
  "ac",
  "açık",
  "acik",
  "göster",
  "goster",
  "evet",
  "on",
  "true",
  "1",
]);
const KAPALI_DEGERLER = new Set([
  "kapat",
  "kapalı",
  "kapali",
  "gizle",
  "hayır",
  "hayir",
  "off",
  "false",
  "0",
]);

function guvenliUrlMu(deger: string, anchorIzinli: boolean): boolean {
  if (deger.startsWith("#")) return anchorIzinli && deger.length > 1;
  try {
    const parsed = new URL(deger);
    return URL_PROTOKOLLERI.includes(parsed.protocol);
  } catch {
    return false;
  }
}

function normalizeTurkeyMobile(deger: string): string | null {
  if (/[a-zA-ZçğıöşüÇĞİÖŞÜ]/.test(deger)) return null;
  const digits = deger.replace(/\D/g, "");
  if (/^05\d{9}$/.test(digits)) return `90${digits.slice(1)}`;
  if (/^5\d{9}$/.test(digits)) return `90${digits}`;
  if (/^905\d{9}$/.test(digits)) return digits;
  return null;
}

function normalizeAcikKapali(deger: unknown): boolean | null {
  if (typeof deger === "boolean") return deger;
  if (typeof deger !== "string") return null;
  const normalized = deger.trim().toLocaleLowerCase("tr-TR");
  if (ACIK_DEGERLER.has(normalized)) return true;
  if (KAPALI_DEGERLER.has(normalized)) return false;
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

  // acikKapali: gerçek boolean veya dar, açıkça izinli esnaf ifadeleri.
  if (alan.tip === "acikKapali") {
    const normalized = normalizeAcikKapali(hamDeger);
    if (normalized === null) {
      return { ok: false, hata: `${alan.etiket} yalnız açık veya kapalı olabilir.` };
    }
    return { ok: true, alan, deger: normalized };
  }

  // sayi: sayıya çevir, sınırları kontrol et
  if (alan.tip === "sayi") {
    if (
      hamDeger === null ||
      hamDeger === "" ||
      (typeof hamDeger === "string" && hamDeger.trim() === "")
    ) {
      return { ok: true, alan, deger: null };
    }
    const sayi = typeof hamDeger === "number" ? hamDeger : Number(String(hamDeger).trim().replace(",", "."));
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

  if (alan.dogrulama === "adres") {
    const adresHatasi = addressHataMesaji(deger);
    if (adresHatasi) return { ok: false, hata: adresHatasi };
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

    case "url": {
      if (!guvenliUrlMu(deger, true)) {
        return {
          ok: false,
          hata: `${alan.etiket} yalnız http veya https adresi olabilir.`,
        };
      }
      return { ok: true, alan, deger };
    }

    case "gorsel": {
      if (!guvenliUrlMu(deger, false)) {
        return {
          ok: false,
          hata: `${alan.etiket} yalnız http veya https adresi olabilir.`,
        };
      }
      return { ok: true, alan, deger };
    }

    case "secim": {
      if (alan.secenekler && !alan.secenekler.includes(deger)) {
        return { ok: false, hata: `${alan.etiket} için geçersiz seçim.` };
      }
      return { ok: true, alan, deger };
    }

    case "metin":
    case "uzunMetin":
      return { ok: true, alan, deger };

    default: {
      const kalan: never = alan.tip;
      return { ok: false, hata: `Desteklenmeyen alan tipi: ${String(kalan)}` };
    }
  }
}

import { vixrexNormalizeDartParity } from "./vixrexNormalizer";

export interface VixrexBekleyenBaglam {
  anahtar: string;
  etiket: string;
  tip: string;
  eylem?: "kaldir";
}

export type VixrexBaglamKarari =
  | "genel_sor"
  | "ozel_sor"
  | "ayni_kalsin"
  | "kaldirma_onayi"
  | "kaldir"
  | "iptal"
  | "bool_true"
  | "bool_false"
  | "saat_eksik"
  | "adres_eksik"
  | "deger";

export interface VixrexBaglamSonucu {
  karar: VixrexBaglamKarari;
  yazma: boolean;
  mesaj: string;
  deger?: string | boolean | null;
}

export const VIXREX_DOGAL_GENEL_SORU = "Vitrininde neyi farklı görmek istersin?";

const IPTAL = new Set(["iptal", "vazgec", "vazgectim"]);
const EVET = new Set(["evet"]);
const HAYIR = new Set(["hayir"]);
const AYNI = new Set(["aynisi", "aynen aynisi"]);
const DEGER_OLMAYAN_KISA = new Set([
  "tamam",
  "olur",
  "peki",
  "aynen",
  "degistir",
  "degissin",
  "yap",
]);

function alanSorusu(bekleyen: VixrexBekleyenBaglam): string {
  return `${bekleyen.etiket} için ne yazayım?`;
}

function calismaSaatiTamMi(input: string): boolean {
  const norm = vixrexNormalizeDartParity(input);
  if (/\b24\s*saat\b/.test(norm) || /\b7\s*[/ ]\s*24\b/.test(norm)) return true;

  const saatler = input.match(/\b(?:[01]?\d|2[0-3])[:.]\d{2}\b/g) ?? [];
  if (saatler.length >= 2) return true;

  if (/\b\d{1,2}\s*[-–—]\s*\d{1,2}\b/.test(norm)) return true;

  const sayilar = norm.match(/\b\d{1,2}\b/g) ?? [];
  if (sayilar.length >= 2 && norm.includes("sabah") && norm.includes("aksam")) return true;

  return false;
}

function adresYeterinceAcikMi(input: string): boolean {
  const norm = vixrexNormalizeDartParity(input);
  const kelimeler = norm.split(/\s+/).filter(Boolean);
  if (kelimeler.length > 3) return true;
  return /\b(mahalle|mah|cadde|cad|sokak|sok|bulvar|blv|no|numara|apartman|apt|site|meydan)\b/.test(norm);
}

/**
 * Yalnız mevcut konuşma bağlamını yorumlar. Yeni niyet çözmez ve kayıt yapmaz.
 * Amaç kısa cevapları önceki soruyla birlikte değerlendirmek; bağlam yetersizse
 * tahmin ederek vitrine yazmak yerine doğal bir takip sorusu üretmektir.
 */
export function vixrexBaglamsalCevapKarari(
  input: string,
  bekleyen: VixrexBekleyenBaglam | null,
): VixrexBaglamSonucu {
  const trimmed = input.trim();
  const norm = vixrexNormalizeDartParity(trimmed);

  if (!bekleyen) {
    return { karar: "genel_sor", yazma: false, mesaj: VIXREX_DOGAL_GENEL_SORU };
  }

  // Bir önceki turda kullanıcı açıkça “onu kaldır” dedi ve Asistan onay
  // sorduysa, sonraki evet/hayır artık alan değeri değildir; o kaldırma
  // kararının cevabıdır.
  if (bekleyen.eylem === "kaldir") {
    if (EVET.has(norm)) {
      return { karar: "kaldir", yazma: true, mesaj: "", deger: null };
    }
    if (HAYIR.has(norm) || IPTAL.has(norm)) {
      return {
        karar: "iptal",
        yazma: false,
        mesaj: `Tamam, ${bekleyen.etiket} bilgisini kaldırmıyorum.`,
      };
    }
    return {
      karar: "kaldirma_onayi",
      yazma: false,
      mesaj: `${bekleyen.etiket} bilgisini kaldırmamı istiyorsan evet, vazgeçtiysen hayır diyebilirsin.`,
    };
  }

  if (IPTAL.has(norm)) {
    return {
      karar: "iptal",
      yazma: false,
      mesaj: "Tamam, bu değişikliği yapmıyorum. Başka neyi değiştirmek istersin?",
    };
  }

  if (AYNI.has(norm)) {
    return {
      karar: "ayni_kalsin",
      yazma: false,
      mesaj: `Tamam, ${bekleyen.etiket} aynı kalsın.`,
    };
  }

  if (bekleyen.tip === "acikKapali") {
    if (EVET.has(norm)) {
      return { karar: "bool_true", yazma: true, mesaj: "", deger: true };
    }
    if (HAYIR.has(norm)) {
      return { karar: "bool_false", yazma: true, mesaj: "", deger: false };
    }
  } else if (EVET.has(norm) || HAYIR.has(norm) || DEGER_OLMAYAN_KISA.has(norm)) {
    return {
      karar: "ozel_sor",
      yazma: false,
      mesaj: alanSorusu(bekleyen),
    };
  }

  if (/\b(onu|bunu)\s+(kaldir|sil|temizle)\b/.test(norm) || /^(kaldir|sil|temizle)$/.test(norm)) {
    return {
      karar: "kaldirma_onayi",
      yazma: false,
      mesaj: `${bekleyen.etiket} bilgisini kaldırmamı mı istiyorsun?`,
    };
  }

  if (bekleyen.anahtar === "calismaSaatleri" && !calismaSaatiTamMi(trimmed)) {
    return {
      karar: "saat_eksik",
      yazma: false,
      mesaj: "Çalışma saatlerini tamamlamak için kaçta açıp kaçta kapandığınızı yazar mısın?",
    };
  }

  if (bekleyen.anahtar === "adres" && !adresYeterinceAcikMi(trimmed)) {
    return {
      karar: "adres_eksik",
      yazma: false,
      mesaj: "Açık adresi biraz daha ayrıntılı yazar mısın?",
    };
  }

  return { karar: "deger", yazma: true, mesaj: "", deger: trimmed };
}

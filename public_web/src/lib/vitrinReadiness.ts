// Vitrin hazırlık raporu (implementation_plan.md Commit 9).
//
// "Hangi alanlar boş?" sorusunu ŞEMADAN hesaplar. Alan başına kontrol
// yazılmaz — referans sablonlar/hedef-vitrin.html'deki getReadiness() beş
// kontrolü elle sayıyordu ve o yüzden yalnız beş şeyi görebiliyordu.
//
// Yeni alan eklendiğinde bu dosya değişmez.

import { VITRIN_FIELDS, type VitrinField, type VitrinSection } from "./vitrinFieldSchema";

/** Vitrinin ayakta durması için doldurulması beklenen alanlar. */
const TEMEL_ALANLAR = new Set([
  "isletmeAdi",
  "kisaTanitim",
  "whatsapp",
  "adres",
  "kategori",
]);

/** Vitrini web sitesi kalitesine çıkaran, ama şart olmayan alanlar. */
const KALITE_ALANLARI = new Set([
  "heroRozet",
  "kapakGorseli",
  "logo",
  "hakkindaBaslik",
  "hakkindaMetin",
  "calismaSaatleri",
  "haritaLinki",
]);

export type EksikOnem = "temel" | "kalite" | "istege-bagli";

export interface EksikAlan {
  anahtar: string;
  etiket: string;
  bolum: VitrinSection;
  onem: EksikOnem;
}

export interface HazirlikRaporu {
  /** Temel alanların tamamı dolu mu? */
  temelTamam: boolean;
  /** 0–100. Temel ve kalite alanlarının doluluk oranı. */
  yuzde: number;
  doluSayisi: number;
  toplamSayisi: number;
  eksikler: EksikAlan[];
  /** Kullanıcıya söylenecek tek cümlelik sıradaki adım. */
  sonrakiAdim: string | null;
}

function onemi(alan: VitrinField): EksikOnem {
  if (TEMEL_ALANLAR.has(alan.anahtar)) return "temel";
  if (KALITE_ALANLARI.has(alan.anahtar)) return "kalite";
  return "istege-bagli";
}

function doluMu(deger: unknown): boolean {
  if (deger === null || deger === undefined) return false;
  if (typeof deger === "string") return deger.trim().length > 0;
  if (typeof deger === "boolean") return true; // açık/kapalı her hâlde karar verilmiştir
  if (typeof deger === "number") return Number.isFinite(deger);
  return true;
}

/**
 * Taslak verisine bakarak hazırlık raporu üretir.
 * @param draftData store_working_drafts.draft_data — kolon adına göre değerler
 */
export function hazirlikRaporu(draftData: Record<string, unknown>): HazirlikRaporu {
  const eksikler: EksikAlan[] = [];
  let dolu = 0;
  let toplam = 0;

  for (const alan of VITRIN_FIELDS) {
    const onem = onemi(alan);
    // İsteğe bağlı alanlar yüzdeye girmez; boşsa da vitrin eksik sayılmaz.
    if (onem === "istege-bagli") continue;

    toplam += 1;
    if (doluMu(draftData[alan.kolon])) {
      dolu += 1;
    } else {
      eksikler.push({
        anahtar: alan.anahtar,
        etiket: alan.etiket,
        bolum: alan.bolum,
        onem,
      });
    }
  }

  // Önce temel eksikler, sonra kalite eksikleri.
  eksikler.sort((a, b) => (a.onem === b.onem ? 0 : a.onem === "temel" ? -1 : 1));

  const temelTamam = !eksikler.some((e) => e.onem === "temel");
  const ilk = eksikler[0];

  return {
    temelTamam,
    yuzde: toplam === 0 ? 100 : Math.round((dolu / toplam) * 100),
    doluSayisi: dolu,
    toplamSayisi: toplam,
    eksikler,
    sonrakiAdim: ilk
      ? ilk.onem === "temel"
        ? `${ilk.etiket} eksik — vitrinin yayına hazır olması için gerekli.`
        : `${ilk.etiket} eklerseniz vitriniz daha güçlü görünür.`
      : null,
  };
}

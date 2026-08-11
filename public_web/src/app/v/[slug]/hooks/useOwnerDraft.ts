"use client";

import { useCallback, useMemo, useState } from "react";
import { hazirlikRaporu, type HazirlikRaporu } from "@/lib/vitrinReadiness";
import { useCanliVitrinSenkron } from "@/lib/canliVitrinSenkron";

/**
 * Taslak verisini tutar ve Supabase Broadcast üzerinden canlı güncel tutar.
 *
 * Sorumluluk:
 *   - sunucudan gelen draftData prop'u yerel kopyaya alır
 *   - sayfa yenilenince (yayınla / bırak / başka oturumdan alan değişikliği
 *     sinyali) draftData değişir → yerelTaslak güncellenir
 *   - hazırlık raporunu hesaplar (doluluk %, eksik alanlar)
 *
 * Başka oturumdan gelen taslak değişikliği router.refresh() ile sunucudan
 * yeniden okunur — broadcast payload'ı hiçbir zaman alan değeri taşımaz
 * (bkz. canliVitrinSenkron.ts güvenlik notu), o yüzden local patch yoktur.
 *
 * draftData → yerelTaslak eşitlemesi bilinçli olarak effect'te DEĞİL, render
 * sırasında yapılır (React'in "adjusting state when a prop changes" deseni,
 * code-review 2026-08-10: `react-hooks/set-state-in-effect` kırmızıydı) —
 * bir effect turu beklemeden aynı render'da güncel taslağı gösterir.
 *
 * Bu hook dışındaki hiçbir şey taslak state'ini doğrudan tutmaz.
 */
export interface OwnerDraftHook {
  yerelTaslak: Record<string, unknown>;
  setAlan: (kolon: string, deger: unknown) => void;
  rapor: HazirlikRaporu;
}

export function useOwnerDraft(
  slug: string,
  draftData: Record<string, unknown>
): OwnerDraftHook {
  const [yerelTaslak, setYerelTaslak] = useState<Record<string, unknown>>(draftData);
  // draftData'nın son işlenen referansı — render sırasında karşılaştırmak
  // için. Bu bir "eski değeri hatırla" state'i, ekranda gösterilmez.
  const [islenenDraftData, setIslenenDraftData] = useState(draftData);

  // Tam sayfa yenilenince (yayınla, bırak, başka oturumdan taslak
  // değişikliği) draftData prop'u yeni bir referans alır; yerelTaslak'ı
  // effect beklemeden, aynı render'da tazele.
  if (draftData !== islenenDraftData) {
    setIslenenDraftData(draftData);
    setYerelTaslak(draftData);
  }

  // Uygulamadan yayınlanan değişiklik VEYA başka oturumdan taslak alan
  // değişikliği → sayfa yenilenir → draftData prop'u tazelenir (yukarıdaki
  // effect ile yerelTaslak'a yansır).
  useCanliVitrinSenkron(slug, true, true);

  const rapor = useMemo(() => hazirlikRaporu(yerelTaslak), [yerelTaslak]);

  const setAlan = useCallback((kolon: string, deger: unknown) => {
    setYerelTaslak((prev: Record<string, unknown>) => ({ ...prev, [kolon]: deger }));
  }, []);

  return { yerelTaslak, setAlan, rapor };
}

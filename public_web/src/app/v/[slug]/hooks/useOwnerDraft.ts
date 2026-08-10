"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { hazirlikRaporu, type HazirlikRaporu } from "@/lib/vitrinReadiness";
import { useCanliVitrinSenkron, type TaslakGuncellemesi } from "@/lib/canliVitrinSenkron";

/**
 * Taslak verisini tutar ve Supabase Broadcast üzerinden canlı güncel tutar.
 *
 * Sorumluluk:
 *   - sunucudan gelen draftData prop'u yerel kopyaya alır
 *   - sayfa yenilenince (yayınla / bırak) draftData değişir → yerelTaslak güncellenir
 *   - başka oturumdan gelen broadcast → yerelTaslak'a alan alan yansır
 *   - hazırlık raporunu hesaplar (doluluk %, eksik alanlar)
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

  // Tam sayfa yenilenince (yayınla, bırak, Flutter'dan stores değişikliği)
  // draftData prop yeni bir referans alır; yerelTaslak'ı tazele.
  useEffect(() => {
    setYerelTaslak(draftData);
  }, [draftData]);

  // Broadcast'ten gelen taslak alan değişikliklerini yerelTaslak'a yansıt.
  const handleTaslakGuncellendi = useCallback((g: TaslakGuncellemesi) => {
    setYerelTaslak((prev: Record<string, unknown>) => ({ ...prev, [g.kolon]: g.deger }));
  }, []);

  // Uygulamadan yayınlanan değişiklik stores → sayfa yenilemesi.
  // Taslak alan değişikliği broadcast → handleTaslakGuncellendi → yerelTaslak.
  useCanliVitrinSenkron(slug, true, handleTaslakGuncellendi);

  const rapor = useMemo(() => hazirlikRaporu(yerelTaslak), [yerelTaslak]);

  const setAlan = useCallback((kolon: string, deger: unknown) => {
    setYerelTaslak((prev: Record<string, unknown>) => ({ ...prev, [kolon]: deger }));
  }, []);

  return { yerelTaslak, setAlan, rapor };
}

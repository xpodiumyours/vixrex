"use client";

import { useCallback, useMemo, useState } from "react";
import { hazirlikRaporu, type HazirlikRaporu } from "@/lib/vitrinReadiness";
import { useCanliVitrinSenkron } from "@/lib/canliVitrinSenkron";

/**
 * Taslak verisini + authoritative draft sürümünü tutar ve Supabase Broadcast
 * üzerinden canlı güncel tutar.
 *
 * Başka oturumdan gelen değişiklikte broadcast yalnız sinyal taşır;
 * router.refresh() sonrası server `draft_data + draft_version` birlikte gelir.
 * Smart-engine optimistic concurrency bu sürümü kullanır: API kendi kendine
 * "en yeni sürümü" okuyup expectedVersion uydurmaz.
 */
export interface OwnerDraftHook {
  yerelTaslak: Record<string, unknown>;
  setAlan: (kolon: string, deger: unknown) => void;
  draftVersion: number;
  setDraftVersion: (version: number) => void;
  rapor: HazirlikRaporu;
  /** "Boş geç" denen isteğe bağlı alanlar (ADR 0002, 3. alt-faz). */
  atlanmisAlanlar: ReadonlySet<string>;
  alanAtlandi: (anahtar: string) => void;
}

export function useOwnerDraft(
  slug: string,
  draftData: Record<string, unknown>,
  draftVersionBaslangic: number,
  atlananAlanlarBaslangic: readonly string[] = []
): OwnerDraftHook {
  const [yerelTaslak, setYerelTaslak] = useState<Record<string, unknown>>(draftData);
  const [draftVersion, setDraftVersion] = useState(draftVersionBaslangic);
  const [atlanmisAlanlar, setAtlanmisAlanlar] = useState<Set<string>>(
    () => new Set(atlananAlanlarBaslangic)
  );
  const [islenenDraftData, setIslenenDraftData] = useState(draftData);
  const [islenenDraftVersion, setIslenenDraftVersion] = useState(draftVersionBaslangic);

  // Tam sayfa yenilenince veya başka oturum draft'ı ilerletince içerik+sürüm
  // aynı render'da birlikte tazelenir; effect ile bir tur gecikme yoktur.
  if (
    draftData !== islenenDraftData ||
    draftVersionBaslangic !== islenenDraftVersion
  ) {
    setIslenenDraftData(draftData);
    setIslenenDraftVersion(draftVersionBaslangic);
    setYerelTaslak(draftData);
    setDraftVersion(draftVersionBaslangic);
  }

  useCanliVitrinSenkron(slug, true, true);

  const rapor = useMemo(
    () => hazirlikRaporu(yerelTaslak, atlanmisAlanlar),
    [yerelTaslak, atlanmisAlanlar]
  );

  const setAlan = useCallback((kolon: string, deger: unknown) => {
    setYerelTaslak((prev: Record<string, unknown>) => ({ ...prev, [kolon]: deger }));
  }, []);

  const alanAtlandi = useCallback((anahtar: string) => {
    setAtlanmisAlanlar((onceki) => new Set(onceki).add(anahtar));
  }, []);

  return {
    yerelTaslak,
    setAlan,
    draftVersion,
    setDraftVersion,
    rapor,
    atlanmisAlanlar,
    alanAtlandi,
  };
}

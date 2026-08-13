"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { FIELD_BY_KEY, type VitrinField } from "@/lib/vitrinFieldSchema";
import { alanOnemi, sonrakiRehberAlan } from "@/lib/vitrinReadiness";
import type { Mesaj } from "./useOwnerChat";

const VURGU_SINIFI = "vixrex-secili-alan";

export interface FieldSelectionHook {
  seciliAlan: VitrinField | null;
  giris: string;
  girisRef: React.RefObject<HTMLTextAreaElement | null>;
  setGiris: (v: string) => void;
  setSeciliAlan: (alan: VitrinField | null) => void;
  alanSec: (anahtar: string, oge?: Element | null) => void;
  vurguyuTemizle: () => void;
  /** Bir alan kaydedildikten SONRA çağrılır: sırada başka alan varsa oraya
   * geçer, yoksa akışı bitirir. `useOwnerActions`'ın üç kaydetme yolu da
   * eski `setSeciliAlan(null)` yerine bunu çağırır. */
  alanaGecVeyaBitir: (kaydedilenAnahtar: string) => void;
  /** Yalnız isteğe bağlı alanlarda gösterilen "Boş geç" düğmesi. */
  alanAtla: () => void;
}

interface Deps {
  yerelTaslak: Record<string, unknown>;
  mesajEkle: (kimden: Mesaj["kimden"], metin: string) => void;
  /**
   * Vitrinde bir alana tıklanınca çağrılır. Panel kapalıyken vitrinden
   * seçim yapmak paneli de açmalı — aksi halde esnaf tıklar, hiçbir şey
   * açılmamış gibi görünür (regresyon, code-review 2026-08-10: refactor
   * sırasında orijinal `setAcik(true)` çağrısı kaybolmuştu).
   */
  onAlanSecildi?: () => void;
}

export function useFieldSelection({
  yerelTaslak,
  mesajEkle,
  onAlanSecildi,
}: Deps): FieldSelectionHook {
  const [seciliAlan, setSeciliAlan] = useState<VitrinField | null>(null);
  const [giris, setGiris] = useState("");
  const girisRef = useRef<HTMLTextAreaElement>(null);
  const vurguluRef = useRef<Element | null>(null);
  // Oturum içinde "boş geç" denen isteğe bağlı alanlar. Kalıcı değil (sayfa
  // yenilenince unutulur) — kalıcı işaretleme ayrı bir alt-faz.
  const [atlanmisAlanlar, setAtlanmisAlanlar] = useState<Set<string>>(
    () => new Set()
  );

  const vurguyuTemizle = useCallback(() => {
    vurguluRef.current?.classList.remove(VURGU_SINIFI);
    vurguluRef.current = null;
  }, []);

  const alanSec = useCallback(
    (anahtar: string, oge?: Element | null) => {
      const alan = FIELD_BY_KEY.get(anahtar);
      if (!alan) return;

      vurguyuTemizle();
      const hedef =
        oge ?? document.querySelector(`[data-vixrex-editable="${anahtar}"]`);
      if (hedef) {
        hedef.classList.add(VURGU_SINIFI);
        vurguluRef.current = hedef;
        hedef.scrollIntoView({ behavior: "smooth", block: "center" });
      }

      onAlanSecildi?.();
      setSeciliAlan(alan);
      const mevcut = yerelTaslak[alan.kolon];
      setGiris(
        alan.tip === "acikKapali"
          ? ""
          : mevcut === null || mevcut === undefined
          ? ""
          : String(mevcut)
      );
      mesajEkle(
        "asistan",
        `"${alan.etiket}" alanını seçtin. Yeni değeri yaz ve gönder.${
          alan.ipucu ? ` (${alan.ipucu})` : ""
        }`
      );
      window.setTimeout(() => girisRef.current?.focus(), 60);
    },
    [yerelTaslak, mesajEkle, vurguyuTemizle, onAlanSecildi]
  );

  const alanaGecVeyaBitir = useCallback(
    (kaydedilenAnahtar: string) => {
      const sonraki = sonrakiRehberAlan(
        yerelTaslak,
        kaydedilenAnahtar,
        atlanmisAlanlar
      );
      if (sonraki) {
        alanSec(sonraki.anahtar);
        return;
      }
      vurguyuTemizle();
      setSeciliAlan(null);
      mesajEkle("asistan", "Harika, şu an eklenecek başka bir şey yok! 🎉");
    },
    [yerelTaslak, atlanmisAlanlar, alanSec, vurguyuTemizle, mesajEkle]
  );

  const alanAtla = useCallback(() => {
    if (!seciliAlan || alanOnemi(seciliAlan) !== "istege-bagli") return;
    const anahtar = seciliAlan.anahtar;
    const etiket = seciliAlan.etiket;
    setAtlanmisAlanlar((onceki) => new Set(onceki).add(anahtar));
    mesajEkle("asistan", `${etiket} şimdilik boş geçildi.`);
    alanaGecVeyaBitir(anahtar);
  }, [seciliAlan, mesajEkle, alanaGecVeyaBitir]);

  // Vitrindeki işaretli öğeler için tek dinleyici.
  useEffect(() => {
    const tiklama = (e: MouseEvent) => {
      const hedef = (e.target as HTMLElement | null)?.closest(
        "[data-vixrex-editable]"
      );
      if (!hedef) return;
      const anahtar = hedef.getAttribute("data-vixrex-editable");
      if (!anahtar) return;
      e.preventDefault();
      alanSec(anahtar, hedef);
    };
    document.addEventListener("click", tiklama);
    return () => document.removeEventListener("click", tiklama);
  }, [alanSec]);

  useEffect(() => vurguyuTemizle, [vurguyuTemizle]);

  return {
    seciliAlan,
    giris,
    girisRef,
    setGiris,
    setSeciliAlan,
    alanSec,
    vurguyuTemizle,
    alanaGecVeyaBitir,
    alanAtla,
  };
}

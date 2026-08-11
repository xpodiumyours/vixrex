"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import type { HazirlikRaporu } from "@/lib/vitrinReadiness";

export interface Mesaj {
  id: number;
  kimden: "asistan" | "kullanici";
  metin: string;
}

export interface OwnerChatHook {
  mesajlar: Mesaj[];
  mesajEkle: (kimden: Mesaj["kimden"], metin: string) => void;
  akisRef: React.RefObject<HTMLDivElement | null>;
}

export function useOwnerChat(rapor: HazirlikRaporu): OwnerChatHook {
  const [mesajlar, setMesajlar] = useState<Mesaj[]>([]);
  const akisRef = useRef<HTMLDivElement>(null);
  const sayacRef = useRef(0);

  const mesajEkle = useCallback((kimden: Mesaj["kimden"], metin: string) => {
    // Numara BURADA sabitlenir. Güncelleyicinin içinde okunursa, aynı anda
    // eklenen mesajlar React toplu güncelleme yaptığı için hepsi son değeri
    // alır ve aynı anahtarı paylaşır ("two children with the same key").
    sayacRef.current += 1;
    const id = sayacRef.current;
    setMesajlar((m) => [...m, { id, kimden, metin }]);
  }, []);

  // Açılış selamı — bir kez.
  useEffect(() => {
    if (mesajlar.length > 0) return;
    const selam = rapor.temelTamam
      ? `Vitrinin yayına hazır görünüyor. Doluluk: %${rapor.yuzde}.`
      : `Vitrininin doluluk oranı %${rapor.yuzde}. Birkaç alan eksik.`;
    mesajEkle("asistan", selam);
    if (rapor.sonrakiAdim) mesajEkle("asistan", rapor.sonrakiAdim);
    mesajEkle(
      "asistan",
      "Değiştirmek istediğin yazıya vitrinde tıkla — buradan düzenleriz."
    );
  }, [mesajlar.length, rapor, mesajEkle]);

  useEffect(() => {
    akisRef.current?.scrollTo({ top: akisRef.current.scrollHeight });
  }, [mesajlar]);

  return { mesajlar, mesajEkle, akisRef };
}

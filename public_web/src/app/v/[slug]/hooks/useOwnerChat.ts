"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import type { HazirlikRaporu } from "@/lib/vitrinReadiness";
import type { AssistantHandoffV1 } from "@/lib/assistantHandoff";

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

export function useOwnerChat(
  rapor: HazirlikRaporu,
  handoff?: AssistantHandoffV1 | null
): OwnerChatHook {
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

  // Açılış — bir kez. Flutter'dan gerçek bir konuşma geçmişi geldiyse
  // (assistant_handoff) o kaldığı yerden devam eder, yeniden selamlanmaz
  // (issue #111). Geçmiş yoksa (manuel panelden yayınlanmış, eski/handoff'suz
  // mağaza vb.) eskisi gibi doluluk özetiyle karşılar.
  useEffect(() => {
    if (mesajlar.length > 0) return;

    if (handoff && handoff.messages.length > 0) {
      for (const m of handoff.messages) {
        mesajEkle(m.role === "assistant" ? "asistan" : "kullanici", m.text);
      }
      if (rapor.sonrakiAdim) mesajEkle("asistan", rapor.sonrakiAdim);
      return;
    }

    const selam = rapor.temelTamam
      ? `Vitrinin yayına hazır görünüyor. Doluluk: %${rapor.yuzde}.`
      : `Vitrininin doluluk oranı %${rapor.yuzde}. Birkaç alan eksik.`;
    mesajEkle("asistan", selam);
    if (rapor.sonrakiAdim) mesajEkle("asistan", rapor.sonrakiAdim);
    mesajEkle(
      "asistan",
      "Değiştirmek istediğin yazıya vitrinde tıkla — buradan düzenleriz."
    );
  }, [mesajlar.length, rapor, handoff, mesajEkle]);

  useEffect(() => {
    akisRef.current?.scrollTo({ top: akisRef.current.scrollHeight });
  }, [mesajlar]);

  return { mesajlar, mesajEkle, akisRef };
}

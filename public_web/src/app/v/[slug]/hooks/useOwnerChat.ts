"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import {
  ownerChatInitialMessages,
  type AssistantHandoffV1,
  type OwnerChatMessage,
} from "@/lib/assistantHandoff";
import type { HazirlikRaporu } from "@/lib/vitrinReadiness";

export type Mesaj = OwnerChatMessage;

export interface OwnerChatHook {
  mesajlar: Mesaj[];
  mesajEkle: (kimden: Mesaj["kimden"], metin: string) => void;
  akisRef: React.RefObject<HTMLDivElement | null>;
}

export function useOwnerChat(
  rapor: HazirlikRaporu,
  handoff: AssistantHandoffV1 | null
): OwnerChatHook {
  const [mesajlar, setMesajlar] = useState<Mesaj[]>(() =>
    ownerChatInitialMessages(rapor, handoff)
  );
  const akisRef = useRef<HTMLDivElement>(null);
  const sayacRef = useRef(mesajlar.length);

  const mesajEkle = useCallback((kimden: Mesaj["kimden"], metin: string) => {
    // Numara BURADA sabitlenir. Güncelleyicinin içinde okunursa, aynı anda
    // eklenen mesajlar React toplu güncelleme yaptığı için hepsi son değeri
    // alır ve aynı anahtarı paylaşır ("two children with the same key").
    sayacRef.current += 1;
    const id = sayacRef.current;
    setMesajlar((m) => [...m, { id, kimden, metin }]);
  }, []);

  useEffect(() => {
    akisRef.current?.scrollTo({ top: akisRef.current.scrollHeight });
  }, [mesajlar]);

  return { mesajlar, mesajEkle, akisRef };
}

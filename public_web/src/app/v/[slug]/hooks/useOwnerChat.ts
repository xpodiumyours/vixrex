"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import {
  ownerChatInitialMessages,
  type AssistantHandoffV1,
  type OwnerChatMessage,
} from "@/lib/assistantHandoff";
import type { HazirlikRaporu } from "@/lib/vitrinReadiness";
import { supabase } from "@/lib/supabase";

export type Mesaj = OwnerChatMessage;

export interface OwnerChatHook {
  mesajlar: Mesaj[];
  mesajEkle: (kimden: Mesaj["kimden"], metin: string) => void;
  akisRef: React.RefObject<HTMLDivElement | null>;
}

export function useOwnerChat(
  rapor: HazirlikRaporu,
  handoff: AssistantHandoffV1 | null,
  opts?: { slug?: string; initialDbMessages?: Array<{ role: string; message_text: string; message_key?: string | null }> }
): OwnerChatHook {
  const [mesajlar, setMesajlar] = useState<Mesaj[]>(() => {
    if (opts?.initialDbMessages && opts.initialDbMessages.length > 0) {
      return opts.initialDbMessages.map((m, i) => ({
        id: i + 1,
        kimden: (m.role === "assistant" ? "asistan" : "kullanici") as Mesaj["kimden"],
        metin: m.message_text,
      }));
    }
    return ownerChatInitialMessages(rapor, handoff);
  });
  const akisRef = useRef<HTMLDivElement>(null);
  const sayacRef = useRef(mesajlar.length);

  // Kalıcı konuşma varsa DB'den yükle (PR4-C13) — React belleği yalnız önbellek
  useEffect(() => {
    if (opts?.initialDbMessages && opts.initialDbMessages.length > 0) return;
    // Eski yol: handoff'tan gelen başlangıç mesajları kullanılıyor
  }, [opts?.initialDbMessages]);

  const mesajEkle = useCallback(
    (kimden: Mesaj["kimden"], metin: string) => {
      sayacRef.current += 1;
      const id = sayacRef.current;
      setMesajlar((m) => [...m, { id, kimden, metin }]);

      // PR4-C13: kalıcı konuşmaya da yaz (idempotent)
      // slug ve conversation yoksa sessizce atla (geriye uyum)
      if (!opts?.slug) return;
      const role = kimden === "asistan" ? "assistant" : "user";
      const clientId = `${Date.now()}-${id}-${kimden}`;
      // Fire-and-forget, UI bloklanmaz
      supabase
        .rpc("get_owner_workspace_bootstrap")
        .then(({ data }) => {
          const conv = (data as { conversation?: { id: string } })?.conversation;
          if (!conv?.id) return null;
          return supabase.rpc("append_assistant_message", {
            p_conversation_id: conv.id,
            p_client_message_id: clientId,
            p_role: role,
            p_message_key: null,
            p_message_text: metin,
            p_catalog_snapshot: null,
          });
        })
        .then(() => {})
        .catch(() => {});
    },
    [opts?.slug]
  );

  useEffect(() => {
    akisRef.current?.scrollTo({ top: akisRef.current.scrollHeight });
  }, [mesajlar]);

  return { mesajlar, mesajEkle, akisRef };
}

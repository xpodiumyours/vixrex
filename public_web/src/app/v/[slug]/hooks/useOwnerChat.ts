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
  /** Faz C2: üçüncü argüman opsiyonel — mevcut 30'dan fazla çağrı yeri
   * hiç değişmeden çalışmaya devam eder. Hızlı cevaplar yalnız oturum
   * belleğinde tutulur, DB'ye yazılmaz (bkz. persist() içindeki not). */
  mesajEkle: (
    kimden: Mesaj["kimden"],
    metin: string,
    hizliCevaplar?: Mesaj["hizliCevaplar"]
  ) => void;
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
  const [conversationId, setConversationId] = useState<string | null>(null);
  const akisRef = useRef<HTMLDivElement>(null);
  const sayacRef = useRef(mesajlar.length);
  const initialLoadDoneRef = useRef(false);

  // Faz 1: Kalıcı hesaplarda ortak Supabase konuşmasına bağlan
  // - Flutter ve landing aynı `assistant_conversations` tablosunu kullanıyor
  // - Sahip paneli ekran belleğinde kalmamalı, kalıcı hesaplarda DB'den okuyup DB'ye yazmalı
  // Faz 2: 15sn poll + sekme görünür olunca tazele — RLS nedeniyle postgres_changes dinlenemez, RPC poll daha güvenilir
  const pollActiveRef = useRef(false);
  const fetchAndSync = useCallback(
    async (opts2?: { forceReplace?: boolean }) => {
      if (pollActiveRef.current) return;
      pollActiveRef.current = true;
      try {
        const { data: { session } } = await supabase.auth.getSession();
        const user = session?.user as { is_anonymous?: boolean } | undefined;
        if (!session || user?.is_anonymous) return;
        const { data, error } = await supabase.rpc("get_assistant_conversation");
        if (error || !data) return;
        const conv = data as {
          id?: string;
          messages?: Array<{ role: string; message_text: string; message_key?: string | null; seq: number; client_message_id?: string | null }>;
        };
        if (!conv.id) return;
        setConversationId((prev) => prev ?? conv.id!);
        const dbMessages = Array.isArray(conv.messages) ? conv.messages : [];
        if (dbMessages.length === 0) return;
        const mapped: Mesaj[] = dbMessages.map((m, i) => ({
          id: i + 1,
          kimden: (m.role === "assistant" ? "asistan" : "kullanici") as Mesaj["kimden"],
          metin: m.message_text,
        }));
        // Dedup: DB daha uzunsa veya ilk mesaj farklıysa (handoff → gerçek DB geçişi) senkronize et
        setMesajlar((prev) => {
          // Faz C2: hizliCevaplar DB'ye yazılmıyor (yalnız oturum belleği) —
          // poll DB'den taze bir dizi getirdiğinde aynı index'teki metin
          // eşleşiyorsa önceki hızlı cevapları kaybetmeden taşı. Eşleşmezse
          // (mesaj gerçekten değiştiyse) taşımaz — yanlış mesaja iliştirmez.
          const zenginlestir = (hedef: Mesaj[]) =>
            hedef.map((msg, i) =>
              prev[i]?.hizliCevaplar && prev[i].metin === msg.metin
                ? { ...msg, hizliCevaplar: prev[i].hizliCevaplar }
                : msg
            );
          if (opts2?.forceReplace) return zenginlestir(mapped);
          if (mapped.length > prev.length) return zenginlestir(mapped);
          // Aynı uzunlukta ama içerik farklıysa (başka cihaz yazdı, poll geç yakaladı) — seq’e göre en günceli al
          if (mapped.length === prev.length && mapped.length > 0) {
            const prevFirst = prev[0]?.metin ?? "";
            const mappedFirst = mapped[0]?.metin ?? "";
            if (prevFirst !== mappedFirst) return zenginlestir(mapped);
          }
          return prev;
        });
        sayacRef.current = Math.max(sayacRef.current, mapped.length);
      } catch {
        // Migration eksikse sessizce bellek modunda kal
      } finally {
        pollActiveRef.current = false;
      }
    },
    []
  );

  useEffect(() => {
    if (opts?.initialDbMessages && opts.initialDbMessages.length > 0) return;
    if (initialLoadDoneRef.current) return;
    initialLoadDoneRef.current = true;
    let cancelled = false;
    (async () => {
      if (cancelled) return;
      await fetchAndSync({ forceReplace: true });
    })();
    return () => {
      cancelled = true;
    };
  }, [opts?.initialDbMessages, fetchAndSync]);

  // Poll: 15sn’de bir ve sekme görünür olunca — başka cihaz/Flutter yazdıysa otomatik düşer
  useEffect(() => {
    if (opts?.initialDbMessages && opts.initialDbMessages.length > 0) return; // server’dan gelen varsa poll’a gerek yok (ileride eklenebilir)
    let interval: ReturnType<typeof setInterval> | null = null;
    let cancelled = false;

    const startPoll = async () => {
      // İlk poll’u 15sn sonra değil, 3sn sonra başlat — hızlı senkron için
      await new Promise((r) => setTimeout(r, 3000));
      if (cancelled) return;
      interval = setInterval(() => {
        if (document.visibilityState !== "visible") return;
        fetchAndSync();
      }, 15000);
    };
    startPoll();

    const onVisible = () => {
      if (document.visibilityState === "visible") fetchAndSync();
    };
    document.addEventListener("visibilitychange", onVisible);

    // Auth değişince (login/logout) hemen senkronize et
    const { data: sub } = supabase.auth.onAuthStateChange(() => {
      fetchAndSync({ forceReplace: true });
    });

    return () => {
      cancelled = true;
      if (interval) clearInterval(interval);
      document.removeEventListener("visibilitychange", onVisible);
      sub.subscription.unsubscribe();
    };
  }, [fetchAndSync, opts?.initialDbMessages]);

  const mesajEkle = useCallback(
    (kimden: Mesaj["kimden"], metin: string, hizliCevaplar?: Mesaj["hizliCevaplar"]) => {
      const trimmed = metin.trim();
      if (!trimmed) return;
      sayacRef.current += 1;
      const id = sayacRef.current;
      setMesajlar((m) => [
        ...m,
        hizliCevaplar && hizliCevaplar.length > 0
          ? { id, kimden, metin: trimmed, hizliCevaplar }
          : { id, kimden, metin: trimmed },
      ]);

      // Kalıcı konuşmaya da yaz — fire-and-forget, UI bloklanmaz
      // conversationId yoksa lazy-resolve dene (tek sefer)
      const role = kimden === "asistan" ? "assistant" : "user";
      const clientId = `next-${typeof crypto !== "undefined" && crypto.randomUUID ? crypto.randomUUID() : `${Date.now()}-${id}`}`;

      const persist = async (cid: string) => {
        try {
          await supabase.rpc("append_assistant_message", {
            p_conversation_id: cid,
            p_client_message_id: clientId,
            p_role: role,
            p_message_key: null,
            p_message_text: trimmed,
            // Faz C2: hizliCevaplar kasıtlı olarak p_catalog_snapshot'a
            // yazılmıyor — column var ve okuma tarafı (get_assistant_
            // conversation) zaten geçiriyor, ama bunu kullanmak DB'de JSON
            // string encode/decode + poll'un zenginlestir() eşleşmesiyle
            // aynı işi iki yerde yapmak demek. C3 gerçek bir kalıcılık
            // ihtiyacı (ör. sayfa yenilenince "Google ile devam et"
            // düğmesinin kaybolmaması) doğrularsa buraya taşınabilir.
            p_catalog_snapshot: null,
          });
        } catch {
          // Anonim veya migration eksikse sessizce yut — bellek modu korunur
        }
      };

      if (conversationId) {
        persist(conversationId);
        return;
      }
      // Lazy resolve: slug olsun olmasın get_assistant_conversation yeter (auth.uid() ile)
      supabase.auth
        .getSession()
        .then(({ data: { session } }) => {
          const u = session?.user as { is_anonymous?: boolean } | undefined;
          if (!session || u?.is_anonymous) return null;
          return supabase.rpc("get_assistant_conversation");
        })
        .then((res) => {
          if (!res || (res as { error?: unknown }).error) return null;
          const data = (res as { data?: unknown }).data as { id?: string } | null;
          if (!data?.id) return null;
          setConversationId(data.id);
          return persist(data.id);
        })
        .catch(() => {});
    },
    [conversationId]
  );

  useEffect(() => {
    akisRef.current?.scrollTo({ top: akisRef.current.scrollHeight });
  }, [mesajlar]);

  return { mesajlar, mesajEkle, akisRef };
}

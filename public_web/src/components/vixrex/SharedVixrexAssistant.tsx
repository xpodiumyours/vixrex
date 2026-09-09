"use client";

import Link from "next/link";
import { useEffect, useRef, useState } from "react";
import {
  loadSharedAssistantContext,
  sendSharedAssistantMessage,
  type SharedAssistantContext,
  type SharedAssistantMessage,
} from "@/lib/assistantConversation";
import { vixRexMesajlari, hizliSecenekEtiketi } from "@/lib/vixrexMesajlari";

const EMPTY_CONTEXT: SharedAssistantContext = {
  authenticated: false,
  conversationId: null,
  messages: [],
  hasStore: false,
  flowState: null,
};

export function SharedVixrexAssistant({ onBrowse }: { onBrowse: () => void }) {
  const [context, setContext] = useState<SharedAssistantContext>(EMPTY_CONTEXT);
  const [messages, setMessages] = useState<SharedAssistantMessage[]>([]);
  const [input, setInput] = useState("");
  const [loading, setLoading] = useState(true);
  const [sending, setSending] = useState(false);
  const [error, setError] = useState("");
  const listRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    let cancelled = false;
    loadSharedAssistantContext()
      .then((next) => {
        if (cancelled) return;
        setContext(next);
        setMessages(next.messages);
      })
      .catch(() => {
        if (!cancelled) setError("Vixrex konuşması yüklenemedi. Lütfen tekrar dene.");
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => { cancelled = true; };
  }, []);

  useEffect(() => {
    listRef.current?.scrollTo({ top: listRef.current.scrollHeight, behavior: "smooth" });
  }, [messages]);

  // `hazirMetin` verilirse yazı kutusu değil, hızlı seçenek gönderiyor
  // demektir: seçeneğin ortak katalogdaki etiketi kullanıcı mesajı olarak
  // konuşmaya düşer ve asistan yerinde cevap verir. Sohbet tabanlı asistanda
  // hızlı seçeneğin karşılığı budur — kullanıcıyı başka sayfaya atmak değil.
  async function send(hazirMetin?: string) {
    const text = (hazirMetin ?? input).trim();
    if (!text || !context.conversationId || sending) return;
    setSending(true);
    setError("");
    if (!hazirMetin) setInput("");
    try {
      const appended = await sendSharedAssistantMessage(context.conversationId, text);
      setMessages((current) => [...current, ...appended]);
    } catch {
      if (!hazirMetin) setInput(text);
      setError("Mesaj gönderilemedi. Bağlantını kontrol edip tekrar dene.");
    } finally {
      setSending(false);
    }
  }

  const visibleMessages = messages.length > 0
    ? messages
    : [{
        id: "welcome",
        seq: 0,
        role: "assistant" as const,
        message_text: vixRexMesajlari.setup_invite,
      }];

  return (
    <section className="flex h-[calc(100vh-61px)] min-h-[520px] flex-col bg-lp-bg-editor" aria-labelledby="vixrex-assistant-title">
      <header className="flex min-h-[58px] items-center gap-3 border-b border-lp-border px-4">
        <span className="flex h-10 w-10 items-center justify-center overflow-hidden rounded-full border border-lp-primary/60 bg-lp-surface" aria-hidden="true">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src="/images/vixrex_v_crystal_mascot.png" alt="" className="h-9 w-9 object-contain" />
        </span>
        <div>
          <h1 id="vixrex-assistant-title" className="text-[16px] font-black text-lp-text">Vixrex</h1>
          <p className="text-[11px] font-semibold text-lp-primary">Yanındayım</p>
        </div>
      </header>

      <div ref={listRef} className="flex-1 space-y-3 overflow-y-auto px-4 py-3" aria-live="polite">
        {loading ? <p className="text-[12px] font-semibold text-lp-muted">Konuşman yükleniyor…</p> : null}
        {!loading && !context.authenticated ? (
          <div className="rounded-2xl border border-lp-border bg-lp-surface-soft px-4 py-4 text-[13px] text-lp-text-alt">
            <p className="font-black text-lp-text">Konuşmanı cihazlar arasında sürdür</p>
            <p className="mt-1">Flutter ve web’de aynı Vixrex konuşmasını görmek için aynı hesapla giriş yap.</p>
            <Link href="/giris" className="mt-3 inline-flex min-h-10 items-center rounded-xl bg-lp-primary px-4 font-black text-lp-on-primary">Giriş yap</Link>
          </div>
        ) : null}
        {!loading ? visibleMessages.map((message) => (
          <div key={`${message.id}-${message.seq}`} className={`flex ${message.role === "user" ? "justify-end" : "justify-start"}`}>
            <div className={`max-w-[720px] whitespace-pre-line rounded-2xl px-4 py-3 text-[13px] leading-[1.5] ${
              message.role === "user"
                ? "bg-lp-primary text-lp-on-primary"
                : "border border-lp-border bg-lp-surface-soft text-lp-text-alt"
            }`}>
              {message.message_text}
            </div>
          </div>
        )) : null}
        {error ? <p className="text-[12px] font-bold text-red-400" role="alert">{error}</p> : null}
      </div>

      <div className="border-t border-lp-border px-4 py-3">
        {!context.hasStore ? (
          <div className="mb-3 grid gap-2 sm:grid-cols-3">
            <Link href="/kesfet?yalniz_kiralik=1" className="flex min-h-11 items-center justify-center rounded-xl bg-lp-primary px-3 text-[12px] font-black text-lp-on-primary">
              {hizliSecenekEtiketi("hazir_vitrin_sec")}
            </Link>
            <button
              type="button"
              disabled={sending}
              onClick={() => {
                void send(
                  hizliSecenekEtiketi("sifirdan_olustur")
                );
              }}
              className="flex min-h-11 items-center justify-center rounded-xl border border-lp-border bg-lp-surface px-3 text-[12px] font-black text-lp-text-alt disabled:opacity-60"
            >
              {hizliSecenekEtiketi("sifirdan_olustur")}
            </button>
            <button type="button" onClick={onBrowse} className="min-h-11 rounded-xl border border-lp-border bg-lp-surface px-3 text-[12px] font-black text-lp-text-alt">
              {hizliSecenekEtiketi("bakiniyorum")}
            </button>
          </div>
        ) : null}
        <form onSubmit={(event) => { event.preventDefault(); void send(); }} className="flex gap-2">
          <label htmlFor="shared-vixrex-message" className="sr-only">Vixrex’e mesaj yaz</label>
          <input
            id="shared-vixrex-message"
            value={input}
            onChange={(event) => setInput(event.target.value)}
            disabled={!context.authenticated || sending}
            placeholder={context.authenticated ? "Vixrex’e sor…" : "Devam etmek için giriş yap"}
            className="h-12 min-w-0 flex-1 rounded-xl border border-lp-border bg-lp-surface px-4 text-[13px] font-semibold text-lp-text outline-none placeholder:text-lp-muted focus:border-lp-primary disabled:opacity-60"
          />
          <button type="submit" disabled={!input.trim() || !context.authenticated || sending} className="h-12 rounded-xl bg-lp-primary px-5 text-[12px] font-black text-lp-on-primary disabled:opacity-50">
            {sending ? "Gönderiliyor…" : "Gönder"}
          </button>
        </form>
      </div>
    </section>
  );
}

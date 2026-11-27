"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabase";
import { ziyaretAnahtariniOkuyaUret } from "@/lib/vitrinZiyaretAnahtari";

type SocialComment = {
  id: string;
  author_name: string;
  body: string;
  created_at: string;
  can_delete?: boolean;
};

interface ProductCommentsProps {
  storeSlug: string;
  productSlug: string;
  enabled?: boolean;
}

export default function ProductComments({
  storeSlug,
  productSlug,
  enabled = true,
}: ProductCommentsProps) {
  const [social, setSocial] = useState<{
    comment_count: number;
    comments: SocialComment[];
  }>({ comment_count: 0, comments: [] });
  const [comment, setComment] = useState("");
  const [message, setMessage] = useState("");
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    if (!enabled) return;
    const key = ziyaretAnahtariniOkuyaUret();
    let active = true;
    async function load() {
      const { data, error } = await supabase.rpc("get_product_social_state", {
        p_store_slug: storeSlug,
        p_product_slug: productSlug,
        p_session_key: key,
      });
      if (!active || error || !data) return;
      const value = data as { comment_count?: unknown; comments?: unknown };
      setSocial({
        comment_count: Number(value.comment_count) || 0,
        comments: Array.isArray(value.comments) ? (value.comments as SocialComment[]) : [],
      });
    }
    void load();
    return () => {
      active = false;
    };
  }, [enabled, productSlug, storeSlug]);

  if (!enabled) return null;

  async function submitComment() {
    const sessionKey = ziyaretAnahtariniOkuyaUret();
    const body = comment.trim();
    if (body.length < 3 || busy) return;
    setBusy(true);
    setMessage("");
    try {
      const {
        data: { session },
      } = await supabase.auth.getSession();
      if (!session || session.user.is_anonymous) {
        setMessage("Yorum yazmak için Google ile giriş yapmalısın.");
        return;
      }
      const { data, error } = await supabase.rpc("create_product_comment", {
        p_store_slug: storeSlug,
        p_product_slug: productSlug,
        p_session_key: sessionKey,
        p_body: body,
      });
      if (error) throw error;
      const created = data as SocialComment;
      setSocial((current) => ({
        ...current,
        comment_count: current.comment_count + 1,
        comments: [created, ...current.comments].slice(0, 20),
      }));
      setComment("");
      setMessage("Yorumun yayınlandı.");
    } catch (error) {
      const detail = error instanceof Error ? error.message : String(error || "");
      if (detail.includes("COMMENT_RATE_LIMIT")) {
        setMessage("Çok kısa sürede fazla yorum gönderdin. Biraz sonra tekrar dene.");
      } else if (detail.includes("DUPLICATE_COMMENT")) {
        setMessage("Aynı yorumu kısa süre içinde tekrar gönderemezsin.");
      } else {
        setMessage("Yorum şu anda kaydedilemedi.");
      }
    } finally {
      setBusy(false);
    }
  }

  async function deleteComment(commentId: string) {
    if (busy) return;
    setBusy(true);
    setMessage("");
    try {
      const { error } = await supabase.rpc("delete_my_product_comment", {
        p_comment_id: commentId,
      });
      if (error) throw error;
      setSocial((current) => ({
        comment_count: Math.max(0, current.comment_count - 1),
        comments: current.comments.filter((item) => item.id !== commentId),
      }));
    } catch {
      setMessage("Yorum şu anda silinemedi.");
    } finally {
      setBusy(false);
    }
  }

  return (
    <section className="rounded-3xl border border-white/10 bg-white/[0.03] p-5" aria-label="Yorumlar">
      <div className="flex items-center justify-between gap-3">
        <h2 className="text-sm font-extrabold text-white">Yorumlar</h2>
        <span className="text-xs font-bold text-white/40">{social.comment_count}</span>
      </div>

      <div className="mt-3 flex gap-2">
        <input
          value={comment}
          maxLength={500}
          onChange={(event) => setComment(event.target.value)}
          placeholder="Ürün hakkında yorum yaz"
          className="min-h-11 w-0 min-w-0 flex-1 rounded-xl border border-white/10 bg-slate-950 px-3 text-sm text-white outline-none placeholder:text-white/35 focus:border-blue-500/50"
        />
        <button
          type="button"
          onClick={() => void submitComment()}
          disabled={busy || comment.trim().length < 3}
          className="min-h-11 rounded-xl border border-blue-500/30 px-4 text-xs font-extrabold text-blue-200 disabled:opacity-45"
        >
          Gönder
        </button>
      </div>

      {message.includes("Google") ? (
        <Link
          href={`/giris?next=${encodeURIComponent(`/v/${storeSlug}/urun/${productSlug}`)}`}
          className="mt-2 inline-flex text-xs font-extrabold text-blue-300 underline"
        >
          Google ile giriş yap
        </Link>
      ) : null}

      {social.comments.length > 0 ? (
        <div className="mt-3 max-h-64 space-y-2 overflow-y-auto pr-1">
          {social.comments.map((item) => (
            <article key={item.id} className="rounded-xl border border-white/8 bg-slate-950/55 px-3 py-2.5">
              <div className="flex items-start justify-between gap-3">
                <div className="min-w-0">
                  <div className="text-[11px] font-extrabold text-white/55">{item.author_name}</div>
                  <p className="mt-1 whitespace-pre-wrap break-words text-xs leading-5 text-white/80">{item.body}</p>
                </div>
                {item.can_delete ? (
                  <button
                    type="button"
                    disabled={busy}
                    onClick={() => void deleteComment(item.id)}
                    className="shrink-0 text-[10px] font-extrabold text-white/40 disabled:opacity-50 hover:text-white"
                  >
                    Sil
                  </button>
                ) : null}
              </div>
            </article>
          ))}
        </div>
      ) : (
        <p className="mt-3 text-xs font-medium text-white/40">Henüz yorum yok.</p>
      )}

      {message ? <p className="mt-3 text-xs font-semibold text-blue-200" role="status">{message}</p> : null}
    </section>
  );
}

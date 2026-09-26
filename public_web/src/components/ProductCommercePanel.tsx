"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabase";
import { ziyaretAnahtariniOkuyaUret } from "@/lib/vitrinZiyaretAnahtari";
import { addToVitrinCart } from "@/lib/vitrinCart";
import { recordVitrinEngagement } from "@/lib/vitrinEngagement";

type SocialComment = {
  id: string;
  author_name: string;
  body: string;
  created_at: string;
  can_delete?: boolean;
};

type SocialState = {
  like_count: number;
  liked: boolean;
  comment_count: number;
  comments: SocialComment[];
};

interface ProductCommercePanelProps {
  storeSlug: string;
  productSlug: string;
  productName: string;
  imageUrl?: string | null;
  priceText?: string | null;
  selectedVariantText?: string;
  selectedVariantId?: string | null;
  stockQuantity?: number | null;
  cartEnabled?: boolean;
  cartDisabledReason?: string;
  enabled?: boolean;
}

export default function ProductCommercePanel({
  storeSlug,
  productSlug,
  productName,
  imageUrl = null,
  priceText = null,
  selectedVariantText = "",
  selectedVariantId = null,
  stockQuantity = null,
  cartEnabled = true,
  cartDisabledReason = "",
  enabled = true,
}: ProductCommercePanelProps) {
  const [social, setSocial] = useState<SocialState>({
    like_count: 0,
    liked: false,
    comment_count: 0,
    comments: [],
  });
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
      const value = data as Partial<SocialState>;
      setSocial({
        like_count: Number(value.like_count) || 0,
        liked: value.liked === true,
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

  async function toggleLike() {
    if (busy) return;
    const {
      data: { session },
    } = await supabase.auth.getSession();
    if (!session || session.user.is_anonymous) {
      setMessage("Beğenmek için Google ile giriş yapmalısın.");
      return;
    }

    const sessionKey = ziyaretAnahtariniOkuyaUret();
    setBusy(true);
    setMessage("");
    try {
      const { data, error } = await supabase.rpc("toggle_product_like", {
        p_store_slug: storeSlug,
        p_product_slug: productSlug,
        p_session_key: sessionKey,
      });
      if (error) throw error;
      const value = (data ?? {}) as { liked?: boolean; like_count?: number };
      setSocial((current) => ({
        ...current,
        liked: value.liked === true,
        like_count: Number(value.like_count) || 0,
      }));
    } catch {
      setMessage("Beğeni şu anda kaydedilemedi.");
    } finally {
      setBusy(false);
    }
  }

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
        ...current,
        comment_count: Math.max(0, current.comment_count - 1),
        comments: current.comments.filter((item) => item.id !== commentId),
      }));
      setMessage("Yorumun silindi.");
    } catch {
      setMessage("Yorum silinemedi.");
    } finally {
      setBusy(false);
    }
  }

  async function addCart() {
    if (!cartEnabled || stockQuantity === 0) return;
    const variantKey = selectedVariantId?.trim() || selectedVariantText.trim() || "standart";
    addToVitrinCart(storeSlug, {
      productSlug,
      productName,
      variantKey,
      variantText: selectedVariantText.trim(),
      priceText: String(priceText || "").trim(),
      imageUrl,
      maxQuantity: stockQuantity,
      quantity: 1,
    });
    await recordVitrinEngagement({
      storeSlug,
      eventType: "cart_add",
      productSlug,
      quantity: 1,
      metadata: {
        variant: selectedVariantText.trim() || null,
        surface: "product",
      },
    });
    setMessage("Sepete eklendi.");
  }

  return (
    <section className="mt-5 rounded-2xl border border-white/10 bg-white/[0.03] p-4" aria-label="Ürün etkileşimleri">
      <div className="grid gap-2 sm:grid-cols-2">
        <button
          type="button"
          onClick={() => void toggleLike()}
          disabled={busy}
          aria-pressed={social.liked}
          className="min-h-11 rounded-xl border border-white/10 bg-slate-900 px-4 text-sm font-extrabold text-white disabled:opacity-60"
        >
          {social.liked ? "♥ Beğendin" : "♡ Beğen"} · {social.like_count}
        </button>
        <button
          type="button"
          onClick={() => void addCart()}
          disabled={!cartEnabled || stockQuantity === 0}
          className="min-h-11 rounded-xl bg-gradient-to-r from-blue-600 to-cyan-500 px-4 text-sm font-extrabold text-white disabled:cursor-not-allowed disabled:opacity-45"
        >
          {stockQuantity === 0 ? "Stokta yok" : "Sepete ekle"}
        </button>
      </div>

      {!cartEnabled && cartDisabledReason ? (
        <p className="mt-2 text-xs font-semibold leading-5 text-amber-200/80">{cartDisabledReason}</p>
      ) : null}

      <div className="mt-4 border-t border-white/10 pt-4">
        <div className="flex items-center justify-between gap-3">
          <h3 className="text-sm font-extrabold text-white">Yorumlar</h3>
          <span className="text-xs font-bold text-white/40">{social.comment_count}</span>
        </div>

        <div className="mt-3 flex gap-2">
          <input
            value={comment}
            maxLength={500}
            onChange={(event) => setComment(event.target.value)}
            placeholder="Ürün hakkında yorum yaz"
            className="min-h-11 min-w-0 flex-1 rounded-xl border border-white/10 bg-slate-950 px-3 text-sm text-white outline-none placeholder:text-white/35 focus:border-blue-500/50"
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
          <div className="mt-3 max-h-52 space-y-2 overflow-y-auto pr-1">
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
                      className="shrink-0 text-[10px] font-extrabold text-red-300 disabled:opacity-50"
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
      </div>

      {message ? <p className="mt-3 text-xs font-semibold text-blue-200" role="status">{message}</p> : null}
    </section>
  );
}

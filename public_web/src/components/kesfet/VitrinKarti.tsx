"use client";

import Link from "next/link";
import { useState } from "react";
import type { KesfetVitrini } from "@/lib/explore";

function waDigits(raw: string | null | undefined): string | null {
  const d = String(raw ?? "").replace(/[^0-9]/g, "");
  if (!d) return null;
  if (d.startsWith("0") && d.length === 11) return `90${d.slice(1)}`;
  if (d.startsWith("5") && d.length === 10) return `90${d}`;
  if (d.length >= 10) return d;
  return null;
}

function waUrl(digits: string, msg: string): string {
  return `https://wa.me/${digits}?text=${encodeURIComponent(msg)}`;
}

/**
 * Keşfet kartı — Flutter'daki `vitrin_store_card.dart`'ın web karşılığı.
 * Kiralık (örnek) vitrinlerde iki eylem var: "İncele" vitrini açar,
 * "Kirala" güvenli köprü sayfasına gider. Köprü ÖNEMLİ: `/api/rent-demo`
 * doğrudan çağrılmaz, reCAPTCHA doğrulaması `/rent-demo` sayfasında yapılır
 * (2026-08-15 güvenlik düzeltmesi, bkz. api/rent-demo/route.ts başlığı).
 */
export function VitrinKarti({ vitrin, isFavorited, onToggleFavorite, isOwnStore }: { vitrin: KesfetVitrini; isFavorited?: boolean; onToggleFavorite?: () => void; isOwnStore?: boolean }) {
  const [waOpen, setWaOpen] = useState(false);
  const digits = waDigits(vitrin.whatsapp);
  const vitrinSlug = vitrin.slug;
  const vitrinAd = vitrin.ad || "vitrininiz";

  const waOptions: Array<{ label: string; msg: string }> = [
    { label: "Ürün ve fiyat bilgisi", msg: `Merhaba, ${vitrinAd} hakkında ürün ve fiyat bilgisi almak istiyorum.` },
    { label: "Sipariş vermek istiyorum", msg: `Merhaba, ${vitrinAd} üzerinden sipariş vermek istiyorum.` },
    { label: "Adres ve çalışma saatleri", msg: `Merhaba, ${vitrinAd} için adres ve çalışma saatlerini öğrenmek istiyorum.` },
  ];

  return (
    <>
      <article className={`flex h-full flex-col overflow-hidden rounded-3xl border bg-lp-surface ${isOwnStore ? "border-lp-primary shadow-[0_0_0_1px_rgba(20,125,255,0.35)]" : "border-lp-border/70"}`}>
        <div className="relative block aspect-[4/3] w-full overflow-hidden bg-lp-surface-soft">
          <Link href={`/v/${vitrinSlug}`} className="absolute inset-0">
            {vitrin.kapakUrl ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img src={vitrin.kapakUrl} alt="" className="h-full w-full object-cover" loading="lazy" />
            ) : (
              <span className="flex h-full w-full items-center justify-center px-4 text-center text-[12px] font-bold text-lp-muted">Kapak görseli bekleniyor</span>
            )}
          </Link>

          {onToggleFavorite ? (
            <button
              type="button"
              onClick={(e) => { e.preventDefault(); e.stopPropagation(); onToggleFavorite(); }}
              aria-label={isFavorited ? "Favoriden çıkar" : "Favoriye ekle"}
              className="absolute right-2 top-2 flex h-9 w-9 items-center justify-center rounded-full border border-white/25 bg-black/45 text-white backdrop-blur-sm transition-colors hover:bg-black/60"
            >
              <svg width="18" height="18" viewBox="0 0 24 24" fill={isFavorited ? "#ff2e4d" : "none"} stroke={isFavorited ? "#ff2e4d" : "white"} strokeWidth="1.8" aria-hidden="true"><path d="M12 21s-6.5-4.2-8.2-8.2A5.2 5.2 0 0 1 12 5.2a5.2 5.2 0 0 1 8.2 7.6C18.5 16.8 12 21 12 21z"/></svg>
            </button>
          ) : null}

          {vitrin.kiralikMi ? (
            <span className="absolute left-3 top-3 rounded-full bg-amber-400 px-2.5 py-1 text-[10px] font-black tracking-[1px] text-lp-bg-editor">KİRALIK</span>
          ) : (
            <span className={`absolute left-3 top-3 rounded-full px-2.5 py-1 text-[10px] font-black tracking-[1px] ${vitrin.acikMi ? "bg-lp-mint text-lp-bg-editor" : "bg-lp-border text-lp-text-alt"}`}>{vitrin.acikMi ? "CANLI" : "KAPALI"}</span>
          )}

          {isOwnStore ? (
            <span className="absolute bottom-2 left-2 rounded-lg bg-lp-primary px-2 py-1 text-[10px] font-black text-white">Senin vitrinin</span>
          ) : null}
        </div>

        <div className="flex flex-1 flex-col gap-1 p-4">
          <p className="text-[10px] font-black uppercase tracking-[1px] text-lp-primary">{vitrin.kategoriEtiketi}</p>
          <h3 className="text-[15px] font-black leading-tight text-lp-text"><Link href={`/v/${vitrinSlug}`}>{vitrin.ad}</Link></h3>
          <p className="flex items-center gap-1 text-[12px] font-semibold text-lp-muted">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="#EF4444" aria-hidden="true"><path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z"/></svg>
            <span className="truncate">{vitrin.konum}</span>
          </p>

          {vitrin.kiralikMi ? (
            <p className="mt-1 flex flex-wrap items-baseline gap-1.5 text-[10px] font-semibold">
              <span className="text-[12px] font-black text-amber-400">Aylık 299 TL</span>
              <span className="text-[10px] font-semibold text-lp-muted">· 14 gün ücretsiz dene</span>
            </p>
          ) : vitrin.urunSayisi > 0 ? (
            <p className="mt-1 text-[12px] font-semibold text-lp-muted">{vitrin.urunSayisi} ürün</p>
          ) : null}

          <div className="mt-4 flex gap-2">
            {vitrin.kiralikMi ? (
              <>
                <Link href={`/v/${vitrinSlug}`} className="flex-1 rounded-xl border border-lp-border px-3 py-2.5 text-center text-[12px] font-black text-lp-text-alt transition-colors hover:bg-lp-surface-soft">İncele</Link>
                <Link href={`/rent-demo?slug=${vitrinSlug}`} className="flex-1 rounded-xl bg-lp-primary px-3 py-2.5 text-center text-[12px] font-black text-lp-on-primary transition-transform hover:-translate-y-0.5">Kirala</Link>
              </>
            ) : digits ? (
              <>
                <Link href={`/v/${vitrinSlug}`} className="flex-1 rounded-xl border border-lp-border px-3 py-2.5 text-center text-[12px] font-black text-lp-text-alt transition-colors hover:bg-lp-surface-soft">Vitrini gör</Link>
                <button type="button" onClick={() => setWaOpen(true)} className="flex-1 rounded-xl bg-[#00A884] px-3 py-2.5 text-center text-[12px] font-black text-white hover:bg-[#02916d]">WhatsApp</button>
              </>
            ) : (
              <Link href={`/v/${vitrinSlug}`} className="w-full rounded-xl border border-lp-border px-3 py-2.5 text-center text-[12px] font-black text-lp-text-alt transition-colors hover:bg-lp-surface-soft">Vitrini gör</Link>
            )}
          </div>
          {vitrin.kiralikMi ? <p className="mt-2 text-center text-[11px] font-semibold text-lp-muted">Giriş yapmazsan vitrinin geçici olur.</p> : null}
        </div>
      </article>

      {waOpen && digits ? (
        <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/50 p-4 sm:items-center" onClick={() => setWaOpen(false)}>
          <div className="w-full max-w-sm rounded-2xl border border-lp-border bg-lp-surface p-5" onClick={(e) => e.stopPropagation()}>
            <div className="flex items-center gap-3">
              <span className="flex h-10 w-10 items-center justify-center rounded-full bg-[#25D366]/15 text-[#25D366]"><svg width="20" height="20" viewBox="0 0 24 24" fill="#25D366" aria-hidden="true"><path d="M19.7 4.3A10 10 0 0 0 4.6 18.8L3 22l3.3-.9A10 10 0 1 0 19.7 4.3zM12 19a7 7 0 0 1-3.5-.9l-.3-.2-2 .5.5-2-.2-.3A7 7 0 1 1 12 19zm4.2-5.3c-.2-.1-1.4-.7-1.6-.8-.2-.1-.4-.1-.6.1-.2.2-.6.8-.8 1-.1.2-.3.2-.5.1-.2-.1-.9-.3-1.7-1-.6-.5-1-1.2-1.1-1.4-.1-.2 0-.3.1-.4l.4-.5c.1-.1.1-.2 0-.4l-.7-1.7c-.2-.4-.4-.4-.6-.4h-.5c-.2 0-.4.1-.6.4-.2.3-.7.7-.7 1.7s.7 2 0 2.8c.7 1 1.6 1.8 2.8 2.4.3.2.6.3.8.4.3.2.6.1.8 0 .2-.2.8-.8 1-1.1.2-.2.3-.2.5-.1l1.4.7c.2.1.3.1.4 0 .3-.2.4-.8.5-1.1 0-.2 0-.4-.1-.4z"/></svg></span>
              <div><p className="text-[13px] font-black text-lp-text">{vitrin.ad}</p><p className="text-[12px] font-semibold text-lp-muted">Hazır mesaj seçin:</p></div>
              <button type="button" onClick={() => setWaOpen(false)} className="ml-auto rounded-full p-1 text-lp-muted hover:bg-lp-surface-soft"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><path d="M18 6L6 18"/><path d="M6 6l12 12"/></svg></button>
            </div>
            <div className="mt-4 flex flex-col gap-2">
              {waOptions.map((o) => (
                <a key={o.label} href={waUrl(digits, o.msg)} target="_blank" rel="noopener noreferrer" className="flex items-center justify-between rounded-xl border border-lp-border bg-lp-surface-soft px-4 py-3 text-left text-[13px] font-bold text-lp-text hover:border-lp-primary">
                  <span>{o.label}</span><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M9 18l6-6-6-6"/></svg>
                </a>
              ))}
            </div>
          </div>
        </div>
      ) : null}
    </>
  );
}

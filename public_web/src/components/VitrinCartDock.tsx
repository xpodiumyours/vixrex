"use client";

import Image from "next/image";
import Link from "next/link";
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import {
  VITRIN_CART_EVENT,
  buildWhatsappOrderUrl,
  cartTotalAmount,
  cartTotalQuantity,
  readVitrinCart,
  removeFromVitrinCart,
  setVitrinCartQuantity,
  type VitrinCartItem,
} from "@/lib/vitrinCart";
import { recordVitrinEngagement } from "@/lib/vitrinEngagement";
import { tutarYazisi } from "@/lib/productCardPresentation";
import { vitrinGorunum } from "@/lib/vitrinGorunum";

const odakHalkasi =
  "focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-400";

interface VitrinCartDockProps {
  storeSlug: string;
  storeName: string;
  whatsappBaseUrl?: string | null;
  trackingEnabled?: boolean;
}

export default function VitrinCartDock({
  storeSlug,
  storeName,
  whatsappBaseUrl = null,
  trackingEnabled = true,
}: VitrinCartDockProps) {
  const [items, setItems] = useState<VitrinCartItem[]>([]);
  const [open, setOpen] = useState(false);
  const [message, setMessage] = useState("");
  const sheetRef = useRef<HTMLDivElement>(null);
  const triggerRef = useRef<HTMLButtonElement>(null);

  const kapat = useCallback(() => {
    setOpen(false);
    window.setTimeout(() => triggerRef.current?.focus(), 0);
  }, []);

  useEffect(() => {
    if (!open) return;
    const sheet = sheetRef.current;
    if (!sheet) return;

    const odaklanabilirler = () =>
      Array.from(
        sheet.querySelectorAll<HTMLElement>(
          'a[href], button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])',
        ),
      ).filter((el) => el.getClientRects().length > 0);

    const kapatDugmesi = sheet.querySelector<HTMLButtonElement>('button[aria-label="Sepeti kapat"]');
    (kapatDugmesi ?? sheet).focus();

    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        event.preventDefault();
        kapat();
        return;
      }
      if (event.key !== "Tab") return;
      const liste = odaklanabilirler();
      if (liste.length === 0) {
        event.preventDefault();
        sheet.focus();
        return;
      }
      const ilk = liste[0];
      const son = liste[liste.length - 1];
      const aktif = document.activeElement as HTMLElement | null;
      if (!aktif || !sheet.contains(aktif)) {
        event.preventDefault();
        ilk.focus();
        return;
      }
      if (event.shiftKey && aktif === ilk) {
        event.preventDefault();
        son.focus();
      } else if (!event.shiftKey && aktif === son) {
        event.preventDefault();
        ilk.focus();
      }
    };

    document.addEventListener("keydown", onKeyDown);
    return () => document.removeEventListener("keydown", onKeyDown);
  }, [open, kapat]);

  useEffect(() => {
    if (!trackingEnabled) return;
    const refresh = () => setItems(readVitrinCart(storeSlug).items);
    refresh();
    const listener = (event: Event) => {
      const detail = (event as CustomEvent<{ storeSlug?: string }>).detail;
      if (!detail?.storeSlug || detail.storeSlug === storeSlug) refresh();
    };
    window.addEventListener(VITRIN_CART_EVENT, listener);
    window.addEventListener("storage", refresh);
    return () => {
      window.removeEventListener(VITRIN_CART_EVENT, listener);
      window.removeEventListener("storage", refresh);
    };
  }, [storeSlug, trackingEnabled]);

  const totalQuantity = useMemo(() => cartTotalQuantity(items), [items]);
  const toplamTutar = useMemo(() => cartTotalAmount(items), [items]);
  if (!trackingEnabled || items.length === 0) return null;

  async function changeQuantity(item: VitrinCartItem, quantity: number) {
    const next = setVitrinCartQuantity(storeSlug, item.productSlug, item.variantKey, quantity);
    setItems(next);
    await recordVitrinEngagement({
      storeSlug,
      eventType: "cart_quantity_change",
      productSlug: item.productSlug,
      quantity,
      metadata: { variant: item.variantText || null },
    });
  }

  async function remove(item: VitrinCartItem) {
    const next = removeFromVitrinCart(storeSlug, item.productSlug, item.variantKey);
    setItems(next);
    await recordVitrinEngagement({
      storeSlug,
      eventType: "cart_remove",
      productSlug: item.productSlug,
      quantity: item.quantity,
      metadata: { variant: item.variantText || null },
    });
  }

  function order() {
    const url = buildWhatsappOrderUrl(whatsappBaseUrl, storeName, items);
    if (!url) {
      setMessage("Bu vitrinde WhatsApp sipariş bağlantısı hazır değil.");
      return;
    }

    const link = document.createElement("a");
    link.href = url;
    link.target = "_blank";
    link.rel = "noopener noreferrer";
    link.click();

    const orderKey =
      typeof crypto !== "undefined" && "randomUUID" in crypto
        ? crypto.randomUUID()
        : `${Date.now()}-${Math.random().toString(36).slice(2)}`;

    void Promise.all([
      ...items.map((item) =>
        recordVitrinEngagement({
          storeSlug,
          eventType: "cart_whatsapp_order",
          productSlug: item.productSlug,
          quantity: item.quantity,
          metadata: {
            order_key: orderKey,
            variant: item.variantText || null,
            item_count: items.length,
          },
        }),
      ),
      recordVitrinEngagement({
        storeSlug,
        eventType: "whatsapp_click",
        quantity: totalQuantity,
        metadata: { surface: "cart", order_key: orderKey },
      }),
    ]);
  }

  return (
    <>
      <button
        ref={triggerRef}
        type="button"
        onClick={() => setOpen(true)}
        className={`fixed bottom-5 left-4 z-[80] min-h-12 rounded-full border border-blue-400/30 bg-slate-950/95 px-4 text-sm font-extrabold text-white shadow-2xl backdrop-blur ${odakHalkasi}`}
        aria-label={`Sepeti aç, ${totalQuantity} ürün`}
      >
        Sepet · {totalQuantity}
        {toplamTutar != null ? ` · ${tutarYazisi(toplamTutar)}` : ""}
      </button>

      {open ? (
        <div className="fixed inset-0 z-[100] flex items-end bg-slate-950/75 backdrop-blur-sm sm:items-center sm:justify-center sm:p-5">
          <div
            ref={sheetRef}
            role="dialog"
            aria-modal="true"
            aria-labelledby="sepet-basligi"
            tabIndex={-1}
            className={`max-h-[88vh] w-full overflow-y-auto rounded-t-[28px] ${vitrinGorunum.yuzey.panel} p-5 text-white shadow-2xl sm:max-w-xl sm:rounded-[28px]`}
          >
            <div className="flex items-center justify-between gap-4">
              <div>
                <h2 id="sepet-basligi" className="text-lg font-black">Sipariş sepeti</h2>
                <p className="mt-1 text-xs font-semibold text-white/45">{totalQuantity} ürün · WhatsApp ile işletmeye gönderilir</p>
              </div>
              <button type="button" onClick={kapat} className={`h-10 w-10 rounded-full border border-white/10 text-lg ${odakHalkasi}`} aria-label="Sepeti kapat">×</button>
            </div>

            <div className="mt-4 space-y-3">
              {items.map((item) => (
                <article key={`${item.productSlug}-${item.variantKey}`} className="rounded-2xl border border-white/10 bg-white/[0.03] p-3">
                  <div className="flex gap-3">
                    {item.imageUrl ? (
                      <Link
                        href={`/v/${storeSlug}/urun/${item.productSlug}`}
                        onClick={() => setOpen(false)}
                        aria-label={`${item.productName} ürün sayfasına git`}
                        className="shrink-0 rounded-xl focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-400"
                      >
                        <Image
                          src={item.imageUrl}
                          alt=""
                          width={56}
                          height={56}
                          className="h-14 w-14 rounded-xl border border-white/10 object-cover"
                        />
                      </Link>
                    ) : null}
                    <div className="min-w-0 flex-1">
                      <Link
                        href={`/v/${storeSlug}/urun/${item.productSlug}`}
                        onClick={() => setOpen(false)}
                        className="inline-flex min-h-6 items-center rounded focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-400"
                      >
                        <h3 className="text-sm font-extrabold">{item.productName}</h3>
                      </Link>
                      {item.variantText ? <p className="mt-1 text-xs font-semibold text-blue-200">{item.variantText}</p> : null}
                      {item.priceText ? <p className={`mt-1 text-xs font-bold ${vitrinGorunum.metin.ikincil}`}>{item.priceText}</p> : null}
                    </div>
                    <button type="button" onClick={() => void remove(item)} className={`inline-flex min-h-6 items-center self-start text-xs font-bold ${vitrinGorunum.baglanti.sessiz} ${odakHalkasi}`}>Kaldır</button>
                  </div>
                  <div className="mt-3 flex items-center gap-2">
                    <button type="button" onClick={() => void changeQuantity(item, Math.max(1, item.quantity - 1))} disabled={item.quantity <= 1} className={`h-9 w-9 rounded-lg border border-white/10 disabled:cursor-not-allowed disabled:opacity-35 ${odakHalkasi}`} aria-label="Adedi azalt">−</button>
                    <span className="min-w-10 text-center text-sm font-black">{item.quantity}</span>
                    <button
                      type="button"
                      onClick={() => void changeQuantity(item, item.quantity + 1)}
                      disabled={item.maxQuantity != null && item.quantity >= item.maxQuantity}
                      className={`h-9 w-9 rounded-lg border border-white/10 disabled:cursor-not-allowed disabled:opacity-35 ${odakHalkasi}`}
                      aria-label="Adedi artır"
                    >
                      +
                    </button>
                    {item.maxQuantity != null && item.quantity >= item.maxQuantity ? (
                      <span className="ml-2 text-[10px] font-semibold text-amber-200/80">
                        Stok sınırı: en fazla {item.maxQuantity} adet
                      </span>
                    ) : null}
                    {item.priceAmount != null && item.quantity > 1 ? (
                      <span className="ml-auto text-sm font-black text-white">
                        {tutarYazisi(item.priceAmount * item.quantity)}
                      </span>
                    ) : null}
                  </div>
                </article>
              ))}
            </div>

            <button
              type="button"
              onClick={order}
              className={`mt-5 min-h-12 w-full rounded-xl px-5 text-sm font-black ${vitrinGorunum.buton.whatsappDolu} ${odakHalkasi}`}
            >
              {toplamTutar != null
                ? `WhatsApp’tan siparişi gönder · ${tutarYazisi(toplamTutar)}`
                : "WhatsApp’tan siparişi gönder"}
            </button>
            {message ? <p className="mt-3 text-xs font-semibold text-amber-200" role="status">{message}</p> : null}
            <p className="mt-3 text-[11px] leading-5 text-white/35">
              Vixrex siparişi otomatik olarak tamamlanmış saymaz; WhatsApp açılması ölçülür, son onay işletme ile müşteri arasındadır.
            </p>
          </div>
        </div>
      ) : null}
    </>
  );
}

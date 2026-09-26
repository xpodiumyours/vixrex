"use client";

import { useEffect, useMemo, useState } from "react";
import {
  VITRIN_CART_EVENT,
  buildWhatsappOrderUrl,
  cartTotalQuantity,
  readVitrinCart,
  removeFromVitrinCart,
  setVitrinCartQuantity,
  type VitrinCartItem,
} from "@/lib/vitrinCart";
import { recordVitrinEngagement } from "@/lib/vitrinEngagement";

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
        type="button"
        onClick={() => setOpen(true)}
        className="fixed bottom-5 left-4 z-[80] min-h-12 rounded-full border border-blue-400/30 bg-slate-950/95 px-4 text-sm font-extrabold text-white shadow-2xl backdrop-blur"
        aria-label={`Sepeti aç, ${totalQuantity} ürün`}
      >
        Sepet · {totalQuantity}
      </button>

      {open ? (
        <div className="fixed inset-0 z-[100] flex items-end bg-slate-950/75 backdrop-blur-sm sm:items-center sm:justify-center sm:p-5">
          <div className="max-h-[88vh] w-full overflow-y-auto rounded-t-[28px] border border-white/10 bg-[#0b1120] p-5 text-white shadow-2xl sm:max-w-xl sm:rounded-[28px]">
            <div className="flex items-center justify-between gap-4">
              <div>
                <h2 className="text-lg font-black">Sipariş sepeti</h2>
                <p className="mt-1 text-xs font-semibold text-white/45">{totalQuantity} ürün · WhatsApp ile işletmeye gönderilir</p>
              </div>
              <button type="button" onClick={() => setOpen(false)} className="h-10 w-10 rounded-full border border-white/10 text-lg" aria-label="Sepeti kapat">×</button>
            </div>

            <div className="mt-4 space-y-3">
              {items.map((item) => (
                <article key={`${item.productSlug}-${item.variantKey}`} className="rounded-2xl border border-white/10 bg-white/[0.03] p-3">
                  <div className="flex gap-3">
                    <div className="min-w-0 flex-1">
                      <h3 className="text-sm font-extrabold">{item.productName}</h3>
                      {item.variantText ? <p className="mt-1 text-xs font-semibold text-blue-200">{item.variantText}</p> : null}
                      {item.priceText ? <p className="mt-1 text-xs font-bold text-white/45">{item.priceText}</p> : null}
                    </div>
                    <button type="button" onClick={() => void remove(item)} className="self-start text-xs font-bold text-red-300">Kaldır</button>
                  </div>
                  <div className="mt-3 flex items-center gap-2">
                    <button type="button" onClick={() => void changeQuantity(item, Math.max(1, item.quantity - 1))} className="h-9 w-9 rounded-lg border border-white/10" aria-label="Adedi azalt">−</button>
                    <span className="min-w-10 text-center text-sm font-black">{item.quantity}</span>
                    <button
                      type="button"
                      onClick={() => void changeQuantity(item, item.quantity + 1)}
                      disabled={item.maxQuantity != null && item.quantity >= item.maxQuantity}
                      className="h-9 w-9 rounded-lg border border-white/10 disabled:cursor-not-allowed disabled:opacity-35"
                      aria-label="Adedi artır"
                    >
                      +
                    </button>
                    {item.maxQuantity != null ? (
                      <span className="ml-2 text-[10px] font-semibold text-white/35">
                        Stok sınırı: {item.maxQuantity}
                      </span>
                    ) : null}
                  </div>
                </article>
              ))}
            </div>

            <button
              type="button"
              onClick={order}
              className="mt-5 min-h-12 w-full rounded-xl bg-[#25D366] px-5 text-sm font-black text-[#04140a]"
            >
              WhatsApp’tan siparişi gönder
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

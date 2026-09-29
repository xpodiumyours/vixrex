"use client";

import { useState, type FormEvent } from "react";

interface SiparisPaneliProps {
  storeSlug: string;
  productSlug: string;
  productName: string;
  priceKurus: number | null;
  isService?: boolean;
}

interface SiparisSonuc {
  amountKurus: number;
  whatsappUrl: string | null;
  paymentLink: string | null;
  paymentUnavailable: boolean;
}

const ODAK = "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-400/70";

function kurusMetni(kurus: number): string {
  const tam = Math.floor(kurus / 100);
  const kurusKisim = kurus % 100;
  return kurusKisim === 0
    ? `${tam} TL`
    : `${tam},${kurusKisim.toString().padStart(2, "0")} TL`;
}

export default function SiparisPaneli({
  storeSlug,
  productSlug,
  productName,
  priceKurus,
  isService = false,
}: SiparisPaneliProps) {
  const [acik, setAcik] = useState(false);
  const [adet, setAdet] = useState(1);
  const [isim, setIsim] = useState("");
  const [telefon, setTelefon] = useState("");
  const [not, setNot] = useState("");
  const [teslim, setTeslim] = useState<"pickup" | "delivery">("pickup");
  const [odeme, setOdeme] = useState<"cash" | "online">("cash");
  const [gonderiliyor, setGonderiliyor] = useState(false);
  const [hata, setHata] = useState("");
  const [sonuc, setSonuc] = useState<SiparisSonuc | null>(null);

  if (priceKurus === null || priceKurus <= 0) return null;

  const toplamKurus = priceKurus * adet;

  async function gonder(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setHata("");
    setGonderiliyor(true);
    try {
      const yanit = await fetch("/api/orders", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({
          storeSlug,
          customerName: isim,
          customerPhone: telefon,
          customerNote: not,
          fulfillment: teslim,
          paymentMethod: odeme,
          items: [{ productSlug, quantity: adet }],
        }),
      });
      const govde = await yanit.json().catch(() => null);
      if (!yanit.ok || !govde?.tamam) {
        setHata(govde?.hata ?? "Sipariş oluşturulamadı. Lütfen tekrar dene.");
        return;
      }
      setSonuc({
        amountKurus: govde.amountKurus ?? 0,
        whatsappUrl: govde.whatsappUrl ?? null,
        paymentLink: govde.paymentLink ?? null,
        paymentUnavailable: Boolean(govde.paymentUnavailable),
      });
    } catch {
      setHata("Bağlantı kurulamadı. Lütfen tekrar dene.");
    } finally {
      setGonderiliyor(false);
    }
  }

  if (sonuc) {
    return (
      <div className="mt-4 rounded-2xl border border-emerald-400/25 bg-emerald-500/10 p-4">
        <p className="text-sm font-extrabold text-emerald-300">
          Siparişin alındı — toplam {kurusMetni(sonuc.amountKurus)}
        </p>
        <p className="mt-1 text-xs font-medium leading-5 text-white/60">
          {isService
            ? "Hizmet talebin işletmeye iletildi."
            : "Siparişin işletmeye iletildi."}{" "}
          Onay için WhatsApp üzerinden yazman yeterli.
        </p>
        <div className="mt-3 grid gap-2 sm:grid-cols-2">
          {sonuc.whatsappUrl ? (
            <a
              href={sonuc.whatsappUrl}
              target="_blank"
              rel="noopener noreferrer"
              className={`flex min-h-12 items-center justify-center rounded-xl bg-[#25D366] px-5 text-center text-sm font-extrabold text-[#04140a] ${ODAK}`}
            >
              WhatsApp&apos;tan siparişi gönder
            </a>
          ) : null}
          {sonuc.paymentLink ? (
            <a
              href={sonuc.paymentLink}
              target="_blank"
              rel="noopener noreferrer"
              className={`flex min-h-12 items-center justify-center rounded-xl bg-blue-600 px-5 text-center text-sm font-extrabold text-white ${ODAK}`}
            >
              Online öde
            </a>
          ) : null}
        </div>
        {odeme === "online" && sonuc.paymentUnavailable ? (
          <p className="mt-2 text-xs font-semibold text-amber-300">
            Online ödeme henüz aktif değil — siparişin yine de alındı, ödemeyi
            kapıda yapabilirsin.
          </p>
        ) : null}
      </div>
    );
  }

  return (
    <div className="mt-4">
      <button
        type="button"
        onClick={() => setAcik((acikMi) => !acikMi)}
        aria-expanded={acik}
        className={`flex min-h-12 w-full items-center justify-center rounded-xl bg-gradient-to-r from-blue-600 to-cyan-600 px-5 text-sm font-extrabold text-white ${ODAK}`}
      >
        {acik ? "Siparişi kapat" : isService ? "Hizmet için sipariş ver" : "Sipariş ver"}
      </button>

      {acik ? (
        <form
          onSubmit={gonder}
          className="mt-3 rounded-2xl border border-white/10 bg-white/[0.03] p-4"
        >
          <label
            htmlFor="siparis-adet"
            className="block text-[11px] font-extrabold uppercase tracking-wider text-white/40"
          >
            Adet
          </label>
          <input
            id="siparis-adet"
            type="number"
            min={1}
            max={99}
            required
            value={adet}
            onChange={(event) => setAdet(Math.min(99, Math.max(1, Number(event.target.value) || 1)))}
            className={`mt-1 w-full rounded-lg border border-white/10 bg-[#0D1C38] px-3 py-2 text-sm font-semibold text-white ${ODAK}`}
          />

          <label
            htmlFor="siparis-isim"
            className="mt-3 block text-[11px] font-extrabold uppercase tracking-wider text-white/40"
          >
            Adın
          </label>
          <input
            id="siparis-isim"
            type="text"
            required
            minLength={2}
            maxLength={120}
            value={isim}
            onChange={(event) => setIsim(event.target.value)}
            className={`mt-1 w-full rounded-lg border border-white/10 bg-[#0D1C38] px-3 py-2 text-sm font-semibold text-white ${ODAK}`}
          />

          <label
            htmlFor="siparis-telefon"
            className="mt-3 block text-[11px] font-extrabold uppercase tracking-wider text-white/40"
          >
            Telefon
          </label>
          <input
            id="siparis-telefon"
            type="tel"
            required
            minLength={10}
            maxLength={20}
            value={telefon}
            onChange={(event) => setTelefon(event.target.value)}
            className={`mt-1 w-full rounded-lg border border-white/10 bg-[#0D1C38] px-3 py-2 text-sm font-semibold text-white ${ODAK}`}
          />

          <label
            htmlFor="siparis-not"
            className="mt-3 block text-[11px] font-extrabold uppercase tracking-wider text-white/40"
          >
            Not (isteğe bağlı)
          </label>
          <textarea
            id="siparis-not"
            maxLength={500}
            rows={2}
            value={not}
            onChange={(event) => setNot(event.target.value)}
            className={`mt-1 w-full rounded-lg border border-white/10 bg-[#0D1C38] px-3 py-2 text-sm font-semibold text-white ${ODAK}`}
          />

          <fieldset className="mt-3">
            <legend className="text-[11px] font-extrabold uppercase tracking-wider text-white/40">
              Teslim ve ödeme
            </legend>
            <div className="mt-2 grid gap-2 sm:grid-cols-2">
              <label className={`flex cursor-pointer items-center gap-2 rounded-lg border border-white/10 px-3 py-2 text-xs font-bold text-white/75 ${ODAK}`}>
                <input
                  type="radio"
                  name="teslim"
                  checked={teslim === "pickup"}
                  onChange={() => setTeslim("pickup")}
                />
                Gel-al
              </label>
              <label className={`flex cursor-pointer items-center gap-2 rounded-lg border border-white/10 px-3 py-2 text-xs font-bold text-white/75 ${ODAK}`}>
                <input
                  type="radio"
                  name="teslim"
                  checked={teslim === "delivery"}
                  onChange={() => setTeslim("delivery")}
                />
                Kurye ile teslim
              </label>
              <label className={`flex cursor-pointer items-center gap-2 rounded-lg border border-white/10 px-3 py-2 text-xs font-bold text-white/75 ${ODAK}`}>
                <input
                  type="radio"
                  name="odeme"
                  checked={odeme === "cash"}
                  onChange={() => setOdeme("cash")}
                />
                Kapıda ödeme
              </label>
              <label className={`flex cursor-pointer items-center gap-2 rounded-lg border border-white/10 px-3 py-2 text-xs font-bold text-white/75 ${ODAK}`}>
                <input
                  type="radio"
                  name="odeme"
                  checked={odeme === "online"}
                  onChange={() => setOdeme("online")}
                />
                Online ödeme
              </label>
            </div>
          </fieldset>

          <div className="mt-4 flex items-center justify-between rounded-xl border border-white/10 bg-white/[0.04] px-4 py-3">
            <span className="text-xs font-bold text-white/50">Toplam</span>
            <span className="text-base font-extrabold text-white">
              {kurusMetni(toplamKurus)}
            </span>
          </div>

          {hata ? (
            <p className="mt-3 rounded-lg border border-red-400/30 bg-red-500/10 px-3 py-2 text-xs font-bold text-red-300" role="alert">
              {hata}
            </p>
          ) : null}

          <button
            type="submit"
            disabled={gonderiliyor}
            className={`mt-4 flex min-h-12 w-full items-center justify-center rounded-xl bg-[#25D366] px-5 text-sm font-extrabold text-[#04140a] disabled:opacity-60 ${ODAK}`}
          >
            {gonderiliyor ? "Gönderiliyor..." : `${productName} siparişini ver`}
          </button>
        </form>
      ) : null}
    </div>
  );
}

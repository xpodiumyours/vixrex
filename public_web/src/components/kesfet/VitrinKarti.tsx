"use client";

import Link from "next/link";
import { useRef, useState } from "react";
import type { KesfetVitrini } from "@/lib/explore";

export type PremiumBilgisi = {
  aktif: boolean;
  bitis: string | null;
};

function whatsappNumarasi(ham: string | null): string | null {
  const rakamlar = String(ham ?? "").replace(/[^0-9]/g, "");
  if (rakamlar.startsWith("0") && rakamlar.length === 11) {
    return `90${rakamlar.slice(1)}`;
  }
  if (rakamlar.startsWith("5") && rakamlar.length === 10) {
    return `90${rakamlar}`;
  }
  return rakamlar.length >= 10 ? rakamlar : null;
}

function whatsappEtiketi(vitrin: KesfetVitrini): string {
  const kategori = vitrin.kategoriEtiketi.toLocaleLowerCase("tr-TR");
  return ["kuaför", "güzellik", "hizmet", "servis", "klinik", "danışmanlık"].some(
    (kelime) => kategori.includes(kelime)
  )
    ? "WhatsApp İletişim"
    : "WhatsApp Sipariş";
}

function premiumEtiketi(premium: PremiumBilgisi | null): string | null {
  if (!premium) return null;
  if (!premium.aktif) return "Premium değil · Aylık 299 TL ile yayınla";
  if (!premium.bitis) return "Premium aktif";
  const bitis = Date.parse(premium.bitis);
  if (!Number.isFinite(bitis)) return "Premium aktif";
  const gun = Math.floor((bitis - Date.now()) / 86_400_000);
  if (gun <= 0) return "Premium aktif · bugün bitiyor";
  return `Premium aktif · ${gun} gün kaldı`;
}

function WhatsappIkonu() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
      <path d="M19.7 4.3A10 10 0 0 0 4.6 18.8L3 22l3.3-.9A10 10 0 1 0 19.7 4.3zM12 19a7 7 0 0 1-3.5-.9l-.3-.2-2 .5.5-2-.2-.3A7 7 0 1 1 12 19zm4.2-5.3c-.2-.1-1.4-.7-1.6-.8-.2-.1-.4-.1-.6.1-.2.2-.6.8-.8 1-.1.2-.3.2-.5.1-.2-.1-.9-.3-1.7-1-.6-.5-1-1.2-1.1-1.4-.1-.2 0-.3.1-.4l.4-.5c.1-.1.1-.2 0-.4l-.7-1.7c-.2-.4-.4-.4-.6-.4h-.5c-.2 0-.4.1-.6.4-.2.3-.7.7-.7 1.7s.7 2 2 2.8c.7 1 1.6 1.8 2.8 2.4.3.2.6.3.8.4.3.2.6.1.8 0 .2-.2.8-.8 1-1.1.2-.2.3-.2.5-.1l1.4.7c.2.1.3.1.4 0 .3-.2.4-.8.5-1.1 0-.2 0-.4-.1-.4z" />
    </svg>
  );
}

export function VitrinKarti({
  vitrin,
  favoriMi = false,
  favoriyiDegistir,
  sahipMi = false,
  premium = null,
}: {
  vitrin: KesfetVitrini;
  favoriMi?: boolean;
  favoriyiDegistir?: () => void;
  sahipMi?: boolean;
  premium?: PremiumBilgisi | null;
}) {
  const dialogRef = useRef<HTMLDialogElement>(null);
  const [whatsappHatasi, setWhatsappHatasi] = useState("");
  const numara = whatsappNumarasi(vitrin.whatsapp);
  const premiumMetni = sahipMi ? premiumEtiketi(premium) : null;
  const vitrinAdi = vitrin.ad.trim() || "vitrininiz";
  const mesajlar = [
    {
      etiket: "Ürün ve fiyat bilgisi",
      metin: `Merhaba, ${vitrinAdi} vitrininiz hakkında ürün ve fiyat bilgisi almak istiyorum.`,
    },
    {
      etiket: "Sipariş vermek istiyorum",
      metin: `Merhaba, ${vitrinAdi} vitrininiz üzerinden sipariş vermek istiyorum.`,
    },
    {
      etiket: "Adres ve çalışma saatleri",
      metin: `Merhaba, ${vitrinAdi} vitrininiz için adres ve çalışma saatlerini öğrenmek istiyorum.`,
    },
  ];

  function whatsappPaneliniAc() {
    setWhatsappHatasi("");
    if (!numara) {
      setWhatsappHatasi("Geçerli bir WhatsApp numarası bulunamadı.");
      return;
    }
    dialogRef.current?.showModal();
  }

  return (
    <>
      <article
        className={`group flex min-h-[280px] h-full flex-col overflow-hidden rounded-[18px] border bg-lp-surface shadow-[0_8px_16px_rgba(0,0,0,0.28)] transition duration-200 ease-out hover:scale-[1.015] hover:shadow-[0_12px_24px_rgba(0,0,0,0.2)] motion-reduce:transform-none ${
          sahipMi
            ? "border-2 border-lp-primary shadow-[0_0_14px_rgba(20,125,255,0.2)]"
            : "border-lp-border"
        }`}
      >
        <div className="relative min-h-0 flex-[4] overflow-hidden bg-gradient-to-br from-lp-surface-soft to-lp-bg-editor">
          <Link href={`/v/${vitrin.slug}`} className="absolute inset-0 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-lp-primary">
            {vitrin.kapakUrl ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img
                src={vitrin.kapakUrl}
                alt={`${vitrin.ad} vitrin kapak görseli`}
                className="h-full w-full object-cover"
                loading="lazy"
              />
            ) : (
              <span className="flex h-full flex-col items-center justify-center gap-2 px-3 text-center text-lp-muted">
                <svg width="34" height="34" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" aria-hidden="true">
                  <path d="M3 10.5 12 4l9 6.5V20H3z" />
                  <path d="M8 20v-6h8v6" />
                </svg>
                <span className="text-[10px] font-bold">Kapak görseli bekleniyor</span>
              </span>
            )}
            <span className="absolute inset-0 bg-gradient-to-b from-black/15 via-transparent to-lp-surface/90" aria-hidden="true" />
          </Link>

          {vitrin.kiralikMi ? (
            <span className="absolute -left-8 top-3 w-28 -rotate-45 bg-amber-500 py-1 text-center text-[9px] font-black tracking-[0.8px] text-stone-900">
              KİRALIK
            </span>
          ) : (
            <span className="absolute left-2.5 top-2.5 flex items-center gap-1 rounded-full border border-white/20 bg-black/60 px-2 py-1 text-[9px] font-black tracking-[0.5px]">
              <span className={`h-1.5 w-1.5 rounded-full ${vitrin.acikMi ? "bg-lp-mint" : "bg-red-400"}`} aria-hidden="true" />
              <span className={vitrin.acikMi ? "text-lp-mint" : "text-red-400"}>
                {vitrin.acikMi ? "CANLI" : "KAPALI"}
              </span>
            </span>
          )}

          {sahipMi ? (
            <span className="absolute bottom-2 left-2.5 rounded-lg border border-lp-primary bg-lp-primary px-2 py-1 text-[9px] font-black text-lp-on-primary">
              Senin vitrinin
            </span>
          ) : null}

          {favoriyiDegistir ? (
            <button
              type="button"
              onClick={favoriyiDegistir}
              aria-label={favoriMi ? `${vitrin.ad} favorilerden çıkar` : `${vitrin.ad} favorilere ekle`}
              aria-pressed={favoriMi}
              className="absolute right-1.5 top-1.5 flex h-11 w-11 items-center justify-center rounded-full border border-white/25 bg-black/45 text-white backdrop-blur-sm transition-colors hover:bg-black/65 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white"
            >
              <svg width="18" height="18" viewBox="0 0 24 24" fill={favoriMi ? "#ff5252" : "none"} stroke={favoriMi ? "#ff5252" : "currentColor"} strokeWidth="1.8" aria-hidden="true">
                <path d="M12 21s-6.5-4.2-8.2-8.2A5.2 5.2 0 0 1 12 5.2a5.2 5.2 0 0 1 8.2 7.6C18.5 16.8 12 21 12 21z" />
              </svg>
            </button>
          ) : null}
        </div>

        <div className="flex flex-[3] flex-col p-3">
          <p className="truncate text-[9px] font-black uppercase tracking-[0.6px] text-lp-primary">
            {vitrin.kategoriEtiketi}
          </p>
          <h3 className="mt-1 truncate text-[15px] font-black leading-[1.15] text-lp-text">
            <Link href={`/v/${vitrin.slug}`} className="rounded focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-lp-primary">
              {vitrin.ad}
            </Link>
          </h3>
          <p className="mt-1 flex min-w-0 items-center gap-1 text-[10px] font-semibold text-lp-muted">
            <svg className="shrink-0 text-red-400" width="13" height="13" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
              <path d="M12 2C8.1 2 5 5.1 5 9c0 5.3 7 13 7 13s7-7.7 7-13c0-3.9-3.1-7-7-7zm0 9.5A2.5 2.5 0 1 1 12 6a2.5 2.5 0 0 1 0 5.5z" />
            </svg>
            <span className="truncate">{vitrin.konum}</span>
          </p>

          {!vitrin.kiralikMi && vitrin.urunSayisi > 0 ? (
            <p className="mt-2 text-[10px] font-semibold text-lp-muted">{vitrin.urunSayisi} ürün</p>
          ) : null}

          {vitrin.kiralikMi ? (
            <p className="mt-2 flex min-w-0 items-baseline gap-1.5">
              <span className="shrink-0 text-[12px] font-black text-amber-500">Aylık 299 TL</span>
              <span className="truncate text-[10px] font-semibold text-lp-muted">· 14 gün ücretsiz dene</span>
            </p>
          ) : null}

          {premiumMetni ? (
            <p className="mt-2 flex min-w-0 items-center gap-1 text-[10px] font-bold text-amber-600">
              <svg className="shrink-0" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
                <path d="m12 2 3 6 6.5 1-4.7 4.6 1.1 6.4L12 17l-5.9 3 1.1-6.4L2.5 9 9 8z" />
              </svg>
              <span className="truncate">{premiumMetni}</span>
            </p>
          ) : null}

          <div className="mt-auto pt-3">
            {vitrin.kiralikMi ? (
              <div className="grid grid-cols-2 gap-1.5">
                <Link href={`/v/${vitrin.slug}`} className="flex min-h-11 items-center justify-center rounded-[10px] border border-lp-primary px-2 text-[11px] font-black text-lp-primary transition-colors hover:bg-lp-surface-soft focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-lp-primary">
                  İncele
                </Link>
                <Link href={`/rent-demo?slug=${encodeURIComponent(vitrin.slug)}`} className="flex min-h-11 items-center justify-center rounded-[10px] bg-lp-primary px-2 text-[11px] font-black text-lp-on-primary transition-colors hover:brightness-110 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-lp-primary focus-visible:ring-offset-2">
                  Kirala
                </Link>
              </div>
            ) : (
              <button
                type="button"
                onClick={whatsappPaneliniAc}
                className="flex min-h-11 w-full items-center justify-center gap-2 rounded-[10px] bg-[#00A884] px-2 text-[11px] font-black text-white transition-colors hover:bg-[#02916d] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#00A884] focus-visible:ring-offset-2"
              >
                <WhatsappIkonu />
                {whatsappEtiketi(vitrin)}
              </button>
            )}
            {whatsappHatasi ? (
              <p className="mt-2 text-[10px] font-bold text-red-500" role="alert">{whatsappHatasi}</p>
            ) : null}
          </div>
        </div>
      </article>

      <dialog
        ref={dialogRef}
        aria-labelledby={`whatsapp-baslik-${vitrin.slug}`}
        onClick={(event) => {
          if (event.target === event.currentTarget) event.currentTarget.close();
        }}
        className="m-auto w-[calc(100%-2rem)] max-w-sm rounded-2xl border border-lp-border bg-lp-surface p-0 text-lp-text shadow-2xl backdrop:bg-black/60"
      >
        <div className="p-5">
          <div className="flex items-start gap-3">
            <span className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-[#25D366]/15 text-[#25D366]" aria-hidden="true">
              <WhatsappIkonu />
            </span>
            <div className="min-w-0">
              <h2 id={`whatsapp-baslik-${vitrin.slug}`} className="truncate text-[14px] font-black">{vitrin.ad}</h2>
              <p className="mt-1 text-[12px] font-semibold text-lp-muted">Hazır mesaj seçin:</p>
            </div>
            <button
              type="button"
              onClick={() => dialogRef.current?.close()}
              aria-label="WhatsApp mesaj panelini kapat"
              className="ml-auto flex h-11 w-11 shrink-0 items-center justify-center rounded-full text-lp-muted hover:bg-lp-surface-soft focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-lp-primary"
            >
              <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" aria-hidden="true">
                <path d="M18 6 6 18M6 6l12 12" />
              </svg>
            </button>
          </div>
          <div className="mt-4 flex flex-col gap-2">
            {numara
              ? mesajlar.map((mesaj) => (
                  <a
                    key={mesaj.etiket}
                    href={`https://wa.me/${numara}?text=${encodeURIComponent(mesaj.metin)}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    onClick={() => dialogRef.current?.close()}
                    className="flex min-h-12 items-center justify-between gap-3 rounded-xl border border-lp-border bg-lp-surface-soft px-4 py-3 text-[13px] font-bold text-lp-text transition-colors hover:border-lp-primary focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-lp-primary"
                  >
                    <span>{mesaj.etiket}</span>
                    <svg className="shrink-0" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
                      <path d="m9 18 6-6-6-6" />
                    </svg>
                  </a>
                ))
              : null}
          </div>
        </div>
      </dialog>
    </>
  );
}

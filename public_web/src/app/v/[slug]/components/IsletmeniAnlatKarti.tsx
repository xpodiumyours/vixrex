"use client";

import { useState } from "react";

interface Props {
  gonderiliyor: boolean;
  onGonder: (metin: string) => void;
  onVazgec: () => void;
}

const ORNEK_YER_TUTUCU =
  "Örn: Kadıköy'de bir kuaförüz, WhatsApp'tan 0532 123 45 67'den ulaşılıyoruz, " +
  "hafta içi 09:00 - 19:00 arası açığız, Bahariye Cad. No:12'deyiz.";

const MIN_UZUNLUK = 10;

/**
 * "İşletmeni anlat" kartı — serbest metinden alan çıkarımının (bkz.
 * serbestMetinCikarim.ts) giriş yüzeyi. Panelin ana kaydırma gövdesinde
 * (StageMeter ile UpNextList arasında) yaşar — SpotlightGuide'ın balonuyla
 * KARIŞTIRILMAMALI: o tek bir VITRIN_FIELD'ın değerini düzenler, bu ise
 * tek seferlik, birden çok alana yayılan bir anlatım girişidir; iki farklı
 * şey aynı yerde durmuyor diye eskiden yaşanan "kutucuklar kopuk" sorunuyla
 * (bkz. OwnerAssistantPanel.tsx'teki StepCard yorum tarihçesi) aynı hataya
 * düşülmüyor — burada ikinci bir alan-düzenleme kutusu YOK, tek seferlik
 * bir giriş var.
 */
export function IsletmeniAnlatKarti({ gonderiliyor, onGonder, onVazgec }: Props) {
  const [metin, setMetin] = useState("");
  const gonderilebilir = metin.trim().length >= MIN_UZUNLUK && !gonderiliyor;

  return (
    <div className="border-t border-white/10 px-4 py-3 space-y-2">
      <p className="text-[11px] font-semibold text-white/40 uppercase tracking-wider">
        İşletmeni Anlat
      </p>
      <textarea
        value={metin}
        onChange={(e) => setMetin(e.target.value)}
        placeholder={ORNEK_YER_TUTUCU}
        rows={4}
        disabled={gonderiliyor}
        className="w-full rounded-xl border border-white/10 bg-white/[0.04] px-3 py-2.5 text-[13px] leading-relaxed text-slate-100 placeholder:text-white/30 outline-none focus:border-blue-400/50 disabled:opacity-60"
      />
      <div className="flex items-center gap-2">
        <button
          type="button"
          onClick={() => gonderilebilir && onGonder(metin.trim())}
          disabled={!gonderilebilir}
          className="flex min-h-10 flex-1 items-center justify-center rounded-xl bg-blue-600 px-3 text-[12px] font-black text-white transition-colors hover:bg-blue-500 disabled:opacity-40"
        >
          {gonderiliyor ? "Okuyorum…" : "Gönder"}
        </button>
        <button
          type="button"
          onClick={onVazgec}
          disabled={gonderiliyor}
          className="flex min-h-10 items-center justify-center px-3 text-[11px] font-bold text-white/40 hover:text-white/70 disabled:opacity-40"
        >
          Tek tek sormanı istiyorum
        </button>
      </div>
    </div>
  );
}

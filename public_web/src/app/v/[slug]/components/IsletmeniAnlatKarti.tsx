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
 * serbestMetinCikarim.ts) giriş yüzeyi. Panel açılınca kendiliğinden,
 * doğrudan burada belirir — bir sohbet balonu + tıklama aracılığıyla DEĞİL
 * (aracı bir mesaj olsaydı göz sohbet akışı ile kartın gerçek konumu
 * arasında zıplardı, tıpkı StepCard'ın 2026-08-22'de kaldırılma
 * sebebiyle aynı hata — bkz. OwnerAssistantPanel.tsx'teki o yorum).
 * Bu yüzden açıklama metni burada, kartın kendisinde.
 *
 * SpotlightGuide'ın balonuyla KARIŞTIRILMAMALI: o tek bir VITRIN_FIELD'ın
 * değerini düzenler, bu ise tek seferlik, birden çok alana yayılan bir
 * anlatım girişidir — ikinci bir alan-düzenleme kutusu değil.
 */
export function IsletmeniAnlatKarti({ gonderiliyor, onGonder, onVazgec }: Props) {
  const [metin, setMetin] = useState("");
  const gonderilebilir = metin.trim().length >= MIN_UZUNLUK && !gonderiliyor;

  return (
    <div className="border-t border-white/10 px-4 py-3 space-y-2">
      <div className="flex items-start gap-2.5">
        <span className="text-base leading-none" aria-hidden="true">📝</span>
        <div>
          <p className="text-[13px] font-black text-white">İşletmeni anlat</p>
          <p className="mt-0.5 text-[11px] leading-relaxed text-white/50">
            WhatsApp numaranı, çalışma saatlerini, adresini ve ne iş yaptığını
            birkaç cümleyle yazarsan bulabildiklerimi otomatik dolduruyorum.
          </p>
        </div>
      </div>
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

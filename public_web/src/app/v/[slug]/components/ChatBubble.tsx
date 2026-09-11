"use client";

import { useState } from "react";
import type { Mesaj } from "../hooks/useOwnerChat";

interface Props {
  mesaj: Mesaj;
  /**
   * Faz C2 (Tek Asistan planı, 2026-09-02): hızlı cevap düğmesine
   * tıklanınca payload'ı çağırana bildirir. Flutter'daki
   * `VixRexQuickReplies.onTap` ile aynı fikir — hangi payload'ın ne
   * yapacağına burası değil, çağıran taraf karar verir (bkz.
   * assistantHandoff.ts'teki QuickReply yorumu). Callback verilmezse
   * düğmeler yine görünür, tıklama sessizce hiçbir şey yapmaz.
   */
  onHizliCevap?: (payload: string, label: string) => void;
}

// Faz A parite (Tek Asistan planı, G3.1): Flutter'ın `ChatBubble`'ıyla aynı
// dile geçti — 14px (text-sm) her iki tarafta eşit, kullanıcı balonundan
// renk kaldırıldı (gradyan yalnız yayınlama düğmesinde kalır). Ayrım artık
// köşe yönünden geliyor: bot sol-alt köşesi kırık, kullanıcı sağ-alt.
const UZUN_MESAJ_SATIRI = 6;

export function ChatBubble({ mesaj, onHizliCevap }: Props) {
  const botMu = mesaj.kimden === "asistan";
  const hizliCevaplar = mesaj.hizliCevaplar ?? [];
  const sistemIkon = mesaj.sistemIkon;
  const [genisletildi, setGenisletildi] = useState(false);
  const satirlar = mesaj.metin.split("\n");
  const uzunMu = satirlar.length > UZUN_MESAJ_SATIRI;
  const gosterilenMetin =
    uzunMu && !genisletildi
      ? satirlar.slice(0, 2).join("\n")
      : mesaj.metin;
  const gizliSatirSayisi = satirlar.length - 2;
  return (
    <div className={`max-w-[85%] space-y-1.5 ${botMu ? "" : "ml-auto"}`}>
      {sistemIkon ? (
        // Faz D3/E/F polish: otomatik doldurma, yönetim önerisi ve haftalık
        // performans mesajları — sıradan sohbet balonundan görsel olarak
        // ayrılsın diye vurgulu "sistem kartı" (ikon + tonlu arka plan).
        <div className="flex gap-2.5 rounded-xl border border-blue-400/20 bg-blue-500/[0.08] px-3.5 py-3 text-sm leading-relaxed text-slate-100">
          <span className="text-base leading-none" aria-hidden="true">
            {sistemIkon}
          </span>
          <span className="whitespace-pre-line">
            {gosterilenMetin}
            {uzunMu ? (
              <button
                type="button"
                onClick={() => setGenisletildi((onceki) => !onceki)}
                className="mt-1.5 block text-[12px] font-bold text-sky-300 hover:text-sky-200"
              >
                {genisletildi ? "Daha az göster" : `${gizliSatirSayisi} satır daha göster`}
              </button>
            ) : null}
          </span>
        </div>
      ) : (
        <div
          className={`whitespace-pre-line border border-white/10 px-3.5 py-3 text-sm leading-relaxed text-slate-200 ${
            botMu
              ? "rounded-t-xl rounded-br-xl rounded-bl-[4px] bg-white/[0.06]"
              : "rounded-t-xl rounded-bl-xl rounded-br-[4px] bg-[#0B1120]"
          }`}
        >
          {gosterilenMetin}
          {uzunMu ? (
            <button
              type="button"
              onClick={() => setGenisletildi((onceki) => !onceki)}
              className="mt-1.5 block text-[12px] font-bold text-sky-300 hover:text-sky-200"
            >
              {genisletildi ? "Daha az göster" : `${gizliSatirSayisi} satır daha göster`}
            </button>
          ) : null}
        </div>
      )}

      {/* Faz C2: hızlı cevaplar — Flutter `VixRexQuickReplies`/`ChatPill`
       * ile aynı görsel dil, ilk seçenek vurgulu (primary). */}
      {hizliCevaplar.length > 0 ? (
        <div className="flex flex-wrap gap-1.5" role="group" aria-label="Hızlı cevaplar">
          {hizliCevaplar.map((secenek, i) => (
            <button
              key={`${secenek.payload}-${i}`}
              type="button"
              onClick={() => onHizliCevap?.(secenek.payload, secenek.label)}
              className={
                i === 0
                  ? "rounded-full bg-blue-600 px-3 py-1.5 text-[12px] font-black text-white transition-colors hover:bg-blue-500"
                  : "rounded-full border border-white/15 px-3 py-1.5 text-[12px] font-bold text-slate-200 transition-colors hover:border-white/30"
              }
            >
              {secenek.label}
            </button>
          ))}
        </div>
      ) : null}
    </div>
  );
}

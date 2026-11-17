"use client";

import { useState } from "react";
import { PREMIUM_ILE_YAYINLA } from "@/lib/fiyatlandirma";

interface Props {
  yayinlaniyor: boolean;
  silmeOnayi: boolean;
  yayinla: () => Promise<void>;
  silmeOnayla: () => void;
  sil: () => Promise<void>;
  setSilmeOnayi: (v: boolean) => void;
  temelTamam: boolean;
  eksikTemelSayisi: number;
  kiralikVitrinMi: boolean;
  premiumAktifMi: boolean;
  yasalOnayli: boolean;
  onayVeriliyor: boolean;
  onayVer: (beyanlar: { privacyAcknowledged: boolean; termsAccepted: boolean; publicationConsent: boolean }) => Promise<boolean>;
  showPublishButton?: boolean;
  durumMetni?: string;
  yuzde?: number;
}

export function PublishBar({
  yayinlaniyor,
  silmeOnayi,
  yayinla,
  silmeOnayla,
  sil,
  setSilmeOnayi,
  temelTamam,
  eksikTemelSayisi,
  kiralikVitrinMi,
  premiumAktifMi,
  yasalOnayli,
  onayVeriliyor,
  onayVer,
  showPublishButton = true,
  durumMetni: _durumMetni,
  yuzde = 0,
}: Props) {
  const [privacyAcknowledged, setPrivacyAcknowledged] = useState(false);
  const [termsAccepted, setTermsAccepted] = useState(false);
  const [publicationConsent, setPublicationConsent] = useState(false);
  const [reapproving, setReapproving] = useState(false);
  const [onayAcik, setOnayAcik] = useState(false);
  const readyToRecord = privacyAcknowledged && termsAccepted && publicationConsent;
  const showConsentForm = !yasalOnayli || reapproving;

  const premiumGerekli = kiralikVitrinMi && !premiumAktifMi;
  const hazir = yasalOnayli && (temelTamam || premiumGerekli);
  const doluluk = Math.max(0, Math.min(100, Math.round(yuzde)));
  const yayinEtiketi = yayinlaniyor
    ? "Yayınlanıyor…"
    : !yasalOnayli
    ? "Yayınla — önce yasal onay gerekiyor"
    : premiumGerekli
    ? PREMIUM_ILE_YAYINLA
    : temelTamam
    ? "Yayınla"
    : `Yayınla — ${eksikTemelSayisi} zorunlu alan eksik`;

  return (
    <div className="flex items-center gap-1.5 relative">
      {silmeOnayi ? (
        <div className="flex items-center gap-1.5 bg-red-950/80 border border-red-500/40 rounded-lg px-2 py-0.5">
          <span className="text-[10px] text-red-300">Yaptığın tüm değişiklikler silinecek ve vitrin son yayınlanan hâline dönecek. Emin misin?</span>
          <button
            type="button"
            onClick={() => void sil()}
            disabled={yayinlaniyor}
            className="text-[10px] font-bold text-red-400 underline decoration-dotted hover:text-red-300 disabled:opacity-50"
          >
            {yayinlaniyor ? "Siliniyor…" : "Evet, sil"}
          </button>
          <button
            type="button"
            onClick={() => setSilmeOnayi(false)}
            disabled={yayinlaniyor}
            className="text-[10px] font-semibold text-slate-400 underline decoration-dotted hover:text-slate-200 disabled:opacity-50"
          >
            Vazgeç
          </button>
        </div>
      ) : (
        <button
          type="button"
          onClick={silmeOnayla}
          disabled={yayinlaniyor}
          className="text-[10px] font-medium text-slate-500 hover:text-slate-300 underline decoration-dotted disabled:opacity-50 px-1"
          title="Değişiklikleri bırak"
        >
          Değişiklikleri bırak
        </button>
      )}

      {showPublishButton ? (
        <button
          type="button"
          onClick={() => (yasalOnayli ? void yayinla() : setOnayAcik((acik) => !acik))}
          disabled={
            yayinlaniyor || (yasalOnayli && !premiumGerekli && !temelTamam)
          }
          aria-label={yayinEtiketi}
          aria-expanded={!yasalOnayli ? onayAcik : undefined}
          title={
            !yasalOnayli
              ? "Yayınlamadan önce yasal onay gerekli."
              : temelTamam || premiumGerekli
              ? premiumGerekli
                ? "Bu hazır vitrin premium üyelikle yayınlanır."
                : undefined
              : `Yayınlamadan önce ${eksikTemelSayisi} zorunlu alanı doldur.`
          }
          className={`relative h-7 shrink-0 overflow-hidden rounded-lg border px-3 text-[11px] font-bold text-white shadow-sm transition disabled:cursor-not-allowed ${
            hazir
              ? "border-sky-400/40 bg-gradient-to-r from-sky-500 to-blue-600 hover:from-sky-400 hover:to-blue-500"
              : "border-white/15 bg-white/[0.06] hover:bg-white/[0.1]"
          }`}
        >
          {!hazir ? (
            <span
              aria-hidden="true"
              className="absolute inset-y-0 left-0 bg-gradient-to-r from-sky-500/70 to-blue-600/70 transition-all duration-500"
              style={{ width: `${doluluk}%` }}
            />
          ) : null}
          <span className="relative flex items-center gap-1.5">
            <span>{yayinlaniyor ? "Yayınlanıyor…" : "Yayınla"}</span>
            {!hazir && !yayinlaniyor ? (
              <span className="rounded-md bg-black/30 px-1 py-px text-[9px] font-black tabular-nums text-sky-100">
                %{doluluk}
              </span>
            ) : null}
          </span>
        </button>
      ) : null}

      {/* Yasal onay açılır formu (yalnızca onay gerekirse açılır) */}
      {!yasalOnayli && showConsentForm && onayAcik ? (
        <div className="absolute right-0 top-9 z-30 w-72 space-y-2 rounded-xl border border-sky-400/30 bg-[#0b162a] p-3 text-[10px] leading-relaxed text-slate-300 shadow-2xl backdrop-blur-xl">
          <p className="font-bold text-white text-[11px]">Yayın Öncesi Yasal Onay</p>
          <p className="text-slate-400">Aydınlatma, kullanım şartları ve açık rıza birbirinden bağımsız beyanlardır.</p>
          <label className="flex items-start gap-2">
            <input
              type="checkbox"
              aria-label="Aydınlatma metnini okudum"
              checked={privacyAcknowledged}
              disabled={onayVeriliyor}
              onChange={(e) => setPrivacyAcknowledged(e.target.checked)}
              className="mt-0.5 h-3.5 w-3.5 shrink-0 accent-blue-500"
            />
            <span>
              <a href="/legal/privacy" target="_blank" rel="noopener noreferrer" className="font-semibold text-blue-400 underline">Aydınlatma Metni</a>
              {"'ni okudum ve bilgilendirildim."}
            </span>
          </label>
          <label className="flex items-start gap-2">
            <input
              type="checkbox"
              aria-label="Kullanım şartlarını kabul ediyorum"
              checked={termsAccepted}
              disabled={onayVeriliyor}
              onChange={(e) => setTermsAccepted(e.target.checked)}
              className="mt-0.5 h-3.5 w-3.5 shrink-0 accent-blue-500"
            />
            <span>
              <a href="/legal/terms" target="_blank" rel="noopener noreferrer" className="font-semibold text-blue-400 underline">Kullanım Şartları</a>
              {"'nı kabul ediyorum."}
            </span>
          </label>
          <label className="flex items-start gap-2">
            <input
              type="checkbox"
              aria-label="Açık rıza veriyorum"
              checked={publicationConsent}
              disabled={onayVeriliyor}
              onChange={(e) => setPublicationConsent(e.target.checked)}
              className="mt-0.5 h-3.5 w-3.5 shrink-0 accent-blue-500"
            />
            <span>
              <a href="/legal/consent" target="_blank" rel="noopener noreferrer" className="font-semibold text-blue-400 underline">Açık Rıza Beyanı</a>
              {"'nda açıklanan işleme kendi isteğimle rıza veriyorum."}
            </span>
          </label>
          <div className="flex items-center justify-end gap-2 pt-1 border-t border-white/10">
            <button
              type="button"
              onClick={() => setOnayAcik(false)}
              className="px-2 py-0.5 text-slate-400 hover:text-white"
            >
              Kapat
            </button>
            <button
              type="button"
              disabled={!readyToRecord || onayVeriliyor}
              onClick={async () => {
                const ok = await onayVer({ privacyAcknowledged, termsAccepted, publicationConsent });
                if (ok) {
                  setReapproving(false);
                  setOnayAcik(false);
                }
              }}
              className="rounded-lg bg-emerald-600 hover:bg-emerald-500 px-3 py-1 font-bold text-white transition disabled:opacity-50"
            >
              {onayVeriliyor ? "Kaydediliyor…" : "Onayla ve Yayınla"}
            </button>
          </div>
        </div>
      ) : null}
    </div>
  );
}

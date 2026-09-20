import { PREMIUM_ILE_YAYINLA } from "@/lib/fiyatlandirma";

interface Props {
  yayinlaniyor: boolean;
  silmeOnayi: boolean;
  yayinla: () => Promise<void>;
  silmeOnayla: () => void;
  sil: () => Promise<void>;
  setSilmeOnayi: (v: boolean) => void;
  /** Temel alanlar tamamsa yayınla düğmesi aktif; değilse pasif ve nedenini
   * yazar. Faz G3 (Tek Asistan planı): "Yayınla düğmesi yalan söylemez." */
  temelTamam: boolean;
  eksikTemelSayisi: number;
  /** Kiralık şablon vitrin mi (cloned_from_slug dolu). Yayın premium ister. */
  kiralikVitrinMi: boolean;
  /** Premium süresi aktif mi (premium_expires_at gelecekte). */
  premiumAktifMi: boolean;
  /** Gizlilik/şartlar/yayın izni üçü de verildi mi (yerelTaslak'tan —
   * owner_forbidden_draft_keys bu alanların YAZILMASINI engeller, OKUNMASINI
   * değil). true olduktan sonra bu ekrandan geri alınamaz (kapsam dışı). */
  yasalOnayli: boolean;
  onayVeriliyor: boolean;
  onayVer: () => Promise<void>;
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
}: Props) {
  // Kiralık şablon vitrin + aktif premium yoksa yayın premium ister.
  // Düğme yalan söylemez: ne gerekiyorsa onu yazar (Faz G3 ilkesi).
  const premiumGerekli = kiralikVitrinMi && !premiumAktifMi;
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
    <div className="border-t border-white/10 px-4 py-3">
      {/* Master onay kutusu — Flutter'daki LegalConsentSection ile aynı
          desen (lib/widgets/editor/legal_consent_section.dart): tek kutu,
          üç belgeyi birlikte kabul eder, ayrı ayrı sorulmaz. */}
      {yasalOnayli ? (
        <p className="mb-2 flex items-center gap-1.5 text-[11px] font-medium text-emerald-400">
          <span aria-hidden>✓</span> Yasal onay verildi.
          {/* Belgeler güncellenip owner-publish PRIVACY/TERMS/CONSENT_
              VERSION_INVALID döndüğünde kullanıcının önü kesilmesin diye
              — checkbox kalıcı olarak gizlendiği için tek geri dönüş
              yolu bu link (nadiren kullanılır, ama tıkanmayı önler). */}
          <button
            type="button"
            onClick={() => void onayVer()}
            disabled={onayVeriliyor}
            className="text-slate-400 underline decoration-dotted hover:text-slate-300"
          >
            {onayVeriliyor ? "Kaydediliyor…" : "yeniden onayla"}
          </button>
        </p>
      ) : (
        <label className="mb-2 flex items-start gap-2 text-[11px] leading-relaxed text-slate-300">
          <input
            type="checkbox"
            checked={false}
            disabled={onayVeriliyor}
            onChange={(e) => {
              if (e.target.checked) void onayVer();
            }}
            className="mt-0.5 h-3.5 w-3.5 shrink-0"
          />
          <span>
            {onayVeriliyor ? (
              "Kaydediliyor…"
            ) : (
              <>
                <a
                  href="/legal/privacy"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="font-semibold text-blue-400 underline"
                >
                  Aydınlatma Metni
                </a>
                {", "}
                <a
                  href="/legal/terms"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="font-semibold text-blue-400 underline"
                >
                  Kullanım Şartları
                </a>
                {" ve "}
                <a
                  href="/legal/consent"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="font-semibold text-blue-400 underline"
                >
                  Açık Rıza Beyanı
                </a>
                {"'nı okudum, anladım ve kabul ediyorum."}
              </>
            )}
          </span>
        </label>
      )}
      <button
        type="button"
        onClick={() => void yayinla()}
        disabled={
          yayinlaniyor || !yasalOnayli || (!premiumGerekli && !temelTamam)
        }
        title={
          !yasalOnayli
            ? "Yayınlamadan önce yukarıdaki onay kutusunu işaretle."
            : temelTamam || premiumGerekli
            ? premiumGerekli
              ? "Bu hazır vitrin premium üyelikle yayınlanır."
              : undefined
            : `Yayınlamadan önce ${eksikTemelSayisi} zorunlu alanı doldur.`
        }
        className="w-full rounded-lg bg-blue-600 px-3 py-2 text-xs font-semibold text-white hover:bg-blue-700 disabled:opacity-50"
      >
        {yayinEtiketi}
      </button>
      {/* "Değişiklikleri bırak" TEK TIKLA silmez: önce onay istenir.
          Bu düğme kullanıcının saatlerce yaptığı işi silebilir. */}
      {silmeOnayi ? (
        <div className="mt-2 flex gap-2">
          <button
            type="button"
            onClick={() => void sil()}
            disabled={yayinlaniyor}
            className="flex-1 rounded-lg bg-red-600/80 px-3 py-2 text-xs font-semibold text-white hover:bg-red-700 disabled:opacity-50"
          >
            {yayinlaniyor ? "Siliniyor…" : "Evet, sil"}
          </button>
          <button
            type="button"
            onClick={() => setSilmeOnayi(false)}
            disabled={yayinlaniyor}
            className="flex-1 rounded-lg border border-white/10 bg-white/[0.06] px-3 py-2 text-xs font-semibold text-slate-300 hover:bg-white/10 disabled:opacity-50"
          >
            Vazgeç
          </button>
        </div>
      ) : (
        <button
          type="button"
          onClick={silmeOnayla}
          disabled={yayinlaniyor}
          className="mt-2 w-full rounded-lg border border-white/10 bg-white/[0.06] px-3 py-2 text-xs font-semibold text-slate-300 hover:bg-white/10 disabled:opacity-50"
        >
          Değişiklikleri bırak
        </button>
      )}
    </div>
  );
}

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
}: Props) {
  // Kiralık şablon vitrin + aktif premium yoksa yayın premium ister.
  // Düğme yalan söylemez: ne gerekiyorsa onu yazar (Faz G3 ilkesi).
  const premiumGerekli = kiralikVitrinMi && !premiumAktifMi;
  const yayinEtiketi = yayinlaniyor
    ? "Yayınlanıyor…"
    : premiumGerekli
    ? "Premium ile yayınla — aylık 299 TL"
    : temelTamam
    ? "Yayınla"
    : `Yayınla — ${eksikTemelSayisi} zorunlu alan eksik`;

  return (
    <div className="border-t border-white/10 px-4 py-3">
      <button
        type="button"
        onClick={() => void yayinla()}
        disabled={yayinlaniyor || (!premiumGerekli && !temelTamam)}
        title={
          temelTamam || premiumGerekli
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

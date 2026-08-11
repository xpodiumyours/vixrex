interface Props {
  yayinlaniyor: boolean;
  silmeOnayi: boolean;
  yayinla: () => Promise<void>;
  silmeOnayla: () => void;
  sil: () => Promise<void>;
  setSilmeOnayi: (v: boolean) => void;
}

export function PublishBar({
  yayinlaniyor,
  silmeOnayi,
  yayinla,
  silmeOnayla,
  sil,
  setSilmeOnayi,
}: Props) {
  return (
    <div className="border-t border-white/10 px-4 py-3">
      <button
        type="button"
        onClick={() => void yayinla()}
        disabled={yayinlaniyor}
        className="w-full rounded-lg bg-blue-600 px-3 py-2 text-xs font-semibold text-white hover:bg-blue-700 disabled:opacity-50"
      >
        {yayinlaniyor ? "Yayınlanıyor…" : "Yayınla"}
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

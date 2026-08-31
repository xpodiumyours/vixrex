export default function KesfetYukleniyor() {
  return (
    <div className="px-6 py-12" role="status" aria-label="Vitrinler yükleniyor">
      <div className="@container mx-auto w-full max-w-[1200px] animate-pulse motion-reduce:animate-none">
        <div className="h-10 w-64 rounded-xl bg-lp-surface-soft" />
        <div className="mt-3 h-6 w-full max-w-xl rounded-lg bg-lp-surface-soft" />
        <div className="mt-8 h-12 rounded-2xl bg-lp-surface-soft" />
        <div className="mt-4 flex gap-2 overflow-hidden">
          {[0, 1, 2, 3, 4].map((index) => (
            <div key={index} className="h-11 w-24 shrink-0 rounded-full bg-lp-surface-soft" />
          ))}
        </div>
        <div className="mt-6 grid grid-cols-2 gap-3 @min-[700px]:grid-cols-3 @min-[1000px]:grid-cols-4">
          {[0, 1, 2, 3, 4, 5, 6, 7].map((index) => (
            <div key={index} className="h-[280px] rounded-[18px] bg-lp-surface-soft" />
          ))}
        </div>
        <span className="sr-only">Vitrinler yükleniyor.</span>
      </div>
    </div>
  );
}

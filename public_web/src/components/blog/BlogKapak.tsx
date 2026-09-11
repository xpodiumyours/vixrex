import Image from "next/image";
import type { BlogIcerikTuru, BlogListeYazisi } from "@/data/blogYazilari";

function icerikTuruEtiketi(icerikTuru: BlogIcerikTuru): string {
  switch (icerikTuru) {
    case "haber":
      return "Haber";
    case "urun_guncellemesi":
      return "Ürün güncellemesi";
    case "isletme_hikayesi":
      return "İşletme hikâyesi";
    default:
      return "Rehber";
  }
}

export function BlogKapak({
  yazi,
  oncelikli = false,
}: {
  yazi: Pick<
    BlogListeYazisi,
    "baslik" | "kategori" | "icerikTuru" | "kapak" | "kapakAlt"
  >;
  oncelikli?: boolean;
}) {
  if (yazi.kapak) {
    return (
      <div className="relative aspect-[16/9] overflow-hidden rounded-[20px] border border-lp-border bg-lp-surface-soft">
        <Image
          src={yazi.kapak}
          alt={yazi.kapakAlt || yazi.baslik}
          fill
          preload={oncelikli}
          sizes={
            oncelikli
              ? "(max-width: 768px) 100vw, 58vw"
              : "(max-width: 768px) 100vw, 33vw"
          }
          className="object-cover"
        />
      </div>
    );
  }

  return (
    <div
      className="relative flex aspect-[16/9] overflow-hidden rounded-[20px] border border-lp-border bg-lp-surface-soft p-6 sm:p-7"
      role="img"
      aria-label={`${yazi.baslik} için Vixrex editoryal kapak`}
    >
      <span
        aria-hidden="true"
        className="absolute right-5 top-5 h-20 w-20 rounded-full border border-lp-primary/25"
      />
      <span
        aria-hidden="true"
        className="absolute bottom-5 right-10 h-10 w-10 rounded-full border border-lp-secondary/25"
      />
      <div className="relative z-10 flex w-full flex-col justify-between">
        <div className="flex items-center justify-between gap-4">
          <span className="text-xs font-black uppercase tracking-[0.18em] text-lp-secondary">
            Vixrex Blog
          </span>
          <span className="rounded-full border border-lp-border bg-lp-bg-editor/40 px-3 py-1 text-[11px] font-black text-lp-muted">
            {icerikTuruEtiketi(yazi.icerikTuru)}
          </span>
        </div>
        <div className="max-w-[82%]">
          <p className="text-xs font-black uppercase tracking-[0.14em] text-lp-muted">
            {yazi.kategori}
          </p>
          <p className="mt-2 break-words text-xl font-black leading-tight tracking-tight text-lp-text sm:text-2xl">
            {yazi.baslik}
          </p>
        </div>
      </div>
    </div>
  );
}

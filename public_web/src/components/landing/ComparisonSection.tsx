import { TikIkonu, YonOkuIkonu } from "@/components/site/icons";

/** Karşılaştırma — envanter §2.6. */
const AYRI_KURULUM = [
  "Domain ve hosting",
  "Teknik ayarlar",
  "WhatsApp bağlantısı",
  "QR ve paylaşım süreci",
  "İçerik güncelleme desteği",
] as const;

const VIXREX_ILE = [
  "İşletme bilgileri ve fotoğraflar",
  "Ürünler ve hizmetler",
  "WhatsApp, adres, link ve QR",
  "Panelden kolay güncelleme",
  "Müşteriyle doğrudan iletişim",
] as const;

export function ComparisonSection() {
  return (
    <section className="bg-lp-bg-editor px-6 py-[88px]">
      <div className="mx-auto w-full max-w-[1200px]">
        <h2 className="text-center text-[38px] font-black tracking-[-0.5px] text-lp-text">
          Dijital vitrinin için gerekenler tek yerde
        </h2>
        <p className="mx-auto mt-4 max-w-[720px] text-center text-[16px] leading-[1.5] text-lp-muted">
          Araçları ve kurulumları ayrı ayrı yönetmek yerine işletme bilgilerini
          Vixrex’e ekle, paylaşmaya başla.
        </p>

        <div className="mt-12 flex flex-col items-stretch gap-6 md:flex-row md:items-center">
          <div className="flex-1 rounded-[28px] border border-lp-border bg-lp-surface p-[26px] shadow-lp-card">
            <p className="text-[13px] font-black tracking-[0.2px] text-lp-muted">
              Ayrı ayrı kurulum
            </p>
            <ul className="mt-[22px] flex flex-col gap-3.5">
              {AYRI_KURULUM.map((satir) => (
                <li key={satir} className="flex items-center gap-3">
                  <span
                    aria-hidden
                    className="h-9 w-9 shrink-0 rounded-xl bg-lp-bg-editor"
                  />
                  <span className="text-[14px] font-semibold text-lp-muted">
                    {satir}
                  </span>
                </li>
              ))}
            </ul>
            <p className="mt-[26px] rounded-[14px] border border-lp-border bg-lp-surface-soft px-4 py-3 text-center text-[12px] font-black text-lp-muted">
              Birden fazla araç ve işlem
            </p>
          </div>

          <span
            aria-hidden
            className="mx-auto flex h-[46px] w-[46px] shrink-0 items-center justify-center rounded-full border border-lp-primary/35 bg-lp-surface-soft text-lp-primary [&>svg]:rotate-90 md:[&>svg]:rotate-0"
          >
            <YonOkuIkonu boyut={22} />
          </span>

          <div className="flex-1 rounded-[28px] border border-lp-primary/40 bg-gradient-to-br from-lp-surface to-lp-turquoise-surface p-[26px] shadow-lp-panel">
            <p className="text-[13px] font-black tracking-[0.2px] text-white">
              Vixrex ile
            </p>
            <ul className="mt-[22px] flex flex-col gap-3.5">
              {VIXREX_ILE.map((satir) => (
                <li key={satir} className="flex items-center gap-3">
                  <span
                    aria-hidden
                    className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-white/10 text-[#65E7E7]"
                  >
                    <TikIkonu boyut={18} />
                  </span>
                  <span className="text-[14px] font-extrabold text-white">
                    {satir}
                  </span>
                </li>
              ))}
            </ul>
            <p className="mt-[26px] rounded-[14px] border border-white/15 bg-white/10 px-4 py-3 text-center text-[12px] font-black text-[#BFF7F7]">
              Tek panel, tek link, doğrudan iletişim
            </p>
          </div>
        </div>
      </div>
    </section>
  );
}

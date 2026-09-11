import { TikIkonu, YonOkuIkonu } from "@/components/site/icons";

function DunyaIkonu() {
  return (
    <svg width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" aria-hidden>
      <circle cx="12" cy="12" r="8" />
      <path d="M4 12h16M12 4c2.2 2.2 3.3 4.9 3.3 8S14.2 17.8 12 20c-2.2-2.2-3.3-4.9-3.3-8S9.8 6.2 12 4Z" />
    </svg>
  );
}

function AyarIkonu() {
  return (
    <svg width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" aria-hidden>
      <path d="M4 7h7M15 7h5M4 12h3M11 12h9M4 17h10M18 17h2" />
      <circle cx="13" cy="7" r="2" />
      <circle cx="9" cy="12" r="2" />
      <circle cx="16" cy="17" r="2" />
    </svg>
  );
}

function MesajIkonu() {
  return (
    <svg width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinejoin="round" aria-hidden>
      <path d="M5 5h14a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H9l-5 3v-3H5a2 2 0 0 1-2-2V7a2 2 0 0 1 2-2Z" />
    </svg>
  );
}

function QrIkonu() {
  return (
    <svg width="19" height="19" viewBox="0 0 24 24" fill="currentColor" aria-hidden>
      <path d="M4 4h6v6H4V4Zm2 2v2h2V6H6Zm8-2h6v6h-6V4Zm2 2v2h2V6h-2ZM4 14h6v6H4v-6Zm2 2v2h2v-2H6Zm8-2h2v2h-2v-2Zm4 0h2v4h-2v-4Zm-4 4h4v2h-4v-2Zm6 2h-2v-2h2v2Z" />
    </svg>
  );
}

function DestekIkonu() {
  return (
    <svg width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
      <path d="M5 13v-1a7 7 0 0 1 14 0v1" />
      <path d="M5 13H4a2 2 0 0 0-2 2v2a2 2 0 0 0 2 2h2v-6H5Zm14 0h1a2 2 0 0 1 2 2v2a2 2 0 0 1-2 2h-2v-6h1ZM18 19c-1 1.3-2.7 2-5 2" />
    </svg>
  );
}

/** Flutter landing_comparison_section.dart ile aynı içerik ve yerleşim. */
const AYRI_KURULUM = [
  { metin: "Domain ve hosting", ikon: <DunyaIkonu /> },
  { metin: "Teknik ayarlar", ikon: <AyarIkonu /> },
  { metin: "WhatsApp bağlantısı", ikon: <MesajIkonu /> },
  { metin: "QR ve paylaşım süreci", ikon: <QrIkonu /> },
  { metin: "İçerik güncelleme desteği", ikon: <DestekIkonu /> },
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
    <section className="bg-lp-bg-editor lp-yan-bosluk py-lp-section">
      <div className="mx-auto w-full max-w-lp">
        <h2 className="text-center text-[38px] font-black tracking-[-0.5px] text-lp-text">
          Dijital vitrinin için gerekenler tek yerde
        </h2>
        <p className="mx-auto mt-4 max-w-lp-dar text-center text-[16px] leading-[1.5] text-lp-muted">
          Araçları ve kurulumları ayrı ayrı yönetmek yerine işletme bilgilerini Vixrex’e ekle, paylaşmaya başla.
        </p>

        <div className="mt-12 flex flex-col items-stretch md:flex-row md:items-center">
          <div className="flex-1 rounded-[28px] border border-lp-border bg-lp-surface p-[26px] shadow-lp-card">
            <p className="text-[13px] font-black tracking-[0.2px] text-lp-muted">
              Ayrı ayrı kurulum
            </p>
            <ul className="mt-[22px]">
              {AYRI_KURULUM.map((satir) => (
                <li key={satir.metin} className="flex items-center gap-3 pb-[14px]">
                  <span
                    aria-hidden
                    className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-lp-bg-editor text-lp-muted"
                  >
                    {satir.ikon}
                  </span>
                  <span className="text-[14px] font-bold leading-[1.35] text-lp-text/80">
                    {satir.metin}
                  </span>
                </li>
              ))}
            </ul>
            <p className="mt-1 rounded-[14px] border border-lp-border bg-lp-surface-soft px-[14px] py-[13px] text-center text-[12px] font-black leading-[1.35] text-lp-muted">
              Birden fazla araç ve işlem
            </p>
          </div>

          <span
            aria-hidden
            className="mx-auto my-[18px] flex h-[46px] w-[46px] shrink-0 items-center justify-center rounded-full border border-lp-primary/35 bg-lp-surface-soft text-lp-primary shadow-lp-card md:mx-[18px] md:my-0 [&>svg]:rotate-90 md:[&>svg]:rotate-0"
          >
            <YonOkuIkonu boyut={22} />
          </span>

          <div className="flex-1 rounded-[28px] border border-lp-primary/40 bg-gradient-to-br from-lp-surface to-lp-turquoise-surface p-[26px] shadow-lp-panel">
            <p className="text-[13px] font-black tracking-[0.2px] text-lp-primary">
              Vixrex ile
            </p>
            <ul className="mt-[22px]">
              {VIXREX_ILE.map((satir) => (
                <li key={satir} className="flex items-center gap-3 pb-[14px]">
                  <span
                    aria-hidden
                    className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-white/10 text-[#65E7E7]"
                  >
                    <TikIkonu boyut={19} />
                  </span>
                  <span className="text-[14px] font-extrabold leading-[1.35] text-white">
                    {satir}
                  </span>
                </li>
              ))}
            </ul>
            <p className="mt-1 rounded-[14px] border border-white/10 bg-white/10 px-[14px] py-[13px] text-center text-[12px] font-black leading-[1.35] text-[#BFF7F7]">
              Tek panel, tek link, doğrudan iletişim
            </p>
          </div>
        </div>
      </div>
    </section>
  );
}

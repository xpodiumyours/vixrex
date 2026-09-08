import { MaterialRoundIcon } from "./MaterialRoundIcon";

const AYRI_KURULUM = [
  ["language", "Domain ve hosting"],
  ["tune", "Teknik ayarlar"],
  ["chat_bubble_outline", "WhatsApp bağlantısı"],
  ["qr_code_2", "QR ve paylaşım süreci"],
  ["support_agent", "İçerik güncelleme desteği"],
] as const;

const VIXREX_ILE = [
  ["storefront", "İşletme bilgileri ve fotoğraflar"],
  ["inventory_2", "Ürünler ve hizmetler"],
  ["hub", "WhatsApp, adres, link ve QR"],
  ["edit_note", "Panelden kolay güncelleme"],
  ["forum", "Müşteriyle doğrudan iletişim"],
] as const;

function SetupPanel({
  label,
  items,
  footer,
  highlighted,
}: {
  label: string;
  items: readonly (readonly [Parameters<typeof MaterialRoundIcon>[0]["name"], string])[];
  footer: string;
  highlighted: boolean;
}) {
  return (
    <div
      className={`flex-1 rounded-[28px] border p-[26px] ${
        highlighted
          ? "border-lp-primary/40 bg-gradient-to-br from-lp-surface to-lp-turquoise-surface shadow-[0_16px_34px_rgba(20,125,255,0.14)]"
          : "border-lp-border bg-lp-surface shadow-[0_16px_24px_rgba(0,0,0,0.20)]"
      }`}
    >
      <p className={`text-[13px] font-black tracking-[0.2px] ${highlighted ? "text-lp-primary" : "text-lp-muted"}`}>
        {label}
      </p>

      <ul className="mt-[22px]">
        {items.map(([ikon, satir]) => (
          <li key={satir} className="mb-[14px] flex items-center">
            <span
              className={`flex h-9 w-9 shrink-0 items-center justify-center rounded-xl ${
                highlighted ? "bg-white/10 text-[#65E7E7]" : "bg-lp-bg-editor text-lp-muted"
              }`}
            >
              <MaterialRoundIcon name={highlighted ? "check" : ikon} size={19} />
            </span>
            <span className={`ml-3 text-[14px] leading-[1.35] ${highlighted ? "font-extrabold text-white" : "font-bold text-lp-text-alt"}`}>
              {satir}
            </span>
          </li>
        ))}
      </ul>

      <p
        className={`mt-1 w-full rounded-[14px] border px-[14px] py-[13px] text-center text-[12px] font-black leading-[1.35] ${
          highlighted
            ? "border-white/10 bg-white/10 text-[#BFF7F7]"
            : "border-lp-border bg-lp-surface-soft text-lp-muted"
        }`}
      >
        {footer}
      </p>
    </div>
  );
}

/** Flutter `landing_comparison_section.dart` + `landing_setup_panel.dart` karşılığı. */
export function ComparisonSection() {
  return (
    <section className="bg-lp-bg-editor px-6 py-[88px]">
      <div className="mx-auto w-full max-w-[1200px]">
        <h2 className="text-center text-[38px] font-black tracking-[-0.5px] text-lp-text">
          Dijital vitrinin için gerekenler tek yerde
        </h2>
        <p className="mt-4 text-center text-[16px] leading-[1.5] text-lp-muted">
          Araçları ve kurulumları ayrı ayrı yönetmek yerine işletme bilgilerini
          Vixrex’e ekle, paylaşmaya başla.
        </p>

        <div className="mt-12 flex flex-col items-stretch min-[869px]:flex-row min-[869px]:items-center">
          <SetupPanel
            label="Ayrı ayrı kurulum"
            items={AYRI_KURULUM}
            footer="Birden fazla araç ve işlem"
            highlighted={false}
          />

          <div className="flex justify-center py-[18px] min-[869px]:px-[18px] min-[869px]:py-0">
            <span className="flex h-[46px] w-[46px] shrink-0 items-center justify-center rounded-full border border-lp-primary/35 bg-lp-surface-soft text-lp-primary shadow-[0_8px_16px_rgba(0,0,0,0.22)]">
              <span className="min-[869px]:hidden">
                <MaterialRoundIcon name="arrow_downward" size={24} />
              </span>
              <span className="hidden min-[869px]:block">
                <MaterialRoundIcon name="arrow_forward" size={24} />
              </span>
            </span>
          </div>

          <SetupPanel
            label="Vixrex ile"
            items={VIXREX_ILE}
            footer="Tek panel, tek link, doğrudan iletişim"
            highlighted
          />
        </div>
      </div>
    </section>
  );
}

import { getAppUrl } from "@/lib/siteUrl";

/** Alt çağrı — envanter §2.10. */
export function BottomCta() {
  return (
    <section
      id="basla"
      className="bg-gradient-to-br from-lp-bg-editor to-lp-primary px-6 py-[88px]"
    >
      <div className="mx-auto w-full max-w-[800px] text-center">
        <h2 className="text-[36px] font-black leading-[1.2] text-lp-surface-soft">
          İşletmenizi tek linkte müşterilerinizle buluşturun
        </h2>
        <p className="mx-auto mt-5 max-w-[640px] text-[18px] leading-[1.5] text-lp-border">
          Vixrex’ini oluştur; linkini, QR kodunu ve WhatsApp iletişimini
          paylaşmaya başla.
        </p>
        <a
          href={`${getAppUrl()}/app`}
          className="mt-9 inline-flex items-center justify-center rounded-3xl bg-lp-primary px-10 py-6 text-[18px] font-black text-white shadow-lp-panel transition-transform hover:-translate-y-0.5"
        >
          Vixrex Oluştur
        </a>
      </div>
    </section>
  );
}

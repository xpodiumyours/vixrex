import Link from "next/link";
import { unstable_cache } from "next/cache";
import { supabase } from "@/lib/supabase";

export const revalidate = 600;

const getStoreCount = unstable_cache(
  async () => {
    const { count } = await supabase
      .from("stores")
      .select("*", { count: "exact", head: true })
      .eq("is_published", true);
    return count || 0;
  },
  ["homepage-store-count"],
  { tags: ["homepage"], revalidate: 600 },
);

const whyItems = [
  {
    icon: "bolt",
    title: "Dakikalar içinde yayına alın",
    description: "Temel bilgilerinizi ekleyin ve vitrininizi oluşturun.",
  },
  {
    icon: "contact",
    title: "Müşteriler size doğrudan ulaşsın",
    description:
      "WhatsApp, adres ve yol tarifi seçeneklerini tek yerde sunun.",
  },
  {
    icon: "share",
    title: "Her kanalda aynı vitrini paylaşın",
    description:
      "Linkinizi sosyal medyada, QR kodunuzu işletmenizde kullanın.",
  },
  {
    icon: "edit",
    title: "Bilgilerinizi panelden güncelleyin",
    description:
      "Fotoğraf, ürün, hizmet ve iletişim bilgilerinizi istediğiniz zaman düzenleyin.",
  },
] as const;

const separateSetupItems = [
  "Domain ve hosting",
  "Teknik ayarlar",
  "WhatsApp bağlantısı",
  "QR ve paylaşım süreci",
  "İçerik güncelleme desteği",
] as const;

const vitrinxSetupItems = [
  "İşletme bilgileri ve fotoğraflar",
  "Ürünler ve hizmetler",
  "WhatsApp, adres, link ve QR",
  "Panelden kolay güncelleme",
  "Müşteriyle doğrudan iletişim",
] as const;

const trustItems = [
  "Kredi kartı gerekmez",
  "Satıştan komisyon alınmaz",
  "Kodsuz kurulum",
  "Link ve QR kod hazırdır",
  "WhatsApp ile doğrudan iletişim",
] as const;

const steps = [
  {
    title: "Bilgilerinizi ekleyin",
    description: "İşletme adı, açıklama, WhatsApp ve adres bilgilerinizi girin.",
  },
  {
    title: "Vitrininizi hazırlayın",
    description: "Fotoğraflarınızı, ürünlerinizi ve hizmetlerinizi ekleyin.",
  },
  {
    title: "Müşterilerinizle paylaşın",
    description: "Vitrin linkinizi veya QR kodunuzu paylaşın.",
  },
] as const;

type GlyphKind =
  | "bolt"
  | "contact"
  | "share"
  | "edit"
  | "chat"
  | "qr"
  | "globe";

function CheckIcon({ className = "h-4 w-4" }: { className?: string }) {
  return (
    <svg
      className={className}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2.5"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <path d="m5 12 4 4L19 6" />
    </svg>
  );
}

function FeatureGlyph({ kind }: { kind: GlyphKind }) {
  const paths: Record<GlyphKind, React.ReactNode> = {
    bolt: <path d="m13 2-8 12h7l-1 8 8-12h-7l1-8Z" />,
    contact: (
      <>
        <path d="M7 3h10a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2Z" />
        <path d="M9 7h6M9 17h6M10 11h4" />
      </>
    ),
    share: (
      <>
        <circle cx="18" cy="5" r="3" />
        <circle cx="6" cy="12" r="3" />
        <circle cx="18" cy="19" r="3" />
        <path d="m8.6 10.6 6.8-4.2M8.6 13.4l6.8 4.2" />
      </>
    ),
    edit: (
      <>
        <path d="M12 20h9" />
        <path d="M16.5 3.5a2.1 2.1 0 0 1 3 3L8 18l-4 1 1-4Z" />
      </>
    ),
    chat: (
      <>
        <path d="M21 15a4 4 0 0 1-4 4H8l-5 3V7a4 4 0 0 1 4-4h10a4 4 0 0 1 4 4Z" />
        <path d="M8 10h8M8 14h5" />
      </>
    ),
    qr: (
      <>
        <rect x="3" y="3" width="6" height="6" rx="1" />
        <rect x="15" y="3" width="6" height="6" rx="1" />
        <rect x="3" y="15" width="6" height="6" rx="1" />
        <path d="M15 15h2v2h-2zM19 15h2M19 19h2v2h-2zM15 19v2" />
      </>
    ),
    globe: (
      <>
        <circle cx="12" cy="12" r="9" />
        <path d="M3 12h18M12 3c3 3.5 3 14 0 18M12 3c-3 3.5-3 14 0 18" />
      </>
    ),
  };

  return (
    <svg
      className="h-6 w-6"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      {paths[kind]}
    </svg>
  );
}

function SetupPanel({
  label,
  items,
  footer,
  highlighted,
}: {
  label: string;
  items: readonly string[];
  footer: string;
  highlighted: boolean;
}) {
  return (
    <article
      className={
        highlighted
          ? "rounded-[28px] border border-[#10D8D8]/30 bg-gradient-to-br from-[#0F172A] to-[#0B6670] p-6 text-white shadow-[0_22px_55px_rgba(11,102,112,0.22)] sm:p-7"
          : "rounded-[28px] border border-[#DCE7EA] bg-white p-6 shadow-[0_18px_45px_rgba(15,23,42,0.06)] dark:border-[#243141] dark:bg-[#131A22] sm:p-7"
      }
    >
      <p
        className={`text-sm font-extrabold ${
          highlighted
            ? "text-[#65E7E7]"
            : "text-[#64748B] dark:text-[#94A3B8]"
        }`}
      >
        {label}
      </p>
      <ul className="mt-6 space-y-3.5">
        {items.map((item) => (
          <li key={item} className="flex items-center gap-3">
            <span
              className={`flex h-9 w-9 shrink-0 items-center justify-center rounded-xl ${
                highlighted
                  ? "bg-white/10 text-[#65E7E7]"
                  : "bg-[#F1F5F9] text-[#64748B] dark:bg-[#1B242F] dark:text-[#94A3B8]"
              }`}
            >
              {highlighted ? (
                <CheckIcon className="h-4 w-4" />
              ) : (
                <span className="h-1.5 w-1.5 rounded-full bg-current" />
              )}
            </span>
            <span
              className={`text-sm leading-6 ${
                highlighted
                  ? "font-bold text-white"
                  : "font-semibold text-[#334155] dark:text-[#CBD5E1]"
              }`}
            >
              {item}
            </span>
          </li>
        ))}
      </ul>
      <div
        className={`mt-5 rounded-2xl border px-4 py-3 text-center text-xs font-extrabold leading-5 ${
          highlighted
            ? "border-white/10 bg-white/10 text-[#BFF7F7]"
            : "border-[#E2E8F0] bg-[#F8FAFC] text-[#64748B] dark:border-[#243141] dark:bg-[#1B242F] dark:text-[#94A3B8]"
        }`}
      >
        {footer}
      </div>
    </article>
  );
}

export default async function HomePage() {
  let displayCount = 0;
  try {
    displayCount = await getStoreCount();
  } catch (error) {
    console.error("Error fetching store count:", error);
  }

  return (
    <div className="min-h-screen overflow-hidden bg-[#FFFBF7] text-[#182028] dark:bg-[#0B0F13] dark:text-[#F1F5F9]">
      <section className="relative">
        <div className="pointer-events-none absolute left-[-12%] top-[8%] h-[320px] w-[320px] rounded-full bg-[#10D8D8]/15 blur-[110px] dark:bg-[#10D8D8]/8" />
        <div className="pointer-events-none absolute right-[-10%] top-[18%] h-[420px] w-[420px] rounded-full bg-[#38A0E4]/15 blur-[130px] dark:bg-[#38A0E4]/8" />

        <header className="relative z-10 mx-auto flex w-full max-w-6xl items-center justify-between px-5 py-6 sm:px-8">
          <div className="flex items-center gap-2.5">
            <div className="flex h-10 w-10 items-center justify-center rounded-full bg-[#10D8D8]/15 text-[#0EA8B0]">
              <svg
                width="21"
                height="21"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2.3"
                strokeLinecap="round"
                strokeLinejoin="round"
                aria-hidden="true"
              >
                <path d="M3 9h18M5 9v11h14V9M4 4h16l1 5H3l1-5Z" />
                <path d="M9 20v-6h6v6" />
              </svg>
            </div>
            <span className="text-xl font-extrabold tracking-tight">VitrinX</span>
          </div>
          <Link
            href="https://app.vitrinx.app"
            className="btn-secondary rounded-xl px-4 py-2.5 text-sm sm:px-5"
          >
            Yönetici Girişi
          </Link>
        </header>

        <main className="relative z-10 mx-auto grid w-full max-w-6xl items-center gap-12 px-5 pb-20 pt-10 sm:px-8 md:grid-cols-[1.08fr_0.92fr] md:pb-28 md:pt-16">
          <div className="flex flex-col items-center text-center md:items-start md:text-left">
            <span className="mb-7 inline-flex rounded-full border border-[#10D8D8]/25 bg-[#10D8D8]/10 px-4 py-2 text-xs font-extrabold tracking-[0.16em] text-[#0EA8B0] dark:text-[#10D8D8]">
              İŞLETMENİZ İÇİN DİJİTAL VİTRİN
            </span>
            <h1 className="max-w-3xl text-4xl font-extrabold leading-[1.08] tracking-[-0.035em] sm:text-5xl lg:text-6xl">
              İşletmenizin dijital vitrini dakikalar içinde hazır
            </h1>
            <p className="mt-6 max-w-2xl text-base leading-7 text-[#475569] dark:text-[#CBD5E1] sm:text-lg sm:leading-8">
              İşletme bilgilerinizi, fotoğraflarınızı, ürün ve hizmetlerinizi,
              adresinizi ve WhatsApp iletişiminizi tek vitrinde toplayın.
              Linkinizi ve QR kodunuzu müşterilerinizle kolayca paylaşın.
            </p>

            {displayCount >= 5 ? (
              <div className="mt-5 flex items-center gap-2 rounded-full border border-[#D0E4E8] bg-white/75 px-4 py-2 text-xs font-bold text-[#475569] dark:border-[#243141] dark:bg-[#131A22]/75 dark:text-[#CBD5E1]">
                <span className="h-2 w-2 rounded-full bg-[#10B981]" />
                VitrinX’te {displayCount} işletme vitrini yayında
              </div>
            ) : null}

            <form
              action="https://app.vitrinx.app"
              method="GET"
              className="mt-8 flex w-full max-w-xl flex-col gap-3 sm:flex-row"
            >
              <label className="flex min-h-14 flex-1 items-center rounded-2xl border border-[#D0E4E8] bg-white px-4 shadow-sm focus-within:border-[#10D8D8] focus-within:ring-4 focus-within:ring-[#10D8D8]/10 dark:border-[#243141] dark:bg-[#1B242F]">
                <span className="select-none text-sm font-bold text-[#64748B] dark:text-[#94A3B8]">
                  vitrinx.app/
                </span>
                <input
                  type="text"
                  name="slug"
                  placeholder="isletmeniz"
                  required
                  aria-label="Vitrin bağlantısı"
                  className="min-w-0 flex-1 border-none bg-transparent py-4 text-sm font-extrabold text-[#182028] outline-none placeholder:text-[#94A3B8] dark:text-white"
                />
              </label>
              <button
                type="submit"
                className="btn-primary min-h-14 rounded-2xl px-7 font-extrabold"
              >
                VitrinX Oluştur
                <svg
                  width="18"
                  height="18"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="2.5"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  aria-hidden="true"
                >
                  <path d="M5 12h14m-6-6 6 6-6 6" />
                </svg>
              </button>
            </form>

            <div className="mt-5 flex flex-wrap justify-center gap-2 md:justify-start">
              {["Kredi kartı gerekmez", "Teknik bilgi gerekmez", "Komisyon yok", "Link ve QR hazır"].map(
                (badge) => (
                  <span
                    key={badge}
                    className="inline-flex items-center gap-1.5 rounded-full border border-[#E2E8F0] bg-white/70 px-3 py-2 text-xs font-bold text-[#334155] dark:border-[#243141] dark:bg-[#131A22]/70 dark:text-[#CBD5E1]"
                  >
                    <CheckIcon className="h-3.5 w-3.5 text-[#10B981]" />
                    {badge}
                  </span>
                ),
              )}
            </div>
          </div>

          <div className="relative mx-auto w-full max-w-lg">
            <div className="absolute inset-8 rounded-[40px] bg-gradient-to-br from-[#10D8D8]/25 to-[#38A0E4]/20 blur-3xl" />
            <div className="relative overflow-hidden rounded-[30px] border border-white/80 bg-white/85 p-5 shadow-[0_24px_70px_rgba(15,23,42,0.14)] backdrop-blur-xl dark:border-[#243141] dark:bg-[#131A22]/90 sm:p-7">
              <div className="flex items-center justify-between border-b border-[#E2E8F0] pb-5 dark:border-[#243141]">
                <div>
                  <p className="text-xs font-bold uppercase tracking-[0.14em] text-[#0EA8B0]">
                    Dijital vitrininiz
                  </p>
                  <h2 className="mt-1 text-2xl font-extrabold">Tek linkte hazır</h2>
                </div>
                <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-[#10D8D8]/12 text-[#0EA8B0]">
                  <FeatureGlyph kind="globe" />
                </div>
              </div>
              <div className="mt-5 grid grid-cols-2 gap-3">
                {[
                  ["qr", "Link ve QR"],
                  ["chat", "WhatsApp"],
                  ["globe", "Adres ve bilgiler"],
                  ["bolt", "Ürün ve hizmetler"],
                ].map(([icon, label]) => (
                  <div
                    key={label}
                    className="rounded-2xl border border-[#E2E8F0] bg-[#F8FAFC] p-4 dark:border-[#243141] dark:bg-[#1B242F]"
                  >
                    <div className="text-[#0EA8B0]">
                      <FeatureGlyph kind={icon as GlyphKind} />
                    </div>
                    <p className="mt-3 text-sm font-extrabold">{label}</p>
                  </div>
                ))}
              </div>
              <div className="mt-4 flex items-center gap-3 rounded-2xl bg-[#10D8D8]/10 p-4 text-sm font-bold text-[#0B7F86] dark:text-[#65E7E7]">
                <CheckIcon className="h-5 w-5 shrink-0" />
                Müşterileriniz size doğrudan ulaşır.
              </div>
            </div>
          </div>
        </main>
      </section>

      <section className="bg-[#F4F5F8] px-5 py-16 dark:bg-[#10161D] sm:px-8 md:py-20">
        <div className="mx-auto flex w-full max-w-6xl flex-col items-center justify-between gap-8 text-center md:flex-row md:text-left">
          <div className="max-w-2xl">
            <h2 className="text-3xl font-extrabold leading-tight tracking-tight sm:text-4xl">
              Müşterileriniz ihtiyaç duyduğu her bilgiye tek linkten ulaşsın
            </h2>
            <p className="mt-4 text-base leading-7 text-[#64748B] dark:text-[#94A3B8]">
              Vitrin linkinizi WhatsApp, sosyal medya, Google İşletme, kartvizit,
              paket veya işletme içi QR kod üzerinden paylaşın.
            </p>
          </div>
          <div className="flex max-w-md flex-wrap justify-center gap-2 md:justify-end">
            {["WhatsApp", "Sosyal medya", "Google İşletme", "QR kod", "Vitrin linki"].map(
              (channel) => (
                <span
                  key={channel}
                  className="rounded-full border border-[#D0E4E8] bg-white px-4 py-2.5 text-xs font-extrabold text-[#334155] dark:border-[#243141] dark:bg-[#131A22] dark:text-[#CBD5E1]"
                >
                  {channel}
                </span>
              ),
            )}
          </div>
        </div>
      </section>

      <section className="bg-white px-5 py-20 dark:bg-[#0B0F13] sm:px-8 md:py-24">
        <div className="mx-auto w-full max-w-6xl">
          <div className="mx-auto max-w-2xl text-center">
            <h2 className="text-3xl font-extrabold tracking-tight sm:text-4xl">
              Dijital vitrininizi kolayca hazırlayın
            </h2>
            <p className="mt-4 text-base leading-7 text-[#64748B] dark:text-[#94A3B8]">
              Müşterilerinizin ihtiyaç duyduğu bilgileri tek vitrinde toplayın,
              panelden yönetin ve istediğiniz yerde paylaşın.
            </p>
          </div>
          <div className="mt-12 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            {whyItems.map((item) => (
              <article
                key={item.title}
                className="flex items-start gap-4 rounded-[22px] border border-[#E2E8F0] bg-[#F8FAFC] p-4 transition-transform duration-200 dark:border-[#243141] dark:bg-[#131A22] sm:block sm:p-5 lg:hover:-translate-y-1"
              >
                <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl bg-[#10D8D8]/10 text-[#0EA8B0]">
                  <FeatureGlyph kind={item.icon} />
                </div>
                <div>
                  <h3 className="text-base font-extrabold leading-6 sm:mt-4 sm:text-lg">
                    {item.title}
                  </h3>
                  <p className="mt-1.5 text-sm leading-6 text-[#64748B] dark:text-[#94A3B8] sm:mt-2">
                    {item.description}
                  </p>
                </div>
              </article>
            ))}
          </div>
        </div>
      </section>

      <section className="bg-[#F1F5F9] px-5 py-20 dark:bg-[#10161D] sm:px-8 md:py-24">
        <div className="mx-auto w-full max-w-6xl">
          <div className="mx-auto max-w-3xl text-center">
            <h2 className="text-3xl font-extrabold tracking-tight sm:text-4xl">
              Dijital vitrininiz için gerekenler tek yerde
            </h2>
            <p className="mt-4 text-base leading-7 text-[#64748B] dark:text-[#94A3B8]">
              Araçları ve kurulumları ayrı ayrı yönetmek yerine işletme
              bilgilerinizi VitrinX’e ekleyin ve paylaşmaya başlayın.
            </p>
          </div>

          <div className="mt-12 grid items-center gap-5 lg:grid-cols-[1fr_auto_1fr]">
            <SetupPanel
              label="Ayrı ayrı kurulum"
              items={separateSetupItems}
              footer="Birden fazla araç ve işlem"
              highlighted={false}
            />
            <div className="flex justify-center">
              <div className="flex h-12 w-12 items-center justify-center rounded-full border border-[#DCE7EA] bg-white text-[#0EA8B0] shadow-[0_10px_24px_rgba(15,23,42,0.09)] dark:border-[#243141] dark:bg-[#131A22]">
                <svg
                  className="h-5 w-5 rotate-90 lg:rotate-0"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="2.4"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  aria-hidden="true"
                >
                  <path d="M5 12h14M13 6l6 6-6 6" />
                </svg>
              </div>
            </div>
            <SetupPanel
              label="VitrinX ile"
              items={vitrinxSetupItems}
              footer="Tek panel, tek link, doğrudan iletişim"
              highlighted
            />
          </div>
        </div>
      </section>

      <section className="bg-white px-5 py-14 dark:bg-[#0B0F13] sm:px-8">
        <div className="mx-auto w-full max-w-6xl text-center">
          <h2 className="text-2xl font-extrabold sm:text-3xl">Başlarken sürpriz yok</h2>
          <div className="mt-7 flex flex-wrap justify-center gap-3">
            {trustItems.map((item) => (
              <span
                key={item}
                className="inline-flex items-center gap-2 rounded-full border border-[#DCE7EA] bg-[#F8FAFC] px-4 py-3 text-xs font-extrabold text-[#334155] dark:border-[#243141] dark:bg-[#131A22] dark:text-[#CBD5E1]"
              >
                <CheckIcon className="h-4 w-4 text-[#10B981]" />
                {item}
              </span>
            ))}
          </div>
        </div>
      </section>

      <section className="bg-[#F8FAFC] px-5 py-20 dark:bg-[#10161D] sm:px-8 md:py-24">
        <div className="mx-auto w-full max-w-5xl">
          <h2 className="text-center text-3xl font-extrabold tracking-tight sm:text-4xl">
            Üç adımda vitrininiz hazır
          </h2>
          <div className="mt-12 grid gap-8 md:grid-cols-3">
            {steps.map((step, index) => (
              <div key={step.title} className="text-center">
                <div className="mx-auto flex h-14 w-14 items-center justify-center rounded-full border-2 border-[#10D8D8]/35 bg-[#10D8D8]/8 text-xl font-extrabold text-[#0EA8B0]">
                  {index + 1}
                </div>
                <h3 className="mt-5 text-lg font-extrabold">{step.title}</h3>
                <p className="mt-2 text-sm leading-6 text-[#64748B] dark:text-[#94A3B8]">
                  {step.description}
                </p>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="bg-gradient-to-br from-[#0F172A] via-[#0B6670] to-[#10D8D8] px-5 py-20 text-white sm:px-8 md:py-24">
        <div className="mx-auto flex max-w-3xl flex-col items-center text-center">
          <h2 className="text-3xl font-extrabold leading-tight tracking-tight text-white sm:text-4xl">
            İşletmenizi tek linkte müşterilerinizle buluşturun
          </h2>
          <p className="mt-5 max-w-2xl text-base leading-7 text-white/80 sm:text-lg">
            VitrinX’inizi oluşturun; linkinizi, QR kodunuzu ve WhatsApp
            iletişiminizi paylaşmaya başlayın.
          </p>
          <Link
            href="https://app.vitrinx.app"
            className="mt-9 inline-flex min-h-14 items-center justify-center rounded-2xl bg-[#10D8D8] px-8 text-base font-extrabold text-white shadow-[0_14px_35px_rgba(16,216,216,0.28)] transition-transform hover:-translate-y-1"
          >
            VitrinX Oluştur
          </Link>
        </div>
      </section>

      <footer className="border-t border-[#D0E4E8] bg-white px-5 py-10 dark:border-[#243141] dark:bg-[#0B0F13] sm:px-8">
        <div className="mx-auto flex w-full max-w-6xl flex-col items-center justify-between gap-5 text-center sm:flex-row sm:text-left">
          <div>
            <p className="font-extrabold tracking-[0.24em] text-[#0EA8B0]">VITRINX</p>
            <p className="mt-2 text-sm text-[#64748B] dark:text-[#94A3B8]">
              İşletmenizin paylaşılabilir dijital vitrini
            </p>
          </div>
          <div className="flex flex-wrap justify-center gap-5 text-sm">
            <Link
              href="https://app.vitrinx.app"
              className="font-semibold text-[#64748B] transition-colors hover:text-[#10D8D8] dark:text-[#94A3B8]"
            >
              Yönetici Paneli
            </Link>
            <Link
              href="https://app.vitrinx.app/kesfet"
              className="font-semibold text-[#64748B] transition-colors hover:text-[#10D8D8] dark:text-[#94A3B8]"
            >
              Keşfet
            </Link>
          </div>
        </div>
      </footer>
    </div>
  );
}

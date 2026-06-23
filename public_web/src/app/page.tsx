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
    title: "Dakikalar içinde hazır",
    description: "Bilgilerinizi ekleyin ve vitrininizi yayınlayın.",
  },
  {
    icon: "code",
    title: "Teknik bilgi gerekmez",
    description: "Kod, hosting veya SSL ayarıyla uğraşmayın.",
  },
  {
    icon: "chat",
    title: "WhatsApp ile doğrudan iletişim",
    description: "Müşterileriniz aracı olmadan size ulaşsın.",
  },
  {
    icon: "qr",
    title: "Link ve QR ile paylaşım",
    description: "Sosyal medya, kartvizit, paket ve işletme içinde paylaşın.",
  },
  {
    icon: "percent",
    title: "Satıştan komisyon yok",
    description: "Müşterilerinizle doğrudan iletişim kurun.",
  },
  {
    icon: "globe",
    title: "Ayrı web sitesi kurmadan başlayın",
    description: "Domain, hosting veya ajans süreci beklemeyin.",
  },
] as const;

const comparisonItems = [
  {
    classic: "Hazırlık günler veya haftalar sürebilir",
    vitrinx: "Dakikalar içinde başlanabilir",
  },
  {
    classic: "Domain, hosting ve SSL yönetimi gerekir",
    vitrinx: "Teknik altyapı hazır gelir",
  },
  {
    classic: "WhatsApp ve QR ayrıca eklenir",
    vitrinx: "WhatsApp, link ve QR hazırdır",
  },
  {
    classic: "Güncelleme teknik destek gerektirebilir",
    vitrinx: "Bilgiler panelden düzenlenir",
  },
  {
    classic: "Kurulum ve bakım maliyetleri oluşabilir",
    vitrinx: "Ayrı web sitesi kurmadan başlanabilir",
  },
  {
    classic: "Pazaryeri komisyonu olabilir",
    vitrinx: "VitrinX satıştan komisyon almaz",
  },
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

type GlyphKind = (typeof whyItems)[number]["icon"];

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
    code: (
      <>
        <path d="m8 9-3 3 3 3" />
        <path d="m16 9 3 3-3 3" />
        <path d="m14 5-4 14" />
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
    percent: (
      <>
        <path d="m19 5-14 14" />
        <circle cx="7" cy="7" r="2" />
        <circle cx="17" cy="17" r="2" />
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
              Teknik kurulumla uğraşmadan işletmenizi müşterileriniz için
              erişilebilir hale getirin.
            </p>
          </div>
          <div className="mt-12 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {whyItems.map((item) => (
              <article
                key={item.title}
                className="rounded-[22px] border border-[#E2E8F0] bg-[#F8FAFC] p-5 transition-transform duration-200 hover:-translate-y-1 dark:border-[#243141] dark:bg-[#131A22]"
              >
                <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-[#10D8D8]/10 text-[#0EA8B0]">
                  <FeatureGlyph kind={item.icon} />
                </div>
                <h3 className="mt-4 text-lg font-extrabold">{item.title}</h3>
                <p className="mt-2 text-sm leading-6 text-[#64748B] dark:text-[#94A3B8]">
                  {item.description}
                </p>
              </article>
            ))}
          </div>
        </div>
      </section>

      <section className="bg-[#F1F5F9] px-5 py-20 dark:bg-[#10161D] sm:px-8 md:py-24">
        <div className="mx-auto w-full max-w-5xl">
          <div className="mx-auto max-w-3xl text-center">
            <h2 className="text-3xl font-extrabold tracking-tight sm:text-4xl">
              İşletmenizi dijitale taşımanın kolay yolu
            </h2>
            <p className="mt-4 text-base leading-7 text-[#64748B] dark:text-[#94A3B8]">
              Web sitesi farklı ihtiyaçlar için güçlü bir çözüm olabilir.
              VitrinX, hızlı ve teknik yük olmadan dijital vitrin oluşturmak
              isteyen işletmeler için hazırlanmıştır.
            </p>
          </div>

          <div className="mt-12 overflow-hidden rounded-[28px] border border-[#DCE7EA] bg-white shadow-[0_20px_55px_rgba(15,23,42,0.08)] dark:border-[#243141] dark:bg-[#131A22]">
            <div className="hidden grid-cols-2 gap-8 border-b border-[#E2E8F0] bg-[#F8FAFC] px-6 py-4 text-xs font-extrabold md:grid dark:border-[#243141] dark:bg-[#1B242F]">
              <span className="text-[#64748B] dark:text-[#94A3B8]">
                Geleneksel web sitesi süreci
              </span>
              <span className="text-[#0EA8B0] dark:text-[#10D8D8]">
                VitrinX ile başlangıç
              </span>
            </div>
            {comparisonItems.map((item, index) => (
              <div
                key={item.classic}
                className={`grid gap-4 px-5 py-5 md:grid-cols-2 md:gap-8 md:px-6 ${
                  index < comparisonItems.length - 1
                    ? "border-b border-[#E2E8F0] dark:border-[#243141]"
                    : ""
                }`}
              >
                <div>
                  <span className="text-[11px] font-extrabold uppercase tracking-wider text-[#94A3B8] md:hidden">
                    Web sitesi süreci
                  </span>
                  <p className="mt-1 text-sm font-semibold leading-6 text-[#64748B] dark:text-[#94A3B8] md:mt-0">
                    {item.classic}
                  </p>
                </div>
                <div>
                  <span className="text-[11px] font-extrabold uppercase tracking-wider text-[#0EA8B0] md:hidden">
                    VitrinX
                  </span>
                  <p className="mt-1 flex items-start gap-2 text-sm font-extrabold leading-6 md:mt-0">
                    <CheckIcon className="mt-1 h-4 w-4 shrink-0 text-[#10B981]" />
                    {item.vitrinx}
                  </p>
                </div>
              </div>
            ))}
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

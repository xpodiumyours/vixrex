import Link from "next/link";
import { VixrexAvatar } from "@/app/v/[slug]/components/VixrexAvatar";
import { KesfetIkonu, OnayIkonu, IleriOkIkonu, GirisIkonu } from "@/components/site/icons";
import { getSiteUrl } from "@/lib/siteUrl";
import { HeroTelefonSahnesi } from "./HeroTelefonSahnesi";
import type { MockupProfili } from "./mockupProfilleri";

/** Hero — envanter §2.2. Flutter referans: landing_hero_section.dart:613-616 (4 rozet) */
const GUVEN_ROZETLERI = [
  "SSL Güvenli Koruma",
  "Kredi kartı gerekmez",
  "Komisyon yok",
  "Link ve QR hazır",
] as const;

/**
 * Bilinçli sapma — hareket yok:
 * Uygulamada (landing_hero_section.dart:65-100) üç mesh glow sin/cos ile
 * yavaşça salınıyor. Web'de sabit duruyor: salınımın orta noktası alındı.
 * Sebep: CSS keyframes ile sonsuz hareket görsel regresyon testlerini her
 * koşuda oynatır (playwright --update-snapshots flaky). Sabit glow görsel
 * zenginliği verir, testi stabil tutar.
 */
export function HeroSection({
  profiller,
  blogErisimi = false,
  isChatOpen = false,
  initialAssistantName = "",
  onStartAssistant,
  onChatClose,
}: {
  profiller: MockupProfili[];
  blogErisimi?: boolean;
  isChatOpen?: boolean;
  initialAssistantName?: string;
  onStartAssistant: (initialName: string) => void;
  onChatClose?: () => void;
}) {
  // Adres ön eki tek kaynaktan gelir; alan adı bağlandığında bu metin de
  // kendiliğinden düzelir (envanter §4, açık madde 5).
  const adresOneki = `${getSiteUrl().replace(/^https?:\/\//, "")}/v/`;

  return (
    <>
      <header className="sticky top-0 z-40 border-b border-white/10 bg-[#050B1A]/85 backdrop-blur-xl lp-yan-bosluk">
        {/* Top Nav — Flutter landing_hero_section.dart:189-363 ile parite */}
        <nav
          aria-label="Ana gezinme"
          className="relative mx-auto flex w-full max-w-lp items-center justify-between py-3.5"
        >
          <Link
            href="/"
            className="group flex items-center gap-2.5 text-lp-text"
            aria-label="Vixrex ana sayfa"
          >
            <VixrexAvatar size={36} halo decorative />
            <span className="text-[20px] font-black tracking-[-0.5px]">Vixrex</span>
          </Link>
          <div className="hidden items-center gap-8 lg:flex">
            <Link
              href="#neden-vixrex"
              className="text-[14px] font-bold text-white/75 transition-colors hover:text-white"
            >
              Neden Vixrex?
            </Link>
            <Link
              href="#nasil-calisir"
              onClick={(e) => {
                e.preventDefault();
                document.getElementById("nasil-calisir")?.scrollIntoView({ behavior: "smooth" });
              }}
              className="text-[14px] font-bold text-white/75 transition-colors hover:text-white"
            >
              Nasıl Çalışır?
            </Link>
          </div>
          <div className="flex items-center gap-2.5">
            {blogErisimi ? (
              <Link
                href="/blog"
                className="inline-flex min-h-11 items-center rounded-lg px-2 text-sm font-semibold text-lp-text outline-none hover:text-lp-secondary focus-visible:ring-2 focus-visible:ring-lp-secondary"
              >
                Blog
              </Link>
            ) : null}
            {/* Vitrinleri Keşfet — Flutter: rounded-[14px], border lp-primary/45 */}
            <Link
              href="/kesfet"
              className="hidden items-center gap-2 rounded-[14px] border border-sky-400/35 bg-[#147DFF]/15 px-4 py-2.5 text-[12px] font-black text-sky-200 backdrop-blur-md transition-colors hover:border-sky-400/60 hover:bg-[#147DFF]/25 md:flex"
              aria-label="Vitrinleri Keşfet"
            >
              <KesfetIkonu boyut={16} />
              Vitrinleri Keşfet
            </Link>
            <Link
              href="/kesfet"
              className="flex h-10 w-10 items-center justify-center rounded-[14px] border border-white/15 bg-white/[0.06] text-lp-text backdrop-blur-md md:hidden"
              aria-label="Vitrinleri Keşfet"
            >
              <KesfetIkonu boyut={18} />
            </Link>
            {/* Giriş Yap — Flutter: rounded-[14px], Icons.login_rounded ikonu */}
            <Link
              href="/giris"
              className="hidden items-center gap-2 rounded-[14px] bg-gradient-to-r from-[#147DFF] to-[#2563EB] px-4 py-2.5 text-[12px] font-black text-white shadow-lg shadow-[#147DFF]/30 transition-all hover:from-[#2589FF] hover:to-[#1D4ED8] md:flex"
            >
              <GirisIkonu boyut={16} />
              Giriş Yap
            </Link>
            <Link
              href="/giris"
              className="flex h-10 w-10 items-center justify-center rounded-[14px] bg-gradient-to-r from-[#147DFF] to-[#2563EB] text-white shadow-lg shadow-[#147DFF]/30 md:hidden"
              aria-label="Giriş Yap"
            >
              <GirisIkonu boyut={18} />
            </Link>
          </div>
        </nav>
      </header>

      <section
        id="vixrex-hero"
        className="relative overflow-x-clip lp-yan-bosluk pb-lp-section pt-8 sm:pt-10 lg:pt-12"
      >
        <div className="relative mx-auto grid w-full max-w-lp grid-cols-1 items-center gap-8 md:grid-cols-12 lg:gap-10">
          <div className="z-10 w-full md:col-span-5">
            <p className="inline-block rounded-[30px] border border-sky-400/45 bg-[#147DFF]/20 px-3.5 py-2 text-[11px] font-black tracking-[1px] text-sky-300 backdrop-blur-md">
              VİXREX ASİSTAN İLE DİJİTAL VİTRİN
            </p>

            <h1 className="mt-5 text-[36px] font-black leading-[1.12] tracking-[-0.8px] text-lp-text md:text-[48px]">
              Vitrininiz
              <br />
              <span className="bg-gradient-to-r from-[#38BDF8] via-[#147DFF] to-[#60A5FA] bg-clip-text text-transparent">
                Vixrex Asistan
              </span>{" "}
              ile
              <br />
              birkaç dakikada hazır
            </h1>

            <p className="mt-5 max-w-[540px] text-[16px] font-medium leading-[1.58] text-white/75">
              İşletme bilgilerini, fotoğraflarını, ürün ve hizmetlerini, adresini
              ve WhatsApp iletişimini Vixrex Asistan ile konuşarak tek vitrinde
              topla.
            </p>

            {/*
              Kurulum başlangıcı — uygulamadaki iki kutulu yapıyla eşitlenir
              (landing_hero_section.dart:495-541). Flutter kendi form
              container'ını 500px'de ölçer; web de viewport yerine aynı gerçek
              alanı container query ile ölçer.
            */}
            <div className="mt-8 @container">
              <form
                onSubmit={(event) => {
                  event.preventDefault();
                  const form = new FormData(event.currentTarget);
                  const isletmeAdi = String(form.get("isletme") ?? "");
                  onStartAssistant(isletmeAdi.trim());
                }}
                className="flex flex-col gap-3 @min-[500px]:flex-row @min-[500px]:items-center"
              >
                <div className="flex h-[52px] min-w-0 flex-1 items-center overflow-hidden rounded-2xl border border-white/[0.14] bg-white/[0.06] backdrop-blur-md transition focus-within:border-[#147DFF] focus-within:shadow-[0_0_0_3px_rgba(20,125,255,0.22)]">
                  <span className="hidden whitespace-nowrap pl-4 pr-1 text-[14px] font-bold text-white/60 sm:inline">
                    {adresOneki}
                  </span>
                  <span
                    aria-hidden="true"
                    className="pl-4 pr-1 text-[14px] font-bold text-white/60 sm:hidden"
                  >
                    /v/
                  </span>
                  <input
                    type="text"
                    name="isletme"
                    placeholder="isletmeniz"
                    className="h-full min-w-0 flex-1 bg-transparent pr-3 text-[14px] font-bold text-white outline-none placeholder:text-white/30"
                  />
                </div>
                <button
                  type="submit"
                  className="flex h-[52px] shrink-0 items-center justify-center gap-2 rounded-2xl bg-gradient-to-r from-[#147DFF] to-[#2563EB] px-6 text-[15px] font-black text-white shadow-xl shadow-[#147DFF]/35 transition-all hover:-translate-y-0.5 hover:from-[#2589FF] hover:to-[#1D4ED8] active:scale-[0.98]"
                >
                  Ücretsiz Vitrinimi Hazırla
                  <IleriOkIkonu boyut={16} />
                </button>
              </form>
            </div>

            <ul className="mt-6 flex flex-wrap gap-2.5">
              {GUVEN_ROZETLERI.map((rozet) => (
                <li
                  key={rozet}
                  className="flex items-center gap-2 rounded-[20px] border border-white/[0.1] bg-white/[0.06] px-3.5 py-2 text-[12px] font-bold text-white/80 backdrop-blur-md"
                >
                  <span className="text-lp-mint">
                    <OnayIkonu boyut={16} />
                  </span>
                  {rozet}
                </li>
              ))}
            </ul>
          </div>

          <div className="flex w-full justify-center md:col-span-7">
            <HeroTelefonSahnesi
              profiller={profiller}
              isChatOpen={isChatOpen}
              initialAssistantName={initialAssistantName}
              onOpenChat={() => onStartAssistant("")}
              onChatClose={onChatClose}
            />
          </div>
        </div>

        <div className="relative mx-auto mt-12 grid w-full max-w-lp grid-cols-1 gap-4 sm:grid-cols-3">
          {[
            { simge: "⚡", baslik: "Hızlı Kurulum", alt: "Dakikalar içinde hazır" },
            { simge: "👥", baslik: "Tüm İşletmeler İçin", alt: "Küçük, orta, büyük fark etmez" },
            { simge: "💙", baslik: "Müşterine Daha Yakın", alt: "Tek link ile her yerde" },
          ].map((ozellik) => (
            <div
              key={ozellik.baslik}
              className="lp-glass-panel flex items-center gap-3.5 rounded-2xl p-4"
            >
              <span className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-[#147DFF]/20 text-[20px] text-lp-primary">
                {ozellik.simge}
              </span>
              <span>
                <span className="block text-[14px] font-extrabold text-white">
                  {ozellik.baslik}
                </span>
                <span className="block text-[12px] font-semibold text-white/60">
                  {ozellik.alt}
                </span>
              </span>
            </div>
          ))}
        </div>
      </section>
    </>
  );
}

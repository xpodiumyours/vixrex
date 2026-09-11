import Link from "next/link";
import { KesfetIkonu, OnayIkonu, IleriOkIkonu, StorefrontIkonu, GirisIkonu } from "@/components/site/icons";
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
  isChatOpen = false,
  initialAssistantName = "",
  onStartAssistant,
  onChatClose,
}: {
  profiller: MockupProfili[];
  isChatOpen?: boolean;
  initialAssistantName?: string;
  onStartAssistant: (initialName: string) => void;
  onChatClose?: () => void;
}) {
  // Adres ön eki tek kaynaktan gelir; alan adı bağlandığında bu metin de
  // kendiliğinden düzelir (envanter §4, açık madde 5).
  const adresOneki = `${getSiteUrl().replace(/^https?:\/\//, "")}/v/`;

  return (
    <section id="vixrex-hero" className="relative overflow-hidden bg-gradient-to-b from-lp-bg-editor to-lp-bg-light lp-yan-bosluk pb-lp-section pt-0">
      {/* Top Nav — Flutter landing_hero_section.dart:189-363 ile parite */}
      <nav
        aria-label="Ana gezinme"
        className="relative mx-auto flex w-full max-w-lp items-center justify-between py-4"
      >
        <Link
          href="/"
          className="flex items-center gap-2 text-lp-text"
          aria-label="Vixrex ana sayfa"
        >
          <span className="flex h-9 w-9 items-center justify-center rounded-full bg-lp-primary/15 text-lp-primary">
            <StorefrontIkonu boyut={20} />
          </span>
          <span className="text-[20px] font-black tracking-[-0.5px]">Vixrex</span>
        </Link>
        <div className="hidden items-center gap-8 lg:flex">
          <Link
            href="#neden-vixrex"
            className="text-[14px] font-bold text-white/70 transition-colors hover:text-white"
          >
            Neden Vixrex?
          </Link>
          <Link
            href="#nasil-calisir"
            className="text-[14px] font-bold text-white/70 transition-colors hover:text-white"
          >
            Nasıl Çalışır?
          </Link>
        </div>
        <div className="flex items-center gap-2.5">
          {/* Vitrinleri Keşfet — Flutter: rounded-[14px], border lp-primary/45 */}
          <Link
            href="/kesfet"
            className="hidden items-center gap-2 rounded-[14px] border border-lp-primary/45 bg-lp-surface-soft px-4 py-3 text-[12px] font-black text-lp-primary transition-colors hover:bg-lp-surface md:flex"
            aria-label="Vitrinleri Keşfet"
          >
            <KesfetIkonu boyut={16} />
            Vitrinleri Keşfet
          </Link>
          <Link
            href="/kesfet"
            className="flex h-10 w-10 items-center justify-center rounded-[14px] border border-lp-border bg-lp-surface-soft text-lp-text md:hidden"
            aria-label="Vitrinleri Keşfet"
          >
            <KesfetIkonu boyut={18} />
          </Link>
          {/* Giriş Yap — Flutter: rounded-[14px], Icons.login_rounded ikonu */}
          <Link
            href="/giris"
            className="hidden items-center gap-2 rounded-[14px] bg-lp-primary px-4 py-3 text-[12px] font-black text-lp-on-primary transition-colors hover:opacity-90 md:flex"
          >
            <GirisIkonu boyut={16} />
            Giriş Yap
          </Link>
          <Link
            href="/giris"
            className="flex h-10 w-10 items-center justify-center rounded-[14px] bg-lp-primary text-lp-on-primary md:hidden"
            aria-label="Giriş Yap"
          >
            <GirisIkonu boyut={18} />
          </Link>
        </div>
      </nav>
      {/* Ambient Mesh Glows — Flutter landing_hero_section.dart:65-100 orta noktası */}
      <div
        aria-hidden="true"
        className="pointer-events-none absolute inset-0 overflow-hidden"
      >
        <div
          aria-hidden="true"
          className="absolute rounded-full"
          style={{
            width: 300,
            height: 300,
            top: 100,
            left: -100,
            background:
              "radial-gradient(closest-side, color-mix(in srgb, var(--color-lp-primary) 30%, transparent), transparent)",
          }}
        />
        <div
          aria-hidden="true"
          className="absolute rounded-full"
          style={{
            width: 400,
            height: 400,
            bottom: 50,
            right: -50,
            background:
              "radial-gradient(closest-side, color-mix(in srgb, var(--color-lp-secondary) 25%, transparent), transparent)",
          }}
        />
        <div
          aria-hidden="true"
          className="absolute rounded-full"
          style={{
            width: 250,
            height: 250,
            top: 200,
            right: 150,
            background:
              "radial-gradient(closest-side, color-mix(in srgb, var(--color-lp-pink) 20%, transparent), transparent)",
          }}
        />
        <div
          aria-hidden="true"
          className="absolute hidden rounded-full md:block"
          style={{
            width: 560,
            height: 560,
            top: 40,
            right: -80,
            background:
              "radial-gradient(closest-side, color-mix(in srgb, var(--color-lp-primary) 22%, transparent), transparent)",
          }}
        />
      </div>
      <div className="relative mx-auto mt-5 flex w-full max-w-lp flex-col items-center gap-10 md:mt-10 md:flex-row md:items-center md:gap-10">
        <div className="w-full flex-1">
          <p className="inline-block rounded-[30px] border border-lp-secondary/45 bg-lp-primary/[0.18] px-3.5 py-2 text-[11px] font-black tracking-[1px] text-lp-secondary">
            VİXREX ASİSTAN İLE DİJİTAL VİTRİN
          </p>

          <h1 className="mt-5 text-[36px] font-black leading-[1.15] tracking-[-0.8px] text-lp-text md:text-[48px]">
            Vitrininiz
            <br />
            <span className="text-lp-secondary">Vixrex Asistan</span> ile
            <br />
            birkaç dakikada hazır
          </h1>

          <p className="mt-5 max-w-[560px] text-[16px] font-medium leading-[1.5] text-white/70">
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
              <div className="flex h-[52px] flex-1 items-center overflow-hidden rounded-2xl border border-white/[0.12] bg-white/[0.06]">
                <span className="hidden whitespace-nowrap px-4 text-[14px] font-bold text-white/60 sm:inline">{adresOneki}</span>
                <span className="px-4 text-[14px] font-bold text-white/60 sm:hidden">/v/</span>
                <input
                  type="text"
                  name="isletme"
                  placeholder="isletmeniz"
                  className="h-full flex-1 bg-transparent text-[14px] font-bold text-white outline-none placeholder:text-white/30"
                />
              </div>
              <button
                type="submit"
                className="flex h-[52px] items-center justify-center gap-2 rounded-2xl bg-lp-primary px-6 text-[15px] font-black text-lp-on-primary transition-transform hover:-translate-y-0.5"
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
                className="flex items-center gap-2 rounded-[20px] border border-white/[0.08] bg-white/[0.06] px-3.5 py-2 text-[12px] font-bold text-white/70"
              >
                <span className="text-lp-mint">
                  <OnayIkonu boyut={16} />
                </span>
                {rozet}
              </li>
            ))}
          </ul>
        </div>

        <div className="flex w-full justify-center md:flex-1">
          <HeroTelefonSahnesi
            profiller={profiller}
            isChatOpen={isChatOpen}
            initialAssistantName={initialAssistantName}
            onChatClose={onChatClose}
          />
        </div>
      </div>
      <div className="relative mx-auto mt-12 grid w-full max-w-lp grid-cols-1 gap-6 sm:grid-cols-3">
        {[
          { simge: "⚡", baslik: "Hızlı Kurulum", alt: "Dakikalar içinde hazır" },
          { simge: "👥", baslik: "Tüm İşletmeler İçin", alt: "Küçük, orta, büyük fark etmez" },
          { simge: "💙", baslik: "Müşterine Daha Yakın", alt: "Tek link ile her yerde" },
        ].map((ozellik) => (
          <div key={ozellik.baslik} className="flex items-center gap-3.5">
            <span className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-lp-primary/15 text-[20px] text-lp-primary">
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
  );
}

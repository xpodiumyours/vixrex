import Link from "next/link";
import { getSiteUrl } from "@/lib/siteUrl";
import { PhoneMockup } from "./PhoneMockup";
import type { MockupProfili } from "./mockupProfilleri";
import { MaterialRoundIcon } from "./MaterialRoundIcon";
import styles from "./landingFlutterParity.module.css";

const GUVEN_ROZETLERI = [
  "SSL Güvenli Koruma",
  "Kredi kartı gerekmez",
  "Komisyon yok",
  "Link ve QR hazır",
] as const;

/** Flutter `landing_hero_section.dart` referansına göre Next.js hero yüzeyi. */
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
  const adresOneki = `${getSiteUrl().replace(/^https?:\/\//, "")}/v/`;

  return (
    <>
      <link
        rel="stylesheet"
        href="https://fonts.googleapis.com/icon?family=Material+Icons+Round&display=block"
        precedence="default"
      />

      <section
        id="vixrex-hero"
        className="relative overflow-hidden bg-gradient-to-b from-lp-bg-editor to-lp-bg-light pb-[50px] min-[769px]:pb-[100px]"
      >
        <nav
          aria-label="Ana gezinme"
          className="relative z-20 mx-auto flex w-full items-center justify-between px-5 py-4 min-[769px]:px-10"
        >
          <Link
            href="/"
            className="flex items-center gap-2 text-lp-text focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-lp-primary"
            aria-label="Vixrex ana sayfa"
          >
            <span className="flex h-9 w-9 items-center justify-center rounded-full bg-lp-primary/15 text-lp-primary">
              <MaterialRoundIcon name="storefront" size={20} />
            </span>
            <span className="text-[20px] font-black tracking-[-0.5px]">Vixrex</span>
          </Link>

          <div className="flex items-center gap-2.5">
            <Link
              href="/kesfet"
              className="hidden items-center gap-2 rounded-[14px] border border-lp-primary/45 bg-lp-surface-soft px-4 py-3 text-[12px] font-black text-lp-primary focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-lp-primary min-[769px]:flex"
            >
              <MaterialRoundIcon name="explore" size={16} />
              Vitrinleri Keşfet
            </Link>
            <Link
              href="/kesfet"
              className="flex h-10 w-10 items-center justify-center rounded-[14px] border border-lp-border bg-lp-surface-soft text-lp-text focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-lp-primary min-[769px]:hidden"
              aria-label="Vitrinleri Keşfet"
            >
              <MaterialRoundIcon name="explore" size={18} />
            </Link>

            <Link
              href="/giris"
              className="hidden items-center gap-2 rounded-[14px] bg-lp-primary px-4 py-3 text-[12px] font-black text-lp-on-primary focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-lp-secondary min-[769px]:flex"
            >
              <MaterialRoundIcon name="login" size={16} />
              Giriş Yap
            </Link>
            <Link
              href="/giris"
              className="flex h-10 w-10 items-center justify-center rounded-[14px] bg-lp-primary text-lp-on-primary focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-lp-secondary min-[769px]:hidden"
              aria-label="Giriş Yap"
            >
              <MaterialRoundIcon name="login" size={18} />
            </Link>
          </div>
        </nav>

        <div aria-hidden="true" className="pointer-events-none absolute inset-0 overflow-hidden">
          <div
            className={`${styles.meshOne} absolute rounded-full`}
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
            className={`${styles.meshTwo} absolute rounded-full`}
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
            className={`${styles.meshThree} absolute rounded-full`}
            style={{
              width: 250,
              height: 250,
              top: 200,
              right: 150,
              background:
                "radial-gradient(closest-side, color-mix(in srgb, var(--color-lp-pink) 20%, transparent), transparent)",
            }}
          />
        </div>

        <div className="relative z-10 mx-auto w-full max-w-[1200px] px-6 pt-5 min-[769px]:pt-10">
          <div className="flex flex-col items-center gap-10 min-[769px]:flex-row min-[769px]:items-center">
            <div className="w-full flex-1 text-center min-[769px]:max-w-[560px] min-[769px]:text-left">
              <p className="inline-block rounded-[30px] border border-lp-secondary/45 bg-lp-primary/[0.18] px-3.5 py-2 text-[11px] font-black tracking-[1px] text-lp-secondary">
                VİXREX ASİSTAN İLE DİJİTAL VİTRİN
              </p>

              <h1 className="mt-[18px] text-[36px] font-black leading-[1.15] tracking-[-0.8px] text-lp-text min-[769px]:text-[48px]">
                Vitrininiz
                <br />
                <span className="text-lp-secondary">Vixrex Asistan</span> ile
                <br />
                birkaç dakikada hazır
              </h1>

              <p className="mx-auto mt-5 max-w-[560px] text-[16px] font-medium leading-[1.5] text-white/70 min-[769px]:mx-0">
                İşletme bilgilerini, fotoğraflarını, ürün ve hizmetlerini, adresini
                ve WhatsApp iletişimini Vixrex Asistan ile konuşarak tek vitrinde
                topla.
              </p>

              <form
                onSubmit={(event) => {
                  event.preventDefault();
                  const form = new FormData(event.currentTarget);
                  const isletmeAdi = String(form.get("isletme") ?? "");
                  onStartAssistant(isletmeAdi.trim());
                }}
                className="mt-8 flex flex-col gap-3 min-[501px]:flex-row min-[501px]:items-center"
              >
                <div className="flex h-[52px] flex-1 items-center overflow-hidden rounded-2xl border border-white/[0.12] bg-white/[0.06] text-left">
                  <span className="hidden whitespace-nowrap px-[14px] text-[14px] font-bold text-white/60 sm:inline">
                    {adresOneki}
                  </span>
                  <span className="px-[14px] text-[14px] font-bold text-white/60 sm:hidden">/v/</span>
                  <input
                    type="text"
                    name="isletme"
                    placeholder="isletmeniz"
                    className="h-full min-w-0 flex-1 bg-transparent pr-[14px] text-[14px] font-bold text-white outline-none placeholder:text-white/30"
                  />
                </div>
                <button
                  type="submit"
                  className="flex h-[52px] items-center justify-center gap-2 rounded-2xl bg-lp-primary px-6 text-[15px] font-black text-lp-on-primary focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-lp-secondary"
                >
                  Ücretsiz Vitrinimi Hazırla
                  <MaterialRoundIcon name="arrow_forward" size={16} />
                </button>
              </form>

              <ul className="mt-6 flex flex-wrap justify-center gap-2.5 min-[769px]:justify-start">
                {GUVEN_ROZETLERI.map((rozet) => (
                  <li
                    key={rozet}
                    className="flex items-center gap-1.5 rounded-[20px] border border-white/[0.08] bg-white/[0.06] px-3 py-2 text-[12px] font-bold text-white/70"
                  >
                    <span className="text-lp-mint">
                      <MaterialRoundIcon name="check_circle" size={16} />
                    </span>
                    {rozet}
                  </li>
                ))}
              </ul>
            </div>

            <div className="flex w-full flex-1 justify-center">
              <PhoneMockup
                profiller={profiller}
                isChatOpen={isChatOpen}
                initialAssistantName={initialAssistantName}
                onChatClose={onChatClose}
              />
            </div>
          </div>
        </div>
      </section>
    </>
  );
}

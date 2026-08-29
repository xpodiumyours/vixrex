import { OnayIkonu, IleriOkIkonu } from "@/components/site/icons";
import { getSiteUrl } from "@/lib/siteUrl";
import { PhoneMockup } from "./PhoneMockup";
import type { MockupProfili } from "./mockupProfilleri";

/** Hero — envanter §2.2. */
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
    <section id="vixrex-hero" className="relative overflow-hidden bg-gradient-to-b from-lp-bg-editor to-lp-bg-light px-6 pb-[50px] pt-5 md:pb-[100px] md:pt-10">
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
      </div>
      <div className="relative mx-auto flex w-full max-w-[1200px] flex-col items-center gap-10 md:flex-row md:items-center md:gap-10">
        <div className="w-full flex-1 md:max-w-[560px]">
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
            (landing_hero_section.dart:495-541). Girilen ad yeni bir route'a
            değil, telefon içindeki mevcut Vixrex Asistan akışına aktarılır.
          */}
          <form
            onSubmit={(event) => {
              event.preventDefault();
              const form = new FormData(event.currentTarget);
              const isletmeAdi = String(form.get("isletme") ?? "");
              onStartAssistant(isletmeAdi.trim());
            }}
            className="mt-8 flex flex-col gap-3 min-[500px]:flex-row min-[500px]:items-center"
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

          <ul className="mt-6 flex flex-wrap gap-2.5">
            {GUVEN_ROZETLERI.map((rozet) => (
              <li
                key={rozet}
                className="flex items-center gap-1.5 rounded-[20px] border border-white/[0.08] bg-white/[0.06] px-3 py-2 text-[12px] font-bold text-white/70"
              >
                <span className="text-lp-mint">
                  <OnayIkonu boyut={16} />
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
    </section>
  );
}

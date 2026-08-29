import Link from "next/link";
import { KesfetIkonu, StorefrontIkonu } from "./icons";

/**
 * Platform yüzeyinin üst gezinmesi (envanter §2.1).
 *
 * Sunucu bileşenidir, sıfır istemci JavaScript'i taşır. Flutter'daki
 * karşılığı oturum durumuna göre "Giriş Yap"/"Çıkış Yap" gösteriyor;
 * web'de henüz hesap oturumu yok (Faz 2), o yüzden giriş bağlantısı
 * şimdilik uygulamaya gider.
 *
 * DİKKAT: bu bileşen kök `layout.tsx`'e KONMAZ — o layout `/v/[slug]`
 * vitrin sayfalarını da sarıyor. Yalnız `(site)` route grubunda yaşar.
 */
export function SiteHeader() {
  return (
    <header className="bg-lp-bg-editor">
      <nav
        aria-label="Ana gezinme"
        className="mx-auto flex w-full max-w-[1200px] items-center justify-between px-6 py-4 md:px-6"
      >
        <Link
          href="/"
          className="flex items-center gap-2.5 text-lp-text"
          aria-label="Vixrex ana sayfa"
        >
          <span className="flex h-9 w-9 items-center justify-center rounded-full bg-lp-primary/15 text-lp-primary">
            <StorefrontIkonu boyut={20} />
          </span>
          <span className="text-[20px] font-black tracking-[-0.5px]">
            Vixrex
          </span>
        </Link>

        <div className="flex items-center gap-2.5">
          <Link
            href="/kesfet"
            className="hidden items-center gap-2 rounded-full border border-lp-primary/45 bg-lp-surface-soft px-4 py-3 text-[12px] font-black text-lp-primary transition-colors hover:bg-lp-surface md:flex"
            aria-label="Vitrinleri Keşfet"
          >
            <KesfetIkonu boyut={16} />
            Vitrinleri Keşfet
          </Link>
          <Link
            href="/kesfet"
            className="flex h-10 w-10 items-center justify-center rounded-full border border-lp-border bg-lp-surface-soft text-lp-text md:hidden"
            aria-label="Vitrinleri Keşfet"
          >
            <KesfetIkonu boyut={18} />
          </Link>

          <a
            href="/giris"
            className="hidden items-center gap-2 rounded-full bg-lp-primary px-4 py-3 text-[12px] font-black text-lp-on-primary md:flex"
          >
            Giriş Yap
          </a>
          <a
            href="/giris"
            className="flex h-10 w-10 items-center justify-center rounded-full bg-lp-primary text-lp-on-primary md:hidden"
            aria-label="Giriş Yap"
          >
            <span aria-hidden className="text-[16px]">→</span>
          </a>
        </div>
      </nav>
    </header>
  );
}

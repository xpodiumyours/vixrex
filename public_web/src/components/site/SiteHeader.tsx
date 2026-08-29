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
    <header className="border-b border-lp-border/40 bg-lp-bg-editor">
      <nav
        aria-label="Ana gezinme"
        className="flex w-full items-center justify-between px-5 py-4 md:px-10"
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

        <div className="flex items-center gap-2">
          <Link
            href="/kesfet"
            className="flex items-center gap-2 rounded-full bg-lp-surface-soft px-3 py-2 text-[13px] font-extrabold text-lp-text-alt transition-colors hover:bg-lp-surface md:px-4"
            aria-label="Vitrinleri Keşfet"
          >
            <KesfetIkonu boyut={18} />
            <span className="hidden md:inline">Vitrinleri Keşfet</span>
          </Link>

          <a
            href="/giris"
            className="rounded-full px-3 py-2 text-[13px] font-extrabold text-lp-secondary transition-colors hover:text-lp-text md:px-4"
          >
            Giriş Yap
          </a>
        </div>
      </nav>
    </header>
  );
}

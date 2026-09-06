import Link from "next/link";
import { blogYayindaMi } from "@/data/blogYazilari";

/**
 * Platform altbilgisi (envanter §2.11) — aynı zamanda #346'nın çözümü.
 *
 * Blog bağlantısı merkezi Vixrex blog kaynağındaki gerçek yayın durumuna
 * bağlıdır. Hiç yayınlanmış yazı yoksa kırık `/blog` bağlantısı gösterilmez.
 */
export async function SiteFooter() {
  const blogYayinda = await blogYayindaMi();

  return (
    <footer className="bg-lp-bg-editor py-14">
      <div className="mx-auto flex w-full max-w-[1200px] flex-col items-center gap-4 px-5 text-center">
        <p className="text-[16px] font-black tracking-[8px] text-lp-primary/80">
          VIXREX
        </p>
        <p className="text-[14px] font-semibold text-lp-muted">
          İşletmenizin paylaşılabilir dijital vitrini
        </p>

        <nav
          aria-label="Yardım ve yasal bilgiler"
          className="flex flex-wrap items-center justify-center gap-1"
        >
          {blogYayinda ? (
            <Link
              href="/blog"
              className="px-3 py-2 text-[13px] font-extrabold text-lp-muted transition-colors hover:text-lp-text-alt"
            >
              Blog
            </Link>
          ) : null}
          <Link
            href="/hakkimizda"
            className="px-3 py-2 text-[13px] font-extrabold text-lp-muted transition-colors hover:text-lp-text-alt"
          >
            Hakkımızda
          </Link>
          <Link
            href="/iletisim"
            className="px-3 py-2 text-[13px] font-extrabold text-lp-muted transition-colors hover:text-lp-text-alt"
          >
            İletişim
          </Link>
          <Link
            href="/yardim"
            className="px-3 py-2 text-[13px] font-extrabold text-lp-muted transition-colors hover:text-lp-text-alt"
          >
            Yardım ve Destek
          </Link>
          <Link
            href="/privacy"
            className="px-3 py-2 text-[13px] font-extrabold text-lp-muted transition-colors hover:text-lp-text-alt"
          >
            KVKK ve Gizlilik Politikası
          </Link>
          <Link
            href="/legal/terms"
            className="px-3 py-2 text-[13px] font-extrabold text-lp-muted transition-colors hover:text-lp-text-alt"
          >
            Kullanım Şartları
          </Link>
        </nav>
      </div>
    </footer>
  );
}

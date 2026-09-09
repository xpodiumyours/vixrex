import Link from "next/link";
import { blogYayindaMi } from "@/data/blogYazilari";

/**
 * Platform altbilgisi (envanter §2.11) — aynı zamanda #346'nın çözümü.
 *
 * #346: yasal sayfalara sitenin hiçbir yerinden bağlantı yoktu. Sayfalar
 * yayındaydı ama ne kullanıcı ne de arama motoru onlara ulaşabiliyordu.
 *
 * Flutter altbilgisi üç bağlantı taşıyor; web'de ikisi var:
 *   - `/privacy`  → mevcut, statik KVKK metni
 *   - `/terms`    → BÖYLE BİR ROTA YOK. Doğrusu `/legal/terms`
 *                   (src/app/legal/[type], türler: privacy|terms|consent)
 *   - `/data-deletion` → yalnız `/data-deletion/status/[code]` var,
 *                   dizinin kendisi 404. Kırık bağlantı eklemek yerine
 *                   şimdilik dışarıda bırakıldı; o sayfa açılınca eklenir.
 */
export function SiteFooter() {
  return (
    <footer className="bg-lp-bg-editor py-[60px]">
      <div className="mx-auto flex w-full max-w-[1200px] flex-col items-center gap-4 px-5 text-center">
        <p className="text-[16px] font-black tracking-[8px] text-lp-primary/80">
          VIXREX
        </p>
        <p className="text-[14px] font-semibold text-lp-muted">
          İşletmenizin paylaşılabilir dijital vitrini
        </p>

        <nav
          aria-label="Yardım ve yasal bilgiler"
          className="flex flex-wrap items-center justify-center gap-2"
        >
          {/* Blog bağlantısı YAYIN ANAHTARINA bağlı: hiç yayında yazı
              yokken `/blog` 404 verdiği için bağlantı da gösterilmez.
              Bkz. src/data/blogYazilari.ts */}
          {blogYayindaMi() ? (
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

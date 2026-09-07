import Link from "next/link";
import { getAppUrl } from "@/lib/siteUrl";

/**
 * Özel 404 sayfası — Next.js App Router convention.
 * Bu dosya, app/ altında tanımlı olmayan herhangi bir slug'a
 * gidildiğinde otomatik olarak gösterilir.
 *
 * İlgili issue: #293
 */
export default function NotFound() {
  return (
    <div className="min-h-[80vh] flex flex-col items-center justify-center px-6 text-center">
      {/* Büyük 404 rakamı */}
      <p
        className="font-vitrin-display text-[8rem] leading-none font-bold tracking-tighter"
        style={{ color: "var(--primary)" }}
      >
        404
      </p>

      {/* Başlık */}
      <h1
        className="mt-4 text-2xl sm:text-3xl font-bold"
        style={{ color: "var(--text-dark)" }}
      >
        Sayfa Bulunamadı
      </h1>

      {/* Açıklayıcı metin */}
      <p
        className="mt-3 max-w-md text-sm sm:text-base leading-relaxed"
        style={{ color: "var(--text-muted)" }}
      >
        Aradığınız sayfa taşınmış, silinmiş veya hiç var olmamış olabilir.
      </p>

      {/* Butonlar */}
      <div className="mt-8 flex flex-col sm:flex-row gap-3">
        <Link href="/" className="btn-primary">
          Ana Sayfaya Dön
        </Link>
        <a href={`${getAppUrl()}/app`} className="btn-secondary">
          Vitrinini Oluştur
        </a>
      </div>
    </div>
  );
}

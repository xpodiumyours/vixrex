import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { blogYayindaMi } from "@/data/blogYazilari";

export const metadata: Metadata = {
  title: "Yayın ilkeleri | Vixrex Blog",
  description:
    "Vixrex Blog içeriklerinin kaynak, doğrulama, güncellik ve yayın güvenliği ilkeleri.",
  alternates: { canonical: "/blog/yayin-ilkeleri" },
};

export default function BlogYayinIlkeleriPage() {
  if (!blogYayindaMi()) notFound();

  return (
    <div className="bg-lp-bg-editor px-5 py-12 sm:px-8 sm:py-16">
      <main className="mx-auto w-full max-w-[780px]">
        <Link
          href="/blog"
          className="inline-flex min-h-11 items-center font-bold text-lp-secondary outline-none hover:text-lp-text focus-visible:ring-2 focus-visible:ring-lp-secondary"
        >
          ← Blog
        </Link>

        <header className="mt-6 border-b border-lp-border/60 pb-8">
          <p className="text-xs font-black uppercase tracking-[0.18em] text-lp-secondary">
            Vixrex Blog
          </p>
          <h1 className="mt-3 text-4xl font-black tracking-tight text-lp-text sm:text-5xl">
            Yayın ilkeleri
          </h1>
          <p className="mt-4 text-lg font-medium leading-8 text-lp-muted">
            Blog içeriklerinin hangi koşullarda hazırlandığını, kontrol edildiğini
            ve yayında tutulduğunu açıkça belirtiriz.
          </p>
        </header>

        <div className="mt-9 space-y-10 text-[17px] font-medium leading-8 text-lp-text">
          <section>
            <h2 className="text-2xl font-black tracking-tight">Ne yayımlıyoruz?</h2>
            <p className="mt-3">
              Dijital vitrin, keşfedilme, müşteri iletişimi, Vixrex ürün
              güncellemeleri ve işletme deneyimleriyle ilgili uygulanabilir
              içerikler hazırlıyoruz. Kesin sonuç, sıralama veya gelir vaadi
              üretmiyoruz.
            </p>
          </section>

          <section>
            <h2 className="text-2xl font-black tracking-tight">Kaynak ve doğrulama</h2>
            <p className="mt-3">
              Google gibi haricî platformlarla ilgili doğrulanabilir iddialarda
              kaynak bağlantıları kullanılır. Vixrex ürününe ilişkin içerikler
              ürünün doğrulama ortamına dayanır. Genel işletme rehberlerinde ise
              doğrulanmamış istatistik, başarı vaadi veya uydurma örnek kullanılmaz.
            </p>
          </section>

          <section>
            <h2 className="text-2xl font-black tracking-tight">Güncellik</h2>
            <p className="mt-3">
              Haricî platform rehberleri en geç 60 günde, genel rehberler 90
              günde yeniden kontrol için işaretlenir. Vixrex ürün içerikleri ürün
              değiştiğinde yeniden gözden geçirilir. Süresi dolan içerik inceleme
              listesine düşer.
            </p>
          </section>

          <section>
            <h2 className="text-2xl font-black tracking-tight">Yayın güvenliği</h2>
            <p className="mt-3">
              Taslak ve arşiv içerikler blog listesine, sitemap'e veya RSS'e
              girmez. Yayın için tarih, içerik türüne göre doğrulama alanları ve
              mevcut kalite kontrollerinin geçmesi gerekir.
            </p>
          </section>

          <section>
            <h2 className="text-2xl font-black tracking-tight">Görseller</h2>
            <p className="mt-3">
              Haricî bir kapak görseli kullanıldığında alternatif metin, kaynak
              ve kullanım hakkı bilgileri birlikte tutulur. Bu bilgiler yoksa
              görsel yayın kalite kontrolünden geçmez.
            </p>
          </section>

          <section className="rounded-[18px] border border-lp-border bg-lp-surface p-5 sm:p-6">
            <h2 className="text-xl font-black tracking-tight">Düzeltme bildirimi</h2>
            <p className="mt-2 text-base leading-7 text-lp-muted">
              Bir yazıda eski veya yanlış bilgi görürseniz iletişim sayfasından
              düzeltme bildirebilirsiniz.
            </p>
            <Link
              href="/iletisim"
              className="mt-4 inline-flex min-h-11 items-center font-black text-lp-secondary outline-none hover:text-lp-text focus-visible:ring-2 focus-visible:ring-lp-secondary"
            >
              Düzeltme bildir →
            </Link>
          </section>
        </div>
      </main>
    </div>
  );
}

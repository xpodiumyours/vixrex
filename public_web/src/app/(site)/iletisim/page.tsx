import type { Metadata } from "next";
import Link from "next/link";

/**
 * İletişim — tek kapı.
 *
 * NEDEN VAR: 2026-08-29'a kadar sitede hiçbir iletişim sayfası yoktu;
 * e-posta adresi yalnız yasal metinlerin içinde geçiyordu. Hem ziyaretçi
 * hem de başvuru değerlendiren affiliate programları önce bu sayfayı
 * arıyor. Adres ve telefon henüz alınmadı — alınınca buraya eklenecek.
 */

export const metadata: Metadata = {
  title: "İletişim | Vixrex",
  description:
    "Vixrex ile iletişime geçin. Destek, iş birliği ve yasal konular için destek@vixrex.com adresine yazabilirsiniz.",
  alternates: { canonical: "/iletisim" },
};

const KONULAR = [
  {
    baslik: "Vitrin ve hesap desteği",
    metin:
      "Vitrin kurma, ürün ekleme, yayınlama veya hesabınızla ilgili her konu. Çoğu sorunun cevabı Yardım ve Destek sayfasında hazır duruyor.",
    baglanti: { yazi: "Yardım ve Destek", yol: "/yardim" },
  },
  {
    baslik: "İş birliği ve tedarikçilik",
    metin:
      "Ürünlerinizin Vixrex vitrinlerinde yer almasını istiyorsanız, iş ortaklığı veya bayilik teklifleriniz için yazın.",
  },
  {
    baslik: "Yasal konular ve veri talepleri",
    metin:
      "KVKK kapsamındaki başvurular, veri silme talepleri ve yasal bildirimler. Talebiniz mevzuattaki süreler içinde yanıtlanır.",
    baglanti: { yazi: "KVKK ve Gizlilik Politikası", yol: "/privacy" },
  },
];

export default function IletisimPage() {
  return (
    <div className="bg-lp-bg-light px-5 py-12 sm:py-16">
      <div className="mx-auto w-full max-w-3xl">
        <section className="overflow-hidden rounded-[28px] border border-lp-border bg-lp-bg-editor px-6 py-8 shadow-[0_24px_70px_rgba(14,32,58,0.12)] sm:px-10 sm:py-12">
          <p className="text-xs font-black uppercase tracking-[0.18em] text-lp-primary">
            İletişim
          </p>
          <h1 className="mt-3 max-w-xl text-3xl font-black tracking-tight text-lp-text sm:text-4xl">
            Bize ulaşın
          </h1>
          <p className="mt-4 text-[15px] leading-relaxed text-lp-muted">
            Her konu için tek bir adres kullanıyoruz. Yazdığınızda hangi
            konuda olduğunu belirtirseniz daha hızlı dönüş yapabiliyoruz.
          </p>

          <a
            href="mailto:destek@vixrex.com"
            className="mt-6 flex items-center justify-between gap-4 rounded-2xl border border-lp-primary/30 bg-lp-primary/10 px-5 py-4 transition-colors hover:border-lp-primary/60"
          >
            <span>
              <span className="block text-[13px] font-black uppercase tracking-wide text-lp-muted">
                E-posta
              </span>
              <span className="mt-0.5 block text-[17px] font-black text-lp-text">
                destek@vixrex.com
              </span>
            </span>
            <span aria-hidden="true" className="text-lp-primary">
              <svg
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth={2}
                strokeLinecap="round"
                strokeLinejoin="round"
                className="h-5 w-5"
              >
                <path d="M5 12h14M13 6l6 6-6 6" />
              </svg>
            </span>
          </a>

          <h2 className="mt-10 text-xl font-black tracking-tight text-lp-text">
            Hangi konuda yazabilirsiniz
          </h2>
          <div className="mt-4 space-y-4">
            {KONULAR.map((konu) => (
              <div
                key={konu.baslik}
                className="rounded-2xl border border-lp-border bg-lp-surface px-5 py-4"
              >
                <p className="text-[15px] font-black text-lp-text">{konu.baslik}</p>
                <p className="mt-1.5 text-[14px] leading-relaxed text-lp-muted">
                  {konu.metin}
                </p>
                {konu.baglanti ? (
                  <Link
                    href={konu.baglanti.yol}
                    className="mt-2 inline-block text-[14px] font-black text-lp-primary hover:underline"
                  >
                    {konu.baglanti.yazi} →
                  </Link>
                ) : null}
              </div>
            ))}
          </div>

          <h2 className="mt-10 text-xl font-black tracking-tight text-lp-text">
            Yasal bilgiler
          </h2>
          <dl className="mt-4 divide-y divide-lp-border overflow-hidden rounded-2xl border border-lp-border bg-lp-surface">
            {[
              ["Ticaret unvanı", "Furkan Aksakal — Aksakal Ticaret"],
              ["Vergi numarası", "0340472476"],
              ["Faaliyet konusu", "İnternet üzerinden perakende ticaret (479114)"],
              ["ETBİS", "Elektronik Ticaret Bilgi Sistemi'ne kayıtlıdır"],
            ].map(([etiket, deger]) => (
              <div key={etiket} className="flex flex-col gap-1 px-5 py-3.5 sm:flex-row sm:gap-4">
                <dt className="text-[13px] font-black uppercase tracking-wide text-lp-muted sm:w-44 sm:shrink-0">
                  {etiket}
                </dt>
                <dd className="text-[14px] font-semibold text-lp-text">{deger}</dd>
              </div>
            ))}
          </dl>

          <p className="mt-6 text-[14px] leading-relaxed text-lp-muted">
            Platform hakkında daha fazla bilgi için{" "}
            <Link href="/hakkimizda" className="font-black text-lp-primary hover:underline">
              Hakkımızda
            </Link>{" "}
            sayfasına bakabilirsiniz.
          </p>
        </section>
      </div>
    </div>
  );
}

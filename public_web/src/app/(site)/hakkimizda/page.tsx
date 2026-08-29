import type { Metadata } from "next";
import Link from "next/link";

/**
 * Hakkımızda — platform kimlik sayfası.
 *
 * NEDEN VAR: 2026-08-29'a kadar sitede "bu platformu kim işletiyor"
 * sorusunun cevabı hiçbir yerde yazmıyordu. İki ayrı yerde lazım:
 * affiliate/dropshipping programları başvuruyu değerlendirirken
 * publisher'ın gerçek olduğunu siteden doğruluyor; ziyaretçi de
 * "param nereye gidiyor" sorusunun cevabını arıyor.
 *
 * Ticari bilgiler (unvan, vergi no) ETBİS beyanıyla aynı — orada zaten
 * kamuya açık. Adres ve telefon henüz alınmadı, alınınca eklenecek.
 */

export const metadata: Metadata = {
  title: "Hakkımızda | Vixrex",
  description:
    "Vixrex, küçük işletmelerin dakikalar içinde kendi dijital vitrinini kurup WhatsApp üzerinden müşteriyle buluşmasını sağlayan Türkiye merkezli bir platformdur.",
  alternates: { canonical: "/hakkimizda" },
};

const YAPTIKLARIMIZ = [
  {
    baslik: "İşletme kendi vitrinini kurar",
    metin:
      "Kuaför, teknik servis, butik, kuruyemişçi — herhangi bir esnaf kod bilmeden kendi vitrinini oluşturur. Ürünler, fiyatlar, çalışma saatleri ve konum işletmenin kendi bilgisidir.",
  },
  {
    baslik: "Müşteri doğrudan işletmeye ulaşır",
    metin:
      "Vitrindeki WhatsApp, telefon ve yol tarifi düğmeleri müşteriyi doğrudan işletmeye bağlar. Arada bir aracı, bir bekleme, bir komisyon yoktur.",
  },
  {
    baslik: "Vitrin her yerde paylaşılabilir",
    metin:
      "Her vitrinin kendine ait bir web adresi ve QR kodu olur. İşletme onu tabelasına, kartvizitine, sosyal medyasına koyar.",
  },
];

const YAPMADIKLARIMIZ = [
  "Vixrex ödeme almaz. Vitrinlerde sepet veya kart ekranı yoktur.",
  "Vixrex kargo göndermez, iade almaz. Bu işlemler ilgili işletmeye aittir.",
  "Vixrex ürünlerin fiyatını, stoğunu veya içeriğini belirlemez; bilgiler işletme tarafından girilir.",
];

export default function HakkimizdaPage() {
  return (
    <div className="bg-lp-bg-light px-5 py-12 sm:py-16">
      <div className="mx-auto w-full max-w-3xl">
        <section className="overflow-hidden rounded-[28px] border border-lp-border bg-lp-bg-editor px-6 py-8 shadow-[0_24px_70px_rgba(14,32,58,0.12)] sm:px-10 sm:py-12">
          <p className="text-xs font-black uppercase tracking-[0.18em] text-lp-primary">
            Hakkımızda
          </p>
          <h1 className="mt-3 max-w-xl text-3xl font-black tracking-tight text-lp-text sm:text-4xl">
            Küçük işletmenin dijital vitrini
          </h1>
          <p className="mt-4 text-[15px] leading-relaxed text-lp-muted">
            Vixrex, esnafın internette bir adresi olmadığı için müşteri
            kaybetmesini çözmek üzere kuruldu. Web sitesi yaptırmak pahalı ve
            uzun; sosyal medya hesabı ise ürünleri, fiyatları ve çalışma
            saatlerini düzgün gösteremiyor. Vixrex ikisinin arasındaki boşluğu
            dolduruyor: dakikalar içinde kurulan, telefonda düzgün görünen,
            tek bağlantıyla paylaşılan bir vitrin.
          </p>

          <h2 className="mt-10 text-xl font-black tracking-tight text-lp-text">
            Ne yapıyoruz
          </h2>
          <div className="mt-4 space-y-4">
            {YAPTIKLARIMIZ.map((madde) => (
              <div
                key={madde.baslik}
                className="rounded-2xl border border-lp-border bg-lp-surface px-5 py-4"
              >
                <p className="text-[15px] font-black text-lp-text">
                  {madde.baslik}
                </p>
                <p className="mt-1.5 text-[14px] leading-relaxed text-lp-muted">
                  {madde.metin}
                </p>
              </div>
            ))}
          </div>

          <h2 className="mt-10 text-xl font-black tracking-tight text-lp-text">
            Ne yapmıyoruz
          </h2>
          <p className="mt-2 text-[14px] leading-relaxed text-lp-muted">
            Bunları açıkça yazıyoruz, çünkü müşterinin en çok merak ettiği şey
            paranın nereye gittiği.
          </p>
          <ul className="mt-4 space-y-2">
            {YAPMADIKLARIMIZ.map((madde) => (
              <li
                key={madde}
                className="flex gap-2.5 text-[14px] leading-relaxed text-lp-muted"
              >
                <span aria-hidden="true" className="text-lp-primary">
                  •
                </span>
                {madde}
              </li>
            ))}
          </ul>

          <h2 className="mt-10 text-xl font-black tracking-tight text-lp-text">
            İşletme bilgileri
          </h2>
          <dl className="mt-4 divide-y divide-lp-border overflow-hidden rounded-2xl border border-lp-border bg-lp-surface">
            {[
              ["Ticaret unvanı", "Furkan Aksakal — Aksakal Ticaret"],
              ["Vergi numarası", "0340472476"],
              ["Faaliyet konusu", "İnternet üzerinden perakende ticaret (479114)"],
              ["E-posta", "destek@vixrex.com"],
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

          <p className="mt-8 text-[14px] leading-relaxed text-lp-muted">
            Sorunuz mu var?{" "}
            <Link href="/iletisim" className="font-black text-lp-primary hover:underline">
              İletişim sayfasından
            </Link>{" "}
            bize yazabilirsiniz. Yasal metinler için{" "}
            <Link href="/legal/terms" className="font-black text-lp-primary hover:underline">
              Kullanım Şartları
            </Link>{" "}
            ve{" "}
            <Link href="/privacy" className="font-black text-lp-primary hover:underline">
              KVKK ve Gizlilik Politikası
            </Link>{" "}
            sayfalarına bakabilirsiniz.
          </p>
        </section>
      </div>
    </div>
  );
}

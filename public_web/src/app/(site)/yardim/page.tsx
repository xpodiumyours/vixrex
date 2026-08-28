import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Yardım ve Destek | Vixrex",
  description:
    "Vixrex vitrini yayınlama, ürün ekleme, paylaşma, randevu yönetimi ve hesap işlemleri hakkında yardım.",
};

const SORULAR = [
  {
    soru: "Vitrin nasıl yayınlanır?",
    cevap:
      "Vitrinim sayfasında işletme bilgilerini doldur, yasal onayları işaretle ve Yayınla düğmesine bas. Yayından sonra işletmene özel web bağlantısı oluşur.",
  },
  {
    soru: "Ürünleri nasıl eklerim?",
    cevap:
      "Vitrinim içindeki Ürün Yönetimi bölümünden ürünlerini tek tek ekleyebilir veya CSV/Excel dosyasıyla toplu yükleyebilirsin.",
  },
  {
    soru: "Müşteriler vitrinimi nasıl görür?",
    cevap:
      "Yayınlanan vitrini herkese açık web bağlantısı ve QR koduyla paylaşabilirsin. Yayındaki vitrinler Keşfet bölümünde de listelenir.",
  },
  {
    soru: "Randevu sistemi nasıl çalışır?",
    cevap:
      "Randevu özelliğini destekleyen kategorilerde randevu ayarlarını açabilirsin. Gelen talepleri Randevu Yönetimi sayfasından onaylayabilir veya reddedebilirsin.",
  },
  {
    soru: "Verilerimi nasıl silebilirim?",
    cevap:
      "Hesap yönetimi sayfasından hesabını ve vitrini silebilirsin. Kişisel verilerinle ilgili ayrıca gizlilik sayfasındaki iletişim adresinden talep oluşturabilirsin.",
  },
] as const;

export default function YardimPage() {
  return (
    <div className="bg-lp-bg-light px-5 py-12 sm:py-16">
      <div className="mx-auto w-full max-w-3xl">
        <section className="overflow-hidden rounded-[28px] border border-lp-border bg-lp-bg-editor px-6 py-8 shadow-[0_24px_70px_rgba(14,32,58,0.12)] sm:px-10 sm:py-12">
          <p className="text-xs font-black uppercase tracking-[0.18em] text-lp-primary">
            Yardım merkezi
          </p>
          <h1 className="mt-3 max-w-xl text-3xl font-black tracking-tight text-lp-text sm:text-4xl">
            Vitrinini kullanırken yanında olalım
          </h1>
          <p className="mt-4 max-w-2xl text-sm font-medium leading-7 text-lp-muted sm:text-base">
            Yayınlama, ürünler, paylaşım ve randevu yönetimiyle ilgili en sık sorulan soruların kısa yanıtları burada.
          </p>
        </section>

        <section className="mt-8" aria-labelledby="sss-baslik">
          <h2 id="sss-baslik" className="text-xl font-black text-lp-text sm:text-2xl">
            Sıkça sorulan sorular
          </h2>
          <div className="mt-4 space-y-3">
            {SORULAR.map((item) => (
              <details key={item.soru} className="group rounded-2xl border border-lp-border bg-white px-5 py-1 shadow-sm open:border-lp-primary/50">
                <summary className="flex min-h-14 cursor-pointer list-none items-center justify-between gap-4 py-4 text-sm font-black text-lp-text marker:content-none sm:text-base">
                  {item.soru}
                  <span className="text-xl text-lp-primary transition-transform group-open:rotate-45" aria-hidden="true">+</span>
                </summary>
                <p className="border-t border-lp-border pb-5 pt-4 text-sm font-medium leading-7 text-lp-muted">
                  {item.cevap}
                </p>
              </details>
            ))}
          </div>
        </section>

        <section className="mt-8 rounded-2xl border border-lp-primary/30 bg-lp-primary/[0.08] p-6 sm:flex sm:items-center sm:justify-between sm:gap-6">
          <div>
            <h2 className="text-lg font-black text-lp-text">Yanıtını bulamadın mı?</h2>
            <p className="mt-2 text-sm font-medium leading-6 text-lp-muted">
              Sorunu ve mümkünse ekran görüntüsünü gönder; destek ekibi inceleyip sana dönüş yapsın.
            </p>
          </div>
          <a href="mailto:Xpodiumyours@gmail.com?subject=Vixrex%20Destek" className="mt-5 inline-flex min-h-12 shrink-0 items-center justify-center rounded-xl bg-lp-primary px-5 py-3 text-sm font-black text-lp-on-primary transition hover:brightness-105 sm:mt-0">
            E-posta gönder
          </a>
        </section>
      </div>
    </div>
  );
}

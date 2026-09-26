import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { blogYayindaMi } from "@/data/blogYazilari";

export const metadata: Metadata = {
  title: "Yayın ilkeleri | Vixrex Blog",
  description:
    "Vixrex Blog içeriklerinin kapsamı, kaynakları ve düzeltme süreci.",
  alternates: { canonical: "/blog/yayin-ilkeleri" },
};

export default function YayinIlkeleri() {
  if (!blogYayindaMi()) notFound();
  return (
    <article className="mx-auto max-w-[760px] px-5 py-12 text-lp-text">
      <Link
        href="/blog"
        className="inline-flex min-h-11 items-center rounded text-lp-secondary focus-visible:ring-2"
      >
        ← Bloga dön
      </Link>
      <h1 className="mt-5 text-4xl font-bold tracking-tight">Yayın ilkeleri</h1>
      <p className="mt-5 text-lg leading-8 text-lp-muted">
        Vixrex Blog, küçük işletmelerin dijital vitrinlerini hazırlamalarına ve
        müşterileriyle daha açık iletişim kurmalarına yardımcı olmak için
        hazırlanır.
      </p>
      <div className="mt-8 space-y-8 text-base leading-7">
        <section>
          <h2 className="text-2xl font-semibold">
            Bir yazı, uygulanabilir bir cevap
          </h2>
          <p className="mt-3 text-lp-muted">
            Her rehber belirli bir soruya odaklanır. Örnekler işletmenin yerine
            karar vermez; kendi bilgilerine uyarlayabileceğin başlangıç
            noktaları sunar. Örnek metinler gerçek müşteri hikâyesi veya
            ölçülmüş başarı sonucu olarak sunulmaz.
          </p>
        </section>
        <section>
          <h2 className="text-2xl font-semibold">Kaynaklar ve yazarlık</h2>
          <p className="mt-3 text-lp-muted">
            Google gibi başka platformların işleyişini anlatan rehberlerde
            ilgili resmi belgelere bağlantı verilir. Vixrex adına hazırlanan
            içeriklerde yazar kurum olarak belirtilir. Yapay zekâ destekli
            taslak hazırlama kullanılabilir; bu, bağımsız uzman incelemesi
            anlamına gelmez. Bir inceleyen varsa adı ayrıca gösterilir.
          </p>
        </section>
        <section>
          <h2 className="text-2xl font-semibold">Güncelleme ve düzeltme</h2>
          <p className="mt-3 text-lp-muted">
            Yazıda yayın ve son kontrol tarihleri bulunur. İçeriği etkileyen
            güncellemeler ayrıca belirtilir. Harici platformların ekranları ve
            kuralları değişebileceğinden işlem öncesinde yazının kaynaklarına da
            bakabilirsin.
          </p>
        </section>
        <section>
          <h2 className="text-2xl font-semibold">
            Görseller ve ürün bilgileri
          </h2>
          <p className="mt-3 text-lp-muted">
            Şematik kapaklar anlatımı destekleyen çizimlerdir; gerçek bir
            işletmenin veya uygulama ekranının fotoğrafı değildir. Gerçek görsel
            kullanılan yazılarda kaynak ve kullanım bilgisi belirtilir. Ürün
            özellikleri, fiyatlar ve sonuçlar doğrulanmadan kesin vaat olarak
            verilmez.
          </p>
        </section>
        <section>
          <h2 className="text-2xl font-semibold">Bize bildir</h2>
          <p className="mt-3 text-lp-muted">
            Yanlış veya eski bir bilgi fark edersen yazının bağlantısını ve
            düzeltilmesini istediğin bölümü iletişim sayfasından iletebilirsin.
          </p>
          <Link
            href="/iletisim"
            className="mt-4 inline-flex min-h-11 items-center rounded text-lp-secondary underline underline-offset-4 focus-visible:ring-2"
          >
            İletişim sayfasına git →
          </Link>
        </section>
      </div>
    </article>
  );
}

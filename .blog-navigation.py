from pathlib import Path
r=Path.cwd()
def write(path,s):
 p=r/path;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(s,encoding='utf-8')
def change(path,a,b):
 p=r/path;s=p.read_text(encoding='utf-8');assert a in s,(path,a[:70]);p.write_text(s.replace(a,b),encoding='utf-8')
write('public_web/src/components/landing/BlogRehberleri.tsx','''import Link from "next/link";
import { yayindakiYazilar } from "@/data/blogYazilari";
import { okumaDakikasiHesapla } from "@/lib/blogIcerik";

export function BlogRehberleri() {
  const yazilar = yayindakiYazilar().slice(0, 3);
  if (!yazilar.length) return null;
  return <section aria-labelledby="landing-blog-baslik" className="bg-lp-bg-editor px-5 py-16 sm:px-8"><div className="mx-auto max-w-[1200px]"><div className="flex flex-wrap items-end justify-between gap-5"><div><p className="text-xs font-bold uppercase tracking-[.18em] text-lp-secondary">Vixrex Blog</p><h2 id="landing-blog-baslik" className="mt-3 text-3xl font-bold text-lp-text">İşletmen için pratik rehberler.</h2><p className="mt-3 text-lp-muted">İlk vitrinden günlük müşteri iletişimine, bir sonraki adımın burada.</p></div><Link href="/blog" className="inline-flex min-h-11 items-center rounded px-2 font-bold text-lp-secondary outline-none focus-visible:ring-2 focus-visible:ring-lp-secondary">Tüm rehberler →</Link></div><div className="mt-8 grid gap-5 md:grid-cols-3">{yazilar.map((yazi) => <Link key={yazi.slug} href={`/blog/${yazi.slug}`} className="rounded-2xl border border-lp-border bg-lp-surface p-6 outline-none transition-colors hover:border-lp-secondary focus-visible:ring-2 focus-visible:ring-lp-secondary"><p className="text-xs font-bold text-lp-secondary">{yazi.kategori}</p><h3 className="mt-3 text-xl font-semibold leading-snug text-lp-text">{yazi.baslik}</h3><p className="mt-3 text-sm leading-6 text-lp-muted">{yazi.ozet}</p><p className="mt-5 text-sm text-lp-secondary">{okumaDakikasiHesapla(yazi.govde)} dk okuma <span aria-hidden="true">↗</span></p></Link>)}</div></div></section>;
}
''')
change('public_web/src/app/(site)/page.tsx','import type { Metadata } from "next";','import type { Metadata } from "next";\nimport { blogYayindaMi } from "@/data/blogYazilari";\nimport { BlogRehberleri } from "@/components/landing/BlogRehberleri";')
change('public_web/src/app/(site)/page.tsx','<LandingChatWrapper profiller={profiller}>','<LandingChatWrapper profiller={profiller} blogErisimi={blogYayindaMi()}>')
change('public_web/src/app/(site)/page.tsx','        <TemplateCatalog />','        <TemplateCatalog />\n        <BlogRehberleri />')
change('public_web/src/components/landing/LandingChatWrapper.tsx','  profiller,\n}: {','  profiller,\n  blogErisimi = false,\n}: {')
change('public_web/src/components/landing/LandingChatWrapper.tsx','  profiller: MockupProfili[];','  profiller: MockupProfili[];\n  blogErisimi?: boolean;')
change('public_web/src/components/landing/LandingChatWrapper.tsx','        profiller={profiller}','        profiller={profiller}\n        blogErisimi={blogErisimi}')
change('public_web/src/components/landing/HeroSection.tsx','  profiller,\n  isChatOpen','  profiller,\n  blogErisimi = false,\n  isChatOpen')
change('public_web/src/components/landing/HeroSection.tsx','  profiller: MockupProfili[];','  profiller: MockupProfili[];\n  blogErisimi?: boolean;')
link='<Link href="/blog" className="inline-flex min-h-11 items-center rounded-lg px-2 text-sm font-semibold text-lp-text outline-none hover:text-lp-secondary focus-visible:ring-2 focus-visible:ring-lp-secondary">Blog</Link>'
change('public_web/src/components/landing/HeroSection.tsx','        <div className="flex items-center gap-2.5">','        <div className="flex items-center gap-2.5">\n          {blogErisimi ? '+link+' : null}')
change('public_web/src/components/site/SiteHeader.tsx','import Link from "next/link";','import Link from "next/link";\nimport { blogYayindaMi } from "@/data/blogYazilari";')
change('public_web/src/components/site/SiteHeader.tsx','        <div className="flex items-center gap-2.5">','        <div className="flex items-center gap-2.5">\n          {blogYayindaMi() ? '+link+' : null}')
change('public_web/src/app/(site)/blog/page.tsx','  title: "Blog | Vixrex",','  title: "İşletmeler için pratik rehberler | Vixrex Blog",\n  alternates: { canonical: "/blog", types: { "application/rss+xml": "/blog/rss.xml" } },\n  openGraph: { title: "Vixrex Blog — İşletmen için işe yarayan bilgiler", description: "Dijital vitrin, Google ve müşteri iletişimi için pratik işletme rehberleri.", url: "/blog", type: "website", locale: "tr_TR" },')
write('public_web/src/app/(site)/blog/yayin-ilkeleri/page.tsx','''import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { blogYayindaMi } from "@/data/blogYazilari";

export const metadata: Metadata = { title: "Yayın ilkeleri | Vixrex Blog", description: "Vixrex Blog içeriklerinin kapsamı, kaynakları ve düzeltme süreci.", alternates: { canonical: "/blog/yayin-ilkeleri" } };

export default function YayinIlkeleri() {
  if (!blogYayindaMi()) notFound();
  return <article className="mx-auto max-w-[760px] px-5 py-12 text-lp-text"><Link href="/blog" className="inline-flex min-h-11 items-center rounded text-lp-secondary focus-visible:ring-2">← Bloga dön</Link><h1 className="mt-5 text-4xl font-bold tracking-tight">Yayın ilkeleri</h1><p className="mt-5 text-lg leading-8 text-lp-muted">Vixrex Blog, küçük işletmelerin dijital vitrinlerini hazırlamalarına ve müşterileriyle daha açık iletişim kurmalarına yardımcı olmak için hazırlanır.</p><div className="mt-8 space-y-8 text-base leading-7"><section><h2 className="text-2xl font-semibold">Bir yazı, uygulanabilir bir cevap</h2><p className="mt-3 text-lp-muted">Her rehber belirli bir soruya odaklanır. Örnekler işletmenin yerine karar vermez; kendi bilgilerine uyarlayabileceğin başlangıç noktaları sunar. Örnek metinler gerçek müşteri hikâyesi veya ölçülmüş başarı sonucu olarak sunulmaz.</p></section><section><h2 className="text-2xl font-semibold">Kaynaklar ve yazarlık</h2><p className="mt-3 text-lp-muted">Google gibi başka platformların işleyişini anlatan rehberlerde ilgili resmi belgelere bağlantı verilir. Vixrex adına hazırlanan içeriklerde yazar kurum olarak belirtilir. Yapay zekâ destekli taslak hazırlama kullanılabilir; bu, bağımsız uzman incelemesi anlamına gelmez. Bir inceleyen varsa adı ayrıca gösterilir.</p></section><section><h2 className="text-2xl font-semibold">Güncelleme ve düzeltme</h2><p className="mt-3 text-lp-muted">Yazıda yayın ve son kontrol tarihleri bulunur. İçeriği etkileyen güncellemeler ayrıca belirtilir. Harici platformların ekranları ve kuralları değişebileceğinden işlem öncesinde yazının kaynaklarına da bakabilirsin.</p></section><section><h2 className="text-2xl font-semibold">Görseller ve ürün bilgileri</h2><p className="mt-3 text-lp-muted">Şematik kapaklar anlatımı destekleyen çizimlerdir; gerçek bir işletmenin veya uygulama ekranının fotoğrafı değildir. Gerçek görsel kullanılan yazılarda kaynak ve kullanım bilgisi belirtilir. Ürün özellikleri, fiyatlar ve sonuçlar doğrulanmadan kesin vaat olarak verilmez.</p></section><section><h2 className="text-2xl font-semibold">Bize bildir</h2><p className="mt-3 text-lp-muted">Yanlış veya eski bir bilgi fark edersen yazının bağlantısını ve düzeltilmesini istediğin bölümü iletişim sayfasından iletebilirsin.</p><Link href="/iletisim" className="mt-4 inline-flex min-h-11 items-center rounded text-lp-secondary underline underline-offset-4 focus-visible:ring-2">İletişim sayfasına git →</Link></section></div></article>;
}
''')

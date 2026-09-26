from pathlib import Path
root=Path.cwd()
def write(path, text):
 p=root/path
 p.parent.mkdir(parents=True,exist_ok=True)
 p.write_text(text,encoding='utf-8')
def change(path, before, after):
 p=root/path
 s=p.read_text(encoding='utf-8')
 assert before in s, (path,before[:60])
 p.write_text(s.replace(before,after),encoding='utf-8')
write('public_web/src/lib/blogKesif.ts', '''import type { BlogKategori, BlogListeYazisi } from "@/data/blogYazilari";

export function blogAramaMetni(metin: string): string {
  return metin.toLocaleLowerCase("tr-TR").normalize("NFD").replace(/[\\u0300-\\u036f]/g, "").replace(/ı/g, "i");
}

export function blogYazilariniFiltrele(yazilar: BlogListeYazisi[], arama: string, kategori: "Tümü" | BlogKategori): BlogListeYazisi[] {
  const kelimeler = blogAramaMetni(arama).trim().split(/\\s+/).filter(Boolean);
  return yazilar.filter((yazi) => {
    if (kategori !== "Tümü" && yazi.kategori !== kategori) return false;
    const metin = blogAramaMetni([yazi.baslik, yazi.ozet, yazi.kategori, ...yazi.sektorler].join(" "));
    return kelimeler.every((kelime) => metin.includes(kelime));
  });
}
''')
write('public_web/src/components/blog/BlogKapak.tsx', '''import Image from "next/image";
import type { BlogListeYazisi } from "@/data/blogYazilari";

export function BlogKapak({ yazi, oncelikli = false }: { yazi: Pick<BlogListeYazisi, "kapak" | "kapakAlt" | "baslik" | "kategori">; oncelikli?: boolean }) {
  if (yazi.kapak) return <div className="relative aspect-[16/9] overflow-hidden rounded-2xl"><Image src={yazi.kapak} alt={yazi.kapakAlt || yazi.baslik} fill preload={oncelikli} sizes="(max-width: 768px) 100vw, 600px" className="object-cover" /></div>;
  const iletisim = yazi.kategori === "Müşteri İletişimi";
  const google = yazi.kategori === "Google ve Keşfedilme";
  const vurgu = iletisim ? "#8bd5bb" : google ? "#f0c98a" : "#91c9ff";
  return (
    <div aria-hidden="true" className="relative aspect-[16/9] overflow-hidden rounded-2xl border border-white/10 bg-[#102344]">
      <svg viewBox="0 0 640 360" className="h-full w-full" fill="none">
        <path d="M0 90H640M0 180H640M0 270H640M160 0V360M320 0V360M480 0V360" stroke="white" strokeOpacity=".045" />
        <circle cx="488" cy="108" r="122" fill={vurgu} fillOpacity=".09" />
        <circle cx="488" cy="108" r="153" stroke={vurgu} strokeOpacity=".18" />
        <rect x="204" y="59" width="238" height="270" rx="15" fill="#06152f" stroke={vurgu} strokeOpacity=".4" transform="rotate(-6 204 59)" />
        <rect x="237" y="56" width="234" height="274" rx="14" fill="#eff5fa" transform="rotate(5 237 56)" />
        <rect x="257" y="79" width="190" height="104" rx="8" fill={vurgu} transform="rotate(5 257 79)" />
        {google ? <g stroke="#102344" strokeWidth="8"><circle cx="344" cy="133" r="22" /><path d="m362 151 22 22" strokeLinecap="round" /></g> : iletisim ? <g><rect x="303" y="109" width="79" height="46" rx="12" fill="#102344" /><path d="m320 151-5 15 22-13" fill="#102344" /><path d="M320 127h44M320 139h29" stroke={vurgu} strokeWidth="4" strokeLinecap="round" /></g> : <g stroke="#102344" strokeWidth="6" strokeLinejoin="round"><path d="M312 132h66v39h-66zM304 130l10-24h54l12 24z" /><path d="M337 171v-24h17v24" /></g>}
        <path d="m251 205 130 11m-132 6 91 8m-93 22 173 15m-175 3 151 13" stroke="#7c91a8" strokeWidth="7" strokeLinecap="round" />
        <rect x="76" y="231" width="140" height="59" rx="13" fill="#18365a" stroke={vurgu} strokeOpacity=".5" />
        <circle cx="105" cy="260" r="13" fill={vurgu} /><path d="m99 260 4 4 8-9" stroke="#102344" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" />
        <path d="M128 253h63m-63 14h43" stroke={vurgu} strokeWidth="5" strokeLinecap="round" />
      </svg>
      <span className="absolute left-5 top-5 text-[11px] font-bold uppercase tracking-[.18em] text-white/75">Vixrex / Rehber</span>
    </div>
  );
}
''')
write('public_web/src/components/blog/BlogKesif.tsx', '''"use client";

import Link from "next/link";
import { useMemo, useState } from "react";
import { BLOG_KATEGORILERI, type BlogKategori, type BlogListeYazisi } from "@/data/blogYazilari";
import { tarihiYaz } from "@/lib/blogIcerik";
import { blogYazilariniFiltrele } from "@/lib/blogKesif";
import { BlogKapak } from "./BlogKapak";

const odak = "outline-none focus-visible:ring-2 focus-visible:ring-lp-secondary focus-visible:ring-offset-4 focus-visible:ring-offset-lp-bg-editor";

export function BlogKesif({ yazilar }: { yazilar: BlogListeYazisi[] }) {
  const [arama, setArama] = useState("");
  const [kategori, setKategori] = useState<"Tümü" | BlogKategori>("Tümü");
  const [limit, setLimit] = useState(9);
  const aktifKategoriler = BLOG_KATEGORILERI.filter((aday) => yazilar.some((yazi) => yazi.kategori === aday));
  const filtreAktif = Boolean(arama.trim()) || kategori !== "Tümü";
  const oneCikan = yazilar.find((yazi) => yazi.slug === "dijital-vitrin-hazirlik-listesi") || yazilar[0];
  const sonuclar = useMemo(() => blogYazilariniFiltrele(yazilar, arama, kategori), [yazilar, arama, kategori]);
  const liste = filtreAktif ? sonuclar : sonuclar.filter((yazi) => yazi.slug !== oneCikan?.slug);
  function temizle() { setArama(""); setKategori("Tümü"); setLimit(9); }

  return (
    <div className="bg-lp-bg-editor px-5 pb-16 pt-8 sm:px-8 sm:pt-12">
      <div className="mx-auto max-w-[1200px]">
        <header className="border-b border-lp-border/60 pb-10 sm:flex sm:items-end sm:justify-between sm:gap-10 sm:pb-12">
          <div>
            <p className="text-xs font-bold uppercase tracking-[.22em] text-lp-secondary">Vixrex Blog</p>
            <h1 className="mt-4 max-w-[780px] text-4xl font-bold leading-[1.1] tracking-[-.035em] text-lp-text sm:text-5xl lg:text-6xl">İşletmen için<br /><span className="text-lp-secondary">işe yarayan bilgiler.</span></h1>
          </div>
          <p className="mt-5 max-w-[340px] text-base leading-7 text-lp-muted">Dijital vitrinden müşteri iletişimine: okuyup kendi işletmende uygulayabileceğin rehberler.</p>
        </header>

        {oneCikan ? <section aria-labelledby="one-cikan-baslik" className="grid items-center gap-7 py-10 lg:grid-cols-[1.15fr_1fr] lg:gap-12 lg:py-12">
          <Link href={`/blog/${oneCikan.slug}`} aria-label={oneCikan.baslik} className={`block rounded-2xl ${odak}`}><BlogKapak yazi={oneCikan} oncelikli /></Link>
          <div>
            <p className="text-xs font-bold uppercase tracking-[.14em] text-lp-secondary">Başlamak için · {oneCikan.kategori}</p>
            <h2 id="one-cikan-baslik" className="mt-4 text-3xl font-bold leading-tight tracking-tight text-lp-text sm:text-4xl"><Link href={`/blog/${oneCikan.slug}`} className={`rounded ${odak} hover:text-lp-secondary`}>{oneCikan.baslik}</Link></h2>
            <p className="mt-4 text-base leading-7 text-lp-muted">{oneCikan.ozet}</p>
            <p className="mt-5 text-sm text-lp-muted">{oneCikan.okumaDakika} dk okuma <span aria-hidden="true">·</span> <time dateTime={oneCikan.yayinTarihi}>{tarihiYaz(oneCikan.yayinTarihi)}</time></p>
            <Link href={`/blog/${oneCikan.slug}`} className={`mt-6 inline-flex min-h-12 items-center rounded-xl bg-lp-primary px-6 font-bold text-lp-on-primary ${odak}`}>Rehberi oku <span aria-hidden="true" className="ml-5">↗</span></Link>
          </div>
        </section> : null}

        <section aria-labelledby="rehberler-baslik" className="border-t border-lp-border/60 pt-9">
          <div className="flex flex-col gap-5 md:flex-row md:items-end md:justify-between">
            <div><p className="text-xs font-bold uppercase tracking-[.18em] text-lp-secondary">Bilgiden uygulamaya</p><h2 id="rehberler-baslik" className="mt-2 text-3xl font-bold text-lp-text">Sıradaki adımını bul.</h2></div>
            <div className="w-full md:max-w-[360px]"><label htmlFor="blog-arama" className="mb-2 block text-sm font-semibold text-lp-muted">Rehberlerde ara</label><input id="blog-arama" type="search" value={arama} onChange={(e) => { setArama(e.target.value); setLimit(9); }} placeholder="Örn. Google, kuaför, iletişim" className="min-h-12 w-full rounded-xl border border-lp-border bg-lp-surface px-4 text-base text-lp-text outline-none placeholder:text-lp-muted focus:border-lp-secondary focus:ring-2 focus:ring-lp-secondary/40" /></div>
          </div>
          <div aria-label="Blog kategorileri" className="mt-6 flex flex-wrap gap-2">
            {(["Tümü", ...aktifKategoriler] as const).map((aday) => <button key={aday} type="button" aria-pressed={kategori === aday} onClick={() => { setKategori(aday); setLimit(9); }} className={`min-h-11 rounded-full border px-4 text-sm font-semibold ${odak} ${kategori === aday ? "border-lp-secondary bg-lp-secondary text-lp-on-primary" : "border-lp-border bg-transparent text-lp-muted hover:border-lp-secondary hover:text-lp-text"}`}>{aday}</button>)}
          </div>
          <div className="mt-6 flex min-h-11 items-center justify-between gap-3 text-sm text-lp-muted"><p role="status" aria-live="polite">{filtreAktif ? `${liste.length} sonuç` : `${yazilar.length} yazı · İşletmene uygun bir konu seç`}</p>{filtreAktif ? <button type="button" onClick={temizle} className={`min-h-11 rounded px-2 font-semibold text-lp-secondary ${odak}`}>Filtreleri temizle</button> : null}</div>
          {liste.length ? <div className="mt-3 grid gap-x-7 gap-y-10 md:grid-cols-2 lg:grid-cols-3">{liste.slice(0, limit).map((yazi) => <article key={yazi.slug} className="group min-w-0">
            <Link href={`/blog/${yazi.slug}`} className={`block h-full rounded-2xl ${odak}`}>
              <BlogKapak yazi={yazi} />
              <div className="pt-5"><p className="text-xs font-bold text-lp-secondary">{yazi.kategori}</p><h3 className="mt-2 text-xl font-semibold leading-snug tracking-tight text-lp-text transition-colors group-hover:text-lp-secondary">{yazi.baslik}</h3><p className="mt-3 text-sm leading-6 text-lp-muted">{yazi.ozet}</p><p className="mt-4 text-xs text-lp-muted"><time dateTime={yazi.guncellemeTarihi || yazi.yayinTarihi}>{yazi.guncellemeTarihi && yazi.guncellemeTarihi !== yazi.yayinTarihi ? "Güncellendi · " : ""}{tarihiYaz(yazi.guncellemeTarihi || yazi.yayinTarihi)}</time> · {yazi.okumaDakika} dk okuma <span aria-hidden="true" className="float-right text-lg text-lp-secondary">↗</span></p></div>
            </Link>
          </article>)}</div> : <div className="mt-3 rounded-2xl border border-dashed border-lp-border p-8"><h3 className="text-lg font-semibold text-lp-text">Bu aramada yazı bulunamadı.</h3><p className="mt-2 text-lp-muted">Daha kısa bir kelime dene veya tüm rehberlere dön.</p><button onClick={temizle} type="button" className={`mt-4 min-h-11 rounded text-sm font-bold text-lp-secondary ${odak}`}>Tüm rehberleri göster →</button></div>}
          {liste.length > limit ? <button type="button" onClick={() => setLimit((deger) => deger + 9)} className={`mx-auto mt-10 block min-h-12 rounded-xl border border-lp-border px-6 font-bold text-lp-text ${odak}`}>Daha fazla yazı göster ({liste.length - limit})</button> : null}
        </section>

        <section className="mt-16 flex flex-col gap-6 rounded-2xl border border-lp-border bg-lp-surface p-7 sm:flex-row sm:items-center sm:justify-between sm:p-9"><div><p className="text-xs font-bold uppercase tracking-[.16em] text-lp-secondary">Şimdi kendi işletmen için</p><h2 className="mt-3 text-2xl font-semibold text-lp-text">Bilgilerini bir vitrinde buluştur.</h2><p className="mt-2 max-w-xl text-sm leading-6 text-lp-muted">İşletme bilgilerini, hizmetlerini ve iletişim yollarını nasıl sunabileceğini vitrin örneklerinde incele.</p></div><Link href="/kesfet" className={`inline-flex min-h-12 shrink-0 items-center justify-center rounded-xl bg-lp-primary px-5 font-bold text-lp-on-primary ${odak}`}>Vitrinleri keşfet →</Link></section>
        <footer className="mt-10 flex flex-wrap items-center justify-between gap-5 border-t border-lp-border/60 pt-6 text-sm text-lp-muted"><p>Vixrex tarafından hazırlanan işletme rehberleri.</p><div className="flex gap-5"><Link href="/blog/yayin-ilkeleri" className={`rounded py-3 hover:text-lp-text ${odak}`}>Yayın ilkeleri</Link><Link href="/blog/rss.xml" className={`rounded py-3 hover:text-lp-text ${odak}`}>RSS</Link></div></footer>
      </div>
    </div>
  );
}
''')
write('public_web/src/components/blog/BlogPaylas.tsx', '''"use client";

import { useState } from "react";

export function BlogPaylas({ baslik }: { baslik: string }) {
  const [durum, setDurum] = useState("");
  async function kopyala() {
    try {
      await navigator.clipboard.writeText(window.location.href.split("#")[0]);
      setDurum("Bağlantı kopyalandı.");
    } catch { setDurum("Bağlantı kopyalanamadı. Tarayıcının adres çubuğundan kopyalayabilirsin."); }
  }
  async function paylas() {
    if (!navigator.share) { await kopyala(); return; }
    try { await navigator.share({ title: baslik, url: window.location.href.split("#")[0] }); }
    catch (hata) { if (!(hata instanceof Error && hata.name === "AbortError")) setDurum("Paylaşım açılamadı. Bağlantıyı kopyalayabilirsin."); }
  }
  return <div className="mt-6 flex flex-wrap items-center gap-x-5 gap-y-2 text-sm text-lp-secondary"><button type="button" onClick={paylas} className="min-h-11 rounded font-semibold outline-none focus-visible:ring-2 focus-visible:ring-lp-secondary">Paylaş ↗</button><button type="button" onClick={kopyala} className="min-h-11 rounded font-semibold outline-none focus-visible:ring-2 focus-visible:ring-lp-secondary">Bağlantıyı kopyala</button><span role="status" className="text-lp-muted">{durum}</span></div>;
}
''')
change('public_web/src/data/blogYazilari.ts', 'export function yayindakiYazilar(): YayindakiBlogYazisi[] {\n  return BLOG_YAZILARI.filter(yayinaUygun)', '''export function blogOnizlemeMi(): boolean {
  return process.env.NODE_ENV === "development" && process.env.BLOG_ONIZLEME === "1";
}

export function yayindakiYazilar(): YayindakiBlogYazisi[] {
  const kaynak = blogOnizlemeMi()
    ? BLOG_YAZILARI.filter((yazi) => yazi.durum !== "arsiv").map((yazi) => ({ ...yazi, yayinda: true, durum: "yayinda" as const, yayinTarihi: yazi.yayinTarihi || yazi.sonKontrolTarihi }))
    : BLOG_YAZILARI;
  return kaynak.filter(yayinaUygun)''')
write('public_web/src/app/(site)/blog/layout.tsx', '''import type { Metadata } from "next";
import { blogOnizlemeMi } from "@/data/blogYazilari";

export function generateMetadata(): Metadata {
  return blogOnizlemeMi() ? { robots: { index: false, follow: false } } : {};
}

export default function BlogLayout({ children }: { children: React.ReactNode }) {
  return <>{blogOnizlemeMi() ? <div className="border-y border-amber-300/30 bg-amber-950 px-5 py-3 text-center text-sm text-amber-100">Yayın öncesi önizleme · Bu yazılar henüz yayında değil.</div> : null}{children}</>;
}
''')
p='public_web/src/app/(site)/blog/[slug]/page.tsx'
change(p, 'import { notFound } from "next/navigation";', 'import { notFound } from "next/navigation";\nimport { BlogKapak } from "@/components/blog/BlogKapak";\nimport { BlogPaylas } from "@/components/blog/BlogPaylas";')
change(p, 'okumaDakika >= 5 && icindekiler.length >= 2', 'icindekiler.length >= 3')
s=(root/p).read_text(encoding='utf-8')
start=s.index('                <div\n                  className="relative mt-8 flex aspect-[16/9]')
end=s.index('\n              )}',start)
s=s[:start]+'                <div className="mt-8"><BlogKapak yazi={yazi} /></div>'+s[end:]
s=s.replace('              <aside\n                className="mt-7', '              <BlogPaylas baslik={yazi.baslik} />\n\n              <aside\n                className="mt-7',1)
s=s.replace('self-start border-l border-lp-border pl-5 lg:sticky lg:top-24 lg:block', 'self-start border-l border-lp-border pl-5 lg:sticky lg:top-6 lg:block lg:max-h-[calc(100vh-3rem)] lg:overflow-y-auto')
(root/p).write_text(s,encoding='utf-8')

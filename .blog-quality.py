from pathlib import Path
r=Path.cwd()
def write(path,s):
 p=r/path;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(s,encoding='utf-8')
def change(path,a,b):
 p=r/path;s=p.read_text(encoding='utf-8');assert a in s,(path,a[:60]);p.write_text(s.replace(a,b),encoding='utf-8')
change('public_web/tests/yardimcilar/landingEsitlikIstisnalariWeb.ts','export const LANDING_ESITLIK_ISTISNALARI_WEB: Istisna[] = [','''export const LANDING_ESITLIK_ISTISNALARI_WEB: Istisna[] = [
  ...["İşletmen için pratik rehberler.", "İlk vitrinden günlük müşteri iletişimine, bir sonraki adımın burada.", "Tüm rehberler →"].map((metin) => ({
    metin,
    neden: "11 Eylül 2026 kurumsal blog görevi: vixrex.com landing sayfasına yayın anahtarlı blog erişimi eklendi. Flutter kaynakları bu görevin kapsamında değil.",
  })),''')
write('public_web/src/app/(site)/blog/kapak/[slug]/route.tsx','''import { ImageResponse } from "next/og";
import { blogYayindaMi, yaziyiBul } from "@/data/blogYazilari";

export async function GET(_request: Request, { params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const yazi = yaziyiBul(slug);
  if (!yazi && (slug !== "blog" || !blogYayindaMi())) return new Response("Bulunamadı", { status: 404 });
  return new ImageResponse(<div style={{ display: "flex", flexDirection: "column", justifyContent: "space-between", width: "100%", height: "100%", padding: "68px 76px", background: "#071426", color: "#f7fbff", borderBottom: "16px solid #57b7ff" }}><div style={{ display: "flex", justifyContent: "space-between", fontSize: 26, color: "#91c9ff" }}><span>VIXREX BLOG</span><span>{yazi?.kategori || "İşletme rehberleri"}</span></div><div style={{ display: "flex", fontSize: 62, lineHeight: 1.16, fontWeight: 700, letterSpacing: -2 }}>{yazi?.baslik || "İşletmen için işe yarayan bilgiler."}</div><div style={{ display: "flex", fontSize: 25, color: "#a9bbda" }}>vixrex.com/blog</div></div>, { width: 1200, height: 630 });
}
''')
p='public_web/src/app/(site)/blog/[slug]/page.tsx'
change(p,'const kapakUrl = yazi.kapak ? mutlakUrl(yazi.kapak) : undefined;','const kapakUrl = yazi.kapak ? mutlakUrl(yazi.kapak) : buildSiteUrl(`/blog/kapak/${yazi.slug}`);')
change(p,'const kapakUrl = yazi.kapak ? mutlakUrl(yazi.kapak) : null;','const kapakUrl = yazi.kapak ? mutlakUrl(yazi.kapak) : buildSiteUrl(`/blog/kapak/${yazi.slug}`);')
change(p,'    description: yazi.ozet,\n    alternates:', '    description: yazi.ozet,\n    twitter: { card: "summary_large_image", title: yazi.baslik, description: yazi.ozet, images: [kapakUrl] },\n    alternates:')
change('public_web/src/app/(site)/blog/page.tsx','url: "/blog", type: "website", locale: "tr_TR"','url: "/blog", type: "website", locale: "tr_TR", images: [{ url: "/blog/kapak/blog", width: 1200, height: 630, alt: "Vixrex Blog — işletme rehberleri" }]')
write('public_web/tests/blog-kesif.test.ts','''import { afterEach, describe, expect, it, vi } from "vitest";
import { BLOG_YAZILARI, blogOnizlemeMi, yayindakiYazilar, type BlogListeYazisi } from "@/data/blogYazilari";
import { blogYazilariniFiltrele } from "@/lib/blogKesif";

const liste: BlogListeYazisi[] = BLOG_YAZILARI.map((yazi) => ({ ...yazi, yayinTarihi: "2026-09-11", okumaDakika: 3 }));
afterEach(() => vi.unstubAllEnvs());

describe("blog keşfi ve önizleme sınırı", () => {
  it("Türkçe karakter kullanılmayan aramayı bulur", () => {
    expect(blogYazilariniFiltrele(liste, "KUAFOR", "Tümü").some((yazi) => yazi.slug === "kuafor-icin-internet-sitesi")).toBe(true);
    expect(blogYazilariniFiltrele(liste, "musteri ILETISIMI", "Tümü").length).toBeGreaterThan(0);
  });
  it("kategori ile arama birlikte uygulanır ve boş sonuç gizlenmez", () => {
    expect(blogYazilariniFiltrele(liste, "kuafor", "Google ve Keşfedilme")).toEqual([]);
    expect(blogYazilariniFiltrele(liste, "", "Tümü")).toHaveLength(liste.length);
    expect(blogYazilariniFiltrele(liste, "bulunmayan-sozcuk", "Tümü")).toEqual([]);
  });
  it("içerik türüne göre haber veya hikâye saklamaz", () => {
    const haber = { ...liste[0], slug: "haber", icerikTuru: "haber" as const };
    const hikaye = { ...liste[0], slug: "hikaye", icerikTuru: "isletme_hikayesi" as const };
    expect(blogYazilariniFiltrele([haber, hikaye], "", "Tümü")).toHaveLength(2);
  });
  it("üretimde önizleme değişkeni taslakları açamaz", () => {
    vi.stubEnv("NODE_ENV", "production");
    vi.stubEnv("BLOG_ONIZLEME", "1");
    expect(blogOnizlemeMi()).toBe(false);
    for (const yazi of yayindakiYazilar()) expect(yazi.yayinda && yazi.durum !== "taslak").toBe(true);
    expect(yayindakiYazilar()).toHaveLength(0);
  });
  it("yerel önizleme taslak kaynağını değiştirmez", () => {
    vi.stubEnv("NODE_ENV", "development");
    vi.stubEnv("BLOG_ONIZLEME", "1");
    expect(yayindakiYazilar()).toHaveLength(BLOG_YAZILARI.length);
    expect(BLOG_YAZILARI.every((yazi) => !yazi.yayinda && yazi.durum === "taslak")).toBe(true);
  });
});
''')
write('public_web/.blog-smoke.cjs','''const { chromium } = require('@playwright/test');
const fs = require('node:fs');
(async () => {
 const browser = await chromium.launch({headless:true});
 const page = await browser.newPage({viewport:{width:1440,height:1000}});
 const errors=[];page.on('pageerror',e=>errors.push(e.message));
 await page.goto('http://127.0.0.1:3107/blog',{waitUntil:'networkidle',timeout:120000});
 fs.mkdirSync('../blog-review',{recursive:true});
 await page.screenshot({path:'../blog-review/blog-desktop.png',fullPage:true});
 console.log(JSON.stringify({title:await page.title(),headings:await page.locator('h1,h2,h3').allTextContents(),overflow:await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth),errors}));
 await page.setViewportSize({width:390,height:844});
 await page.screenshot({path:'../blog-review/blog-mobile.png',fullPage:true});
 await page.goto('http://127.0.0.1:3107/blog/dijital-vitrin-hazirlik-listesi',{waitUntil:'networkidle',timeout:120000});
 await page.screenshot({path:'../blog-review/article-mobile.png',fullPage:true});
 console.log(JSON.stringify({article:await page.title(),overflow:await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth),errors}));
 await browser.close();
})().catch(e=>{console.error(e);process.exit(1)});
''')

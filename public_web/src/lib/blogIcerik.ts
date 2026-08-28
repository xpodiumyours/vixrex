import { sanitizeHtml } from "@/lib/sanitize";
import { isExternalHttpUrl } from "@/lib/siteUrl";

/**
 * Vixrex blog yazılarının gösterim yardımcıları.
 *
 * NEDEN AYRI DOSYA: aynı işi yapan `formatContent`, vitrin yazılarının
 * sayfasında (`app/v/[slug]/yazilar/[articleSlug]/page.tsx`) sayfa içine
 * gömülü duruyor. Orası bu işin kapsamı dışında — 29 canlı vitrini
 * ilgilendiren bir dosyayı blog için kıpırdatmak gereksiz risk. Bu yüzden
 * aynı desen burada, test edilebilir biçimde tekrar ediliyor. Vitrin
 * tarafındaki kopya değişirse buranın da gözden geçirilmesi gerekir.
 *
 * Güvenlik sırası değişmez: önce `sanitizeHtml`, sonra paragraflama, en
 * sonda dış bağlantı işaretlemesi.
 */

function disBaglantilariIsaretle(html: string): string {
  if (!html) return "";
  return html.replace(
    /<a\s+([^>]*?)href="([^"]+?)"([^>]*?)>/gi,
    (eslesme, onEk, adres, sonEk) => {
      if (!isExternalHttpUrl(adres)) return eslesme;
      if (/rel=/i.test(eslesme)) {
        return eslesme.replace(/rel="([^"]+?)"/i, 'rel="$1 ugc nofollow"');
      }
      return `<a ${onEk}href="${adres}"${sonEk} rel="ugc nofollow">`;
    }
  );
}

/**
 * Düz metni paragraflara çevirir. Boş satır paragraf ayırır.
 * Yazılar HTML içermez (bkz. `blogYazilari.ts` gövde biçimi notu), ama
 * ileride içerirse de temizleyiciden geçmiş olur.
 */
export function govdeyiBicimlendir(metin: string): string {
  if (!metin) return "";
  const temiz = sanitizeHtml(metin);

  if (temiz.includes("<p>") || temiz.includes("<br") || temiz.includes("</div>")) {
    return disBaglantilariIsaretle(temiz);
  }

  const paragraflar = temiz
    .split(/\n\s*\n/)
    .map((p) => `<p class="mb-4 leading-relaxed">${p.replace(/\n/g, "<br />")}</p>`)
    .join("");

  return disBaglantilariIsaretle(paragraflar);
}

/** "2026-09-01" → "1 Eylül 2026". Liste kartı ve yazı başlığı kullanır. */
export function tarihiYaz(isoTarih: string): string {
  return new Date(isoTarih).toLocaleDateString("tr-TR", {
    day: "numeric",
    month: "long",
    year: "numeric",
  });
}

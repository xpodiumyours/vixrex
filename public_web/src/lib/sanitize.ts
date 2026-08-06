import sanitizeHtmlLib from "sanitize-html";

/**
 * Esnafın yazdığı blog içeriğini güvenli hâle getirir.
 *
 * NEDEN KÜTÜPHANE, NEDEN DÜZENLİ İFADE DEĞİL
 * Bu dosya eskiden regex ile etiket siliyordu. O yöntem atlatılabilir:
 *
 *     <scr<script>ipt>alert(1)</scr</script>ipt>
 *
 * İçteki `<script>` silinince geriye çalışan bir `<script>` kalır. CodeQL
 * bunu "Bad HTML filtering regexp" ve "Incomplete multi-character
 * sanitization" olarak üç ayrı yüksek önemli uyarıyla bildirdi
 * (2026-07-18'den beri açıktı).
 *
 * İçerik `dangerouslySetInnerHTML` ile doğrudan sayfaya basılıyor ve
 * yazıyı esnaf giriyor — yani girdi güvenilmez, çıktı herkese görünür.
 * Bu ikisi bir aradayken regex temizleme yeterli değildir.
 *
 * YAKLAŞIM: izin listesi (allowlist). Aşağıda sayılmayan her etiket ve
 * her öznitelik atılır — yeni bir saldırı yöntemi çıktığında listeyi
 * güncellemek gerekmez, çünkü bilinmeyen her şey zaten reddedilir.
 */

const IZINLI_ETIKETLER = [
  "p", "br", "strong", "b", "em", "i", "u",
  "ul", "ol", "li",
  "h2", "h3", "h4",
  "blockquote",
  "a",
];

export function sanitizeHtml(html: string): string {
  if (!html) return "";

  return sanitizeHtmlLib(html, {
    allowedTags: IZINLI_ETIKETLER,

    allowedAttributes: {
      // Bağlantıda yalnız adres, başlık ve sekme davranışı.
      // class/style/id yok: sayfa düzeni ele geçirilemesin.
      a: ["href", "title", "target", "rel"],
      p: ["class"],
    },

    // javascript: ve data: adresleri düşer; yalnız bunlar kalır.
    allowedSchemes: ["http", "https", "mailto", "tel"],
    allowedSchemesAppliedToAttributes: ["href"],

    // Dış bağlantılar yeni sekmede ve referans sızdırmadan açılır.
    transformTags: {
      a: (etiket, oz) => ({
        tagName: "a",
        attribs: {
          ...oz,
          rel: "noopener noreferrer nofollow",
        },
      }),
    },

    // İzinsiz etiketin İÇERİĞİ korunur, etiketin kendisi atılır —
    // böylece yazı kaybolmaz, yalnız biçimlendirme düşer.
    disallowedTagsMode: "discard",
  });
}

/**
 * JSON-LD verisini <script type="application/ld+json"> içine güvenli basar.
 *
 * NEDEN
 * `JSON.stringify` çıktısında `<` karakteri kaçmaz. Mağaza adı, ürün adı,
 * yazı başlığı gibi kullanıcı girdisi doğrudan JSON-LD içine gömülüyor
 * (dangerouslySetInnerHTML ile). Birisi mağaza adına
 * `</script><script>...` yazarsa, ld+json bloğu erken kapanır ve arkasına
 * gerçekten çalışan bir <script> eklenmiş olur — saklı (stored) XSS.
 *
 * ÇÖZÜM: `<` karakterini, unicode kod noktasının (U+003C) JSON escape
 * biçimiyle değiştir. Bu geçerli bir JSON kaçışı — tarayıcı içeriği hâlâ
 * doğru ayrıştırır — ama artık HTML parser'ı tarafından `</script` olarak
 * okunamaz.
 */
export function safeJsonLdHtml(data: unknown): string {
  return JSON.stringify(data).replace(/</g, "\\u003c");
}

/**
 * Platformun kendisini tanımlayan yapılandırılmış veri.
 *
 * 2026-08-26'ya kadar sitede yalnız vitrin/ürün/yazı düzeyinde JSON-LD
 * vardı; "Vixrex nedir, bu site kimin" sorusunun makine tarafından
 * okunabilir bir cevabı yoktu. Vitrin sayfalarındaki BreadcrumbList
 * zaten 1. basamakta siteUrl'e "Ana Sayfa" diye işaret ediyordu — o
 * adres bugüne kadar başka bir yere yönleniyordu.
 *
 * `potentialAction`/`SearchAction` BİLEREK yok: gerçek bir site içi arama
 * yokken beyan etmek boş sinyaldir.
 */
export function organizationJsonLd(siteUrl: string) {
  return {
    "@context": "https://schema.org",
    "@type": "Organization",
    name: "Vixrex",
    url: siteUrl,
    description:
      "İşletmelerin bilgilerini, ürünlerini, adresini ve WhatsApp iletişimini tek linkte toplayan dijital vitrin platformu.",
    areaServed: "TR",
  };
}

export function webSiteJsonLd(siteUrl: string) {
  return {
    "@context": "https://schema.org",
    "@type": "WebSite",
    name: "Vixrex",
    url: siteUrl,
    inLanguage: "tr-TR",
    publisher: { "@type": "Organization", name: "Vixrex", url: siteUrl },
  };
}

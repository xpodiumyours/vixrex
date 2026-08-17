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

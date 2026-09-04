# Katman 2.5 — Katman 3 Öncesi Profesyonel Sertleştirme

Durum: **AKTİF BLOKER**

Katman 3 RESEARCH bu 5 madde tamamlanmadan başlamaz.

## 1. Migration geçmişi eşitliği

Amaç: Repo migration dosya adları ile canlı Supabase migration history sürümlerini birebir hizalamak.

Doğrulanan eski sapma:
- Repo eski: `20260904173500_add_vixrex_blog_articles.sql`
- Canlı history: `20260904182313_add_vixrex_blog_articles`
- Repo eski: `20260904193000_add_vixrex_blog_library_metadata.sql`
- Canlı history: `20260904195755_add_vixrex_blog_library_metadata`

Uygulanan düzeltme:
- Katman 1 branch'inde dosya `20260904182313_add_vixrex_blog_articles.sql` olarak hizalandı.
- Katman 2 stack branch'inde aynı Katman 1 dosyası hizalandı.
- Katman 2 metadata dosyası `20260904195755_add_vixrex_blog_library_metadata.sql` olarak hizalandı.
- Eski iki timestamp dosyası aktif Katman 2 branch'inden kaldırıldı.
- Canlı şemaya bu hizalama için yeni SQL uygulanmadı; yalnız repo migration kimliği canlı history ile eşitlendi.

Kalan doğrulama:
- Sıfırdan migration zinciri + GRANT bekçisi yeni dosya adlarıyla tekrar geçmeli.

Durum: **dosya/history hizalaması yapıldı, zincir VERIFY bekliyor.**

## 2. Blog RLS performans sertleştirmesi

Supabase Performance Advisor, yeni blog tablolarındaki admin RLS policy'lerinde `auth.uid()` çağrılarının satır başına yeniden değerlendirilmesini işaretliyor.

Hedef:
- `vixrex_blog_articles`
- `vixrex_blog_article_relations`

Admin kontrolleri davranış değiştirmeden `(select auth.uid())` biçimine alınacak.

Uygulama branch'inde yeni hardening migration'ı eklendi:
- `20260904203000_optimize_vixrex_blog_rls.sql`

Kural:
- Public `published` görünürlüğü değişmeyecek.
- Admin yetkisi genişlemeyecek.
- `anon` taslak erişimi 0 kalacak.

Kalan doğrulama:
- sıfırdan migration zinciri
- gerçek allow/deny davranış testi
- canlı uygulama sonrası Supabase Performance Advisor tekrar kontrolü

Durum: **kodlandı, VERIFY bekliyor.**

## 3. Gerçek allow/deny davranış testleri

Mevcut Katman 2 testleri önemli sözleşmeleri kaynak kod üzerinden kilitliyor; bu tek başına gerçek RLS/API davranışını kanıtlamıyor.

Eklenecek davranış kontrolleri:
- anon taslak merkezi yazı okuyamaz
- anon/authenticated admin olmayan kullanıcı merkezi yazı oluşturamaz/güncelleyemez/silemez
- admin taslak okuyabilir/yönetebilir
- public yalnız `published` yazıyı görebilir
- relation public erişimi yalnız iki uç da `published` olduğunda mümkündür
- admin API normal kullanıcıyı reddeder, admin kullanıcıyı kabul eder

Durum: **bekliyor.**

## 4. Auth security durumunu doğru raporlama

CI `auth-config-check` işi secret'lar yoksa başarıyla çıkıp kontrolü atlayabiliyor. Bu nedenle yalnız job'ın yeşil olması canlı Auth güvenliğini ispatlamaz.

Canlı Security Advisor denetiminde `Leaked Password Protection` kapalı olarak raporlandı.

Uygulanan düzeltme:
- İlerleme panosunda `auth security geçti` şeklindeki mutlak ifade kaldırıldı.
- CI job sonucu ile canlı Auth Advisor sonucu ayrı raporlanıyor.
- Canlı `Leaked Password Protection` durumu açıkça `kapalı` olarak kaydedildi.

Durum: **TAMAMLANDI.**

## 5. Taslak blog içerik doğruluğu ve provenance

Mevcut iki merkezi yazı `draft` kalacak.

Yayın öncesi:
- değişebilen Google/SEO/ürün iddiaları güncel birincil kaynaklarla doğrulanacak
- kesin olmayan süre/sonuç ifadeleri kaldırılacak veya koşullu yazılacak
- `source_urls` ve provenance alanları gerçek kaynaklarla doldurulacak
- doğrulama tamamlanmadan `published` yapılmayacak

İlk kaynak araştırması doğrulandı:
- Google Business Profile doğrulama yöntemi tek bir posta kartı yöntemi değildir; kullanılabilir yöntemleri Google işletmeye göre otomatik belirler.
- Yerel sonuçlar ağırlıklı olarak alaka düzeyi, mesafe ve belirginlik/popülerlik sinyallerine dayanır.
- Google Search belirli bir sayfanın dizine eklenmesini veya belirli bir sürede sonuç göstermesini garanti etmez.

Bu nedenle eski `Google adresinize kod içeren kart gönderir` ve sabit `bir ila dört hafta` gibi kesin ifadeler yayın öncesi düzeltilecektir.

Durum: **kaynak araştırması başladı, içerik/veri güncellemesi bekliyor.**

## Çıkış kriteri

Bu beş madde teknik kanıtlarla tamamlanır, ilerleme panosunda ayrı ayrı `[x]` yapılır ve ancak bundan sonra **Katman 3 — Vitrine Yazı Çekme / Taslak Enjeksiyonu RESEARCH** başlar.

# Katman 2.5 — Katman 3 Öncesi Profesyonel Sertleştirme

Durum: **AKTİF BLOKER**

Katman 3 RESEARCH bu 5 madde tamamlanmadan başlamaz.

## 1. Migration geçmişi eşitliği

Amaç: Repo migration dosya adları ile canlı Supabase migration history sürümlerini birebir hizalamak.

Doğrulanan sapma:
- Repo: `20260904173500_add_vixrex_blog_articles.sql`
- Canlı history: `20260904182313_add_vixrex_blog_articles`
- Repo: `20260904193000_add_vixrex_blog_library_metadata.sql`
- Canlı history: `20260904195755_add_vixrex_blog_library_metadata`

Kural:
- Canlı şema yeniden uygulanmayacak.
- Veri değiştiren yeni migration yazılmayacak.
- Önce migration history ile dosya adları eşitlenecek, sonra sıfırdan migration zinciri tekrar doğrulanacak.

Durum: **sapma doğrulandı, düzeltme bekliyor.**

## 2. Blog RLS performans sertleştirmesi

Supabase Performance Advisor, yeni blog tablolarındaki admin RLS policy'lerinde `auth.uid()` çağrılarının satır başına yeniden değerlendirilmesini işaretliyor.

Hedef:
- `vixrex_blog_articles`
- `vixrex_blog_article_relations`

Admin kontrolleri davranış değiştirmeden `(select auth.uid())` biçimine alınacak.

Kural:
- Public `published` görünürlüğü değişmeyecek.
- Admin yetkisi genişlemeyecek.
- `anon` taslak erişimi 0 kalacak.

Durum: **uyarı doğrulandı, düzeltme bekliyor.**

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

Plan kuralı:
- İlerleme panosunda bu kontrol artık `geçti` diye mutlak yazılmayacak.
- CI job sonucu ile canlı Auth Advisor sonucu ayrı raporlanacak.
- Bu madde blog davranışını değiştirmez; doğrulama raporlamasını düzeltir.

Durum: **plan kaydı düzeltilecek.**

## 5. Taslak blog içerik doğruluğu ve provenance

Mevcut iki merkezi yazı `draft` kalacak.

Yayın öncesi:
- değişebilen Google/SEO/ürün iddiaları güncel birincil kaynaklarla doğrulanacak
- kesin olmayan süre/sonuç ifadeleri kaldırılacak veya koşullu yazılacak
- `source_urls` ve provenance alanları gerçek kaynaklarla doldurulacak
- doğrulama tamamlanmadan `published` yapılmayacak

Özellikle eski `Google adresinize kod içeren kart gönderir` gibi tek doğrulama yöntemi varmış gibi yazılan ifadeler güncel Google Business Profile doğrulama yöntemleriyle uyumlu hale getirilecek.

Durum: **bekliyor.**

## Çıkış kriteri

Bu beş madde teknik kanıtlarla tamamlanır, ilerleme panosunda ayrı ayrı `[x]` yapılır ve ancak bundan sonra **Katman 3 — Vitrine Yazı Çekme / Taslak Enjeksiyonu RESEARCH** başlar.

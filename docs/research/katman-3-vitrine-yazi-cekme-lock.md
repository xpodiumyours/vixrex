# Katman 3 — Vitrine Yazı Çekme / Taslak Enjeksiyonu LOCK

Durum: **KİLİTLİ — kullanıcı onayı alındı.**

Araştırma: `docs/research/katman-3-vitrine-yazi-cekme-arastirma.md`

## Kilitli ürün davranışı

1. Yalnız `status='published'` merkezi Vixrex yazısı kaynak olabilir.
2. Enjeksiyon hiçbir koşulda doğrudan yayın yapmaz; yeni `store_articles` satırı daima `draft` oluşur.
3. Vitrin yazısında merkezi kaynak kimliği kalıcı provenance olarak tutulur.
4. Aynı merkezi yazı aynı vitrine istemeden ikinci kez eklenemez; tekrar istek idempotent davranır.
5. Yetki yalnız uygulama katmanında bırakılmaz; DB hedef vitrinin sahibini yeniden doğrular.
6. Esnaf oluşan taslağı mevcut Blog Yönetimi → Yazıyı Düzenle → Taslak Kaydet / Yayınla akışıyla yönetir.
7. Mevcut `store_articles` CRUD ve yayın sistemi yeniden yazılmaz.
8. Merkezi içerik yüzlerce vitrinde otomatik birebir yayınlanmaz.
9. İki mod korunur: `linked_excerpt` (kaynak bağlantılı kısa sürüm) ve `adaptable_draft` (vitrine uyarlanacak tam taslak).
10. Flutter ve Next.js aynı DB eylemini kullanabilecek şekilde istemciden bağımsız backend sözleşmesi kullanır; ayrı ikinci backend kurulmaz.
11. Vixrex Asistan blog komutları Katman 3'e alınmaz; Katman 4'te kalır.
12. BUILD sonrası yetki, published→draft, duplicate/idempotency, kaynak provenance, mevcut CRUD ve Flutter/Next.js regresyonları teknik VERIFY ile kanıtlanır.

## Kilitli veri modeli

`store_articles` için minimum provenance alanları:
- `source_vixrex_blog_article_id uuid null` → `vixrex_blog_articles.id`
- `source_vixrex_blog_article_slug text null` → kaynak slug snapshot'ı
- `source_vixrex_blog_import_mode text null` → `linked_excerpt | adaptable_draft`
- `source_vixrex_blog_imported_at timestamptz null`

Kaynak merkezi satır sonradan silinse bile vitrin yazısı silinmez. FK `ON DELETE SET NULL` olabilir; fakat kaynak slug snapshot'ı korunur. Duplicate engeli yalnız FK kimliğine bağlı bırakılmaz; `(store_slug, source_vixrex_blog_article_slug)` üzerinde partial unique index ile korunur.

## Kilitli import güvenliği

Dar import eylemi:
- hedef vitrin slug'ı alınır,
- Next.js için HttpOnly owner cookie doğrulanır ve session token DB'ye aktarılır,
- DB owner session / authenticated owner yetkisini hedef vitrinle eşleştirir,
- merkezi kaynağın `published` olduğunu DB içinde tekrar doğrular,
- yalnız hedef vitrinde `draft` snapshot oluşturur,
- aynı kaynak daha önce eklenmişse yeni satır yerine mevcut yazının kimliğini/slug'ını döndürür.

## Alan eşleme

Kopyalanabilir:
- central `title` → store `title`
- central `summary` → store `summary`
- central `cover_image_url` → store `cover_image_url`
- `adaptable_draft`: central `content` → store `content`
- `linked_excerpt`: merkezi özet + merkezi `/blog/[slug]` kaynak bağlantısı → store `content`
- store `article_type` → `standard`
- store `status` → daima `draft`

Kopyalanmaz:
- merkezi yayın tarihi
- merkezi SEO skoru/hataları
- merkezi konu ID'si doğrudan `target_topic` olarak
- merkezi konum metadata'sı doğrudan `target_city` olarak

SEO alanları mevcut vitrin editöründe yeniden hesaplanır.

## UX kilidi

Yeni paralel blog yönetim ekranı yok.

Next.js akışı:
`Blog Yönetimi → Vixrex Kütüphanesinden Yazı Ekle → yazı seç → mod seç → taslak oluştur → mevcut Yazıyı Düzenle`

Flutter tarafı aynı veri/RPC sözleşmesini kullanır ve mevcut Blog Yazılarım/Editör akışına bağlanabilir; davranış farklı bir veri modeline ayrılmaz.

## Kapsam dışı

- Asistan niyet motoru / blog komutları
- 46 vitrin alanı
- Keşfet
- Kirala/sahiplik oluşturma akışı
- public vitrin ana tasarımı
- Dijital Çarşı
- merkezi yazıların esnaf kopyalarını otomatik senkronlaması
- otomatik yayın

## BUILD çıkış kriteri

BUILD yalnız bu kilitli kapsamı uygular. Yeni ihtiyaç çıkarsa sessizce eklenmez; tekrar RESEARCH/LOCK kararı gerekir.

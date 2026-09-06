# Katman 3 — Vitrine Yazı Çekme / Taslak Enjeksiyonu Araştırması

Durum: **RESEARCH TAMAMLANDI — UYGUN AMA ŞARTLI**

Bu belge BUILD değildir. Kod veya canlı DB davranışı değiştirilmez.

## 1. Mevcut gerçeklik

### Merkezi Vixrex yazısı

`vixrex_blog_articles` merkezi içerik kaynağıdır. Public okuma katmanı yalnız `status='published'` yazıları döndürür; taslaklar fail-closed kalır.

Merkezi yazıda Katman 3 için kullanılabilecek alanlar:
- `id`
- `slug`
- `title`
- `summary`
- `content`
- `cover_image_url`
- `primary_topic`
- `purpose`
- sektör/konum/etiket metadata
- provenance ve `source_urls`

### Vitrin yazısı

Canlı `store_articles` şeması bugün:
- `id`
- `store_slug`
- `title`
- `slug`
- `summary`
- `content`
- `cover_image_url`
- `article_type`
- `target_topic`
- `target_city`
- `seo_score`
- `seo_errors`
- `status`
- `is_blog_trusted`
- yayın/oluşturma/güncelleme tarihleri

`store_articles` içinde merkezi Vixrex yazısıyla kaynağı bağlayan bir alan bugün **yok**.

Canlı tablo kısıtları:
- `(store_slug, slug)` unique
- `store_slug → stores.slug` FK, delete cascade
- status: `draft | review | published | rejected`
- public yalnız `published` okur
- owner kendi yazısını yönetebilir
- admin policy'leri ayrıca vardır

Canlı kullanım anlık görüntüsü: 15 `store_articles` satırı, 5 vitrin, tümü published; bir vitrindeki en yüksek yazı sayısı 3.

## 2. Mevcut oluşturma/yayın akışı

Next.js `/api/articles`:
- owner-session cookie ile korunuyor
- yeni yazıyı `store_articles` tablosuna ekliyor
- yeni yazı POST'ta zorunlu olarak `status='draft'`
- PATCH ile sahibi sonradan `draft` veya `published` yapabiliyor
- başlık/özet/içerik olmadan yayın engelleniyor

Owner blog ekranı zaten:
- yazı listesi
- yeni yazı
- düzenle
- taslak kaydet
- yayınla
- sil
akışına sahip.

Bu yüzden Katman 3 için ikinci bir blog editörü veya ikinci bir yayın sistemi kurmaya gerek yoktur.

Flutter da aynı `store_articles` tablosunu `ArticleService` üzerinden kullanır ve mevcut blog listesi/editörü vardır. Yeni kaynak ilişkisi mevcut satırı normal bir `store_articles` satırı olarak bırakırsa editörlerin temel CRUD davranışı korunabilir.

## 3. Hedefle uyum

Kilitli hedef teknik olarak mümkündür:

`merkezi yayınlanmış Vixrex yazısı → owner yetkisi → store_articles draft → mevcut editör → mevcut yayın akışı`

Bu akış yeni bir içerik sistemi kurmadan mevcut iki sistemi bağlar.

Sonuç: **UYGUN AMA ŞARTLI.**

## 4. Zorunlu şartlar

### Şart A — yalnız yayınlanmış merkezi yazı kaynak olabilir

Esnaf kütüphanesi `draft` merkezi yazıyı okuyamaz veya vitrine çekemez. Kaynak sorgusu hem API seviyesinde hem DB seviyesinde `status='published'` koşulunu doğrulamalıdır.

### Şart B — enjeksiyon her zaman draft oluşturur

Kaynak yazı `published` olsa bile yeni `store_articles` satırı yalnız `draft` oluşturulur. Kaynak status hiçbir biçimde vitrin status'una kopyalanmaz.

### Şart C — kaynak ilişkisi kalıcı tutulur

`store_articles` satırında merkezi kaynak kimliği tutulmalıdır. En küçük güvenli model:
- nullable `source_vixrex_blog_article_id uuid`
- FK → `vixrex_blog_articles.id`
- merkezi kaynak silinirse vitrin kopyası kaybolmamalı; ilişki için `ON DELETE SET NULL`

Bu ilişki Katman 4'te Asistan'ın hangi merkezi yazıyı çektiğini de deterministik biçimde bilmesini sağlar.

### Şart D — aynı kaynak aynı vitrine istemeden ikinci kez eklenemez

Partial unique index önerisi:
`(store_slug, source_vixrex_blog_article_id) WHERE source_vixrex_blog_article_id IS NOT NULL`

Tekrar istek idempotent davranmalıdır: ikinci kopya üretmek yerine mevcut taslağın kimliğini/slug'ını döndürmek daha güvenlidir.

### Şart E — owner-session yalnız uygulama katmanında bırakılmamalı

Mevcut `/api/articles` owner cookie doğrulaması sonrası service-role client ile CRUD yapıyor. Katman 3 enjeksiyonunda daha dar bir güvenlik sınırı önerilir:
- HttpOnly owner cookie doğrulanır
- cookie içindeki `sessionToken` DB RPC'ye verilir
- DB RPC geçerli/tüketilmiş/süresi dolmamış owner session ile hedef vitrini yeniden doğrular
- kaynak merkezi yazının published olduğunu DB içinde doğrular
- yalnız o vitrine draft insert yapar

Bu desen mevcut `owner-draft → update_working_draft_field` yapısındaki iki kapılı güvenlik modeline uyar ve Katman 4 tarafından tekrar kullanılabilir.

### Şart F — merkezi kaynak güncellenince esnaf kopyası sessizce overwrite edilmez

Enjeksiyon bir **snapshot draft** üretmelidir. Esnaf düzenlemeye başladıktan sonra merkezi yazı güncellenirse onun metni otomatik değiştirilmez. Kaynağı tekrar senkronlama ileride ayrı özellik olur; Katman 3 kapsamına alınmaz.

## 5. İçerik / SEO riski

Merkezi tam yazının yüzlerce vitrinde değişmeden yayınlanması ürün hedefiyle uyumlu değildir.

Google güncel canonicalization rehberinde aynı veya çok benzer ana içeriği olan URL'leri duplicate kümesine alabileceğini ve temsilci canonical URL seçebileceğini açıklıyor. Syndicated içerikte, kopyaların arama sonuçlarında görünmesi istenmiyorsa partner kopyalarında indexing'i engellemenin daha etkili olabileceğini ayrıca belirtiyor.

Bu nedenle kilitli plandaki iki güvenli mod korunmalıdır:
1. **Kaynak bağlantılı kısa sürüm**
2. **Vitrine uyarlanmak üzere tam taslak sürüm**

Katman 3 hiçbir modu otomatik yayınlamaz.

İlk BUILD için en küçük güvenli davranış:
- kaynak seçilir
- kullanıcı hangi kopya modunu istediğini seçer
- draft oluşturulur
- doğrudan mevcut editöre açılır
- kullanıcı içeriği görür/değiştirir
- yayınlama mevcut explicit `Yayınla` eyleminde kalır

Tam taslak modunda exact kaynak metninin doğrudan yüzlerce vitrine otomatik yayınlanmasına yeni bir otomasyon eklenmez.

## 6. Alan eşleme araştırması

Güvenli ortak alanlar:
- central `title` → store `title`
- central `summary` → store `summary`
- central `content` → store `content`
- central `cover_image_url` → store `cover_image_url`
- store `status` → daima `draft`
- store `article_type` → `standard`

Otomatik eşlenmemesi gerekenler:
- merkezi `primary_topic` ID'sini körlemesine `target_topic` metnine yazmak
- merkezi konum metadata'sını işletmenin `target_city` alanı sanmak
- merkezi `published_at` tarihini vitrin yayınına taşımak
- merkezi SEO skoru/hatalarını vitrine taşımak

Vitrin SEO alanları mevcut editörde yeniden hesaplanmalıdır.

## 7. Kapak görseli

Merkezi blog kapakları `shelf-images/vixrex-blog/covers/...` altında public, rastgele isimli URL ile tutuluyor. Katman 3'te aynı görsel baytını her vitrin için yeniden yüklemek gereksiz depolama üretir.

En küçük yaklaşım: draft satırına merkezi `cover_image_url` referansını kopyalamak. Esnaf isterse mevcut owner editörü üzerinden kendi kapağını yükleyebilir.

Otomatik dosya çoğaltma Katman 3 kapsamında gerekli görünmüyor.

## 8. UX-FIT

Yeni bağımsız ekran yerine mevcut `Blog Yönetimi` yüzeyi kullanılmalıdır.

Mevcut Next.js ekranında `Yeni Yazı Oluştur` kartı ve yazı listesi vardır. Uygun ekleme noktası aynı ekran içinde ikinci bir CTA'dır:
- `Vixrex Kütüphanesinden Yazı Ekle`

Akış:
`Blog Yönetimi → Kütüphaneden yazı seç → kopya modu → Taslak oluştur → mevcut Yazıyı Düzenle ekranı`

Böylece:
- yeni editör yok
- yeni yayın butonu yok
- owner shell değişmiyor
- esnafın öğrendiği mevcut `Taslak Kaydet / Yayınla` davranışı korunuyor

Flutter eşitliği açısından veri modeli istemciden bağımsız tutulmalıdır. Flutter'a ayrı ikinci backend yazılmamalı; ileride aynı server/RPC eylemi çağrılabilmelidir. Katman 3 LOCK sırasında ilk UI yüzeyinin hangi istemcide açılacağı ayrıca netleştirilmelidir.

UX-FIT sonucu: **UYGUN AMA ŞARTLI** — mevcut Blog Yönetimi ve editör yeniden kullanılmalı; paralel yeni blog yönetim ekranı yapılmamalı.

## 9. Dokunulacak yüzeyler — aday

LOCK onayı sonrası yalnız gerekli minimum yüzeyler:
- yeni migration: `store_articles` kaynak ilişkisi + idempotency
- dar DB RPC: owner-session doğrulamalı published-central → store draft
- server API/adapter: RPC çağrısı
- merkezi kütüphane seçim verisi
- mevcut `Blog Yönetimi` içinde küçük kütüphane CTA/selection yüzeyi
- hedefli testler

## 10. Dokunulmaması gereken yüzeyler

Katman 3'te:
- Vixrex Asistan niyet motoru yok — Katman 4
- 46 vitrin alanı yok
- Keşfet yok
- Kirala/sahiplik oluşturma akışı yok
- public vitrin ana tasarımı yok
- Dijital Çarşı yok — Katman 5
- merkezi blog admin editörü yeniden yazılmaz
- mevcut store article editörü/yayın sistemi yeniden yazılmaz
- merkezi yazı güncellemesi esnaf kopyalarını otomatik overwrite etmez

## 11. Güvenlik / regresyon kapıları

BUILD sonrası teknik VERIFY en az şunları kanıtlamalı:
- geçersiz owner session → import reddedilir
- A vitrininin oturumu → B vitrinine yazamaz
- merkezi draft kaynak → import edilemez
- merkezi published kaynak → yalnız draft store article üretir
- tekrar aynı kaynak → ikinci satır üretmez
- kaynak silinse bile mevcut esnaf draft/kopyası silinmez
- import mevcut `/api/articles` CRUD'ını bozmaz
- esnaf kopyası mevcut editörle değiştirilebilir
- public route draft'ı göstermez
- publish yine yalnız mevcut explicit owner eylemiyle olur
- Flutter mevcut `store_articles` fetch/edit davranışı kaynak alanı eklense de kırılmaz

## 12. Ölçek

Kaynak ilişkisi + partial unique index, 1000+ merkezi yazı ve çok sayıda vitrin için lineer duplicate kontrolü yerine indeksli kontrol sağlar.

Tam merkezi içerik her importta text olarak snapshot kopyalanır; bu bilinçli seçimdir çünkü esnaf kopyası merkezi kaynaktan bağımsız düzenlenebilmelidir. Görsel baytları ise tekrar kopyalanmaz.

Kütüphane seçim ekranı bütün merkezi yazıları tek seferde client'a yüklememeli; Katman 2'nin konu/sektör filtreleri ve sayfalama/bounded query yaklaşımı yeniden kullanılmalıdır.

## 13. Araştırma kararı

**UYGUN AMA ŞARTLI**

BUILD'e geçiş şartları:
1. source relation + duplicate idempotency kilitlenecek
2. DB'nin owner session'ı bağımsız doğruladığı dar import RPC modeli kilitlenecek
3. yalnız published central → draft store kuralı kilitlenecek
4. mevcut Blog Yönetimi/editör yeniden kullanılacak
5. iki kopya modu kilitli plandaki sınırla korunacak
6. Katman 4 Asistan davranışı Katman 3'e taşınmayacak

Kullanıcı bu araştırma + UX-FIT şartlarını onaylamadan BUILD başlamaz.

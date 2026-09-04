# Katman 2 — Merkezi Blog Kütüphanesi Araştırması

Durum: **RESEARCH tamamlandı — sonuç: UYGUN AMA ŞARTLI.**

Bu dosya Katman 2 için yalnız araştırma/uygunluk kararını kilitler. BUILD başlamadı.

## 1. Mevcut gerçeklik

- `vixrex_blog_articles` bugün yalnız temel yazı alanlarını taşıyor: slug, başlık, özet, içerik, kapak görseli, durum, okuma süresi ve tarihler.
- Katman 2 için gereken konu, sektör, yer, kullanım amacı, etiket, kaynak/provenance ve ilgili-yazı ilişkileri henüz merkezi veri modelinde yok.
- Public veri erişim katmanı yalnız temel alanları seçiyor.
- Blog ana sayfası bütün kartları tek tip `Rehber` olarak gösteriyor; kategori/konu filtresi veya arama yok.
- Canlı `store_articles` tablosunda `target_topic` ve `target_city` alanları var, fakat bunlar serbest metin ve mevcut 15 yazının hiçbirinde dolu değil. Bu nedenle merkezi kütüphanenin kanonik taksonomisi olarak yeniden kullanılamaz.

## 2. Vixrex sektör kaynağı — doğrulandı

- Yeni işletme kategori listesi üretmek yasak.
- `shared/business_categories.json` tek kanonik kaynaktır.
- Kaynakta **19 kategori** vardır.
- Katman 2 sektör eşleşmesi bu mevcut `id` değerlerini kullanmalıdır.
- Merkezi blog için ikinci bir sektör sözlüğü/DB kopyası oluşturulmamalı; aksi halde `tek veri` ilkesi bozulur.

## 3. Yer/konum kaynağı — düzeltildi ve doğrulandı

İlk taramada yalnız ilçe alanları görünmüştü; daha derin doğrulamada mevcut Vixrex konum omurgasının daha geniş olduğu görüldü:

- `stores.province_code`
- `stores.province_name`
- `stores.district_code`
- `stores.district_name`
- `stores.neighborhood_name`
- `stores.latitude` / `longitude`

Flutter tarafında `lib/config/turkey_cities_config.dart` **81 ili** ve illere bağlı ilçe listelerini taşıyor. `StoreLocationFetchService` bu kaynağı kullanıyor.

Sonuç:
- Katman 2 için yeni şehir veritabanı icat edilmeyecek.
- İl eşleşmesinde mevcut `province_code` kullanılacak.
- İlçe, mevcut Vixrex ilçe adı kaynağıyla birlikte il koduna bağlı ele alınacak.
- Merkezi makale konum hedefleri, mağazanın mevcut konum alanlarıyla doğrudan eşleşebilecek.

Not: mevcut konum servisindeki `districtCode` davranışı ayrı bir mevcut kod konusu olabilir; Katman 2 bu servisi değiştirmeyecek.

## 4. Store blog modeliyle ilişki — doğrulandı

`store_articles` şu alanlara zaten sahip:
- `article_type`
- `target_topic`
- `target_city`
- `seo_score`
- `seo_errors`
- `cover_image_url`
- taslak/yayın durumu

Ancak:
- `target_topic` ve `target_city` serbest metin,
- canlı mevcut yazılarda kullanılmıyor,
- owner API bu alanları doğrudan metin olarak kabul ediyor.

Bu nedenle Katman 2 merkezi kütüphanede kontrollü metadata kurmalı; Katman 3'te vitrine taslak çekilirken gerekiyorsa mevcut `store_articles` alanlarına insan-okur değerleri dönüştürülmeli. Merkezi taksonominin kendisi `store_articles` içine taşınmamalı.

## 5. Görsel kalite ve yükleme hattı — doğrulandı

Vixrex'in mevcut görsel hattı ortak ve güvenlik kontrollü:
- en fazla 5 MB giriş
- JPG / PNG / WebP bayt doğrulaması
- uzun kenar en fazla **1600 px**
- kalite **82**
- 1 MB üzeri dosyada yedek sıkıştırma
- küçük görseller büyütülmüyor
- EXIF taşınmıyor
- Flutter ve web aynı sıkıştırma parametrelerini kullanıyor
- `shelf-images` depolaması ve uzun cache süresi kullanılıyor

Katman 2 için ayrı görsel algoritması oluşturmak uygun değil.

Şart:
- Merkezi Vixrex blog kapak yükleme yolu owner-upload endpoint'ini doğrudan kullanamaz; o endpoint vitrin owner-session ve 46-alan şemasına bağlı.
- Merkezi blog için admin/servis yetkili ayrı dar yükleme ucu gerekir, fakat sıkıştırma çekirdeği `gorselSikistir.ts` yeniden kullanılmalıdır.

## 6. SEO / bilgi mimarisi — güncel resmi kaynaklarla doğrulandı

Google Search Central / Crawling Infrastructure güncel rehberleri:
- İç bağlantılar sayfaların keşfedilmesine ve bağlamın anlaşılmasına yardım eder.
- URL-parametreli çok sayıda filtre kombinasyonu gereksiz ve hatta çok büyük tarama alanı üretebilir.
- Filtre sonuçlarının tamamını ayrı indekslenebilir URL yapmak yerine anlamlı sabit kategori/konu sayfaları tercih edilmelidir.
- `BlogPosting`/`Article` yapılandırılmış verisi makalenin başlık, görsel ve tarih bağlamını Google'a daha açık anlatabilir; görünürlük garantisi değildir.
- Görsellerde standart HTML image elemanı, anlamlı alt metni, responsive sunum ve sayfayı gerçekten temsil eden yüksek kaliteli ama optimize edilmiş görsel önerilir.

Katman 2 sonucu:
- `/blog/konu/[slug]` ve gerektiğinde `/blog/sektor/[id]` gibi kontrollü, anlamlı route'lar uygundur.
- `?konu=x&sektor=y&sehir=z&...` kombinasyonlarının her biri SEO sayfası yapılmayacak.
- Filtre UX'i gerekirse kullanıcı tarafında kalabilir; indekslenebilir yüzey kontrollü tutulmalıdır.

## 7. UX-FIT araştırması

Mevcut Vixrex yüzeyleri iki farklı bağlamı zaten ayırıyor:
- Public Vixrex blogu: açık renk `lp-*` platform dili, 1200px katalog, dar makale okuma yüzeyi.
- Esnaf blog yönetimi: `owner-*` sahiplik dili, yazı listesi + düzenleyici.

Katman 2 merkezi kütüphane public Vixrex blogunun `lp-*` dilinde kalmalı. Owner sayfası görünümünü merkezi bloga taşımak uygun değil.

En küçük UX genişlemesi:
- Blog ana sayfasında öne çıkan içerik
- konu blokları
- sektör filtresi/seçimi
- son yazılar
- kapak görseli olan kartlar
- mobilde tek akış, masaüstünde geniş katalog

Yeni ayrı uygulama hissi, yeni global navigation veya Keşfet/owner shell değişikliği gerekmiyor.

## 8. Bilgi mimarisi — önerilen kontrollü model

### 8.1 Sektör

Kesin sayı: **19** mevcut Vixrex kategorisi.

### 8.2 Konu

Yeni konu listesi ayrı bir kod içi sabit olarak dağılmamalı. Katman 2 BUILD onayı gelirse `shared/` altında tek bir blog taksonomi kaynağı oluşturulması en güvenli yaklaşım.

Mevcut Vixrex kullanıcı akışlarından çıkan **7 aday ana konu ailesi**:
1. Google ve yerel görünürlük
2. Dijital vitrin ve web görünümü
3. Ürün, hizmet ve fiyat/katalog
4. Müşteri iletişimi, paylaşım ve satış
5. Randevu ve işletme yönetimi
6. Vixrex kullanımı ve yayınlama
7. Dijital Çarşı ve işletme bağlantıları — geleceğe açık, Katman 5 davranışını burada başlatmaz

Bu 7 başlık BUILD öncesi kullanıcı onayına sunulur; onaydan önce kanonik sayılmaz.

### 8.3 Kullanım amacı

Konu ile amaç aynı şey olmamalı. Örneğin `Google görünürlük` konu iken amaç `müşteri bulma` olabilir.

Öneri: sınırlı ve makine-okur amaç sözlüğü. Kesin değerler BUILD öncesi LOCK'ta dondurulacak.

### 8.4 Etiketler

Etiketler yardımcı arama sinyali olmalı; ana kategori yerine geçmemeli.
- normalize edilmiş kısa slug/metin
- tekrar yok
- sınırsız kullanıcı üretimi yok
- makale başına üst sınır konmalı

### 8.5 Konum

Üç seviye yeterli:
- Türkiye geneli
- il
- il + ilçe

Mevcut `province_code` + ilçe adı kullanılacak. Yeni şehir sözlüğü yok.

### 8.6 İlgili yazılar

`related_slugs` gibi gevşek metin dizisi yerine ayrı ilişki tablosu daha güvenli:
- gerçek article ID referansı
- silmede referans bütünlüğü
- ilişki türü eklenebilir
- daha sonra Dijital Çarşı bağlantı omurgasına karışmadan genişleyebilir

## 9. Önerilen veri yaklaşımı — henüz BUILD değil

Mevcut `vixrex_blog_articles` tablosu korunur ve yalnız kütüphane metadata'sı eklenir. Yeni ikinci makale tablosu açılmaz.

Aday alanlar:
- `primary_topic`
- `purpose`
- `sector_ids text[]`
- `province_codes text[]`
- ilçe hedefleri için il koduyla birlikte yapılandırılmış değer
- `tags text[]`
- `provenance` / kaynak bilgisi

İlgili yazılar ayrı ilişki tablosunda tutulur.

Taksonominin konu/amaç sözlükleri `shared/` tek kaynaktan okunur; sektörler mevcut `shared/business_categories.json` kaynağından gelir.

## 10. SECURITY/RISK sonucu

### Güvenli
- Merkezi tablo ayrı kalıyor.
- `store_articles` RLS/owner-session davranışı Katman 2'de değişmek zorunda değil.
- Public sorgu yalnız `published` filtresini koruyabilir.
- Metadata public içerikte okunabilir ama taslaklar yine RLS altında kalır.

### Riskler ve şartlar
1. Serbest metin konu/sektör kullanılırsa Asistan eşleşmesi zamanla bozulur → kontrollü ID/slug gerekli.
2. Business category DB kopyası açılırsa iki kaynak oluşur → yasak.
3. Owner-upload merkezi blog için yeniden kullanılırsa yetki modeli karışır → ayrı admin yükleme yolu gerekli.
4. Her filtre kombinasyonu URL olursa tarama alanı şişer → yalnız kontrollü landing route'ları indekslenebilir olmalı.
5. İlişkili yazılar metin slug dizisi olursa referans bütünlüğü zayıf olur → ilişki tablosu tercih edilmeli.
6. Katman 2, `store_articles`, owner blog editörü, Asistan veya Kirala akışını değiştirmemeli.

## 11. LOOK sonucu

Doğrudan doğrulanan yüzeyler:
- `vixrex_blog_articles` canlı şeması
- canlı `store_articles` şeması ve RLS policy'leri
- `/api/articles`
- owner blog liste/düzenleme ekranları
- public `/blog` katalog yüzeyi
- `shared/business_categories.json`
- Vixrex il/ilçe kaynağı ve store konum alanları
- owner görsel yükleme + ortak sıkıştırma çekirdeği

Varsayıma dayalı kritik nokta bırakılmadı; konu/amaç isimleri ise özellikle **aday** olarak bırakıldı.

## 12. Katman 2 kararı

**UYGUN AMA ŞARTLI.**

BUILD için önerilen LOCK şartları:
1. Sektör: mevcut 19 kategori ID'si, yeni sözlük yok.
2. Konu + amaç: tek shared taksonomi kaynağı; kullanıcı onayından sonra kilitlenecek.
3. Konum: mevcut 81 il / ilçe kaynağı; yeni şehir verisi yok.
4. Merkezi tablo genişletilecek; ikinci merkezi makale tablosu yok.
5. İlgili yazılar ayrı relation tablosu.
6. Public blog `lp-*` UX dilinde kalacak; owner/Keşfet/global shell değişmeyecek.
7. Görseller mevcut 1600/82 sıkıştırma çekirdeğini kullanacak; merkezi admin yükleme yetkisi owner-upload'tan ayrılacak.
8. Taslak/public RLS davranışı değişmeyecek.
9. Katman 3 vitrine yazı çekme ve Katman 4 Asistan davranışı bu BUILD'e sokulmayacak.

Bu şartlar onaylanmadan Katman 2 BUILD başlamaz.

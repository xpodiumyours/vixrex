# Vitrin Alan Şeması

> Sahibin düzenleyebileceği her vitrin alanının tek kaynağı.
> `implementation_plan.md` Commit 8'in önkoşuludur.

## 1. Neden bu dosya var

Commit 8 "beş alanı tipli ve izin listeli hale getir" diyor. O beş alan tek tek elle yazılırsa, Commit 10'daki kırk alan için aynı iş sekiz kez tekrarlanır ve orada tıkanılır.

Şema yazıldığında **alan eklemek kod yazmak değil, satır eklemek** olur:

- Komut işleyicisi şemadan okur → her alan için ayrı dallanma yok
- Sunucu doğrulaması şemadan okur → her alan için ayrı doğrulayıcı yok
- Tıkla-düzenle listesi şemadan üretilir → her alan için ayrı işaretleme yok

Beş alan bu şemanın beş satırıdır. Kırk alan kırk satır.

## 2. Kaynak: HTML'in çizdiği, asistanının yapabildiği değil

Alan listesi `teknik_vitrin_asistan.html` içindeki `MASTER_CONFIG`'den çıkarıldı — yani **vitrinin ekrana çizdiği her alandan**.

Dikkat: o dosyadaki asistan bu alanların ancak onda birine dokunabiliyor. Tıkla-düzenle işareti yalnız hero başlığı, rozet, tanıtım, telefon, e-posta, adres ve saatlere konmuş. Hakkımızda, SSS, galeri, blog bölümleri tıklanamıyor.

**Hedef HTML'in asistanı değil, HTML'in görünüşüdür.** Görünüş web sitesi kalitesinde olacak; düzenleme tarafında HTML'i aşacağız — çizilen her alan düzenlenebilir olacak.

Alanların veritabanı karşılıkları `stores` tablosundan, müşteriye gerçekten gidenler `public_web/src/app/v/[slug]/page.tsx` içindeki `PUBLIC_STORE_SELECT`'ten doğrulandı.

## 3. İki kapı, tek yer — düzenleme nerede yapılır

Bu karar 2026-08-04'te verildi ve **belirsiz bırakılmayacak kadar önemlidir.** Flutter/Next.js vitrin tekrarı aylar yediği için aynı hata düzenleme tarafında tekrarlanmamalıdır.

**Sahip düzenlemesi Next.js sahip panelinde yapılır.** Aynı şemaya bakan iki kapı vardır:

| Kapı | Nasıl | Ne zaman |
|---|---|---|
| **Form** | Vitrindeki alana tıklanır, kutu açılır, yazılır | Kullanıcı ne değiştireceğini biliyor |
| **Asistan** | Sohbete yazılır, asistan aynı alanı günceller | Kullanıcı yönlendirilmek istiyor |

İkisi de aynı şemadan beslenir, aynı doğrulamadan geçer, aynı çalışma taslağına yazar. **Aynı alan için iki farklı kayıt yolu yoktur.**

**Flutter'daki manuel üyelik paneli yerinde kalır.** Taşınmaz, silinmez. Rolü: arka plan / yedek yol. Sebebi:

- İnternet veya sahip oturumu olmadan da veri düzenlenebilsin
- Next.js paneli erişilemezse iş durmasın
- Toplu yükleme, OCR ve Excel akışları Flutter'da olduğu gibi kalsın

Flutter bu paneli **veriyi düzenlemek ve Supabase'e yazmak** için kullanır; vitrini çizmez. Değişmez kural korunur: müşterinin ve sahibin gördüğü vitrin yalnız Next.js'te render edilir.

---

## 4. Şema satırının biçimi

| Bilgi | Açıklama |
|---|---|
| `anahtar` | Komutlarda kullanılan sabit ad. Yayına çıktıktan sonra değişmez. |
| `tip` | `metin` \| `uzunMetin` \| `sayı` \| `telefon` \| `eposta` \| `url` \| `görsel` \| `seçim` \| `açıkKapalı` |
| `etiket` | Kullanıcıya gösterilen Türkçe ad. Asistan bunu konuşur, form bunu yazar. |
| `kolon` | `stores` tablosundaki hedef. |
| `doğrulama` | Sunucu tarafında uygulanan sınır. |
| `bölüm` | Vitrindeki hangi bölüm — tıkla-düzenle odaklaması ve bölüm gizleme için. |

---

## 5. Skaler alanlar

Tek değer taşırlar. Komut tipi: **"şu alanı şu değere ayarla"**.

### 5.1 Hero / işletme kimliği — bölüm: `hero`

| anahtar | tip | etiket | kolon | doğrulama |
|---|---|---|---|---|
| `isletmeAdi` | metin | İşletme Adı | `name` | zorunlu, 2–60 |
| `heroRozet` | metin | Hero Rozet Metni | `hero_badge` | 0–60 |
| `kisaTanitim` | uzunMetin | Kısa Tanıtım | `description` | 0–300 |
| `konumMetni` | metin | Hero Konum Metni | `hero_location_text` | 0–60 |
| `kategori` | seçim | İşletme Kategorisi | `kategori` | `business_category_config.dart` listesinden |
| `isletmeTuru` | metin | İşletme Türü | `business_type` | 0–40 |
| `logo` | görsel | Logo | `logo_url` | güvenli URL, kendi depomuz |
| `kapakGorseli` | görsel | Kapak / Hero Görseli | `shelf_image_url` | güvenli URL, kendi depomuz |
| `tema` | seçim | Tema Ön Ayarı | `theme_preset` | tanımlı ön ayar listesinden |

### 5.2 İletişim — bölüm: `contact`

| anahtar | tip | etiket | kolon | doğrulama |
|---|---|---|---|---|
| `whatsapp` | telefon | WhatsApp Numarası | `whatsapp` | yalnız rakam, 10–13 hane |
| `telefon` | telefon | Telefon | `phone` | yalnız rakam, 10–13 hane |
| `eposta` | eposta | E-posta | `email` | geçerli e-posta |
| `adres` | uzunMetin | Açık Adres | `address` | 0–200 |
| `haritaEtiketi` | metin | Harita Kartı Etiketi | `map_label` | 0–120 |
| `calismaSaatleri` | metin | Çalışma Saatleri | `working_hours` | serbest metin veya haftalık yapı |
| `instagram` | metin | Instagram Kullanıcı Adı | `instagram` | `@` olmadan, 0–30 |
| `website` | url | Web Sitesi | `website` | `http`/`https` |
| `haritaLinki` | url | Google İşletme / Harita | `google_business_link` | `http`/`https` |
| `enlem` | sayı | Konum — Enlem | `latitude` | -90 … 90 |
| `boylam` | sayı | Konum — Boylam | `longitude` | -180 … 180 |

### 5.3 Katalog başlıkları — bölüm: `categories` / `products`

| anahtar | tip | etiket | kolon | doğrulama |
|---|---|---|---|---|
| `kategoriBolumBaslik` | metin | Kategori Bölümü Başlığı | `category_section_title` | 0–60 |
| `urunBolumBaslik` | metin | Ürün Bölümü Başlığı | `product_section_title` | 0–60 |

### 5.4 Öne çıkan kampanya bandı — bölüm: `featured`

| anahtar | tip | etiket | kolon | doğrulama |
|---|---|---|---|---|
| `bantEtiket` | metin | Kampanya Etiketi | `featured_banner_label` | 0–40 |
| `bantBaslik` | metin | Kampanya Başlığı | `featured_banner_title` | 0–90 |
| `bantAciklama` | uzunMetin | Kampanya Açıklaması | `featured_banner_description` | 0–200 |
| `bantGorsel` | görsel | Kampanya Görseli | `featured_banner_image_url` | güvenli URL |
| `bantFiyat` | metin | Kampanya Fiyat Metni | `featured_banner_price_text` | 0–30 |

### 5.5 Hakkımızda — bölüm: `about`

| anahtar | tip | etiket | kolon | doğrulama |
|---|---|---|---|---|
| `hakkindaUstBaslik` | metin | Hakkımızda Üst Başlık | `about_kicker` | 0–40 |
| `hakkindaBaslik` | metin | Hakkımızda Başlığı | `about_title` | 0–90 |
| `hakkindaMetin` | uzunMetin | Hakkımızda Yazısı | `corporate_bio` | 0–1200 |
| `hakkindaGorsel` | görsel | Hakkımızda Görseli | `about_image_url` | güvenli URL |
| `hakkindaGorselAlt` | metin | Görsel Alt Yazısı | `about_image_caption` | 0–120 |

### 5.6 Galeri başlıkları — bölüm: `gallery`

| anahtar | tip | etiket | kolon | doğrulama |
|---|---|---|---|---|
| `galeriUstBaslik` | metin | Galeri Üst Başlık | `gallery_section_kicker` | 0–40 |
| `galeriBaslik` | metin | Galeri Başlığı | `gallery_section_title` | 0–90 |
| `galeriAksiyonMetni` | metin | Galeri Buton Metni | `gallery_action_label` | 0–40 |
| `galeriAksiyonLinki` | url | Galeri Buton Bağlantısı | `gallery_action_href` | `http`/`https` veya `#bölüm` |

### 5.7 Blog başlıkları — bölüm: `blog`

| anahtar | tip | etiket | kolon | doğrulama |
|---|---|---|---|---|
| `blogUstBaslik` | metin | Blog Üst Başlık | `blog_section_kicker` | 0–40 |
| `blogBaslik` | metin | Blog Bölüm Başlığı | `blog_section_title` | 0–90 |

### 5.8 SSS başlıkları — bölüm: `faq`

| anahtar | tip | etiket | kolon | doğrulama |
|---|---|---|---|---|
| `sssUstBaslik` | metin | SSS Üst Başlık | `faq_section_kicker` | 0–40 |
| `sssBaslik` | metin | SSS Bölüm Başlığı | `faq_section_title` | 0–90 |
| `sssAciklama` | uzunMetin | SSS Bölüm Açıklaması | `faq_section_description` | 0–200 |

### 5.9 Görünürlük

| anahtar | tip | etiket | kolon | doğrulama |
|---|---|---|---|---|
| `puanGoster` | açıkKapalı | Değerlendirme Puanını Göster | `show_storefront_rating` | — |
| `yolTarifiGoster` | açıkKapalı | Yol Tarifi Butonunu Göster | `show_directions_link` | — |
| `referansLinki` | url | Referanslar Bağlantısı | `references_link` | `http`/`https` |
| `bolumGorunurluk` | *(yapı)* | Bölüm Açık/Kapalı | `section_visibility` | sekiz bölüm için açık/kapalı |

---

## 6. Koleksiyonlar

Birden çok kayıt taşırlar. Skalerlerden **farklı komutlar** gerektirirler: `ekle`, `düzenle`, `sil`, `sırala`.

Öğe alanları `teknik_vitrin_asistan.html`'den birebir çıkarıldı.

| anahtar | etiket | kolon | öğe alanları |
|---|---|---|---|
| `urunler` | Ürünler / Hizmetler | `products` | ad, kategori, fiyat, eskiFiyat, indirimli, etiket, görsel, açıklama, stokDurumu, teslimBölgesi |
| `urunKategorileri` | Ürün Kategorileri | `product_categories` | ad, sayaçMetni, görsel |
| `galeriOgeleri` | Galeri Kareleri | `gallery_items` | başlık, görsel, altMetin |
| `sikSorulanlar` | Sık Sorulan Sorular | `faq_items` | soru, cevap |
| `degerKartlari` | Hakkımızda Değer Kartları | `about_values` | başlık, açıklama |
| `pazaryeriLinkleri` | Pazaryeri Bağlantıları | `marketplace_links` | platform, url, altBaşlık |
| `yazilar` | Blog Yazıları | `store_articles` *(ayrı tablo)* | üstBilgi, başlık, özet, görsel, altMetin, içerik |

**Açık soru:** `urunler` bugün hem `products` JSONB kolonunda hem ayrı bir `products` tablosunda tutulabiliyor; `product_storage_version` hangisinin geçerli olduğunu belirtiyor. Ürün komutları yazılmadan önce tek kaynak netleştirilmelidir.

---

## 7. Sahibin düzenleyemeyeceği alanlar

Şemaya girmez; izin listesi bunları reddeder.

| kolon | sebep |
|---|---|
| `id`, `slug` | kimlik; slug yayınlama akışında üretilir |
| `edit_token` | gizli anahtar, istemciye hiç gitmez |
| `user_id` | sahiplik |
| `is_published`, `status`, `published_at` | yalnız yayınlama akışı değiştirir |
| `is_demo` | kiralık şablon koruması |
| `is_premium`, `premium_plan`, `premium_expires_at` | ödeme sistemi belirler |
| `version` | sürüm çakışması tetikleyicisi yazar |
| `rating_score`, `review_count` | **uydurma değer yazılmaz** — gerçek değerlendirme kaynağı bağlanana kadar sahibe kapalı |
| `privacy_notice_*`, `terms_*`, `publication_consent_*` | yasal kabul kayıtları |
| `created_at`, `updated_at` | sistem |
| `location_source`, `location_accuracy_meters`, `location_consent_at` | konum servisi yazar |
| `is_blog_trusted` | moderasyon kararı |

---

## 8. Bölüm başlıkları — sabitten sahibe

### Sorun neydi

Bölüm başlıkları `public_web/src/lib/vitrinCopy.ts` içinde **kategoriye göre sabit** yazılıydı. Her kuaför vitrini aynı "Hakkımızda" başlığını, her kafe aynı tanıtım cümlesini gösteriyordu. Sahip bunları değiştiremiyordu.

Bu, vitrinin boş görünmesine değil, **hepsinin aynı görünmesine** yol açar. Gerçek bir web sitesinde sahibi başlığı kendi yazar: "Hakkımızda" yerine "Kadıköy'ün 12 yıllık teknik servisi" yazabilir. Yüz vitrin aynı başlıklarla dizilirse şablon oldukları anlaşılır — farkı yok eden şey budur.

Ayrıca bölümler yalnız verisi boşsa gizleniyordu. Sahibin "ben blog istemiyorum" deme hakkı yoktu.

### Ne yapıldı

`supabase/migrations/20260804220000_add_owner_editable_section_labels.sql` ile 12 kolon eklendi. Hepsi NULL olabilir. Kolon adları yukarıdaki tablolarda yazılı.

### Varsayılan kuralı — en önemli kısım

**`vitrinCopy.ts` kaldırılmaz. Varsayılan olur.**

| Durum | Ne gösterilir |
|---|---|
| Kolon NULL | Kategorinin hazır metni (`vitrinCopy.ts`) |
| Sahip bir değer yazmış | Sahibin yazdığı |

Böylece yayındaki mevcut vitrinler hiç etkilenmez, yeni açılan vitrin boş başlıklarla görünmez, isteyen sahip kendi cümlesini yazar.

Bu kural Commit 10'da render tarafına uygulanır. Uygulanırken `vitrinCopy.ts` silinmez; yalnız "önce kolona bak, boşsa buraya düş" sırası kurulur.

### `section_visibility` nasıl çalışır

JSONB, varsayılanı boş nesne. Boş = bugünkü davranış (bölüm yalnız verisi boşsa gizlenir). Anahtar yazılmışsa **sahibin kararı üstün gelir.**

Anahtarlar: `categories`, `products`, `about`, `gallery`, `blog`, `faq`, `contact`

Örnek: `{"blog": false}` → blog yazısı olsa bile bölüm gösterilmez.

### Kalan iş

Bu kolonların müşteri yanıtına girmesi için `public_web/src/app/v/[slug]/page.tsx` içindeki `PUBLIC_STORE_SELECT` listesine eklenmeleri gerekir. Commit 10 kapsamındadır; migration tek başına görünürlük sağlamaz.

---

## 9. Uygulama sırası

1. Bu şemayı koda dök — tek dosya, her alan bir satır. Henüz komut yazma.
2. Commit 8'in beş alanını bu şemadan üret. Beş ayrı dallanma yazma.
3. §8'deki eksik alanlar için tek migration.
4. Commit 10'da bölüm bölüm ilerle — her bölüm satır eklemek olsun.

## 10. Değiştirme kuralı

Bu dosya alan sözleşmesidir. Bir alanın `anahtar` değeri yayına çıktıktan sonra değiştirilmez — asistan komutları ve kayıtlı taslaklar ona bağlıdır. Yeni alan eklenir, eski anahtar silinmez.

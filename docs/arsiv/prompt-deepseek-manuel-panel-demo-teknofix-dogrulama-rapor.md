# Rapor — manuel panel demo-teknofix içeriğini gerçekten üretebiliyor mu

- **Görev:** `docs/prompt-deepseek-manuel-panel-demo-teknofix-dogrulama.md`
- **Tarih / bağlam:** doğrulama 2026-08-09; yerel `main` başlangıçta 2 commit gerideydi
  (`baacdb1` #72, `8098579` #74), `git pull --ff-only` ile güncellendi. Aşağıdaki
  tüm satırlar **güncel kod** içindir (HEAD = `8098579`).
- **Kapsam dışı:** Next.js Asistan paneli, SQL/migration yolları sayılmadı.
- **Önemli bağlam:** demo içeriği panel ile değil, migration ile yazıldı
  (`supabase/migrations/20260809120000_demo_teknofix_icerik_doldur.sql`, 195 satır).
  Aşağıdaki her madde "esnaf bu alanı yalnız panelden **girip kaydedip yayınlayabilir** mi?"
  sorusunu yanıtlar.
- Kanıt zinciri kısaltmaları: Panel UI → model → `store_publish_payload_builder.dart`
  (paylaşım) → `stores` RPC → Next.js `PUBLIC_STORE_SELECT` (`page.tsx:141-152`) → render.

## Kontrol listesi sonuçları

### 1. Hero — ✅
İşletme adı, rozet, kısa açıklama, telefon/WhatsApp/e-posta, çalışma saatleri, kapak görseli:
hepsinin panel girişi var ve yayında render ediliyor.
- İsim/rozet/açıklama: vitrin formu Temel Bilgiler bölümü
  (`lib/widgets/editor/form_business_info.dart:43-47`); payload
  (`lib/services/store_publish_payload_builder.dart` 35-100).
- Konum metni: `lib/widgets/editor/location_editor_section.dart` (hero konum metni),
  bağlantı `lib/widgets/editor/form_location_info.dart:50-52`; yayında
  `public_web/src/app/v/[slug]/VitrinProfileView.tsx:457` (📍 heroLocationText).
- Kapak: `lib/widgets/editor/cover_picker_section.dart` → `setCoverUrl`
  (`lib/controllers/store_editor_controller.dart:312-318`) → `shelf_image_url`
  (payload :80) → hero görseli (`VitrinProfileView.tsx` heroImage; `page.tsx:433-434`).
- Çalışma saatleri: form saat editörü → `working_hours` → `page.tsx:512-521`.
- **Not (sınır dışı alan):** logo panelden yüklenemiyor (`logo_url` yalnız
  `lib/services/auto_fill_service.dart:194-196` ile yazılıyor), ama hero görseli
  `shelf_image_url`'dan geldiği için vitrin görünümü kapakla eksiksiz kurulabiliyor.

### 2. 4 kategori: isim + görsel — ❌ görsel (isim ✅)
- İsim: `lib/widgets/product/product_category_management_screen.dart:41-48` (yalnız
  id/name/sortOrder). **Hâlâ doğru:** görsel alanı yok; model ve
  `product_categories` tablosunda görsel kolonu yok
  (`supabase/migrations_arsiv/202607200002_add_product_tables.sql`).
- Vitrin yansıması dolaylıdır: kategori kartı görseli, o kategorideki **ilk ürünün
  görselinden** türer (`page.tsx:485-491`, `ProductCatalog.tsx`). Yani esnaf kategorilere
  görsel yükleyemez; ürün görseli ekleyince kart görseli otomatik oluşur.

### 3. 8 ürün/hizmet — ✅ (süre/garanti tek serbest metin alanında ⚠️)
- İsim, fiyat metni, fiyat tutarı/para birimi, **eski fiyat**, rozet, açıklama, kategori
  ataması, **4 görsel yükleme**, stok durumu, görünürlük:
  `lib/widgets/product/product_editor_sheet.dart` (teslim bölgesi :288) →
  `lib/repositories/supabase_product_repository.dart` (`p_fulfillment_region` :100) →
  `products` tablosu → `page.tsx:178-187` seçimi → render.
- Demo'daki "2 iş günü, 6 ay garanti" satırı `fulfillment_region` serbest metnine
  giriliyor ve `ProductCatalog.tsx:218-220`'de gösteriliyor — **yapısal "süre/garanti"
  alanı yok**, metin olarak taşınıyor (⚠️).
- Sınırlamalar: ürün kaydı için mağaza modu gerekir ve **önce yayın şartı** var
  ("Ürünleri kaydetmek için önce vitrini yayınlayın", `store_editor_controller.dart:779-784`).

### 4. Kampanya bandı — ✅ (görsel URL metin alanı ⚠️)
- Etiket, başlık, açıklama, fiyat metni: `lib/widgets/editor/featured_campaign_sheet.dart`
  (başlık :17-18, :46-47); payload featured_banner_*; render `page.tsx:449-459`.
- **Not:** görsel yalnız "Görsel bağlantısı" URL metin alanı (`featured_campaign_sheet.dart:121`)
  — yükleme butonu yok (⚠️). Demo kampanya görseli migration ile URL olarak girildi.

### 5. Hakkımızda — ✅ (görsel URL metin alanı ⚠️)
- Üst başlık, başlık, paragraf, görsel + alt yazı, **3 değer kartı** (başlık+açıklama):
  `lib/widgets/editor/about_editor_sheet.dart` (kicker :16, başlık :17, body :18,
  değer kartları :34-46; kayıt :81-86; görsel :153 URL, alt yazı :161).
- Payload: about_values ≤3; render `page.tsx:405-412`.
- **Not:** görsel yalnız URL metin alanı (⚠️).

### 6. Galeri — ✅
- Üst başlık, başlık, **buton metni + buton linki**: `gallery_editor_section.dart:35-48,134-143`
  → controller (`store_editor_controller.dart:421-426`) → payload `gallery_action_label/href`
  (:51-52) → render `VitrinProfileView.tsx:702-707`.
- 5 görsel + etiketler: çoklu **yükleme** + görsel başına etiket
  (`gallery_editor_section.dart:124`, `form_media_picker.dart:20`); yayında
  etiketler `VitrinProfileView.tsx:689-693`.

### 7. Blog — ⚠️ (yazı ekleme ✅, bölüm başlıkları ✅, yazı listesi/düzenleme ❌)
- Bölüm üst başlığı + başlığı: vitrin formu blog giriş kartı alanları → payload
  blog_section_kicker/title → render `VitrinProfileView.tsx:741-748`.
- Yazı ekleme: `BlogEditorScreen` — başlık, özet, tam içerik, **kapak görseli
  yükleme**, konu, şehir, tür; `article_service.dart` kayıt (draft/published);
  `store_articles` tablosu (unique store_slug+slug); yayında `page.tsx:163-170`
  (published, son 3) ve `yazilar/` listesi. **Sınır yok** (her yazı ayrı kayıt).
- Sınırlamalar: yazı kaydetmek için önce yayınlanmış vitrin şartı
  (`vitrin_form_section.dart:1401-1411`).
- **❌ Eksik:** panelde mevcut yazıları **listeleme/düzenleme** UI'ı yok
  (`navigateToBlogEditor` yalnız `vitrin_form_section.dart:1410`'dan, tek yazı
  state'i ile çağrılıyor). Demo'daki 3 yazı migration ile yazıldı; panelden eşdeğer
  3 yazı **sıfırdan** eklenebilir ama sonradan düzenlenemez.

### 8. SSS — ✅ (20 adet ile sınırlı)
- Üst başlık, başlık, açıklama: `faq_editor_sheet.dart:121-139`.
- Soru-cevap ekleme/çıkarma: `faq_editor_sheet.dart:151-185` ("Soru ekle" :185).
- Kayıt: payload faq_items — **en fazla 20** (store_publish_payload_builder take(20)).
- Render: `page.tsx:387-395`, `VitrinProfileView.tsx:773-780`.

### 9. İletişim — ⚠️ (Referanslar Bağlantısı ❌)
- Açık adres, il/ilçe, GPS: `location_editor_section.dart` / `form_location_info.dart:26-88`.
- Harita kartı etiketi: `form_location_info.dart:53-54` (map_label) → render
  `VitrinProfileView.tsx:823`.
- Google İşletme/Harita Bağlantısı: `my_vitrin_screen.dart:56,261` ("Google İşletme"
  alanı) → payload `google_business_link` (:89) → render :635.
- Yol tarifi aç/kapa: `show_directions_link` toggle; puan bandı aç/kapa:
  `show_storefront_rating` toggle → render `page.tsx:424-425`, `VitrinProfileView.tsx:630`.
- **❌ Referanslar Bağlantısı:** hâlâ UI yok — yalnız model
  (`store_data.dart:79`), payload (:78) ve render (`page.tsx:470`) var;
  `lib/widgets` içinde giriş alanı yok.

### 10. İşletme Türü — ⚠️ (elle girilemiyor, kategori seçiminden otomatik)
- Kesin doğrulama: `store_editor_controller.dart:329-336` — kategori seçilince
  `_data.businessType = config.label` yazılıyor; elle değiştirme alanı yok.
- Etkisi: esnaf "Teknik Servis" kategorisini seçerse istenen business_type
  otomatik gelir (`vitrinProfile.ts:34`), bu yüzden demo için pratik sonuç elde
  edilebilir ama alan bağımsız bir giriş değil.

### 11. Bölüm görünürlüğü (section_visibility, 7 anahtar) — ✅
- Panel: `lib/widgets/editor/section_visibility_card.dart:15-25` — 7 anahtar:
  categories, products, about, gallery, blog, faq, contact.
- Kayıt: payload `section_visibility`; seçim: `page.tsx` PUBLIC_STORE_SELECT
  (section_visibility dahil, :152).
- Render: `VitrinProfileView.tsx:227-244` `bolumGorunur(...)` — aynı 7 anahtar,
  `false` ise bölüm gizlenir (about :251, gallery :263, faq :273, blog :278,
  contact :284, categories/products :297-298); test:
  `public_web/tests/bolum-gorunurluk-behavior.test.ts`.
- Uyarı: bu zincir **#74 ile yayına girmiştir**; bundan önceki deploy'larda
  section_visibility hiç okunmuyordu. Güncel canlı (vixrex-public) bu kodu içeriyor.

## Özet

Panel bu içeriğin **7/11 parçasını eksiksiz (1, 3, 4, 5, 6, 8, 11)**, **4/11
parçasını kısmen (2, 7, 9, 10)** gerçekten üretebiliyor.

Eksik/koşullu parçalar (tümü, kırpılmadan):
1. **Kategori görseli** — panelde görsel alanı/tablo kolonu yok; yalnız ilk ürün
   görselinden dolaylı türetme (`page.tsx:485-491`).
2. **Blog yazı yönetimi** — yazı ekleme var, mevcut yazı listesi/düzenleme UI'ı yok
   (`app_router.dart:294` çağrı yolu tek: `vitrin_form_section.dart:1410`).
3. **Referanslar Bağlantısı** — panel UI'ı yok (yalnız model/payload/render).
4. **İşletme Türü** — elle giriş yok, kategori seçimine bağlı
   (`store_editor_controller.dart:329-336`).
5. (Alt notlar) Logo yükleme UI'ı yok (`auto_fill_service.dart:194-196` dışında);
   süre/garanti yapısal alan değil, "Teslim bölgesi" serbest metni
   (`product_editor_sheet.dart:288`); kampanya ve Hakkımızda görselleri yükleme
   değil URL metin alanı (`featured_campaign_sheet.dart:121`, `about_editor_sheet.dart:153`).

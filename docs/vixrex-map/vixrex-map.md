# Vixrex Ana Haritası — Derinlik 2

Salt-okuma kaynak: `main@7e187d087874` — 21 Eylül 2026.

## Canlı durum katmanı

Bu harita artık **kodda var**, **test sonucu doğrulandı** ve **canlıda doğrulandı** kavramlarını birbirine karıştırmaz.

- **Yeşil:** Somut kanıt var. Örneğin düğümün kod kanıtı mevcut veya harita açıldığı anda GitHub `main` SHA tarama commit'iyle eşleşiyor.
- **Sarı:** Bu harita üretiminde test/canlı kanıt toplanmadı. Bu durum **bozuk** demek değildir; yalnız doğrulanmamış demektir.
- **Kırmızı:** Harita tarama commitinden sapmışsa veya açık bir uyumsuzluk kaydedilmişse kullanılır.
- Harita açıldığında GitHub'ın public commits API'sinden `main` SHA yeniden okunur. Harita eskiyse üst durum çubuğu bunu anında gösterir; hiçbir anahtar veya gizli bilgi kullanılmaz.
- Her sistem düğümünde gelen ve giden bağlantılar görünür. Böylece örneğin `Vixrex Asistan → çalışma taslağı → yayın → public vitrin` zinciri kart detayından izlenebilir.
- `docs/vixrex-system-map` dalı Vercel dağıtımı başlatmaz; `vercel.json` ve `public_web/vercel.json` yalnız `main` ve `verify-*` dallarını dağıtıma açar. GitHub CI push tetikleyicisi de yalnız `main` için açıktır.

> Güvenlik kuralı: Kod dosyasının bulunması canlıda çalıştığını; test dosyasının bulunması son testin geçtiğini kanıtlamaz. `Canlı doğrulandı` ancak canlı kanıt kaynağı kaydedildiğinde kullanılmalıdır.

## Bu sürüm neyi çözüyor?

Bir alan seçildiğinde artık yalnız **46 alan** düğümünü görmüyorsun. Alanın ortak kayıt hattı ile alana özel gerçek etkileri ayrı gösteriliyor.

**Ortak hat:** `alan sözleşmesi → manuel editör / Vixrex Asistan → working draft → DB doğrulama → yayın → stores → public vitrin`.

Bunun üzerine yalnız o alana ait yan etkiler eklenir. Örneğin `isletmeAdi/name`: slug üretim girdisi, LocalBusiness adı, ürün seller adı, ürün SEO metni, blog markası, randevu başlığı ve Keşfet araması.

> Önemli: “bağımlı” olmak her değişiklikte otomatik yeniden üretim demek değildir. `name` yeni vitrinin slug üretim girdisidir; mevcut vitrinin adını değiştirmek mevcut slug'ı otomatik değiştirmez.

## 46 alan etki dizini

| Alan | DB | Bölüm | Alan-özel doğrudan etki sayısı |
|---|---|---|---:|
| İşletme Adı (`isletmeAdi`) | `name` | hero | 8 |
| Hero Rozet Metni (`heroRozet`) | `hero_badge` | hero | 2 |
| Kısa Tanıtım (`kisaTanitim`) | `description` | hero | 4 |
| Hero Konum Metni (`konumMetni`) | `hero_location_text` | hero | 1 |
| İşletme Kategorisi (`kategori`) | `kategori` | hero | 5 |
| İşletme Türü (`isletmeTuru`) | `business_type` | hero | 2 |
| Logo (`logo`) | `logo_url` | hero | 4 |
| Kapak / Hero Görseli (`kapakGorseli`) | `shelf_image_url` | hero | 3 |
| WhatsApp Numarası (`whatsapp`) | `whatsapp` | contact | 6 |
| Telefon (`telefon`) | `phone` | contact | 3 |
| E-posta (`eposta`) | `email` | contact | 1 |
| Açık Adres (`adres`) | `address` | contact | 5 |
| İl (`il`) | `province_name` | contact | 4 |
| İlçe (`ilce`) | `district_name` | contact | 4 |
| Mahalle (`mahalle`) | `neighborhood_name` | contact | 1 |
| Harita Kartı Etiketi (`haritaEtiketi`) | `map_label` | contact | 1 |
| Çalışma Saatleri (`calismaSaatleri`) | `working_hours` | contact | 3 |
| Instagram Kullanıcı Adı (`instagram`) | `instagram` | contact | 3 |
| Web Sitesi (`website`) | `website` | contact | 2 |
| Google İşletme / Harita Bağlantısı (`haritaLinki`) | `google_business_link` | contact | 2 |
| Konum — Enlem (`enlem`) | `latitude` | contact | 3 |
| Konum — Boylam (`boylam`) | `longitude` | contact | 3 |
| Kategori Bölümü Başlığı (`kategoriBolumBaslik`) | `category_section_title` | categories | 1 |
| Ürün Bölümü Başlığı (`urunBolumBaslik`) | `product_section_title` | products | 1 |
| Kampanya Etiketi (`bantEtiket`) | `featured_banner_label` | featured | 1 |
| Kampanya Başlığı (`bantBaslik`) | `featured_banner_title` | featured | 1 |
| Kampanya Açıklaması (`bantAciklama`) | `featured_banner_description` | featured | 1 |
| Kampanya Görseli (`bantGorsel`) | `featured_banner_image_url` | featured | 1 |
| Kampanya Fiyat Metni (`bantFiyat`) | `featured_banner_price_text` | featured | 1 |
| Hakkımızda Üst Başlık (`hakkindaUstBaslik`) | `about_kicker` | about | 1 |
| Hakkımızda Başlığı (`hakkindaBaslik`) | `about_title` | about | 1 |
| Hakkımızda Yazısı (`hakkindaMetin`) | `corporate_bio` | about | 3 |
| Hakkımızda Görseli (`hakkindaGorsel`) | `about_image_url` | about | 1 |
| Görsel Alt Yazısı (`hakkindaGorselAlt`) | `about_image_caption` | about | 1 |
| Galeri Üst Başlık (`galeriUstBaslik`) | `gallery_section_kicker` | gallery | 1 |
| Galeri Başlığı (`galeriBaslik`) | `gallery_section_title` | gallery | 1 |
| Galeri Buton Metni (`galeriAksiyonMetni`) | `gallery_action_label` | gallery | 1 |
| Galeri Buton Bağlantısı (`galeriAksiyonLinki`) | `gallery_action_href` | gallery | 1 |
| Blog Üst Başlık (`blogUstBaslik`) | `blog_section_kicker` | blog | 1 |
| Blog Bölüm Başlığı (`blogBaslik`) | `blog_section_title` | blog | 1 |
| SSS Üst Başlık (`sssUstBaslik`) | `faq_section_kicker` | faq | 1 |
| SSS Bölüm Başlığı (`sssBaslik`) | `faq_section_title` | faq | 1 |
| SSS Bölüm Açıklaması (`sssAciklama`) | `faq_section_description` | faq | 1 |
| Değerlendirme Puanını Göster (`puanGoster`) | `show_storefront_rating` | hero | 1 |
| Yol Tarifi Butonunu Göster (`yolTarifiGoster`) | `show_directions_link` | contact | 1 |
| Referanslar Bağlantısı (`referansLinki`) | `references_link` | about | 1 |

## İşletme Adı — `isletmeAdi / name`

### Ortak kayıt/yayın hattı

- **Tek kaynak → Alan sözleşmesi:** Anahtar, DB kolonu, tip, bölüm, zorunluluk ve doğrulama burada tanımlanır. Kanıt: `shared/vitrin_alanlari.json`, `public_web/src/lib/vitrinFieldSchema.ts`, `lib/config/vitrin_alanlari.g.dart`.
- **Dil / asistan → Vixrex Asistan:** Niyet sözlüğü alanı esnaf dilinden bulur; değer doğrulanır ve canonical kolona çevrilir. Kanıt: `shared/vixrex_niyet_sozlugu.json`, `public_web/src/lib/vixrexNluPipeline.ts`, `lib/services/vixrex_nlu/`.
- **Düzenleme → Manuel editörler:** Flutter manuel panel ve Next.js sahip editörü aynı alan sözleşmesine göre değeri düzenler. Kanıt: `lib/controllers/store_editor_controller.dart`, `lib/services/store_content_editing_service.dart`, `public_web/src/components/owner/VitrinimEditor.tsx`.
- **Taslak → store_working_drafts:** Değişiklik canlı store'a doğrudan yazılmadan çalışma taslağına kaydedilir; sürüm/çakışma kuralları uygulanır. Kanıt: `public_web/src/app/api/owner-draft/route.ts`, `supabase/migrations/20260805100000_add_working_draft_field_update.sql`, `supabase/migrations/20260909231500_lock_owned_assistant_batch_to_46_fields.sql`.
- **DB doğrulama → Assistant field command guard:** Asistan üzerinden gelen değer DB tarafında da alan tipine göre kontrol edilir. Kanıt: `supabase/migrations/20260909234500_validate_assistant_command_values_in_db.sql`.
- **Yayın → publish_working_draft:** Taslak yayın kapılarından geçerse canlı stores verisine taşınır. Kanıt: `lib/services/store_publish_payload_builder.dart`, `public_web/src/app/api/owner-publish/route.ts`, `supabase/migrations/20260805180000_add_publish_and_discard_working_draft.sql`.
- **Canlı okuma → Public vitrin:** Yayınlanan değer PUBLIC_STORE_SELECT üzerinden /v/[slug] yüzüne ulaşır. Kanıt: `public_web/src/lib/publicStoreSelect.ts`, `public_web/src/app/v/[slug]/page.tsx`.

### Alana özel etkiler

- **Slug üretimi:** Yeni vitrin oluşturulurken işletme adı slug üretiminin girdisidir. **Koşul:** Mevcut vitrinin adı sonradan değişince mevcut slug otomatik yeniden üretilmez. Kanıt: `public_web/src/app/api/create-store/route.ts`, `lib/services/store_publish_service.dart`, `lib/services/store_publish_payload_builder.dart`.
- **Public vitrin kimliği:** Vitrin adı, public vitrinin ana marka/işletme adı olarak gösterilir. Kanıt: `public_web/src/app/v/[slug]/page.tsx`.
- **SEO / LocalBusiness:** İşletme adı yapılandırılmış işletme varlığının name değerine gider. Kanıt: `lib/services/seo_service.dart`, `public_web/src/app/v/[slug]/page.tsx`, `test/seo_schema_builder_test.dart`.
- **Ürün SEO ve satıcı kimliği:** Ürün sayfası başlığı/açıklaması ve Product seller.name işletme adını kullanır. Kanıt: `public_web/src/app/v/[slug]/urun/[productSlug]/page.tsx`, `public_web/src/app/v/[slug]/urun/[productSlug]/PublicProductDetailPage.tsx`, `public_web/src/lib/productStructuredData.ts`.
- **Blog marka kimliği:** İşletme blogunda yazar/yayıncı adı ve vitrin başlığı olarak kullanılır. Kanıt: `public_web/src/app/v/[slug]/yazilar/page.tsx`, `public_web/src/app/v/[slug]/yazilar/[articleSlug]/page.tsx`.
- **Randevu yüzeyi:** Randevu sayfası ve randevu oluşturma bağlamı işletme adını taşır. Kanıt: `public_web/src/app/v/[slug]/randevu/page.tsx`, `public_web/src/app/v/[slug]/randevu/BookingWizardClient.tsx`.
- **Keşfet / arama / favori:** İşletme adı arama ve Flutter favori kimliği gibi keşif davranışlarında kullanılır. Kanıt: `lib/controllers/explore_controller.dart`, `lib/screens/explore_screen.dart`, `public_web/src/lib/explore.ts`.
- **Instagram ürün aktarımı bağlamı:** Instagram import sırasında ürün bağlamına storeName olarak verilir. Kanıt: `public_web/src/app/api/instagram/import/route.ts`.

### Özellikle etkilemediği şeyler

- Mevcut vitrinin URL slug'ı yalnız adı düzenlediğin için otomatik değişmez.
- Ürünlerin kendi product.name alanları değişmez; yalnız satıcı/mağaza bağlamı değişir.

### İlgili test kapıları

`public_web/tests/vitrin-field-schema.test.ts`, `public_web/tests/vixrex-46-alan-davranis-denetimi.test.ts`, `public_web/tests/vixrex-validation-parity.test.ts`, `test/vixrex_46_alan_executor_kapsam_test.dart`, `test/store_publish_payload_builder_test.dart`, `public_web/tests/vitrin-olusturma-parite.test.ts`, `test/seo_schema_builder_test.dart`

## Hero Rozet Metni — `heroRozet / hero_badge`

### Ortak kayıt/yayın hattı

- **Tek kaynak → Alan sözleşmesi:** Anahtar, DB kolonu, tip, bölüm, zorunluluk ve doğrulama burada tanımlanır. Kanıt: `shared/vitrin_alanlari.json`, `public_web/src/lib/vitrinFieldSchema.ts`, `lib/config/vitrin_alanlari.g.dart`.
- **Dil / asistan → Vixrex Asistan:** Niyet sözlüğü alanı esnaf dilinden bulur; değer doğrulanır ve canonical kolona çevrilir. Kanıt: `shared/vixrex_niyet_sozlugu.json`, `public_web/src/lib/vixrexNluPipeline.ts`, `lib/services/vixrex_nlu/`.
- **Düzenleme → Manuel editörler:** Flutter manuel panel ve Next.js sahip editörü aynı alan sözleşmesine göre değeri düzenler. Kanıt: `lib/controllers/store_editor_controller.dart`, `lib/services/store_content_editing_service.dart`, `public_web/src/components/owner/VitrinimEditor.tsx`.
- **Taslak → store_working_drafts:** Değişiklik canlı store'a doğrudan yazılmadan çalışma taslağına kaydedilir; sürüm/çakışma kuralları uygulanır. Kanıt: `public_web/src/app/api/owner-draft/route.ts`, `supabase/migrations/20260805100000_add_working_draft_field_update.sql`, `supabase/migrations/20260909231500_lock_owned_assistant_batch_to_46_fields.sql`.
- **DB doğrulama → Assistant field command guard:** Asistan üzerinden gelen değer DB tarafında da alan tipine göre kontrol edilir. Kanıt: `supabase/migrations/20260909234500_validate_assistant_command_values_in_db.sql`.
- **Yayın → publish_working_draft:** Taslak yayın kapılarından geçerse canlı stores verisine taşınır. Kanıt: `lib/services/store_publish_payload_builder.dart`, `public_web/src/app/api/owner-publish/route.ts`, `supabase/migrations/20260805180000_add_publish_and_discard_working_draft.sql`.
- **Canlı okuma → Public vitrin:** Yayınlanan değer PUBLIC_STORE_SELECT üzerinden /v/[slug] yüzüne ulaşır. Kanıt: `public_web/src/lib/publicStoreSelect.ts`, `public_web/src/app/v/[slug]/page.tsx`.

### Alana özel etkiler

- **Public hero rozeti:** Müşteri vitrininin hero rozet metnini değiştirir. Kanıt: `public_web/src/app/v/[slug]/page.tsx`.
- **Sahip önizleme davranışı:** Kiralık/örnek owner preview'da gerçek rozet yerine örnek görünüm mesajı geçici olarak gösterilebilir. **Koşul:** Bu görsel override DB değerini değiştirmez. Kanıt: `public_web/src/app/v/[slug]/page.tsx`.

### Özellikle etkilemediği şeyler

- SEO başlığı veya slug üretimini değiştirmez.

### İlgili test kapıları

`public_web/tests/vitrin-field-schema.test.ts`, `public_web/tests/vixrex-46-alan-davranis-denetimi.test.ts`, `public_web/tests/vixrex-validation-parity.test.ts`, `test/vixrex_46_alan_executor_kapsam_test.dart`, `test/store_publish_payload_builder_test.dart`

## Kısa Tanıtım — `kisaTanitim / description`

### Ortak kayıt/yayın hattı

- **Tek kaynak → Alan sözleşmesi:** Anahtar, DB kolonu, tip, bölüm, zorunluluk ve doğrulama burada tanımlanır. Kanıt: `shared/vitrin_alanlari.json`, `public_web/src/lib/vitrinFieldSchema.ts`, `lib/config/vitrin_alanlari.g.dart`.
- **Dil / asistan → Vixrex Asistan:** Niyet sözlüğü alanı esnaf dilinden bulur; değer doğrulanır ve canonical kolona çevrilir. Kanıt: `shared/vixrex_niyet_sozlugu.json`, `public_web/src/lib/vixrexNluPipeline.ts`, `lib/services/vixrex_nlu/`.
- **Düzenleme → Manuel editörler:** Flutter manuel panel ve Next.js sahip editörü aynı alan sözleşmesine göre değeri düzenler. Kanıt: `lib/controllers/store_editor_controller.dart`, `lib/services/store_content_editing_service.dart`, `public_web/src/components/owner/VitrinimEditor.tsx`.
- **Taslak → store_working_drafts:** Değişiklik canlı store'a doğrudan yazılmadan çalışma taslağına kaydedilir; sürüm/çakışma kuralları uygulanır. Kanıt: `public_web/src/app/api/owner-draft/route.ts`, `supabase/migrations/20260805100000_add_working_draft_field_update.sql`, `supabase/migrations/20260909231500_lock_owned_assistant_batch_to_46_fields.sql`.
- **DB doğrulama → Assistant field command guard:** Asistan üzerinden gelen değer DB tarafında da alan tipine göre kontrol edilir. Kanıt: `supabase/migrations/20260909234500_validate_assistant_command_values_in_db.sql`.
- **Yayın → publish_working_draft:** Taslak yayın kapılarından geçerse canlı stores verisine taşınır. Kanıt: `lib/services/store_publish_payload_builder.dart`, `public_web/src/app/api/owner-publish/route.ts`, `supabase/migrations/20260805180000_add_publish_and_discard_working_draft.sql`.
- **Canlı okuma → Public vitrin:** Yayınlanan değer PUBLIC_STORE_SELECT üzerinden /v/[slug] yüzüne ulaşır. Kanıt: `public_web/src/lib/publicStoreSelect.ts`, `public_web/src/app/v/[slug]/page.tsx`.

### Alana özel etkiler

- **Public açıklama:** Vitrinin görünen kısa açıklamasının ana kaynağıdır. Kanıt: `public_web/src/app/v/[slug]/page.tsx`.
- **SEO açıklaması:** Vitrin metadata/işletme açıklamasında ilk tercih edilen açıklamadır. Kanıt: `public_web/src/app/v/[slug]/page.tsx`, `lib/services/seo_service.dart`.
- **Ürün açıklaması fallback:** Ürünün kendi açıklaması yoksa ürün detay açıklamasına fallback olabilir. Kanıt: `public_web/src/app/v/[slug]/urun/[productSlug]/page.tsx`, `public_web/src/app/v/[slug]/urun/[productSlug]/PublicProductDetailPage.tsx`.
- **Flutter Keşfet araması:** Arama sorgusu işletme açıklamasında da eşleşir. Kanıt: `lib/controllers/explore_controller.dart`.

### Özellikle etkilemediği şeyler

- Ürün kaydının kendi description alanını değiştirmez.

### İlgili test kapıları

`public_web/tests/vitrin-field-schema.test.ts`, `public_web/tests/vixrex-46-alan-davranis-denetimi.test.ts`, `public_web/tests/vixrex-validation-parity.test.ts`, `test/vixrex_46_alan_executor_kapsam_test.dart`, `test/store_publish_payload_builder_test.dart`

## Hero Konum Metni — `konumMetni / hero_location_text`

### Ortak kayıt/yayın hattı

- **Tek kaynak → Alan sözleşmesi:** Anahtar, DB kolonu, tip, bölüm, zorunluluk ve doğrulama burada tanımlanır. Kanıt: `shared/vitrin_alanlari.json`, `public_web/src/lib/vitrinFieldSchema.ts`, `lib/config/vitrin_alanlari.g.dart`.
- **Dil / asistan → Vixrex Asistan:** Niyet sözlüğü alanı esnaf dilinden bulur; değer doğrulanır ve canonical kolona çevrilir. Kanıt: `shared/vixrex_niyet_sozlugu.json`, `public_web/src/lib/vixrexNluPipeline.ts`, `lib/services/vixrex_nlu/`.
- **Düzenleme → Manuel editörler:** Flutter manuel panel ve Next.js sahip editörü aynı alan sözleşmesine göre değeri düzenler. Kanıt: `lib/controllers/store_editor_controller.dart`, `lib/services/store_content_editing_service.dart`, `public_web/src/components/owner/VitrinimEditor.tsx`.
- **Taslak → store_working_drafts:** Değişiklik canlı store'a doğrudan yazılmadan çalışma taslağına kaydedilir; sürüm/çakışma kuralları uygulanır. Kanıt: `public_web/src/app/api/owner-draft/route.ts`, `supabase/migrations/20260805100000_add_working_draft_field_update.sql`, `supabase/migrations/20260909231500_lock_owned_assistant_batch_to_46_fields.sql`.
- **DB doğrulama → Assistant field command guard:** Asistan üzerinden gelen değer DB tarafında da alan tipine göre kontrol edilir. Kanıt: `supabase/migrations/20260909234500_validate_assistant_command_values_in_db.sql`.
- **Yayın → publish_working_draft:** Taslak yayın kapılarından geçerse canlı stores verisine taşınır. Kanıt: `lib/services/store_publish_payload_builder.dart`, `public_web/src/app/api/owner-publish/route.ts`, `supabase/migrations/20260805180000_add_publish_and_discard_working_draft.sql`.
- **Canlı okuma → Public vitrin:** Yayınlanan değer PUBLIC_STORE_SELECT üzerinden /v/[slug] yüzüne ulaşır. Kanıt: `public_web/src/lib/publicStoreSelect.ts`, `public_web/src/app/v/[slug]/page.tsx`.

### Alana özel etkiler

- **Hero konum metni:** Public vitrinde hero bölümünün görünen konum yazısını değiştirir. Kanıt: `public_web/src/app/v/[slug]/page.tsx`.

### Özellikle etkilemediği şeyler

- Adres, il/ilçe, GPS koordinatları veya LocalBusiness GeoCoordinates değişmez.

### İlgili test kapıları

`public_web/tests/vitrin-field-schema.test.ts`, `public_web/tests/vixrex-46-alan-davranis-denetimi.test.ts`, `public_web/tests/vixrex-validation-parity.test.ts`, `test/vixrex_46_alan_executor_kapsam_test.dart`, `test/store_publish_payload_builder_test.dart`

## İşletme Kategorisi — `kategori / kategori`

### Ortak kayıt/yayın hattı

- **Tek kaynak → Alan sözleşmesi:** Anahtar, DB kolonu, tip, bölüm, zorunluluk ve doğrulama burada tanımlanır. Kanıt: `shared/vitrin_alanlari.json`, `public_web/src/lib/vitrinFieldSchema.ts`, `lib/config/vitrin_alanlari.g.dart`.
- **Dil / asistan → Vixrex Asistan:** Niyet sözlüğü alanı esnaf dilinden bulur; değer doğrulanır ve canonical kolona çevrilir. Kanıt: `shared/vixrex_niyet_sozlugu.json`, `public_web/src/lib/vixrexNluPipeline.ts`, `lib/services/vixrex_nlu/`.
- **Düzenleme → Manuel editörler:** Flutter manuel panel ve Next.js sahip editörü aynı alan sözleşmesine göre değeri düzenler. Kanıt: `lib/controllers/store_editor_controller.dart`, `lib/services/store_content_editing_service.dart`, `public_web/src/components/owner/VitrinimEditor.tsx`.
- **Taslak → store_working_drafts:** Değişiklik canlı store'a doğrudan yazılmadan çalışma taslağına kaydedilir; sürüm/çakışma kuralları uygulanır. Kanıt: `public_web/src/app/api/owner-draft/route.ts`, `supabase/migrations/20260805100000_add_working_draft_field_update.sql`, `supabase/migrations/20260909231500_lock_owned_assistant_batch_to_46_fields.sql`.
- **DB doğrulama → Assistant field command guard:** Asistan üzerinden gelen değer DB tarafında da alan tipine göre kontrol edilir. Kanıt: `supabase/migrations/20260909234500_validate_assistant_command_values_in_db.sql`.
- **Yayın → publish_working_draft:** Taslak yayın kapılarından geçerse canlı stores verisine taşınır. Kanıt: `lib/services/store_publish_payload_builder.dart`, `public_web/src/app/api/owner-publish/route.ts`, `supabase/migrations/20260805180000_add_publish_and_discard_working_draft.sql`.
- **Canlı okuma → Public vitrin:** Yayınlanan değer PUBLIC_STORE_SELECT üzerinden /v/[slug] yüzüne ulaşır. Kanıt: `public_web/src/lib/publicStoreSelect.ts`, `public_web/src/app/v/[slug]/page.tsx`.

### Alana özel etkiler

- **Keşfet sınıflandırması:** Keşfet kategori filtresi ve kategori sayfalarında vitrinin hangi grupta göründüğünü etkiler. Kanıt: `lib/controllers/explore_controller.dart`, `public_web/src/app/(site)/kesfet/[kategori]/page.tsx`, `public_web/src/lib/explore.ts`.
- **Vitrin profil/şablon seçimi:** Kategori, public vitrinin kategori profili ve kopya/deneyim varyantını seçmekte kullanılır. Kanıt: `public_web/src/app/v/[slug]/page.tsx`, `public_web/src/lib/vitrinProfile.ts`.
- **Schema.org işletme tipi:** Kategori bazı iş türlerinde LocalBusiness alt tipinin seçimini etkiler (örn. HairSalon). Kanıt: `public_web/src/app/v/[slug]/page.tsx`.
- **Ürün varsayılan şablonu:** Sahip ürün yönetiminde varsayılan ürün şablonunun seçim girdilerinden biridir. Kanıt: `public_web/src/app/app/urunler/page.tsx`, `public_web/src/components/owner/VitrinimEditor.tsx`.
- **Flutter vitrin kartı davranışı:** Kategori bazı CTA/metin seçimlerinde kullanılır. Kanıt: `lib/widgets/vitrin_store_card.dart`.

### Özellikle etkilemediği şeyler

- Mevcut vitrin slug'ını değiştirmez.
- Ürün kayıtlarını otomatik başka kategoriye taşımaz.

### İlgili test kapıları

`public_web/tests/vitrin-field-schema.test.ts`, `public_web/tests/vixrex-46-alan-davranis-denetimi.test.ts`, `public_web/tests/vixrex-validation-parity.test.ts`, `test/vixrex_46_alan_executor_kapsam_test.dart`, `test/store_publish_payload_builder_test.dart`

## İşletme Türü — `isletmeTuru / business_type`

### Ortak kayıt/yayın hattı

- **Tek kaynak → Alan sözleşmesi:** Anahtar, DB kolonu, tip, bölüm, zorunluluk ve doğrulama burada tanımlanır. Kanıt: `shared/vitrin_alanlari.json`, `public_web/src/lib/vitrinFieldSchema.ts`, `lib/config/vitrin_alanlari.g.dart`.
- **Dil / asistan → Vixrex Asistan:** Niyet sözlüğü alanı esnaf dilinden bulur; değer doğrulanır ve canonical kolona çevrilir. Kanıt: `shared/vixrex_niyet_sozlugu.json`, `public_web/src/lib/vixrexNluPipeline.ts`, `lib/services/vixrex_nlu/`.
- **Düzenleme → Manuel editörler:** Flutter manuel panel ve Next.js sahip editörü aynı alan sözleşmesine göre değeri düzenler. Kanıt: `lib/controllers/store_editor_controller.dart`, `lib/services/store_content_editing_service.dart`, `public_web/src/components/owner/VitrinimEditor.tsx`.
- **Taslak → store_working_drafts:** Değişiklik canlı store'a doğrudan yazılmadan çalışma taslağına kaydedilir; sürüm/çakışma kuralları uygulanır. Kanıt: `public_web/src/app/api/owner-draft/route.ts`, `supabase/migrations/20260805100000_add_working_draft_field_update.sql`, `supabase/migrations/20260909231500_lock_owned_assistant_batch_to_46_fields.sql`.
- **DB doğrulama → Assistant field command guard:** Asistan üzerinden gelen değer DB tarafında da alan tipine göre kontrol edilir. Kanıt: `supabase/migrations/20260909234500_validate_assistant_command_values_in_db.sql`.
- **Yayın → publish_working_draft:** Taslak yayın kapılarından geçerse canlı stores verisine taşınır. Kanıt: `lib/services/store_publish_payload_builder.dart`, `public_web/src/app/api/owner-publish/route.ts`, `supabase/migrations/20260805180000_add_publish_and_discard_working_draft.sql`.
- **Canlı okuma → Public vitrin:** Yayınlanan değer PUBLIC_STORE_SELECT üzerinden /v/[slug] yüzüne ulaşır. Kanıt: `public_web/src/lib/publicStoreSelect.ts`, `public_web/src/app/v/[slug]/page.tsx`.

### Alana özel etkiler

- **Vitrin profil/şablon seçimi:** Kategori ile birlikte public vitrin profilinin seçim girdisidir. Kanıt: `public_web/src/app/v/[slug]/page.tsx`, `public_web/src/lib/vitrinProfile.ts`.
- **Ürün varsayılan şablonu:** Kategori ile birlikte varsayılan ürün tipi/şablonu belirlemede kullanılır. Kanıt: `public_web/src/app/app/urunler/page.tsx`, `public_web/src/components/owner/VitrinimEditor.tsx`.

### Özellikle etkilemediği şeyler

- Keşfet kategori URL'sini tek başına yeniden yazmaz.

### İlgili test kapıları

`public_web/tests/vitrin-field-schema.test.ts`, `public_web/tests/vixrex-46-alan-davranis-denetimi.test.ts`, `public_web/tests/vixrex-validation-parity.test.ts`, `test/vixrex_46_alan_executor_kapsam_test.dart`, `test/store_publish_payload_builder_test.dart`

## Logo — `logo / logo_url`

### Ortak kayıt/yayın hattı

- **Tek kaynak → Alan sözleşmesi:** Anahtar, DB kolonu, tip, bölüm, zorunluluk ve doğrulama burada tanımlanır. Kanıt: `shared/vitrin_alanlari.json`, `public_web/src/lib/vitrinFieldSchema.ts`, `lib/config/vitrin_alanlari.g.dart`.
- **Dil / asistan → Vixrex Asistan:** Niyet sözlüğü alanı esnaf dilinden bulur; değer doğrulanır ve canonical kolona çevrilir. Kanıt: `shared/vixrex_niyet_sozlugu.json`, `public_web/src/lib/vixrexNluPipeline.ts`, `lib/services/vixrex_nlu/`.
- **Düzenleme → Manuel editörler:** Flutter manuel panel ve Next.js sahip editörü aynı alan sözleşmesine göre değeri düzenler. Kanıt: `lib/controllers/store_editor_controller.dart`, `lib/services/store_content_editing_service.dart`, `public_web/src/components/owner/VitrinimEditor.tsx`.
- **Taslak → store_working_drafts:** Değişiklik canlı store'a doğrudan yazılmadan çalışma taslağına kaydedilir; sürüm/çakışma kuralları uygulanır. Kanıt: `public_web/src/app/api/owner-draft/route.ts`, `supabase/migrations/20260805100000_add_working_draft_field_update.sql`, `supabase/migrations/20260909231500_lock_owned_assistant_batch_to_46_fields.sql`.
- **DB doğrulama → Assistant field command guard:** Asistan üzerinden gelen değer DB tarafında da alan tipine göre kontrol edilir. Kanıt: `supabase/migrations/20260909234500_validate_assistant_command_values_in_db.sql`.
- **Yayın → publish_working_draft:** Taslak yayın kapılarından geçerse canlı stores verisine taşınır. Kanıt: `lib/services/store_publish_payload_builder.dart`, `public_web/src/app/api/owner-publish/route.ts`, `supabase/migrations/20260805180000_add_publish_and_discard_working_draft.sql`.
- **Canlı okuma → Public vitrin:** Yayınlanan değer PUBLIC_STORE_SELECT üzerinden /v/[slug] yüzüne ulaşır. Kanıt: `public_web/src/lib/publicStoreSelect.ts`, `public_web/src/app/v/[slug]/page.tsx`.

### Alana özel etkiler

- **Public marka görseli:** Vitrin, blog ve randevu yüzlerinde marka logosu olarak görünür. Kanıt: `public_web/src/app/v/[slug]/page.tsx`, `public_web/src/app/v/[slug]/yazilar/page.tsx`, `public_web/src/app/v/[slug]/randevu/page.tsx`.
- **SEO/OG görsel fallback:** Kapak görseli yoksa vitrin metadata görseli olarak logo kullanılabilir. **Koşul:** Kapak görseli önceliklidir. Kanıt: `public_web/src/app/v/[slug]/page.tsx`.
- **Ürün görsel fallback:** Ürün görseli ve kapak görseli yoksa ürün detayında fallback olabilir. Kanıt: `public_web/src/app/v/[slug]/urun/[productSlug]/page.tsx`, `public_web/src/app/v/[slug]/urun/[productSlug]/PublicProductDetailPage.tsx`.
- **Blog structured data:** İşletme yazılarında author/publisher logo bağlamına girer. Kanıt: `public_web/src/app/v/[slug]/yazilar/[articleSlug]/page.tsx`.

### Özellikle etkilemediği şeyler

- Ürünlerin kendi image_urls kayıtlarını değiştirmez.

### İlgili test kapıları

`public_web/tests/vitrin-field-schema.test.ts`, `public_web/tests/vixrex-46-alan-davranis-denetimi.test.ts`, `public_web/tests/vixrex-validation-parity.test.ts`, `test/vixrex_46_alan_executor_kapsam_test.dart`, `test/store_publish_payload_builder_test.dart`

## Kapak / Hero Görseli — `kapakGorseli / shelf_image_url`

### Ortak kayıt/yayın hattı

- **Tek kaynak → Alan sözleşmesi:** Anahtar, DB kolonu, tip, bölüm, zorunluluk ve doğrulama burada tanımlanır. Kanıt: `shared/vitrin_alanlari.json`, `public_web/src/lib/vitrinFieldSchema.ts`, `lib/config/vitrin_alanlari.g.dart`.
- **Dil / asistan → Vixrex Asistan:** Niyet sözlüğü alanı esnaf dilinden bulur; değer doğrulanır ve canonical kolona çevrilir. Kanıt: `shared/vixrex_niyet_sozlugu.json`, `public_web/src/lib/vixrexNluPipeline.ts`, `lib/services/vixrex_nlu/`.
- **Düzenleme → Manuel editörler:** Flutter manuel panel ve Next.js sahip editörü aynı alan sözleşmesine göre değeri düzenler. Kanıt: `lib/controllers/store_editor_controller.dart`, `lib/services/store_content_editing_service.dart`, `public_web/src/components/owner/VitrinimEditor.tsx`.
- **Taslak → store_working_drafts:** Değişiklik canlı store'a doğrudan yazılmadan çalışma taslağına kaydedilir; sürüm/çakışma kuralları uygulanır. Kanıt: `public_web/src/app/api/owner-draft/route.ts`, `supabase/migrations/20260805100000_add_working_draft_field_update.sql`, `supabase/migrations/20260909231500_lock_owned_assistant_batch_to_46_fields.sql`.
- **DB doğrulama → Assistant field command guard:** Asistan üzerinden gelen değer DB tarafında da alan tipine göre kontrol edilir. Kanıt: `supabase/migrations/20260909234500_validate_assistant_command_values_in_db.sql`.
- **Yayın → publish_working_draft:** Taslak yayın kapılarından geçerse canlı stores verisine taşınır. Kanıt: `lib/services/store_publish_payload_builder.dart`, `public_web/src/app/api/owner-publish/route.ts`, `supabase/migrations/20260805180000_add_publish_and_discard_working_draft.sql`.
- **Canlı okuma → Public vitrin:** Yayınlanan değer PUBLIC_STORE_SELECT üzerinden /v/[slug] yüzüne ulaşır. Kanıt: `public_web/src/lib/publicStoreSelect.ts`, `public_web/src/app/v/[slug]/page.tsx`.

### Alana özel etkiler

- **Public hero:** Vitrinin ana/hero görselidir. Kanıt: `public_web/src/app/v/[slug]/page.tsx`.
- **SEO/OG görsel:** Vitrin metadata görselinde logodan önce kullanılır. Kanıt: `public_web/src/app/v/[slug]/page.tsx`.
- **Ürün görsel fallback:** Ürün görseli yoksa ürün detayında fallback görsel olabilir. Kanıt: `public_web/src/app/v/[slug]/urun/[productSlug]/page.tsx`, `public_web/src/app/v/[slug]/urun/[productSlug]/PublicProductDetailPage.tsx`.

### Özellikle etkilemediği şeyler

- Ürünlerin kendi görsel dizisini değiştirmez.

### İlgili test kapıları

`public_web/tests/vitrin-field-schema.test.ts`, `public_web/tests/vixrex-46-alan-davranis-denetimi.test.ts`, `public_web/tests/vixrex-validation-parity.test.ts`, `test/vixrex_46_alan_executor_kapsam_test.dart`, `test/store_publish_payload_builder_test.dart`

## WhatsApp Numarası — `whatsapp / whatsapp`

### Ortak kayıt/yayın hattı

- **Tek kaynak → Alan sözleşmesi:** Anahtar, DB kolonu, tip, bölüm, zorunluluk ve doğrulama burada tanımlanır. Kanıt: `shared/vitrin_alanlari.json`, `public_web/src/lib/vitrinFieldSchema.ts`, `lib/config/vitrin_alanlari.g.dart`.
- **Dil / asistan → Vixrex Asistan:** Niyet sözlüğü alanı esnaf dilinden bulur; değer doğrulanır ve canonical kolona çevrilir. Kanıt: `shared/vixrex_niyet_sozlugu.json`, `public_web/src/lib/vixrexNluPipeline.ts`, `lib/services/vixrex_nlu/`.
- **Düzenleme → Manuel editörler:** Flutter manuel panel ve Next.js sahip editörü aynı alan sözleşmesine göre değeri düzenler. Kanıt: `lib/controllers/store_editor_controller.dart`, `lib/services/store_content_editing_service.dart`, `public_web/src/components/owner/VitrinimEditor.tsx`.
- **Taslak → store_working_drafts:** Değişiklik canlı store'a doğrudan yazılmadan çalışma taslağına kaydedilir; sürüm/çakışma kuralları uygulanır. Kanıt: `public_web/src/app/api/owner-draft/route.ts`, `supabase/migrations/20260805100000_add_working_draft_field_update.sql`, `supabase/migrations/20260909231500_lock_owned_assistant_batch_to_46_fields.sql`.
- **DB doğrulama → Assistant field command guard:** Asistan üzerinden gelen değer DB tarafında da alan tipine göre kontrol edilir. Kanıt: `supabase/migrations/20260909234500_validate_assistant_command_values_in_db.sql`.
- **Yayın → publish_working_draft:** Taslak yayın kapılarından geçerse canlı stores verisine taşınır. Kanıt: `lib/services/store_publish_payload_builder.dart`, `public_web/src/app/api/owner-publish/route.ts`, `supabase/migrations/20260805180000_add_publish_and_discard_working_draft.sql`.
- **Canlı okuma → Public vitrin:** Yayınlanan değer PUBLIC_STORE_SELECT üzerinden /v/[slug] yüzüne ulaşır. Kanıt: `public_web/src/lib/publicStoreSelect.ts`, `public_web/src/app/v/[slug]/page.tsx`.

### Alana özel etkiler

- **Yayın kapısı:** Zorunlu alandır; yayın readiness WhatsApp'ın dolu/geçerli olmasını ister. Kanıt: `public_web/src/app/api/owner-publish/route.ts`, `lib/services/store_publish_validator.dart`, `supabase/migrations/20260821164605_store_publish_readiness_core.sql`.
- **Public WhatsApp CTA:** Vitrinin WhatsApp iletişim URL'sini ve hazır mesajını üretir. Kanıt: `public_web/src/app/v/[slug]/page.tsx`, `public_web/src/components/TrackedWhatsAppLink.tsx`.
- **Ürün WhatsApp CTA:** Ürün detay sayfalarındaki WhatsApp iletişimini üretir. Kanıt: `public_web/src/app/v/[slug]/urun/[productSlug]/page.tsx`, `public_web/src/app/v/[slug]/urun/[productSlug]/PublicProductDetailPage.tsx`.
- **SEO telefon verisi:** Schema tarafında telefon için WhatsApp normalize edilmiş numarası fallback olarak kullanılabilir. Kanıt: `public_web/src/app/v/[slug]/page.tsx`, `lib/services/seo_service.dart`.
- **İşletme doğrulama:** Google işletme sahipliği doğrulamasında phone ile birlikte eşleşme adayıdır. Kanıt: `supabase/functions/verify-business-ownership/index.ts`.
- **Flutter Keşfet sipariş akışı:** Keşfet kartındaki WhatsApp eylemleri bu numarayı kullanır. Kanıt: `lib/screens/explore_screen.dart`.

### İlgili test kapıları

`public_web/tests/vitrin-field-schema.test.ts`, `public_web/tests/vixrex-46-alan-davranis-denetimi.test.ts`, `public_web/tests/vixrex-validation-parity.test.ts`, `test/vixrex_46_alan_executor_kapsam_test.dart`, `test/store_publish_payload_builder_test.dart`, `public_web/e2e/whatsapp-akisi.spec.ts`, `public_web/e2e/public-vitrin.spec.ts`

## Telefon — `telefon / phone`

### Ortak kayıt/yayın hattı

- **Tek kaynak → Alan sözleşmesi:** Anahtar, DB kolonu, tip, bölüm, zorunluluk ve doğrulama burada tanımlanır. Kanıt: `shared/vitrin_alanlari.json`, `public_web/src/lib/vitrinFieldSchema.ts`, `lib/config/vitrin_alanlari.g.dart`.
- **Dil / asistan → Vixrex Asistan:** Niyet sözlüğü alanı esnaf dilinden bulur; değer doğrulanır ve canonical kolona çevrilir. Kanıt: `shared/vixrex_niyet_sozlugu.json`, `public_web/src/lib/vixrexNluPipeline.ts`, `lib/services/vixrex_nlu/`.
- **Düzenleme → Manuel editörler:** Flutter manuel panel ve Next.js sahip editörü aynı alan sözleşmesine göre değeri düzenler. Kanıt: `lib/controllers/store_editor_controller.dart`, `lib/services/store_content_editing_service.dart`, `public_web/src/components/owner/VitrinimEditor.tsx`.
- **Taslak → store_working_drafts:** Değişiklik canlı store'a doğrudan yazılmadan çalışma taslağına kaydedilir; sürüm/çakışma kuralları uygulanır. Kanıt: `public_web/src/app/api/owner-draft/route.ts`, `supabase/migrations/20260805100000_add_working_draft_field_update.sql`, `supabase/migrations/20260909231500_lock_owned_assistant_batch_to_46_fields.sql`.
- **DB doğrulama → Assistant field command guard:** Asistan üzerinden gelen değer DB tarafında da alan tipine göre kontrol edilir. Kanıt: `supabase/migrations/20260909234500_validate_assistant_command_values_in_db.sql`.
- **Yayın → publish_working_draft:** Taslak yayın kapılarından geçerse canlı stores verisine taşınır. Kanıt: `lib/services/store_publish_payload_builder.dart`, `public_web/src/app/api/owner-publish/route.ts`, `supabase/migrations/20260805180000_add_publish_and_discard_working_draft.sql`.
- **Canlı okuma → Public vitrin:** Yayınlanan değer PUBLIC_STORE_SELECT üzerinden /v/[slug] yüzüne ulaşır. Kanıt: `public_web/src/lib/publicStoreSelect.ts`, `public_web/src/app/v/[slug]/page.tsx`.

### Alana özel etkiler

- **Telefon CTA:** Public vitrinde tel: bağlantısı üretir. Kanıt: `public_web/src/app/v/[slug]/page.tsx`.
- **SEO telefon tercihi:** Yapılandırılmış veride telefon varsa öncelikli; yoksa WhatsApp fallback olabilir. Kanıt: `public_web/src/app/v/[slug]/page.tsx`.
- **İşletme doğrulama:** Google işletme sahipliği doğrulamasında WhatsApp ile birlikte telefon eşleşmesine katılır. Kanıt: `supabase/functions/verify-business-ownership/index.ts`.

### İlgili test kapıları

`public_web/tests/vitrin-field-schema.test.ts`, `public_web/tests/vixrex-46-alan-davranis-denetimi.test.ts`, `public_web/tests/vixrex-validation-parity.test.ts`, `test/vixrex_46_alan_executor_kapsam_test.dart`, `test/store_publish_payload_builder_test.dart`

## E-posta — `eposta / email`

### Ortak kayıt/yayın hattı

- **Tek kaynak → Alan sözleşmesi:** Anahtar, DB kolonu, tip, bölüm, zorunluluk ve doğrulama burada tanımlanır. Kanıt: `shared/vitrin_alanlari.json`, `public_web/src/lib/vitrinFieldSchema.ts`, `lib/config/vitrin_alanlari.g.dart`.
- **Dil / asistan → Vixrex Asistan:** Niyet sözlüğü alanı esnaf dilinden bulur; değer doğrulanır ve canonical kolona çevrilir. Kanıt: `shared/vixrex_niyet_sozlugu.json`, `public_web/src/lib/vixrexNluPipeline.ts`, `lib/services/vixrex_nlu/`.
- **Düzenleme → Manuel editörler:** Flutter manuel panel ve Next.js sahip editörü aynı alan sözleşmesine göre değeri düzenler. Kanıt: `lib/controllers/store_editor_controller.dart`, `lib/services/store_content_editing_service.dart`, `public_web/src/components/owner/VitrinimEditor.tsx`.
- **Taslak → store_working_drafts:** Değişiklik canlı store'a doğrudan yazılmadan çalışma taslağına kaydedilir; sürüm/çakışma kuralları uygulanır. Kanıt: `public_web/src/app/api/owner-draft/route.ts`, `supabase/migrations/20260805100000_add_working_draft_field_update.sql`, `supabase/migrations/20260909231500_lock_owned_assistant_batch_to_46_fields.sql`.
- **DB doğrulama → Assistant field command guard:** Asistan üzerinden gelen değer DB tarafında da alan tipine göre kontrol edilir. Kanıt: `supabase/migrations/20260909234500_validate_assistant_command_values_in_db.sql`.
- **Yayın → publish_working_draft:** Taslak yayın kapılarından geçerse canlı stores verisine taşınır. Kanıt: `lib/services/store_publish_payload_builder.dart`, `public_web/src/app/api/owner-publish/route.ts`, `supabase/migrations/20260805180000_add_publish_and_discard_working_draft.sql`.
- **Canlı okuma → Public vitrin:** Yayınlanan değer PUBLIC_STORE_SELECT üzerinden /v/[slug] yüzüne ulaşır. Kanıt: `public_web/src/lib/publicStoreSelect.ts`, `public_web/src/app/v/[slug]/page.tsx`.

### Alana özel etkiler

- **Public iletişim:** Public vitrinde gösterilen işletme e-posta bilgisini değiştirir. Kanıt: `public_web/src/app/v/[slug]/page.tsx`, `public_web/src/app/v/[slug]/VitrinProfileView.tsx`.

### Özellikle etkilemediği şeyler

- Kullanıcının Vixrex hesap e-postasını değiştirmez.

### İlgili test kapıları

`public_web/tests/vitrin-field-schema.test.ts`, `public_web/tests/vixrex-46-alan-davranis-denetimi.test.ts`, `public_web/tests/vixrex-validation-parity.test.ts`, `test/vixrex_46_alan_executor_kapsam_test.dart`, `test/store_publish_payload_builder_test.dart`

## Açık Adres — `adres / address`

### Ortak kayıt/yayın hattı

- **Tek kaynak → Alan sözleşmesi:** Anahtar, DB kolonu, tip, bölüm, zorunluluk ve doğrulama burada tanımlanır. Kanıt: `shared/vitrin_alanlari.json`, `public_web/src/lib/vitrinFieldSchema.ts`, `lib/config/vitrin_alanlari.g.dart`.
- **Dil / asistan → Vixrex Asistan:** Niyet sözlüğü alanı esnaf dilinden bulur; değer doğrulanır ve canonical kolona çevrilir. Kanıt: `shared/vixrex_niyet_sozlugu.json`, `public_web/src/lib/vixrexNluPipeline.ts`, `lib/services/vixrex_nlu/`.
- **Düzenleme → Manuel editörler:** Flutter manuel panel ve Next.js sahip editörü aynı alan sözleşmesine göre değeri düzenler. Kanıt: `lib/controllers/store_editor_controller.dart`, `lib/services/store_content_editing_service.dart`, `public_web/src/components/owner/VitrinimEditor.tsx`.
- **Taslak → store_working_drafts:** Değişiklik canlı store'a doğrudan yazılmadan çalışma taslağına kaydedilir; sürüm/çakışma kuralları uygulanır. Kanıt: `public_web/src/app/api/owner-draft/route.ts`, `supabase/migrations/20260805100000_add_working_draft_field_update.sql`, `supabase/migrations/20260909231500_lock_owned_assistant_batch_to_46_fields.sql`.
- **DB doğrulama → Assistant field command guard:** Asistan üzerinden gelen değer DB tarafında da alan tipine göre kontrol edilir. Kanıt: `supabase/migrations/20260909234500_validate_assistant_command_values_in_db.sql`.
- **Yayın → publish_working_draft:** Taslak yayın kapılarından geçerse canlı stores verisine taşınır. Kanıt: `lib/services/store_publish_payload_builder.dart`, `public_web/src/app/api/owner-publish/route.ts`, `supabase/migrations/20260805180000_add_publish_and_discard_working_draft.sql`.
- **Canlı okuma → Public vitrin:** Yayınlanan değer PUBLIC_STORE_SELECT üzerinden /v/[slug] yüzüne ulaşır. Kanıt: `public_web/src/lib/publicStoreSelect.ts`, `public_web/src/app/v/[slug]/page.tsx`.

### Alana özel etkiler

- **Yayın kapısı:** Zorunlu yayın alanıdır. Kanıt: `public_web/src/app/api/owner-publish/route.ts`, `supabase/migrations/20260821164605_store_publish_readiness_core.sql`.
- **Harita / yol tarifi:** GPS yoksa Google Maps arama URL'si ve embed adres üzerinden üretilebilir. Kanıt: `public_web/src/app/v/[slug]/page.tsx`.
- **SEO PostalAddress:** Fiziksel konum yeterliyse LocalBusiness adres verisine girer. Kanıt: `lib/services/seo_service.dart`, `test/seo_schema_builder_test.dart`.
- **Ürün konum bağlamı:** Ürün detayında mağaza adresi/harita bağlamı olarak kullanılır. Kanıt: `public_web/src/app/v/[slug]/urun/[productSlug]/page.tsx`, `public_web/src/app/v/[slug]/urun/[productSlug]/PublicProductDetailPage.tsx`.
- **Keşfet kartı fallback:** Daha özel konum alanı yoksa Flutter kartında konum metni fallback olabilir. Kanıt: `lib/widgets/vitrin_store_card.dart`.

### İlgili test kapıları

`public_web/tests/vitrin-field-schema.test.ts`, `public_web/tests/vixrex-46-alan-davranis-denetimi.test.ts`, `public_web/tests/vixrex-validation-parity.test.ts`, `test/vixrex_46_alan_executor_kapsam_test.dart`, `test/store_publish_payload_builder_test.dart`

## İl — `il / province_name`

### Ortak kayıt/yayın hattı

- **Tek kaynak → Alan sözleşmesi:** Anahtar, DB kolonu, tip, bölüm, zorunluluk ve doğrulama burada tanımlanır. Kanıt: `shared/vitrin_alanlari.json`, `public_web/src/lib/vitrinFieldSchema.ts`, `lib/config/vitrin_alanlari.g.dart`.
- **Dil / asistan → Vixrex Asistan:** Niyet sözlüğü alanı esnaf dilinden bulur; değer doğrulanır ve canonical kolona çevrilir. Kanıt: `shared/vixrex_niyet_sozlugu.json`, `public_web/src/lib/vixrexNluPipeline.ts`, `lib/services/vixrex_nlu/`.
- **Düzenleme → Manuel editörler:** Flutter manuel panel ve Next.js sahip editörü aynı alan sözleşmesine göre değeri düzenler. Kanıt: `lib/controllers/store_editor_controller.dart`, `lib/services/store_content_editing_service.dart`, `public_web/src/components/owner/VitrinimEditor.tsx`.
- **Taslak → store_working_drafts:** Değişiklik canlı store'a doğrudan yazılmadan çalışma taslağına kaydedilir; sürüm/çakışma kuralları uygulanır. Kanıt: `public_web/src/app/api/owner-draft/route.ts`, `supabase/migrations/20260805100000_add_working_draft_field_update.sql`, `supabase/migrations/20260909231500_lock_owned_assistant_batch_to_46_fields.sql`.
- **DB doğrulama → Assistant field command guard:** Asistan üzerinden gelen değer DB tarafında da alan tipine göre kontrol edilir. Kanıt: `supabase/migrations/20260909234500_validate_assistant_command_values_in_db.sql`.
- **Yayın → publish_working_draft:** Taslak yayın kapılarından geçerse canlı stores verisine taşınır. Kanıt: `lib/services/store_publish_payload_builder.dart`, `public_web/src/app/api/owner-publish/route.ts`, `supabase/migrations/20260805180000_add_publish_and_discard_working_draft.sql`.
- **Canlı okuma → Public vitrin:** Yayınlanan değer PUBLIC_STORE_SELECT üzerinden /v/[slug] yüzüne ulaşır. Kanıt: `public_web/src/lib/publicStoreSelect.ts`, `public_web/src/app/v/[slug]/page.tsx`.

### Alana özel etkiler

- **Yayın kapısı:** Zorunlu yayın alanıdır. Kanıt: `public_web/src/app/api/owner-publish/route.ts`, `supabase/migrations/20260821164605_store_publish_readiness_core.sql`.
- **Public konum:** Public vitrin konum bileşenine provinceName olarak gider. Kanıt: `public_web/src/app/v/[slug]/page.tsx`.
- **Keşfet verisi:** Keşfet store seçimi/konum verisinde okunur. Kanıt: `public_web/src/lib/explore.ts`.
- **Asistan özel akışı:** Next NLU il alanını özel akış gerektiren alan olarak işaretler. Kanıt: `public_web/src/lib/vixrexNluPipeline.ts`.

### İlgili test kapıları

`public_web/tests/vitrin-field-schema.test.ts`, `public_web/tests/vixrex-46-alan-davranis-denetimi.test.ts`, `public_web/tests/vixrex-validation-parity.test.ts`, `test/vixrex_46_alan_executor_kapsam_test.dart`, `test/store_publish_payload_builder_test.dart`

## İlçe — `ilce / district_name`

### Ortak kayıt/yayın hattı

- **Tek kaynak → Alan sözleşmesi:** Anahtar, DB kolonu, tip, bölüm, zorunluluk ve doğrulama burada tanımlanır. Kanıt: `shared/vitrin_alanlari.json`, `public_web/src/lib/vitrinFieldSchema.ts`, `lib/config/vitrin_alanlari.g.dart`.
- **Dil / asistan → Vixrex Asistan:** Niyet sözlüğü alanı esnaf dilinden bulur; değer doğrulanır ve canonical kolona çevrilir. Kanıt: `shared/vixrex_niyet_sozlugu.json`, `public_web/src/lib/vixrexNluPipeline.ts`, `lib/services/vixrex_nlu/`.
- **Düzenleme → Manuel editörler:** Flutter manuel panel ve Next.js sahip editörü aynı alan sözleşmesine göre değeri düzenler. Kanıt: `lib/controllers/store_editor_controller.dart`, `lib/services/store_content_editing_service.dart`, `public_web/src/components/owner/VitrinimEditor.tsx`.
- **Taslak → store_working_drafts:** Değişiklik canlı store'a doğrudan yazılmadan çalışma taslağına kaydedilir; sürüm/çakışma kuralları uygulanır. Kanıt: `public_web/src/app/api/owner-draft/route.ts`, `supabase/migrations/20260805100000_add_working_draft_field_update.sql`, `supabase/migrations/20260909231500_lock_owned_assistant_batch_to_46_fields.sql`.
- **DB doğrulama → Assistant field command guard:** Asistan üzerinden gelen değer DB tarafında da alan tipine göre kontrol edilir. Kanıt: `supabase/migrations/20260909234500_validate_assistant_command_values_in_db.sql`.
- **Yayın → publish_working_draft:** Taslak yayın kapılarından geçerse canlı stores verisine taşınır. Kanıt: `lib/services/store_publish_payload_builder.dart`, `public_web/src/app/api/owner-publish/route.ts`, `supabase/migrations/20260805180000_add_publish_and_discard_working_draft.sql`.
- **Canlı okuma → Public vitrin:** Yayınlanan değer PUBLIC_STORE_SELECT üzerinden /v/[slug] yüzüne ulaşır. Kanıt: `public_web/src/lib/publicStoreSelect.ts`, `public_web/src/app/v/[slug]/page.tsx`.

### Alana özel etkiler

- **Yayın kapısı:** Zorunlu yayın alanıdır. Kanıt: `public_web/src/app/api/owner-publish/route.ts`, `supabase/migrations/20260821164605_store_publish_readiness_core.sql`.
- **Public konum:** Public vitrin konum bileşenine districtName olarak gider. Kanıt: `public_web/src/app/v/[slug]/page.tsx`.
- **Keşfet verisi:** Keşfet store seçimi/konum verisinde okunur. Kanıt: `public_web/src/lib/explore.ts`.
- **Asistan özel akışı:** Next NLU ilçe alanını özel akış gerektiren alan olarak işaretler. Kanıt: `public_web/src/lib/vixrexNluPipeline.ts`.

### İlgili test kapıları

`public_web/tests/vitrin-field-schema.test.ts`, `public_web/tests/vixrex-46-alan-davranis-denetimi.test.ts`, `public_web/tests/vixrex-validation-parity.test.ts`, `test/vixrex_46_alan_executor_kapsam_test.dart`, `test/store_publish_payload_builder_test.dart`

## Mahalle — `mahalle / neighborhood_name`

### Ortak kayıt/yayın hattı

- **Tek kaynak → Alan sözleşmesi:** Anahtar, DB kolonu, tip, bölüm, zorunluluk ve doğrulama burada tanımlanır. Kanıt: `shared/vitrin_alanlari.json`, `public_web/src/lib/vitrinFieldSchema.ts`, `lib/config/vitrin_alanlari.g.dart`.
- **Dil / asistan → Vixrex Asistan:** Niyet sözlüğü alanı esnaf dilinden bulur; değer doğrulanır ve canonical kolona çevrilir. Kanıt: `shared/vixrex_niyet_sozlugu.json`, `public_web/src/lib/vixrexNluPipeline.ts`, `lib/services/vixrex_nlu/`.
- **Düzenleme → Manuel editörler:** Flutter manuel panel ve Next.js sahip editörü aynı alan sözleşmesine göre değeri düzenler. Kanıt: `lib/controllers/store_editor_controller.dart`, `lib/services/store_content_editing_service.dart`, `public_web/src/components/owner/VitrinimEditor.tsx`.
- **Taslak → store_working_drafts:** Değişiklik canlı store'a doğrudan yazılmadan çalışma taslağına kaydedilir; sürüm/çakışma kuralları uygulanır. Kanıt: `public_web/src/app/api/owner-draft/route.ts`, `supabase/migrations/20260805100000_add_working_draft_field_update.sql`, `supabase/migrations/20260909231500_lock_owned_assistant_batch_to_46_fields.sql`.
- **DB doğrulama → Assistant field command guard:** Asistan üzerinden gelen değer DB tarafında da alan tipine göre kontrol edilir. Kanıt: `supabase/migrations/20260909234500_validate_assistant_command_values_in_db.sql`.
- **Yayın → publish_working_draft:** Taslak yayın kapılarından geçerse canlı stores verisine taşınır. Kanıt: `lib/services/store_publish_payload_builder.dart`, `public_web/src/app/api/owner-publish/route.ts`, `supabase/migrations/20260805180000_add_publish_and_discard_working_draft.sql`.
- **Canlı okuma → Public vitrin:** Yayınlanan değer PUBLIC_STORE_SELECT üzerinden /v/[slug] yüzüne ulaşır. Kanıt: `public_web/src/lib/publicStoreSelect.ts`, `public_web/src/app/v/[slug]/page.tsx`.

### Alana özel etkiler

- **Public konum:** Public vitrin konum bileşeninde mahalle bilgisidir. Kanıt: `public_web/src/app/v/[slug]/page.tsx`.

### İlgili test kapıları

`public_web/tests/vitrin-field-schema.test.ts`, `public_web/tests/vixrex-46-alan-davranis-denetimi.test.ts`, `public_web/tests/vixrex-validation-parity.test.ts`, `test/vixrex_46_alan_executor_kapsam_test.dart`, `test/store_publish_payload_builder_test.dart`, `public_web/tests/konum-parite.test.ts`

## Harita Kartı Etiketi — `haritaEtiketi / map_label`

### Ortak kayıt/yayın hattı

- **Tek kaynak → Alan sözleşmesi:** Anahtar, DB kolonu, tip, bölüm, zorunluluk ve doğrulama burada tanımlanır. Kanıt: `shared/vitrin_alanlari.json`, `public_web/src/lib/vitrinFieldSchema.ts`, `lib/config/vitrin_alanlari.g.dart`.
- **Dil / asistan → Vixrex Asistan:** Niyet sözlüğü alanı esnaf dilinden bulur; değer doğrulanır ve canonical kolona çevrilir. Kanıt: `shared/vixrex_niyet_sozlugu.json`, `public_web/src/lib/vixrexNluPipeline.ts`, `lib/services/vixrex_nlu/`.
- **Düzenleme → Manuel editörler:** Flutter manuel panel ve Next.js sahip editörü aynı alan sözleşmesine göre değeri düzenler. Kanıt: `lib/controllers/store_editor_controller.dart`, `lib/services/store_content_editing_service.dart`, `public_web/src/components/owner/VitrinimEditor.tsx`.
- **Taslak → store_working_drafts:** Değişiklik canlı store'a doğrudan yazılmadan çalışma taslağına kaydedilir; sürüm/çakışma kuralları uygulanır. Kanıt: `public_web/src/app/api/owner-draft/route.ts`, `supabase/migrations/20260805100000_add_working_draft_field_update.sql`, `supabase/migrations/20260909231500_lock_owned_assistant_batch_to_46_fields.sql`.
- **DB doğrulama → Assistant field command guard:** Asistan üzerinden gelen değer DB tarafında da alan tipine göre kontrol edilir. Kanıt: `supabase/migrations/20260909234500_validate_assistant_command_values_in_db.sql`.
- **Yayın → publish_working_draft:** Taslak yayın kapılarından geçerse canlı stores verisine taşınır. Kanıt: `lib/services/store_publish_payload_builder.dart`, `public_web/src/app/api/owner-publish/route.ts`, `supabase/migrations/20260805180000_add_publish_and_discard_working_draft.sql`.
- **Canlı okuma → Public vitrin:** Yayınlanan değer PUBLIC_STORE_SELECT üzerinden /v/[slug] yüzüne ulaşır. Kanıt: `public_web/src/lib/publicStoreSelect.ts`, `public_web/src/app/v/[slug]/page.tsx`.

### Alana özel etkiler

- **Public harita kartı metni:** Harita/konum bölümünde görünen etiket metnini değiştirir. Kanıt: `public_web/src/app/v/[slug]/page.tsx`.

### Özellikle etkilemediği şeyler

- Google Maps hedefini, adresi veya GPS koordinatlarını değiştirmez.

### İlgili test kapıları

`public_web/tests/vitrin-field-schema.test.ts`, `public_web/tests/vixrex-46-alan-davranis-denetimi.test.ts`, `public_web/tests/vixrex-validation-parity.test.ts`, `test/vixrex_46_alan_executor_kapsam_test.dart`, `test/store_publish_payload_builder_test.dart`

## Çalışma Saatleri — `calismaSaatleri / working_hours`

### Ortak kayıt/yayın hattı

- **Tek kaynak → Alan sözleşmesi:** Anahtar, DB kolonu, tip, bölüm, zorunluluk ve doğrulama burada tanımlanır. Kanıt: `shared/vitrin_alanlari.json`, `public_web/src/lib/vitrinFieldSchema.ts`, `lib/config/vitrin_alanlari.g.dart`.
- **Dil / asistan → Vixrex Asistan:** Niyet sözlüğü alanı esnaf dilinden bulur; değer doğrulanır ve canonical kolona çevrilir. Kanıt: `shared/vixrex_niyet_sozlugu.json`, `public_web/src/lib/vixrexNluPipeline.ts`, `lib/services/vixrex_nlu/`.
- **Düzenleme → Manuel editörler:** Flutter manuel panel ve Next.js sahip editörü aynı alan sözleşmesine göre değeri düzenler. Kanıt: `lib/controllers/store_editor_controller.dart`, `lib/services/store_content_editing_service.dart`, `public_web/src/components/owner/VitrinimEditor.tsx`.
- **Taslak → store_working_drafts:** Değişiklik canlı store'a doğrudan yazılmadan çalışma taslağına kaydedilir; sürüm/çakışma kuralları uygulanır. Kanıt: `public_web/src/app/api/owner-draft/route.ts`, `supabase/migrations/20260805100000_add_working_draft_field_update.sql`, `supabase/migrations/20260909231500_lock_owned_assistant_batch_to_46_fields.sql`.
- **DB doğrulama → Assistant field command guard:** Asistan üzerinden gelen değer DB tarafında da alan tipine göre kontrol edilir. Kanıt: `supabase/migrations/20260909234500_validate_assistant_command_values_in_db.sql`.
- **Yayın → publish_working_draft:** Taslak yayın kapılarından geçerse canlı stores verisine taşınır. Kanıt: `lib/services/store_publish_payload_builder.dart`, `public_web/src/app/api/owner-publish/route.ts`, `supabase/migrations/20260805180000_add_publish_and_discard_working_draft.sql`.
- **Canlı okuma → Public vitrin:** Yayınlanan değer PUBLIC_STORE_SELECT üzerinden /v/[slug] yüzüne ulaşır. Kanıt: `public_web/src/lib/publicStoreSelect.ts`, `public_web/src/app/v/[slug]/page.tsx`.

### Alana özel etkiler

- **Public açık/kapalı durumu:** Bugünün ve haftanın çalışma saatleri public vitrinde hesaplanır. Kanıt: `public_web/src/app/v/[slug]/page.tsx`, `public_web/src/lib/workingHours.ts`.
- **SEO OpeningHoursSpecification:** Çalışma saatleri schema.org openingHoursSpecification üretimine girer. Kanıt: `public_web/src/lib/workingHours.ts`, `public_web/src/app/v/[slug]/page.tsx`.
- **Randevu çalışma zamanı:** Booking ayarlarının çalışma saatleri yoksa/uygun akışta store çalışma saatleri fallback olarak kullanılabilir. **Koşul:** booking_settings.working_hours varsa public sayfada o değer önceliklidir. Kanıt: `public_web/src/app/v/[slug]/page.tsx`, `public_web/src/app/api/owner-booking-settings/route.ts`.

### Özellikle etkilemediği şeyler

- Randevu kayıtlarını geriye dönük değiştirmez.

### İlgili test kapıları

`public_web/tests/vitrin-field-schema.test.ts`, `public_web/tests/vixrex-46-alan-davranis-denetimi.test.ts`, `public_web/tests/vixrex-validation-parity.test.ts`, `test/vixrex_46_alan_executor_kapsam_test.dart`, `test/store_publish_payload_builder_test.dart`

## Instagram Kullanıcı Adı — `instagram / instagram`

### Ortak kayıt/yayın hattı

- **Tek kaynak → Alan sözleşmesi:** Anahtar, DB kolonu, tip, bölüm, zorunluluk ve doğrulama burada tanımlanır. Kanıt: `shared/vitrin_alanlari.json`, `public_web/src/lib/vitrinFieldSchema.ts`, `lib/config/vitrin_alanlari.g.dart`.
- **Dil / asistan → Vixrex Asistan:** Niyet sözlüğü alanı esnaf dilinden bulur; değer doğrulanır ve canonical kolona çevrilir. Kanıt: `shared/vixrex_niyet_sozlugu.json`, `public_web/src/lib/vixrexNluPipeline.ts`, `lib/services/vixrex_nlu/`.
- **Düzenleme → Manuel editörler:** Flutter manuel panel ve Next.js sahip editörü aynı alan sözleşmesine göre değeri düzenler. Kanıt: `lib/controllers/store_editor_controller.dart`, `lib/services/store_content_editing_service.dart`, `public_web/src/components/owner/VitrinimEditor.tsx`.
- **Taslak → store_working_drafts:** Değişiklik canlı store'a doğrudan yazılmadan çalışma taslağına kaydedilir; sürüm/çakışma kuralları uygulanır. Kanıt: `public_web/src/app/api/owner-draft/route.ts`, `supabase/migrations/20260805100000_add_working_draft_field_update.sql`, `supabase/migrations/20260909231500_lock_owned_assistant_batch_to_46_fields.sql`.
- **DB doğrulama → Assistant field command guard:** Asistan üzerinden gelen değer DB tarafında da alan tipine göre kontrol edilir. Kanıt: `supabase/migrations/20260909234500_validate_assistant_command_values_in_db.sql`.
- **Yayın → publish_working_draft:** Taslak yayın kapılarından geçerse canlı stores verisine taşınır. Kanıt: `lib/services/store_publish_payload_builder.dart`, `public_web/src/app/api/owner-publish/route.ts`, `supabase/migrations/20260805180000_add_publish_and_discard_working_draft.sql`.
- **Canlı okuma → Public vitrin:** Yayınlanan değer PUBLIC_STORE_SELECT üzerinden /v/[slug] yüzüne ulaşır. Kanıt: `public_web/src/lib/publicStoreSelect.ts`, `public_web/src/app/v/[slug]/page.tsx`.

### Alana özel etkiler

- **Public sosyal bağlantı:** Instagram kullanıcı adı/URL'sinden public vitrin bağlantısı üretilir. Kanıt: `public_web/src/app/v/[slug]/page.tsx`.
- **Ürün sosyal bağlantı:** Ürün detayında mağazanın Instagram bağlantısı olarak kullanılabilir. Kanıt: `public_web/src/app/v/[slug]/urun/[productSlug]/page.tsx`, `public_web/src/app/v/[slug]/urun/[productSlug]/PublicProductDetailPage.tsx`.
- **Bağlantı doğrulama:** Store link doğrulama/normalize katmanlarına girer. Kanıt: `lib/services/store_publish_links_validator.dart`.

### Özellikle etkilemediği şeyler

- Bu alanı değiştirmek Instagram OAuth bağlantısını veya ürün importunu kendiliğinden başlatmaz; Instagram sync ayrı alt sistemdir.

### İlgili test kapıları

`public_web/tests/vitrin-field-schema.test.ts`, `public_web/tests/vixrex-46-alan-davranis-denetimi.test.ts`, `public_web/tests/vixrex-validation-parity.test.ts`, `test/vixrex_46_alan_executor_kapsam_test.dart`, `test/store_publish_payload_builder_test.dart`

## Web Sitesi — `website / website`

### Ortak kayıt/yayın hattı

- **Tek kaynak → Alan sözleşmesi:** Anahtar, DB kolonu, tip, bölüm, zorunluluk ve doğrulama burada tanımlanır. Kanıt: `shared/vitrin_alanlari.json`, `public_web/src/lib/vitrinFieldSchema.ts`, `lib/config/vitrin_alanlari.g.dart`.
- **Dil / asistan → Vixrex Asistan:** Niyet sözlüğü alanı esnaf dilinden bulur; değer doğrulanır ve canonical kolona çevrilir. Kanıt: `shared/vixrex_niyet_sozlugu.json`, `public_web/src/lib/vixrexNluPipeline.ts`, `lib/services/vixrex_nlu/`.
- **Düzenleme → Manuel editörler:** Flutter manuel panel ve Next.js sahip editörü aynı alan sözleşmesine göre değeri düzenler. Kanıt: `lib/controllers/store_editor_controller.dart`, `lib/services/store_content_editing_service.dart`, `public_web/src/components/owner/VitrinimEditor.tsx`.
- **Taslak → store_working_drafts:** Değişiklik canlı store'a doğrudan yazılmadan çalışma taslağına kaydedilir; sürüm/çakışma kuralları uygulanır. Kanıt: `public_web/src/app/api/owner-draft/route.ts`, `supabase/migrations/20260805100000_add_working_draft_field_update.sql`, `supabase/migrations/20260909231500_lock_owned_assistant_batch_to_46_fields.sql`.
- **DB doğrulama → Assistant field command guard:** Asistan üzerinden gelen değer DB tarafında da alan tipine göre kontrol edilir. Kanıt: `supabase/migrations/20260909234500_validate_assistant_command_values_in_db.sql`.
- **Yayın → publish_working_draft:** Taslak yayın kapılarından geçerse canlı stores verisine taşınır. Kanıt: `lib/services/store_publish_payload_builder.dart`, `public_web/src/app/api/owner-publish/route.ts`, `supabase/migrations/20260805180000_add_publish_and_discard_working_draft.sql`.
- **Canlı okuma → Public vitrin:** Yayınlanan değer PUBLIC_STORE_SELECT üzerinden /v/[slug] yüzüne ulaşır. Kanıt: `public_web/src/lib/publicStoreSelect.ts`, `public_web/src/app/v/[slug]/page.tsx`.

### Alana özel etkiler

- **Public web sitesi CTA:** Harici web sitesi bağlantısı normalize edilip vitrinde kullanılır. Kanıt: `public_web/src/app/v/[slug]/page.tsx`.
- **Bağlantı doğrulama:** Yayın/link doğrulama kurallarına girer. Kanıt: `lib/services/store_publish_links_validator.dart`.

### Özellikle etkilemediği şeyler

- Vixrex vitrinin canonical URL'sini veya slug'ını değiştirmez.

### İlgili test kapıları

`public_web/tests/vitrin-field-schema.test.ts`, `public_web/tests/vixrex-46-alan-davranis-denetimi.test.ts`, `public_web/tests/vixrex-validation-parity.test.ts`, `test/vixrex_46_alan_executor_kapsam_test.dart`, `test/store_publish_payload_builder_test.dart`

## Google İşletme / Harita Bağlantısı — `haritaLinki / google_business_link`

### Ortak kayıt/yayın hattı

- **Tek kaynak → Alan sözleşmesi:** Anahtar, DB kolonu, tip, bölüm, zorunluluk ve doğrulama burada tanımlanır. Kanıt: `shared/vitrin_alanlari.json`, `public_web/src/lib/vitrinFieldSchema.ts`, `lib/config/vitrin_alanlari.g.dart`.
- **Dil / asistan → Vixrex Asistan:** Niyet sözlüğü alanı esnaf dilinden bulur; değer doğrulanır ve canonical kolona çevrilir. Kanıt: `shared/vixrex_niyet_sozlugu.json`, `public_web/src/lib/vixrexNluPipeline.ts`, `lib/services/vixrex_nlu/`.
- **Düzenleme → Manuel editörler:** Flutter manuel panel ve Next.js sahip editörü aynı alan sözleşmesine göre değeri düzenler. Kanıt: `lib/controllers/store_editor_controller.dart`, `lib/services/store_content_editing_service.dart`, `public_web/src/components/owner/VitrinimEditor.tsx`.
- **Taslak → store_working_drafts:** Değişiklik canlı store'a doğrudan yazılmadan çalışma taslağına kaydedilir; sürüm/çakışma kuralları uygulanır. Kanıt: `public_web/src/app/api/owner-draft/route.ts`, `supabase/migrations/20260805100000_add_working_draft_field_update.sql`, `supabase/migrations/20260909231500_lock_owned_assistant_batch_to_46_fields.sql`.
- **DB doğrulama → Assistant field command guard:** Asistan üzerinden gelen değer DB tarafında da alan tipine göre kontrol edilir. Kanıt: `supabase/migrations/20260909234500_validate_assistant_command_values_in_db.sql`.
- **Yayın → publish_working_draft:** Taslak yayın kapılarından geçerse canlı stores verisine taşınır. Kanıt: `lib/services/store_publish_payload_builder.dart`, `public_web/src/app/api/owner-publish/route.ts`, `supabase/migrations/20260805180000_add_publish_and_discard_working_draft.sql`.
- **Canlı okuma → Public vitrin:** Yayınlanan değer PUBLIC_STORE_SELECT üzerinden /v/[slug] yüzüne ulaşır. Kanıt: `public_web/src/lib/publicStoreSelect.ts`, `public_web/src/app/v/[slug]/page.tsx`.

### Alana özel etkiler

- **Google İşletme bağlantısı:** Public vitrine googleBusinessLink olarak gider. Kanıt: `public_web/src/app/v/[slug]/page.tsx`.
- **Güvenlik/allowlist:** DB kısıtı Google/g.page/goo.gl gibi izinli güvenli alanları zorlar. Kanıt: `supabase/migrations_arsiv/20260622000002_add_google_visibility_and_blog.sql`, `supabase_schema.sql`.

### Özellikle etkilemediği şeyler

- GPS enlem/boylamını değiştirmez.
- Yol tarifi CTA'sı koordinat/adres hattından ayrıca üretilebilir.

### İlgili test kapıları

`public_web/tests/vitrin-field-schema.test.ts`, `public_web/tests/vixrex-46-alan-davranis-denetimi.test.ts`, `public_web/tests/vixrex-validation-parity.test.ts`, `test/vixrex_46_alan_executor_kapsam_test.dart`, `test/store_publish_payload_builder_test.dart`

## Konum — Enlem — `enlem / latitude`

### Ortak kayıt/yayın hattı

- **Tek kaynak → Alan sözleşmesi:** Anahtar, DB kolonu, tip, bölüm, zorunluluk ve doğrulama burada tanımlanır. Kanıt: `shared/vitrin_alanlari.json`, `public_web/src/lib/vitrinFieldSchema.ts`, `lib/config/vitrin_alanlari.g.dart`.
- **Dil / asistan → Vixrex Asistan:** Niyet sözlüğü alanı esnaf dilinden bulur; değer doğrulanır ve canonical kolona çevrilir. Kanıt: `shared/vixrex_niyet_sozlugu.json`, `public_web/src/lib/vixrexNluPipeline.ts`, `lib/services/vixrex_nlu/`.
- **Düzenleme → Manuel editörler:** Flutter manuel panel ve Next.js sahip editörü aynı alan sözleşmesine göre değeri düzenler. Kanıt: `lib/controllers/store_editor_controller.dart`, `lib/services/store_content_editing_service.dart`, `public_web/src/components/owner/VitrinimEditor.tsx`.
- **Taslak → store_working_drafts:** Değişiklik canlı store'a doğrudan yazılmadan çalışma taslağına kaydedilir; sürüm/çakışma kuralları uygulanır. Kanıt: `public_web/src/app/api/owner-draft/route.ts`, `supabase/migrations/20260805100000_add_working_draft_field_update.sql`, `supabase/migrations/20260909231500_lock_owned_assistant_batch_to_46_fields.sql`.
- **DB doğrulama → Assistant field command guard:** Asistan üzerinden gelen değer DB tarafında da alan tipine göre kontrol edilir. Kanıt: `supabase/migrations/20260909234500_validate_assistant_command_values_in_db.sql`.
- **Yayın → publish_working_draft:** Taslak yayın kapılarından geçerse canlı stores verisine taşınır. Kanıt: `lib/services/store_publish_payload_builder.dart`, `public_web/src/app/api/owner-publish/route.ts`, `supabase/migrations/20260805180000_add_publish_and_discard_working_draft.sql`.
- **Canlı okuma → Public vitrin:** Yayınlanan değer PUBLIC_STORE_SELECT üzerinden /v/[slug] yüzüne ulaşır. Kanıt: `public_web/src/lib/publicStoreSelect.ts`, `public_web/src/app/v/[slug]/page.tsx`.

### Alana özel etkiler

- **Google Maps hedefi:** Adres yerine kesin koordinatla yol tarifi ve embed URL üretimine katılır. Kanıt: `public_web/src/app/v/[slug]/page.tsx`.
- **SEO GeoCoordinates:** Adres + iki koordinat mevcutsa fiziksel işletme structured data'sına GeoCoordinates eklenir. Kanıt: `lib/services/seo_service.dart`, `test/seo_schema_builder_test.dart`.
- **GPS / ters geocode akışı:** Konum alma ve ters geocode servisleriyle birlikte çalışır. Kanıt: `lib/services/location_service.dart`, `public_web/src/app/api/location/reverse-geocode/route.ts`, `lib/controllers/mixins/store_location_mixin.dart`.

### Özellikle etkilemediği şeyler

- Tek koordinat tek başına tam fiziksel konum zincirini tamamlamaz; latitude + longitude birlikte gerekir.

### İlgili test kapıları

`public_web/tests/vitrin-field-schema.test.ts`, `public_web/tests/vixrex-46-alan-davranis-denetimi.test.ts`, `public_web/tests/vixrex-validation-parity.test.ts`, `test/vixrex_46_alan_executor_kapsam_test.dart`, `test/store_publish_payload_builder_test.dart`

## Konum — Boylam — `boylam / longitude`

### Ortak kayıt/yayın hattı

- **Tek kaynak → Alan sözleşmesi:** Anahtar, DB kolonu, tip, bölüm, zorunluluk ve doğrulama burada tanımlanır. Kanıt: `shared/vitrin_alanlari.json`, `public_web/src/lib/vitrinFieldSchema.ts`, `lib/config/vitrin_alanlari.g.dart`.
- **Dil / asistan → Vixrex Asistan:** Niyet sözlüğü alanı esnaf dilinden bulur; değer doğrulanır ve canonical kolona çevrilir. Kanıt: `shared/vixrex_niyet_sozlugu.json`, `public_web/src/lib/vixrexNluPipeline.ts`, `lib/services/vixrex_nlu/`.
- **Düzenleme → Manuel editörler:** Flutter manuel panel ve Next.js sahip editörü aynı alan sözleşmesine göre değeri düzenler. Kanıt: `lib/controllers/store_editor_controller.dart`, `lib/services/store_content_editing_service.dart`, `public_web/src/components/owner/VitrinimEditor.tsx`.
- **Taslak → store_working_drafts:** Değişiklik canlı store'a doğrudan yazılmadan çalışma taslağına kaydedilir; sürüm/çakışma kuralları uygulanır. Kanıt: `public_web/src/app/api/owner-draft/route.ts`, `supabase/migrations/20260805100000_add_working_draft_field_update.sql`, `supabase/migrations/20260909231500_lock_owned_assistant_batch_to_46_fields.sql`.
- **DB doğrulama → Assistant field command guard:** Asistan üzerinden gelen değer DB tarafında da alan tipine göre kontrol edilir. Kanıt: `supabase/migrations/20260909234500_validate_assistant_command_values_in_db.sql`.
- **Yayın → publish_working_draft:** Taslak yayın kapılarından geçerse canlı stores verisine taşınır. Kanıt: `lib/services/store_publish_payload_builder.dart`, `public_web/src/app/api/owner-publish/route.ts`, `supabase/migrations/20260805180000_add_publish_and_discard_working_draft.sql`.
- **Canlı okuma → Public vitrin:** Yayınlanan değer PUBLIC_STORE_SELECT üzerinden /v/[slug] yüzüne ulaşır. Kanıt: `public_web/src/lib/publicStoreSelect.ts`, `public_web/src/app/v/[slug]/page.tsx`.

### Alana özel etkiler

- **Google Maps hedefi:** Adres yerine kesin koordinatla yol tarifi ve embed URL üretimine katılır. Kanıt: `public_web/src/app/v/[slug]/page.tsx`.
- **SEO GeoCoordinates:** Adres + iki koordinat mevcutsa fiziksel işletme structured data'sına GeoCoordinates eklenir. Kanıt: `lib/services/seo_service.dart`, `test/seo_schema_builder_test.dart`.
- **GPS / ters geocode akışı:** Konum alma ve ters geocode servisleriyle birlikte çalışır. Kanıt: `lib/services/location_service.dart`, `public_web/src/app/api/location/reverse-geocode/route.ts`, `lib/controllers/mixins/store_location_mixin.dart`.

### Özellikle etkilemediği şeyler

- Tek koordinat tek başına tam fiziksel konum zincirini tamamlamaz; latitude + longitude birlikte gerekir.

### İlgili test kapıları

`public_web/tests/vitrin-field-schema.test.ts`, `public_web/tests/vixrex-46-alan-davranis-denetimi.test.ts`, `public_web/tests/vixrex-validation-parity.test.ts`, `test/vixrex_46_alan_executor_kapsam_test.dart`, `test/store_publish_payload_builder_test.dart`

## Kategori Bölümü Başlığı — `kategoriBolumBaslik / category_section_title`

### Ortak kayıt/yayın hattı

- **Tek kaynak → Alan sözleşmesi:** Anahtar, DB kolonu, tip, bölüm, zorunluluk ve doğrulama burada tanımlanır. Kanıt: `shared/vitrin_alanlari.json`, `public_web/src/lib/vitrinFieldSchema.ts`, `lib/config/vitrin_alanlari.g.dart`.
- **Dil / asistan → Vixrex Asistan:** Niyet sözlüğü alanı esnaf dilinden bulur; değer doğrulanır ve canonical kolona çevrilir. Kanıt: `shared/vixrex_niyet_sozlugu.json`, `public_web/src/lib/vixrexNluPipeline.ts`, `lib/services/vixrex_nlu/`.
- **Düzenleme → Manuel editörler:** Flutter manuel panel ve Next.js sahip editörü aynı alan sözleşmesine göre değeri düzenler. Kanıt: `lib/controllers/store_editor_controller.dart`, `lib/services/store_content_editing_service.dart`, `public_web/src/components/owner/VitrinimEditor.tsx`.
- **Taslak → store_working_drafts:** Değişiklik canlı store'a doğrudan yazılmadan çalışma taslağına kaydedilir; sürüm/çakışma kuralları uygulanır. Kanıt: `public_web/src/app/api/owner-draft/route.ts`, `supabase/migrations/20260805100000_add_working_draft_field_update.sql`, `supabase/migrations/20260909231500_lock_owned_assistant_batch_to_46_fields.sql`.
- **DB doğrulama → Assistant field command guard:** Asistan üzerinden gelen değer DB tarafında da alan tipine göre kontrol edilir. Kanıt: `supabase/migrations/20260909234500_validate_assistant_command_values_in_db.sql`.
- **Yayın → publish_working_draft:** Taslak yayın kapılarından geçerse canlı stores verisine taşınır. Kanıt: `lib/services/store_publish_payload_builder.dart`, `public_web/src/app/api/owner-publish/route.ts`, `supabase/migrations/20260805180000_add_publish_and_discard_working_draft.sql`.
- **Canlı okuma → Public vitrin:** Yayınlanan değer PUBLIC_STORE_SELECT üzerinden /v/[slug] yüzüne ulaşır. Kanıt: `public_web/src/lib/publicStoreSelect.ts`, `public_web/src/app/v/[slug]/page.tsx`.

### Alana özel etkiler

- **Public kategori bölümü başlığı:** Vitrindeki kategori bölümünün görünen başlığını değiştirir. Kanıt: `public_web/src/app/v/[slug]/page.tsx`.

### Özellikle etkilemediği şeyler

- Ürün kategorilerini veya işletme kategorisini değiştirmez.

### İlgili test kapıları

`public_web/tests/vitrin-field-schema.test.ts`, `public_web/tests/vixrex-46-alan-davranis-denetimi.test.ts`, `public_web/tests/vixrex-validation-parity.test.ts`, `test/vixrex_46_alan_executor_kapsam_test.dart`, `test/store_publish_payload_builder_test.dart`

## Ürün Bölümü Başlığı — `urunBolumBaslik / product_section_title`

### Ortak kayıt/yayın hattı

- **Tek kaynak → Alan sözleşmesi:** Anahtar, DB kolonu, tip, bölüm, zorunluluk ve doğrulama burada tanımlanır. Kanıt: `shared/vitrin_alanlari.json`, `public_web/src/lib/vitrinFieldSchema.ts`, `lib/config/vitrin_alanlari.g.dart`.
- **Dil / asistan → Vixrex Asistan:** Niyet sözlüğü alanı esnaf dilinden bulur; değer doğrulanır ve canonical kolona çevrilir. Kanıt: `shared/vixrex_niyet_sozlugu.json`, `public_web/src/lib/vixrexNluPipeline.ts`, `lib/services/vixrex_nlu/`.
- **Düzenleme → Manuel editörler:** Flutter manuel panel ve Next.js sahip editörü aynı alan sözleşmesine göre değeri düzenler. Kanıt: `lib/controllers/store_editor_controller.dart`, `lib/services/store_content_editing_service.dart`, `public_web/src/components/owner/VitrinimEditor.tsx`.
- **Taslak → store_working_drafts:** Değişiklik canlı store'a doğrudan yazılmadan çalışma taslağına kaydedilir; sürüm/çakışma kuralları uygulanır. Kanıt: `public_web/src/app/api/owner-draft/route.ts`, `supabase/migrations/20260805100000_add_working_draft_field_update.sql`, `supabase/migrations/20260909231500_lock_owned_assistant_batch_to_46_fields.sql`.
- **DB doğrulama → Assistant field command guard:** Asistan üzerinden gelen değer DB tarafında da alan tipine göre kontrol edilir. Kanıt: `supabase/migrations/20260909234500_validate_assistant_command_values_in_db.sql`.
- **Yayın → publish_working_draft:** Taslak yayın kapılarından geçerse canlı stores verisine taşınır. Kanıt: `lib/services/store_publish_payload_builder.dart`, `public_web/src/app/api/owner-publish/route.ts`, `supabase/migrations/20260805180000_add_publish_and_discard_working_draft.sql`.
- **Canlı okuma → Public vitrin:** Yayınlanan değer PUBLIC_STORE_SELECT üzerinden /v/[slug] yüzüne ulaşır. Kanıt: `public_web/src/lib/publicStoreSelect.ts`, `public_web/src/app/v/[slug]/page.tsx`.

### Alana özel etkiler

- **Public ürün bölümü başlığı:** Vitrindeki ürünler bölümünün görünen başlığını değiştirir. Kanıt: `public_web/src/app/v/[slug]/page.tsx`.

### Özellikle etkilemediği şeyler

- products tablosunu veya ürün kategorilerini değiştirmez.

### İlgili test kapıları

`public_web/tests/vitrin-field-schema.test.ts`, `public_web/tests/vixrex-46-alan-davranis-denetimi.test.ts`, `public_web/tests/vixrex-validation-parity.test.ts`, `test/vixrex_46_alan_executor_kapsam_test.dart`, `test/store_publish_payload_builder_test.dart`

## Kampanya Etiketi — `bantEtiket / featured_banner_label`

### Ortak kayıt/yayın hattı

- **Tek kaynak → Alan sözleşmesi:** Anahtar, DB kolonu, tip, bölüm, zorunluluk ve doğrulama burada tanımlanır. Kanıt: `shared/vitrin_alanlari.json`, `public_web/src/lib/vitrinFieldSchema.ts`, `lib/config/vitrin_alanlari.g.dart`.
- **Dil / asistan → Vixrex Asistan:** Niyet sözlüğü alanı esnaf dilinden bulur; değer doğrulanır ve canonical kolona çevrilir. Kanıt: `shared/vixrex_niyet_sozlugu.json`, `public_web/src/lib/vixrexNluPipeline.ts`, `lib/services/vixrex_nlu/`.
- **Düzenleme → Manuel editörler:** Flutter manuel panel ve Next.js sahip editörü aynı alan sözleşmesine göre değeri düzenler. Kanıt: `lib/controllers/store_editor_controller.dart`, `lib/services/store_content_editing_service.dart`, `public_web/src/components/owner/VitrinimEditor.tsx`.
- **Taslak → store_working_drafts:** Değişiklik canlı store'a doğrudan yazılmadan çalışma taslağına kaydedilir; sürüm/çakışma kuralları uygulanır. Kanıt: `public_web/src/app/api/owner-draft/route.ts`, `supabase/migrations/20260805100000_add_working_draft_field_update.sql`, `supabase/migrations/20260909231500_lock_owned_assistant_batch_to_46_fields.sql`.
- **DB doğrulama → Assistant field command guard:** Asistan üzerinden gelen değer DB tarafında da alan tipine göre kontrol edilir. Kanıt: `supabase/migrations/20260909234500_validate_assistant_command_values_in_db.sql`.
- **Yayın → publish_working_draft:** Taslak yayın kapılarından geçerse canlı stores verisine taşınır. Kanıt: `lib/services/store_publish_payload_builder.dart`, `public_web/src/app/api/owner-publish/route.ts`, `supabase/migrations/20260805180000_add_publish_and_discard_working_draft.sql`.
- **Canlı okuma → Public vitrin:** Yayınlanan değer PUBLIC_STORE_SELECT üzerinden /v/[slug] yüzüne ulaşır. Kanıt: `public_web/src/lib/publicStoreSelect.ts`, `public_web/src/app/v/[slug]/page.tsx`.

### Alana özel etkiler

- **Featured kampanya bandı:** Kampanya etiketi featuredBanner nesnesine girer ve public kampanya bandını değiştirir. Kanıt: `public_web/src/app/v/[slug]/page.tsx`, `public_web/src/app/v/[slug]/components/CampaignEditor.tsx`.

### İlgili test kapıları

`public_web/tests/vitrin-field-schema.test.ts`, `public_web/tests/vixrex-46-alan-davranis-denetimi.test.ts`, `public_web/tests/vixrex-validation-parity.test.ts`, `test/vixrex_46_alan_executor_kapsam_test.dart`, `test/store_publish_payload_builder_test.dart`, `public_web/tests/dilim2-featured-banner-contract.test.ts`

## Kampanya Başlığı — `bantBaslik / featured_banner_title`

### Ortak kayıt/yayın hattı

- **Tek kaynak → Alan sözleşmesi:** Anahtar, DB kolonu, tip, bölüm, zorunluluk ve doğrulama burada tanımlanır. Kanıt: `shared/vitrin_alanlari.json`, `public_web/src/lib/vitrinFieldSchema.ts`, `lib/config/vitrin_alanlari.g.dart`.
- **Dil / asistan → Vixrex Asistan:** Niyet sözlüğü alanı esnaf dilinden bulur; değer doğrulanır ve canonical kolona çevrilir. Kanıt: `shared/vixrex_niyet_sozlugu.json`, `public_web/src/lib/vixrexNluPipeline.ts`, `lib/services/vixrex_nlu/`.
- **Düzenleme → Manuel editörler:** Flutter manuel panel ve Next.js sahip editörü aynı alan sözleşmesine göre değeri düzenler. Kanıt: `lib/controllers/store_editor_controller.dart`, `lib/services/store_content_editing_service.dart`, `public_web/src/components/owner/VitrinimEditor.tsx`.
- **Taslak → store_working_drafts:** Değişiklik canlı store'a doğrudan yazılmadan çalışma taslağına kaydedilir; sürüm/çakışma kuralları uygulanır. Kanıt: `public_web/src/app/api/owner-draft/route.ts`, `supabase/migrations/20260805100000_add_working_draft_field_update.sql`, `supabase/migrations/20260909231500_lock_owned_assistant_batch_to_46_fields.sql`.
- **DB doğrulama → Assistant field command guard:** Asistan üzerinden gelen değer DB tarafında da alan tipine göre kontrol edilir. Kanıt: `supabase/migrations/20260909234500_validate_assistant_command_values_in_db.sql`.
- **Yayın → publish_working_draft:** Taslak yayın kapılarından geçerse canlı stores verisine taşınır. Kanıt: `lib/services/store_publish_payload_builder.dart`, `public_web/src/app/api/owner-publish/route.ts`, `supabase/migrations/20260805180000_add_publish_and_discard_working_draft.sql`.
- **Canlı okuma → Public vitrin:** Yayınlanan değer PUBLIC_STORE_SELECT üzerinden /v/[slug] yüzüne ulaşır. Kanıt: `public_web/src/lib/publicStoreSelect.ts`, `public_web/src/app/v/[slug]/page.tsx`.

### Alana özel etkiler

- **Featured kampanya bandı:** Kampanya başlığı featuredBanner nesnesine girer ve public kampanya bandını değiştirir. Kanıt: `public_web/src/app/v/[slug]/page.tsx`, `public_web/src/app/v/[slug]/components/CampaignEditor.tsx`.

### İlgili test kapıları

`public_web/tests/vitrin-field-schema.test.ts`, `public_web/tests/vixrex-46-alan-davranis-denetimi.test.ts`, `public_web/tests/vixrex-validation-parity.test.ts`, `test/vixrex_46_alan_executor_kapsam_test.dart`, `test/store_publish_payload_builder_test.dart`, `public_web/tests/dilim2-featured-banner-contract.test.ts`

## Kampanya Açıklaması — `bantAciklama / featured_banner_description`

### Ortak kayıt/yayın hattı

- **Tek kaynak → Alan sözleşmesi:** Anahtar, DB kolonu, tip, bölüm, zorunluluk ve doğrulama burada tanımlanır. Kanıt: `shared/vitrin_alanlari.json`, `public_web/src/lib/vitrinFieldSchema.ts`, `lib/config/vitrin_alanlari.g.dart`.
- **Dil / asistan → Vixrex Asistan:** Niyet sözlüğü alanı esnaf dilinden bulur; değer doğrulanır ve canonical kolona çevrilir. Kanıt: `shared/vixrex_niyet_sozlugu.json`, `public_web/src/lib/vixrexNluPipeline.ts`, `lib/services/vixrex_nlu/`.
- **Düzenleme → Manuel editörler:** Flutter manuel panel ve Next.js sahip editörü aynı alan sözleşmesine göre değeri düzenler. Kanıt: `lib/controllers/store_editor_controller.dart`, `lib/services/store_content_editing_service.dart`, `public_web/src/components/owner/VitrinimEditor.tsx`.
- **Taslak → store_working_drafts:** Değişiklik canlı store'a doğrudan yazılmadan çalışma taslağına kaydedilir; sürüm/çakışma kuralları uygulanır. Kanıt: `public_web/src/app/api/owner-draft/route.ts`, `supabase/migrations/20260805100000_add_working_draft_field_update.sql`, `supabase/migrations/20260909231500_lock_owned_assistant_batch_to_46_fields.sql`.
- **DB doğrulama → Assistant field command guard:** Asistan üzerinden gelen değer DB tarafında da alan tipine göre kontrol edilir. Kanıt: `supabase/migrations/20260909234500_validate_assistant_command_values_in_db.sql`.
- **Yayın → publish_working_draft:** Taslak yayın kapılarından geçerse canlı stores verisine taşınır. Kanıt: `lib/services/store_publish_payload_builder.dart`, `public_web/src/app/api/owner-publish/route.ts`, `supabase/migrations/20260805180000_add_publish_and_discard_working_draft.sql`.
- **Canlı okuma → Public vitrin:** Yayınlanan değer PUBLIC_STORE_SELECT üzerinden /v/[slug] yüzüne ulaşır. Kanıt: `public_web/src/lib/publicStoreSelect.ts`, `public_web/src/app/v/[slug]/page.tsx`.

### Alana özel etkiler

- **Featured kampanya bandı:** Kampanya açıklaması featuredBanner nesnesine girer ve public kampanya bandını değiştirir. Kanıt: `public_web/src/app/v/[slug]/page.tsx`, `public_web/src/app/v/[slug]/components/CampaignEditor.tsx`.

### İlgili test kapıları

`public_web/tests/vitrin-field-schema.test.ts`, `public_web/tests/vixrex-46-alan-davranis-denetimi.test.ts`, `public_web/tests/vixrex-validation-parity.test.ts`, `test/vixrex_46_alan_executor_kapsam_test.dart`, `test/store_publish_payload_builder_test.dart`, `public_web/tests/dilim2-featured-banner-contract.test.ts`

## Kampanya Görseli — `bantGorsel / featured_banner_image_url`

### Ortak kayıt/yayın hattı

- **Tek kaynak → Alan sözleşmesi:** Anahtar, DB kolonu, tip, bölüm, zorunluluk ve doğrulama burada tanımlanır. Kanıt: `shared/vitrin_alanlari.json`, `public_web/src/lib/vitrinFieldSchema.ts`, `lib/config/vitrin_alanlari.g.dart`.
- **Dil / asistan → Vixrex Asistan:** Niyet sözlüğü alanı esnaf dilinden bulur; değer doğrulanır ve canonical kolona çevrilir. Kanıt: `shared/vixrex_niyet_sozlugu.json`, `public_web/src/lib/vixrexNluPipeline.ts`, `lib/services/vixrex_nlu/`.
- **Düzenleme → Manuel editörler:** Flutter manuel panel ve Next.js sahip editörü aynı alan sözleşmesine göre değeri düzenler. Kanıt: `lib/controllers/store_editor_controller.dart`, `lib/services/store_content_editing_service.dart`, `public_web/src/components/owner/VitrinimEditor.tsx`.
- **Taslak → store_working_drafts:** Değişiklik canlı store'a doğrudan yazılmadan çalışma taslağına kaydedilir; sürüm/çakışma kuralları uygulanır. Kanıt: `public_web/src/app/api/owner-draft/route.ts`, `supabase/migrations/20260805100000_add_working_draft_field_update.sql`, `supabase/migrations/20260909231500_lock_owned_assistant_batch_to_46_fields.sql`.
- **DB doğrulama → Assistant field command guard:** Asistan üzerinden gelen değer DB tarafında da alan tipine göre kontrol edilir. Kanıt: `supabase/migrations/20260909234500_validate_assistant_command_values_in_db.sql`.
- **Yayın → publish_working_draft:** Taslak yayın kapılarından geçerse canlı stores verisine taşınır. Kanıt: `lib/services/store_publish_payload_builder.dart`, `public_web/src/app/api/owner-publish/route.ts`, `supabase/migrations/20260805180000_add_publish_and_discard_working_draft.sql`.
- **Canlı okuma → Public vitrin:** Yayınlanan değer PUBLIC_STORE_SELECT üzerinden /v/[slug] yüzüne ulaşır. Kanıt: `public_web/src/lib/publicStoreSelect.ts`, `public_web/src/app/v/[slug]/page.tsx`.

### Alana özel etkiler

- **Featured kampanya bandı:** Kampanya görseli featuredBanner nesnesine girer ve public kampanya bandını değiştirir. Kanıt: `public_web/src/app/v/[slug]/page.tsx`, `public_web/src/app/v/[slug]/components/CampaignEditor.tsx`.

### İlgili test kapıları

`public_web/tests/vitrin-field-schema.test.ts`, `public_web/tests/vixrex-46-alan-davranis-denetimi.test.ts`, `public_web/tests/vixrex-validation-parity.test.ts`, `test/vixrex_46_alan_executor_kapsam_test.dart`, `test/store_publish_payload_builder_test.dart`, `public_web/tests/dilim2-featured-banner-contract.test.ts`

## Kampanya Fiyat Metni — `bantFiyat / featured_banner_price_text`

### Ortak kayıt/yayın hattı

- **Tek kaynak → Alan sözleşmesi:** Anahtar, DB kolonu, tip, bölüm, zorunluluk ve doğrulama burada tanımlanır. Kanıt: `shared/vitrin_alanlari.json`, `public_web/src/lib/vitrinFieldSchema.ts`, `lib/config/vitrin_alanlari.g.dart`.
- **Dil / asistan → Vixrex Asistan:** Niyet sözlüğü alanı esnaf dilinden bulur; değer doğrulanır ve canonical kolona çevrilir. Kanıt: `shared/vixrex_niyet_sozlugu.json`, `public_web/src/lib/vixrexNluPipeline.ts`, `lib/services/vixrex_nlu/`.
- **Düzenleme → Manuel editörler:** Flutter manuel panel ve Next.js sahip editörü aynı alan sözleşmesine göre değeri düzenler. Kanıt: `lib/controllers/store_editor_controller.dart`, `lib/services/store_content_editing_service.dart`, `public_web/src/components/owner/VitrinimEditor.tsx`.
- **Taslak → store_working_drafts:** Değişiklik canlı store'a doğrudan yazılmadan çalışma taslağına kaydedilir; sürüm/çakışma kuralları uygulanır. Kanıt: `public_web/src/app/api/owner-draft/route.ts`, `supabase/migrations/20260805100000_add_working_draft_field_update.sql`, `supabase/migrations/20260909231500_lock_owned_assistant_batch_to_46_fields.sql`.
- **DB doğrulama → Assistant field command guard:** Asistan üzerinden gelen değer DB tarafında da alan tipine göre kontrol edilir. Kanıt: `supabase/migrations/20260909234500_validate_assistant_command_values_in_db.sql`.
- **Yayın → publish_working_draft:** Taslak yayın kapılarından geçerse canlı stores verisine taşınır. Kanıt: `lib/services/store_publish_payload_builder.dart`, `public_web/src/app/api/owner-publish/route.ts`, `supabase/migrations/20260805180000_add_publish_and_discard_working_draft.sql`.
- **Canlı okuma → Public vitrin:** Yayınlanan değer PUBLIC_STORE_SELECT üzerinden /v/[slug] yüzüne ulaşır. Kanıt: `public_web/src/lib/publicStoreSelect.ts`, `public_web/src/app/v/[slug]/page.tsx`.

### Alana özel etkiler

- **Featured kampanya bandı:** Kampanya fiyat metni featuredBanner nesnesine girer ve public kampanya bandını değiştirir. Kanıt: `public_web/src/app/v/[slug]/page.tsx`, `public_web/src/app/v/[slug]/components/CampaignEditor.tsx`.

### Özellikle etkilemediği şeyler

- Ürün fiyatını, stokunu veya PayTR fiyatını değiştirmez.

### İlgili test kapıları

`public_web/tests/vitrin-field-schema.test.ts`, `public_web/tests/vixrex-46-alan-davranis-denetimi.test.ts`, `public_web/tests/vixrex-validation-parity.test.ts`, `test/vixrex_46_alan_executor_kapsam_test.dart`, `test/store_publish_payload_builder_test.dart`, `public_web/tests/dilim2-featured-banner-contract.test.ts`

## Hakkımızda Üst Başlık — `hakkindaUstBaslik / about_kicker`

### Ortak kayıt/yayın hattı

- **Tek kaynak → Alan sözleşmesi:** Anahtar, DB kolonu, tip, bölüm, zorunluluk ve doğrulama burada tanımlanır. Kanıt: `shared/vitrin_alanlari.json`, `public_web/src/lib/vitrinFieldSchema.ts`, `lib/config/vitrin_alanlari.g.dart`.
- **Dil / asistan → Vixrex Asistan:** Niyet sözlüğü alanı esnaf dilinden bulur; değer doğrulanır ve canonical kolona çevrilir. Kanıt: `shared/vixrex_niyet_sozlugu.json`, `public_web/src/lib/vixrexNluPipeline.ts`, `lib/services/vixrex_nlu/`.
- **Düzenleme → Manuel editörler:** Flutter manuel panel ve Next.js sahip editörü aynı alan sözleşmesine göre değeri düzenler. Kanıt: `lib/controllers/store_editor_controller.dart`, `lib/services/store_content_editing_service.dart`, `public_web/src/components/owner/VitrinimEditor.tsx`.
- **Taslak → store_working_drafts:** Değişiklik canlı store'a doğrudan yazılmadan çalışma taslağına kaydedilir; sürüm/çakışma kuralları uygulanır. Kanıt: `public_web/src/app/api/owner-draft/route.ts`, `supabase/migrations/20260805100000_add_working_draft_field_update.sql`, `supabase/migrations/20260909231500_lock_owned_assistant_batch_to_46_fields.sql`.
- **DB doğrulama → Assistant field command guard:** Asistan üzerinden gelen değer DB tarafında da alan tipine göre kontrol edilir. Kanıt: `supabase/migrations/20260909234500_validate_assistant_command_values_in_db.sql`.
- **Yayın → publish_working_draft:** Taslak yayın kapılarından geçerse canlı stores verisine taşınır. Kanıt: `lib/services/store_publish_payload_builder.dart`, `public_web/src/app/api/owner-publish/route.ts`, `supabase/migrations/20260805180000_add_publish_and_discard_working_draft.sql`.
- **Canlı okuma → Public vitrin:** Yayınlanan değer PUBLIC_STORE_SELECT üzerinden /v/[slug] yüzüne ulaşır. Kanıt: `public_web/src/lib/publicStoreSelect.ts`, `public_web/src/app/v/[slug]/page.tsx`.

### Alana özel etkiler

- **Hakkımızda bölümü:** Public Hakkımızda bölümünün üst başlığını değiştirir. Kanıt: `public_web/src/app/v/[slug]/page.tsx`, `public_web/src/app/v/[slug]/components/AboutEditor.tsx`.

### İlgili test kapıları

`public_web/tests/vitrin-field-schema.test.ts`, `public_web/tests/vixrex-46-alan-davranis-denetimi.test.ts`, `public_web/tests/vixrex-validation-parity.test.ts`, `test/vixrex_46_alan_executor_kapsam_test.dart`, `test/store_publish_payload_builder_test.dart`

## Hakkımızda Başlığı — `hakkindaBaslik / about_title`

### Ortak kayıt/yayın hattı

- **Tek kaynak → Alan sözleşmesi:** Anahtar, DB kolonu, tip, bölüm, zorunluluk ve doğrulama burada tanımlanır. Kanıt: `shared/vitrin_alanlari.json`, `public_web/src/lib/vitrinFieldSchema.ts`, `lib/config/vitrin_alanlari.g.dart`.
- **Dil / asistan → Vixrex Asistan:** Niyet sözlüğü alanı esnaf dilinden bulur; değer doğrulanır ve canonical kolona çevrilir. Kanıt: `shared/vixrex_niyet_sozlugu.json`, `public_web/src/lib/vixrexNluPipeline.ts`, `lib/services/vixrex_nlu/`.
- **Düzenleme → Manuel editörler:** Flutter manuel panel ve Next.js sahip editörü aynı alan sözleşmesine göre değeri düzenler. Kanıt: `lib/controllers/store_editor_controller.dart`, `lib/services/store_content_editing_service.dart`, `public_web/src/components/owner/VitrinimEditor.tsx`.
- **Taslak → store_working_drafts:** Değişiklik canlı store'a doğrudan yazılmadan çalışma taslağına kaydedilir; sürüm/çakışma kuralları uygulanır. Kanıt: `public_web/src/app/api/owner-draft/route.ts`, `supabase/migrations/20260805100000_add_working_draft_field_update.sql`, `supabase/migrations/20260909231500_lock_owned_assistant_batch_to_46_fields.sql`.
- **DB doğrulama → Assistant field command guard:** Asistan üzerinden gelen değer DB tarafında da alan tipine göre kontrol edilir. Kanıt: `supabase/migrations/20260909234500_validate_assistant_command_values_in_db.sql`.
- **Yayın → publish_working_draft:** Taslak yayın kapılarından geçerse canlı stores verisine taşınır. Kanıt: `lib/services/store_publish_payload_builder.dart`, `public_web/src/app/api/owner-publish/route.ts`, `supabase/migrations/20260805180000_add_publish_and_discard_working_draft.sql`.
- **Canlı okuma → Public vitrin:** Yayınlanan değer PUBLIC_STORE_SELECT üzerinden /v/[slug] yüzüne ulaşır. Kanıt: `public_web/src/lib/publicStoreSelect.ts`, `public_web/src/app/v/[slug]/page.tsx`.

### Alana özel etkiler

- **Hakkımızda bölümü:** Public Hakkımızda bölümünün ana başlığını değiştirir. Kanıt: `public_web/src/app/v/[slug]/page.tsx`, `public_web/src/app/v/[slug]/components/AboutEditor.tsx`.

### İlgili test kapıları

`public_web/tests/vitrin-field-schema.test.ts`, `public_web/tests/vixrex-46-alan-davranis-denetimi.test.ts`, `public_web/tests/vixrex-validation-parity.test.ts`, `test/vixrex_46_alan_executor_kapsam_test.dart`, `test/store_publish_payload_builder_test.dart`

## Hakkımızda Yazısı — `hakkindaMetin / corporate_bio`

### Ortak kayıt/yayın hattı

- **Tek kaynak → Alan sözleşmesi:** Anahtar, DB kolonu, tip, bölüm, zorunluluk ve doğrulama burada tanımlanır. Kanıt: `shared/vitrin_alanlari.json`, `public_web/src/lib/vitrinFieldSchema.ts`, `lib/config/vitrin_alanlari.g.dart`.
- **Dil / asistan → Vixrex Asistan:** Niyet sözlüğü alanı esnaf dilinden bulur; değer doğrulanır ve canonical kolona çevrilir. Kanıt: `shared/vixrex_niyet_sozlugu.json`, `public_web/src/lib/vixrexNluPipeline.ts`, `lib/services/vixrex_nlu/`.
- **Düzenleme → Manuel editörler:** Flutter manuel panel ve Next.js sahip editörü aynı alan sözleşmesine göre değeri düzenler. Kanıt: `lib/controllers/store_editor_controller.dart`, `lib/services/store_content_editing_service.dart`, `public_web/src/components/owner/VitrinimEditor.tsx`.
- **Taslak → store_working_drafts:** Değişiklik canlı store'a doğrudan yazılmadan çalışma taslağına kaydedilir; sürüm/çakışma kuralları uygulanır. Kanıt: `public_web/src/app/api/owner-draft/route.ts`, `supabase/migrations/20260805100000_add_working_draft_field_update.sql`, `supabase/migrations/20260909231500_lock_owned_assistant_batch_to_46_fields.sql`.
- **DB doğrulama → Assistant field command guard:** Asistan üzerinden gelen değer DB tarafında da alan tipine göre kontrol edilir. Kanıt: `supabase/migrations/20260909234500_validate_assistant_command_values_in_db.sql`.
- **Yayın → publish_working_draft:** Taslak yayın kapılarından geçerse canlı stores verisine taşınır. Kanıt: `lib/services/store_publish_payload_builder.dart`, `public_web/src/app/api/owner-publish/route.ts`, `supabase/migrations/20260805180000_add_publish_and_discard_working_draft.sql`.
- **Canlı okuma → Public vitrin:** Yayınlanan değer PUBLIC_STORE_SELECT üzerinden /v/[slug] yüzüne ulaşır. Kanıt: `public_web/src/lib/publicStoreSelect.ts`, `public_web/src/app/v/[slug]/page.tsx`.

### Alana özel etkiler

- **Hakkımızda bölümü:** Public Hakkımızda metnini değiştirir. Kanıt: `public_web/src/app/v/[slug]/page.tsx`, `public_web/src/app/v/[slug]/components/AboutEditor.tsx`.
- **SEO açıklama fallback:** Kısa tanıtım boşsa vitrin açıklamasında fallback olur. **Koşul:** kisaTanitim/description boşsa. Kanıt: `public_web/src/app/v/[slug]/page.tsx`, `lib/services/seo_service.dart`.
- **Ürün açıklama fallback:** Ürünün ve kısa tanıtımın açıklaması yoksa ürün detay metnine fallback olabilir. **Koşul:** product.description ve store.description boşsa. Kanıt: `public_web/src/app/v/[slug]/urun/[productSlug]/page.tsx`, `public_web/src/app/v/[slug]/urun/[productSlug]/PublicProductDetailPage.tsx`.

### İlgili test kapıları

`public_web/tests/vitrin-field-schema.test.ts`, `public_web/tests/vixrex-46-alan-davranis-denetimi.test.ts`, `public_web/tests/vixrex-validation-parity.test.ts`, `test/vixrex_46_alan_executor_kapsam_test.dart`, `test/store_publish_payload_builder_test.dart`

## Hakkımızda Görseli — `hakkindaGorsel / about_image_url`

### Ortak kayıt/yayın hattı

- **Tek kaynak → Alan sözleşmesi:** Anahtar, DB kolonu, tip, bölüm, zorunluluk ve doğrulama burada tanımlanır. Kanıt: `shared/vitrin_alanlari.json`, `public_web/src/lib/vitrinFieldSchema.ts`, `lib/config/vitrin_alanlari.g.dart`.
- **Dil / asistan → Vixrex Asistan:** Niyet sözlüğü alanı esnaf dilinden bulur; değer doğrulanır ve canonical kolona çevrilir. Kanıt: `shared/vixrex_niyet_sozlugu.json`, `public_web/src/lib/vixrexNluPipeline.ts`, `lib/services/vixrex_nlu/`.
- **Düzenleme → Manuel editörler:** Flutter manuel panel ve Next.js sahip editörü aynı alan sözleşmesine göre değeri düzenler. Kanıt: `lib/controllers/store_editor_controller.dart`, `lib/services/store_content_editing_service.dart`, `public_web/src/components/owner/VitrinimEditor.tsx`.
- **Taslak → store_working_drafts:** Değişiklik canlı store'a doğrudan yazılmadan çalışma taslağına kaydedilir; sürüm/çakışma kuralları uygulanır. Kanıt: `public_web/src/app/api/owner-draft/route.ts`, `supabase/migrations/20260805100000_add_working_draft_field_update.sql`, `supabase/migrations/20260909231500_lock_owned_assistant_batch_to_46_fields.sql`.
- **DB doğrulama → Assistant field command guard:** Asistan üzerinden gelen değer DB tarafında da alan tipine göre kontrol edilir. Kanıt: `supabase/migrations/20260909234500_validate_assistant_command_values_in_db.sql`.
- **Yayın → publish_working_draft:** Taslak yayın kapılarından geçerse canlı stores verisine taşınır. Kanıt: `lib/services/store_publish_payload_builder.dart`, `public_web/src/app/api/owner-publish/route.ts`, `supabase/migrations/20260805180000_add_publish_and_discard_working_draft.sql`.
- **Canlı okuma → Public vitrin:** Yayınlanan değer PUBLIC_STORE_SELECT üzerinden /v/[slug] yüzüne ulaşır. Kanıt: `public_web/src/lib/publicStoreSelect.ts`, `public_web/src/app/v/[slug]/page.tsx`.

### Alana özel etkiler

- **Hakkımızda görseli:** Public Hakkımızda bölümünün görselini değiştirir. Kanıt: `public_web/src/app/v/[slug]/page.tsx`, `public_web/src/app/v/[slug]/components/AboutEditor.tsx`.

### İlgili test kapıları

`public_web/tests/vitrin-field-schema.test.ts`, `public_web/tests/vixrex-46-alan-davranis-denetimi.test.ts`, `public_web/tests/vixrex-validation-parity.test.ts`, `test/vixrex_46_alan_executor_kapsam_test.dart`, `test/store_publish_payload_builder_test.dart`

## Görsel Alt Yazısı — `hakkindaGorselAlt / about_image_caption`

### Ortak kayıt/yayın hattı

- **Tek kaynak → Alan sözleşmesi:** Anahtar, DB kolonu, tip, bölüm, zorunluluk ve doğrulama burada tanımlanır. Kanıt: `shared/vitrin_alanlari.json`, `public_web/src/lib/vitrinFieldSchema.ts`, `lib/config/vitrin_alanlari.g.dart`.
- **Dil / asistan → Vixrex Asistan:** Niyet sözlüğü alanı esnaf dilinden bulur; değer doğrulanır ve canonical kolona çevrilir. Kanıt: `shared/vixrex_niyet_sozlugu.json`, `public_web/src/lib/vixrexNluPipeline.ts`, `lib/services/vixrex_nlu/`.
- **Düzenleme → Manuel editörler:** Flutter manuel panel ve Next.js sahip editörü aynı alan sözleşmesine göre değeri düzenler. Kanıt: `lib/controllers/store_editor_controller.dart`, `lib/services/store_content_editing_service.dart`, `public_web/src/components/owner/VitrinimEditor.tsx`.
- **Taslak → store_working_drafts:** Değişiklik canlı store'a doğrudan yazılmadan çalışma taslağına kaydedilir; sürüm/çakışma kuralları uygulanır. Kanıt: `public_web/src/app/api/owner-draft/route.ts`, `supabase/migrations/20260805100000_add_working_draft_field_update.sql`, `supabase/migrations/20260909231500_lock_owned_assistant_batch_to_46_fields.sql`.
- **DB doğrulama → Assistant field command guard:** Asistan üzerinden gelen değer DB tarafında da alan tipine göre kontrol edilir. Kanıt: `supabase/migrations/20260909234500_validate_assistant_command_values_in_db.sql`.
- **Yayın → publish_working_draft:** Taslak yayın kapılarından geçerse canlı stores verisine taşınır. Kanıt: `lib/services/store_publish_payload_builder.dart`, `public_web/src/app/api/owner-publish/route.ts`, `supabase/migrations/20260805180000_add_publish_and_discard_working_draft.sql`.
- **Canlı okuma → Public vitrin:** Yayınlanan değer PUBLIC_STORE_SELECT üzerinden /v/[slug] yüzüne ulaşır. Kanıt: `public_web/src/lib/publicStoreSelect.ts`, `public_web/src/app/v/[slug]/page.tsx`.

### Alana özel etkiler

- **Hakkımızda görsel altyazısı:** Public Hakkımızda görselinin açıklama/caption metnini değiştirir. Kanıt: `public_web/src/app/v/[slug]/page.tsx`, `public_web/src/app/v/[slug]/components/AboutEditor.tsx`.

### İlgili test kapıları

`public_web/tests/vitrin-field-schema.test.ts`, `public_web/tests/vixrex-46-alan-davranis-denetimi.test.ts`, `public_web/tests/vixrex-validation-parity.test.ts`, `test/vixrex_46_alan_executor_kapsam_test.dart`, `test/store_publish_payload_builder_test.dart`

## Galeri Üst Başlık — `galeriUstBaslik / gallery_section_kicker`

### Ortak kayıt/yayın hattı

- **Tek kaynak → Alan sözleşmesi:** Anahtar, DB kolonu, tip, bölüm, zorunluluk ve doğrulama burada tanımlanır. Kanıt: `shared/vitrin_alanlari.json`, `public_web/src/lib/vitrinFieldSchema.ts`, `lib/config/vitrin_alanlari.g.dart`.
- **Dil / asistan → Vixrex Asistan:** Niyet sözlüğü alanı esnaf dilinden bulur; değer doğrulanır ve canonical kolona çevrilir. Kanıt: `shared/vixrex_niyet_sozlugu.json`, `public_web/src/lib/vixrexNluPipeline.ts`, `lib/services/vixrex_nlu/`.
- **Düzenleme → Manuel editörler:** Flutter manuel panel ve Next.js sahip editörü aynı alan sözleşmesine göre değeri düzenler. Kanıt: `lib/controllers/store_editor_controller.dart`, `lib/services/store_content_editing_service.dart`, `public_web/src/components/owner/VitrinimEditor.tsx`.
- **Taslak → store_working_drafts:** Değişiklik canlı store'a doğrudan yazılmadan çalışma taslağına kaydedilir; sürüm/çakışma kuralları uygulanır. Kanıt: `public_web/src/app/api/owner-draft/route.ts`, `supabase/migrations/20260805100000_add_working_draft_field_update.sql`, `supabase/migrations/20260909231500_lock_owned_assistant_batch_to_46_fields.sql`.
- **DB doğrulama → Assistant field command guard:** Asistan üzerinden gelen değer DB tarafında da alan tipine göre kontrol edilir. Kanıt: `supabase/migrations/20260909234500_validate_assistant_command_values_in_db.sql`.
- **Yayın → publish_working_draft:** Taslak yayın kapılarından geçerse canlı stores verisine taşınır. Kanıt: `lib/services/store_publish_payload_builder.dart`, `public_web/src/app/api/owner-publish/route.ts`, `supabase/migrations/20260805180000_add_publish_and_discard_working_draft.sql`.
- **Canlı okuma → Public vitrin:** Yayınlanan değer PUBLIC_STORE_SELECT üzerinden /v/[slug] yüzüne ulaşır. Kanıt: `public_web/src/lib/publicStoreSelect.ts`, `public_web/src/app/v/[slug]/page.tsx`.

### Alana özel etkiler

- **Galeri bölümü:** Public galeri üst başlığını değiştirir. Kanıt: `public_web/src/app/v/[slug]/page.tsx`.

### İlgili test kapıları

`public_web/tests/vitrin-field-schema.test.ts`, `public_web/tests/vixrex-46-alan-davranis-denetimi.test.ts`, `public_web/tests/vixrex-validation-parity.test.ts`, `test/vixrex_46_alan_executor_kapsam_test.dart`, `test/store_publish_payload_builder_test.dart`

## Galeri Başlığı — `galeriBaslik / gallery_section_title`

### Ortak kayıt/yayın hattı

- **Tek kaynak → Alan sözleşmesi:** Anahtar, DB kolonu, tip, bölüm, zorunluluk ve doğrulama burada tanımlanır. Kanıt: `shared/vitrin_alanlari.json`, `public_web/src/lib/vitrinFieldSchema.ts`, `lib/config/vitrin_alanlari.g.dart`.
- **Dil / asistan → Vixrex Asistan:** Niyet sözlüğü alanı esnaf dilinden bulur; değer doğrulanır ve canonical kolona çevrilir. Kanıt: `shared/vixrex_niyet_sozlugu.json`, `public_web/src/lib/vixrexNluPipeline.ts`, `lib/services/vixrex_nlu/`.
- **Düzenleme → Manuel editörler:** Flutter manuel panel ve Next.js sahip editörü aynı alan sözleşmesine göre değeri düzenler. Kanıt: `lib/controllers/store_editor_controller.dart`, `lib/services/store_content_editing_service.dart`, `public_web/src/components/owner/VitrinimEditor.tsx`.
- **Taslak → store_working_drafts:** Değişiklik canlı store'a doğrudan yazılmadan çalışma taslağına kaydedilir; sürüm/çakışma kuralları uygulanır. Kanıt: `public_web/src/app/api/owner-draft/route.ts`, `supabase/migrations/20260805100000_add_working_draft_field_update.sql`, `supabase/migrations/20260909231500_lock_owned_assistant_batch_to_46_fields.sql`.
- **DB doğrulama → Assistant field command guard:** Asistan üzerinden gelen değer DB tarafında da alan tipine göre kontrol edilir. Kanıt: `supabase/migrations/20260909234500_validate_assistant_command_values_in_db.sql`.
- **Yayın → publish_working_draft:** Taslak yayın kapılarından geçerse canlı stores verisine taşınır. Kanıt: `lib/services/store_publish_payload_builder.dart`, `public_web/src/app/api/owner-publish/route.ts`, `supabase/migrations/20260805180000_add_publish_and_discard_working_draft.sql`.
- **Canlı okuma → Public vitrin:** Yayınlanan değer PUBLIC_STORE_SELECT üzerinden /v/[slug] yüzüne ulaşır. Kanıt: `public_web/src/lib/publicStoreSelect.ts`, `public_web/src/app/v/[slug]/page.tsx`.

### Alana özel etkiler

- **Galeri bölümü:** Public galeri ana başlığını değiştirir. Kanıt: `public_web/src/app/v/[slug]/page.tsx`.

### İlgili test kapıları

`public_web/tests/vitrin-field-schema.test.ts`, `public_web/tests/vixrex-46-alan-davranis-denetimi.test.ts`, `public_web/tests/vixrex-validation-parity.test.ts`, `test/vixrex_46_alan_executor_kapsam_test.dart`, `test/store_publish_payload_builder_test.dart`

## Galeri Buton Metni — `galeriAksiyonMetni / gallery_action_label`

### Ortak kayıt/yayın hattı

- **Tek kaynak → Alan sözleşmesi:** Anahtar, DB kolonu, tip, bölüm, zorunluluk ve doğrulama burada tanımlanır. Kanıt: `shared/vitrin_alanlari.json`, `public_web/src/lib/vitrinFieldSchema.ts`, `lib/config/vitrin_alanlari.g.dart`.
- **Dil / asistan → Vixrex Asistan:** Niyet sözlüğü alanı esnaf dilinden bulur; değer doğrulanır ve canonical kolona çevrilir. Kanıt: `shared/vixrex_niyet_sozlugu.json`, `public_web/src/lib/vixrexNluPipeline.ts`, `lib/services/vixrex_nlu/`.
- **Düzenleme → Manuel editörler:** Flutter manuel panel ve Next.js sahip editörü aynı alan sözleşmesine göre değeri düzenler. Kanıt: `lib/controllers/store_editor_controller.dart`, `lib/services/store_content_editing_service.dart`, `public_web/src/components/owner/VitrinimEditor.tsx`.
- **Taslak → store_working_drafts:** Değişiklik canlı store'a doğrudan yazılmadan çalışma taslağına kaydedilir; sürüm/çakışma kuralları uygulanır. Kanıt: `public_web/src/app/api/owner-draft/route.ts`, `supabase/migrations/20260805100000_add_working_draft_field_update.sql`, `supabase/migrations/20260909231500_lock_owned_assistant_batch_to_46_fields.sql`.
- **DB doğrulama → Assistant field command guard:** Asistan üzerinden gelen değer DB tarafında da alan tipine göre kontrol edilir. Kanıt: `supabase/migrations/20260909234500_validate_assistant_command_values_in_db.sql`.
- **Yayın → publish_working_draft:** Taslak yayın kapılarından geçerse canlı stores verisine taşınır. Kanıt: `lib/services/store_publish_payload_builder.dart`, `public_web/src/app/api/owner-publish/route.ts`, `supabase/migrations/20260805180000_add_publish_and_discard_working_draft.sql`.
- **Canlı okuma → Public vitrin:** Yayınlanan değer PUBLIC_STORE_SELECT üzerinden /v/[slug] yüzüne ulaşır. Kanıt: `public_web/src/lib/publicStoreSelect.ts`, `public_web/src/app/v/[slug]/page.tsx`.

### Alana özel etkiler

- **Galeri CTA:** Galeri bölümündeki aksiyon düğmesinin metnini değiştirir. Kanıt: `public_web/src/app/v/[slug]/page.tsx`.

### Özellikle etkilemediği şeyler

- Galeri görsellerini değiştirmez.

### İlgili test kapıları

`public_web/tests/vitrin-field-schema.test.ts`, `public_web/tests/vixrex-46-alan-davranis-denetimi.test.ts`, `public_web/tests/vixrex-validation-parity.test.ts`, `test/vixrex_46_alan_executor_kapsam_test.dart`, `test/store_publish_payload_builder_test.dart`

## Galeri Buton Bağlantısı — `galeriAksiyonLinki / gallery_action_href`

### Ortak kayıt/yayın hattı

- **Tek kaynak → Alan sözleşmesi:** Anahtar, DB kolonu, tip, bölüm, zorunluluk ve doğrulama burada tanımlanır. Kanıt: `shared/vitrin_alanlari.json`, `public_web/src/lib/vitrinFieldSchema.ts`, `lib/config/vitrin_alanlari.g.dart`.
- **Dil / asistan → Vixrex Asistan:** Niyet sözlüğü alanı esnaf dilinden bulur; değer doğrulanır ve canonical kolona çevrilir. Kanıt: `shared/vixrex_niyet_sozlugu.json`, `public_web/src/lib/vixrexNluPipeline.ts`, `lib/services/vixrex_nlu/`.
- **Düzenleme → Manuel editörler:** Flutter manuel panel ve Next.js sahip editörü aynı alan sözleşmesine göre değeri düzenler. Kanıt: `lib/controllers/store_editor_controller.dart`, `lib/services/store_content_editing_service.dart`, `public_web/src/components/owner/VitrinimEditor.tsx`.
- **Taslak → store_working_drafts:** Değişiklik canlı store'a doğrudan yazılmadan çalışma taslağına kaydedilir; sürüm/çakışma kuralları uygulanır. Kanıt: `public_web/src/app/api/owner-draft/route.ts`, `supabase/migrations/20260805100000_add_working_draft_field_update.sql`, `supabase/migrations/20260909231500_lock_owned_assistant_batch_to_46_fields.sql`.
- **DB doğrulama → Assistant field command guard:** Asistan üzerinden gelen değer DB tarafında da alan tipine göre kontrol edilir. Kanıt: `supabase/migrations/20260909234500_validate_assistant_command_values_in_db.sql`.
- **Yayın → publish_working_draft:** Taslak yayın kapılarından geçerse canlı stores verisine taşınır. Kanıt: `lib/services/store_publish_payload_builder.dart`, `public_web/src/app/api/owner-publish/route.ts`, `supabase/migrations/20260805180000_add_publish_and_discard_working_draft.sql`.
- **Canlı okuma → Public vitrin:** Yayınlanan değer PUBLIC_STORE_SELECT üzerinden /v/[slug] yüzüne ulaşır. Kanıt: `public_web/src/lib/publicStoreSelect.ts`, `public_web/src/app/v/[slug]/page.tsx`.

### Alana özel etkiler

- **Galeri CTA hedefi:** Galeri aksiyon düğmesinin hedef URL'sini değiştirir. Kanıt: `public_web/src/app/v/[slug]/page.tsx`.

### Özellikle etkilemediği şeyler

- Galeri görsellerini değiştirmez.

### İlgili test kapıları

`public_web/tests/vitrin-field-schema.test.ts`, `public_web/tests/vixrex-46-alan-davranis-denetimi.test.ts`, `public_web/tests/vixrex-validation-parity.test.ts`, `test/vixrex_46_alan_executor_kapsam_test.dart`, `test/store_publish_payload_builder_test.dart`

## Blog Üst Başlık — `blogUstBaslik / blog_section_kicker`

### Ortak kayıt/yayın hattı

- **Tek kaynak → Alan sözleşmesi:** Anahtar, DB kolonu, tip, bölüm, zorunluluk ve doğrulama burada tanımlanır. Kanıt: `shared/vitrin_alanlari.json`, `public_web/src/lib/vitrinFieldSchema.ts`, `lib/config/vitrin_alanlari.g.dart`.
- **Dil / asistan → Vixrex Asistan:** Niyet sözlüğü alanı esnaf dilinden bulur; değer doğrulanır ve canonical kolona çevrilir. Kanıt: `shared/vixrex_niyet_sozlugu.json`, `public_web/src/lib/vixrexNluPipeline.ts`, `lib/services/vixrex_nlu/`.
- **Düzenleme → Manuel editörler:** Flutter manuel panel ve Next.js sahip editörü aynı alan sözleşmesine göre değeri düzenler. Kanıt: `lib/controllers/store_editor_controller.dart`, `lib/services/store_content_editing_service.dart`, `public_web/src/components/owner/VitrinimEditor.tsx`.
- **Taslak → store_working_drafts:** Değişiklik canlı store'a doğrudan yazılmadan çalışma taslağına kaydedilir; sürüm/çakışma kuralları uygulanır. Kanıt: `public_web/src/app/api/owner-draft/route.ts`, `supabase/migrations/20260805100000_add_working_draft_field_update.sql`, `supabase/migrations/20260909231500_lock_owned_assistant_batch_to_46_fields.sql`.
- **DB doğrulama → Assistant field command guard:** Asistan üzerinden gelen değer DB tarafında da alan tipine göre kontrol edilir. Kanıt: `supabase/migrations/20260909234500_validate_assistant_command_values_in_db.sql`.
- **Yayın → publish_working_draft:** Taslak yayın kapılarından geçerse canlı stores verisine taşınır. Kanıt: `lib/services/store_publish_payload_builder.dart`, `public_web/src/app/api/owner-publish/route.ts`, `supabase/migrations/20260805180000_add_publish_and_discard_working_draft.sql`.
- **Canlı okuma → Public vitrin:** Yayınlanan değer PUBLIC_STORE_SELECT üzerinden /v/[slug] yüzüne ulaşır. Kanıt: `public_web/src/lib/publicStoreSelect.ts`, `public_web/src/app/v/[slug]/page.tsx`.

### Alana özel etkiler

- **Vitrin blog bölümü başlığı:** Public vitrindeki blog teaser bölümünün üst başlığını değiştirir. Kanıt: `public_web/src/app/v/[slug]/page.tsx`.

### Özellikle etkilemediği şeyler

- store_articles kayıtlarını, yazı başlıklarını veya sitemap'i değiştirmez.

### İlgili test kapıları

`public_web/tests/vitrin-field-schema.test.ts`, `public_web/tests/vixrex-46-alan-davranis-denetimi.test.ts`, `public_web/tests/vixrex-validation-parity.test.ts`, `test/vixrex_46_alan_executor_kapsam_test.dart`, `test/store_publish_payload_builder_test.dart`

## Blog Bölüm Başlığı — `blogBaslik / blog_section_title`

### Ortak kayıt/yayın hattı

- **Tek kaynak → Alan sözleşmesi:** Anahtar, DB kolonu, tip, bölüm, zorunluluk ve doğrulama burada tanımlanır. Kanıt: `shared/vitrin_alanlari.json`, `public_web/src/lib/vitrinFieldSchema.ts`, `lib/config/vitrin_alanlari.g.dart`.
- **Dil / asistan → Vixrex Asistan:** Niyet sözlüğü alanı esnaf dilinden bulur; değer doğrulanır ve canonical kolona çevrilir. Kanıt: `shared/vixrex_niyet_sozlugu.json`, `public_web/src/lib/vixrexNluPipeline.ts`, `lib/services/vixrex_nlu/`.
- **Düzenleme → Manuel editörler:** Flutter manuel panel ve Next.js sahip editörü aynı alan sözleşmesine göre değeri düzenler. Kanıt: `lib/controllers/store_editor_controller.dart`, `lib/services/store_content_editing_service.dart`, `public_web/src/components/owner/VitrinimEditor.tsx`.
- **Taslak → store_working_drafts:** Değişiklik canlı store'a doğrudan yazılmadan çalışma taslağına kaydedilir; sürüm/çakışma kuralları uygulanır. Kanıt: `public_web/src/app/api/owner-draft/route.ts`, `supabase/migrations/20260805100000_add_working_draft_field_update.sql`, `supabase/migrations/20260909231500_lock_owned_assistant_batch_to_46_fields.sql`.
- **DB doğrulama → Assistant field command guard:** Asistan üzerinden gelen değer DB tarafında da alan tipine göre kontrol edilir. Kanıt: `supabase/migrations/20260909234500_validate_assistant_command_values_in_db.sql`.
- **Yayın → publish_working_draft:** Taslak yayın kapılarından geçerse canlı stores verisine taşınır. Kanıt: `lib/services/store_publish_payload_builder.dart`, `public_web/src/app/api/owner-publish/route.ts`, `supabase/migrations/20260805180000_add_publish_and_discard_working_draft.sql`.
- **Canlı okuma → Public vitrin:** Yayınlanan değer PUBLIC_STORE_SELECT üzerinden /v/[slug] yüzüne ulaşır. Kanıt: `public_web/src/lib/publicStoreSelect.ts`, `public_web/src/app/v/[slug]/page.tsx`.

### Alana özel etkiler

- **Vitrin blog bölümü başlığı:** Public vitrindeki blog teaser bölümünün ana başlığını değiştirir. Kanıt: `public_web/src/app/v/[slug]/page.tsx`.

### Özellikle etkilemediği şeyler

- store_articles kayıtlarını, yazı başlıklarını veya sitemap'i değiştirmez.

### İlgili test kapıları

`public_web/tests/vitrin-field-schema.test.ts`, `public_web/tests/vixrex-46-alan-davranis-denetimi.test.ts`, `public_web/tests/vixrex-validation-parity.test.ts`, `test/vixrex_46_alan_executor_kapsam_test.dart`, `test/store_publish_payload_builder_test.dart`

## SSS Üst Başlık — `sssUstBaslik / faq_section_kicker`

### Ortak kayıt/yayın hattı

- **Tek kaynak → Alan sözleşmesi:** Anahtar, DB kolonu, tip, bölüm, zorunluluk ve doğrulama burada tanımlanır. Kanıt: `shared/vitrin_alanlari.json`, `public_web/src/lib/vitrinFieldSchema.ts`, `lib/config/vitrin_alanlari.g.dart`.
- **Dil / asistan → Vixrex Asistan:** Niyet sözlüğü alanı esnaf dilinden bulur; değer doğrulanır ve canonical kolona çevrilir. Kanıt: `shared/vixrex_niyet_sozlugu.json`, `public_web/src/lib/vixrexNluPipeline.ts`, `lib/services/vixrex_nlu/`.
- **Düzenleme → Manuel editörler:** Flutter manuel panel ve Next.js sahip editörü aynı alan sözleşmesine göre değeri düzenler. Kanıt: `lib/controllers/store_editor_controller.dart`, `lib/services/store_content_editing_service.dart`, `public_web/src/components/owner/VitrinimEditor.tsx`.
- **Taslak → store_working_drafts:** Değişiklik canlı store'a doğrudan yazılmadan çalışma taslağına kaydedilir; sürüm/çakışma kuralları uygulanır. Kanıt: `public_web/src/app/api/owner-draft/route.ts`, `supabase/migrations/20260805100000_add_working_draft_field_update.sql`, `supabase/migrations/20260909231500_lock_owned_assistant_batch_to_46_fields.sql`.
- **DB doğrulama → Assistant field command guard:** Asistan üzerinden gelen değer DB tarafında da alan tipine göre kontrol edilir. Kanıt: `supabase/migrations/20260909234500_validate_assistant_command_values_in_db.sql`.
- **Yayın → publish_working_draft:** Taslak yayın kapılarından geçerse canlı stores verisine taşınır. Kanıt: `lib/services/store_publish_payload_builder.dart`, `public_web/src/app/api/owner-publish/route.ts`, `supabase/migrations/20260805180000_add_publish_and_discard_working_draft.sql`.
- **Canlı okuma → Public vitrin:** Yayınlanan değer PUBLIC_STORE_SELECT üzerinden /v/[slug] yüzüne ulaşır. Kanıt: `public_web/src/lib/publicStoreSelect.ts`, `public_web/src/app/v/[slug]/page.tsx`.

### Alana özel etkiler

- **SSS bölüm kabuğu:** Public SSS bölümünün üst başlığını değiştirir. Kanıt: `public_web/src/app/v/[slug]/page.tsx`.

### Özellikle etkilemediği şeyler

- Gerçek SSS maddelerini (faq_items) değiştirmez.

### İlgili test kapıları

`public_web/tests/vitrin-field-schema.test.ts`, `public_web/tests/vixrex-46-alan-davranis-denetimi.test.ts`, `public_web/tests/vixrex-validation-parity.test.ts`, `test/vixrex_46_alan_executor_kapsam_test.dart`, `test/store_publish_payload_builder_test.dart`

## SSS Bölüm Başlığı — `sssBaslik / faq_section_title`

### Ortak kayıt/yayın hattı

- **Tek kaynak → Alan sözleşmesi:** Anahtar, DB kolonu, tip, bölüm, zorunluluk ve doğrulama burada tanımlanır. Kanıt: `shared/vitrin_alanlari.json`, `public_web/src/lib/vitrinFieldSchema.ts`, `lib/config/vitrin_alanlari.g.dart`.
- **Dil / asistan → Vixrex Asistan:** Niyet sözlüğü alanı esnaf dilinden bulur; değer doğrulanır ve canonical kolona çevrilir. Kanıt: `shared/vixrex_niyet_sozlugu.json`, `public_web/src/lib/vixrexNluPipeline.ts`, `lib/services/vixrex_nlu/`.
- **Düzenleme → Manuel editörler:** Flutter manuel panel ve Next.js sahip editörü aynı alan sözleşmesine göre değeri düzenler. Kanıt: `lib/controllers/store_editor_controller.dart`, `lib/services/store_content_editing_service.dart`, `public_web/src/components/owner/VitrinimEditor.tsx`.
- **Taslak → store_working_drafts:** Değişiklik canlı store'a doğrudan yazılmadan çalışma taslağına kaydedilir; sürüm/çakışma kuralları uygulanır. Kanıt: `public_web/src/app/api/owner-draft/route.ts`, `supabase/migrations/20260805100000_add_working_draft_field_update.sql`, `supabase/migrations/20260909231500_lock_owned_assistant_batch_to_46_fields.sql`.
- **DB doğrulama → Assistant field command guard:** Asistan üzerinden gelen değer DB tarafında da alan tipine göre kontrol edilir. Kanıt: `supabase/migrations/20260909234500_validate_assistant_command_values_in_db.sql`.
- **Yayın → publish_working_draft:** Taslak yayın kapılarından geçerse canlı stores verisine taşınır. Kanıt: `lib/services/store_publish_payload_builder.dart`, `public_web/src/app/api/owner-publish/route.ts`, `supabase/migrations/20260805180000_add_publish_and_discard_working_draft.sql`.
- **Canlı okuma → Public vitrin:** Yayınlanan değer PUBLIC_STORE_SELECT üzerinden /v/[slug] yüzüne ulaşır. Kanıt: `public_web/src/lib/publicStoreSelect.ts`, `public_web/src/app/v/[slug]/page.tsx`.

### Alana özel etkiler

- **SSS bölüm kabuğu:** Public SSS bölümünün ana başlığını değiştirir. Kanıt: `public_web/src/app/v/[slug]/page.tsx`.

### Özellikle etkilemediği şeyler

- Gerçek SSS maddelerini (faq_items) değiştirmez.

### İlgili test kapıları

`public_web/tests/vitrin-field-schema.test.ts`, `public_web/tests/vixrex-46-alan-davranis-denetimi.test.ts`, `public_web/tests/vixrex-validation-parity.test.ts`, `test/vixrex_46_alan_executor_kapsam_test.dart`, `test/store_publish_payload_builder_test.dart`

## SSS Bölüm Açıklaması — `sssAciklama / faq_section_description`

### Ortak kayıt/yayın hattı

- **Tek kaynak → Alan sözleşmesi:** Anahtar, DB kolonu, tip, bölüm, zorunluluk ve doğrulama burada tanımlanır. Kanıt: `shared/vitrin_alanlari.json`, `public_web/src/lib/vitrinFieldSchema.ts`, `lib/config/vitrin_alanlari.g.dart`.
- **Dil / asistan → Vixrex Asistan:** Niyet sözlüğü alanı esnaf dilinden bulur; değer doğrulanır ve canonical kolona çevrilir. Kanıt: `shared/vixrex_niyet_sozlugu.json`, `public_web/src/lib/vixrexNluPipeline.ts`, `lib/services/vixrex_nlu/`.
- **Düzenleme → Manuel editörler:** Flutter manuel panel ve Next.js sahip editörü aynı alan sözleşmesine göre değeri düzenler. Kanıt: `lib/controllers/store_editor_controller.dart`, `lib/services/store_content_editing_service.dart`, `public_web/src/components/owner/VitrinimEditor.tsx`.
- **Taslak → store_working_drafts:** Değişiklik canlı store'a doğrudan yazılmadan çalışma taslağına kaydedilir; sürüm/çakışma kuralları uygulanır. Kanıt: `public_web/src/app/api/owner-draft/route.ts`, `supabase/migrations/20260805100000_add_working_draft_field_update.sql`, `supabase/migrations/20260909231500_lock_owned_assistant_batch_to_46_fields.sql`.
- **DB doğrulama → Assistant field command guard:** Asistan üzerinden gelen değer DB tarafında da alan tipine göre kontrol edilir. Kanıt: `supabase/migrations/20260909234500_validate_assistant_command_values_in_db.sql`.
- **Yayın → publish_working_draft:** Taslak yayın kapılarından geçerse canlı stores verisine taşınır. Kanıt: `lib/services/store_publish_payload_builder.dart`, `public_web/src/app/api/owner-publish/route.ts`, `supabase/migrations/20260805180000_add_publish_and_discard_working_draft.sql`.
- **Canlı okuma → Public vitrin:** Yayınlanan değer PUBLIC_STORE_SELECT üzerinden /v/[slug] yüzüne ulaşır. Kanıt: `public_web/src/lib/publicStoreSelect.ts`, `public_web/src/app/v/[slug]/page.tsx`.

### Alana özel etkiler

- **SSS bölüm kabuğu:** Public SSS bölüm açıklamasını değiştirir. Kanıt: `public_web/src/app/v/[slug]/page.tsx`.

### Özellikle etkilemediği şeyler

- Gerçek SSS maddelerini (faq_items) değiştirmez.

### İlgili test kapıları

`public_web/tests/vitrin-field-schema.test.ts`, `public_web/tests/vixrex-46-alan-davranis-denetimi.test.ts`, `public_web/tests/vixrex-validation-parity.test.ts`, `test/vixrex_46_alan_executor_kapsam_test.dart`, `test/store_publish_payload_builder_test.dart`

## Değerlendirme Puanını Göster — `puanGoster / show_storefront_rating`

### Ortak kayıt/yayın hattı

- **Tek kaynak → Alan sözleşmesi:** Anahtar, DB kolonu, tip, bölüm, zorunluluk ve doğrulama burada tanımlanır. Kanıt: `shared/vitrin_alanlari.json`, `public_web/src/lib/vitrinFieldSchema.ts`, `lib/config/vitrin_alanlari.g.dart`.
- **Dil / asistan → Vixrex Asistan:** Niyet sözlüğü alanı esnaf dilinden bulur; değer doğrulanır ve canonical kolona çevrilir. Kanıt: `shared/vixrex_niyet_sozlugu.json`, `public_web/src/lib/vixrexNluPipeline.ts`, `lib/services/vixrex_nlu/`.
- **Düzenleme → Manuel editörler:** Flutter manuel panel ve Next.js sahip editörü aynı alan sözleşmesine göre değeri düzenler. Kanıt: `lib/controllers/store_editor_controller.dart`, `lib/services/store_content_editing_service.dart`, `public_web/src/components/owner/VitrinimEditor.tsx`.
- **Taslak → store_working_drafts:** Değişiklik canlı store'a doğrudan yazılmadan çalışma taslağına kaydedilir; sürüm/çakışma kuralları uygulanır. Kanıt: `public_web/src/app/api/owner-draft/route.ts`, `supabase/migrations/20260805100000_add_working_draft_field_update.sql`, `supabase/migrations/20260909231500_lock_owned_assistant_batch_to_46_fields.sql`.
- **DB doğrulama → Assistant field command guard:** Asistan üzerinden gelen değer DB tarafında da alan tipine göre kontrol edilir. Kanıt: `supabase/migrations/20260909234500_validate_assistant_command_values_in_db.sql`.
- **Yayın → publish_working_draft:** Taslak yayın kapılarından geçerse canlı stores verisine taşınır. Kanıt: `lib/services/store_publish_payload_builder.dart`, `public_web/src/app/api/owner-publish/route.ts`, `supabase/migrations/20260805180000_add_publish_and_discard_working_draft.sql`.
- **Canlı okuma → Public vitrin:** Yayınlanan değer PUBLIC_STORE_SELECT üzerinden /v/[slug] yüzüne ulaşır. Kanıt: `public_web/src/lib/publicStoreSelect.ts`, `public_web/src/app/v/[slug]/page.tsx`.

### Alana özel etkiler

- **Puan görünürlüğü:** Public vitrinde rating bandının gösterilip gösterilmeyeceğini belirler. Kanıt: `public_web/src/app/v/[slug]/page.tsx`.

### Özellikle etkilemediği şeyler

- rating_score veya review_count değerlerini değiştirmez; yalnız görünürlüğü kontrol eder.

### İlgili test kapıları

`public_web/tests/vitrin-field-schema.test.ts`, `public_web/tests/vixrex-46-alan-davranis-denetimi.test.ts`, `public_web/tests/vixrex-validation-parity.test.ts`, `test/vixrex_46_alan_executor_kapsam_test.dart`, `test/store_publish_payload_builder_test.dart`

## Yol Tarifi Butonunu Göster — `yolTarifiGoster / show_directions_link`

### Ortak kayıt/yayın hattı

- **Tek kaynak → Alan sözleşmesi:** Anahtar, DB kolonu, tip, bölüm, zorunluluk ve doğrulama burada tanımlanır. Kanıt: `shared/vitrin_alanlari.json`, `public_web/src/lib/vitrinFieldSchema.ts`, `lib/config/vitrin_alanlari.g.dart`.
- **Dil / asistan → Vixrex Asistan:** Niyet sözlüğü alanı esnaf dilinden bulur; değer doğrulanır ve canonical kolona çevrilir. Kanıt: `shared/vixrex_niyet_sozlugu.json`, `public_web/src/lib/vixrexNluPipeline.ts`, `lib/services/vixrex_nlu/`.
- **Düzenleme → Manuel editörler:** Flutter manuel panel ve Next.js sahip editörü aynı alan sözleşmesine göre değeri düzenler. Kanıt: `lib/controllers/store_editor_controller.dart`, `lib/services/store_content_editing_service.dart`, `public_web/src/components/owner/VitrinimEditor.tsx`.
- **Taslak → store_working_drafts:** Değişiklik canlı store'a doğrudan yazılmadan çalışma taslağına kaydedilir; sürüm/çakışma kuralları uygulanır. Kanıt: `public_web/src/app/api/owner-draft/route.ts`, `supabase/migrations/20260805100000_add_working_draft_field_update.sql`, `supabase/migrations/20260909231500_lock_owned_assistant_batch_to_46_fields.sql`.
- **DB doğrulama → Assistant field command guard:** Asistan üzerinden gelen değer DB tarafında da alan tipine göre kontrol edilir. Kanıt: `supabase/migrations/20260909234500_validate_assistant_command_values_in_db.sql`.
- **Yayın → publish_working_draft:** Taslak yayın kapılarından geçerse canlı stores verisine taşınır. Kanıt: `lib/services/store_publish_payload_builder.dart`, `public_web/src/app/api/owner-publish/route.ts`, `supabase/migrations/20260805180000_add_publish_and_discard_working_draft.sql`.
- **Canlı okuma → Public vitrin:** Yayınlanan değer PUBLIC_STORE_SELECT üzerinden /v/[slug] yüzüne ulaşır. Kanıt: `public_web/src/lib/publicStoreSelect.ts`, `public_web/src/app/v/[slug]/page.tsx`.

### Alana özel etkiler

- **Yol tarifi görünürlüğü:** Public vitrinde mapsUrl/yol tarifi CTA'sının üretilip gösterilmesini kontrol eder. Kanıt: `public_web/src/app/v/[slug]/page.tsx`.

### Özellikle etkilemediği şeyler

- Adres, enlem, boylam veya Google İşletme bağlantısını silmez/değiştirmez.

### İlgili test kapıları

`public_web/tests/vitrin-field-schema.test.ts`, `public_web/tests/vixrex-46-alan-davranis-denetimi.test.ts`, `public_web/tests/vixrex-validation-parity.test.ts`, `test/vixrex_46_alan_executor_kapsam_test.dart`, `test/store_publish_payload_builder_test.dart`, `test/store_data_contract_test.dart`, `public_web/tests/assistant-db-value-validation-contract.test.ts`

## Referanslar Bağlantısı — `referansLinki / references_link`

### Ortak kayıt/yayın hattı

- **Tek kaynak → Alan sözleşmesi:** Anahtar, DB kolonu, tip, bölüm, zorunluluk ve doğrulama burada tanımlanır. Kanıt: `shared/vitrin_alanlari.json`, `public_web/src/lib/vitrinFieldSchema.ts`, `lib/config/vitrin_alanlari.g.dart`.
- **Dil / asistan → Vixrex Asistan:** Niyet sözlüğü alanı esnaf dilinden bulur; değer doğrulanır ve canonical kolona çevrilir. Kanıt: `shared/vixrex_niyet_sozlugu.json`, `public_web/src/lib/vixrexNluPipeline.ts`, `lib/services/vixrex_nlu/`.
- **Düzenleme → Manuel editörler:** Flutter manuel panel ve Next.js sahip editörü aynı alan sözleşmesine göre değeri düzenler. Kanıt: `lib/controllers/store_editor_controller.dart`, `lib/services/store_content_editing_service.dart`, `public_web/src/components/owner/VitrinimEditor.tsx`.
- **Taslak → store_working_drafts:** Değişiklik canlı store'a doğrudan yazılmadan çalışma taslağına kaydedilir; sürüm/çakışma kuralları uygulanır. Kanıt: `public_web/src/app/api/owner-draft/route.ts`, `supabase/migrations/20260805100000_add_working_draft_field_update.sql`, `supabase/migrations/20260909231500_lock_owned_assistant_batch_to_46_fields.sql`.
- **DB doğrulama → Assistant field command guard:** Asistan üzerinden gelen değer DB tarafında da alan tipine göre kontrol edilir. Kanıt: `supabase/migrations/20260909234500_validate_assistant_command_values_in_db.sql`.
- **Yayın → publish_working_draft:** Taslak yayın kapılarından geçerse canlı stores verisine taşınır. Kanıt: `lib/services/store_publish_payload_builder.dart`, `public_web/src/app/api/owner-publish/route.ts`, `supabase/migrations/20260805180000_add_publish_and_discard_working_draft.sql`.
- **Canlı okuma → Public vitrin:** Yayınlanan değer PUBLIC_STORE_SELECT üzerinden /v/[slug] yüzüne ulaşır. Kanıt: `public_web/src/lib/publicStoreSelect.ts`, `public_web/src/app/v/[slug]/page.tsx`.

### Alana özel etkiler

- **Referanslar bağlantısı:** Harici referans URL'si normalize edilerek public vitrine referencesUrl olarak gider. Kanıt: `public_web/src/app/v/[slug]/page.tsx`.

### Özellikle etkilemediği şeyler

- Hakkımızda metnini veya gerçek referans içeriklerini otomatik üretmez.

### İlgili test kapıları

`public_web/tests/vitrin-field-schema.test.ts`, `public_web/tests/vixrex-46-alan-davranis-denetimi.test.ts`, `public_web/tests/vixrex-validation-parity.test.ts`, `test/vixrex_46_alan_executor_kapsam_test.dart`, `test/store_publish_payload_builder_test.dart`
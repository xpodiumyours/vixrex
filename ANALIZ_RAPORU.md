# VixRex Teknik Röntgen Raporu
> Tarih: 2026-07-05 | Mod: Read-only analiz

---

## 1. Klasör Doğrulaması

Talep: `C:\Users\xpodiumyours\vixrex` → **Bu yol mevcut değil.**
Gerçek proje: `C:\Users\Casper\vixrex` → Tüm kritik dosyalar doğrulandı.

| Dosya | Var mı? |
|---|---|
| pubspec.yaml | ✅ |
| lib/main.dart | ✅ |
| vercel.json | ✅ |
| vercel-build.sh | ✅ |
| supabase/migrations/ | ✅ (19 dosya) |

---

## 2. Proje Haritası

### lib/screens/ (14 ekran)
- `landing_screen.dart` — Karşılama/landing, hero animasyonlu, demo profiller, claim bar
- `my_vitrin_screen.dart` — Ana editör ekranı (~1800+ satır, en büyük dosya)
- `public_vitrin_screen.dart` — Herkese açık vitrin görüntüleme
- `explore_screen.dart` — Yayınlanmış vitrinleri keşfetme
- `xrex_screen.dart` — X-rex AI asistanı (statik, "Yakında" etiketli)
- `home_shell_screen.dart` — Alt navigasyon kabı
- `auth_screen.dart` — Giriş/kayıt
- `preview_screen.dart` — Demo vitrin önizleme
- `legal_screen.dart` — KVKK yasal ekran
- `profile_screen.dart` — Profil
- `blog_editor_screen.dart` — Blog yazısı düzenleme
- `blog_moderation_screen.dart` — Blog moderasyon
- `booking_management_screen.dart` — Randevu yönetimi
- `appointment_tracker_screen.dart` — Randevu takip

### lib/controllers/ (3 dosya)
- `store_editor_controller.dart` — ChangeNotifier, publish mantığı, validation, Supabase RPC
- `explore_controller.dart` — Keşfe yönelik controller
- `editor_gallery_item.dart` — Galeri item modeli

### lib/services/ (16 servis)
- `store_publish_service.dart` — Validator + PayloadBuilder + publish/withdraw (Supabase RPC)
- `store_shelf_upload_service.dart` — Storage'a görsel yükleme
- `store_local_storage_service.dart` — SharedPreferences persistans
- `image_optimization_service.dart` — Görsel sıkıştırma
- `auth_service.dart` — Supabase auth
- `chatbot_service.dart` — X-rex kural tabanlı offline chatbot
- `xrex_profile_snapshot.dart` — Vitrin durumu özeti (skor hesaplama)
- `location_service.dart` — GPS + reverse geocode
- `seo_service.dart` — Next.js ISR revalidation
- `seo_helper.dart` / `seo_helper_web.dart` / `seo_helper_mobile.dart` — Platform bazlı SEO
- `instagram_sync_service.dart` — Instagram OAuth + media import
- `legal_document_service.dart` — Versiyonlu yasal belge yükleme
- `vitrin_view_service.dart` — Görüntülenme kaydı
- `local_storage_keys.dart` — SharedPreferences key sabitleri

### lib/repositories/ (1 dosya)
- `explore_repository.dart` — Supabase stores + SharedPreferences favoriler

### lib/models/ (3 dosya)
- `store_data.dart` — ~849 satır, tüm domain modeli tek dosyada (Product, MarketplaceLink, StoreOffering, StoreGalleryItem, BookingSettings, PublishedVitrinInfo, StoreData)
- `chat_message.dart` — Chat mesaj modeli (QuickReply, XrexAction enum dahil)
- `legal_document.dart` — Yasal belge modeli

### lib/config/ (8 dosya)
- `app_router.dart` — GoRouter yapılandırması
- `business_category_config.dart` — Kategori listesi
- `chatbot_config.dart` — X-rex intent/yanıt tanımları
- `instagram_sync_config.dart` — Instagram feature flag
- `legal_config.dart` — Yasal bilgi kontrolü (data controller identity)
- `public_site_config.dart` — Public link builder
- `public_vitrin_route_config.dart` — Public vitrin route ayarları
- `turkey_cities_config.dart` — İl/ilçe listesi

### lib/utils/ (4 dosya)
- `app_error_guard.dart` — Try-catch wrapper
- `gallery_image_file_validator.dart` — Boyut/format kontrolü
- `token_generator.dart` — Edit token üretimi
- `whatsapp_link_helper.dart` — TR WhatsApp numarası doğrulama

### supabase/migrations/ (19 dosya)
`gallery_items` → `shelf_images_file_limit` → `location_fields` → `logo_url` → `products` → `storage_policies` → `user_id_and_auth_policies` → `security_advisor_warnings` → `delete_user_account` → `offerings` → `booking_system` → `google_visibility_and_blog` → `quality_and_spam_controls` → `published_at_and_updated_at` → `instagram_sync_products` → `meta_data_deletion_requests` → `retained_to_instagram_imports` → `versioned_legal_documents_and_acceptances`

### api/ (3 dosya)
- `v/[slug].js` — SEO shell (OG meta, JSON-LD schema, Flutter bootstrap)
- `sitemap.js` — Dinamik sitemap
- `robots.js` — Robots.txt

### public_web/ (Next.js projesi — FLUTTER'DAN BAĞIMSIZ)
- Public vitrin view (`/v/[slug]/page.tsx`)
- Instagram OAuth flow (connect/callback/disconnect/media/import/status)
- Booking wizard + tracker
- Blog yazilar
- Revalidate API
- Data deletion (Meta GDPR)
- Report abuse API
- `CLAUDE.md` ve `AGENTS.md` mevcut

### test/ (36 dosya)
Kapsama: controller, service, repository, widget, model testleri. `xrex_coach_test.dart` mevcut.

---

## 3. Ana Akış Haritası

### Landing → Editör
```
LandingScreen
  ├─ _loadSavedVitrinState() → AuthService.getStoreForCurrentUser()
  │   ├─ Supabase stores (edit_token sorgusu) ← DOĞRUDAN UI
  │   └─ SharedPreferences'a yaz
  └─ _navigateToEditor() → AppRouter.navigateToHomeShell(initialIndex: 1)
```

### Editör Publish Akışı
```
MyVitrinScreen._publishVitrin()
  ├─ LegalConfig kontrolü
  ├─ LegalDocumentService.loadPublishingDocuments()
  ├─ Field validation (name, whatsapp, address, province, district, googleLink)
  ├─ StoreShelfUploadService.uploadShelfImage()  → Supabase Storage
  ├─ StoreShelfUploadService.uploadGalleryImage() → Supabase Storage
  ├─ StorePublishService.publishStore()
  │   ├─ StorePublishValidator.validate()
  │   ├─ Supabase edit_token lookup
  │   ├─ Supabase slug lookup
  │   └─ rpc('update_store_with_token') veya insert
  ├─ Supabase booking_settings upsert ← DOĞRUDAN UI
  ├─ StoreLocalStorageService.savePublishedVitrinInfo()
  └─ SeoService.revalidateStore() → Next.js ISR purge
```

### Public Vitrin Görüntüleme
```
api/v/[slug].js (Vercel serverless)
  └─ Supabase REST API → stores tablosu
  └─ Dinamik HTML shell (OG, JSON-LD, Flutter bootstrap)

PublicVitrinScreen (Flutter web)
  └─ Supabase stores (slug ile) ← DOĞRUDAN UI
  └─ VitrinViewService.recordView()
  └─ VitrinView widget render
```

### X-rex Akışı
```
ChatbotBadge (Landing/MyVitrin overlay)
  └─ XrexOverlay.show() → _XrexPanel
      ├─ ChatbotService.respond() — keyword eşleme (offline)
      ├─ QuickReply.action → XrexAction enum
      └─ _handleAction() → callback zinciri (scroll/navigate/copy/qr/share)
```

### Randevu Akışı
```
BookingManagementScreen
  └─ Supabase booking_settings + bookings tabloları

AppointmentTrackerScreen
  └─ Token ile randevu durumu
```

---

## 4. Özellik Durum Tablosu

| Özellik | Durum | Açıklama |
|---|---|---|
| Publish akışı | Tamamlandı | Validation, upload, Supabase RPC, ISR purge |
| Kapak upload | Tamamlandı | FilePicker → optimize → Supabase Storage |
| Galeri upload | Tamamlandı | Max 12 fotoğraf, validation, sequential upload |
| Local save | Tamamlandı | SharedPreferences, auto-save pattern |
| Auto-fill hazır görseller | Bilinmiyor | `AutoFillBanner`, `CategoryAutoFillSheet`, `LandingTemplateCatalog` kodda bulunamadı. Bu isimlerde dosya/yapı yok |
| AutoFillBanner | Bilinmiyor | Kodda tanımı yok |
| CategoryAutoFillSheet | Bilinmiyor | Kodda tanımı yok |
| LandingTemplateCatalog | Bilinmiyor | Kodda tanımı yok |
| X-rex kalite raporu | Tamamlandı | `XrexProfileSnapshot.from()` + skor hesaplama + `_XrexScoreBar` |
| X-rex openAutoFillDialog | Bilinmiyor | `XrexAction` enum'unda böyle bir aksiyon yok. Mevcut aksiyonlar: openVitrim, openExplore, copyLink, showQr, shareWhatsapp, scrollTo* |
| Supabase migration/RPC | Tamamlandı | 19 migration, update_store_with_token, withdraw_store_publication_consent RPC'leri |
| Vercel build | Tamamlandı | Flutter web build + deploy-info.json + cache headers |
| public_web API | Tamamlandı | Next.js, Instagram OAuth, booking, blog, revalidate, data-deletion |

---

## 5. Kritik Riskler

### Risk K-1: MyVitrinScreen Tek Dosya Yükü
**Seviye:** Kritik
**Dosya:** `lib/screens/my_vitrin_screen.dart` (~1800+ satır)
**Sorun:** Tek StatefulWidget içinde publish mantığı, gallery management, booking settings, legal consent, marketplace links, Instagram sync, blog articles, location, QR, share, delete hepsi bir arada.
**Neden önemli:** Herhangi bir alan değiştirmek tüm dosyayı riske atar. Merge conflict olasılığı yüksek.
**Bozulabilecek akış:** Publish, gallery, booking, legal — hepsi.
**Minimum güvenli çözüm:** Publish mantığını `MyVitrinScreen._publishVitrin()`'den çıkarıp `StoreEditorController.publish()`'e taşıyın (controller'da zaten var ama screen kendi versiyonunu da çalıştırıyor).
**Dokunulmaması gerekenler:** `StorePublishService` payload builder dokunulmamalı.

### Risk K-2: UI'dan Doğrudan Supabase Çağrıları
**Seviye:** Kritik
**Dosya:** `landing_screen.dart:240-244`, `my_vitrin_screen.dart:422-438,854-865`
**Sorun:** Screen'ler Supabase client'ı doğrudan kullanıyor. Service/repository katmanı bypass ediliyor.
**Neden önemli:** Test edilemezlik, data access pattern tutarsızlığı, RLS policy değişikliğinde birden fazla dosyada fix lazım.
**Bozulabilecek akış:** Landing otomatik giriş, article yükleme, booking settings kaydetme.
**Minimum güvenli çözüm:** Her doğrudan Supabase çağrısını ilgili service'e taşı. `StorePublishService` veya yeni bir `BookingService` oluştur.
**Dokunulmaması gerekenler:** Supabase RLS policy'leri.

### Risk K-3: StoreData Modeli Aşırı Yüklenmiş
**Seviye:** Kritik
**Dosya:** `lib/models/store_data.dart` (~849 satır)
**Sorun:** Product, MarketplaceLink, StoreOffering, StoreGalleryItem, BookingSettings, PublishedVitrinInfo, StoreData — hepsi tek dosyada.
**Neden önemli:** Herhangi bir model değişikliği tüm dosyayı etkiler. `toJson()`/`fromJson()` karmaşıklığı hata kaynağı.
**Bozulabilecek akış:** Tüm data flow.
**Minimum güvenli çözüm:** Her modeli ayrı dosyaya çıkar. Mevcut import path'leri korunarak backward-compatible şekilde yapılabilir.
**Dokunulmaması gerekenler:** Supabase tablo isimleri, JSON key isimleri.

---

## 6. Orta Riskler

### Risk O-1: Controller ve Screen Arasında Çift Mantık
**Seviye:** Orta
**Dosya:** `store_editor_controller.dart` + `my_vitrin_screen.dart`
**Sorun:** `StoreEditorController.publish()` metodu var ama `MyVitrinScreen._publishVitrin()` de kendi publish mantığını çalıştırıyor. İkisi birbirinden bağımsız.
**Neden önemli:** Hangisinin çalıştığı zależy hangi akıştan girildiğine. Tutarsız behavior.
**Minimum güvenli çözüm:** Screen'deki publish'ı kaldır, controller'daki publish'ı kullan.

### Risk O-2: XrexAction'da openAutoFillDialog Yok
**Seviye:** Orta
**Dosya:** `lib/models/chat_message.dart` (XrexAction enum)
**Sorun:** `openAutoFillDialog` isimli aksiyon enum'da tanımlı değil. Mevcut aksiyonlar: openVitrim, openExplore, copyLink, showQr, shareWhatsapp, scrollTo*.
**Neden önemli:** Eğer bu özellik isteniyorsa önce enum'a eklenmeli, sonra _handleAction'a case eklenmeli, sonra ChatbotConfig intents'e bağlanmalı.
**Minimum güvenli çözüm:** Özellik talebi netleştirilmeli.

### Risk O-3: Booking Settings Upserd'ı Screen'de
**Seviye:** Orta
**Dosya:** `my_vitrin_screen.dart:854-865`
**Sorun:** Publish sonrası booking settings Supabase'e screen'den upsert ediliyor. Controller'da bu mantık var ama screen kendi versiyonunu da çalışıyor.
**Neden önemli:** Publish success sonrası booking başarısız olursa tutarsız state.
**Minimum güvenli çözüm:** Booking upsert'ı publish service içine taşı.

### Risk O-4: store_articles Tablosu Service Katmanında Değil
**Seviye:** Orta
**Dosya:** `my_vitrin_screen.dart:422` ve `store_editor_controller.dart:313`
**Sorun:** Her iki yerde de `Supabase.instance.client.from('store_articles')` doğrudan çağrılıyor. Ayrı bir article service'i yok.
**Minimum güvenli çözüm:** `ArticleService` oluştur.

### Risk O-5: Public Web Flutter'dan Bağımsız Deploy
**Seviye:** Orta
**Dosya:** `public_web/` (Next.js) + root `vercel.json` (Flutter)
**Sorun:** public_web ayrı bir Vercel projesi olarak deploy edilmeli (Next.js), root Flutter web ise aynı Vercel projesinde static hosting olarak. `vercel.json`'daki rewrite'lar `/v/:slug`'ı `api/v/[slug].js`'e yönlendiriyor — bu serverless function Flutter build output'undan BAĞIMSIZ çalışır.
**Neden önemli:** İkisi karıştırılırsa deploy hataları olur. Next.js projesi root'daki Flutter build'i bozar.
**Minimum güvenli çözüm:** public_web'in kendi `vercel.json`'u var, deploy'lar ayrı tutulmalı.

---

## 7. Düşük Riskler

### Risk D-1: chatbot_overlay.dart Import Hack
**Dosya:** `lib/widgets/chatbot_overlay.dart:1203-1207`
**Sorun:** `_mathRef = math.pi` ve `_servicesRef = HapticFeedback.selectionClick` gibi unused import bastırma hack'i var.
**Minimum çözüm:** Bu import'ları kaldır, unused uyarısını `// ignore_for_file` ile çöz.

### Risk D-2: Normalizasyon Fonksiyonu Tekrarı
**Dosya:** `_normalizeTurkish` hem `my_vitrin_screen.dart:608` hem `store_editor_controller.dart:564` hem `chatbot_service.dart:52` içinde tekrar ediyor.
**Minimum çözüm:** Tek bir utility fonksiyona çıkar.

### Risk D-3: XrexScreen Statik "Yakında" Etiketi
**Dosya:** `lib/screens/xrex_screen.dart:185`
**Sorun:** Tüm suggestion kartlarında "Yakında" etiketi var — özellik henüz aktif değil.
**Minimum çözüm:** Aktif olmadığında erişimi kısıtla veya screen'i tamamen kaldır.

### Risk D-4: landing_screen.dart ~1700 Satır
**Dosya:** `lib/screens/landing_screen.dart`
**Sorun:** Hero section, value band, features, comparison, trust band, steps, CTA, footer — hepsi tek dosyada.
**Minimum çözüm:** Alt section'ları ayrı widget'lara çıkar.

### Risk D-5: test/ Kapsama Eksik
**Dosya:** `test/`
**Sorun:** `my_vitrin_screen_test.dart` var ama publish akışının end-to-end testi yok. `store_publish_service_test.dart` mevcut ama integration test değil.
**Minimum çözüm:** Publish happy path + validation failure path testleri ekle.

---

## 8. Kod Kalitesi Borçları

1. **StoreData God Object** — Tek modelde 6+ alt model, ~849 satır, tüm domain temsil ediliyor
2. **MyVitrinScreen God Widget** — ~1800+ satır, publish/gallery/booking/legal/marketplace her şey bir arada
3. **Çift Publish Mantığı** — Controller'da `publish()` var ama screen'de `_publishVitrin()` de bağımsız çalışıyor
4. **Doğrudan Supabase Çağrıları** — 4 farklı noktada UI'dan Supabase'a doğrudan erişim
5. **Normalize Fonksiyonu Tekrarı** — 3 farklı dosyada aynı Türkçe karakter normalizasyonu
6. **Unused Import Hack** — `chatbot_overlay.dart` sonunda math ve HapticFeedback referans hack'i
7. **XrexScreen Boş** — Statik "Yakında" etiketli, henüz aktif değil
8. **public_web ile İletişim Kopukluğu** — Flutter app ve Next.js public_web arasında paylaşılan tip/contact yok

---

## 9. İlk Kontrol Edilmesi Gereken 5 Küçük İş

1. **`my_vitrin_screen.dart:854-865` booking settings upsert'ı** — Screen'den doğrudan Supabase çağrısı. Publish success sonrası hata olursa tutarsız state oluşur. Controller'a taşı.

2. **`landing_screen.dart:240-244` Supabase edit_token lookup** — AuthService'e taşı. Mevcut `AuthService.getStoreForCurrentUser()` zamen var ama edit_token için ayrı sorgu yapılıyor.

3. **`my_vitrin_screen.dart:422-438` article fetching** — `store_articles` tablosuna doğrudan erişim. Basit bir `ArticleService` ile çözülebilir.

4. **`chatbot_overlay.dart:1203-1207` unused import hack** — Kaldır, `// ignore_for_file: unused_import` ile değiştir veya import'ları temizle.

5. **`store_editor_controller.dart` vs `my_vitrin_screen.dart` publish çakışması** — Hangisi çalışıyor, hangisi duruyor netleştirilmeli. Controller'daki versiyon daha temiz, screen'deki versiyon legacy olarak kaldırılmalı.

---

*Bu rapor read-only analiz ile oluşturulmuştur. Hiçbir dosya değiştirilmemiştir.*

# VixRex Teknik Röntgen Raporu
> Tarih: 2026-07-06 | Güncelleme: Teknik risk doğrulaması tamamlandı

---

## 1. Klasör Doğrulaması

| Dosya | Var mı? |
|---|---|
| pubspec.yaml | ✅ |
| lib/main.dart | ✅ |
| vercel.json | ✅ |
| vercel-build.sh | ✅ |
| supabase/migrations/ | ✅ (19 dosya) |

---

## 2. Proje Haritası (Güncel)

### lib/screens/ (14 ekran)
- `landing_screen.dart` — 287 satır (refactored, 9 section widget'ı)
- `my_vitrin_screen.dart` — 248 satır (refactored, 3 section)
- `vixrex_screen.dart` — 688 satır (asistan ekranı, aktif)
- `public_vitrin_screen.dart` — Herkese açık vitrin görüntüleme
- `explore_screen.dart` — Yayınlanmış vitrinleri keşfetme
- `home_shell_screen.dart` — Alt navigasyon kabı
- `auth_screen.dart` — Giriş/kayıt
- `preview_screen.dart` — Demo vitrin önizleme
- `legal_screen.dart` — KVKK yasal ekran
- `profile_screen.dart` — Profil
- `blog_editor_screen.dart` — 732 satır, Blog yazısı düzenleme
- `blog_moderation_screen.dart` — Blog moderasyon
- `booking_management_screen.dart` — Randevu yönetimi
- `appointment_tracker_screen.dart` — Randevu takip

### lib/screens/my_vitrin/sections/
- `vitrin_form_section.dart` — 613 satır
- `vitrin_publish_section.dart` — 29 satır
- `vitrin_danger_section.dart`

### lib/controllers/ (2 dosya)
- `store_editor_controller.dart` — 798 satır, ChangeNotifier, EditorGalleryItem class'ı dahil
- `explore_controller.dart` — Keşfe yönelik controller

### lib/services/ (23 servis)
- `store_publish_service.dart` — 608 satır, Validator + PayloadBuilder + publish/withdraw
- `store_shelf_upload_service.dart` — Storage'a görsel yükleme
- `store_local_storage_service.dart` — SharedPreferences persistans
- `image_optimization_service.dart` — Görsel sıkıştırma
- `auth_service.dart` — Supabase auth
- `chatbot_service.dart` — X-rex kural tabanlı offline chatbot
- `vixrex_profile_snapshot.dart` — Vitrin durumu özeti (skor hesaplama)
- `location_service.dart` — GPS + reverse geocode
- `seo_service.dart` — Next.js ISR revalidation
- `seo_helper.dart` / `seo_helper_web.dart` / `seo_helper_mobile.dart` — Platform bazlı SEO
- `instagram_sync_service.dart` — Instagram OAuth + media import
- `legal_document_service.dart` — Versiyonlu yasal belge yükleme
- `vitrin_view_service.dart` — Görüntülenme kaydı
- `local_storage_keys.dart` — SharedPreferences key sabitleri
- **YENİ:** `article_service.dart` — Blog yazıları için Supabase servisi
- **YENİ:** `booking_service.dart` — Randevu işlemleri için Supabase servisi
- **YENİ:** `auto_fill_service.dart` — Otomatik dolgu servisi
- **YENİ:** `vixrex_guidance_service.dart` — Asistan rehberlik servisi
- **YENİ:** `vixrex_promotion_service.dart` — Tanıtım servisi
- **YENİ:** `public_store_service.dart` — Public vitrin servisi
- **YENİ:** `category_image_service.dart` — Kategori görselleri servisi

### lib/repositories/ (1 dosya)
- `explore_repository.dart` — Supabase stores + SharedPreferences favoriler

### lib/models/ (8 dosya)
- `store_data.dart` — 605 satır (849'dan düşürüldü)
- **YENİ:** `store_product.dart` — 224 satır (StoreData'dan ayrıldı)
- **YENİ:** `store_offering.dart` — StoreData'dan ayrıldı
- **YENİ:** `working_hours.dart` — StoreData'dan ayrıldı
- `chat_message.dart` — Chat mesaj modeli (QuickReply, XrexAction enum dahil)
- `legal_document.dart` — Yasal belge modeli
- `landing_demo_profile.dart` — Landing demo profilleri
- `vitrin_gallery_preview_item.dart` — Galeri önizleme modeli

### lib/widgets/editor/ (14 dosya)
- `publish_actions_section.dart`
- `gallery_editor_section.dart`
- `cover_picker_section.dart`
- `common_form_fields.dart`
- `article_summary_row.dart`
- `legal_consent_section.dart`
- `location_editor_section.dart`
- `marketplace_links_section.dart`
- `public_link_card.dart`
- `published_summary_card.dart`
- `qr_code_bottom_sheet.dart`
- `store_theme_picker.dart`
- `visibility_hub_card.dart`
- `working_hours_editor.dart` — 697 satır

### lib/widgets/landing/ (11 dosya)
- `landing_hero_section.dart` — 767 satır (büyük)
- `landing_template_catalog.dart` — 615 satır
- `landing_value_band.dart`
- `landing_comparison_section.dart`
- `landing_trust_band.dart`
- `landing_steps_section.dart`
- `landing_bottom_cta.dart`
- `landing_value_card.dart`
- `landing_setup_panel.dart`
- `phone_mockup.dart`

### lib/widgets/ (Diğer)
- `chatbot_overlay.dart` — 1005 satır (büyük)
- `booking_wizard_sheet.dart` — 733 satır

### lib/config/ (8 dosya)
- `app_router.dart` — GoRouter yapılandırması
- `business_category_config.dart` — Kategori listesi
- `chatbot_config.dart` — X-rex intent/yanıt tanımları
- `instagram_sync_config.dart` — Instagram feature flag
- `legal_config.dart` — Yasal bilgi kontrolü
- `public_site_config.dart` — Public link builder
- `public_vitrin_route_config.dart` — Public vitrin route ayarları
- `turkey_cities_config.dart` — İl/ilçe listesi

### lib/utils/ (4 dosya)
- `app_error_guard.dart` — Try-catch wrapper
- `gallery_image_file_validator.dart` — Boyut/format kontrolü
- `secure_token_generator.dart` — Token üretimi
- `whatsapp_link_helper.dart` — TR WhatsApp numarası doğrulama

### supabase/migrations/ (19 dosya)
`gallery_items` → `shelf_images_file_limit` → `location_fields` → `logo_url` → `products` → `storage_policies` → `user_id_and_auth_policies` → `security_advisor_warnings` → `delete_user_account` → `offerings` → `booking_system` → `google_visibility_and_blog` → `quality_and_spam_controls` → `published_at_and_updated_at` → `instagram_sync_products` → `meta_data_deletion_requests` → `retained_to_instagram_imports` → `versioned_legal_documents_and_acceptances`

### api/ (3 dosya)
- `v/[slug].js` — SEO shell (OG meta, JSON-LD schema, Flutter bootstrap)
- `sitemap.js` — Dinamik sitemap
- `robots.js` — Robots.txt

### public_web/ (Next.js projesi — FLUTTER'DAN BAĞIMSIZ)
- Public vitrin view (`/v/[slug]/page.tsx`)
- Instagram OAuth flow
- Booking wizard + tracker
- Blog yazilar
- Revalidate API
- Data deletion (Meta GDPR)
- Report abuse API

### test/ (36+ dosya)
Kapsama: controller, service, repository, widget, model testleri.

---

## 3. Ana Akış Haritası (Güncel)

### Landing → Editör
```
LandingScreen (287 satır, refactored)
  ├─ section widget'ları: Hero, ValueBand, Features, Comparison, TrustBand, Steps, CTA, TemplateCatalog
  └─ _navigateToEditor() → AppRouter.navigateToHomeShell(initialIndex: 1)
```

### Editör Publish Akışı
```
MyVitrinScreen (248 satır, refactored)
  ├─ vitrin_form_section.dart — Form alanları
  ├─ vitrin_publish_section.dart — Yayınla bölümü
  └─ vitrin_danger_section.dart — Tehlikeli işlemler

StoreEditorController (798 satır)
  ├─ publish() metodu — Tek publish noktası
  ├─ EditorGalleryItem — Galeri item yönetimi
  └─ Supabase RPC çağrıları
```

### Public Vitrin Görüntüleme
```
api/v/[slug].js (Vercel serverless)
  └─ Supabase REST API → stores tablosu
  └─ Dinamik HTML shell (OG, JSON-LD, Flutter bootstrap)

PublicVitrinScreen (Flutter web)
  └─ PublicStoreService → Supabase
  └─ VitrinViewService.recordView()
```

### VixRex Asistan Akışı
```
VixRexScreen (688 satır, aktif)
  ├─ VixRexGuidanceService — Rehberlik önerileri
  ├─ VixRexProfileSnapshot — Kalite raporu
  └─ VixRexPromotionService — Tanıtım metinleri

ChatbotBadge (1005 satır)
  └─ XrexOverlay.show() → _XrexPanel
      ├─ ChatbotService.respond() — keyword eşleme
      └─ QuickReply.action → callback zinciri
```

### Randevu Akışı
```
BookingManagementScreen
  └─ BookingService → Supabase RPC

AppointmentTrackerScreen
  └─ BookingService.getAppointmentByToken()
```

---

## 4. Özellik Durum Tablosu

| Özellik | Durum | Açıklama |
|---|---|---|
| Publish akışı | ✅ Tamamlandı | Validation, upload, Supabase RPC, ISR purge |
| Kapak upload | ✅ Tamamlandı | FilePicker → optimize → Supabase Storage |
| Galeri upload | ✅ Tamamlandı | Max 12 fotoğraf, validation, sequential upload |
| Local save | ✅ Tamamlandı | SharedPreferences, auto-save pattern |
| Auto-fill hazır görseller | ✅ Tamamlandı | `CategoryGallerySheet`, `LandingTemplateCatalog` mevcut |
| X-rex kalite raporu | ✅ Tamamlandı | `VixRexGuidanceService` + `VixRexProfileSnapshot` |
| X-rex rehberlik | ✅ Tamamlandı | Aktif, VixRexScreen'de gösteriliyor |
| Blog servisi | ✅ Tamamlandı | `ArticleService` oluşturuldu |
| Randevu servisi | ✅ Tamamlandı | `BookingService` oluşturuldu |
| Supabase migration/RPC | ✅ Tamamlandı | 19 migration |
| Vercel build | ✅ Tamamlandı | Flutter web build + deploy-info.json |
| public_web API | ✅ Tamamlandı | Next.js, Instagram OAuth, booking, blog |

---

## 5. Çözülen Kritik Riskler ✅

### Risk K-1: MyVitrinScreen God Widget → ÇÖZÜLDÜ
**Önceki:** ~1800+ satır tek dosya
**Şimdi:** 248 satıra düşürüldü, 3 section'a bölündü
- `vitrin_form_section.dart` — 613 satır
- `vitrin_publish_section.dart` — 29 satır
- `vitrin_danger_section.dart`

### Risk K-2: UI'dan Doğrudan Supabase Çağrıları → ÇÖZÜLDÜ
**Önceki:** Screen'lerde doğrudan Supabase erişimi
**Şimdi:** Screen'de kalmadı, sadece controller ve service katmanında

### Risk K-3: StoreData God Object → ÇÖZÜLDÜ
**Önceki:** ~849 satır tek dosya
**Şimdi:** 605 satıra düşürüldü, 3 model ayrıldı:
- `store_product.dart` — 224 satır
- `store_offering.dart`
- `working_hours.dart`

---

## 6. Çözülen Orta Riskler ✅

### Risk O-1: Controller/Screen Çift Publish → ÇÖZÜLDÜ
**Önceki:** Her ikisinde de publish mantığı
**Şimdi:** Screen'deki `_publishVitrin` kaldırıldı, sadece controller'da

### Risk O-3: Booking Settings Upserd'ı Screen'de → ÇÖZÜLDÜ
**Önceki:** Screen'den doğrudan Supabase upsert
**Şimdi:** `BookingService` oluşturuldu, service katmanında

### Risk O-4: store_articles Service Eksik → ÇÖZÜLDÜ
**Önceki:** Doğrudan Supabase çağrısı
**Şimdi:** `ArticleService` oluşturuldu

---

## 7. Çözülen Düşük Riskler ✅

### Risk D-1: chatbot_overlay Import Hack → ÇÖZÜLDÜ
**Önceki:** `_mathRef = math.pi` hack'i
**Şimdi:** Temiz import'lar

### Risk D-3: XrexScreen "Yakında" Etiketi → ÇÖZÜLDÜ
**Önceki:** Statik "Yakında" etiketi
**Şimdi:** `VixRexScreen` aktif, `VixRexGuidanceService` kullanıyor

### Risk D-4: landing_screen ~1700 Satır → ÇÖZÜLDÜ
**Önceki:** Tek dosyada her şey
**Şimdi:** 287 satıra düşürüldü, 9 section widget'ına bölündü

---

## 8. Devam Eden Riskler ⚠️

### Yeni Riskler (Büyük Dosyalar)

| Dosya | Satır | Açıklama |
|---|---|---|
| `chatbot_overlay.dart` | 1005 | Badge + Panel + mesaj mantığı tek dosyada |
| `store_editor_controller.dart` | 798 | EditorGalleryItem class'ı controller içinde |
| `landing_hero_section.dart` | 767 | Animasyon ağırlıklı |
| `booking_wizard_sheet.dart` | 733 | Tek bottom sheet |
| `blog_editor_screen.dart` | 732 | Blog düzenleme |
| `working_hours_editor.dart` | 697 | Çalışma saatleri editoru |
| `vixrex_screen.dart` | 688 | Asistan ekranı |
| `landing_template_catalog.dart` | 615 | Şablon kataloğu |
| `vitrin_form_section.dart` | 613 | Form section |
| `store_publish_service.dart` | 608 | Publish service |

### Kalan Riskler

| Risk | Durum | Açıklama |
|---|---|---|
| _normalizeTurkish tekrarı | ⚠️ Kısmi | 2 dosyada: business_category_config.dart, location_editor_section.dart |
| public_web ile İletişim Kopukluğu | ⚠️ Devam | Flutter app ve Next.js arasında paylaşılan tip/contact yok |

---

## 9. Kod Kalitesi Borçları (Güncel)

### Çözülen Borçlar ✅
1. ~~StoreData God Object~~ → 605 satıra düşürüldü, 3 model ayrıldı
2. ~~MyVitrinScreen God Widget~~ → 248 satıra düşürüldü, 3 section'a bölündü
3. ~~Çift Publish Mantığı~~ → Screen'deki kaldırıldı
4. ~~Doğrudan Supabase Çağrıları~~ → Service katmanına taşındı
5. ~~Unused Import Hack~~ → Temizlendi
6. ~~XrexScreen Boş~~ → Aktif hale getirildi

### Devam Eden Borçlar
1. **chatbot_overlay 1005 satır** — Bölünmeli (Badge, Panel, Mesaj mantığı ayrılabilir)
2. **store_editor_controller 798 satır** — EditorGalleryItem ayrılabilir
3. **Normalize Fonksiyonu Tekrarı** — 2 dosyada (önceki 3'ten azaldı)
4. **public_web ile İletişim Kopukluğu** — Paylaşılan tipler oluşturulmalı

---

## 10. Toplam Kod Büyüklüğü

- **lib/ klasörü:** 30,154 satır Dart kodu
- **Toplam dosya:** 140+ Dart dosyası
- **En büyük dosyalar:** chatbot_overlay (1005), store_editor_controller (798), landing_hero_section (767)

---

*Bu rapor 2026-07-06 tarihinde güncellenmiştir. Tüm kritik riskler doğrulanmış ve çözülmüştür.*

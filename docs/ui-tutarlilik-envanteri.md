# Flutter Paneli UI Tutarlılık Envanteri

> Tarih: 2026-08-08 · Kapsam: `lib/` (Flutter işletme paneli)
> Amaç: Ekranların neden birbirine benzemediğini ölçülebilir biçimde ortaya koymak ve düzeltme sırasını belirlemek.

## 1. Özet

| Metrik | Değer | Değerlendirme |
|---|---|---|
| Toplam Dart dosyası | 230 | — |
| `TextStyle(` literal içeren dosya | 87 | Çok yüksek |
| `Color(0x...)` literal içeren dosya | 28 | Yüksek (büyük kısmı vitrin tema preset'i) |
| `AppColors` import eden dosya | 88 | İyi |
| `AppTextStyles` import eden dosya | 3 | **Çok düşük — tipografi sistemi devre dışı** |
| Farklı `fontSize` değeri | 22 | Dağınık |
| Farklı köşe yuvarlaklığı değeri | 20 | Dağınık |
| Farklı `FontWeight` değeri | 8 | Dağınık |

**Kök neden:** `AppTextStyles` (lib/theme/app_text_styles.dart) tanımlanmış ama neredeyse hiç kullanılmıyor. `main.dart`'taki `ThemeData`'da `textTheme`, `appBarTheme.titleTextStyle` ve `cardTheme` için standartlar kısmi. Sonuç: her ekran kendi tipografisini ve kart desenini elle yazmış.

## 2. Tipografi Dağılımı

`fontSize` kullanımı (tüm `lib/`):

| Değer | Sayı | Not |
|---|---|---|
| 12 | 120 | Standart yardımcı metin |
| 13 | 99 | Etiket/form |
| 11 | 65 | Küçük yardımcı |
| 14 | 50 | Gövde metni |
| 18 | 28 | Başlık |
| 16 | 22 | Başlık |
| 10 | 22 | Çok küçük |
| 15 | 13 | Orta |
| 20, 22, 24 | 7+5+5 | Büyük başlık |
| 8, 9, 11.5, 12.5, 13.5, 14.5, 17, 28, 30, 36, 38 | 1-9 | **Tutarsız/rastgele** |

`FontWeight` kullanımı:

| Değer | Sayı |
|---|---|
| w900 | 119 |
| bold (=w700) | 100 |
| w800 | 76 |
| w700 | 61 |
| w600 | 67 |
| w500 | 9 |
| normal | 4 |
| w400 | 1 |

Aynı anlama gelen `bold` ve `w700` iki farklı gösterimle kullanılıyor; başlık hiyerarşisinin (display/section/sub) hangi ağırlıkta olduğu ekrandan ekrana değişiyor.

## 3. Köşe Yuvarlaklığı Dağılımı

| Değer | Sayı | Not |
|---|---|---|
| 12 | 85 | Tema standardı |
| 14 | 55 | Temada tanımsız |
| 10 | 44 | Temada tanımsız |
| 16 | 44 | Temada tanımsız |
| 20 | 18 | Temada tanımsız |
| 999 / 99 | 13+3 | Yuvarlak buton/çip |
| 8, 18, 22, 24, 28, 30, 34, 36, 40, 2, 4, 5, 6 | 1-10 | Rastgele |

Temada `radius12/16/20/24/30/40` sabitleri tanımlı (`AppColors.radius*`); kod bu sabitleri değil literal değerleri kullanıyor ve `14`, `10` gibi tanımsız değerler üretiyor.

## 4. Ekran İskeletleri

`lib/screens/` — arka plan ve AppBar durumu:

| Ekran | Arka plan | AppBar | Sorun |
|---|---|---|---|
| appointment_tracker | bgEditor | Evet | Başlık inline stil |
| app_settings | bgEditor | Evet | Başlık inline stil |
| auth | bgEditor | Hayır | — |
| blog_editor | (tema) | Evet | AppBar stilini tema almıyor |
| blog_moderation | (tema) | Evet | Aynı |
| booking_management | bgEditor | Evet | Başlık inline stil |
| bulk_product_upload | **surface** | Hayır | Diğerlerinden farklı zemin |
| explore | **surface** | Evet | Farklı zemin + inline AppBar |
| help_support | bgEditor | Evet | — |
| home_shell | **surface** | Hayır | Alt gezinme iskeleti, zemin farklı |
| landing | **bgLight** | Hayır | Özel marka sayfası (kabul edilebilir) |
| legal | **bgLight** | Evet | Özel sayfa ama AppBar stilini inline |
| my_vitrin | bgEditor | Hayır | Form sayfası, zemin doğru |
| notifications | bgEditor | Evet | — |
| ocr_scanner | bgEditor | Evet | — |
| product_category_management | (tema) | Evet | — |
| profile | bgEditor | Evet | — |
| public_product | (tema) | Evet | — |
| public_site_redirect | bgEditor | Evet | — |
| vixrex_onboarding_chat | bgEditor | Hayır | — |
| vixrex_screen | bgEditor | Evet | — |

**Zemin tutarsızlığı:** Çoğu ekran `bgEditor` kullanıyor; `home_shell`, `explore`, `bulk_product_upload` ve `my_vitrin` alt bölümleri `surface` kullanıyor. Kullanıcı ana panelden (`home_shell` → sekme geçişi) diğer ekranlara geçince zemin tonu değişiyor.

**AppBar sorunu:** `appBarTheme.titleTextStyle` tanımlı olmadığı için her ekran başlığı `TextStyle(color: darkText, fontWeight: w900, fontSize: 18)` gibi kendi literal stiliyle yazıyor (ör. app_settings_screen.dart:232-239, booking_management_screen.dart:118).

## 5. Kart Deseni Tekrarı

`CardTheme` tanımlı (surface + radius 12 + border) ama ekranlarda `Card` widget'ı yerine şu desen kopyala-yapıştır yapılıyor:

```dart
Container(
  decoration: BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(16), // ekrana göre 12/16/20 değişiyor
    border: Border.all(color: AppColors.border),
  ),
  ...
)
```

Bu desen en az 15+ dosyada tekrarlanıyor (app_settings, booking_management, profile, help_support, vitrin_form_section, location_editor_section, vb.). Ortak `AppCard` bileşeni yok.

## 6. Inline TextStyle Yoğunluğu (İlk 25 Dosya)

| Dosya | TextStyle sayısı |
|---|---|
| screens/bulk_product_upload_screen.dart | 27 |
| widgets/editor/location_editor_section.dart | 24 |
| screens/booking_management_screen.dart | 19 |
| screens/vixrex_onboarding_chat_screen.dart | 18 |
| widgets/landing/landing_hero_section.dart | 16 |
| screens/appointment_tracker_screen.dart | 15 |
| widgets/editor/working_hours_editor.dart | 15 |
| screens/my_vitrin/sections/vitrin_form_section.dart | 13 |
| widgets/landing/phone_mockup.dart | 13 |
| screens/explore_screen.dart | 12 |
| screens/ocr_scanner_screen.dart | 11 |
| widgets/editor/marketplace_links_section.dart | 11 |
| widgets/landing/landing_template_catalog.dart | 11 |
| screens/auth_screen.dart | 11 |
| widgets/vixrex_panel.dart | 10 |
| screens/legal_screen.dart | 10 |
| widgets/vixrex_message_bubble.dart | 10 |
| screens/home_shell_screen.dart | 9 |
| widgets/editor/gallery_editor_section.dart | 9 |
| widgets/editor/visibility_hub_card.dart | 9 |
| widgets/product/product_management_sheet.dart | 9 |
| widgets/auto_fill/category_gallery_sheet.dart | 9 |

## 7. Diğer Bulgular

- `Colors.white` literal kullanımları (ör. QR kutusu — teknik zorunluluk, dokunulmamalı) ve `Colors.red` (xml_upload_dialog.dart:117 — `AppColors.error` kullanılmalı).
- `AppColors` içinde `radius*` sabitleri var ama kod literallerle çalışıyor.
- Landing ekranı (`landing_screen.dart`, `widgets/landing/*`) kendi özel marka diliyle yazılmış — bu kasıtlı olabilir; kullanıcı onayı olmadan dokunulmamalı.
- `vitrin_theme_preset.dart` müşteri vitrininin 8 tema paletini içeriyor — panel UI'sıyla karıştırılmamalı (bilinçli ayrım).

## 8. Önerilen Düzeltme Sırası

1. **Temayı tamamla (tek değişiklik, tüm ekranlara yayılır):**
   - `appBarTheme.titleTextStyle` → ortak başlık stili (18/w900)
   - `textTheme` → displayTitle/sectionTitle/subTitle/body/caption/label standartları
   - `AppTextStyles` sabitlerini `textTheme` ile aynı değerlere çek
2. **Ortak bileşenler (`lib/widgets/common/`):**
   - `AppCard` (kart: surface + radius16 + border — en yaygın kullanım 16 olduğu için)
   - `AppSectionHeader` (bölüm başlığı + açıklama)
   - `AppScreenScaffold` (AppBar + zemin + güvenli alan + içerik boşluğu standardı)
3. **Örnek taşıma (4-5 ekran):** `app_settings`, `notifications`, `help_support`, `profile`, `booking_management` — zemin ve kart deseni ortak bileşenlere çekilir.
4. **Kalan ekranlar:** `bulk_product_upload`, `appointment_tracker`, `explore`, `auth`, `legal`, vitrin form bölümleri.
5. **Tekil düzeltmeler:** `xml_upload_dialog`'daki `Colors.red`, zemin tutarsızlıkları (home_shell/explore/bulk → bgEditor), radius literal'lerinin sabitlere çekilmesi.
6. **Doğrulama:** `flutter analyze` + görsel ekran karşılaştırma (aynı ekranda her ekranın öncesi/sonrası).

## 9. Kapsam Dışı

- `widgets/landing/*` (kasıtlı özel tasarım)
- `vitrin_theme_preset.dart` (müşteri vitrini paletleri)
- Next.js `public_web` yüzeyi (ayrı envanter gerekir)
- Flutter'da vitrin çizimi — değişmez kural gereği yasak, bu rapor yalnız panel UI'sına aittir

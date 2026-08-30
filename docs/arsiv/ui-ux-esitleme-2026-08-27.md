# Vixrex UI/UX eşitleme envanteri — 2026-08-27

Dal: `feat/web-yonetim-akislari`
İncelenen commit: `223b356c10a86df05677aa3f9a9d3fb611cd3fe0`

## Kapsam kararı

- Yönetim tasarım kaynağı: Flutter `AppColors` + `AppTheme`. Aktif yönetim ekranları bu katmanı sistematik kullanıyor.
- Landing izolasyonu: Next.js `--color-lp-*` korunur.
- Canlı vitrin izolasyonu: Next.js `:root` ve `.vitrin-shell` değerleri korunur; 29 public vitrin etkilenmez.
- Public renderer: Next.js `/v/[slug]`; Flutter public route'ları yönlendirme ekranıdır.
- Düzenleme kapıları: Flutter manuel panel + Next.js owner assistant. Üçüncü web form paneli oluşturulmaz.
- Veri/servis/API/URL/auth/SEO mimarisi değiştirilmez.

## Ekran envanteri

| Ekran | Platform | Route | Dosya | Kullanıcı | Görevi / ana bileşenler | Veri kaynağı | Karşı platform |
|---|---|---|---|---|---|---|---|
| Landing | Flutter | `/` | `lib/screens/landing_screen.dart`, `lib/widgets/landing/` | Ziyaretçi | Marka, değer önerisi, maket asistan | Statik/maket | Next `/` |
| Landing | Web | `/` | `public_web/src/app/(site)/page.tsx` | Ziyaretçi | SSR landing, telefon maketi, CTA | Sunucu + statik | Flutter landing |
| Giriş / kayıt | Flutter | `/auth` | `lib/screens/auth_screen.dart` | Ziyaretçi | E-posta, şifre, Google, reset, giriş/kayıt modu | Supabase Auth | Web `/giris`, `/kayit` |
| Giriş | Web | `/giris` | `public_web/src/app/giris/page.tsx` | Ziyaretçi | E-posta/şifre girişi | Supabase Auth | Flutter `/auth` |
| Kayıt | Web | `/kayit` | `public_web/src/app/kayit/page.tsx` | Ziyaretçi | Hesap ve e-posta doğrulama | Supabase Auth | Flutter `/auth` |
| Onboarding | Flutter | `/onboarding-chat` | `lib/screens/vixrex_onboarding_chat_screen.dart` | Yeni owner | Altı adımlı vitrin kurulum yolculuğu | Mevcut servisler | Web owner assistant (tam eşdeğer doğrulanamadı) |
| Ana yönetim | Flutter | `/app`, `/home` | `lib/screens/home_shell_screen.dart` | Owner | Vitrinim, Keşfet, Vixrex, Profil navigasyonu | Mevcut ekran state/service | Web `/app` |
| Ana yönetim | Web | `/app` | `public_web/src/app/app/page.tsx` | Owner | Tek vitrini açma veya ilk vitrini oluşturma | Supabase + `/api/create-store` | Flutter `Vitrinim` |
| Vitrin yönetimi | Flutter | `/app` içi | `lib/screens/my_vitrin_screen.dart`, `lib/screens/my_vitrin/` | Owner | Bilgi, görünüm, yayın ve yönetim girişleri | Mevcut repository/service | Web `/v/[slug]` owner assistant |
| Ürün listesi | Flutter | sheet | `lib/widgets/product/product_management_sheet.dart` | Owner | Liste, arama, filtre, toplu işlem | Mevcut product katmanı | Web: eksik |
| Ürün ekle/düzenle | Flutter | sheet | `lib/widgets/product/product_editor_sheet.dart` | Owner | Ürün formu, doğrulama, kaydet | Mevcut product katmanı | Web: eksik |
| Kategori yönetimi | Flutter | iç ekran | `lib/screens/product_category_management_screen.dart` | Owner | Ürün kategorileri | Mevcut product katmanı | Web: eksik |
| Toplu ürün yükleme | Flutter | iç ekran | `lib/screens/bulk_product_upload_screen.dart` | Owner | Toplu katalog girişi | Mevcut product katmanı | Web: eksik |
| Keşfet | Flutter | shell sekmesi | `lib/screens/explore_screen.dart` | Kullanıcı | Vitrin keşfi | Mevcut servis | Web `/kesfet` |
| Keşfet | Web | `/kesfet`, `/kesfet/[kategori]` | `public_web/src/app/(site)/kesfet/**/page.tsx` | Ziyaretçi | SSR vitrin/kategori keşfi | Sunucu veri erişimi | Flutter Keşfet |
| Public vitrin | Flutter | `/v/:slug` | `lib/screens/public_site_redirect_screen.dart` | Ziyaretçi | Canonical web vitrine yönlendirir | URL/deep link | Web `/v/[slug]` |
| Public vitrin | Web | `/v/[slug]` | `public_web/src/app/v/[slug]/page.tsx`, `VitrinProfileView.tsx` | Ziyaretçi / owner | Public sunum; owner ise assistant düzenleme kapısı | Sunucu veri erişimi | Canonical |
| Public ürün | Flutter | `/v/:slug/urun/:productSlug` | `lib/screens/public_product_screen.dart` | Ziyaretçi | Canonical web ürüne geçiş/uyum | URL/deep link | Web public ürün |
| Public ürün | Web | `/v/[slug]/urun/[productSlug]` | `public_web/src/app/v/[slug]/urun/[productSlug]/page.tsx` | Ziyaretçi | SSR ürün bilgisi, vitrin bağlantısı | Sunucu veri erişimi | Canonical |
| Profil | Flutter | shell sekmesi | `lib/screens/profile_screen.dart` | Owner | Hesap ve profil | Auth/profile service | Web: eksik |
| Ayarlar | Flutter | iç ekran | `lib/screens/app_settings_screen.dart` | Owner | Uygulama tercihleri | Yerel/servis | Web: eksik |
| QR / paylaşım | Flutter | Vitrinim içi widget/aksiyon | `lib/screens/my_vitrin_screen.dart` | Owner | Vitrin URL paylaşımı | Vitrin kimliği | Web public/owner içi kısmi |
| Randevu yönetimi | Flutter | `/bookings/:slug` | `lib/screens/booking_management_screen.dart` | Owner | Randevu yönetimi | Booking service | Web public randevu akışı var, owner yönetimi eksik |
| Moderasyon/admin | Flutter | shell koşullu sekme | `lib/screens/blog_moderation_screen.dart` | Admin | Blog moderasyonu | Mevcut admin katmanı | Web: eşdeğer bulunamadı |

## Ekran eşleştirme matrisi

| Kullanıcı amacı | Flutter | Web | Görsel uyum | Davranış uyumu | Durum |
|---|---|---|---|---|---|
| Marka/landing | Landing | `/` | Aynı landing token ailesi | Maket sohbet iki tarafta da ürün motoru değildir | TAM UYUMLU |
| E-posta ile giriş | `/auth` | `/giris` | Yönetim teması eşitlendi | Flutter Google seçeneği web'de yok | DAVRANIŞ FARKI |
| Kayıt | `/auth` kayıt modu | `/kayit` | Yönetim teması eşitlendi | Ayrı route platform farkı; doğrulama korunuyor | GÖRSEL FARK |
| İlk vitrin oluşturma | Onboarding/Vitrinim | `/app` | Token, form ve CTA dili eşitlendi | Flutter altı adım; web kısa başlangıç + owner assistant | BİLGİ MİMARİSİ FARKI |
| Mevcut vitrini yönetme | `Vitrinim` | `/app` → `/v/[slug]` | `Vitrinim`, durum ve CTA eşitlendi | Web owner assistant, Flutter manuel panel | TAM UYUMLU (platform rolü) |
| Ürün listeleme/yönetme | Product management sheet | Bulunamadı | — | API yazma yolları var; okuma/UI yok | WEB EKSİK |
| Ürün ekleme/düzenleme | Product editor sheet | Bulunamadı | — | Yeni sorgu eklemeden gerçekleştirilemez | WEB EKSİK |
| Ürün silme/onay | Flutter confirmation | Bulunamadı | — | Web UI yok | WEB EKSİK |
| Keşfet | Explore | `/kesfet` | Public tema kasıtlı ayrı | Ana amaç aynı | GÖRSEL FARK |
| Public vitrin görme | Web'e yönlendirme | SSR `/v/[slug]` | Tek canonical renderer | Aynı URL/kimlik | TAM UYUMLU |
| Public ürün görme | Web uyumu/yönlendirme | SSR ürün route'u | Tek canonical renderer | Aynı ürün kimliği | TAM UYUMLU |
| Profil/ayarlar | Mevcut | Bulunamadı | — | — | WEB EKSİK |
| Moderasyon | Mevcut, role bağlı | Bulunamadı | — | — | WEB EKSİK |

## Kritik akış karşılaştırması

| Akış | Flutter | Web | Sonuç |
|---|---|---|---|
| Login → yönetim | `/auth` → `/app` | `/giris` → `/app` | Adım sayısı uyumlu; auth sağlayıcı farkı var |
| Vitrin oluştur → kaydet | Onboarding/Vitrinim | `/app` → `/v/[slug]` | Web daha kısa; domain sonucu aynı |
| Vitrin düzenle → yayınla | Vitrinim manuel panel | Public renderer içi owner assistant | Kasıtlı iki düzenleme kapısı |
| Ürün oluştur/düzenle/sil | Flutter ürün sheet'leri | UI bulunamadı | WEB EKSİK |
| Public vitrini/ürünü gör | Canonical web route'a geçiş | SSR public route | Tek renderer, uyumlu |

## Design token haritası

| Token | Flutter | Next.js yönetim scope'u | Uyum |
|---|---|---|---|
| Primary | `AppColors.primary #147DFF` | `--owner-primary #147DFF` | TAM |
| Primary dark | `#0B5FD7` | `--owner-primary-dark #0B5FD7` | TAM |
| Secondary | `#57B7FF` | `--owner-secondary #57B7FF` | TAM |
| Background | `bgEditor #050B1A` | `--owner-bg #050B1A` | TAM |
| Background soft | `bgLight #08132D` | `--owner-bg-soft #08132D` | TAM |
| Surface | `surface #0B1730` | `--owner-surface #0B1730` | TAM |
| Surface soft | `surfaceSoft #112448` | `--owner-surface-soft #112448` | TAM |
| Text primary | `darkText #F7FBFF` | `--owner-text #F7FBFF` | TAM |
| Text secondary | `darkTextAlt #D9E7FF` | `--owner-text-alt #D9E7FF` | TAM |
| Muted | `muted #A9BBDA` | `--owner-muted #A9BBDA` | TAM |
| Border | `border #294D88` | `--owner-border #294D88` | TAM |
| Success | `#10B981` | `--owner-success #10B981` | TAM |
| Warning | `#F59E0B` | `--owner-warning #F59E0B` | TAM |
| Error | `#EF4444` | `--owner-error #EF4444` | TAM |
| Font | Outfit | global Outfit zinciri | TAM |
| Type | 24/18/16/14/12 | 24–30/20/16/14/12 responsive | PLATFORM UYUMLU |
| Spacing | 4/8/12/16/24/32 | Tailwind 1/2/3/4/6/8 | TAM |
| Radius | 10/12/16/24/pill | 10/12/16/pill | TAM |
| Shadow | küçük/orta/büyük tema gölgeleri | owner card + primary CTA gölgeleri | KISMİ |

`--color-lp-*`, public `--primary` ve `.vitrin-shell` bu haritanın parçası değildir; bilinçli olarak ayrı bırakılmıştır.

## Ortak bileşen envanteri

| Alan | Flutter | Web | Değerlendirme |
|---|---|---|---|
| Button | `AppButton` + native/ikon varyantları | Yönetimde `owner-button-primary/secondary` | Yönetim semantiği eşitlendi; repo genelinde legacy varyantlar var |
| Input | `AppTheme.inputDecorationTheme` | `owner-label` + `owner-input` | Yönetim form dili eşitlendi |
| Card | `AppCard` | `owner-card`; public kartlar ayrı | Doğru domain ayrımı |
| Empty/loading | `AppEmptyState`, `AppSkeleton` | `/app` inline erişilebilir state | Web ortak state bileşeni eksik |
| Status | `StatusChip` | owner yayın/taslak rozeti | Renk + metin uyumlu |
| Product card | Public ve management sorumluluklarına göre ayrı | Public catalog bileşenleri; management yok | Duplicate sayılmadı |
| Store card | Flutter Vitrinim/Keşfet varyantları | `VitrinKarti` public; owner card | Kullanıcı tipi nedeniyle ayrı tutuldu |
| Avatar | `VixrexAvatar` ve domain avatarları | Public vitrin avatarları | Management ortaklığı yok |
| WhatsApp/share | Flutter aksiyonları | Public tracked CTA bileşenleri | Public kapsamda korundu |
| Header/navigation | `HomeShellScreen` bottom nav/rail | Site header + owner header | Platform-native fark korundu |

Kod taramasında Flutter ortak katmanda `AppButton`, `AppCard`, `AppEmptyState`, `AppSectionHeader`, `AppSkeleton`, `StatusChip` bulundu. Web'de genel bir ikinci UI kütüphanesi yoktur; bu çalışma yeni bağımlılık veya component framework eklemez.

## Değişiklik kayıtları

### Giriş / kayıt

- Flutter: `AuthScreen`; davranışı korunur.
- Next.js: `/giris`, `/kayit`; Supabase çağrıları ve route'lar korunur.
- Ana farklar: rastgele siyah/mavi palet, placeholder-only alanlar, zayıf focus/error dili.
- Değişiklik: owner tokenları, ortak auth iskeleti, label, 48 px kontrol, focus-visible, alert/busy semantics.
- Responsive: 320+ tek kolon; 640+ geniş padding ve yatay yardımcı linkler.
- Risk: Google auth davranış farkı devam eder.

### Vitrinim

- Flutter: shell içinde `Vitrinim`.
- Next.js: `/app`.
- Ana farklar: “Yönetim Paneli / Vitrinlerim / Yeni Vitrin” çoğul dili tek-vitrin domain kuralıyla çelişiyordu.
- Değişiklik: `Vitrinim`, `Vitrini Yönet`, metinli yayın durumu; mevcut vitrin varken oluşturma formunun gösterilmemesi.
- Responsive: mobile stacked header/form; desktop iki kolonlu ilk-vitrin alanı ve geniş içerik.
- Korunan davranış: mevcut Supabase select, create-store, owner-session ve public vitrin geçişi.
- Risk: Web ürün yönetimi bulunmadığından owner akışı tamamlanmış değildir.

## Doğrulama

- `node --test tests/owner-ui-contract.test.mjs`: 4/4 geçti.
- Değiştirilen TSX dosyalarında hedefli ESLint: 0 hata, 0 uyarı.
- Repo genel ESLint: değişiklik dışı 17 mevcut uyarı nedeniyle `--max-warnings=0` başarısız.
- Tam TypeScript/dev render: çalışma kopyasındaki bağımlılık setinde `@sentry/nextjs`, `@playwright/test` ve `sanitize-html` bulunmadığından bloke.
- Statik responsive inceleme: 320–375, 390–430, 768, 1024 ve 1280+ sınıf davranışları kontrol edildi.
- SEO guard: `/`, `/kesfet`, `/v/[slug]` server entry dosyalarında `use client` olmadığı sözleşme testiyle doğrulandı.

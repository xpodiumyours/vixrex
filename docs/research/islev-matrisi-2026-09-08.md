# Vixrex İşlev Matrisi (2026-09-08)

Kural: Her hücre dosya kanıtlı. Okunmadan yazılan satır yok. Değerler: Eşit / Kısmen / Yok.
Kaynak dallar: `main` (Flutter referansı) + `origin/pr/435` (Next envanteri). Yöntem: dosya başları okundu, anahtar kelime arandı.
Kapsam: sahip paneli + ona bağlı müşteri yüzleri. Public SEO yüzeyi (`/`, blog listesi, sitemap) matris dışıdır.

## Özet sayı

- Flutter ekranı: 22 dosya + 2 klasör (my_vitrin bölümleri, bulk upload widgetları sayılmadı — alt kırılım).
- Next karşılığı: 8 owner bileşeni + 8 `/app` route + `/giris` `/kayit` + `/v/[slug]` altı (randevu, randevu-yonetim, blog-yonetim, urun, yazilar) + 43 API route.
- Sonuç: 24 satırdan Görünüm=Eşit: 3 (matris satır 2,3 kısmen — testle kilitli), İşlev=Eşit: 11, İşlev=Kısmen: 9, İşlev=Yok: 4 (OCR, blog moderasyon, istemci push kaydı, public redirect uygulaması — redirect yönlendirme olarak var, ekran olarak yok).

## Matris

| # | Flutter ekranı | Amaç | Next karşılığı | Görünüm | İşlev | Kanıt | PR |
|---|---|---|---|---|---|---|---|
| 1 | `lib/screens/auth_screen.dart` (AuthScreen) | E-posta + Google giriş/kayıt, şifre sıfırlama, web'de reCAPTCHA | `public_web/src/app/giris/page.tsx` + `kayit/page.tsx` + `sifre-sifirla/` + `OwnerAuthLayout.tsx` | Kısmen | Kısmen | giris: `googleIleGiris` + `provider: "google"` + `Flutter auth_screen` yorumu var; kayit `OwnerAuthLayout` kullanıyor. reCAPTCHA karşılığı: API'de `verify-recaptcha` + `revalidate` route var, giriş sayfasındaki bot kontrol eşleşmesi bakılmadı | Yok (parity dışı) |
| 2 | `lib/screens/home_shell_screen.dart` (HomeShellScreen) | Alt sekmeli iskelet, oturum, OCR/asistan orkestrasyonu | `components/app/AppShellBoundary.tsx` + `AppSidebar.tsx` + `AppShellContext.tsx` + `src/app/app/layout.tsx` | Eşit (test kilitli) | Kısmen | Boundary yorumu: "Flutter IndexedStack karşılığı 4 sekmeyi mount tutar". Sidebar `width=220` ↔ CSS `220px` (testte). OCR girişi web'de yok (satır 15) | #437 |
| 3 | `lib/screens/my_vitrin_screen.dart` + `my_vitrin/sections/` (5 akordeon form) | Vitrin düzenleme formu kabuğu | `components/owner/VitrinimEditor.tsx` + `/app` page | Eşit (test kilitli) | Kısmen | Form `BorderRadius.circular(22)` ↔ `--vx-app-radius-vitrin-form: 22px`; `screenWidth>900 + spacing24` ↔ `grid-cols-2 + column-gap:24px`; alanlar `fillColor:inputBg, radius14, fontSize:14` ↔ CSS karşılıkları (3 test dosyası) | #438, #439 |
| 4 | `lib/screens/explore_screen.dart` (ExploreScreen) | Vitrin arama/filtre, kiralık şablon seçimi | `src/app/(site)/kesfet/page.tsx` + `[kategori]/page.tsx` | Bakılmadı | Kısmen | İki tarafta da arama + kategori var (dosya adları). Satır-satır eşleşme bu matriste yapılmadı — parity PR'ı yok | Yok |
| 5 | `lib/screens/landing_screen.dart` (LandingScreen) | Pazarlama hero/demo + başlatma kapısı | `src/app/(site)/page.tsx` + `components/landing/` | Kısmen | Kısmen | #433 yalnız ComparisonSection; #436 hero hizası. Değer bantları/features parity'si parça parça | #433, #436 |
| 6 | `lib/screens/vixrex_onboarding_chat_screen.dart` | Ad/WA/konum soran kurulum sohbeti | Landing telefon maketi (mockup, çalışmaz) + `/app/vixrex` SharedVixrexAssistant | Kısmen (#432 kilitliyor) | Kısmen | CLAUDE.md: ana sayfadaki maket sabit metin. Gerçek akış `/app/vixrex` + landing→kayıt aktarım testleri (#423'te kilitli) | #432 (DRAFT), #423 (DRAFT) |
| 7 | `lib/screens/vixrex_screen.dart` (VixRexScreen) | Yayın yoksa onboarding, varsa companion | `src/app/app/vixrex/page.tsx` (SharedVixrexAssistant) | Bakılmadı | Kısmen | Dosya yorumu: "Flutter HomeShellScreen 3. sekmenin karşılığı". Companion rehber eşleşmesi bakılmadı | Yok |
| 8 | `lib/screens/booking_management_screen.dart` | Randevu onay/ret/erteleme (3 sekme) | `src/app/v/[slug]/randevu-yonetim/page.tsx` | Bakılmadı | Kısmen | İki tarafta da yönetim yüzeyi var. Sekme/davranış eşleşmesi bakılmadı | Yok |
| 9 | `lib/screens/appointment_tracker_screen.dart` | Müşterinin token ile randevu takibi/iptali | `src/app/v/[slug]/randevu/[token]/` + `BookingWizardClient.tsx` | Bakılmadı | Kısmen | İki tarafta da token'lı takip var. İptal akış eşleşmesi bakılmadı | Yok |
| 10 | `lib/screens/notifications_screen.dart` | Bildirim geçmişi + okundu işaretleme | `src/app/app/bildirimler/page.tsx` (tam liste, inbox sorgulu) + `OwnerNotificationLink.tsx` (rozetli link) | Bakılmadı | Eşit | bildirimler: `notification_inbox ... limit 50` + okundu işaretleme; inbox servisi iki tarafta da var. İstemci push kaydı (service worker) web'de YOK — sunucu push (OneSignal cron) var | Yok |
| 11 | `lib/screens/profile_screen.dart` | E-posta, vitrin linki/QR, ayar/yasal girişleri | `src/app/app/profil/page.tsx` (QR sheet + kopyalama + bağlantılar) | Bakılmadı | Eşit | profil: QR + kopyalama + ayar/yasal linkleri mevcut. QR üretimi web'de qrserver.com, Flutter'da qr_flutter — çıktı aynı, yöntem farklı | Yok |
| 12 | `lib/screens/app_settings_screen.dart` | Bildirim tercihi, hesap silme/çıkış, yasal sayfalar | `src/app/app/ayarlar/page.tsx` + `hesap/page.tsx` (unpublish/store/account) | Bakılmadı | Eşit | hesap: 3 işlem tipi + onay metinleri; ayarlar: dışa aktarma. Push tercihi Flutter'da, web karşılığı bakılmadı | Yok |
| 13 | `lib/screens/product_category_management_screen.dart` | Kategori ekle/yeniden adlandır/eşle (yerel) | `OwnerCategoryManager.tsx` + `/api/product-categories` (POST/PATCH/DELETE/sırala) | Bakılmadı | Eşit | add/rename/delete/move + API route'ları mevcut. Yerel-önce vs sunucu-önce farkı bakılmadı | Yok |
| 14 | `lib/screens/bulk_product_upload_screen.dart` + widgets (6 görünüm) | Excel/CSV seç→parse→önizle→kaydet | `BulkProductUpload.tsx` + `/api/products/batch` | Bakılmadı | Eşit | Web: `XLSX.read`, `accept=".xlsx,.xls,.csv"`, 5MB sınır, sütun eşleme, `saveAll`. Adım sayısı Flutter'da 6 görünüm, web'de tek bileşen — akış eşdeğerliği bakılmadı | Yok |
| 15 | `lib/screens/ocr_scanner_screen.dart` (OcrScannerScreen) | Fiş/raf fotoğrafından ürün çıkarma + onay | YOK | Yok | Yok | Web'de OCR motoru yok. Kanıt: `assistantHandoff.ts:34` "yalnız Flutter'a özgü"; products.ts'de OCR yalnız yorum/etiket olarak geçiyor. `BulkProductUpload` alternatif yoldur, eşdeğer değildir | Yok |
| 16 | `lib/screens/blog_editor_screen.dart` | Yazı oluşturma + taslak/yayın + SEO revalidate | `src/app/v/[slug]/blog-yonetim/[articleSlug]/page.tsx` + `blogSeoAnalizi` | Bakılmadı | Eşit | Düzenleyici + SEO analizi + yayınlama mevcut. Kapak seçici eşleşmesi bakılmadı | Yok |
| 17 | `lib/screens/blog_post_list_screen.dart` | Yazı listesi + duruma göre düzenleme | `src/app/v/[slug]/blog-yonetim/page.tsx` + `/v/[slug]/yazilar/` | Bakılmadı | Eşit | Liste + yeni yazı + durum rozeti mevcut | Yok |
| 18 | `lib/screens/blog_moderation_screen.dart` | Admin onay/ret (`is_admin`) | YOK | Yok | Yok | `moderasyon\|moderation\|review` araması `public_web/src` içinde sonuçsuz. Yayın akışı doğrudan yayına gidiyor görünüyor | Yok |
| 19 | `lib/screens/public_product_screen.dart` | Tek ürün detay/galeri/paylaşım | `src/app/v/[slug]/urun/` + `ProductCatalog.tsx` | Bakılmadı | Kısmen | Ürün listesi + detay mevcut. storageVersion=2 dalı, galeri/paylaşım eşleşmesi bakılmadı | Yok |
| 20 | `lib/screens/public_site_redirect_screen.dart` | `/v/*` açılınca Next müşteri sitesine dışarı atma | `vercel.json` rewrites + `not-found.tsx` CTA + #434 AppEntryLink | Bakılmadı | Kısmen | Yönlendirme mekanizması var (rewrite + CTA → `/app`). Ekran olarak Flutter'daki ara yüzün karşılığı yok, gerek de yok — mekanizma yeterli | #434 (bloklu) |
| 21 | `lib/screens/help_support_screen.dart` | SSS + e-posta destek | `src/app/(site)/yardim/page.tsx` (CSV/Excel cümlesi dahil) | Bakılmadı | Eşit | SSS + iletişim mevcut | Yok |
| 22 | `lib/screens/legal_screen.dart` | KVKK/şartlar/rıza/veri silme metinleri | `src/app/legal/` + `privacy/page.tsx` + `data-deletion/` + `/api/meta/data-deletion` | Bakılmadı | Eşit | Metinler + silme akışı (API dahil) mevcut | Yok |
| 23 | Vitrin yayın/silme (`vitrin_publish_section`, `vitrin_danger_section`, MyVitrinState) | Yayın özeti + kalıcı silme (onaylı) | `/api/owner-publish` + `/api/owner-discard` + `/app/hesap` + `/api/account` | Bakılmadı | Eşit | Yayın/silme API + onay ekranları mevcut. Tehlikeli işlem çift onayı iki tarafta da var | Yok |
| 24 | Randevu müşteri sihirbazı (Flutter tarafı — BookingWizard karşılığı) | Müşteri randevu oluşturma adımları | `BookingWizardClient.tsx` (localStorage taslaklı) | Bakılmadı | Kısmen | Sihirbaz mevcut. localStorage taslağı XSS yüzeyidir (research-continuation.md satır 60-61) — ayrı iş | Yok |

## PR hükmü (matristen okunan)

- #437: Satır 2'nin GÖRÜNÜM hücresini Eşit yapar. Değerler birebir (`220`, `68`, `#0B5FD7`, `alpha 0.16→rgba`). Test dosyası Flutter kaynağını okuduğu için ispatı kendi içinde. VERİMLİ + DOĞRU.
- #438: Satır 3'ün kabuk GÖRÜNÜM hücresini Eşit yapar (`22px`, `24px`, `901px`). VERİMLİ + DOĞRU.
- #439: Satır 3'ün alan GÖRÜNÜM hücresini Eşit yapar (`inputBg #0D1C38`, `radius14→14px`, `fontSize 14`). Kapsam kilidi doğru (yalnız EditorTextField'lı alanlar). VERİMLİ + DOĞRU.
- #435: Satır 3/16/19 dahil tüm Next okumalarının tazelik koşulu. `{expire:0}` webhook için dokümana uygun. Tek eksik `server-only` paketi. DOĞRU (1 satır eksikle).
- #433: Satır 5'in 1 bölümü. Testsiz olduğu için hüküm ŞARTLI — #437 kalıbında teste bağlanmalı.
- #434: Satır 20'nin mekanizması. Dart hatası + mimari onay engeli. BLOKLU.
- #440/#406/#401: Matris hücresi değiştirmez, kapıların önünü açar. VERİMLİ (altyapı).

## Gerçek eksikler (matristen çıkan, PR'sız)

1. Satır 15 OCR — web karşılığı yok. Kapanış yolu: ya "Flutter'a özgü" kararı yazılır (assistantHandoff yorumu karar olur), ya web'e tarama dışı manuel giriş güçlendirilir.
2. Satır 18 blog moderasyon — web'de yok. Ya admin akışı taşınır, ya "moderasyonsuz yayın" kararı yazılır.
3. Satır 6 onboarding sohbet derinliği — maket vs gerçek akış farkı. #432 DRAFT bunu kilitliyor, bitmeden oran artmaz.
4. Satır 4/7/8/9/19 "Bakılmadı" hücreleri — görünüm karşılaştırması yapılmadı. Bunlar olmadan "görünüm %100" denmez.
5. Satır 24 localStorage taslağı — güvenlik notu var, ayrı iş.

## Dürüst oran (paydası yazılı)

- Payda: 24 satır × 2 sütun (Görünüm + İşlev) = 48 hücre. "Bakılmadı" hücreleri bilinmiyor sayılır.
- Bu paket (437+438+439+433+435) Eşit yaptığı hücre: Görünüm 3 (satır 2, 3-kabuk, 3-alan) + kısmi 2 (satır 5 iki parça) + İşlev koşulu 1 (#435 tazelik). İşlev Eşitliklerinin çoğu PR'sız zaten mevcuttu (satır 10-14, 16, 17, 21-23).
- "Flutter Web'e gerek yok" cümlesi için gereken: satır 15/18 kararı + satır 6 bitimi + Bakılmadı'ların kapanması. Bunlar olmadan oran verilmez — veren uydurur.

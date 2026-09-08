# Vixrex Uyum Sözleşmesi — İndeks (17 matris)

**Referans:** Çalışan Flutter Web (`main@29c13c09`). **Kural:** Flutter değiştirilmez.
**Kaynak:** `VIXREX-UYUM-SOZLESMESI.md` (8 Eylül 2026, doğrulanmış kabul edildi; 2 yol düzeltmesi bu indekste uygulandı).
**Dürüstlük kuralı:** `✓` yalnız kod + onu kilitleyen test birlikte görüldüyse. Test dosyasının varlığı, testin geçtiği anlamına gelmez. `main`de olmayan test açıkça yazılır.

Düzeltmeler (denetimde bulundu): `StatusBar.tsx` yolu `components/kesfet/` altındadır; `canonicalPublicStoreUrl` adında metot yoktur, karşılığı `PublicSiteConfig.buildVitrinLink` + canonical `/v/slug` yorumudur (`lib/config/public_site_config.dart:126`).

## 1. İşlev matrisi

| İşlev | Flutter (kaynak) | Next.js (kaynak) | İlgili test (main) | Eksik kontrol | Durum |
|---|---|---|---|---|---|
| Ana uygulama kabuğu | `HomeShellScreen` (`lib/screens/home_shell_screen.dart`) | `AppShellBoundary` + `AppSidebar` (`public_web/src/components/app/`) | `f5-shell-parite.test.ts` (var) | Sıra/kalıcılık E2E | △ |
| Vitrin oluşturma | Vixrex kurulum akışı + `StorePublishService` | `/app` + `/api/create-store` | uçtan uca test yok | Zorunlu alan + sahiplik + taslak sonucu E2E | △ |
| Vitrin düzenleme | `MyVitrinScreen` + `StoreEditorController` | `/app`, `/v/[slug]` yönetim modu | alan sözleşmesi kısmi | Alan→kolon yazım E2E | △ |
| Vitrin yayınlama | `store_publish_validator.dart` + `store_publish_service.dart` | `/api/owner-publish` + `publish_working_draft` RPC | hazırlık testi (bakılmadı) | RPC kapı eşliği | △ |
| Yayın linki açma | `PublicSiteConfig.buildVitrinLink` (`lib/config/public_site_config.dart`) | `/v/[slug]` | yok (belirtilmedi) | Kanonik link testi | △ |
| Link kopyalama | profil/kabuk | durum çubuğu/profil | yok (belirtilmedi) | Yayınsızken üretilmeme testi | △ |
| QR gösterme | `qr_code_bottom_sheet.dart` | `VitrinQrSheet.tsx` | yok (belirtilmedi) | Yayınlı slug URL testi | △ |
| Keşfet listeleme | `ExploreScreen` | `/kesfet` | `kesfet-esitlik-contract.test.ts` (var) | Canlı veri kart eylemleri | △ |
| WhatsApp iletişim | Keşfet/vitrin kartı | `VitrinKarti`/public vitrin | yok (belirtilmedi) | Geçersiz numara davranışı | △ |
| Vixrex asistan | `VixRexScreen` + tek `StoreEditorController` | `/app/vixrex` + owner asistan (`useOwnerChat`) | `assistant-continuity-baseline.test.ts` (var) | 46 alan sonuç eşitliği | △ |
| Ürün yönetimi | ürün yönetimi/OCR/XML ekranları | `/app/urunler` + Products API | yok (belirtilmedi) | CRUD sözleşme eşliği | △ |
| Görsel yükleme | `StoreShelfUploadService` | `/api/owner-upload` | `gorsel-sikistirma.test.ts` (var) | 1600px/82 sözleşme E2E | △ |
| Bildirimler | `NotificationsScreen` | `/app/bildirimler` | yok (belirtilmedi) | Yükleme/hata/boş/dolu anlam eşliği | △ |
| Profil | `ProfileScreen` | `/app/profil` | `owner-ui-contract.test.ts` (var) | Hesap eylemleri karşılaştırması | △ |
| Ayarlar | `AppSettingsScreen` | `/app/ayarlar` | yok (belirtilmedi) | Eylem eşliği | △ |
| Blog yönetimi | blog ekranları | `/v/[slug]/blog-yonetim` | yok (belirtilmedi) | Taslak/yayın/SEO + yetki | △ |
| Randevu yönetimi | booking ekranları | `/v/[slug]/randevu-yonetim` | yok (belirtilmedi) | Saat/kapasite/durum geçişleri | △ |
| OCR ürün ekleme | `OcrScannerScreen` | yok (bilinçli) | — | İstisna kararı yazılı duruyor; ürün sonucu ortak veriye yazılmalı | İstisna |

## 2. Ekran ve menü matrisi

| Flutter | Next rotası | Menü konumu | İlgili test (main) | Eksik kontrol | Durum |
|---|---|---|---|---|---|
| Vitrinim | `/app` | 1 | `f5-shell-parite.test.ts` (var) | — | △ |
| Keşfet | `/kesfet` | 2 | `kesfet-esitlik-contract.test.ts` (var) | — | △ |
| Vixrex | `/app/vixrex` | 3 | belirtilmedi | sıra testi | △ |
| Profil | `/app/profil` | 4 | `owner-ui-contract.test.ts` (var) | — | △ |
| Ürün yönetimi | `/app/urunler` | Vitrinim altı | belirtilmedi | karşılık testi | △ |
| Bildirimler | `/app/bildirimler` | Profil/üst eylem | belirtilmedi | karşılık testi | △ |
| Ayarlar | `/app/ayarlar` | Profil altı | belirtilmedi | karşılık testi | △ |
| Yardım | `/yardim` | Profil/site | belirtilmedi | karşılık testi | △ |
| Giriş/Kayıt | `/giris`, `/kayit` | Uygulama dışı | belirtilmedi | karşılık testi | △ |
| Blog listesi/yazısı | `/v/[slug]/yazilar`, `[articleSlug]` | Public vitrin | belirtilmedi | karşılık testi | △ |
| Blog yönetimi | `/v/[slug]/blog-yonetim` | Sahip altı | belirtilmedi | karşılık testi | △ |
| Randevu oluşturma/takibi | `/v/[slug]/randevu`, `randevu/[token]` | Public vitrin | belirtilmedi | karşılık testi | △ |
| Randevu yönetimi | `/v/[slug]/randevu-yonetim` | Sahip altı | belirtilmedi | karşılık testi | △ |
| Ürün detayı | `/v/[slug]/urun/[productSlug]` | Public vitrin | belirtilmedi | karşılık testi | △ |
| OCR tarayıcı | yok | Flutter özel | — | İstisna | İstisna |
| Moderasyon | doğrulanmadı | yalnız Flutter yönetici | yok | Karar gerekli (taşı/Flutter'da bırak) | ✗ |

Not: Sekme sırası/davranış testleri (`f5`, `kesfet-esitlik`) main'dedir; tam menü sırası kilidi yoktur.

## 3. UI görünüm matrisi

| Öğe | Flutter kilitli değer | Next.js değeri | İlgili test | Eksik kontrol | Durum |
|---|---|---|---|---|---|
| Ana renk | `#147DFF` (`app_colors.dart`) | `--owner-primary: #147DFF` (`globals.css:105`) | token testi kısmi | tam token kilidi | △ |
| İkincil renk | `#57B7FF` | `--owner-secondary` | token testi kısmi | tam token kilidi | △ |
| Arka planlar | `#050B1A`, `#08132D` | `--owner-bg`, `--owner-bg-soft` | token testi kısmi | tam token kilidi | △ |
| Yüzeyler | `#0B1730`, `#112448` | `--owner-surface*` | token testi kısmi | tam token kilidi | △ |
| Metinler | `#F7FBFF`, `#D9E7FF`, `#A9BBDA` | `--owner-text*` | token testi kısmi | kontrast oranı testi yok | △ |
| Kenarlık | `#294D88` | `--owner-border` | token testi kısmi | tam token kilidi | △ |
| Başarı/hata/uyarı | `#10B981/#EF4444/#F59E0B` | aynı | belirtilmedi | kilit testi | △ |
| Yazı ailesi | Outfit (`pubspec.yaml`) | Outfit | belirtilmedi | kilit testi | △ |
| Kart/kontrol yarıçapı | 16px / 12px | `.owner-card` / `.owner-input` | belirtilmedi | kilit testi | △ |
| Alt menü | 68px (`app_theme.dart`) | 68px | PR dalında (`ui-parity-contract`, #437 — main'de yok) | PR inince kilitlenir | △ |
| Sol menü | `ShellSidebar width 220` | 220px | PR dalında (#437 — main'de yok) | PR inince kilitlenir | △ |
| Vitrin formu | `BorderRadius.circular(22)`, `>900px` + `spacing24` | 22px, `grid-cols-2`, `column-gap:24px` | PR dalında (#438 — main'de yok) | PR inince kilitlenir | △ |
| Form alanları | `inputBg`, `radius14`, `fontSize 14` | `#0D1C38`, 14px | PR dalında (#439 — main'de yok) | PR inince kilitlenir | △ |
| Public vitrin paleti | yönetim paletinden ayrı | `--primary/#38A0E4` ayrı | — | Ayrı kalmalı (istisna) | Korunacak |

## 4. UX akış matrisi

| Akış | Flutter sonucu | Next hedefi | İlgili test (main) | Eksik kontrol | Durum |
|---|---|---|---|---|---|
| Sekme değiştir/dön | gövde bağlı kalır (`IndexedStack`) | `KaliciAnaSekmeler` saklar | kabuk testi (belirtilmedi) | kaydırma dahil test | △ |
| Global arama | Keşfet'e geçer + uygular | `/kesfet?q=...` | belirtilmedi | sonuç eşliği | △ |
| Vitrinsiz → Vitrinim | Vixrex kurulumu | `/app` + durum çubuğu | belirtilmedi | tek E2E | △ |
| Ad değiştir → kaydet → dön | controller → taslak → kayıt | draft API → working draft | belirtilmedi | kalıcılık eşliği | △ |
| Cihaz değiştir | hesaba bağlı veri geri gelir | `get_owner_workspace_bootstrap` | belirtilmedi | iki cihaz testi | △ |
| Yayınla | yasal + zorunlu alan kapısı | RPC aynı kapı | hazırlık testi (bakılmadı) | kapı eşliği | △ |
| Yayın sonrası düzenle | slug/link korunur | slug/link korunur | belirtilmedi | E2E | △ |
| QR/link paylaş | yayınsızken engel | aynı | belirtilmedi | engel testi | △ |
| Asistan alan güncelle | editor/controller yolu | draft yazma yolu | belirtilmedi | 46 alan sonuç testi | △ |
| Görsel yükle | optimize → bucket → URL → taslak | doğrula → optimize → bucket → taslak | sıkıştırma testi (var) | zincir E2E | △ |
| Kayıt hatası | mesaj, veri korunur | mesaj + tekrar dene | belirtilmedi | ortak hata sözlüğü yok | △ |

## 5. Responsive matrisi

| Genişlik | Flutter | Next | İlgili test | Eksik kontrol | Durum |
|---|---|---|---|---|---|
| ≤640px | mobil yoğunluk | public mobil tokenları | belirtilmedi | ekran bazlı kontrol | △ |
| 641–768px | mobil/tablet uyarlaması | `sm:` düzeni | belirtilmedi | ekran bazlı kontrol | △ |
| 769–900px | alt menülü geniş düzen | alt menü görünür | kabuk testi kısmi | — | △ |
| >900px | sol menü + durum çubuğu | `min-[901px]` sol menü | PR dalında (#437) | PR inince kilitlenir | △ |
| Alt boşluk | 68px menü korur | `pb-[68px]` | belirtilmedi | kilit testi | △ |
| Güvenli alan | `SafeArea` | `env(safe-area-inset-bottom)` | belirtilmedi | eşdeğerlik testi | △ |
| Ürün görsel oranı | mobil 1:1 | mobil 1:1; 640px üstü 4:5 | belirtilmedi | görsel karşılaştırma | △ |
| %200 yakınlaştırma | doğrulanmadı | doğrulanmadı | yok | Ölçüm gerekli | ○ |
| Yatay telefon | doğrulanmadı | doğrulanmadı | yok | Ölçüm gerekli | ○ |

## 6. Durum matrisi

| Durum | Flutter | Next | İlgili test | Eksik kontrol | Durum |
|---|---|---|---|---|---|
| Oturumsuz | anonim oturum dener | giriş/ziyaretçi akışı | belirtilmedi | sonuç sözleşmesi (bilinçli farklı) | △ |
| Anonim, vitrinsiz | Vixrex kurulum | `/app` oluşturma + Vixrex | belirtilmedi | akış eşliği | △ |
| Kalıcı hesap, vitrinsiz | kurulum/oluşturma | `has_store=false` oluşturma | belirtilmedi | temel karşılık testi | △ |
| Taslak, yayınlanmamış | "Yayında değil" + CTA | aynı | belirtilmedi | metin eşliği | △ |
| Yayınlı | link/QR/aç/kopyala | aynı | belirtilmedi | eylem eşliği | △ |
| Deneme/Premium/süre-bitimi | bilgi + kapılar | bilgi + kapılar | belirtilmedi | süre sonu/canli saat E2E | △ |
| Başkasının vitrini | düzenleme reddedilir | reddedilir | belirtilmedi | DB çekirdek testi | △ |
| Silinmiş slug | bulunamadı | 404/not-found | belirtilmedi | anlam eşliği | △ |
| Yükleniyor | iskelet/ilerleme | loading/iskelet | belirtilmedi | tüm ekranlar kapsanmıyor | △ |
| Ağ hatası | hata + tekrar | hata + tekrar | belirtilmedi | ortak metin matrisi yok | △ |

## 7. 46 alan matrisi

**Tek kaynak:** `shared/vitrin_alanlari.json` (46 alan, 6 zorunlu — sayı doğrulandı). Üretimler: `lib/config/vitrin_alanlari.g.dart`, `public_web/src/lib/vitrinFieldSchema.ts`.
**Kabul:** sayı 46, anahtar/kolon benzersiz, üretimler merkezi JSON ile aynı (`schema-drift` CI işi), zorunlular yayın hazırlık raporunda.
**Satır-satır kolon eşleşmesi bu indekste tek tek doğrulanmadı** — aşağıdaki liste kaynak belgedendir; şüpheli satır yayın hazırlık testine karşı kontrol edilmelidir.

| # | Anahtar | Kolon | Tip/Bölüm | Kural |
|---:|---|---|---|---|
| 1 | `isletmeAdi` | `name` | metin/hero | zorunlu, 2–60 |
| 2 | `heroRozet` | `hero_badge` | metin/hero | kalite, ≤60 |
| 3 | `kisaTanitim` | `description` | uzun/hero | ≤300 |
| 4 | `konumMetni` | `hero_location_text` | metin/hero | ≤60 |
| 5 | `kategori` | `kategori` | seçim/hero | zorunlu, merkezi liste |
| 6 | `isletmeTuru` | `business_type` | metin/hero | ≤40 |
| 7 | `logo` | `logo_url` | görsel/hero | kalite |
| 8 | `kapakGorseli` | `shelf_image_url` | görsel/hero | kalite |
| 9 | `whatsapp` | `whatsapp` | telefon/iletişim | zorunlu, TR mobil |
| 10 | `telefon` | `phone` | telefon/iletişim | isteğe bağlı |
| 11 | `eposta` | `email` | e-posta/iletişim | ≤120 |
| 12 | `adres` | `address` | uzun/iletişim | zorunlu, ≤200 |
| 13 | `il` | `province_name` | metin/iletişim | zorunlu, ≤60 |
| 14 | `ilce` | `district_name` | metin/iletişim | zorunlu, ≤60 |
| 15 | `mahalle` | `neighborhood_name` | metin/iletişim | kalite, ≤60 |
| 16 | `haritaEtiketi` | `map_label` | metin/iletişim | ≤120 |
| 17 | `calismaSaatleri` | `working_hours` | metin/iletişim | kalite, ≤400 |
| 18 | `instagram` | `instagram` | metin/iletişim | ≤30, `@` yok |
| 19 | `website` | `website` | URL/iletişim | geçerli URL |
| 20 | `haritaLinki` | `google_business_link` | URL/iletişim | kalite, geçerli URL |
| 21 | `enlem` | `latitude` | sayı/iletişim | -90…90 |
| 22 | `boylam` | `longitude` | sayı/iletişim | -180…180 |
| 23 | `kategoriBolumBaslik` | `category_section_title` | metin/kategoriler | ≤60 |
| 24 | `urunBolumBaslik` | `product_section_title` | metin/ürünler | ≤60 |
| 25 | `bantEtiket` | `featured_banner_label` | metin/kampanya | ≤40 |
| 26 | `bantBaslik` | `featured_banner_title` | metin/kampanya | ≤90 |
| 27 | `bantAciklama` | `featured_banner_description` | uzun/kampanya | ≤200 |
| 28 | `bantGorsel` | `featured_banner_image_url` | görsel/kampanya | isteğe bağlı |
| 29 | `bantFiyat` | `featured_banner_price_text` | metin/kampanya | ≤30 |
| 30 | `hakkindaUstBaslik` | `about_kicker` | metin/hakkında | ≤40 |
| 31 | `hakkindaBaslik` | `about_title` | metin/hakkında | kalite, ≤90 |
| 32 | `hakkindaMetin` | `corporate_bio` | uzun/hakkında | kalite, ≤1200 |
| 33 | `hakkindaGorsel` | `about_image_url` | görsel/hakkında | isteğe bağlı |
| 34 | `hakkindaGorselAlt` | `about_image_caption` | metin/hakkında | ≤120 |
| 35 | `galeriUstBaslik` | `gallery_section_kicker` | metin/galeri | ≤40 |
| 36 | `galeriBaslik` | `gallery_section_title` | metin/galeri | ≤90 |
| 37 | `galeriAksiyonMetni` | `gallery_action_label` | metin/galeri | ≤40 |
| 38 | `galeriAksiyonLinki` | `gallery_action_href` | URL/galeri | geçerli URL |
| 39 | `blogUstBaslik` | `blog_section_kicker` | metin/blog | ≤40 |
| 40 | `blogBaslik` | `blog_section_title` | metin/blog | ≤90 |
| 41 | `sssUstBaslik` | `faq_section_kicker` | metin/SSS | ≤40 |
| 42 | `sssBaslik` | `faq_section_title` | metin/SSS | ≤90 |
| 43 | `sssAciklama` | `faq_section_description` | uzun/SSS | ≤200 |
| 44 | `puanGoster` | `show_storefront_rating` | boolean/hero | boolean |
| 45 | `yolTarifiGoster` | `show_directions_link` | boolean/iletişim | boolean |
| 46 | `referansLinki` | `references_link` | URL/hakkında | geçerli URL |

## 8. Tek veri / senkronizasyon matrisi

| Veri | Kanonik kaynak | Flutter yerel rolü | Next yerel rolü | İlgili test/kanıt | Eksik kontrol | Durum |
|---|---|---|---|---|---|---|
| Kimlik | Supabase Auth `auth.uid()` | oturum önbelleği | çerez/istemci oturumu | belirtilmedi | oturum eşliği | △ |
| Kalıcı hesap ayrımı | `is_permanent_user()` (migration mevcut) | gösterim/akış | gösterim/akış | belirtilmedi | ayrım testi | △ |
| Sahiplik | `stores.user_id` + RPC | edit token desteği | owner session desteği | belirtilmedi | çekirdek testi | △ |
| Yayınlı vitrin | `stores` | önbellek | sunucu sorgusu | belirtilmedi | tazelik (`#435`) | △ |
| Çalışma taslağı | working draft | yerel taslak + kuyruk | istemci görünümü | belirtilmedi | çakışma/iki cihaz | △ |
| Kurulum akışı | `owner_flow_states` | geçiş önbelleği | oturum görünümü | belirtilmedi | altyapı testi | △ |
| Asistan konuşması | `assistant_conversations/messages` | cache | görünüm | `assistant-continuity-baseline` (var) | devamlılık E2E | △ |
| Bekleyen alan | `pending_slot` (migration mevcut) | cache olabilir | cache olabilir | belirtilmedi | slot testi | △ |
| 46 alan şeması | `shared/vitrin_alanlari.json` | üretilmiş Dart | TS kaynak | `schema-drift` CI (var) | — | ✓ Kilitli |
| Mesaj tonu | `shared/vixrex_mesajlar.json` | üretilmiş Dart | TS tüketimi | üretim hattı (var) | — | ✓ Kilitli |
| Ürünler | ürün tabloları | düzenleme kuyruğu | API/görünüm | belirtilmedi | E2E | △ |
| Görseller | Storage + stores URL | sıkıştırma geçişi | sunucu sıkıştırma | sıkıştırma testi (var) | zincir E2E | △ |
| Yayın linki | `/v/{slug}` kanonik | son link cache | route üretimi | belirtilmedi | kanonik testi | △ |
| Kategori listesi | merkezi kategori kaynağı | üretilmiş Dart | TS | üretim testi (var) | — | ✓ Kilitli |
| Premium/deneme | Supabase zaman alanları | gösterim | gösterim/API | belirtilmedi | saat sınırı | △ |

## 9. Doğrulama ve iş kuralı matrisi

| Kural | Flutter | Next | Sunucu/DB kapısı | İlgili test (main) | Eksik kontrol | Durum |
|---|---|---|---|---|---|---|
| Ad 2–60 | var | var | yayın hazırlığı | `vitrin-field-schema.test.ts` (var) | — | △ |
| WhatsApp TR mobil | var | var | `assert_store_publish_ready` (kanıt: migration adı) | TR normalize testi (var) | kapı eşliği | △ |
| Adres/İl/İlçe zorunlu | var | var | yayın hazırlığı | şema testi (var) | — | △ |
| Kategori merkezi liste | var | var | payload/şema | şema testi (var) | — | △ |
| E-posta biçimi | var | var | doğrulanmadı | biçim testi (var) | DB kapısı | △ |
| URL şeması | var | var | hassas şema reddi | test (var) | — | △ |
| Enlem/Boylam | şema | şema | doğrulanmadı | belirtilmedi | DB kısıtı | △ |
| Uzunluklar | merkezi 46 alan | merkezi 46 alan | draft RPC | şema testi (var) | — | △ |
| Yasal onaysız yayın yok | var | buton kapalı + API | `publish_working_draft` | belirtilmedi | kapı eşliği | △ |
| Public yalnız yayınlı | public yalnız yayınlı | public yalnız yayınlı | RLS/sorgu `is_published=true` | belirtilmedi | sorgu testi | △ |
| Hesapta tek vitrin | sahiplik servisleri | create/link API | sahiplik RPC | belirtilmedi | çekirdek testi | △ |
| Slug çakışması | yeni slug/korumalı güncelleme | API/RPC | unique kuralı | belirtilmedi | kural testi | △ |

## 10. Bağlantı / servis matrisi

| İşlem | Flutter yolu | Next yolu | Ortak sonuç | İlgili test | Eksik kontrol | Durum |
|---|---|---|---|---|---|---|
| Çalışma alanı aç | `OwnerBootstrapService` | `get_owner_workspace_bootstrap` | aynı kullanıcı/vitrin/taslak | belirtilmedi | sonuç eşliği | △ |
| Taslak yaz | working-draft adapter | `/api/owner-draft` | `update_working_draft_field` | belirtilmedi | sonuç eşliği | △ |
| Geri al | draft restore servisi | owner restore route | `restore_working_draft_field` | belirtilmedi | altyapı testi | △ |
| Yayınla | `StorePublishService` | `/api/owner-publish` | yayın RPC + hazırlık | belirtilmedi | kapı eşliği | △ |
| Oluştur | create/publish servisi | `/api/create-store` | stores + sahiplik + session | belirtilmedi | akış farkı testi | △ |
| Hesaba bağla | `AuthService` | `/api/account/link-store` | `claim_store_for_user` | belirtilmedi | çekirdek testi | △ |
| Public oku | `PublicStoreService` | `/v/[slug]` sunucu sorgusu | yalnız yayınlı | belirtilmedi | filtre testi | △ |
| Görsel yükle | `StoreShelfUploadService` | `/api/owner-upload` | `shelf-images` | sıkıştırma testi | yol/kova eşliği | △ |
| Ürün CRUD | product service/RPC | `/api/products` | ürün tabloları/RPC | belirtilmedi | sözleşme eşliği | △ |
| Asistan konuşması | repository/RPC | `useOwnerChat`/RPC | tek konuşma, sıralı mesaj | continuity baseline (var) | sıra E2E | △ |
| Kurulum durumu | owner flow repository | landing/app RPC | `owner_flow_states` | belirtilmedi | altyapı testi | △ |
| Realtime taslak | `StoreRealtimeSyncService` | istemci yenileme/kanal | working draft | belirtilmedi | çift taraflı canlı test | △ |

## 11. Yetki ve güvenlik matrisi

| Aktör | Yayınlıyı gör | Taslağı gör | Düzenle | Yayınla | Hassas kolon |
|---|---|---|---|---|---|
| Anon | Evet | Hayır | Yalnız owner session akışı | Yalnız session + kural | Hayır |
| Anonim Supabase kullanıcısı | Evet | Yalnız kendi oturumu | Yetkili RPC | Yetkili RPC | Hayır |
| Kalıcı sahip | Evet | Kendi vitrini | Kendi vitrini | Kendi + yasal/hazırlık | Projection hariç hayır |
| Başka kullanıcı | Evet | Hayır | Hayır | Hayır | Hayır |
| service_role | Evet | Görev gereği | Görev gereği | Görev gereği | Evet; istemciye sızmaz |

Güvenlik kuralları (migration/CI kanıtlı olanlar): `edit_token`/`user_id`/klon/premium iç alanları public SELECT dışında (REVOKE migration); `TRUNCATE/MAINTAIN/REFERENCES/TRIGGER` anon/authenticated'tan REVOKE (`grant-guard` CI); asistan/akış tabloları RLS açık, politika yok, yalnız RPC; RPC'lerde `auth.uid()` + sabit `search_path`; owner session HMAC çerezi (ham token loglanmaz); yüklemede imza kontrolü + oran sınırı; storage anon yükleme yalnız slug kapsamı; rate limiter yalnız `service_role`.
**Eksik kontrol:** tablo başına `supabase/tests/<tablo>_rls.test.sql` yok (`tests/` içinde yalnız smoke testleri var) — bu tablonun satırları politika iddiasıdır, test kilidi değildir. Durum: △.

## 12. Hata / yükleniyor / boş durum matrisi

| Durum | Flutter | Next | İlgili test | Eksik kontrol | Durum |
|---|---|---|---|---|---|
| Başlangıç hatası | global guard/log | route error boundary | belirtilmedi | kurtarma ekranı eşliği | △ |
| Yükleniyor | iskelet/ilerleme | loading/iskelet | belirtilmedi | tüm rotalar kapsanmıyor | △ |
| Bulunamadı | kullanıcı mesajı | 404/not-found | belirtilmedi | anlam eşliği | △ |
| Yetkisiz | tekrar aç/giriş | 401 + mesaj | belirtilmedi | anlam eşliği | △ |
| Taslak yok | yeniden yükleme | "Önizlemeyi tekrar açın" | belirtilmedi | metin eşliği yok | △ |
| Kayıt başarısız | mesaj, veri korunur | "Kaydedilemedi…" | belirtilmedi | ortak katalog yok | △ |
| Yayın başarısız | hata + tekrar | hata + tekrar | belirtilmedi | anlam eşliği | △ |
| Görsel boş/büyük/bozuk | çağrı/limit/ret | çağrı/"5 MB"/imza reddi | sıkıştırma testi (var) | Flutter limit satır kilidi | △ |
| Keşfet/bildirim boş | ortak bileşen / "Henüz…" | boş görünüm / aynı metin | belirtilmedi | metin/görsel testi | △ |
| Konum yok | yönlendirme/uyarı | "Konum bulunamadı" | belirtilmedi | kurtarma yolu eşliği | △ |
| WhatsApp geçersiz | sabit mesaj | aynı mesaj | belirtilmedi | metin kilidi | △ |
| İnternet yok | hata/yerel taslak | route/API hatası | yok | Merkezi çevrimdışı sözleşme yok | ✗ |
| İki cihaz çakışması | resolver/kuyruk | sürüm/RPC hatası | yok | kazanma kuralı + mesaj kilidi | △ |

## 13. Görsel ve dosya matrisi

| Kural | Flutter | Next | İlgili test | Eksik kontrol | Durum |
|---|---|---|---|---|---|
| Tür | JPEG/PNG/WebP | JPEG/PNG/WebP | sıkıştırma testi (var) | — | △ |
| Uzun kenar | 1600px | 1600px | sıkıştırma testi (var) | E2E | △ |
| JPEG kalite | 82 | 82, mozjpeg | sıkıştırma testi (var) | — | △ |
| PNG | optimize | palette/compression | sıkıştırma testi (var) | sonuç türü karşılaştırması | △ |
| WebP | kodlamadan korunur | kodlamadan korunur | sıkıştırma testi (var) | — | △ |
| Yedek sıkıştırma | kalite 65/ikinci hedef | ikinci hedef | belirtilmedi | eşik karşılaştırması | △ |
| İstemci boyutu | doğrulanmalı | 5 MB | belirtilmedi | Flutter taraf kilidi | △ |
| Sunucu MIME | uzantı/MIME | magic-byte + eşlik | belirtilmedi | ortak kapı (sunucu) | △ |
| Bucket/yollar | `shelf-images`, slug kapsamı | aynı | belirtilmedi | galeri yol sözleşmesi | △ |
| Yetkisiz yükleme | Storage/RPC reddeder | session + limit + Storage | belirtilmedi | çekirdek testi | △ |
| Public URL | bucket public URL | bucket public URL | belirtilmedi | — | △ |
| Alt metin | bazı ekranlarda | bazı bileşenlerde | belirtilmedi | merkezi kural yok | △ |

## 14. Erişilebilirlik matrisi

| Kontrol | Flutter | Next | İlgili test | Eksik kontrol | Durum |
|---|---|---|---|---|---|
| Form etiketi | tema/alan widget | görünür/`sr-only` | belirtilmedi | ekran taraması | △ |
| Hata duyurusu | SnackBar | bazı ekranda `role="alert"` | belirtilmedi | live-region doğrulaması | △ |
| Klavye odağı | varsayılan | `focus-visible` 3px/2px | yok | E2E klavye testi yok | △ |
| Menü adı | NavigationDestination | `aria-label/current` | belirtilmedi | — | △ |
| Dekoratif ikon | semantik denetim gerekli | `aria-hidden` | belirtilmedi | Flutter tarafı | △ |
| Dokunma hedefi | 68px bar, ortak butonlar | ≥48px kontroller, ≥44px menü | belirtilmedi | ölçüm kilidi | △ |
| Kontrast | palet tanımlı | aynı palet | yok | oran otomatik testi yok | ○ |
| %200 büyüme | doğrulanmadı | doğrulanmadı | yok | test gerekli | ○ |
| Okuyucu sırası | doğrulanmadı | DOM sırası | yok | test yok | ○ |
| Hareket azaltma | doğrulanmadı | `prefers-reduced-motion` kuralları | belirtilmedi | Flutter kontrolü | △ |
| Alt açıklama | merkezi değil | bazı bileşenlerde | belirtilmedi | merkezi kural yok | △ |
| Renk-dışı durum | metin + renk | metin + renk | belirtilmedi | durum çubuğu kilidi | △ |

## 15. SEO ve public vitrin matrisi

| Yüzey | Index koşulu | Metadata/canonical | Sitemap | Yapısal veri | İlgili test | Eksik kontrol | Durum |
|---|---|---|---|---|---|---|---|
| `/v/[slug]` | yalnız `is_published` | dinamik title/desc/canonical/OG | yayınlılar | LocalBusiness JSON-LD | belirtilmedi | temel E2E | △ |
| Taslak | public sorguda yok | üretilmez | dahil edilmez | üretilmez | belirtilmedi | sızıntı testi | △ |
| Demo vitrin | public olabilir | metadata olabilir | dışında | sayfaya göre | sitemap testi (var) | — | △ |
| `/v/[slug]/urun/[productSlug]` | yayınlı vitrin + ürün | dinamik canonical/OG | ürün girdileri | Product | belirtilmedi | temel E2E | △ |
| `/v/[slug]/yazilar` | yayınlı vitrin + blog | canonical | duruma göre | liste/breadcrumb | belirtilmedi | doğrulama | △ |
| `/v/[slug]/yazilar/[articleSlug]` | yayınlı yazı | dinamik canonical/OG | yayınlılar | Article | belirtilmedi | temel E2E | △ |
| `/blog` | taslaksa kapalı | site metadata | politikaya göre | liste | belirtilmedi | ürün kararı kilidi | △ |
| `/kesfet` | açık | canonical/OG | statik | liste | belirtilmedi | temel E2E | △ |
| robots | yönetim/özel engelli | `robots.txt` route (var) | — | — | belirtilmedi | kaynak testi | △ |
| JSON-LD güvenliği | script kıramaz | güvenli serileştirme | — | XSS testi | belirtilmedi | enjeksiyon testi | △ |

## 16. Performans matrisi

| Ölçüm | Hedef | Kanıt | Durum |
|---|---|---|---|
| Sekmeye dönüş | yeniden kurulum yok | IndexedStack + kalıcı sekmeler (mimari) | △ (ölçüm yok) |
| Kabuk prefetch | gecikme azaltma | yalnız kabukta prefetch | △ (envanter yok) |
| Görsel lazy | görünür öncelikli | bazı görsellerde `loading="lazy"` | △ (envanter yok) |
| Aktarım boyutu | 1600px/82 | iki tarafta optimizasyon | △ |
| İlk açılış / LCP / INP / CLS | belirlenmedi | ölçüm yok | ○ |
| API/DB p95 | belirlenmedi | ölçüm yok | ○ |
| JS bundle / Flutter çıktı | bütçe yok | build var, bütçe kapısı yok | ✗ (kapı eksik) |
| Hata oranı | belirlenmedi | eşik doğrulanmadı | ○ |

Not: Sayı uydurulmadı. Hedefler üretim ölçümünden sonra kilitlenir.

## 17. Test ve yayına alma matrisi

| Yüzey | Zorunlu kapı | CI durumu |
|---|---|---|
| Her PR | yüzey sınıflandırması + secret taraması | var |
| Flutter | `dart format --set-exit-if-changed`, `flutter test` | var |
| Şema | TS dışa aktarım + Dart üretim + fark kontrolü | var (`schema-drift`) |
| Next | `npm ci`, lint, test, build | var |
| Supabase | migration/kontrat/smoke | kısmi |
| PR E2E (Preview) | kritik akışlar gerçek Preview'a karşı | yok |
| main sonrası E2E | Playwright production | var (birleşme sonrası) |
| Flutter referans değişikliği | varsayılan yasak, istisna+onay gerekir | kural (bu indeks) |
| Public regresyon | `/v/[slug]`, ürün, yazı, sitemap, robots | testler var; görsel regresyon yok |
| UI eşitliği | token sözleşmesi | kısmi; piksel testi yok |
| Erişilebilirlik | klavye + %200 | yok |
| Performans | Web Vitals + boyut bütçesi | yok |
| Teslimat | güncel main + zorunlu kontroller + SHA yorumu | iş akışı var (`teslimat.yml`) |

PR karar tablosu: matris satırı yazılmamış / Flutter izinsiz değişmiş / 46 alan üretim farkı / CI kırmızı / yetki etkisi test edilmemiş / Preview doğrulanmamış public etkisi → main'e alınmaz. Yalnız yeşil CI "kod kapıları geçti" demektir, "uçtan uca güvenli" denmez. Matris + test + Preview tamam → aday.

## Sürüm notu

Bu indeks `VIXREX-UYUM-SOZLESMESI.md` (8 Eylül 2026) içeriğinin depo içi sürümüdür; 2 yol düzeltmesi uygulanmıştır. `△/✗/○` satırları kapanmadan "tam eşit/tam güvenli" sonucu verilmez.

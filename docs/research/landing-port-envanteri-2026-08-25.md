# Landing Port Envanteri: Flutter → Next.js (public_web)

**Tarih:** 2026-08-25
**Amaç:** Flutter landing ekranının (`vixrex-app.vercel.app`, canvas-render, Google tarafından okunamıyor) içeriğinin **eksiksiz**, sunucu-render Next.js ana sayfasına (`public_web/`) taşınması için tek kaynak envanter. İlgili iş: #344.
**Kural:** Bu dokümandaki metinler kod stringlerinden HARFİYEN kopyalanmıştır; çeviri/kısaltma yapılmamıştır. Emin olunmayan her yer `DOĞRULANMALI` etiketlidir.

---

## 0. Kaynak dosyalar (bu envanterin dayanağı)

| Dosya | Rolü |
|---|---|
| `lib/screens/landing_screen.dart` | Ekran birleştirici: bölüm sırası, demo veri havuzu, navigasyon callback'leri |
| `lib/widgets/landing/landing_hero_section.dart` | Top nav + hero metin + form/rozetler |
| `lib/widgets/landing/landing_hero_mockup.dart` | Telefon mockup sarmalayıcı, yüzen rozetler, nokta göstergeler |
| `lib/widgets/landing/phone_mockup.dart` | Telefon çerçevesi ve vitrin önizleme içeriği |
| `lib/widgets/landing/landing_value_band.dart` | "Tek link" değer bandı + kanal çipleri |
| `lib/widgets/landing/landing_features_section.dart` | 4 özellik kartı ızgarası |
| `lib/widgets/landing/landing_value_card.dart` | Özellik kartı bileşeni (hover efektli) |
| `lib/widgets/landing/landing_comparison_section.dart` | Karşılaştırma bölümü (2 panel + ok) |
| `lib/widgets/landing/landing_setup_panel.dart` | Karşılaştırma panel bileşeni |
| `lib/widgets/landing/landing_trust_band.dart` | Güven rozetleri bandı |
| `lib/widgets/landing/landing_steps_section.dart` | 3 adım zaman çizelgesi |
| `lib/widgets/landing/landing_template_catalog.dart` | Şablon kataloğu grid + bottom-sheet önizleme |
| `lib/widgets/landing/landing_template_card.dart` | Kategori kartı |
| `lib/widgets/landing/landing_template_category.dart` | Kategori tanım listesi (20 kategori) |
| `lib/widgets/landing/landing_bottom_cta.dart` | Alt CTA + footer |
| `lib/widgets/chatbot_badge.dart` | Yüzen maskot FAB + konuşma balonu |
| `lib/models/landing_demo_profile.dart` | Hero demo profil modeli (+`toStoreData()` demo tohumu) |
| `lib/theme/app_colors.dart`, `lib/theme/app_theme.dart` | Renk/radius/spacing token'ları, font: **Outfit** |
| `lib/services/category_image_service.dart` | `category_image_templates` tablosu erişimi + fallback görseller |
| `lib/config/public_site_config.dart`, `lib/config/legal_config.dart`, `lib/config/app_router.dart` | URL/route kuralları |

---

## 1. Sayfa kompozisyonu (bölüm sırası)

Kaynak: `lib/screens/landing_screen.dart:420-476`. Tek `SingleChildScrollView` içinde dikey `Column`; arka plan `AppColors.bgLight`.

| # | Bölüm | Widget | Satır |
|---|---|---|---|
| 1 | Top navigation bar | `LandingHeroSection._buildTopNavBar` (hero içindeki ilk satır) | hero:189 |
| 2 | Hero (metin + telefon mockup) | `LandingHeroSection` + `LandingHeroMockup` + `PhoneMockup` | screen:429 |
| 3 | Değer bandı | `LandingValueBand` | screen:451 |
| 4 | Özellik kartları | `LandingFeaturesSection` (4 × `LandingValueCard`) | screen:452 |
| 5 | Karşılaştırma | `LandingComparisonSection` (2 × `LandingSetupPanel` + ok) | screen:453 |
| 6 | Güven bandı | `LandingTrustBand` | screen:454 |
| 7 | Adımlar | `LandingStepsSection` | screen:455 |
| 8 | Şablon kataloğu | `LandingTemplateCatalog` (grid + bottom-sheet önizleme) | screen:457 |
| 9 | Alt CTA + Footer | `LandingBottomCta` | screen:460 |
| — | Sayfa sonu boşluğu | `SizedBox(height: 96)` — maskot FAB son satırı kapatmasın diye | screen:465 |
| — | Sabit yüzen öğe (FAB) | `ChatbotBadge` (sağ altta maskot; dokununca telefon mockup içinde sohbet overlay açılır) | screen:470 |

### Mobil / masaüstü farkları

| Bölüm | Kırılım | Masaüstü | Mobil |
|---|---|---|---|
| Nav | `maxWidth > 768` (hero:107) | Etiketli butonlar ("Vitrinleri Keşfet", "Giriş Yap"/"Çıkış Yap") | Sadece ikon butonlar |
| Hero içerik+mockup | `> 768` | Yan yana Row, flex 5/5, gap 40; pad üst 40 / alt 100 | Alt alta Column, gap 40; pad üst 20 / alt 50; metin ortalı, H1 36px (masaüstü 48px) |
| Hero setup formu | iç genişlik `> 500` (hero:490); input ön eki `< 400` iken kısalır | Input + buton aynı satır | Alt alta |
| Value band | `> 820` (value:18) | Metin solda (flex 5), çip bulutu sağda (flex 4), gap 48 | Alt alta, ortalanmış, gap 24 |
| Features | `> 1040` → 4 kolon, `> 680` → 2 kolon, altında tek kolon (features:47-54). Tek kolonda kart içeriği yatay dizilir (ikon solda) | Wrap 4×260px kart, gap 18 | Tam genişlik kart; `isHorizontal=true` iken 420px yatay düzen |
| Comparison | `> 820` (comparison:59) | Paneller yan yana, arada sağa ok | Paneller alt alta, arada aşağı ok, dikey boşluk 18 |
| Steps | `> 800` (steps:33) | 3 adım yan yana | Alt alta, adımlar arası 28px |
| Catalog grid | `> 900` → 4 kolon, `> 600` → 3, altında 2 (catalog:370-375) | 4'lü grid, hücre aralığı 16, aspect ratio 0.85 | 2'li grid |
| Mockup sohbet açılınca | scroll hedefi mobilde 560px, masaüstünde 0 (screen:395-414) | Sayfayı en üste kaydırır (450ms easeOutCubic) | 560px'e animasyonlu kaydırma |

---

## 2. Bölüm bölüm içerik dökümü (HARFİYEN)

> Metinler birebir koddan kopyalanmıştır. `\n` = satır sonu. Kesme işaretleri kaynakta geçtiği gibi korunmuştur (örn. comparison:48 ve bottom_cta:47'deki `Vixrex’e`, `Vixrex’ini` kelimelerinde U+2019 ’ karakteri vardır).

### 2.1 Top Navigation Bar — `landing_hero_section.dart:189-363`

| Öğe | Metin | Kaynak |
|---|---|---|
| Marka adı | `Vixrex` | :216 |
| Keşfet butonu (desktop etiketi; mobilde sadece explore ikonu) | `Vitrinleri Keşfet` | :233 |
| Giriş butonu (oturum yoksa) | `Giriş Yap` | :321 |
| Çıkış butonu (oturum varsa) | `Çıkış Yap` | :283 |

Görsel: marka ikonu `storefront_rounded`, daire zemin `primary %15`, ikon primary, boyut 20. Marka yazısı 20px w900, letterSpacing -0.5, renk `darkText`.
Koşul: oturum durumu `Supabase.instance.client.auth.currentUser != null` (:666).
Nav dolgusu: yatay desktop 40 / mobil 20, dikey 16.

### 2.2 Hero — `landing_hero_section.dart:365-651`

Arka plan: dikey gradient `bgEditor` (#050B1A) → `bgLight` (#08132D); üstüne 3 animasyonlu mesh glow (§7).

**Rozet (pill):**
```
VİXREX ASİSTAN İLE DİJİTAL VİTRİN
```
(:384 — 11px w900, letterSpacing 1.0, renk `secondary`; kutu: `primary %18` zemin, radius 30, kenarlık `secondary %45`, dolgu 14×8)

**H1 (RichText, 3 parça; masaüstü 48px / mobil 36px, w900, height 1.15, letterSpacing -0.8):**
```
Vitrininiz\n
Vixrex Asistan        ← RENKLİ: AppColors.secondary (#57B7FF)
 ile\nbirkaç dakikada hazır
```
(:405-411 — Next.js karşılığı: `Vitrininiz<br/>` + `<span style="color:#57B7FF">Vixrex Asistan</span>` + `<br/>birkaç dakikada hazır`. Dikkat: üçüncü span "ile"den ÖNCE boşlukla başlar.)

**Alt metin (16px, beyaz %70, height 1.5, w500):**
```
İşletme bilgilerini, fotoğraflarını, ürün ve hizmetlerini, adresini ve WhatsApp iletişimini Vixrex Asistan ile konuşarak tek vitrinde topla.
```
(:416)

**Durum A — kayıtlı vitrin varsa (`hasSavedVitrin && !isCheckingSavedVitrin`, hero:430):**

| Öğe | Metin | Kaynak |
|---|---|---|
| Birincil buton (gradient #0EA5E9→#2563EB yatay, ikon edit_document, radius 16, yükseklik 52, glow #0EA5E9) | `Kayıtlı Vitrinimi Düzenle` | :465 |
| TextButton link (secondary, 13px w900) | `Farklı vitrinleri incele` | :477 |

**Durum B — kayıtlı vitrin yoksa (setup form, hero:486-601):**

| Öğe | Metin / değer | Kaynak |
|---|---|---|
| Input ön eki (alan genişliği ≥400px) | `vixrex-public.vercel.app/v/` | :511 |
| Input ön eki (dar <400px) | `/v/` | :509 |
| Input hint | `isletmeniz` | :530 |
| Gönder butonu (ikon arrow_forward_rounded 16, radius 16, yükseklik 52) | `Ücretsiz Vitrinimi Hazırla` | :566 |

Input görünümü: zemin beyaz %6, kenarlık beyaz %12, radius 16, yükseklik 52; ön ek 14px bold beyaz %60; hint beyaz %30 normal; yazı 14px bold beyaz. Buton: `primary` zemin, `onPrimary` yazı 15px w900.
Not: input değeri `_storeNameController` — gönderimde editöre başlangıç vitrin adı olarak taşınır (screen:385-393). DOĞRULANMALI (ürün kararı): Next.js kendi domaininde gösterileceği için ön ek metni (`vixrex-public.vercel.app/v/`) aynı kalacak mı?

**Güven rozetleri (4 pill; check_circle ikonu #10B981 16px + metin 12px w700 beyaz %70; zemin beyaz %6, kenarlık beyaz %8, radius 20):**

| # | Metin | Kaynak |
|---|---|---|
| 1 | `SSL Güvenli Koruma` | :613 |
| 2 | `Kredi kartı gerekmez` | :614 |
| 3 | `Komisyon yok` | :615 |
| 4 | `Link ve QR hazır` | :616 |

(Kod yorumu :610-612: rozet metinlerindeki emoji önekleri 2026-08-22'de bilinçli kaldırıldı — portta geri getirilmemeli.)
Rozetlerle hero arasındaki dikey boşluklar: H1'den sonra 20, formdan sonra 32, rozetlerden önce 24.

### 2.3 Telefon mockup içeriği (Hero'nun sağ/mobil-alt parçası) — `phone_mockup.dart`

Mockup, aktif demo profili (`activeProfileIndex`) verisini çizer. Sabit etiketler:

| Öğe | Metin | Kaynak |
|---|---|---|
| İçerik bölümü başlığı | `Hakkında` | :255 |
| Galeri bölümü başlığı | `Vitrin galerisi` | :427 |
| Galeri sayaç çipi | `{profile.galleryImages.length} fotoğraf` (örn. `3 fotoğraf`) | :448 |
| Alt durum kutusu başlık | `Vitrin hazır` | :543 |
| Alt durum kutusu alt metin | `${profile.links.length} bağlantı` (örn. `2 bağlantı`) | :552 |
| Kapak üstü önizleme çipi | `profile.badgeText` (aşağıdaki profil tablolarında) | :178 |

Dekoratif: Dynamic Island çentiği (96×22 siyah, radius 20), home indicator (110×4 beyaz %30).

**Demo profilleri — 4 slayt sırayla döner (16 sn'lik döngü, slayt başına 4 sn). Veri kaynağı `landing_screen.dart:53-210`:**

#### Profil 1 — `Aymira Giyim` (screen:54-92)
- Kategori şeridi: `KADIN GİYİM / BUTİK`
- Açıklama (Hakkında): `Yeni sezon reyonları ve mağaza fotoğrafları tek vitrinde.`
- İkon: `checkroom_rounded` · Vurgu rengi: `#FF5A1F`
- Rozet 1: ikon `photo_library_rounded`, metin `Galeri`
- Rozet 2: ikon `qr_code_2_rounded`, metin `QR kod`
- Aksiyon çipleri: `chat_bubble_rounded` #25D366, `camera_alt_rounded` #E1306C
- Link kartları:
  1. `Vitrin galerisi` / alt: `Raf ve reyon fotoğrafları` (ikon photo_library, renk #FF5A1F)
  2. `Trendyol` / alt: `Mağazayı ziyaret edin` (ikon shopping_bag, renk #F27A1A)
- Kapak fallback: `https://images.unsplash.com/photo-1441984904996-e0b6ba687e04?auto=format&fit=crop&w=400&q=80`
- Galeri fallback (4): `photo-1567401893414-76b7b1e5a7a5`, `photo-1490481651871-ab68de25d43d`, `photo-1445205170230-053b83016050`, `photo-1483985988355-763728e1935b` (hepsi `w=300&q=80`)
- `templateCategoryKey`: `butik_giyim`

#### Profil 2 — `Lezzet Durağı` (screen:93-131)
- Kategori şeridi: `KAFE / RESTORAN`
- Açıklama: `Menü, konum ve WhatsApp sipariş bilgileri tek ekranda.`
- İkon: `restaurant_menu_rounded` · Vurgu: `#EA580C`
- Rozet 1: `menu_book_rounded` + `Menü` · Rozet 2: `directions_rounded` + `Yol tarifi`
- Aksiyonlar: chat_bubble #25D366, location_on #EF4444
- Linkler:
  1. `Günün menüsü` / `Sıcak yemek ve tatlılar` (local_dining, #EA580C)
  2. `Paket servis` / `WhatsApp ile sipariş` (delivery_dining, #10B981)
- Kapak fallback: `photo-1554118811-1e0d58224f24` · Galeri fallback: `photo-1495474472287-4d71bcdd2085`, `photo-1509042239860-f550ce710b93`, `photo-1565299624946-b28f40a0ae38`, `photo-1544025162-d76694265947`
- `templateCategoryKey`: `kafe_restoran`

#### Profil 3 — `Nova Kuaför` (screen:132-170)
- Kategori şeridi: `KUAFÖR / GÜZELLİK`
- Açıklama: `Randevu, hizmetler ve sosyal medya bağlantıları hazır.`
- İkon: `content_cut_rounded` · Vurgu: `#DB2777`
- Rozet 1: `calendar_month_rounded` + `Randevu` · Rozet 2: `camera_alt_rounded` + `Instagram`
- Aksiyonlar: chat_bubble #25D366, camera_alt #E1306C
- Linkler:
  1. `Hizmetler` / `Kesim, boya ve bakım` (spa, #DB2777)
  2. `Randevu al` / `WhatsApp ile hızlı iletişim` (event_available, #10B981)
- Kapak fallback: `photo-1560066984-138dadb4c035` · Galeri fallback: `photo-1522337360788-8b13dee7a37e`, ardından `photo-1595476108010-b4d1f102b1b1` ÜÇ kez tekrarlı (screen:165-167)
- `templateCategoryKey`: `kuafor_guzellik`

#### Profil 4 — `TeknoFix` (screen:171-209)
- Kategori şeridi: `TELEFON TEKNİK SERVİS`
- Açıklama: `Servis talebi, adres ve güvenilir iletişim tek vitrinde.`
- İkon: `build_circle_rounded` · Vurgu: `#2563EB`
- Rozet 1: `chat_bubble_rounded` + `WhatsApp` · Rozet 2: `location_on_rounded` + `Konum`
- Aksiyonlar: chat_bubble #25D366, phone_android #2563EB
- Linkler:
  1. `Servis kaydı` / `Ekran, batarya ve bakım` (construction, #2563EB)
  2. `Google yorumları` / `Müşteri güveni` (verified, #6366F1)
- Kapak fallback: `photo-1512499617640-c74ae3a79d37` · Galeri fallback: `photo-1601784551446-20c9e07cdbdb`, ardından `photo-1545259741-2ea3ebf61fa3` ÜÇ kez tekrarlı (screen:204-206), `photo-1585771724684-38269d6639fd`
- `templateCategoryKey`: `teknik_servis`

> Not: Bu statik görseller yalnızca BAŞLANGIÇ değeridir; ekran açılınca `CategoryImageService` ile canlı veriyle değiştirilir (§4, bağımlılık 3). Canlı veride galeri ilk 3 görselle sınırlıdır (screen:264) ve sayaç buna göre `3 fotoğraf` olur.

Model notları (`landing_demo_profile.dart`):
- `status: 'AÇIK'` alanı TÜM profillerde tanımlı ama mockup'ta ÇİZİLMEZ — portta render edilmemeli.
- Rozet 2'nin rengi `secondaryBadgeColor` getter'ı: `links.last.color` (:59-62).
- `toStoreData()` (:64-196): demo profillerinden tam `StoreData` tohumu üretir (ürün/adres/telefon dahil — örn. Aymira için offerings `Elbise Seçenekleri`, `Triko & Hırka`, `Yeni Sezon Ceket`; ortak adres `Atatürk Cad. No:24, Şişli, İstanbul`, telefon `05551234567`). Landing widget'ları bunu kullanmaz; mockup içi sohbet/editör tarafı kullanır. DOĞRULANMALI: mockup-sohbet overlay'i port kapsamına alınırsa bu tohumun taşınması gerekir.

**Yüzen rozetler** (`landing_hero_mockup.dart:98-123`): sağ üstte `badgeText`, sol altta `secondaryBadgeText`; cam efekti (backdrop blur 12), sinüs bobbing ±10px; sohbet açıkken gizlenir. Kutu: `surface %92` zemin, radius 20, kenarlık `primary %28` 1.2px, gölge siyah %10 blur10 offset(0,5); ikon çipi vurgu rengi %20 dairede, metin 12px w800 darkText.

**Slayt noktaları** (:127-145): 4 nokta; aktif olan primary, 24×8 hap; pasifler 8×8 `border` rengi; geçiş animasyonu 260ms.

### 2.4 Değer Bandı — `landing_value_band.dart`

Zemin `bgLight`, dolgu dikey 64 / yatay 24, içerik max 1200.

**Başlık (30px w900, height 1.2):**
```
Müşterin ihtiyaç duyduğu her bilgiye tek linkten ulaşsın
```
(:26)

**Alt metin (16px darkTextAlt, height 1.55):**
```
Vitrin linkinizi WhatsApp, sosyal medya, Google İşletme, kartvizit, paket veya işletme içi QR kod üzerinden paylaşın.
```
(:37)

**Çipler (5 adet; surfaceSoft zemin, kenarlık border, radius 999, dolgu 14×11, 12px w900 darkTextAlt):**
```
WhatsApp
Sosyal medya
Google İşletme
QR kod
Vitrin linki
```
(:52-58)

### 2.5 Özellik Kartları — `landing_features_section.dart` (+ `landing_value_card.dart`)

Zemin `bgLight`, dolgu (24, 48, 24, 72), max 1200.

**Başlık (38px w900, ortalı):**
```
Dijital vitrinini kolayca hazırla
```
(:25)

**Alt metin (18px darkTextAlt, height 1.5):**
```
Müşterinin ihtiyaç duyduğu bilgileri tek vitrinde topla, panelden yönet, istediğin yerde paylaş.
```
(:36)

**4 kart (başlık / açıklama / ikon / renk):**

| # | İkon | Renk token | Hex | Başlık | Açıklama | Kaynak |
|---|---|---|---|---|---|---|
| 1 | `bolt_rounded` | primary | #147DFF | `Dakikalar içinde yayına alın` | `Temel bilgilerini ekle, vitrinini oluştur.` | :61-66 |
| 2 | `contact_phone_rounded` | mint (landingMint) | #10B981 | `Müşteriler size doğrudan ulaşsın` | `WhatsApp, adres ve yol tarifi seçeneklerini tek yerde sunun.` | :70-75 |
| 3 | `share_rounded` | pinkAccent (landingPinkAccent) | #8B5CF6 | `Her kanalda aynı vitrini paylaşın` | `Linkinizi sosyal medyada, QR kodunuzu işletmenizde kullanın.` | :79-84 |
| 4 | `edit_note_rounded` | blueAccent (=secondary) | #57B7FF | `Bilgilerini panelden güncelle` | `Fotoğraf, ürün, hizmet ve iletişim bilgilerini istediğin zaman düzenle.` | :88-93 |

Kart görünümü (`landing_value_card.dart`): zemin `surface`, radius 28, kenarlık 1.2px `border %85`; dolgu 24; ikon kutusu 54×54 radius 18, ikon rengi %14 zemin üzerinde 26px; başlık 22px w900 ls-0.6 h1.15 darkText; açıklama 16px w600 darkTextAlt h1.6; başlık-açıklama arası 10, ikon-başlık arası 18 (dikey modda). Hover (yalnız desktop grid'de etkin): -6px kalkma + 1.01 ölçek, 220ms easeOut, kenarlık kart rengine döner (%30), iki katmanlı gölge.

### 2.6 Karşılaştırma — `landing_comparison_section.dart` + `landing_setup_panel.dart`

Zemin `bgEditor`, dolgu dikey 88 / yatay 24, max 1200.

**Başlık (38px w900, ls -0.5, ortalı):**
```
Dijital vitrinin için gerekenler tek yerde
```
(:37)

**Alt metin (16px mutedText, height 1.5):**
```
Araçları ve kurulumları ayrı ayrı yönetmek yerine işletme bilgilerini Vixrex’e ekle, paylaşmaya başla.
```
(:48)

**Sol panel — label: `Ayrı ayrı kurulum` (highlighted=false):**

Satırlar (her biri Material ikonu + metin):
```
Domain ve hosting
Teknik ayarlar
WhatsApp bağlantısı
QR ve paylaşım süreci
İçerik güncelleme desteği
```
(:13-17 — ikonlar sırasıyla language, tune, chat_bubble_outline, qr_code_2, support_agent; mutedText renkte, kutu bgEditor zemin radius 12 36×36)

Footer:
```
Birden fazla araç ve işlem
```
(:63 — surfaceSoft zemin, kenarlık border, radius 14, 12px w900 mutedText, ortalı)

Panel etiketi stili: 13px w900 ls0.2 mutedText.

**Sağ panel — label: `Vixrex ile` (highlighted=true):**

Satır ikonlarının yerine turkuaz check `check_rounded` (#65E7E7, kutu beyaz %10):
```
İşletme bilgileri ve fotoğraflar
Ürünler ve hizmetler
WhatsApp, adres, link ve QR
Panelden kolay güncelleme
Müşteriyle doğrudan iletişim
```
(:19-25 — metin BEYAZ 14px w800)

Footer:
```
Tek panel, tek link, doğrudan iletişim
```
(:69 — beyaz %10 zemin, kenarlık beyaz %12, metin #BFF7F7)

Panel kabuğu (setup_panel:22-51): dolgu 26, radius 28. Normal: `surface` zemin, kenarlık `border`, gölge siyah %20 blur24 offset(0,16). Vurgulu: gradient `surface`→`turquoiseSurface` (sol üst→sağ alt), kenarlık `primary %38`, gölge `primary %14` blur34 offset(0,16). Etiketten sonra 22, satırlar arası 14, footer öncesi ~26.
Ortadaki yön oku: 46×46 daire, surfaceSoft zemin, kenarlık `primary %35`, gölge siyah %22 blur16 offset(0,8); ikon masaüstünde `arrow_forward_rounded`, mobilde `arrow_downward_rounded`, primary renk (comparison:72-95).

### 2.7 Güven Bandı — `landing_trust_band.dart`

Zemin `bgLight`, dolgu dikey 56 / yatay 24, max 1100.

**Başlık (30px w900, ortalı):**
```
Başlarken sürpriz yok
```
(:29)

**5 rozet (pill; zemin surface, kenarlık border, radius 999, dolgu 16×12; ikon primary 18px + metin 13px w800 darkText):**

| # | İkon | Metin | Kaynak |
|---|---|---|---|
| 1 | `credit_card_off_rounded` | `Kredi kartı gerekmez` | :12 |
| 2 | `percent_rounded` | `Satıştan komisyon alınmaz` | :13 |
| 3 | `code_off_rounded` | `Kodsuz kurulum` | :14 |
| 4 | `qr_code_2_rounded` | `Link ve QR kod hazırdır` | :15 |
| 5 | `chat_bubble_rounded` | `WhatsApp ile doğrudan iletişim` | :16 |

Başlık-rozet arası 28.

### 2.8 Adımlar — `landing_steps_section.dart`

Zemin `bgLight`, dolgu dikey 76 / yatay 24, max 1200.

**Başlık (36px w900, ortalı):**
```
Üç adımda dijital vitrinin hazır
```
(:21)

**Adımlar (başlıktan 56 sonra; numara daireleri):**

| # | Başlık (18px bold) | Açıklama (14px mutedText w600 h1.45) | Kaynak |
|---|---|---|---|
| 1 | `Vitrininizi kurun` | `İşletme bilgilerini, görsellerini, ürün ve hizmetlerini ekle.` | :37-38 |
| 2 | `Yayınla` | `Bilgilerinizi kontrol edin; vitrin linkinizi ve QR kodunuzu hazır edin.` | :42-43 |
| 3 | `Müşterilerinize duyurun` | `Linkinizi WhatsApp, sosyal medya veya işletmenizdeki QR kod ile paylaşın.` | :47-48 |

Numara dairesi: 60×60, `primary %10` zemin, `primary %30` 2px kenarlık, içinde sayı 24px w900 primary. Daire-başlık arası 20, başlık-açıklama arası 10, açıklama yatay iç boşluk 20. Mobilde adımlar alt alta +28px.

### 2.9 Şablon Kataloğu — `landing_template_catalog.dart` + `landing_template_category.dart` + `landing_template_card.dart`

Zemin `bgLight`, dolgu dikey 64 / yatay 24, max 1200, ortalı.

**Üst pill (primary %10 zemin, radius 999, dolgu 16×8):**
```
HAZIR ŞABLONLAR
```
(:333 — primary, 12px w900, ls1.5)

**Başlık (28px w900, h1.2, ortalı):**
```
İşletme Kategorine Özel Hazır Görseller
```
(:344)

**Alt metin (15px mutedText w600, h1.5, ortalı):**
```
12 farklı kategoride profesyonel, telifsiz görsellerle vitrinini saniyeler içinde oluştur.
```
(:357)

> ⚠️ **TUTARSIZLIK — DOĞRULANMALI (ürün kararı):** Metin "12 kategori" diyor ama `templateCategories` listesi **20 kategori** içerir (landing_template_category.dart:12-128) ve grid `templateCategories.length` kadar kart basar (catalog:385). Portta mevcut davranışı koruyan seçim: 20 kart + metin olduğu gibi. Karar bekliyor.

**Kart alt etiketi (yükleme bitince):**
```
Hazır görseller →
```
(template_card:100 — primary, 11px w700; yüklenirken 16×16 spinner strokeWidth 2 :93-98)

**Kategorilerin TAM listesi (key / label / ikon / renk) — `landing_template_category.dart:12-128`:**

| key | label | ikon | renk |
|---|---|---|---|
| butik_giyim | `Butik & Giyim` | checkroom_rounded | #FF5A1F |
| kuafor_guzellik | `Kuaför & Güzellik` | content_cut_rounded | #DB2777 |
| kafe_restoran | `Kafe & Restoran` | restaurant_menu_rounded | #EA580C |
| berber | `Berber` | face_rounded | #7C3AED |
| oto_kuafor | `Oto Kuaför` | local_car_wash_rounded | #2563EB |
| market_bakkal | `Market & Bakkal` | shopping_basket_rounded | #059669 |
| pastane_tatlici | `Pastane & Tatlıcı` | bakery_dining_rounded | #D946EF |
| mobilya_dekorasyon | `Mobilya & Dekorasyon` | chair_rounded | #CA8A04 |
| spor_salonu | `Spor Salonu` | fitness_center_rounded | #DC2626 |
| dis_klinigi | `Diş Kliniği` | medical_services_rounded | #0891B2 |
| eczane | `Eczane` | local_pharmacy_rounded | #16A34A |
| teknik_servis | `Teknik Servis` | build_circle_rounded | #4F46E5 |
| butik | `Butik` | local_mall_rounded | #8B5CF6 |
| kozmetik | `Kozmetik` | face_retouching_natural_rounded | #F472B6 |
| elektronik | `Elektronik` | devices_rounded | #6366F1 |
| kirtasiye | `Kırtasiye` | menu_book_rounded | #FBBF24 |
| pet_shop_veteriner | `Pet Shop & Veteriner` | pets_rounded | #14B8A2 |
| hizmet_danismanlik | `Hizmet & Danışmanlık` | business_center_rounded | #84CC16 |
| egitim_ders | `Eğitim & Ders` | school_rounded | #38BDF8 |
| ev_temizlik | `Ev & Temizlik` | clean_hands_rounded | #4ADE80 |

Grid: kolon sayısı kırılıma göre 4/3/2, hücre aralığı 16 (yatay+dikey), childAspectRatio 0.85.
Kart (template_card): zemin surface, radius 20, kenarlık border, gölge siyah %4 blur12 offset(0,4); üst 3/5 kapak görseli (`coverImages.first.imageUrl`; yoksa kategori ikonu fallback — ikon 48px, kategori rengi %40, zemin kategori rengi %8); alt 2/5 dolgu 14: ikon çipi (kategori rengi %12 zemin, radius 8, ikon 18) + label 13px w800 darkText + `Hazır görseller →`.

**Bottom sheet önizleme (karta dokununca, catalog:76-308) — metinler:**

| Öğe | Metin | Kaynak |
|---|---|---|
| Başlık | `{category.label}` (yukarıdaki liste) | :127 |
| Sayaç (görsel varken) | `{imageSet.totalCount} hazır görsel mevcut` | :137 |
| Sayaç (yüklenirken) | `Hazır görseller yükleniyor...` | :138 |
| Bölüm başlığı 1 | `Kapak Görselleri` | :163 |
| Bölüm başlığı 2 | `Galeri Görselleri` | :189 |
| Bölüm başlığı 3 | `Ürün Görselleri` | :215 |
| Boş durum metni | `Bu kategori için henüz hazır görsel bulunmuyor.` | :260 |
| Aksiyon butonu (ikon arrow_forward_rounded 20) | `Bu Şablonla Başla` | :285 |

Sheet görünümü: yükseklik faktörü 0.85, zemin surface, üst köşe radius 24; tutamak 40×4 border rengi radius 999; başlık satırı: ikon çipi (kategori rengi %15, radius 12, ikon 24) + başlık 18px w900 + sayaç 12px w600 mutedText; bölüm başlıkları 13px w800 darkText; thumbnail şeritleri yükseklik 120, genişlik 160, radius 12, alt gradient (siyah %70) üzerine `title` etiketi 10px w700 beyaz (maxLines 1); boş durumda `image_not_supported_outlined` 48px mutedText %50; buton yükseklik 54, primary zemin, beyaz yazı 15px w900, radius 16.

### 2.10 Alt CTA — `landing_bottom_cta.dart`

Zemin: gradient `bgEditor` → `primary`, sol üst→sağ alt (:22-27); dolgu dikey 88 / yatay 24; içerik max 800.

**Başlık (36px w900, h1.2, ortalı, renk surfaceSoft):**
```
İşletmenizi tek linkte müşterilerinizle buluşturun
```
(:35)

**Alt metin (18px, h1.5, ortalı, renk border):**
```
Vixrex’ini oluştur; linkini, QR kodunu ve WhatsApp iletişimini paylaşmaya başla.
```
(:47)

**Buton (radius 24, padding 40×24, elevation 10, primary zemin / beyaz yazı 18px w900):**
```
Vixrex Oluştur
```
(:71)

### 2.11 Footer — `landing_bottom_cta.dart:82-133`

Zemin `bgEditor`, dikey dolgu 60, ortalı sütun.

| Öğe | Metin | Hedef/route | Kaynak |
|---|---|---|---|
| Marka (16px w900, letterSpacing 8, primary %80) | `VIXREX` | — | :90 |
| Tagline (14px w600 mutedText) | `İşletmenizin paylaşılabilir dijital vitrini` | — | :100 |
| Yasal link 1 | `KVKK ve Gizlilik Politikası` | `LegalConfig.privacyPath` = `/privacy` | :115-116 |
| Yasal link 2 | `Kullanım Şartları` | `LegalConfig.termsPath` = `/terms` | :120-121 |
| Yasal link 3 | `Veri Silme` | `LegalConfig.dataDeletionPath` = `/data-deletion` | :125-126 |

Link stili: 13px w800 mutedText, dolgu 12×8. Kaynak değerler: legal_config.dart:33-36.
public_web'de `/privacy` ve `/data-deletion` klasörleri mevcut (`public_web/src/app/`); `/terms` rotasının durumu DOĞRULANMALI (`src/app/legal/` altındaki route eşlemesine bakılmalı).

### 2.12 Yüzen Maskot FAB + Balonu — `chatbot_badge.dart`

- Görsel: `assets/images/vixrex_v_crystal_mascot.png` (60×60 contain; hata olursa `assets/images/vixrex_mascot.webp`) (:222-233).
- Kabuk: 60×60 daire, `#0E1B2E` %78 zemin, kenarlık `#38A0E4` %63 1.5px; nabız glow `#0EA5E9` (blur 16, spread 2, opaklık salınımı 2sn); dikey tarama çizgisi (3sn döngü); sağ altta yeşil nokta #10B981 6px (+glow).
- Konuşma balonu (maksimum genişlik 220, mesaj değişince yeniden açılır, 6 sn sonra kendiliğinden kapanır; balona dokunmak kapatır):

| Durum | Metin | Kaynak |
|---|---|---|
| Profil yok / ad tamamlanmamış | `👋 Dijital vitrinini hazırlayayım mı?` | :127 |
| Kategori eksik | `Sıradaki adım: Kategorini seç` | :132 |
| Her şey tamam | `✨ Vitrinin harika görünüyor!` | :141 |
| Genel öneri | `Sıradaki adım: {öneri başlığı}` (VixRexGuidanceService.recommendationFor sonucu) | :143 |

Balon görünümü: `#EE0E1B2E` zemin, köşeler (14,14,14,3), kenarlık `#0EA5E9` %71 1.2px, gölge blur10 offset(0,3), metin beyaz 11.5px w700 maxLines 2; ±4px yüzme animasyonu (1800ms).

DOĞRULANMALI: durum-bazlı balon mesajları yerel profil anlık görüntüsüne bağlıdır. SSR statik sayfada varsayılan `👋 Dijital vitrinini hazırlayayım mı?` basılıp diğerleri hydration sonrası mı gösterilecek — kapsam kararı.

---

## 3. Etkileşim haritası

| Tetikleyici | Flutter davranışı | Kod | Next.js port notu |
|---|---|---|---|
| Nav `Vitrinleri Keşfet` | `_navigateToExploreApp()` → HomeShell sekme 1 (Keşfet); GoRouter `/home` | screen:340-347 | App (vixrex-app) Keşfet akışına dış bağlantı. DOĞRULANMALI: kesin hedef URL (app origin + path/fragment) ürün kararı |
| Nav `Giriş Yap` | `AppRouter.navigateToAuth` → `/auth`; dönüşte state yenilenir | hero:314-317, :341-346 | App auth sayfasına dış bağlantı. DOĞRULANMALI: app origin'deki auth adresi |
| Nav `Çıkış Yap` | `AuthService().signOut()` → UI + `hasSavedVitrin` yeniden yüklenir | hero:270-275; screen:444-449 | Oturumlu kullanıcı landing'de nadir; v1'de gösterilmeyebilir mi — DOĞRULANMALI (kapsam) |
| Hero `Kayıtlı Vitrinimi Düzenle` | HomeShell sekme 0 (`navigateToHomeShell(context)`) | screen:349-351 | App'e yönlendirme. DOĞRULANMALI |
| Hero `Farklı vitrinleri incele` | Keşfet (sekme 1) | hero:473-485 | Nav Keşfet ile aynı hedef |
| Setup input + `Ücretsiz Vitrinimi Hazırla` | Input değeri `initialVitrinName` olarak HomeShell sekme 2'ye taşınır | screen:385-393 | App onboarding'e isim parametresiyle geçiş gerekebilir. DOĞRULANMALI: app'in URL parametre desteği |
| Mockup'a dokunma — kapak görseli, önizleme çipi, aksiyon çipleri, link kartları, galeri kareleri (hepsi `onPreviewTap`) | Aktif profil adından `_landingDemoDrafts` slug'ı bulunur → `openPublicUrl(PublicSiteConfig.buildVitrinLink(slug))`: **dış tarayıcıda** `https://vixrex-public.vercel.app/v/{slug}`; slug yoksa snackbar `Demo vitrin önizlemesi açılamadı.` | screen:368-383; PublicSiteConfig:53-57 | Next.js'te hedef artık AYNI site: `<a href="/v/{slug}">`. Slug map HARFİYEN (screen:361-366): `Aymira Giyim`→`demo-aymira-giyim`, `Lezzet Durağı`→`demo-lezzet-duragi`, `Nova Kuaför`→`demo-nova-kuafor`, `TeknoFix`→`demo-teknofix` |
| Katalog kartına dokunma | Bottom sheet önizleme açılır | catalog:76-308 | Modal/sheet bileşeni; SSR verisi hazır olursa anında dolu açılır |
| Sheet `Bu Şablonla Başla` | Sheet kapanır → `savePendingCategoryKey(categoryKey)` → Keşfet akışı (dosya üstü yorum: "auth -> vitrin formu akışı") | catalog:279-282; screen:340-347 | Seçilen kategori app tarafına taşınmalı. DOĞRULANMALI: `pendingCategoryKey`'in app'teki okuma yeri ve app URL'siyle aktarım şekli |
| Alt CTA `Vixrex Oluştur` | `onNavigateToEditor` = setup submit ile aynı (bu noktada input boş → isimsiz) | screen:460, :385-393 | App onboarding'e yönlendirme |
| Footer yasal linkleri | Flutter içi push `/privacy`, `/terms`, `/data-deletion` | bottom_cta:140-151 | Next.js'te bunlar AYNI sitenin rotaları — düz `<a>` linkleri |
| Maskot FAB'a dokunma | `_openMockupChat`: telefon mockup İÇİNDE `VixRexOnboardingChatScreen(compact:true)` overlay açılır + sayfa kaydırılır (mobil 560px / masaüstü 0; 450ms easeOutCubic) | screen:395-418; hero_mockup:79-93 | **En büyük kapsam sorusu:** gerçek sohbet motoru (VixRexSessionController + StoreEditorController) Flutter'da. v1 önerisi: FAB setup formuna/CTA'ya smooth-scroll veya app'e yönlendirme yapsın. DOĞRULANMALI (kapsam kararı) |
| Balona dokunma | Balon kapanır, maskot yerinde kalır | chatbot_badge:171-174 | Basit dismiss state |

Oturum gerektiren öğeler: yalnızca `Çıkış Yap` butonu ve koşullu `Kayıtlı Vitrinimi Düzenle` görünümü (yerel kayıt + bulut doğrulaması). Diğer tüm butonlar/linkler anonimdir.

---

## 4. Veri bağımlılıkları

**Düzeltme (görevdeki varsayıma karşı):** `landing_hero_section.dart:666`'daki `Supabase.instance.client` **veri çekmez** — tek kullanım oturum denetimidir (`auth.currentUser != null`, :664-670). `lib/widgets/landing/` altındaki hiçbir widget veritabanına erişmez (grep ile doğrulandı). Veri erişimi ekran seviyesindedir.

| # | Bağımlılık | Nerede | Sorgu/kaynak | Tip |
|---|---|---|---|---|
| 1 | Auth oturumu | hero nav `_isUserLoggedIn` | `supabase.auth.currentUser` | Canlı (client-side) |
| 2 | Kayıtlı vitrin durumu (`hasSavedVitrin`) | screen:291-338 | `StoreLocalStorageService.loadVitrinData()` + `loadPublishedVitrinInfo()` (localStorage); iddia edilen slug bulutta gerçekten var mı: `StorePublishService.yayindaMi(slug)` → `stores` tablosu slug sorgusu (store_publish_service.dart:39-47). Bulut kesin "yok" demedikçe yerel kayıt korunur ("hayalet vitrin" koruması, screen:297-318) | Hibrit (localStorage + canlı) |
| 3 | Şablon görselleri — hem hero demo galerileri hem katalog | screen:232-281; catalog:48-74 | `CategoryImageService.getImagesForCategory(key)`: `category_image_templates` tablosundan `select('*').eq('category_key', key).eq('is_active', true).order('display_order')` (category_image_service.dart:114-152). Satır alanları: `id, category_key, category_label, image_type ('cover'\|'logo_placeholder'\|'gallery'\|'product'), image_url, thumbnail_url, title, description, display_order, source_url`. Sonuç boş/hata → fallback set (§5.3) | **Canlı veri** — SSR'da karşılanmalı |
| 4 | Demo vitrin slug map | screen:361-366 | Sabit map; demo vitrinler yayında ve `is_demo` işaretli (migration `20260805210000_publish_landing_demo_stores.sql`, screen yorumu :353-360) | Statik |
| 5 | Fallback görsel havuzu | category_image_service.dart:155-218 | DB boş/hatada Unsplash sabit URL map'i | Statik |

### SSR'da karşılanması (public_web mevcut deseniyle uyumlu)

- Mevcut public istemci deseni: `public_web/src/lib/supabase.ts` — env `SUPABASE_URL` + `SUPABASE_PUBLISHABLE_KEY` (veya NEXT_PUBLIC_* ikilisi) ile `createClient`; server component'lerde doğrudan kullanılabilir (admin varyant: `supabaseAdmin.ts`).
- Ana sayfa Server Component olmalı ve:
  1. Katalog için Flutter'daki 20 ayrı istek yerine TEK sorgu önerilir: `.from('category_image_templates').select('*').eq('is_active', true).order('display_order')`, JS'te `category_key`'e göre grupla.
  2. Hero demo profilleri aynı veriden beslenir: profilin `templateCategoryKey`'ine göre filtrele → kapak `coverImages[0].imageUrl`, galeri `galleryImages` ilk 3 (Flutter mantığı screen:244-267; kapak canlıda yoksa statik Unsplash kapak korunur).
  3. DB sonucu boşsa fallback Unsplash setine düş (category_image_service.dart:148-151) — sayfa asla boş görselle render olmamalı.
  4. `next/image` remotePatterns'e eklenecek host'lar: `chfulefxczbgurtgavtp.supabase.co` (storage) ve `images.unsplash.com` (fallback). DOĞRULANMALI: `next.config.ts` içindeki mevcut remotePatterns.
  5. RLS: storage bucket `category-templates` public (policy `category_templates_storage_public`, supabase_schema.sql:1879). Tablo `category_image_templates` için anon SELECT izni SSR anon-key okuması için şart — DOĞRULANMALI: tablo policy'sini migration'lardan teyit et.
  6. `hasSavedVitrin` + auth durumu sunucuda bilinemez (localStorage/cookie) → SSR çıktısı "kayıtsız" varsayılanını (setup formu) basmalı; kayıtlı-vitrin görünümü client hydration sonrası değişmeli. Böylece bot birincil CTA'yı (`Ücretsiz Vitrinimi Hazırla`) her zaman görür.
  7. Demo linkleri statik map'ten SSR'da gerçek `<a href="/v/demo-...">` olarak basılmalı (SEO için bot erişilebilir).
  8. Mevcut `public_web/src/app/page.tsx`, kök `/` rotasını `getAppUrl()`'e REDIRECT ediyor (:1-7). Port tamamlandığında bu redirect YENİ landing sayfasıyla değiştirilecek — aksi halde yeni sayfa asla görünmez. Entegrasyonun ilk maddesi budur.

---

## 5. Görsel varlıklar

### 5.1 Yerel asset (public_web'e kopyalanmalı)

| Asset | Kullanım | Hedef |
|---|---|---|
| `assets/images/vixrex_v_crystal_mascot.png` | ChatbotBadge maskotu (60×60) | `public_web/public/images/...` |
| `assets/images/vixrex_mascot.webp` | Maskot fallback | Aynı klasör (fallback zinciri korunacaksa) |

### 5.2 Telefon mockup içeriği nasıl üretiliyor

Gerçek ekran görüntüsü DEĞİLDİR — **tamamen widget'larla çizilmiş sahte vitrin arayüzü** (phone_mockup.dart): çentik + kapak görseli + gradyan overlay + isim/kategori/badge + `Hakkında` + aksiyon çipleri + en fazla 2 link kartı + 3'lü galeri şeridi (+ `{n} fotoğraf` çipi) + `Vitrin hazır` kutusu + home indicator. Next.js'te HTML/CSS ile birebir kurulabilir; tüm metin/renk verisi §2.3'tedir.

Mockup kabuk ölçüleri: dış 325×640, radius 40, zemin #EB0A101C (ARGB), kenarlık beyaz %18 2.5px; üçlü gölge (#0EA5E9 spread 1.5 blur 0; siyah %55 blur50 offset(0,25); #0EA5E9 %35 blur36 offset(0,16)); iç ekran radius 34, zemin bgEditor, kenarlık border. Yükseklik <700 ise ölçek `(h/700).clamp(0.5,1.0)` (:13-20).
Kapak bölümü: yükseklik 156; alt katman gradient (accentColor %18 → bgLight, sol üst→sağ alt); cover görseli `BoxFit.cover` (hatada accent renkte profil ikonu 42px); siyah overlay %16→%52 (üstten alta).

### 5.3 Uzak görseller

- **Yeni storage deseni** (migration `supabase/migrations/20260825000000_sablon_gorselleri_kendi_deponuzda.sql`, #235):
  `https://chfulefxczbgurtgavtp.supabase.co/storage/v1/object/public/category-templates/{kategori_key}/{tip}-{sira}-{hash}.jpg`
  - `{tip}` ∈ `cover | gallery | logo_placeholder | product`; örnek: `.../butik/cover-1-69582d.jpg`
  - Eski Unsplash adresi satırda `source_url` kolonunda saklanıyor (lisans izi).
  - UI key ↔ DB key eşlemesi: `landing_template_catalog._dbKey` (:30-46) — mevcut içerik kimlik eşlemesi (birebir). DOĞRULANMALI: 20 UI key'inin tamamının DB `category_key` uzayında karşılığı var mı (örn. UI'daki `kozmetik`, `kirtasiye`, `pet_shop_veteriner` migration başlıklarında görülmedi; DB'de bu key'lerde satır yoksa o kartlar fallback'e düşer).
- **Statik Unsplash fallback map'i** (category_image_service.dart:177-218) kategori başına bir cover içerir; hepsi `w=1200&q=80` biçimindedir. Portta bu map aynen bir sabite dönüştürülmelidir (tam liste kaynak dosyadadır; burada tek tek tekrarlanmadı — dosya referansı bağlayıcıdır).
- **Hero demo statik görselleri**: §2.3'te profil bazında listelendi (kapak w=400, galeri w=300).

---

## 6. Tasarım dili

### 6.1 Renk paleti (Flutter `AppColors` — landing'de kullanılanların TAM hex listesi)

| Token | Hex | Landing kullanımı |
|---|---|---|
| `primary` | `#147DFF` | Tüm birincil butonlar, ikonlar, numara daireleri, link vurguları |
| `secondary` | `#57B7FF` | H1 ortası span, hero rozet metni/kenarlığı, TextButton |
| `onPrimary` | `#06152F` | primary üzerindeki yazı |
| `bgEditor` | `#050B1A` | Hero gradient başlangıcı, comparison zemini, footer zemini, CTA gradienti, mockup iç ekranı |
| `bgLight` | `#08132D` | Scaffold/body zemini, çoğu bölümün zemini, hero gradient bitişi |
| `surface` | `#0B1730` | Kartlar, rozet pill'leri, sheet zemini, normal setup paneli |
| `surfaceSoft` | `#112448` | Nav Keşfet butonu, value band çipleri, comparison oku, CTA başlık rengi |
| `turquoiseSurface` | `#102B59` | Vurgulu setup panel gradient sonu |
| `darkText` | `#F7FBFF` | Başlıklar ve ana metin |
| `darkTextAlt` | `#D9E7FF` | İkincil metin (alt paragraflar) |
| `mutedText` | `#A9BBDA` | Üçüncül metin, yasal linkler, adım açıklamaları |
| `border` | `#294D88` | Standart kenarlık, pasif slayt noktaları, CTA alt metin rengi |
| `landingMint` | `#10B981` | Özellik kartı 2 rengi (= success) |
| `landingBlueAccent` | `#57B7FF` (= secondary) | Özellik kartı 4 |
| `landingPinkAccent` | `#8B5CF6` | Özellik kartı 3; mesh glow |
| Rozet check yeşili | `#10B981` | Hero güven rozetleri ikonu |
| Kayıtlı vitrin gradienti | `#0EA5E9 → #2563EB` | "Kayıtlı Vitrinimi Düzenle" butonu (+glow #0EA5E9) |
| Setup panel check / footer | `#65E7E7` / `#BFF7F7` | Vurgulu panelde ikon ve footer metni |
| Mockup aksiyon/link renkleri | `#25D366` (WhatsApp), `#E1306C` (Instagram), `#EF4444`, `#2563EB`, `#F27A1A` (Trendyol), `#DB2777`, `#EA580C`, `#10B981`, `#6366F1`, `#FF5A1F` | Demo profil içerikleri (§2.3) |
| FAB süsleri | `#0EA5E9`, `#38A0E4`, `#0E1B2E`, `#EE0E1B2E` | ChatbotBadge kabuk/balon |
| Mockup kabuğu | `#EB0A101C` (ARGB), `#0A101C` | Telefon dış kabuk zemini |

⚠️ **PALET UYARISI — DOĞRULANMALI:** public_web'in mevcut token'ları (`public_web/src/app/globals.css:11-31`) FARKLI değerler kullanıyor: `--primary: #38A0E4`, `--bg-app: #071322`, `--surface: #0E1B2E`, `--text-dark: #F8FAFC`, `--text-muted: #8FA6BE`, `--border: #25415F`. Flutter landing ise yukarıdaki AppColors paletini kullanır (#147DFF ailesi). İki seçenek: (a) landing'e özgü scope'lanmış yeni token seti ekle (`--lp-*`) ve AppColors değerlerini harfiyen taşı — görsel birebirlik için önerilen bu; (b) mevcut vitrin token'larına oturt (renkler kayar). Karar bekliyor.

### 6.2 Tipografi

- Font ailesi: **Outfit** (app_theme.dart:25; public_web aynı aileyi tanıyor — `globals.css:7 --font-outfit: 'Outfit'`; layout'ta yüklü olup olmadığı DOĞRULANMALI).
- Landing'de kullanılan ölçekler (px/weight): 48 w900 · 38 w900 · 36 w900 · 30 w900 · 28 w900 · 24 w900 · 22 w900 · 20 w900 · 18 bold/w600/w800/w900 · 16 w500-w700 · 15 w600-w900 · 14 w600-w900 · 13 w600-w900 · 12 w600-w900 · 11 w600-w900 · 10 w700-w800.
- Karakteristikler: başlıklar hep w900 (Black); letterSpacing H1 -0.8, karşılaştırma başlığı -0.5, kart başlığı -0.6; pill/badge metinlerinde geniş letterSpacing (+1.0, +1.5; footer +8).
- Tailwind önerisi: ağırlık için `font-black` baskın; boyutlar arbitrary (`text-[38px] leading-[1.2] tracking-[-0.5px]`) ya da Tailwind v4 `@theme` içinde adlandırılmış ölçek.

### 6.3 Radius ölçeği

| Değer | Nerede |
|---|---|
| 999 (hap/daire) | Çipler, rozetler, önizleme çipi, sayaç etiketleri, sheet tutamağı |
| 40 / 34 | Telefon dış kabuk / iç ekran |
| 30 | Hero üst rozet |
| 28 | Value card, setup panel |
| 24 | Alt CTA butonu, sheet üst köşeleri |
| 20 | Kart kapak üst köşeleri, katalog kartı, mockup yüzen rozetleri, hero güven rozet kutusu |
| 16 | Form inputu, submit/kayıtlı-vitrin/sheet butonu |
| 14 | Link kartları, panel footer kutusu, balon köşeleri, nav ikon butonları |
| 12 | İkon çipleri, action çipleri, galeri kareleri, numara yok — kontrol radius sözleşmesi |

### 6.4 Gölge desenleri

- Yumuşak kart gölgesi: siyah %4-8, blur 12-24, offset (0,4)-(0,18)
- Derin panel gölgesi: siyah %20 blur24 offset(0,16); vurgulu panelde markalı `primary %14` blur34
- Hover kart: iki katman — kart rengi %16 blur30 offset(0,16) + siyah %8 blur30 offset(0,18)
- Marka glow: `primary %14` blur34 (vurgulu panel); `#0EA5E9` ailesi mockup ve FAB'da; alt CTA butonu elevation 10
- Tailwind önerisi: arbitrary shadow (`shadow-[0_16px_24px_rgba(0,0,0,0.2)]`) veya `@theme` içinde `--shadow-lp-*`

### 6.5 Boşluk ölçeği

AppColors spacing sabitleri: 4/8/12/16/20/24/30/32/40/60/80/100/120.
Landing bölüm dikey dolguları: nav 16 · hero alt 100(d)/50(m) · value band 64 · features 48+72 · comparison 88 · trust 56 · steps 76 · katalog 64 · CTA 88 · footer 60 · sayfa sonu 96.
İçerik genişliği: neredeyse tüm bölümler `maxWidth: 1200` (trust band 1100, bottom CTA 800), yatay dolgu 24. Tailwind önerisi: `max-w-[1200px] mx-auto px-6`.

---

## 7. Flutter'a özgü parçalar ve Next.js eşdeğeri

| Flutter öğesi | Detay | Next.js eşdeğer davranış önerisi |
|---|---|---|
| Mesh glow animasyonu (hero) | 16sn sonsuz döngü; sin/cos ile 3 radial-gradient dairenin konum salınımı (±20-40px): primary %30 (300px), blueAccent %25 (400px), pinkAccent %20 (250px) (hero:63-102, :653-662) | CSS keyframes: 3 mutlak konumlu blur'lu daire (`radial-gradient(closest-side, renk, transparent)`), `transform: translate` salınımı; `prefers-reduced-motion`'da durdur |
| Profil karuseli | AnimationController 16sn repeat; index = `(değer*4).floor()` (screen:212-230); slayt geçişi AnimatedSwitcher 520ms easeOutCubic fade + sağdan %6 slide (mockup:49-62) | Client component: 4000ms interval + CSS transition (opacity + translateX(6%→0)); SSR ilk kare = Profil 1 (bota statik içerik) |
| Yüzen rozet bobbing | sin((value+phase)*2π)*10px (mockup:99-123) | CSS keyframes translateY ±10px, farklı delay'ler |
| Slayt noktaları | AnimatedContainer 260ms (mockup:131-143) | CSS width/color transition |
| ValueCard hover | -6px translate + 1.01 scale, kenarlık/gölge değişimi, 220ms (value_card:68-129) | Tailwind `hover:-translate-y-1.5 hover:scale-[1.01] transition duration-200` |
| BackdropFilter blur (yüzen rozetler) | ui.ImageFilter.blur 12 (mockup:152-156) | `backdrop-filter: blur(12px)` + yarı saydam zemin |
| SafeArea | Web'de etkisiz | Gerekmez |
| Mockup ölçeklenmesi | yükseklik <700'de `(h/700).clamp(0.5,1.0)` transform (phone_mockup:13-20) | Responsive genişlik veya `transform: scale()` |
| Material Icons | ~55 farklı ikon kullanılır: storefront, explore, login_rounded, logout_rounded, edit_document, arrow_forward_rounded, arrow_downward_rounded, check_circle_rounded, check_rounded, bolt_rounded, contact_phone_rounded, share_rounded, edit_note_rounded, language_rounded, tune_rounded, chat_bubble_outline_rounded, chat_bubble_rounded, qr_code_2_rounded, support_agent_rounded, inventory_2_rounded, hub_rounded, forum_rounded, credit_card_off_rounded, percent_rounded, code_off_rounded, menu_book_rounded, directions_rounded, location_on_rounded, delivery_dining_rounded, local_dining_rounded, spa_rounded, event_available_rounded, construction_rounded, verified_rounded, phone_android_rounded, camera_alt_rounded, photo_library_rounded, shopping_bag_rounded, restaurant_menu_rounded, content_cut_rounded, calendar_month_rounded, build_circle_rounded, checkroom_rounded, face_rounded, local_car_wash_rounded, shopping_basket_rounded, bakery_dining_rounded, chair_rounded, fitness_center_rounded, medical_services_rounded, local_pharmacy_rounded, devices_rounded, pets_rounded, business_center_rounded, school_rounded, clean_hands_rounded, image_outlined, broken_image, image_not_supported_outlined, local_mall_rounded, face_retouching_natural_rounded, local_pharmacy_rounded | public_web'de ikon kütüphanesi YOK (package.json'da bağımlılık yok). Öneri: inline SVG bileşen seti ya da tek bağımlılık olarak `lucide-react`. DOĞRULANMALI: hangisi? Material ikonlarının birebir karşılığı olmayanlarda en yakın eşleme tablosu çıkarılmalı |
| ChatbotBadge pulse/scan/float | 3 paralel AnimationController: pulse 2sn reverse, scan 3sn linear, float 1800ms reverse (chatbot_badge:72-96) | CSS keyframes (box-shadow pulse, translateY scan/float) |
| Mockup içi sohbet overlay | Gerçek VixRex sohbet motorunun kompakt hali (hero_mockup:79-93; VixRexSessionController tek oturumu HomeShell sohbetiyle paylaşır — screen:41-46) | §3'teki kapsam kararına kadar TAŞINMADI varsay; FAB'a alternatif davranış bağlanır |
| Programatik scroll | Sohbet açılışında animateTo 450ms easeOutCubic, mobil hedef 560px (screen:395-414) | `scrollIntoView({behavior:'smooth'})` |
| SnackBar | `Demo vitrin önizlemesi açılamadı.` (screen:371-376) | Portta gerekmez — slug map sabitse her zaman bulunur |
| FittedBox prefix kısaltması | Dar alanda `vixrex-public.vercel.app/v/` → `/v/` (hero:503-520) | İki media-query metni veya CSS truncate |
| RichText renkli span | H1 ortası secondary (#57B7FF) | `<span className="text-[#57B7FF]">` |
| Gradient yüzeyler | Kayıtlı vitrin butonu (#0EA5E9→#2563EB), vurgulu panel (surface→turquoiseSurface), alt CTA (bgEditor→primary), hero arka planı (bgEditor→bgLight), kapak overlay'leri | Tailwind `bg-gradient-to-*` |

---

## 8. Port kontrol listesi (kabul kriterleri)

### Entegrasyon
- [ ] `public_web/src/app/page.tsx` redirect'i kaldırıldı; `/` artık SSR landing sayfası (§4 madde 8)
- [ ] Sayfa Server Component; HTML kaynak görüntülendiğinde TÜM metinler bot tarafından okunabilir (view-source testi)
- [ ] Metadata tanımlandı: `<title>` + description (Flutter tarafında yoktu; örn. tagline `İşletmenizin paylaşılabilir dijital vitrini` kullanılabilir — DOĞRULANMALI)
- [ ] Maskot PNG/WebP `public/images/` altına kopyalandı ve yükleniyor

### Bölüm bölüm (yukarıdan aşağı)
- [ ] Nav: logo dairesi + `Vixrex`; masaüstünde `Vitrinleri Keşfet` + `Giriş Yap` etiketli, mobilde ikon-only
- [ ] Hero: rozet `VİXREX ASİSTAN İLE DİJİTAL VİTRİN`; H1 üç parçalı, orta span #57B7FF; alt metin; setup formu (ön ek + hint `isletmeniz` + `Ücretsiz Vitrinimi Hazırla`); 4 güven rozeti tam metinle (emoji'siz)
- [ ] Hero mockup: çentik, kapak, `Hakkında`, 2 aksiyon çipi, 2 link kartı, 3'lü galeri + `3 fotoğraf` çipi, `Vitrin hazır` + `N bağlantı`, home indicator; 4 demo profili sırayla dönüyor; yüzen 2 rozet ve nokta göstergeler var
- [ ] Mockup tıklaması aktif profile göre `/v/demo-{aymira-giyim|lezzet-duragi|nova-kuafor|teknofix}` adreslerini açıyor
- [ ] Value band: başlık + alt metin + 5 çip (`WhatsApp`, `Sosyal medya`, `Google İşletme`, `QR kod`, `Vitrin linki`); masaüstü yan yana / mobil alt alta
- [ ] Features: başlık + alt metin + 4 kart (ikon/renk/metin §2.5 ile birebir); hover efekti desktop'ta çalışıyor
- [ ] Comparison: başlık + alt metin (`Vixrex’e` kesmesi dahil) + iki panel (5+5 satır + footer'lar) + yön oku (masaüstü sağa / mobil aşağı); vurgulu panel gradientli, check ikonlu
- [ ] Trust band: `Başlarken sürpriz yok` + 5 rozet tam metinle
- [ ] Steps: `Üç adımda dijital vitrinin hazır` + 3 adım tam metinle
- [ ] Katalog: `HAZIR ŞABLONLAR` pill + başlık + alt metin + grid (4/3/2 kırılım) + 20 kategori kartı; kapaklar Supabase storage'dan; görselsiz kategoride ikon fallback
- [ ] Sheet önizleme: kategori başlığı + `{n} hazır görsel mevcut` + Kapak/Galeri/Ürün şeritleri + `Bu Şablonla Başla`
- [ ] Alt CTA: gradient zemin + başlık + alt metin + `Vixrex Oluştur`
- [ ] Footer: `VIXREX` + tagline + 3 yasal link çalışıyor (`/privacy`, `/terms`, `/data-deletion`)
- [ ] Sağ altta maskot FAB + balon (`👋 Dijital vitrinini hazırlayayım mı?`); sayfa sonunda 96px boşluk

### Veri
- [ ] `category_image_templates` tek sorguda çekiliyor; `is_active=true`, `display_order` sıralı; boşsa Unsplash fallback devrede
- [ ] next/image remotePatterns: supabase.co storage host + images.unsplash.com
- [ ] Demo linkleri SSR HTML'inde gerçek `<a href="/v/demo-...">` olarak mevcut
- [ ] Oturum/kayıtlı-vitrin durumları hydration sonrası çözülüyor; SSR çıktısı her zaman setup-formunu içeriyor

### Kalite
- [ ] Metin diff'i: bu dokümandaki §2 metinleriyle render edilen HTML birebir eşleşiyor (U+2019 kesmeler, emoji'siz rozetler dahil)
- [ ] Mobil 360px / tablet 768px / masaüstü 1440px görünümleri Flutter ekran görüntüleriyle karşılaştırıldı
- [ ] `prefers-reduced-motion` destekleniyor
- [ ] Ikon-only mobil butonlarda aria-label var; Lighthouse SEO/erişilebilirlik eşiği geçildi

---

## Ek A — Bilinen tutarsızlıklar / açık kararlar (özet)

1. **12 vs 20 kategori** — katalog metni "12" diyor, liste 20 elemanlı (§2.9 uyarısı). Ürün kararı.
2. **Palet farkı** — Flutter AppColors (#147DFF ailesi) vs public_web globals.css (#38A0E4 ailesi) (§6.1 uyarısı). Öneri: landing-scope token seti.
3. **Mockup-sohbet overlay'i** — gerçek sohbet motoru Flutter'da; port kapsamı belirsiz (§3, §7). v1'de FAB'a farklı davranış bağlama önerisi yapıldı.
4. **App hedef URL'leri** — `Vitrinleri Keşfet`, `Giriş Yap`, `Kayıtlı Vitrinimi Düzenle`, editor butonlarının Next.js'ten Flutter app'e kesin adresleri belirlenmeli (§3).
5. **Setup input ön eki** — kendi domainindeyken `vixrex-public.vercel.app/v/` metni UX açısından sorgulanabilir; kurallar gereği harfiyen korunmalı (§2.2 notu).
6. **`/terms` rotası** — public_web'de var mı teyit edilmeli (§2.11).
7. **Kategori key kapsama** — UI'daki 20 key'in DB `category_key` uzayıyla örtüşmesi teyit edilmeli; eksikse o kartlar fallback'e düşer (§5.3).
8. **RLS anon SELECT** — `category_image_templates` tablosunda anon okuma izni teyidi (§4).
9. **Outfit fontunun public_web layout'unda yüklü olması** teyit edilmeli (§6.2).

*Envanter sonu. Bu doküman #344 uygulamasının tek kaynak içeriğidir; eksik bulunan satır buraya işlenmelidir.*

# VIXREX WEB + MOBİL TAMLIK RAPORU

**Tarih:** 27 Ağustos 2026
**Yazan:** Freebuff (Buffy)
**Amaç:** Vixrex'in web + mobil birlikte çalışan tek ürün olarak tasarlanması gerekirken mevcut repository'de hangi parçaların tamamen Flutter'a sıkıştığı, yalnız Next.js tarafında kaldığı, yarım yapıldığı veya gereksiz tekrarlandığını kanıta dayalı olarak ortaya çıkarmak.

---

## 1. Tek Cümlelik Gerçek Durum

> Vixrex bugün **tam web + mobil uygulama değildir**; Flutter ağırlıklı bir yönetim paneli (mobil + web) ve Next.js tarafında **kısmi web uygulaması** (public vitrin + sahip asistan paneli) bulunmaktadır. İki platform ortak Supabase verisine bağlanır ama **aynı kullanıcı deneyimini sunmaz** — Flutter tüm CRUD'u yaparken, web yalnızca vitrin gösterimi ve sınırlı alan düzenlemesi sunar.

---

## 2. Gerçek Mimari

```text
                    ┌─────────────────────────────────┐
                    │         SUPABASE (PostgreSQL)    │
                    │  stores, products, appointments  │
                    │  store_articles, bookings, etc.  │
                    │  + RPC fonksiyonları (20+)       │
                    │  + Storage (shelf-images)         │
                    └──────────┬──────────────────────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
     ┌────────▼────────┐ ┌────▼─────────┐ ┌────▼──────────┐
     │   FLUTTER        │ │   NEXT.JS    │ │   SUPABASE    │
     │   (lib/)         │ │ (public_web/) │ │   Edge Funcs  │
     │                  │ │              │ │               │
     │ Mobil: APK       │ │ Public web:  │ │ 3 edge func:  │
     │ Web: vixrex-app  │ │ vixrex-public│ │ - send-booking│
     │                  │ │              │ │ - verify-ownership│
     │ yetkisi:         │ │ yetkisi:     │ │ - assistant-nlu│
     │ - Auth (Supabase │ │ - Public     │               │
     │   Auth SDK)      │ │   vitrin    │ └───────────────┘
     │ - Store CRUD     │ │ - Public    │
     │ - Product CRUD   │ │   ürün      │
     │ - Blog CRUD      │ │ - Owner     │
     │ - Booking管理     │ │   asistan   │
     │ - Keşfet (okuma) │ │   (sınırli) │
     │ - OCR/Excel      │ │ - Keşfet    │
     │ - Premium         │ │ - SEO       │
     │ - Push bildirim  │ │ - Sitemap   │
     │ - Admin panel    │ │ - Blog      │
     │                  │ │   gösterimi │
     │ modu:            │ │             │
     │ - Web: admin     │ │ modu:       │
     │   panel (noindex)│ │ - Public    │
     │ - Mobil: tam     │ │ - Owner     │
     │   yönetim        │ │   asistan   │
     └──────────────────┘ └─────────────┘
```

---

## 3. Özellik Matrisi

| Özellik | Flutter | Next.js Web | Ortak Backend | Senkron mu? | Durum |
|---------|---------|-------------|---------------|-------------|-------|
| **Kayıt/Login** | TAM (Supabase Auth) | YOK (owner session cookie) | Supabase Auth | KISMİ | Flutter Supabase Auth, web HMAC cookie |
| **Logout** | TAM | YOK | Supabase Auth | YOK | Web'de çıkış mekanizması yok |
| **Session** | TAM (Supabase) | KISMİ (HMAC cookie, 30dk) | Supabase + HMAC | KISMİ | Farklı mekanizmalar |
| **Profil** | TAM | YOK | Supabase | YOK | Web'de profil yönetimi yok |
| **İşletme/Vitrin Oluşturma** | TAM | YOK (kirala ile dolaylı) | Supabase | KISMİ | Web'de doğrudan oluşturma yok |
| **Vitrin Düzenleme** | TAM (tüm alanlar) | KISMİ (sahip asistan paneli, 40 alan) | Supabase + RPC | KISMİ | Flutter tam, web 40 alan |
| **Vitrin Silme** | TAM | KISMİ (API var) | Supabase | EVET | İkisi de silebilir |
| **Draft** | TAM (yerel + Supabase) | TAM (working_draft tablosu) | Supabase | EVET | Ortak working_draft |
| **Publish** | TAM | TAM (publish_working_draft RPC) | Supabase | EVET | Aynı RPC |
| **Unpublish** | TAM | YOK | Supabase | KISMİ | Web'de kaldırma yok |
| **Ürün Ekleme** | TAM (ürün CRUD) | YOK | Supabase (products tablosu) | YOK | Web'de ürün ekleme yok |
| **Ürün Düzenleme** | TAM | YOK | Supabase | YOK | Web'de ürün düzenleme yok |
| **Ürün Silme** | TAM | YOK | Supabase | YOK | Web'de ürün silme yok |
| **Ürün Listeleme** | TAM | TAM (public vitrin) | Supabase | EVET | İkisi de okuyabilir |
| **Kategori** | TAM (yönetim) | KISMİ (gösterim) | Supabase | KISMİ | Flutter yönetir, web gösterir |
| **Görsel Yükleme** | TAM (shelf-images bucket) | KISMİ (owner-upload API) | Supabase Storage | KISMİ | İkisi de yükleyebilir |
| **Stok** | TAM | YOK | Supabase | YOK | Web'de stok yönetimi yok |
| **Fiyat** | TAM | KISMİ (gösterim) | Supabase | KISMİ | Flutter yönetir |
| **Katalog** | TAM (ürün kataloğu) | YOK | Supabase | YOK | Web'de katalog yönetimi yok |
| **QR** | TAM (oluştur + göster) | TAM (gösterim) | qrserver.com API | EVET | İkisi de QR gösterebilir |
| **Paylaşım** | TAM (share_plus) | KISMİ (link kopyalama) | - | KISMİ | Flutter'da paylaşım zengin |
| **WhatsApp** | TAM (dış bağlantı) | TAM (dış bağlantı) | - | EVET | İkisi de wa.me'ye bağlanır |
| **Keşfet** | TAM (Flutter) | TAM (Next.js /kesfet) | Supabase | EVET | İkisi de listeleyebilir |
| **Arama** | YOK | YOK | - | YOK | Arama mevcut değil |
| **Public Vitrin** | YOK (redirect) | TAM (SSR, SEO) | Supabase | EVET | Web tek kaynak |
| **Public Ürün** | YOK (redirect) | TAM (SSR, SEO) | Supabase | EVET | Web tek kaynak |
| **SEO** | YOK (noindex) | TAM (metadata, sitemap, JSON-LD) | - | N/A | Web tek SEO yüzeyi |
| **Owner Yönetim** | TAM (Flutter panel) | KISMİ (asistan paneli, 40 alan) | Supabase + RPC | KISMİ | Flutter tam, web sınırlı |
| **Admin** | TAM (blog moderation) | YOK | Supabase | YOK | Web'de admin yok |
| **Blog Yazma** | TAM | YOK | Supabase | YOK | Web'de blog yazma yok |
| **Blog Gösterim** | YOK (redirect) | TAM (SSR) | Supabase | EVET | Web tek kaynak |
| **Randevu Oluşturma** | YOK (redirect) | TAM (create-booking API) | Supabase RPC | EVET | Web tek kaynak |
| **Randevu Yönetimi** | TAM | YOK | Supabase | YOK | Web'de randevu yönetimi yok |
| **Premium/Ödeme** | KISMİ (iskelet) | KISMİ (PayTR entegrasyonu) | Supabase + PayTR | KISMİ | Yarım |
| **OCR** | TAM | YOK | Supabase | N/A | Yalnız mobil |
| **Excel Yükleme** | TAM | YOK | Supabase | N/A | Yalnız mobil |
| **Push Bildirim** | TAM (OneSignal) | YOK | OneSignal | N/A | Yalnız mobil |
| **Instagram Senkron** | KISMİ (kapalı) | KISMİ (API var) | Supabase + Instagram | KISMİ | İkisi de yarım |

---

## 4. Flutter'a Sıkışmış Kritik Özellikler

### 1. Ürün CRUD (ekleme/düzenleme/silme/sıralama)

- **Flutter dosyası:** `lib/controllers/product_controller.dart`, `lib/repositories/supabase_product_repository.dart`
- **Flutter'daki gerçek işlem:** `create_store_product_v2`, `update_store_product`, `delete_store_product`, `reorder_store_products` RPC'leri
- **Web karşılığı:** YOK — `public_web/src/app/v/[slug]/page.tsx` yalnızca okuyor
- **Durum:** YALNIZ FLUTTER — ürün yönetimi web'den yapılamıyor

### 2. Blog Yazma/Yayınlama

- **Flutter dosyası:** `lib/screens/blog_editor_screen.dart`, `lib/controllers/blog_editor_controller.dart`
- **Flutter'daki gerçek işlem:** `store_articles` tablosuna INSERT/UPDATE
- **Web karşılığı:** YOK — web yalnızca published blogları gösteriyor
- **Durum:** YALNIZ FLUTTER — blog yazmak için Flutter gerekli

### 3. Admin Panel (Blog Moderasyon)

- **Flutter dosyası:** `lib/screens/blog_moderation_screen.dart`, `lib/screens/home_shell_screen.dart` (admin tab)
- **Flutter'daki gerçek işlem:** `approve_store_article`, `reject_store_article` RPC'leri
- **Web karşılığı:** YOK
- **Durum:** YALNIZ FLUTTER — admin işleri mobilde

### 4. Randevu Yönetimi (onay/red/iptal/değişiklik)

- **Flutter dosyası:** `lib/screens/booking_management_screen.dart`, `lib/controllers/booking_management_controller.dart`
- **Flutter'daki gerçek işlem:** `respond_to_appointment` RPC'si
- **Web karşılığı:** YOK — web yalnızca randevu OLUŞTURUYOR
- **Durum:** YALNIZ FLUTTER — randevu yönetimi mobilde

### 5. OCR/Excel Toplu Ürün Yükleme

- **Flutter dosyası:** `lib/screens/ocr_scanner_screen.dart`, `lib/screens/bulk_product_upload_screen.dart`
- **Durum:** YALNIZ MOBİL — phone-specific özellik

### 6. Push Bildirim (OneSignal)

- **Flutter dosyası:** `lib/services/push_notification_service.dart`
- **Durum:** YALNIZ MOBİL — native push

### 7. Premium/Ödeme Yönetimi

- **Flutter dosyası:** `lib/services/premium_service.dart` (iskelet)
- **Durum:** KISMİ — her iki tarafta da yarım

---

## 5. Web'e Sıkışmış Kritik Özellikler

### 1. Public Vitrin Görüntüleme (SEO)

- **Web dosyası:** `public_web/src/app/v/[slug]/page.tsx`
- **Durum:** TAM — SSR, JSON-LD, OpenGraph, canonical
- **Flutter karşılığı:** Redirect (noindex)

### 2. Public Ürün Sayfası (SEO)

- **Web dosyası:** `public_web/src/app/v/[slug]/urun/[productSlug]/page.tsx`
- **Durum:** TAM — Product JSON-LD

### 3. Keşfet Sayfası (SEO)

- **Web dosyası:** `public_web/src/app/(site)/kesfet/page.tsx`
- **Durum:** TAM — SSR, kategori filtresi

### 4. Sahip Asistan Paneli (Vixrex Asistan)

- **Web dosyası:** `public_web/src/app/v/[slug]/OwnerAssistantPanel.tsx`, `OwnerWorkspaceShell.tsx`
- **Durum:** KISMİ — 40 alan düzenlenebilir, tamamı değil
- **Flutter karşılığı:** TAM (tüm alanlar)

### 5. Sitemap/Robots

- **Web dosyası:** `public_web/src/app/sitemap.xml/route.ts`, `robots.txt/route.ts`
- **Durum:** TAM

### 6. Randevu Oluşturma (Müşteri)

- **Web dosyası:** `public_web/src/app/v/[slug]/randevu/`, `api/create-booking/route.ts`
- **Durum:** TAM — müşteri randevu alabilir

### 7. Yasal Onay (Web Üzerinden)

- **Web dosyası:** `public_web/src/app/api/owner-accept-legal/route.ts`
- **Durum:** TAM — sahip panelinden yasal onay verilebilir

---

## 6. Yarım Bırakılmış Web + Mobil Akışlar

### 1. ZİNCİR KOPUK: Kayıt → Vitrin Oluşturma

```
Web'de kayıt: YOK (Flutter Auth SDK gerektirir)
Flutter'da kayıt: TAM (anonim + kalıcı hesap)
Vitrin oluşturma: YALNIZ FLUTTER
```

**Durum:** Web'den vitrin oluşturulamıyor. Flutter zorunlu.

### 2. ZİNCİR KOPUK: Web'de Ürün Yönetimi

```
Flutter: ürün ekle → Supabase products tablosu
Web: ürün展示i var ama ekleme/düzenleme/silme YOK
```

**Durum:** Web'de ürün yönetimi tamamen eksik.

### 3. ZİNCİR KOPUK: Web'de Blog Yönetimi

```
Flutter: blog yaz → Supabase store_articles tablosu
Web: blog gösterimi var ama yazma YOK
```

**Durum:** Blog yazmak için Flutter gerekli.

### 4. KISMİ: Vitrin Düzenleme

```
Flutter: tüm alanlar (40+) → Supabase stores tablosu
Web: yalnızca 40 alan (asistan paneli) → update_working_draft_field RPC
```

**Durum:** Flutter tam, web sınırlı. Ama web tarafı artıyor (asistan paneli genişletiliyor).

### 5. KISMİ: Görsel Yükleme

```
Flutter: shelf-images bucket → doğrudan Supabase Storage
Web: /api/owner-upload → service-role ile Supabase Storage
```

**Durum:** İkisi de yükleyebilir ama farklı yollarla.

---

## 7. Veri Senkronizasyonu Hükmü

**KISMİ SENKRON**

**Kanıt:**
- **Ortak veri kaynağı:** Her iki taraf da aynı `stores`, `products`, `store_articles`, `appointments` tablolarına bağlı
- **Ortak draft mekanizması:** `working_draft` tablosu + `update_working_draft_field` RPC — hem Flutter hem web kullanıyor
- **Ortak publish mekanizması:** `publish_working_draft` RPC — hem Flutter hem web kullanıyor
- **Senkron olmayan alanlar:**
  - Flutter'da yapılan ürün ekleme/düzenleme → web'de products tablosundan okunuyor (senkron)
  - Web'de yapılan alan güncellemeleri → draft'a yazılıyor, publish sonrası canlıya geçiyor (senkron)
  - Flutter'daki blog/admin/booking yönetimi → web'de karşılığı yok (tek yön)
  - Web'deki asistan paneli → Flutter'da karşılığı yok (tek yön)

---

## 8. Auth ve Ownership Hükmü

**KISMİ ORTAK**

**Kanıt:**
- **Flutter auth:** Supabase Auth SDK (`signInWithPassword`, `signInWithIdToken`, anonim) → `auth.users` tablosu
- **Web auth:** HMAC imzalı HttpOnly cookie (`vixrex_owner_session`) → `owner_sessions` tablosu
- **Ortak nokta:** İkisi de `user_id` üzerinden sahipliği doğruluyor
- **Fark:** Flutter'da Supabase Auth session var, web'de yok. Web'de owner session 30 dakika yaşıyor, Flutter'da kalıcı.
- **Aynı kullanıcı:** Flutter'da kalıcı hesapla giriş yapan kullanıcı, web'de owner session cookie ile aynı vitrini düzenleyebilir (ama farklı mekanizmayla)

---

## 9. Veri Modeli Karşılaştırması

### Store/Vitrin

- **Supabase:** `stores` tablosu (JSONB alanlar: products, gallery_items, offerings, marketplace_links)
- **Flutter:** `StoreData` modeli (birebir eşleşme)
- **Next.js:** `PublicStoreRow` interface (birebir eşleşme)
- **Fark:** Yok — aynı tablo, aynı alanlar

### Product

- **Supabase:** `products` tablosu (yeni v2)
- **Flutter:** `Product` modeli
- **Next.js:** `ProductRow` interface
- **Fark:** Flutter hem JSONB (v1) hem products (v2) kullanıyor; web yalnızca products (v2)

### Category

- **Supabase:** `product_categories` tablosu
- **Flutter:** `ProductCategory` modeli
- **Next.js:** `CategoryRow` interface
- **Fark:** Yok

---

## 10. Draft/Publish Mimarisi

```
FLUTTER:
StoreEditorController
  → updateField() → save_store_draft_with_token RPC
  → publish() → publish_working_draft RPC
  → openOwnerPreview() → HMAC cookie → /api/owner-session

NEXT.JS:
OwnerAssistantPanel
  → /api/owner-draft → update_working_draft_field RPC
  → /api/owner-publish → publish_working_draft RPC
  → working_draft tablosu (ortak)

SUPABASE:
working_draft tablosu
  → draft_data JSONB
  → draft_version, live_version
  → version_conflict kontrolü
```

**Publish durumu:** Tek kaynaktan — `stores.is_published` kolonu. Hem Flutter hem web aynı RPC'yi kullanıyor.

---

## 11. Public Web'in Gerçek Durumu

**Sınıf: B — Public Web + Kısmi Yönetim**

**Kanıt:**
- ❌ Kullanıcı login olabilir mi? **HAYIR** (Supabase Auth login'i yok)
- ❌ Vitrin oluşturabilir mi? **HAYIR** (yalnızca kirala ile dolaylı)
- ❌ Ürün ekleyebilir mi? **HAYIR**
- ⚠️ Vitrin düzenleyebilir mi? **KISMİ** (sahip asistan paneli, 40 alan)
- ❌ Ürün düzenleyebilir mi? **HAYIR**
- ✅ Publish yapabilir mi? **EVET** (asistan panelinden)
- ❌ Hesabını yönetebilir mi? **HAYIR**
- ⚠️ Flutter'a gitmeden temel işletme yönetimini tamamlayabilir mi? **KISMİ** (yalnızca vitrin alanı düzenleme)

---

## 12. Flutter'ın Gerçek Durumu

**Sınıf: C — Monolitik Flutter (Web + Mobil + Admin)**

**Kanıt:**
- Flutter hem mobil (APK) hem web (vixrex-app.vercel.app) çalışır
- Web'de public vitrin gösterimi yapmaz (redirect)
- Admin paneli, blog yönetimi, randevu yönetimi — hepsi Flutter'da
- OCR, Excel, push bildirim — yalnız mobilde
- Flutter Web: `/app` rotasında admin paneli (noindex)
- Flutter landing'i web'de var ama noindex

---

## 13. Eksik Köprüler

### 1. Eksik Köprü: Web'de Auth

- **Kanıt:** Next.js'te Supabase Auth login formu yok
- **Kullanıcı etkisi:** Web'den giriş yapılamıyor, yeni vitrin oluşturulamıyor
- **Teknik etkisi:** Web yalnızca mevcut vitrinleri gösterebilir/yetkili erişim yapabilir
- **Öncelik:** P0

### 2. Eksik Köprü: Web'de Ürün CRUD

- **Kanıt:** `public_web/src/app/v/[slug]/page.tsx` yalnızca okuyor; ürün ekleme/düzenleme API'si yok
- **Kullanıcı etkisi:** Ürün eklemek/düzenlemek için Flutter'a geçmek zorunda
- **Teknik etkisi:** Web yarım vitrin yönetim paneli
- **Öncelik:** P0

### 3. Eksik Köprü: Web'de Blog Yazma

- **Kanıt:** Blog yazma API'si yok; yalnızca okuma var
- **Kullanıcı etkisi:** Blog yazmak için Flutter gerekli
- **Öncelik:** P1

### 4. Eksik Köprü: Web'de Randevu Yönetimi

- **Kanıt:** `/api/create-booking` var ama randevu yönetimi (onay/red) yok
- **Kullanıcı etkisi:** Randevu yönetimi için Flutter gerekli
- **Öncelik:** P1

### 5. Eksik Köprü: Web'de Profil/Ayarlar

- **Kanıt:** Profil yönetim sayfası yok
- **Kullanıcı etkisi:** Hesap bilgilerini değiştiremez
- **Öncelik:** P1

### 6. Eksik Köprü: Web'de Vitrin Oluşturma

- **Kanıt:** Yalnızca `rent-demo` ile kiralama var; sıfırdan oluşturma yok
- **Kullanıcı etkisi:** Yeni vitrin için Flutter gerekli
- **Öncelik:** P1

### 7. Eksik Köprü: Flutter Web'de Public Vitrin Redirect

- **Kanıt:** `vercel.json` redirect: `/v/:path*` → `vixrex-public.vercel.app`
- **Kullanıcı etkisi:** Flutter web'den vitrin bağlantısına tıklandığında yeni sekme açılır
- **Öncelik:** P2 (beklenen davranış)

---

## 14. Platform Sorumluluk Tablosu (Bugün Gerçekten Olan)

| Sorumluluk | Flutter | Next.js | Supabase |
|------------|---------|---------|----------|
| Auth | ✅ Supabase Auth | ❌ HMAC cookie | ✅ Auth + sessions |
| Onboarding | ✅ Sohbet tabanlı | ❌ | ❌ |
| Vitrin CRUD | ✅ Tam | ⚠️ Sınırlı (asistan) | ✅ stores + draft |
| Ürün CRUD | ✅ Tam | ❌ | ✅ products |
| Medya | ✅ Upload +管理 | ⚠️ Sınırlı (owner-upload) | ✅ Storage |
| Draft | ✅ Yerel + Supabase | ✅ working_draft | ✅ working_draft |
| Publish | ✅ publish_working_draft | ✅ publish_working_draft | ✅ RPC |
| Public Vitrin | ❌ Redirect | ✅ SSR + SEO | ✅ stores |
| Public Ürün | ❌ Redirect | ✅ SSR + SEO | ✅ products |
| SEO | ❌ noindex | ✅ Tam | ❌ |
| Sitemap | ❌ Redirect | ✅ Dinamik | ❌ |
| Keşfet | ✅ Flutter | ✅ Next.js | ✅ stores |
| QR | ✅ Oluştur + göster | ✅ Gösterim | ❌ |
| Paylaşım | ✅ share_plus | ⚠️ Link kopyala | ❌ |
| WhatsApp | ✅ Dış bağlantı | ✅ Dış bağlantı | ❌ |
| Admin | ✅ Blog moderasyon | ❌ | ✅ admins tablosu |
| Blog Yazma | ✅ | ❌ | ✅ store_articles |
| Blog Gösterim | ❌ Redirect | ✅ SSR | ✅ store_articles |
| Randevu Oluşturma | ❌ Redirect | ✅ create-booking | ✅ RPC |
| Randevu Yönetimi | ✅ | ❌ | ✅ respond_to_appointment |
| Premium | ⚠️ İskelet | ⚠️ PayTR | ⚠️ Schema var |
| OCR | ✅ | ❌ | ❌ |
| Excel | ✅ | ❌ | ❌ |
| Push Bildirim | ✅ OneSignal | ❌ | ❌ |
| Instagram | ⚠️ Kapalı | ⚠️ API var | ✅ connections |

---

## 15. 6 Senaryo Sonucu

### Senaryo 1: Web'den kayıt → vitrin oluştur → ürün ekle → yayınla

- **Başlangıç:** Web'de Supabase Auth login formu
- **Adım 1:** Kayıt ol → Supabase Auth user
- **Adım 2:** Vitrin oluştur → stores tablosu
- **Adım 3:** Ürün ekle → products tablosu
- **Adım 4:** Yayınla → publish_working_draft RPC
- **Sonuç:** KOPUK — Web'de kayıt/vitrin oluşturma/ürün ekleme yok

### Senaryo 2: Aynı kullanıcı mobil uygulamaya gir → web'de oluşturduğu vitrini yönet

- **Başlangıç:** Flutter'da kalıcı hesap
- **Adım 1:** Flutter'da vitrin oluştur → stores tablosu
- **Adım 2:** Web'de owner session ile giriş yap
- **Adım 3:** Asistan paneli ile sınırlı düzenleme
- **Sonuç:** KISMİ — Flutter'da vitrin oluşturulup yayınlanırsa, web'de asistan paneli ile sınırlı düzenleme yapılabilir

### Senaryo 3: Mobilde ürün ekle → public web ürün sayfasında görün

- **Başlangıç:** Flutter'da ürün ekleme
- **Adım 1:** ProductController.addProduct() → products tablosu
- **Adım 2:** Web'de /v/[slug]/urun/[productSlug] sayfası okunur
- **Sonuç:** TAM — Flutter ürün ekler → products tablosu → web'de ürün sayfası okunur

### Senaryo 4: Web'de ürün değiştir → mobilde güncel hali görün

- **Başlangıç:** Web'de ürün değiştirme
- **Adım 1:** Web'de ürün değiştirme API'si
- **Sonuç:** KOPUK — Web'de ürün değiştirme yok

### Senaryo 5: Mobilde vitrin yayınla → public SEO sayfası doğru şekilde yayınlansın

- **Başlangıç:** Flutter'da publish
- **Adım 1:** publish_working_draft RPC → stores.is_published=true
- **Adım 2:** Web'de /v/[slug] sayfası SSR ile gösterilir
- **Sonuç:** TAM — Flutter publish → stores.is_published=true → web'de SEO ile gösterilir

### Senaryo 6: Public sayfadan işletme sahibinin yönetim alanına geçiş yapılabilsin

- **Başlangıç:** Public vitrin sayfası
- **Adım 1:** "Düzenle" butonuna tıkla
- **Adım 2:** Owner session cookie oluşturulur
- **Adım 3:** Asistan paneli açılır
- **Sonuç:** TAM — Public vitrinde "Düzenle" butonu → owner session → asistan paneli

---

## 16. En Kritik 10 Eksik

1. **Web'de auth (giriş/kayıt)** — Yeni kullanıcılar web'den başlayamıyor
2. **Web'de ürün CRUD** — Ürün eklemek/düzenlemek için Flutter zorunlu
3. **Web'de vitrin oluşturma** — Sıfırdan vitrin web'den yapılamıyor
4. **Web'de blog yazma** — Blog yazmak için Flutter zorunlu
5. **Web'de randevu yönetimi** — Randevu onay/red için Flutter zorunlu
6. **Web'de profil yönetimi** — Hesap bilgileri değiştirilemiyor
7. **Web'de vitrin silme/unpublish** — Yalnızca Flutter'dan
8. **Flutter Web'de public vitrin** — noindex + redirect (beklenen davranış)
9. **Premium/ödeme** — Her iki tarafta da yarım
10. **Arama** — Hiçbir tarafta yok

---

## 17. Platform Tamlık Oranları

### Flutter

**%75** — Tüm CRUD, admin, blog, randevu yönetimi, OCR, premium mevcut ama public vitrin gösterimi ve SEO yok.

### Web

**%35** — Public vitrin (SEO), keşfet, randevu oluşturma, sahip asistan paneli (kısıtlı) mevcut ama auth, ürün CRUD, vitrin oluşturma, blog yazma, randevu yönetimi eksik.

### Ortak Backend/Senkronizasyon

**%60** — Ortak Supabase verisi, draft/publish mekanizması, keşfet senkron ama auth farklı, ürün yönetimi tek yönlü, blog/admin tek yönlü.

---

## 18. Mevcut Kodu Bozmadan Tamamlama Sırası

### P0 — Ürünü iki platformda tutarsız hale getiren

1. Web'de auth mekanizması (Supabase Auth → Next.js entegrasyonu)
2. Web'de ürün CRUD API'leri (create, update, delete endpoint'leri)

### P1 — Web + mobil ürününü tamamlamayı engelleyen

3. Web'de vitrin oluşturma akışı
4. Web'de blog yazma API'si
5. Web'de randevu yönetimi API'si
6. Web'de profil/ayarlar sayfası

### P2 — Mimari borç

7. Flutter'daki admin panelinin web'e taşınması (blog moderasyon)
8. Flutter Web'deki landing sayfasının kaldırılması (zaten redirect var)
9. Premium/ödeme akışının tamamlanması (her iki tarafta)

### P3 — Temizlik

10. Legacy Flutter landing dosyalarının temizlenmesi
11. Kullanılmayan service dosyalarının kontrol edilmesi

---

## Kaynaklar

- `AGENTS.md` — Proje kuralları
- `VIXREX_RULES.md` — Ürün/güvenlik sınırları
- `CONTEXT.md` — Teknik/ürün durumu
- `docs/seo-mimari-plani.md` — SEO planı
- `docs/google-gorunurluk.md` — Google görünürlüğü
- `docs/agents/repository-guide.md` — Teknik depo haritası
- `docs/agents/store-editor-controller-parcalama.md` — Controller parçalama durumu
- Kod kanıtları: `lib/`, `public_web/`, `supabase/` dizinlerindeki dosyalar

# VixRex SEO Mimari Planı

**Tarih:** 2026-08-26
**Hedef:** Google görünürlüğünü sağla, mevcut uygulamayı bozma, web+ mobil eşitliğini kur.
**Tek kaynak:** Supabase (PostgreSQL)

---

## 1. Mevcut Durum Özeti

| Yüzey | Teknoloji | Google Görebilir mi? | SEO Uygun mu? |
|---|---|---|---|
| Flutter Web (vixrex-app.vercel.app) | Flutter SPA | ❌ (noindex + JS) | ❌ |
| Next.js Public (vixrex-public.vercel.app) | Next.js SSR | ✅ | ✅ (partial) |
| Flutter Mobil (APK) | Flutter Native | N/A (App Store) | N/A |

### Kritik Eksikler
1. **Google'da 0 index** — Hiçbir sayfa indexlenmemiş
2. **Next.js'te /landing yok** — Ana sayfa Flutter'a redirect ediyor
3. **Next.js'te /kesfet yok** — Keşfet sayfası sadece Flutter'da var
4. **Flutter landing Google'da görünmüyor** — noindex + SPA
5. **Sitemap'i Google'a bildirmemiş olabiliriz**

### Korunacak Mevcut Özellikler
- ✅ Flutter mobil uygulama (aynen devam)
- ✅ Flutter web admin paneli (Vitrinim, Asistan, Profil)
- ✅ Next.js vitrin sayfaları (/v/:slug)
- ✅ Next.js ürün sayfaları (/v/:slug/urun/:slug)
- ✅ Next.js blog sayfaları (/v/:slug/yazilar)
- ✅ Next.js rent-demo (/rent-demo)
- ✅ Next.js OwnerAssistantPanel (sahip paneli)
- ✅ Supabase tek kaynak
- ✅ Flutter'daki keşfet + kirala butonu (Next.js'e açılır)
- ✅ Flutter'daki Vixrex Asistan (ilk kurulum)

---

## 2. Mimari Hedef

```
┌──────────────────────────────────────────────────────┐
│  NEXT.JS (public_web) — Web Yüzeyi (SEO-uyumlu)      │
│                                                       │
│  / → Landing (Google indeksler) ← YENİ               │
│  /kesfet → Keşfet (Google indeksler) ← YENİ          │
│  /v/:slug → Vitrin sayfası ✅                         │
│  /v/:slug/urun/:slug → Ürün sayfası ✅                │
│  /v/:slug/yazilar → Blog ✅                           │
│  /rent-demo → Kirala akışı ✅                         │
│  /sitemap.xml → Google'a sitemap ✅                   │
│  /robots.txt → Robots config ✅                       │
│                                                       │
│  Tümü SSR → Google botu tam HTML görüyor ✅           │
└────────────────────────┬─────────────────────────────┘
                         │
                         ▼
           ┌──────────────────────┐
           │      SUPABASE        │  ← TEK KAYNAK
           │   (PostgreSQL + Auth)│
           └──────────────────────┘
                         ▲
                         │
┌────────────────────────┴─────────────────────────────┐
│  FLUTTER (lib/) — Mobil + Web Admin                   │
│                                                       │
│  MOBİL (APK):                                        │
│    /home → Keşfet ✅                                  │
│    /app → Vitrinim ✅                                 │
│    /vixrex → Asistan (ilk kurulum) ✅                  │
│    /profile → Profil ✅                               │
│    OCR, Excel, Push notification ✅                    │
│                                                       │
│  WEB (vixrex-app.vercel.app):                        │
│    /app → Admin paneli (noindex) ✅                    │
│    / → Landing → Next.js'e redirect ← DEĞİŞİKLİK    │
│    /kesfet → Next.js'e redirect ← DEĞİŞİKLİK         │
│    /v/:slug → Next.js'e redirect ✅ (zaten var)       │
│    /sitemap.xml → Next.js'e redirect ✅ (zaten var)   │
│    /robots.txt → Next.js'e redirect ✅ (zaten var)    │
└──────────────────────────────────────────────────────┘
```

---

## 3. Fazlar (Quarter bazında)

### Q1: Temel SEO Altyapısı (1-2 hafta)
**Hedef:** Google sayfalarımızı görsün ve indekslesin.

#### Faz 1.1: Google Search Console Kurulumu
- **Ne:** `vixrex-public.vercel.app`'i Google Search Console'a ekle
- **Neden:** Sitemap submit etmeden Google index almaz
- **Dosya değişikliği:** Yok (dashboard işlemi)
- **Test:** GSC'de sitemap submit et, "URL Deneme" ile bir /v/ sayfasını test et
- **Geri dönüş:** GSC'den domaini kaldır (eğer yanlış yapılırsa)
- **Risk:** SIFIR

#### Faz 1.2: Sitemap'i Güncelle — /kesfet URL'lerini Ekle
- **Ne:** `public_web/src/app/sitemap.xml/route.ts`'e vitrin listesi ekle
- **Neden:** Google'ın keşfet sayfasını bulması için
- **UX/UI:** Yok (backend değişikliği)
- **Dosyalar:**
  - `public_web/src/app/sitemap.xml/route.ts` → vitrin listesi ekle
- **Test:** `curl vixrex-public.vercel.app/sitemap.xml` ile yeni URL'leri doğrula
- **Geri dönüş:** Eski sitemap versiyonuna dön
- **Risk:** DÜŞÜK

#### Faz 1.3: Next.js Kök Sayfayı Düzelt
- **Ne:** `public_web/src/app/page.tsx`'teki redirect'i kaldır, gerçek landing sayfası yap
- **Neden:** Şu an `vixrex-public.vercel.app/` → `vixrex-app.vercel.app`'e gidiyor. Google landing'i göremiyor.
- **UX/UI:**
  - Basit, temiz bir landing: Hero + "Vitrin Oluştur" CTA + Nasıl Çalışır + Özellikler
  - Vixrex marka renkleri (dark theme: #0B1120, blue accents)
  - Mobil responsive
  - Logo, hero image, CTA butonları
- **Dosyalar:**
  - `public_web/src/app/page.tsx` → redirect'i kaldır, landing component yaz
  - `public_web/src/app/components/LandingHero.tsx` → YENİ
  - `public_web/src/app/components/LandingFeatures.tsx` → YENİ
  - `public_web/src/app/components/LandingCta.tsx` → YENİ
- **SEO:**
  - `generateMetadata`: title, description, OG image
  - JSON-LD: `WebSite` + `Organization`
  - Canonical: `https://vixrex-public.vercel.app/`
- **Test:**
  - `npm run build` başarılı mı?
  - `curl vixrex-public.vercel.app/` → tam HTML görüyor mu?
  - Google Rich Results Test → JSON-LD doğru mu?
  - Mobil responsive: 375px, 768px, 1024px
- **Geri dönüş:** Eski redirect'i geri koy (tek satır)
- **Risk:** DÜŞÜK

### Q2: Keşfet Sayfası (2-3 hafta)
**Hedef:** Google vitrinleri listeleyen bir sayfa görsün.

#### Faz 2.1: Next.js Keşfet Sayfası Oluştur
- **Ne:** `/kesfet` rotası — Supabase'den yayınlanmış vitrinleri grid olarak listeler
- **Neden:** Flutter'daki keşfet sadece SPA, Google göremiyor
- **UX/UI Tasarım Kararları:**
  - **Grid:** 2 sütun (mobil) → 3 sütun (tablet) → 4 sütun (masaüstü)
  - **Kart tasarımı:** Mevcut `VitrinStoreCard` ile aynı görsel dil (dark theme, blue accents)
  - **Her kart:** Logo, mağaza adı, kategori, konum, kapak görseli
  - **Filtreleme:** Kategori chip'leri (Flutter'daki ile aynı)
  - **Arama:** Üstte arama kutusu
  - **Kiralık şablon badge'i:** "Hazır Vitrin" rozeti
  - **Kirala butonu:** Kiralık vitrinlerde → /rent-demo'ya gider
  - **Skeleton loading:** Mevcut `AppSkeleton` ile aynı
  - **Empty state:** "Aramanızla eşleşen vitrin yok"
  - **Pagination:** Sonsuz kaydırma (infinite scroll) veya "Daha fazla yükle"
- **Dosyalar:**
  - `public_web/src/app/kesfet/page.tsx` → YENİ (ana sayfa)
  - `public_web/src/app/kesfet/StoreCard.tsx` → YENİ (kart bileşeni)
  - `public_web/src/app/kesfet/FilterBar.tsx` → YENİ (kategori filtreleri)
  - `public_web/src/app/kesfet/SearchBar.tsx` → YENİ (arama)
- **Veri akışı:**
  ```
  Supabase → stores WHERE is_published=true
  Supabase → products WHERE is_active=true AND is_visible=true (ürün sayısı için)
  Supabase → category_image_templates (kapak görselleri için)
  ```
- **SEO:**
  - `generateMetadata`: title="Vixrex'leri Keşfet | Dijital Vitrinler", description
  - `robots: { index: true, follow: true }`
  - Canonical: `https://vixrex-public.vercel.app/kesfet`
  - H1: "Vixrex'leri Keşfet"
  - Structured data: `ItemList` (vitrin listesi)
- **Test:**
  - `npm run build` başarılı mı?
  - `curl vixrex-public.vercel.app/kesfet` → tam HTML görüyor mu?
  - Tüm vitrinler listeleniyor mu?
  - Kategori filtreleri çalışıyor mu?
  - Arama çalışıyor mu?
  - Kirala butonu → /rent-demo'ya yönlendiriyor mu?
  - Mobil responsive: 375px, 768px, 1024px
  - Lighthouse SEO skoru: 90+
  - Google Rich Results Test
- **Geri dönüş:** Dosyayı sil, veritabanında hiçbir değişiklik yok
- **Risk:** DÜŞÜK (sadece yeni dosya, mevcut hiçbir şeyi bozmaz)

#### Faz 2.2: Sitemap'i /kesfet ile Güncelle
- **Ne:** Sitemap'e `/kesfet` URL'sini ekle
- **Dosya:** `public_web/src/app/sitemap.xml/route.ts`
- **Test:** `curl sitemap.xml` → `/kesfet` görünüyor mu?
- **Risk:** SIFIR

#### Faz 2.3: Flutter Web'den /kesfet'i Redirect Et
- **Ne:** `vercel.json`'a redirect ekle: `/kesfet` → `vixrex-public.vercel.app/kesfet`
- **Neden:** Flutter web'den keşfet'e gelenler Next.js'e yönlensin
- **Dosya:** `vercel.json`
- **Test:** `curl vixrex-app.vercel.app/kesfet` → Next.js'e redirect mi?
- **Risk:** DÜŞÜK (Flutter web'deki keşfet zaten Google tarafından göremiyor)

### Q3: Flutter Web Temizliği + Hata Düzeltmeleri (1-2 hafta)
**Hedef:** Flutter web'i sadece admin paneli olarak bırak, SEO hatalarını düzelt.

#### Faz 3.1: Flutter Web Landing Redirect
- **Ne:** `vercel.json`'a redirect ekle: `/` → `vixrex-public.vercel.app/`
- **Neden:** Flutter landing'i Google'a görünmüyor, Next.js landing'i var artık
- **Dosya:** `vercel.json`
- **Test:** `curl vixrex-app.vercel.app/` → Next.js landing'e redirect mi?
- **Risk:** ORTA — Flutter web'de landing artık direkt Next.js'e gider
  - **Koruma:** Flutter mobilde etkilenmez (APK'da landing yok)
  - **Koruma:** Flutter web admin paneli `/app` rotasında, etkilenmez

#### Faz 3.2: Ürün Fiyat Alanını Düzelt (SEO Hatası)
- **Ne:** `urun/[productSlug]/page.tsx`'teki `price` regex'ini düzelt
- **Neden:** "150-200 TL" → "150200" oluyor, Google geçersiz price görüyor
- **Dosya:** `public_web/src/app/v/[slug]/urun/[productSlug]/page.tsx`
- **UX/UI:** Yok (backend data transform)
- **Test:**
  - Aralık fiyat → doğru mu?
  - Türkçe fiyat → doğru mu?
  - Fiyat yoksa → undefined mi?
  - Google Rich Results Test → Product schema doğru mu?
- **Geri dönüş:** Eski regex'i geri koy
- **Risk:** DÜŞÜK

#### Faz 3.3: offers.seller'ı LocalBusiness'a Bağla
- **Ne:** Ürün JSON-LD'sinde `seller`'ı mağaza sayfasındaki `LocalBusiness`'a `@id` ile bağla
- **Neden:** İki schema düğümü şu an kopuk
- **Dosya:** `public_web/src/app/v/[slug]/urun/[productSlug]/page.tsx`
- **Test:** Google Rich Results Test → seller linkli mi?
- **Risk:** DÜŞÜK

### Q4: İleri SEO + Performans (2-3 hafta)
**Hedef:** Google sıralamasını iyileştir, Core Web Vitals'ı optimize et.

#### Faz 4.1: Keşfet Sayfası ISR/Cache
- **Ne:** Keşfet sayfasını `unstable_cache` ile önbellekle
- **Neden:** Her istekte Supabase sorgusu pahalı
- **Test:** İlk yükleme hızı < 2sn
- **Risk:** DÜŞÜK

#### Faz 4.2: OpenGraph Image Oluştur
- **Ne:** Vitrin sayfaları için dinamik OG image
- **Neden:** Sosyal paylaşım paylaşımlarında görsel görünmüyor
- **Dosya:** `public_web/src/app/v/[slug]/opengraph-image.tsx` → YENİ
- **Test:** Twitter Card Validator, Facebook Sharing Debugger
- **Risk:** DÜŞÜK

#### Faz 4.3: Canonical URL'leri Doğrula
- **Ne:** Tüm sayfalarda canonical URL'lerin doğru olduğundan emin ol
- **Test:** `curl -I` ile canonical header'ları kontrol et
- **Risk:** SIFIR

#### Faz 4.4: Core Web Vitals Optimizasyonu
- **Ne:** LCP, FID, CLS optimizasyonu
- **Dosyalar:**
  - Image optimization (next/image)
  - Font loading optimization
  - Critical CSS
- **Test:** PageSpeed Insights → 90+ skor
- **Risk:** DÜŞÜK

---

## 4. Korunacak Kritik Özellikler

### Flutter Mobil (APK) — Hiçbir Değişiklik Yok
- ✅ Landing ekranı → Aynen kalır (mobilde Google araması yok)
- ✅ Keşfet ekranı → Aynen kalır (mobilde SUPABASE'den veri çeker)
- ✅ Vitrinim paneli → Aynen kalır
- ✅ Vixrex Asistan → Aynen kalır (ilk kurulum)
- ✅ OCR, Excel → Aynen kalır
- ✅ Push notification → Aynen kalır
- ✅ Kirala butonu → Aynen kalır (Next.js'i dış tarayıcıda açar)

### Flutter Web — Sadece Admin Paneli
- ✅ `/app` → Vitrinim (noindex korunur)
- ✅ `/vixrex` → Asistan (noindex korunur)
- ✅ `/profile` → Profil (noindex korunur)
- 🔄 `/` → Next.js landing'e redirect (YENİ)
- 🔄 `/kesfet` → Next.js keşfet'e redirect (YENİ)

### Next.js — SEO Yüzeyi
- ✅ `/v/:slug` → Vitrin (SSR, JSON-LD, OpenGraph)
- ✅ `/v/:slug/urun/:slug` → Ürün (SSR, Product JSON-LD)
- ✅ `/v/:slug/yazilar` → Blog listesi (SSR)
- ✅ `/v/:slug/yazilar/:slug` → Blog yazısı (SSR, BlogPosting JSON-LD)
- ✅ `/rent-demo` → Kirala akışı (reCAPTCHA + POST)
- ✅ `/sitemap.xml` → Sitemap
- ✅ `/robots.txt` → Robots
- 🔄 `/` → Landing sayfası (YENİ — redirect kaldırılır)
- 🔄 `/kesfet` → Keşfet sayfası (YENİ)

---

## 5. UX/UI Tasarım İlkeleri

### Next.js Landing Sayfası
- **Tema:** Dark (#0B1120) — mevcut vitrin temasıyla uyumlu
- **Font:** Outfit — mevcut font ile aynı
- **Renk paleti:** Blue-600 (#2563EB) primary, slate-300 text
- **Hero:** Büyük başlık + açıklama + "Vitrin Oluştur" CTA
- **Nasıl Çalışır:** 3 adım (Kayıt → Oluştur → Yayınla)
- **Özellikler:** Grid layout, ikonlu kartlar
- **Footer:** Logo + linkler + KVKK
- **Responsive:** Mobil-first, 375px-1440px

### Next.js Keşfet Sayfası
- **Tema:** Dark — vitrin kartlarıyla uyumlu
- **Grid:** Responsive (2→3→4 sütun)
- **Kart:** Logo + ad + kategori + konum + kapak görseli
- **Filtreleme:** Kategori chip'leri (yatay scroll)
- **Arama:** Üstte sabit arama kutusu
- **Skeleton:** Yüklenirken iskelet görünümü
- **Empty state:** "Eşleşen vitrin yok"
- **Kiralık badge:** "Hazır Vitrin" rozeti
- **Kirala butonu:** Blue gradient, vitrin kartında

---

## 6. Doğrulama Kontrol Listesi

Her faz sonrası:
- [ ] `npm run build` başarılı mı?
- [ ] `flutter analyze` temiz mi?
- [ ] `flutter test` geçiyor mu?
- [ ] `npm run test` (vitest) geçiyor mu?
- [ ] `curl` ile SSR doğrulandı mı?
- [ ] Google Rich Results Test geçiyor mu?
- [ ] Mobil responsive doğrulandı mı?
- [ ] Mevcut rotalar kırıldı mı? (回归 test)
- [ ] Flutter web hâlâ çalışıyor mu?
- [ ] Next.js vitrin sayfaları hâlâ çalışıyor mu?

---

## 7. Rollback Planı

| Faz | Geri Alma | Süre |
|---|---|---|
| 1.1 GSC | GSC'den domaini kaldır | 1 dk |
| 1.2 Sitemap | Eski sitemap versiyonuna dön | 5 dk |
| 1.3 Landing | `page.tsx`'te redirect'i geri koy | 5 dk |
| 2.1 Keşfet | `kesfet/` klasörünü sil | 5 dk |
| 3.1 Redirect | `vercel.json`'dan redirect'i kaldır | 5 dk |
| 3.2 Price | Eski regex'i geri koy | 5 dk |
| 3.3 Seller | Eski JSON-LD'yi geri koy | 5 dk |

**Tüm geri almalar** — veritabanında değişiklik YOK, sadece kod değişikliği.
**Flutter mobil** — Hiçbir geri alma gerektirmez, etkilenmez.

---

## 8. Zaman Çizelgesi

| Hafta | Faz | Çıktı |
|---|---|---|
| 1 | 1.1 + 1.2 + 1.3 | GSC kuruldu, sitemap güncellendi, landing sayfası yayında |
| 2-3 | 2.1 + 2.2 + 2.3 | Keşfet sayfası yayında, redirect'ler çalışıyor |
| 4 | 3.1 + 3.2 + 3.3 | Flutter web temizlendi, SEO hataları düzeltildi |
| 5-6 | 4.1 + 4.2 + 4.3 + 4.4 | Performans optimize, OG image, canonical'lar |

---

## 9. Başarı Ölçütleri

- [ ] Google'da `site:vixrex-public.vercel.app` → en az 10 sonuç
- [ ] Keşfet sayfası Google tarafından indekslendi
- [ ] Landing sayfası Google tarafından indekslendi
- [ ] Vitrin sayfaları Google Rich Results gösteriyor
- [ ] Core Web Vitals: LCP < 2.5s, FID < 100ms, CLS < 0.1
- [ ] Lighthouse SEO: 90+
- [ ] Flutter mobil uygulama aynen çalışıyor (hiçbir bozulma yok)
- [ ] Flutter web admin paneli aynen çalışıyor
- [ ] Tüm mevcut Next.js sayfaları aynen çalışıyor

# Vibe Coding Master Skill: Ürün Kalitesi, Token Optimizasyonu ve E2E Test Uygunluğu

> **Versiyon:** 1.0  
> **Son Güncelleme:** 2026-07-10  
> **Kullanım:** Bu skill, vibe coding (AI-assisted development) ile mobil ve web uygulama geliştirirken karşılaşılan yaygın sorunları önlemek, token harcamalarını kontrol altında tutmak ve uygulamayı E2E testine uygun hale getirmek için kullanılır.  
> **Hedef Kitle:** Solo geliştiriciler, startup kurucuları, vibe coding ile MVP/demo geliştiren ekipler.

---

## 1. Vibe Coding Hatalarının Tespiti ve Önlenmesi

### 1.1 Yaygın Vibe Coding Hata Kalıpları

| Hata Kalıbı | Belirti | Önlem |
|-------------|---------|-------|
| **Context Collapse (Bağlam Çöküşü)** | AI önceki kararlara aykırı kod üretir, tutarsız desenler kullanır | Yeni session başlat, context dosyalarını (CLAUDE.md, .cursor/rules) yeniden yükle |
| **Scope Drift (Kapsam Sürüklenmesi)** | Her prompt ile yeni özellikler eklenir, MVP'ye ulaşılamaz | "Future Ideas" bölümü tut, her prompt'ta tek özellik odaklan |
| **Hallucinated API** | AI, var olmayan API metodları veya kütüphaneler önerir | Her bağımlılığı `npm info` veya resmi dokümantasyondan doğrula |
| **Security Blind Spots** | Input validation eksik, SQL injection, CORS `*` kullanımı | Her endpoint'te auth check, rate limiting, input validation zorunlu |
| **Over-engineering** | Basit sorunlara karmaşık çözümler üretilir | "Bana 3 yaklaşım ver: en basit, orta, full-featured" şeklinde promptla |
| **Inconsistent Styling** | Her prompt farklı kod stili üretir | Baştan `.cursor/rules` veya `CLAUDE.md` ile stil kılavuzu tanımla |
| **Forgotten Edge Cases** | Kod ideal koşullarda çalışır, boş data veya hata durumları unutulur | Her prompt'ta "error handling, empty states, loading states" ekle |
| **Context Rot (Bağlam Bozulması)** | Uzun sessionlarda AI performansı düşer, "lost in the middle" problemi | Context penceresini 100K token altında tut, compaction kullan |

### 1.2 Hata Tespit Kontrol Listesi (Her AI Interaction Sonrası)

```
□ Kod, önceki kararlara aykırı mı? (Consistency check)
□ Yeni bağımlılık eklendi mi? (Dependency audit)
□ Güvenlik açığı var mı? (Auth, validation, CORS)
□ Hata durumları ele alındı mı? (try-catch, null checks)
□ Performans sorunu var mı? (unnecessary re-renders, memory leaks)
□ Erişilebilirlik (accessibility) düşünüldü mü? (WCAG 2.2)
□ Kod tekrarı (DRY) var mı? (Refactoring check)
□ Context window büyüklüğü kontrol edildi mi? (Token usage check)
```

---

## 2. MVP/Demo Odaklı Geliştirme (Ürün Değil, MVP)
## 2.1 AI Session Yönetimi (Token Optimizasyonu)

- Context 80K token'a ulaşınca **YENİ SESSION** başlat
- Her session'da tek feature odaklan (max 5 dosya)
- Önce `VIXREX_OTURUM_OZETI.md` oku, sonra devam et
- Eski tool output'larını session'da tutma, `NOTES.md` özet dosyası kullan
- Claude Code: `/context` komutu ile token kullanımını izle, `/compact` ile alan aç
- **Kural**: Her session başında `VIXREX_OTURUM_OZETI.md` + ilgili max 5 dosya oku, gerisini session'a sokma

---

## 2.2 MVP Sınırı (Scope Drift Kontrolü)

- `PLAN.md` dosyasındaki "Faz 1" dışına çıkma
- Yeni fikir gelirse → `PLAN.md`'ye "Faz 2/Gelecek" bölümüne yaz, şimdi implemente ETME
- Her session başında: "Bugün sadece [X] özelliği. Başka önerme."
- AI'dan 3 yaklaşım iste: "Basit / Orta / Full-featured" → Hep **Basit**'i seç
- **Kural**: "Bu feature Faz 1'de mi?" sorusuna EVET cevabı yoksa, implemente ETME

---

## 2.3 Çapraz Platform Tutarlılık (Flutter + Next.js)

- **Aynı API contract**: Supabase RLS ve fonksiyonlar her iki platformda aynı çalışmalı
- **Aynı veri modeli**: `lib/models/` ve `src/types/` senkronize olmalı
- **UI kararları**: Bir platformda alınan UI kararı diğerine de yansıtılmalı
- **Auth flow**: Flutter'daki login/register akışı ile Next.js'teki aynı olmalı (passkey, magic link, vs.)
- **Değişiklik kuralı**: Değişiklik yaparken "Bu değişiklik diğer platformu etkiler mi?" sorusunu sor
- **Senkronizasyon**: Model değişikliği yapıldığında diğer platformdaki karşılığı da güncelle

---

## 2.4 Dependency ve API Doğrulama

- Yeni paket önerisi gelirse: `pub.dev` veya `npm` üzerinden varlığını kontrol et
- Supabase fonksiyonu önerilirse: Resmi dokümantasyondan doğrula
- Breaking change içeren paket güncellemesi → Önce changelog oku, sonra uygula
- `flutter pub deps` ve `npm audit` her hafta çalıştırılmalı
- **Yasak**: AI'ın önerdiği paketi doğrulamadan `pubspec.yaml` veya `package.json`'a ekleme
- **Kural**: Her yeni bağımlılık için `npm info [package]` veya `pub.dev/packages/[package]` kontrolü zorunlu

---

## 2.5 E2E Test Önceliği (Unit Test'ten Önce)

- **Kritik kullanıcı akışları** E2E ile test edilmeli:
  - İşletme kaydı → Vitrin oluşturma → Ürün ekleme → Public vitrin görüntüleme
  - Login → Dashboard → Ürün düzenleme → Değişikliğin public vitrinde görünmesi
- **Araçlar**: Flutter için **Patrol**, Next.js için **Playwright**
- Her PR'da E2E pipeline geçmeli (GitHub Actions)
- Unit test sadece: `Result<T>` utilities, validation, calculation
- **Kural**: E2E test olmadan feature merge edilmez
- **Kural**: Vibe-coded kodda internal yapıyı test etmek yerine kullanıcı perspektifinden test et

---

## 2.6 Vitrin UI Kalite Kontrolü

- **8pt grid** sistemi kullanılmalı (Flutter: `SizedBox(height: 8)`, Next.js: Tailwind spacing)
- **Loading states**: Skeleton > CircularProgressIndicator (Flutter), Skeleton > Spinner (Next.js)
- **Empty states**: "Henüz ürün eklenmemiş" gibi kullanıcı dostu mesajlar
- **Error states**: Teknik hata mesajı değil, "Bir sorun oluştu, tekrar dene" + retry butonu
- **Dark mode**: Her iki platformda aynı tema tokenları (`primary`, `surface`, `text-primary`)
- **Responsive**: Mobil vitrin (Flutter) ve web vitrin (Next.js) aynı bilgiyi farklı formatta göstermeli
- **Accessibility**: WCAG 2.2 AA minimum, ekran okuyucu testi yapılmalı
- **Kural**: Her screen'de loading + empty + error state olmalı

---

## 2.7 Hata Mesajı Standartları (Türkçe)

| Durum | Mesaj | Aksiyon |
|-------|-------|---------|
| Ağ hatası | "İnternet bağlantınızı kontrol edin" | Retry butonu |
| Auth hatası | "Giriş bilgileriniz hatalı, tekrar deneyin" | Login ekranına yönlendir |
| Veri bulunamadı | "Henüz içerik eklenmemiş" | Ekleme butonu göster |
| Sunucu hatası | "Bir sorun oluştu, lütfen tekrar deneyin" | Retry + destek linki |
| Validasyon | "[Alan] zorunludur" / "[Alan] geçersiz format" | İlgili input'a odaklan |
| Yetkisiz erişim | "Bu işlem için yetkiniz yok" | Login ekranına yönlendir |
| Timeout | "İşlem zaman aşımına uğradı, tekrar deneyin" | Retry butonu |

- **Kural**: Kullanıcıya asla raw exception mesajı gösterme
- **Kural**: Her hata mesajı bir aksiyon içermeli (retry, yönlendirme, vs.)

---

## 2.8 Mobil İzin Yönetimi (Flutter App)

| İzin | Kullanım | Zorunlu | Paket |
|------|----------|---------|-------|
| Kamera | Ürün fotoğrafı çekme | Evet | `permission_handler` + `image_picker` |
| Galeri | Ürün fotoğrafı seçme | Evet | `permission_handler` + `image_picker` |
| Konum | İşletme adresi tespiti | Önerilen | `permission_handler` + `geolocator` |
| Bildirimler | Sipariş/Sipariş durumu | Evet | `firebase_messaging` |
| Biyometrik | Hızlı giriş | Önerilen | `local_auth` |

- İzin **contextual** istenmeli (kullanıcı kamera butonuna bastığında)
- Reddedilirse: Ayarlara yönlendirme + alternatif sunma (manuel adres girişi)
- Her izin için ayrı yönetim, `PermissionStatus` cache'le
- **Kural**: İzin istemeden önce kullanıcıya NEDEN istendiğini açıkla (pre-permission dialog)
- **Kural**: İzin reddedilirse app crash olmamalı, graceful degrade

---

## 2.9 VixRex Prompt Şablonları

### Yeni Özellik Prompt'u
```
VixRex [Flutter/Next.js] projesinde [özellik adı] implementasyonu.
Mevcut mimari: Clean Architecture, Result<T> pattern, Supabase.
İlgili dosyalar: [max 5 dosya listesi]

Önce:
1. Implementasyon planı (hangi dosyalar değişecek)
2. API endpoint / Supabase fonksiyonları
3. UI değişiklikleri
4. Test senaryoları

Onay verince kod yaz. Context window'u 80K altında tut.
Başka dosyaya dokunma.
```

### Debug Prompt'u
```
VixRex'te [hata açıklaması].
Hata: [stack trace / mesaj]
İlgili dosyalar: [dosyalar]

Sadece bu dosyaları analiz et. Root cause bul, minimum fix uygula.
Diğer dosyalara dokunma. Test yazmayı unutma.
```

### UI Review Prompt'u
```
[Screen] UI'sini VixRex vitrin standartlarına göre review et:
- 8pt grid kullanılıyor mu?
- Loading/empty/error states var mı?
- Dark mode uyumlu mu?
- Primary CTA (örn: "Ürün Ekle", "Vitrini Gör") belirgin mi?
- Responsive (mobil vitrin + web vitrin) düşünüldü mü?
- Accessibility: kontrast, font boyutu, screen reader uyumu?
```

### Refactor Prompt'u
```
[Özellik/Dosya] refactor edilmesi gerekiyor.
Sebep: [refactor sebebi]
Hedef: [Hedef 1], [Hedef 2]
Kısıtlamalar:
- Mevcut API contract'ı bozma
- Test coverage'ı koru veya artır
- Breaking change yaratma
- Diğer platformu (Flutter/Next.js) etkileme

Önce refactor planını açıkla, onay verince adım adım uygula.
Her adımda test et. Context window'u 80K altında tut.
```

---

## 2.10 Veri Gizliliği ve Güvenlik (Vitrin Platformu)

- **Public vitrin**: İşletme adı, adres, ürünler, fiyatlar → Herkese açık
- **Private veri**: Müşteri listesi, sipariş geçmişi, finansal veriler → Auth gerekli
- **Supabase RLS**: Her tabloda row-level security politikaları aktif
- **API rate limiting**: 100 req/min başlangıç
- **Input validation**: Zod (Next.js) / freezed (Flutter) ile type-safe validation
- **PII şifreleme**: Telefon, email veritabanında encrypt edilmeli
- **GDPR/KVKK**: Kullanıcı verisi silme talebi endpoint'i hazır olmalı
- **Kural**: Her yeni tablo oluşturulduğunda RLS policy'si de oluşturulmalı
- **Kural**: API endpoint'lerde auth check zorunlu, anon access yasak
- **Kural**: Client-side'da API key, secret, password asla hardcoded olmamalı

---

## 3. Token Optimizasyonu ve Maliyet Kontrolü

### 3.1 Token Harcamalarını Azaltma Stratejileri

> **Altın Kural:** Context penceresini mümkün olduğunca küçük tut. AI modelleri, context büyüdükçe performansı düşer ("lost in the middle" problemi). Smart Zone (ilk ~100K token) içinde kal. citeweb_search:4#1

| Strateji | Uygulama | Token Tasarrufu | Kaynak |
|----------|----------|-----------------|--------|
| **Chunking (Parçalama)** | Her prompt tek bir dosya/özellik odaklı | ~40% | citeweb_search:1#1 |
| **Context Files** | `.cursor/rules`, `CLAUDE.md` ile tekrar eden kuralları dışarı taşı | ~25% | citeweb_search:4#1 |
| **Modular Prompting** | Her prompt tek bir concern/concern | ~30% | citeweb_search:1#1 |
| **Fresh Session** | Context büyüdüğünde yeni session başlat | ~50% (uzun sessionlarda) | citeweb_search:4#1 |
| **Observation Masking** | Eski tool output'larını placeholder ile değiştir | ~52% | citeweb_search:4#4 |
| **LLM Summarization** | Eski conversation'ları özetle | ~50% | citeweb_search:4#4 |
| **Hybrid Approach** | Observation masking + ara sıra summarization | ~57% | citeweb_search:4#4 |
| **Self-Critique Loop** | AI'dan kendi kodunu önce eleştirmesini iste | ~15% (daha az revizyon) | citeweb_search:1#1 |
| **Prompt Caching** | Statik prompt kısımlarını cache'le | ~50-90% | citeweb_search:4#0 |

### 3.2 Context Window Yönetimi (2026 En İyi Pratikler)

#### Smart Zone vs Dumb Zone

- **Smart Zone:** İlk ~100K token. AI burada en iyi performansı gösterir.
- **Dumb Zone:** 100K+ token. AI dikkat dağınıklığı yaşar, tutarsız kod üretir.

**Strateji:** Context'i 100K token altında tut. Claude Code'da `/context` komutu ile canlı takip yap. citeweb_search:4#1

#### Claude Code Context Yönetimi Komutları

```
/context     - Mevcut token kullanımını görüntüle
/clear       - Mevcut session context'ini temizle
/compact     - Conversation'ı özetle, alan aç
/recap       - Session özetini görüntüle
/rewind      - Belirli bir noktaya geri dön
/branch      - Mevcut noktadan yeni session başlat
/btw         - Ana thread'i kirletmeden yan soru sor
```

#### Context Engineering Best Practices citeweb_search:4#2

1. **Selective Context Injection:** Her prompt'ta sadece ilgili bilgiyi ekle
2. **Hierarchical Summarization:** Eski conversation'ları özetle, yeni olanları verbatim tut
3. **Role-Based Filtering:** Her agent'a sadece rolüne uygun context ver
4. **Structured Note-Taking:** AI'dan `NOTES.md` dosyası tutmasını iste (agentic memory)
5. **External Memory (RAG):** Büyük dokümantasyonu context'e değil, vektör DB'ye koy

### 3.3 Token Bütçesi Yönetimi

Her proje için günlük/haftalık token bütçesi belirle:

```
Günlük Token Bütçesi: ~50K-100K tokens
- Planlama & Araştırma: 20%
- Kod Üretimi: 50%
- Debug & Revizyon: 20%
- Test & Dokümantasyon: 10%

Haftalık Token Bütçesi: ~300K-500K tokens
- Yeni Özellikler: 60%
- Refactoring: 20%
- Bug Fix: 15%
- Diğer: 5%

Kritik Eşik: Context 80K token'a ulaşınca YENİ SESSION BAŞLAT
```

### 3.4 "Token-Aware" Prompt Şablonları

**Düşük Token (Hızlı Fix):**
```
"[Dosya adı] dosyasındaki [fonksiyon adı] fonksiyonunda 
[spesifik hata] var. Sadece bu fonksiyonu düzelt, 
diğer dosyalara dokunma."
```

**Orta Token (Yeni Özellik):**
```
"[Özellik adı] implementasyonu. Önce planı açıkla, 
onay verince sadece gerekli dosyaları değiştir. 
Mevcut [X] pattern'ini kullan."
```

**Yüksek Token (Mimari Değişiklik):**
```
"[Mimari değişiklik] gerekiyor. Önce mevcut kodu analiz et, 
sonra refactor planı oluştur, onay verince adım adım uygula. 
Her adımda test et."
```

---

## 4. Kod Kalitesi ve Modülerlik

### 4.1 Katmanlı Mimari (Layered Architecture)

Her uygulama, kategoriden bağımsız olarak şu katmanları içermelidir:

```
📁 src/
├── 📁 presentation/          # UI Katmanı
│   ├── 📁 screens/           # Ekranlar
│   ├── 📁 widgets/           # Yeniden kullanılabilir widget'lar
│   ├── 📁 themes/            # Tema, renkler, typography
│   └── 📁 navigation/        # Routing, navigation logic
├── 📁 domain/                # İş Mantığı Katmanı
│   ├── 📁 entities/          # Veri modelleri
│   ├── 📁 usecases/          # İş akışları (her biri tek sorumluluk)
│   └── 📁 repositories/      # Repository interface'leri
├── 📁 data/                  # Veri Katmanı
│   ├── 📁 models/            # API/DTO modelleri
│   ├── 📁 datasources/       # Remote (API) & Local (DB) kaynakları
│   └── 📁 repositories/      # Repository implementasyonları
├── 📁 core/                  # Çekirdek Katman
│   ├── 📁 constants/         # Sabitler, API URL'leri
│   ├── 📁 utils/             # Yardımcı fonksiyonlar
│   ├── 📁 errors/            # Özel hata sınıfları
│   └── 📁 di/                # Dependency Injection
└── 📁 test/                  # Test Katmanı
    ├── 📁 unit/
    ├── 📁 widget/
    └── 📁 e2e/
```

### 4.2 Modülerlik Prensipleri

**1. Single Responsibility Principle (SRP):**
- Her dosya/fonksiyon tek bir iş yapar
- Bir dosya 200 satırı geçmemeli
- Bir fonksiyon 50 satırı geçmemeli

**2. Dependency Inversion:**
- Üst katmanlar alt katmanlara bağımlı olmamalı
- Interface'ler üzerinden iletişim kurulmalı

**3. Feature-Based Modülerlik:**
```
📁 features/
├── 📁 auth/
│   ├── 📁 presentation/
│   ├── 📁 domain/
│   └── 📁 data/
├── 📁 profile/
├── 📁 feed/
└── 📁 settings/
```

### 4.3 Kod Kalitesi Kontrol Listesi

```
□ Her fonksiyon tek bir sorumluluk taşıyor mu?
□ Magic number/string var mı? (Constant'lara taşı)
□ Null safety / Type safety sağlanmış mı?
□ Error handling her async operasyonda var mı?
□ Kod tekrarı (DRY) var mı?
□ Fonksiyon isimleri açıklayıcı mı? (getUserById vs getData)
□ Comment'ler "nasıl" değil, "neden" açıklıyor mu?
□ Dead code var mı?
□ Memory leak riski var mı? (event listener'lar, subscriptions)
```

---

## 5. Kütüphane ve Teknoloji Seçimi

### 5.1 Teknoloji Stack Tespiti (2026 Güncel)

#### Mobil (React Native)

| Kategori | Önerilen | Alternatif | Notlar |
|----------|----------|------------|--------|
| **State Management** | Zustand | Redux Toolkit, Jotai | Zustand daha az boilerplate |
| **Navigation** | React Navigation v7 | - | Native stack kullan |
| **HTTP Client** | Axios + TanStack Query | SWR | Caching ve refetching kritik |
| **Form** | React Hook Form | Formik | Performans için RHF |
| **Validation** | Zod | Yup | TypeScript ile Zod daha iyi |
| **Styling** | NativeWind (Tailwind) | Styled Components | Tutarlılık için Tailwind |
| **Storage** | MMKV | AsyncStorage | MMKV daha hızlı, encrypted |
| **Push Notifications** | Firebase Cloud Messaging | OneSignal | FCM ücretsiz ve güvenilir |
| **Analytics** | Firebase Analytics | Amplitude, Mixpanel | FCM ile entegrasyon kolay |
| **Crash Reporting** | Sentry | Firebase Crashlytics | Sentry daha detaylı stack trace |

#### Mobil (Flutter)

| Kategori | Önerilen | Alternatif | Notlar |
|----------|----------|------------|--------|
| **State Management** | Riverpod | Bloc, GetX | Riverpod compile-safe |
| **Navigation** | GoRouter | AutoRoute | Deep link desteği kritik |
| **HTTP Client** | Dio + Riverpod | http package | Interceptor'lar için Dio |
| **Form** | flutter_form_builder | reactive_forms | Hızlı form oluşturma |
| **Validation** | formz | - | Type-safe validation |
| **Styling** | Material 3 | Cupertino | Adaptive tema kullan |
| **Storage** | Hive | SharedPreferences | Hive daha hızlı, NoSQL |
| **Push Notifications** | firebase_messaging | - | FlutterFire ekosistemi |
| **Analytics** | firebase_analytics | - | - |
| **Crash Reporting** | firebase_crashlytics | Sentry | - |

#### Web

| Kategori | Önerilen | Alternatif | Notlar |
|----------|----------|------------|--------|
| **Framework** | Next.js 15 | Remix, Astro | SSR/SSG için Next.js |
| **State Management** | Zustand | Redux Toolkit, Jotai | - |
| **Styling** | Tailwind CSS | CSS Modules | Utility-first hızlı geliştirme |
| **UI Components** | shadcn/ui | MUI, Chakra UI | Tailwind tabanlı, özelleştirilebilir |
| **Form** | React Hook Form + Zod | Formik + Yup | - |
| **HTTP Client** | TanStack Query | SWR, Axios | Server state management |
| **Auth** | NextAuth.js | Clerk, Auth0 | Next.js ile native entegrasyon |
| **Database** | Supabase | Firebase, PlanetScale | PostgreSQL, RLS, real-time |
| **Deployment** | Vercel | Netlify, Railway | Next.js için optimal |

### 5.2 Kütüphane Doğrulama Kontrol Listesi

```
□ Son güncelleme 6 ay içinde mi? (npm info [package])
□ Weekly download sayısı > 100K mi?
□ GitHub stars > 1K mi?
□ Açık issue/PR oranı makul mü?
□ TypeScript desteği var mı?
□ Tree-shakeable mı? (bundle size)
□ Lisans uyumlu mu? (MIT/Apache)
□ Maintenance durumu aktif mi? (son commit tarihi)
```

---

## 6. UI Tasarım ve Modernlik Tespiti

### 6.1 2026 UI Tasarım Trendleri ve Uygulama

#### Temel Prensipler

| Trend | Uygulama | Kontrol Noktası |
|-------|----------|-----------------|
| **Dark-First Design** | Koyu tema önce tasarlanır, açık tema adapte edilir | En az 4 surface level (bg, elevated, secondary, overlay) |
| **Thumb-Friendly** | Birincil aksiyonlar ekranın alt 1/3'ünde | 75% tek parmak kullanımı hedeflenir |
| **Cognitive Minimalism** | Her ekranda 1-3 aksiyon | Gereksiz elementleri kaldır |
| **Micro-Interactions** | 300ms altı animasyonlar, 60fps | Haptic feedback ile birlikte |
| **Passkey Auth** | Biyometrik giriş, şifresiz | Fallback (email magic link) hazır |
| **Adaptive UI** | Kullanım pattern'ine göre layout değişimi | En az 3 farklı kullanım modu varsa uygula |
| **Accessibility-First** | WCAG 2.2 AA uyumu | Ekran okuyucu, yüksek kontrast, scalable text |

#### Renk Sistemi (Tema Tokenları)

```
Color Tokens:
├── primary: Ana marka rengi
├── secondary: Destekleyici renk
├── background: Ana arka plan
├── surface: Kart, container arka planları
├── surface-elevated: Üst katman arka planları
├── text-primary: Ana metin
├── text-secondary: İkincil metin
├── text-disabled: Devre dışı metin
├── error: Hata durumları
├── success: Başarı durumları
├── warning: Uyarı durumları
└── border: Sınır/ayrım çizgileri
```

#### Tipografi Sistemi

```
Typography Scale:
├── display: 32-40px (Büyük başlıklar, landing)
├── headline: 24-28px (Ekran başlıkları)
├── title: 18-20px (Kart başlıkları, section)
├── body: 14-16px (Ana metin)
├── label: 12-14px (Buton, input label)
└── caption: 10-12px (Küçük yardımcı metin)
```

### 6.2 UI Kalite Kontrol Listesi

```
□ 8pt grid sistemi kullanılıyor mu?
□ Tutarlı spacing (padding/margin) var mı?
□ Primary CTA her ekranda belirgin mi?
□ Loading states tasarlandı mı? (Skeleton > Spinner)
□ Empty states tasarlandı mı?
□ Error states tasarlandı mı? (kullanıcı dostu mesajlar)
□ Dark mode renkleri ayrı mı tasarlandı? (invert değil)
□ Touch target minimum 44x44px (iOS) / 48x48dp (Android)?
□ Font boyutu sistem ayarlarına duyarlı mı?
□ RTL (sağdan sola) dil desteği var mı?
```

---

## 7. Sayfa Akışları ve Entegrasyon (Kategori Bağımsız)

### 7.1 Universal App Flow Şablonu

Her uygulama, kategorisine göre aşağıdaki sayfa yapısını adapte etmelidir:

#### Temel Sayfa Yapısı (Tüm Uygulamalar İçin)

```
📱 App Flow
├── 🏠 Landing / Welcome Screen
│   ├── Logo / Marka kimliği
│   ├── Value proposition (1 cümle)
│   ├── Primary CTA: "Başla" / "Kaydol"
│   ├── Secondary CTA: "Giriş Yap" (varsa)
│   └── Legal: Terms, Privacy Policy linkleri
│
├── 🔐 Auth Flow
│   ├── Login Screen
│   │   ├── Email/Phone input
│   │   ├── Password input (göster/gizle toggle)
│   │   ├── "Şifremi Unuttum" linki
│   │   ├── Primary CTA: "Giriş Yap"
│   │   ├── Social Login butonları (Google, Apple)
│   │   └── "Hesabın yok mu? Kaydol" linki
│   │
│   ├── Register Screen
│   │   ├── Ad Soyad input
│   │   ├── Email/Phone input
│   │   ├── Password input + Strength indicator
│   │   ├── Password Confirm input
│   │   ├── Terms & Privacy checkbox
│   │   ├── Primary CTA: "Kaydol"
│   │   └── "Zaten hesabın var mı? Giriş Yap" linki
│   │
│   └── Forgot Password Screen
│       ├── Email input
│       ├── Primary CTA: "Sıfırlama Linki Gönder"
│       └── Success state: "Email kontrol et"
│
├── 🏠 Main App Flow (Bottom Navigation)
│   ├── Tab 1: Home / Feed / Dashboard
│   ├── Tab 2: Explore / Discover / Search
│   ├── Tab 3: Create / Add / Action (FAB)
│   ├── Tab 4: Notifications / Activity
│   └── Tab 5: Profile / Settings
│
└── ⚙️ Settings / Profile Flow
    ├── Profile Edit
    ├── Account Settings
    ├── Notifications Settings
    ├── Privacy & Security
    ├── Help & Support
    └── Logout
```

### 7.2 Kategori Bazlı Özel Sayfa Akışları

#### Sosyal Arkadaşlık Platformu

```
Additional Screens:
├── 👤 Profile Screen
│   ├── Avatar, Cover Photo
│   ├── Bio, Location, Interests
│   ├── Action Buttons: Mesaj, Arkadaş Ekle, Engelle
│   └── Content Grid (gönderiler, fotoğraflar)
│
├── 💬 Messages Screen
│   ├── Conversation List
│   ├── Chat Screen (mesaj baloncukları, timestamp)
│   ├── Media sharing, Voice message
│   └── Typing indicator, Read receipts
│
├── 🔍 Discover / Nearby Screen
│   ├── Filter: Mesafe, Yaş, İlgi Alanları
│   ├── User Cards (swipeable)
│   └── Match/Bağlantı isteği
│
└── 🔔 Notifications Screen
    ├── Match/Bağlantı istekleri
    ├── Mesaj bildirimleri
    ├── Sistem bildirimleri
    └── Mark all as read
```

#### E-Ticaret Platformu

```
Additional Screens:
├── 🏪 Product Listing
│   ├── Categories, Filters, Sort
│   ├── Product Cards (image, title, price, rating)
│   └── Pagination / Infinite scroll
│
├── 📦 Product Detail
│   ├── Image Gallery (zoom, swipe)
│   ├── Title, Price, Discount
│   ├── Variants (size, color)
│   ├── Add to Cart CTA
│   ├── Reviews & Ratings
│   └── Related Products
│
├── 🛒 Cart Screen
│   ├── Product List (quantity, remove)
│   ├── Coupon Code input
│   ├── Price Breakdown (subtotal, shipping, tax, total)
│   └── Checkout CTA
│
├── 💳 Checkout Flow
│   ├── Shipping Address
│   ├── Payment Method (Card, Wallet, COD)
│   ├── Order Summary
│   └── Place Order CTA
│
└── 📋 Order History
    ├── Order List (status: pending, shipped, delivered)
    ├── Order Detail
    └── Reorder / Track
```

#### Stok Takip Uygulaması

```
Additional Screens:
├── 📊 Dashboard
│   ├── Total Items, Low Stock Alerts
│   ├── Recent Transactions
│   └── Quick Actions (Add Item, Scan Barcode)
│
├── 📦 Inventory List
│   ├── Search, Filter (category, status)
│   ├── Item Cards (image, name, quantity, status)
│   └── Bulk Actions
│
├── ➕ Add/Edit Item
│   ├── Name, SKU, Barcode
│   ├── Category, Description
│   ├── Quantity, Unit, Min Stock Level
│   ├── Cost Price, Selling Price
│   ├── Supplier Info
│   └── Save / Cancel
│
├── 🔄 Transactions
│   ├── Stock In / Stock Out
│   ├── Transfer Between Locations
│   └── History Log
│
└── 📈 Reports
    ├── Stock Levels
    ├── Sales Report
    └── Low Stock Alert
```

#### Dijital Cüzdan

```
Additional Screens:
├── 💰 Home / Balance
│   ├── Total Balance (hide/show toggle)
│   ├── Quick Actions (Send, Receive, Top-up)
│   └── Recent Transactions
│
├── 📤 Send Money
│   ├── Recipient Selection (contacts, QR)
│   ├── Amount Input
│   ├── Note/Memo
│   ├── Confirmation
│   └── Success/Failure State
│
├── 📥 Receive Money
│   ├── QR Code Display
│   ├── Share Link
│   └── Request Amount
│
├── 💳 Cards Management
│   ├── Virtual/Physical Cards List
│   ├── Card Details (mask/unmask)
│   ├── Freeze/Unfreeze
│   └── Transaction Limits
│
└── 📋 Transaction History
    ├── Filter (date, type, amount)
    ├── Transaction Detail
    └── Export / Receipt
```

### 7.3 Navigation ve Akış Uyumu Kontrol Listesi

```
□ Her ekranda "geri" aksiyonu net mi?
□ Deep link desteği var mı? (push notification'dan doğru ekrana)
□ Bottom navigation 3-5 item arasında mı?
□ Tab değişiminde state korunuyor mu?
□ Modal vs Full-screen navigation doğru kullanılıyor mu?
□ Offline durumda navigation çalışıyor mu?
□ Gesture back (iOS swipe) destekleniyor mu?
□ Screen reader ile navigation test edildi mi?
```

---

## 8. Backend ve Bulut Altyapısı

### 8.1 Platform ve Sağlayıcı Tespiti

#### BaaS (Backend as a Service) Seçimi

| Kriter | Supabase | Firebase | AWS Amplify | Appwrite |
|--------|----------|----------|-------------|----------|
| **Database** | PostgreSQL | Firestore | DynamoDB | MariaDB |
| **Real-time** | ✅ WebSocket | ✅ Firestore | ❌ | ✅ WebSocket |
| **Auth** | Email, OAuth, SSO | Email, OAuth, Anon | Cognito | Email, OAuth |
| **Storage** | S3-compatible | Cloud Storage | S3 | S3-compatible |
| **Functions** | Deno Edge | Cloud Functions | Lambda | Functions |
| **Pricing** | Tier-based | Pay-per-use | Pay-per-use | Self-host |
| **Open Source** | ✅ | ❌ | ❌ | ✅ |
| **Vendor Lock-in** | Düşük | Yüksek | Yüksek | Düşük |
| **TypeScript** | ✅ | ✅ | ✅ | ✅ |
| **Self-host** | ✅ | ❌ | ❌ | ✅ |

**Öneri:** MVP için Supabase (predictable pricing, SQL, low lock-in). Google ekosistemine derin entegrasyon gerekiyorsa Firebase. citeweb_search:2#2

#### Deployment Platformları

| Platform | En İyi Kullanım | Ücretsiz Tier |
|----------|----------------|---------------|
| **Vercel** | Next.js web apps | ✅ Generous |
| **Netlify** | Static/JAMstack | ✅ Generous |
| **Railway** | Full-stack apps | ✅ Limited |
| **Render** | Web services, DB | ✅ Generous |
| **Fly.io** | Edge deployment | ✅ Generous |
| **AWS Free Tier** | Production scale | ✅ 12 ay |
| **Google Cloud Run** | Containerized | ✅ Generous |

### 8.2 Güvenlik ve Depolama Kontrol Listesi

```
□ Tüm API endpoint'leri auth korumalı mı?
□ Rate limiting uygulanmış mı? (100 req/min başlangıç)
□ Input validation her endpoint'te var mı?
□ SQL injection koruması var mı? (parameterized queries)
□ XSS koruması var mı? (output encoding)
□ CORS whitelist kullanılıyor mu? (NOT: *)
□ HTTPS zorunlu mu?
□ API key'ler client-side'ta hardcoded değil mi?
□ Environment variables kullanılıyor mu?
□ Database RLS (Row Level Security) aktif mi?
□ PII (Personally Identifiable Information) şifreleniyor mu?
□ GDPR/KVKK uyumu sağlanmış mı?
□ Backup stratejisi var mı? (günlük otomatik)
□ Log retention politikası var mı?
```

---

## 9. Uygulama İzinleri ve Entegrasyonlar

### 9.1 iOS ve Android İzin Matrisi

| İzin | iOS | Android | Kullanım Senaryosu | Zorunlu mu? |
|------|-----|---------|-------------------|-------------|
| **Kamera** | `NSCameraUsageDescription` | `CAMERA` | Profil fotoğrafı, QR tarama, belge tarama | Kategori bağımlı |
| **Galeri/Fotoğraflar** | `NSPhotoLibraryUsageDescription` | `READ_EXTERNAL_STORAGE` | Profil fotoğrafı, paylaşım | Kategori bağımlı |
| **Konum** | `NSLocationWhenInUseUsageDescription` | `ACCESS_FINE_LOCATION` | Yakındakiler, teslimat, harita | Kategori bağımlı |
| **Bildirimler** | `UNUserNotificationCenter` | `POST_NOTIFICATIONS` | Push notification | Genellikle evet |
| **Mikrofon** | `NSMicrophoneUsageDescription` | `RECORD_AUDIO` | Sesli mesaj, voice search | Kategori bağımlı |
| **Rehber** | `NSContactsUsageDescription` | `READ_CONTACTS` | Arkadaş bulma, invite | Kategori bağımlı |
| **Bluetooth** | `NSBluetoothAlwaysUsageDescription` | `BLUETOOTH` | Cihaz bağlantısı, beacon | Kategori bağımlı |
| **Face ID/Touch ID** | `NSFaceIDUsageDescription` | `USE_BIOMETRIC` | Biyometrik auth | Önerilen |
| **Ağ Durumu** | - | `ACCESS_NETWORK_STATE` | Offline/online tespiti | Önerilen |

### 9.2 İzin İsteme Akışı (Best Practice)

```
1. Contextual Permission Request
   └── Kullanıcı özelliği kullanmaya çalıştığında izin iste
   └── Önce "pre-permission" dialog (neden istendiğini açıkla)
   └── Sonra sistem dialog'u

2. Permission Denied Handling
   └── Kullanıcı reddederse, ayarlara yönlendirme butonu göster
   └── Fonksiyonu gracefully degrade et (alternatif sun)

3. Permission Status Tracking
   └── Kullanıcının izin durumunu cache'le
   └── Her app açılışında kontrol et, gerekirse tekrar iste
```

### 9.3 Entegrasyon Kontrol Listesi

```
□ Sosyal Login (Google, Apple) entegrasyonu test edildi mi?
□ Deep link / Universal link çalışıyor mu?
□ Push notification delivery test edildi mi? (background, foreground, killed)
□ In-app purchase / Subscription flow test edildi mi?
□ Analytics events doğru gönderiliyor mu?
□ Crash reporting aktif mi?
□ CDN (image/asset delivery) yapılandırıldı mı?
□ Error tracking (Sentry) entegre mi?
□ CI/CD pipeline çalışıyor mu?
```

---

## 10. E2E Test Uygunluğu

### 10.1 E2E Test Stratejisi (Vibe Coding İçin)

> **Kritik İlke:** Vibe-coded uygulamalarda unit test yerine E2E test önceliklidir. Çünkü AI-generated kodun internal yapısını tam olarak anlamak zordur; kullanıcı perspektifinden test daha güvenilirdir. citeweb_search:1#3

#### Test Piramidi (Vibe Coding Adaptasyonu)

```
         /\
        /  \     E2E Tests (Kullanıcı perspektifi)
       /    \    - Kritik kullanıcı akışları
      /______\   - Auth, core flow, payment
     /        \
    /          \  Integration Tests (API + UI)
   /            \ - API endpoint'leri
  /______________\ - Database operations
 /                \
/                  \ Unit Tests (Sadece kritik business logic)
/____________________\ - Validation, calculation, utilities
```

### 10.2 E2E Test Araçları

#### React Native

| Araç | Kullanım | Avantaj | Dezavantaj |
|------|----------|---------|------------|
| **Detox** | Gray-box E2E | Hızlı, sync | iOS setup karmaşık |
| **Maestro** | Black-box E2E | Kolay setup, YAML | Daha az kontrol |
| **Appium** | Cross-platform | WebDriver standard | Yavaş, karmaşık |

**Öneri:** Maestro (hızlı başlangıç, vibe coding için ideal) citeweb_search:1#6

#### Flutter

| Araç | Kullanım | Avantaj | Dezavantaj |
|------|----------|---------|------------|
| **integration_test** | Built-in E2E | Flutter ekosistemiyle native | Sınırlı |
| **Patrol** | Native E2E | iOS/Android native interaction | Ek bağımlılık |
| **Maestro** | Black-box E2E | Cross-platform | Daha az Flutter-specific |

**Öneri:** integration_test + Patrol (native interaction için) citeweb_search:1#6

#### Web

| Araç | Kullanım | Avantaj | Dezavantaj |
|------|----------|---------|------------|
| **Playwright** | Modern E2E | Hızlı, reliable, cross-browser | Yeni öğrenme eğrisi |
| **Cypress** | E2E + Component | Developer experience | Sadece Chromium tabanlı |
| **Selenium** | Legacy E2E | Cross-browser | Yavaş, karmaşık |

**Öneri:** Playwright (2026'nın standardı)

### 10.3 E2E Test Senaryoları (Kategori Bağımsız)

#### Kritik Kullanıcı Akışları (Her Uygulama İçin)

```yaml
# Test Suite: Critical User Flows

tests:
  - name: "User Registration Flow"
    steps:
      - openApp
      - tap: "Kaydol"
      - fill: { field: "email", value: "test@example.com" }
      - fill: { field: "password", value: "Test123!" }
      - fill: { field: "confirm_password", value: "Test123!" }
      - tap: "Kaydol"
      - assert: { text: "Hoş geldiniz" }
      - assert: { screen: "Home" }

  - name: "Login Flow"
    steps:
      - openApp
      - tap: "Giriş Yap"
      - fill: { field: "email", value: "test@example.com" }
      - fill: { field: "password", value: "Test123!" }
      - tap: "Giriş Yap"
      - assert: { screen: "Home" }

  - name: "Auth Boundary Test"
    steps:
      - loginAs: "user_a"
      - navigateTo: "/profile/user_b"
      - assert: { text: "Erişim reddedildi" }
      - assert: { statusCode: 403 }

  - name: "Offline Fallback"
    steps:
      - setNetwork: "offline"
      - openApp
      - assert: { text: "Çevrimdışı mod" }
      - assert: { element: "cached_content", visible: true }
```

#### Kategori Bazlı E2E Senaryoları

**Sosyal Arkadaşlık:**
```yaml
  - name: "Match Flow"
    steps:
      - login
      - navigateTo: "Discover"
      - swipe: "right"
      - assert: { text: "Match!" }
      - tap: "Mesaj Gönder"
      - fill: { field: "message", value: "Merhaba!" }
      - tap: "Gönder"
      - assert: { text: "Merhaba!" }
```

**E-Ticaret:**
```yaml
  - name: "Complete Purchase Flow"
    steps:
      - login
      - search: "ürün adı"
      - tap: { firstProduct: true }
      - selectVariant: { size: "M", color: "Kırmızı" }
      - tap: "Sepete Ekle"
      - navigateTo: "Cart"
      - tap: "Ödeme Yap"
      - fillAddress
      - selectPayment: "credit_card"
      - fillCardDetails
      - tap: "Siparişi Tamamla"
      - assert: { text: "Siparişiniz alındı" }
```

**Stok Takip:**
```yaml
  - name: "Add Item and Check Stock"
    steps:
      - login
      - tap: "Yeni Ürün Ekle"
      - fill: { field: "name", value: "Test Ürün" }
      - fill: { field: "quantity", value: "100" }
      - fill: { field: "min_stock", value: "10" }
      - tap: "Kaydet"
      - navigateTo: "Inventory"
      - assert: { text: "Test Ürün" }
      - assert: { text: "100" }
```

**Dijital Cüzdan:**
```yaml
  - name: "Send Money Flow"
    steps:
      - login
      - tap: "Para Gönder"
      - selectRecipient: "contact_1"
      - fill: { field: "amount", value: "50" }
      - tap: "Devam"
      - assert: { text: "50 TL" }
      - confirmBiometric
      - assert: { text: "İşlem başarılı" }
      - navigateTo: "History"
      - assert: { text: "-50 TL" }
```

### 10.4 E2E Test Altyapısı Kurulumu

#### CI/CD Entegrasyonu (GitHub Actions Örneği)

```yaml
# .github/workflows/e2e.yml
name: E2E Tests

on: [push, pull_request]

jobs:
  e2e:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install dependencies
        run: npm ci

      - name: Run E2E Tests (Web)
        run: npx playwright test
        if: matrix.platform == 'web'

      - name: Run E2E Tests (Mobile - Maestro)
        run: |
          npm install -g @maestro/cli
          maestro test e2e/
        if: matrix.platform == 'mobile'

      - name: Upload Test Results
        uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: test-results
          path: test-results/
```

### 10.5 E2E Test Uygunluğu Kontrol Listesi

```
□ Her kritik kullanıcı akışı E2E test ile kapsanmış mı?
□ Auth boundary test'leri yazıldı mı? (User A, User B verisine erişememeli)
□ Offline/Online geçiş test edildi mi?
□ Push notification deep link test edildi mi?
□ CI/CD'de her push'ta testler çalışıyor mu?
□ Test suite sağlığı > 80% mi? (skipped test < 20%)
□ Testler self-healing mi? (UI değişikliğinde otomatik adaptasyon)
□ Test data yönetimi var mı? (her test bağımsız)
□ Test paralel çalışabiliyor mu?
□ Flaky test'ler belirlenip düzeltildi mi?
```

---

## 11. Vibe Coding Prompt Şablonları (Kopyala-Yapıştır)

### 11.1 Proje Başlatma Prompt'u

```
Sen bir senior [React Native/Flutter/Next.js] geliştiricisisin. 
[Uygulama kategorisi] alanında bir [MVP/demo] uygulaması geliştiriyoruz.

Teknoloji stack:
- Framework: [örn: React Native 0.74 + Expo]
- State Management: [örn: Zustand]
- Backend: [örn: Supabase]
- Styling: [örn: NativeWind]

Mimari:
- Clean Architecture / Layered Architecture kullan
- Feature-based modülerlik
- Repository pattern
- Dependency Injection

Kurallar:
1. Her prompt'ta tek bir özellik/fonksiyon odaklan
2. Önce planı açıkla, onayımı al, sonra kod yaz
3. Error handling, loading states, empty states her zaman ekle
4. TypeScript/Type safety zorunlu
5. Her dosya 200 satırı geçmemeli
6. Test yazmayı unutma
7. Context window'u 100K token altında tut

Şimdi [proje adı] için temel yapıyı (scaffolding) oluştur.
```

### 11.2 Yeni Özellik Prompt'u

```
[Önceki özellik] tamamlandı. Şimdi [yeni özellik adı] implementasyonu.

Önce implementasyon planını açıkla:
1. Hangi dosyalar değişecek?
2. Yeni dosyalar neler?
3. API endpoint'leri neler?
4. UI değişiklikleri neler?
5. Test senaryoları neler?

Onay verince kodu yaz. Mevcut [X] pattern'ini kullan.
Context window'u kontrol altında tut.
```

### 11.3 Debug Prompt'u

```
[Özellik/Hata açıklaması] çalışmıyor.

Hata mesajı: [hata mesajı]
Beklenen davranış: [beklenen]
Mevcut davranış: [mevcut]

İlgili dosyalar:
- [dosya 1]
- [dosya 2]

Sadece bu dosyaları analiz et, gereksiz dosyalara dokunma.
Önce root cause'u bul, sonra fix'i uygula.
```

### 11.4 Refactor Prompt'u

```
[Özellik/Dosya] refactor edilmesi gerekiyor.

Sebep: [refactor sebebi]

Hedef:
1. [Hedef 1]
2. [Hedef 2]

Kısıtlamalar:
- Mevcut API contract'ı bozma
- Test coverage'ı koru veya artır
- Breaking change yaratma

Önce refactor planını açıkla, onay verince adım adım uygula.
Her adımda test et. Context window'u 80K token altında tut.
```

### 11.5 UI Review Prompt'u

```
[Screen/Component] UI'sini review et.

Kontrol et:
1. 2026 UI trendleriyle uyumlu mu? (dark-first, thumb-friendly, minimal)
2. Accessibility uyumu var mı? (WCAG 2.2)
3. Responsive/foldable desteği var mı?
4. Loading/empty/error states var mı?
5. Micro-interactions (haptic, animation) var mı?
6. Primary CTA belirgin mi?
7. 8pt grid kullanılıyor mu?

Eksikleri listele ve düzelt.
```

### 11.6 Token Optimizasyon Prompt'u

```
Mevcut session context window'u kontrol et.
Eğer 80K token'ı aştıysa:
1. Önce mevcut çalışmayı NOTES.md dosyasına özetle
2. Yeni session başlat
3. NOTES.md'den devam et

Eğer 80K altındaysa:
- Sadece ilgili dosyaları context'e ekle
- Gereksiz tool output'larını temizle
```

---

## 12. CI/CD ve Deployment Pipeline

### 12.1 Git Workflow

```
main branch (production)
  └── develop branch (staging)
        └── feature/[feature-name]
        └── bugfix/[bug-name]
        └── refactor/[refactor-name]

Kurallar:
- Her PR'da E2E test geçmeli
- Code review (AI veya human) zorunlu
- Semantic versioning kullan
- Changelog tut
```

### 12.2 Deployment Checklist

```
□ Tüm E2E testler yeşil mi?
□ Security audit (SAST/DAST) tamamlandı mı?
□ Dependency vulnerability scan (npm audit) temiz mi?
□ Performance benchmark (Lighthouse/Core Web Vitals) kabul edilebilir mi?
□ Analytics events doğru çalışıyor mu?
□ Feature flags yapılandırıldı mı?
□ Rollback planı hazır mı?
□ Monitoring/Alerting aktif mi?
□ App Store / Play Store metadata güncellendi mi?
```

---

## 13. Özet: Günlük Vibe Coding Rutini

```
🌅 GÜN BAŞLANGICI (15 dk)
├── PLAN.md'yi gözden geçir
├── Dünkü commit'leri review et
├── Context window'u kontrol et (/context)
└── Bugünkü hedefi belirle (1-2 özellik max)

🛠️ GELİŞTİRME DÖNGÜSÜ (Her Özellik İçin)
├── 1. Prompt: Plan iste (5 dk)
├── 2. Prompt: Kod üret (15-30 dk)
├── 3. Manuel review: Kod kalitesi kontrolü (10 dk)
├── 4. Test: Unit + E2E test çalıştır (10 dk)
├── 5. Debug: Gerekirse fix (10-20 dk)
├── 6. Context check: 80K token eşiğini kontrol et
└── 7. Commit: Anlamlı commit mesajı (5 dk)

🌙 GÜN SONU (15 dk)
├── E2E test suite çalıştır
├── Coverage raporunu kontrol et
├── PLAN.md'yi güncelle
├── NOTES.md'yi güncelle (session özeti)
└── Yarınki planı belirle
```

---

## 14. Kaynaklar ve Referanslar

- [Vibe Coding Guide 2026](https://www.sitepoint.com/vibe-coding-2026-complete-guide/) citeweb_search:1#0
- [Vibe Coding Best Practices](https://www.memberstack.com/blog/9-vibe-coding-best-practices) citeweb_search:1#1
- [Vibe Coding Testing Gap](https://getautonoma.com/blog/vibe-coding-testing) citeweb_search:1#3
- [Building AI Coding Agents](https://arxiv.org/html/2603.05344v1) citeweb_search:1#2
- [Context Window Management Strategies](https://www.getmaxim.ai/articles/context-window-management-strategies-for-long-context-ai-agents-and-chatbots/) citeweb_search:4#0
- [Keep Context Window Sharp](https://medium.com/engineering-in-the-age-of-ai/keep-your-ai-agents-context-window-sharp-7255d83a8949) citeweb_search:4#1
- [Effective Context Engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) citeweb_search:4#2
- [Smarter Context Management](https://blog.jetbrains.com/research/2025/12/efficient-context-management/) citeweb_search:4#4
- [Mobile App Testing Best Practices 2026](https://momentic.ai/blog/mobile-app-testing-best-practices) citeweb_search:2#1
- [Supabase vs Firebase 2026](https://tech-insider.org/supabase-vs-firebase-2026/) citeweb_search:2#2
- [Mobile App UI/UX Trends 2026](https://www.gitnexa.com/blogs/mobile-app-ui-ux-design-trends) citeweb_search:2#0
- [Mobile App Design Trends 2026](https://muz.li/blog/whats-changing-in-mobile-app-design-ui-patterns-that-matter-in-2026/) citeweb_search:2#4
- [React Native vs Flutter Testing](https://maestro.dev/insights/react-native-vs-flutter-testing-comparison) citeweb_search:1#6

---

*Bu skill, vibe coding pratiğini sürdürülebilir, test edilebilir ve üretim kalitesinde tutmak için tasarlanmıştır. Her proje başlangıcında bu dokümanı gözden geçirin ve AI'ya referans olarak verin.*

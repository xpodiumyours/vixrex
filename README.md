# VixRex

> **Küçük işletmeler için dijital vitrin ve müşteri yönetim platformu.**

VixRex, küçük işletmelerin kod bilmeden dijital bir vitrin sahibi olmasını sağlar. İki ayrı, birbirinden bağımsız yayınlanan uygulamadan oluşur ve ikisi de aynı Supabase (PostgreSQL) veritabanını paylaşır.

---

## 🏗️ Sistem Mimarisi

```
vixrex/
├── lib/               # Flutter — işletme sahibinin yönetim paneli (Web + Android)
├── public_web/        # Next.js — herkese açık vitrin (/v/:slug) + sahip modunda "Vixrex Asistan" düzenleme paneli
├── shared/             # Vitrin alan şeması + mesaj katalogu — Flutter ve Next.js'in ortak tek kaynağı
└── supabase/           # PostgreSQL migration'ları, RLS politikaları, Edge Function'lar
```

- **Flutter panel** (`lib/`) → Vercel projesi: `vixrex-app`
- **Next.js vitrin** (`public_web/`) → Vercel projesi: `vixrex-public`

İki Vercel projesi **ayrı yayınlanır ve ayrı doğrulanır** — birinin deploy olması diğerinin çalıştığı anlamına gelmez.

### Vitrin görünümü yalnız Next.js'te çizilir

Müşterinin gördüğü `/v/:slug` sayfası ve sahibin önizlemesi **tek bir yerden**, `public_web`'teki gerçek şablondan gelir. Flutter bu sayfayı kendi başına bir daha çizmez; yalnız veriyi düzenler, Supabase'e yazar ve Next.js linkini açar.

### Düzenlemenin iki kapısı

Bir vitrin alanı iki yoldan düzenlenebilir:

1. **Flutter manuel panel** — büyük form, toplu işlem (OCR/Excel), çevrimdışı çalışma.
2. **"Vixrex Asistan"** (`public_web`, sahip modu) — vitrinin üzerinde bir alana tıklayınca açılan sohbet/düzenleme paneli (`OwnerWorkspaceShell`, `OwnerAssistantPanel`). Form doldurmak yerine "tıkla, değiştir" deneyimi.

İkisi de aynı alan şemasına (`shared/vitrin_alanlari.json`) ve aynı doğrulamaya bakar, aynı taslağa yazar.

---

## 🚀 Öne Çıkan Özellikler

- 🏪 **Dijital vitrin editörü** — işletme bilgileri, logo/kapak görselleri, sosyal medya bağlantıları, tema.
- 💬 **Vixrex Asistan (tıkla-düzenle panel)** — herkese açık vitrin sayfasının üzerinde, sahip modunda açılan düzenleme paneli; ayrı bir form ekranı değildir.
- 🏷️ **Kiralık vitrin + premium abonelik** — hazır bir şablon 14 gün ücretsiz denenip kiralanabilir; süre dolduğunda 3 gün içinde yenilenmezse vitrin taslağa döner. Ödeme PayTR üzerinden alınır.
- 📸 **OCR ile toplu ürün yükleme** — menü/broşür/liste görsellerinden metin tanıma (Google ML Kit) ile ürün kartı oluşturma; ücretsiz kullanıcı için günlük limitlidir.
- 📊 **Excel ile toplu veri aktarımı** — ürün/stok listelerini tek seferde sisteme aktarma.
- 📅 **Randevu ve booking yönetimi** — hizmet bazlı takvim, onay/iptal, müşteri için takip bağlantısı (`/v/:slug/randevu/:token`).
- 🔍 **Keşfet ekranı** — yayınlanmış tüm vitrinleri listeleme, arama, kategoriye göre filtreleme, favorileme.
- 🆕 **"Hazır Vitrin Seç" onboarding** — sıfırdan kurmak yerine Keşfet'teki kiralık şablonlardan birini seçip kiralayarak başlama yolu.
- 📝 **Blog / duyuru yönetimi** — işletmenin kendi vitrininde yazı paylaşması.
- 📷 **Instagram'dan ürün aktarma** — kod tamamlanmış durumda ama **varsayılan olarak kapalı** (`INSTAGRAM_SYNC_ENABLED=false`); Meta App Review süreci henüz tamamlanmadı.
- ✅ **Yasal onay akışı** — gizlilik/şartlar/yayın izni onayı hem Flutter panelinden hem Vixrex Asistan üzerinden verilebilir.

---

## 🛠️ Teknoloji Yığını

### Flutter panel (`lib/`)

| Alan | Paket / sürüm |
| :--- | :--- |
| SDK | Dart `^3.7.2`, Flutter 3.x |
| Veritabanı & Auth | `supabase_flutter ^2.12.4` |
| Yönlendirme | `go_router ^14.3.0` |
| OCR | `google_mlkit_text_recognition 0.15.1` |
| Excel / dosya | `excel ^4.0.0`, `file_picker`, `image_picker`, `flutter_image_compress` |
| Google girişi | `google_sign_in ^6.2.2` |
| reCAPTCHA v3 | `recaptcha_v3` (site anahtarı `web/index.html` içinde, dart-define değil) |
| Push bildirim | `onesignal_flutter ^5.2.0` |
| Hata izleme | `sentry_flutter 9.3.0` |

### Next.js vitrin (`public_web/`)

- **Framework:** Next.js (TypeScript, App Router)
- **Veri katmanı:** `@supabase/supabase-js`
- **Stil:** Tailwind CSS
- **Ödeme:** PayTR (kiralık vitrin/premium akışı)

### Ortak (`shared/`, `supabase/`)

- `shared/vitrin_alanlari.json` — düzenlenebilir vitrin alanlarının tek kaynağı; Flutter (`lib/config/vitrin_alanlari.g.dart`) ve Next.js (`vitrinFieldSchema.ts`) buradan üretilir/senkronize edilir. CI'da sapma kontrolü var.
- `supabase/migrations/` — sürümlü SQL migration'lar; canlı şema yalnız bu dosyalardan değişir.

---

## 💻 Yerel Geliştirme Ortamı

### Gereksinimler

- [Flutter SDK](https://docs.flutter.dev/get-started/install) `>= 3.7.2`
- [Node.js](https://nodejs.org/) `>= 18.x` (`public_web` için)

### Flutter paneli

Ortam değişkenleri `--dart-define` ile geçer. Yerelde git'e alınmayan `dart_defines.local.json` gerekir (`dart_defines.example.json` örnektir).

```powershell
.\dev.ps1          # Flutter :5000 + Next.js :3000 birlikte
.\run.ps1          # Yalnız Flutter Web
```

```bash
flutter pub get
dart analyze
flutter test
flutter build web --release --dart-define-from-file=dart_defines.local.json
```

### Next.js vitrini

```bash
cd public_web
npm install
npm run dev      # http://localhost:3000
npm run lint
npm run build
npm run test
```

---

## ⚙️ Çevre Değişkenleri

### Flutter (`--dart-define`)

Kod içinde `String.fromEnvironment` / `bool.fromEnvironment` ile okunan tüm değişkenler:

| Değişken | Zorunlu mu | Açıklama |
| :--- | :--- | :--- |
| `SUPABASE_URL` | **Evet** | Supabase proje adresi (`vercel-build.sh` eksikse build'i durdurur) |
| `SUPABASE_PUBLISHABLE_KEY` | **Evet** | Supabase publishable/anon anahtarı |
| `PUBLIC_SITE_URL` | Hayır | `public_web` adresi (varsayılan: `https://vixrex-public.vercel.app`) |
| `ONESIGNAL_APP_ID` | Hayır | Push bildirim |
| `SENTRY_DSN` | Hayır | Hata izleme |
| `GOOGLE_WEB_CLIENT_ID` / `GOOGLE_IOS_CLIENT_ID` | Hayır | Google ile giriş |
| `REVALIDATION_SECRET` | Hayır | Next.js ISR revalidate çağrısı için ortak sır |
| `INSTAGRAM_SYNC_ENABLED` | Hayır | `true`/`false` — Instagram içe aktarmayı açar (varsayılan `false`) |
| `LEGAL_DATA_CONTROLLER_TITLE`, `LEGAL_DATA_CONTROLLER_ADDRESS`, `LEGAL_MERSIS_NUMBER`, `LEGAL_TAX_NUMBER`, `LEGAL_PRIVACY_EMAIL` | Hayır | Gizlilik/KVKK metinlerindeki veri sorumlusu bilgileri (varsayılanları kodda var) |

### Next.js (`public_web/.env.local`)

`.env.example` dosyasındaki gerçek liste:

```env
# Supabase
SUPABASE_URL=
SUPABASE_PUBLISHABLE_KEY=
SUPABASE_SERVICE_ROLE_KEY=       # yalnız sunucu tarafı, NEXT_PUBLIC_ ÖNEKİ ASLA ALMAZ

# Sunucu-yalnız sırlar
REVALIDATION_SECRET=
TURNSTILE_SECRET_KEY=
RECAPTCHA_SECRET_KEY=
OWNER_SESSION_SECRET=            # sahip önizleme çerezini imzalar, en az 32 karakter
RATE_LIMIT_SECRET=               # "vitrini kirala" oran sınırlaması, üretimde MUTLAKA ayarlanmalı

# Herkese açık
NEXT_PUBLIC_SITE_URL=https://vixrex.app
NEXT_PUBLIC_APP_URL=https://app.vixrex.app
NEXT_PUBLIC_GA_ID=
NEXT_PUBLIC_RECAPTCHA_SITE_KEY=

# Instagram API (senkron varsayılan kapalı)
INSTAGRAM_CLIENT_ID=
INSTAGRAM_CLIENT_SECRET=
INSTAGRAM_REDIRECT_URI=
INSTAGRAM_SCOPES=
INSTAGRAM_STATE_SECRET=
INSTAGRAM_TOKEN_ENCRYPTION_KEY=
INSTAGRAM_ALLOWED_ORIGINS=
```

Not: `supabase.ts` `NEXT_PUBLIC_SUPABASE_URL`/`NEXT_PUBLIC_SUPABASE_ANON_KEY`'i de yedek olarak okur, ama önce `SUPABASE_URL`/`SUPABASE_PUBLISHABLE_KEY`'e bakar — bu ikisi asıl kaynaktır.

---

## 🌐 Yayınlama (Deployment)

Proje **Vercel** üzerinde iki ayrı proje olarak yayınlanır:

1. **`vixrex-app`** — Flutter Web release derlemesi (`vercel-build.sh`).
2. **`vixrex-public`** — `public_web` dizinindeki Next.js uygulaması. `/api/health` üzerinden uygulama, veritabanı bağlantısı ve PayTR yapılandırmasının durumu kontrol edilebilir.

Veritabanı şeması `supabase/migrations/` altındaki sürümlü SQL dosyalarıyla değişir; canlı Dashboard'dan elle değiştirilmez.

---

## 📄 Lisans

Bu proje özel mülkiyete tabidir. Tüm hakları saklıdır.

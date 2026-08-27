# VixRex

> **Küçük işletmeler için dijital vitrin ve müşteri yönetim platformu.**

VixRex, küçük işletmelerin kod bilmeden dijital bir vitrin sahibi olmasını sağlar. İki ayrı, birbirinden bağımsız yayınlanan uygulamadan oluşur ve ikisi de aynı Supabase (PostgreSQL) veritabanını paylaşır.

---

## 🏗️ Sistem Mimarisi

```
vixrex/
├── lib/               # Flutter — işletme sahibinin yönetim paneli (Web + Android)
├── public_web/        # Next.js — platformun herkese açık yüzü: ana sayfa, Keşfet,
│                      #   kategori sayfaları, vitrinler (/v/:slug) ve sahip modunda
│                      #   "Vixrex Asistan" düzenleme paneli
├── shared/             # Vitrin alan şeması + mesaj katalogu — Flutter ve Next.js'in ortak tek kaynağı
└── supabase/           # PostgreSQL migration'ları, RLS politikaları, Edge Function'lar
```

- **Flutter panel** (`lib/`) → Vercel projesi: `vixrex-app`
- **Next.js platform** (`public_web/`) → Vercel projesi: `vixrex-public`

İki Vercel projesi **ayrı yayınlanır ve ayrı doğrulanır** — birinin deploy olması diğerinin çalıştığı anlamına gelmez.

### Next.js platformun ana kapısıdır (2026-08-26)

Kök adres artık uygulamaya yönlendirmiyor; gerçek bir sayfa. Arama motorunun
okuduğu her yüzey `public_web`'te üretilir:

| Adres | İçerik |
| :--- | :--- |
| `/` | Ana sayfa (tanıtım) |
| `/kesfet` | Yayındaki vitrinlerin dizini |
| `/kesfet/:kategori` | 19 kanonik kategori sayfası (adresler tireli: `kafe-lokanta`) |
| `/v/:slug` | Vitrin |
| `/sitemap.xml`, `/robots.txt` | Arama motoru altyapısı |

Flutter yüzeyi (`vixrex-app`) `X-Robots-Tag: noindex` ile aramadan çıkarılmıştır —
aynı içeriğin iki adreste indekslenmesini önler.

`(site)` route grubu ana sayfayı ve Keşfet'i ortak başlık/altbilgiyle sarar.
Bu layout kök layout'a **konmaz**: kök layout `/v/:slug` vitrinlerini de sarıyor,
oraya başlık eklemek canlı vitrinleri bozar.

### Vitrin görünümü yalnız Next.js'te çizilir

Müşterinin gördüğü `/v/:slug` sayfası ve sahibin önizlemesi **tek bir yerden**, `public_web`'teki gerçek şablondan gelir. Flutter bu sayfayı kendi başına bir daha çizmez; yalnız veriyi düzenler, Supabase'e yazar ve Next.js linkini açar.

### Düzenlemenin iki kapısı

Bir vitrin alanı iki yoldan düzenlenebilir:

1. **Flutter manuel panel** — büyük form, toplu işlem (OCR/Excel), çevrimdışı çalışma.
2. **"Vixrex Asistan"** (`public_web`, sahip modu) — vitrinin üzerinde bir alana tıklayınca açılan sohbet/düzenleme paneli (`OwnerWorkspaceShell`, `OwnerAssistantPanel`). Form doldurmak yerine "tıkla, değiştir" deneyimi.

İkisi de aynı alan şemasına (`shared/vitrin_alanlari.json`) ve aynı doğrulamaya bakar, aynı taslağa yazar.

### Ana sayfadaki asistan sohbeti bir makettir

Ana sayfada telefon mockup'ının içinde açılan Vixrex Asistan sohbeti **sabit
reklam metnidir** — kullanıcı yazamaz, hiçbir sunucuya bağlı değildir ve
bağlanmayacaktır. Web'de gerçek asistan yalnız sahip panelindedir.

Bu kural 2026-08-26'da kondu: o gün ölçüldüğünde iki yüzeyde toplam **dokuz
ayrı "Vixrex Asistan" parçası** vardı (Flutter'da 6, web'de 3). Maketi
"çalışmıyor" sanıp motora bağlamak dördüncü bir web asistanı doğururdu.
Tam metin: `VIXREX_RULES.md` §1.

### Vitrin kalıcı hesaba bağlıdır (2026-08-26)

- **Hesap başına tek vitrin.** Veritabanı seviyesinde kısmi unique index ile
  zorlanır; ikinci kiralama `ALREADY_OWNS_STORE` döner — bu bir hata değil,
  kuralın çalıştığının işaretidir.
- **Yeni cihazda açılış** `bootstrap_owner_state()` ile yapılır; kullanıcı
  aynı hesapla girdiğinde vitrini kod/link istenmeden gelir.
- Demo vitrin kiralandığında klon **sahipli doğar** (`rent_demo_for_account`),
  düzenleme anahtarı bir yıllıktır.

Bu iş öncesinde canlıda vitrinlerin **hiçbirinde** `user_id` dolu değildi;
sahiplenme hiç çalışmamıştı.

---

## 🚀 Öne Çıkan Özellikler

- 🏪 **Dijital vitrin editörü** — işletme bilgileri, logo/kapak görselleri, sosyal medya bağlantıları, tema.
- 💬 **Vixrex Asistan (tıkla-düzenle panel)** — herkese açık vitrin sayfasının üzerinde, sahip modunda açılan düzenleme paneli; ayrı bir form ekranı değildir.
- 🏷️ **Kiralık vitrin + premium abonelik** — hazır bir şablon 14 gün ücretsiz denenip kiralanabilir; süre dolduğunda 3 gün içinde yenilenmezse vitrin taslağa döner. Ödeme PayTR üzerinden alınır.
- 📸 **OCR ile toplu ürün yükleme** — menü/broşür/liste görsellerinden metin tanıma (Google ML Kit) ile ürün kartı oluşturma; ücretsiz kullanıcı için günlük limitlidir.
- 📊 **Excel ile toplu veri aktarımı** — ürün/stok listelerini tek seferde sisteme aktarma.
- 📅 **Randevu ve booking yönetimi** — hizmet bazlı takvim, onay/iptal, müşteri için takip bağlantısı (`/v/:slug/randevu/:token`).
- 🔍 **Keşfet** — yayınlanmış vitrinlerin dizini. Flutter'da arama/filtre/favori ile; web'de ayrıca taranabilir bir dizin ve 19 kategori sayfası olarak (`/kesfet`, `/kesfet/:kategori`). Kategori süzgeçleri düz bağlantıdır: JavaScript'e bağlı süzgeç kategorileri arama motorundan gizler.
- 🔐 **Kalıcı hesap sahipliği** — vitrin hesaba bağlanır, hesap başına tek vitrin kuralı vardır, yeni cihazda aynı hesapla girildiğinde vitrin kendiliğinden gelir.
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
dart format lib test     # CI'da ayrı bir kapı — atlanırsa PR kırmızı düşer
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
npm run e2e:local   # E2E'yi yerel derlemeye karşı koşar
```

---

## ✅ Test ve Kalite Kapıları

Bu depoda PR'ı **gerçekten durduran** kapılar var. Bunları bilmeden çalışmak
en sık zaman kaybı sebebidir.

| Kapı | Ne yapar | Nerede |
| :--- | :--- | :--- |
| Kapsam kontrolü | 12 dosya / 600 satırı aşan PR, açıklamada `Kapsam-Onay:` satırı yoksa CI'yı kırar | `.github/scripts/verify_pr_scope.py` |
| Supabase erişim bekçisi | `lib/repositories/` dışında `Supabase.instance` kullanan dosya sayısını dondurur | `.github/scripts/verify_supabase_erisim_ratchet.py` |
| Biçim kapısı | `dart format --output=none --set-exit-if-changed lib test` | `.github/workflows/ci.yml` |
| Şema üretim hattı | `shared/*.json` → üretici → `.g.dart` tazeliğini `git diff --exit-code` ile kanıtlar | `.github/workflows/ci.yml` |
| Sızıntı taraması, GRANT bekçisi | Sır ve veritabanı izin kontrolü | `.github/workflows/ci.yml` |

**E2E yalnız `main`'e push'ta koşar, PR'da atlanır.** Yani yeşil bir PR, gerçek
tarayıcıda çalıştığının kanıtı değildir — merge sonrası `main` koşumuna bakın.

**Görsel regresyon temelleri işletim sistemine bağlıdır:**
`*-chromium-linux.png` ve `*-chromium-win32.png` ayrı tutulur. CI Linux'ta
koştuğu için Windows'ta üretilen temel CI'yı yeşile çevirmez; Linux temeli
Docker'daki Playwright kabıyla üretilir. Testler canlı siteye baktığından
(`E2E_PUBLIC_BASE_URL` verilmezse), temel üretmeden önce Vercel dağıtımının
bitmesi gerekir.

**Testin yeşil olması ekranın çalıştığı anlamına gelmez.** 2026-08-26'da 671
birim testi yeşilken gerçek tarayıcıda üç kullanıcı engeli bulundu: çerez
bildirimi asistan düğmesini kapatıyordu, bir bağlantı 404 veriyordu, bir düğme
hiçbir şey yapmıyordu. Kullanıcı akışını değiştiren işlerde gerçek tarayıcı
kontrolü şarttır.

---

## 🧱 Bilinen Mimari Borç

Yeni gelen kişinin **yanlış deseni çoğaltmaması** için; issue listesi değildir.

- **Fiyat tek kaynakta değil.** "299 TL" on ayrı dosyada elle yazılı (Flutter,
  web ve ödeme kodunda). Fiyat değişirse hepsini tek tek bulmak gerekir.
- **Renkler elle kopyalanmış.** `lib/theme/app_colors.dart` 38 renk tanımlıyor;
  `public_web/src/app/globals.css` bunların bir kısmını `--color-lp-*` adıyla
  elle taşımış. Hiçbir test ikisini bağlamıyor.
- **Flutter ↔ web metin eşitliği tek yönlü.** `landing-esitlik-contract.test.ts`
  web geride kalırsa yakalar, Flutter geride kalırsa yakalamaz.
- **Keşfet sayfasının iki taraf arasındaki eşitliğine hiç bakılmadı.**

**Doğru desen ise aynı depoda mevcut:** kategoriler
`shared/business_categories.json` tek kaynağından gelir — Flutter kodu ondan
üretilir, web doğrudan okur, CI her koşumda tazeliği kanıtlar. Yeni ortak
veri eklerken bu deseni izleyin, elle kopyalamayın.

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

## 🧭 Vixrex'te Çalışmaya Başlarken

Yeni geliştirici veya ajan için sıra:

1. **`VIXREX_RULES.md`** — değişmez mimari kurallar, kanıt seviyeleri, yetki
   sınırları. **Kural kaynağı burasıdır**; bu README kural üretmez, kurala
   yönlendirir.
2. **`AGENTS.md`** — ajan çalışma akışı ve PR disiplini.
3. **`CONTEXT.md`** — ürün hedefi ve güncel durum notları.
4. Bu README — mimari rehber ve kurulum.

Sonra: değiştireceğin akışı **koddan takip et** (giriş noktası → controller →
service/repository → Supabase → ekran). README ile kod çelişirse **kodu esas
al** ve README'deki tutarsızlığı bildir.

Aynı anda birden fazla ajan çalıştırılıyorsa **her biri ayrı çalışma alanında**
olmalı: aynı klasörde dal değiştiren iki ajan birbirinin kaydedilmemiş işini
siler. Bu 2026-08-26'da yaşandı.

---

## 📄 Lisans

Bu proje özel mülkiyete tabidir. Tüm hakları saklıdır.

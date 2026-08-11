# VixRex teknik depo haritası

Bu belge modelden bağımsız teknik başvuru kaynağıdır. Ajan başlangıcı ve yetki sınırları `AGENTS.md`, ürün/güvenlik kuralları `VIXREX_RULES.md`, aktif iş kapsamı ise ilgili GitHub issue’sundadır.

## Yerel komutlar

### Flutter paneli (`lib/`)

Ortam değişkenleri `--dart-define` ile geçer; yerelde git’e alınmayan `dart_defines.local.json` gerekir (`dart_defines.example.json` örnektir).

```powershell
.\dev.ps1          # Flutter :5000 + Next.js :3000
.\run.ps1          # Yalnız Flutter Web
.\run.ps1 windows  # Windows hedefi
```

`dev.ps1`, yerel çalışma için `PUBLIC_SITE_URL` değerini dosyada değiştirebilir; çalışma sonunda gizli ayar dosyasının yanlışlıkla paylaşılmadığı doğrulanır.

```bash
flutter pub get
dart analyze
dart format lib test
flutter gen-l10n
flutter test
flutter test test/product_test.dart
flutter test --plain-name "yayınlanmış vitrin"
flutter build web --release --dart-define-from-file=dart_defines.local.json
```

### Next.js müşteri vitrini (`public_web/`)

`public_web/.env.local` içinde `NEXT_PUBLIC_SUPABASE_URL` ve `NEXT_PUBLIC_SUPABASE_ANON_KEY` gerekir.

```bash
cd public_web
npm install
npm run dev
npm run lint
npm run build
npm run test
npx vitest run tests/api/instagram/status.test.ts
```

### CI

- `.github/workflows/kalite-kapilari.yml`: her PR'da korunan testleri, migration zincirini ve CI yüzey sınıflandırma testini çalıştırır.
- `.github/workflows/ci.yml`: değişen dosyaları sınıflandırır; Flutter, şema ve Next.js full suite'lerini yalnız etkilenen yüzeyde çalıştırır. Bilinmeyen path bütün yüzeyleri açar.
- `.github/workflows/android-apk.yml`: elle başlatılan analyze/sözleşme testi ve imzalı APK/AAB üretimi. Yeni zorunlu sözleşme testi eklendiğinde bu workflow’un açık test listesi de incelenir.
- Yerel kanıt görevin kapsamına göre alınır; CI bağımsız son kontroldür.

## İki yüzey, tek veri kaynağı

```text
lib/         → Flutter işletme paneli (Web :5000 + Android), Vercel: vixrex-app
public_web/  → Next.js müşteri vitrini /v/:slug, Vercel: vixrex-public
supabase/    → PostgreSQL + Auth + Storage + Edge Functions
```

İki Vercel projesi ayrı yayınlanır ve ayrı doğrulanır.

## Tek vitrin renderer’ı

Müşteri vitrini ve sahip önizlemesi yalnız Next.js `public_web` içindeki gerçek `/v/:slug` şablonundan gelir. Flutter veriyi düzenler, Supabase’e yazar ve Next.js bağlantısını açar; ikinci bir vitrin görünümü çizmez.

Bu sözleşmenin başlıca kilitleri:

- `lib/config/app_router.dart`: `/v/*` rotaları `PublicSiteRedirectScreen` üzerinden gider.
- `vercel.json`: vitrin, sitemap ve robots istekleri `vixrex-public` projesine yönlenir.
- `test/architecture_routing_contract_test.dart`: yönlendirme kararını ve eski SEO handler’larının yokluğunu doğrular.

Bu kararın yeniden açılması kullanıcının açık isteğini gerektirir.

## Taslak önizleme

1. Flutter `StoreEditorController.previewDraftLink()` ile taslağı `save_store_draft_with_token` RPC’sine yazar.
2. `PublicSiteConfig.buildVitrinPreviewLink` `/v/{slug}?preview_token={token}` bağlantısını üretir.
3. Next.js, `preview_token` olduğunda `get_store_preview`; normal istekte yayınlı `stores` verisini okur.

`StoreEditorController.openOwnerPreview()` taslak/yayın ayrımının tek sahibidir. Ekranlar bu kararı tekrar etmez. Next.js sayfası arama parametresi okuduğu için dinamik çalışır; veri sorgusunun kendi önbellek sözleşmesi ayrıca korunur.

## Flutter katmanları

```text
screens/      → sayfalar ve ekran bölümleri
controllers/  → ChangeNotifier tabanlı ekran durumu
services/     → iş mantığı ve dış servis adaptörleri
repositories/ → soyut veri erişimi + Supabase uygulamaları
models/       → veri sınıfları
config/       → router, public site ve kategori ayarları
core/         → Result<T> ve Supabase hata eşlemesi
```

Servis ve repository katmanları exception yaymak yerine `Result<T>` ile başarı/hata taşır. Ekran gezinmesi `AppRouter` yardımcıları üzerinden yapılır; `context.go` başarısız olduğunda kullanılan `Navigator` fallback’i izole widget testleri içindir.

Mimari büyüme sınırları ve yeni modül sahipliği `AGENTS.md` içinde zorunlu sözleşmedir.

## Sözleşme testleri

`test/**/*_contract_test.dart` ve `public_web/tests/*-contract.test.ts` dosyaları kaynak metni okuyarak mimari kararları koruyabilir. Böyle bir test kırıldığında varsayılan hareket testi gevşetmek değil, koruduğu kararın neden ihlal edildiğini incelemektir.

## Supabase

- Şema değişikliği yalnız `supabase/migrations/` altında yeni, sürümlü migration ile yapılır; uygulanmış migration değiştirilmez.
- İstemciden erişilen public tablolarda RLS açık olmalıdır.
- Yetkili yazma yolları `SECURITY DEFINER` kullanıyorsa `SET search_path = ''` ile sınırlandırılır.
- `DROP`, kolon türü, toplu `UPDATE/DELETE`, constraint ve RLS değişikliklerinde `VIXREX_RULES.md` onay/yedek/geri dönüş sınırları geçerlidir.
- `service_role` hiçbir zaman istemciye gönderilmez; Next.js’te yalnız server-only katmanda tutulur.

## Sık tuzaklar

- `vercel-build.sh`, geçmişteki bayat Flutter build olayını yakalamak için yasaklı eski işaretleri denetler.
- Kök `*_vitrin*.html`, `design_mockups/` ve benzeri dosyalar tasarım referansıdır; production vitrini değildir.
- `.scratch/`, `scratch/` ve araştırma klasörleri kanıt/çalışma alanıdır; kendi başına production davranışı sayılmaz.
- Aktif görevler GitHub Issues içindedir. Issue kullanımı `docs/agents/issue-tracker.md`, etiketler `docs/agents/triage-labels.md` içindedir.

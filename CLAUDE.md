# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Başlangıç sırası (zorunlu)

Bu depoda her ajan, herhangi bir işlemden önce `AGENTS.md` içindeki sırayı uygular: `VIXREX_RULES.md` → `.agents/skills/ask-matt/SKILL.md` (skill haritası) → göreve uyan skill → varsa `implementation_plan.md` → sonra kod.

@AGENTS.md

Kullanıcıyla iletişim Türkçe ve sadedir (`VIXREX_RULES.md` §2). Sonuç önce söylenir: "hazır", "hazır değil", "test edilmedi" veya "canlıda doğrulandı". Bir özellik için yalnızca ulaşılan kanıt seviyesi (§5) söylenir — "kodda var", "çalışıyor" demek değildir.

---

## Komutlar

### Flutter paneli (`lib/`)

Ortam değişkenleri `--dart-define` ile geçer; `dart_defines.local.json` gerekir (`dart_defines.example.json`'dan kopyalanır).

```powershell
.\dev.ps1          # Panel :5000 + Next.js vitrin :3000 birlikte (yerel geliştirme)
.\run.ps1          # Yalnız Flutter (chrome, :5000)
.\run.ps1 windows  # Masaüstü hedefi
```

`dev.ps1`, `dart_defines.local.json` içindeki `PUBLIC_SITE_URL` alanını `http://localhost:3000` olarak **dosyada üzerine yazar** — yerelde çalıştıktan sonra bu dosya kirli kalır, canlı adrese dönmek için geri düzeltilmelidir.

```bash
flutter pub get
dart analyze                      # hatasız olmalı (CI kapısı)
dart format lib test              # değişen production dosyaları formatlanır
flutter gen-l10n                  # lib/l10n/app_tr.arb değiştiyse
flutter test                      # tüm testler
flutter test test/product_test.dart                  # tek dosya
flutter test --plain-name "yayınlanmış vitrin"       # tek test
flutter build web --release --dart-define-from-file=dart_defines.local.json
```

### Next.js müşteri vitrini (`public_web/`)

`public_web/.env.local` gerekir (`NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`).

```bash
cd public_web
npm install
npm run dev                       # :3000
npm run lint                      # CI kapısı (public-web-lint.yml)
npm run build                     # production yayını öncesi zorunlu
npm run test                      # vitest run
npx vitest run tests/api/instagram/status.test.ts   # tek dosya
```

### CI

- `.github/workflows/public-web-lint.yml` — `public_web/**` değişince ESLint.
- `.github/workflows/android-apk.yml` — yalnız `workflow_dispatch`. `dart analyze` + adı adı sayılmış bir sözleşme testi listesi çalıştırır, sonra imzalı APK/AAB üretir. **Yeni bir sözleşme testi eklendiğinde bu listeye de eklenmelidir**, aksi halde CI'da hiç çalışmaz.
- `flutter test` bütünüyle CI'da koşmuyor — yerelde koşturmak sizin sorumluluğunuz.

---

## Mimari

### İki yüzey, tek veri kaynağı

```
lib/         → Flutter işletme paneli (Web :5000 + Android). Vercel projesi: vixrex-app
public_web/  → Next.js müşteri vitrini /v/:slug.        Vercel projesi: vixrex-public
supabase/    → PostgreSQL + Auth + Storage + Edge Functions (ortak veri katmanı)
```

İki Vercel projesi **ayrı deploy olur ve ayrı sonuç verir**. Birinin başarılı olması diğeri hakkında hiçbir şey söylemez.

### Değişmez kural — vitrin görünümünü yalnızca Next.js render eder

Flutter, müşterinin veya esnafın göreceği vitrin/önizleme sayfasını **kendi başına asla çizmez**. Esnafın "Önizle" ihtiyacı dahil her görünüm `public_web`'in gerçek `/v/:slug` şablonundan gelir. Flutter yalnızca: veriyi düzenler → Supabase'e yazar → Next.js linkini açar.

Bu kural 2026-08-03'te, aylarca süren Flutter/Next.js vitrin tekrarı karmaşasından sonra kesinleşti. Kod tarafında üç yerden birden kilitlenmiştir:

- `lib/config/app_router.dart` — bütün `/v/*` rotaları yalnızca `PublicSiteRedirectScreen`'e gider.
- `vercel.json` — `/v/:path*`, `/sitemap.xml`, `/robots.txt` → `vixrex-public.vercel.app` redirect.
- `test/architecture_routing_contract_test.dart` — yukarıdakileri sözleşme olarak doğrular; `api/v/[slug].js` gibi eski SEO handler'larının var olmadığını da kontrol eder.

Yeniden açılması kullanıcının açık isteğini gerektirir.

### Taslak önizleme akışı (preview_token)

Yayınlanmamış bir vitrini sahibine göstermenin tek yolu budur:

1. Flutter, `StoreEditorController.previewDraftLink()` → `save_store_draft_with_token(slug, edit_token, store)` RPC'siyle taslağı Supabase'e yazar.
2. `PublicSiteConfig.buildVitrinPreviewLink(slug, editToken)` → `/v/{slug}?preview_token={token}` linkini üretir.
3. Next.js `public_web/src/app/v/[slug]/page.tsx`, `preview_token` varsa `get_store_preview` RPC'siyle veriyi çeker — yayınlı satırlar normal `stores` sorgusundan gelir.

`StoreEditorController.openOwnerPreview()` taslak/yayın ayrımının **tek** sahibidir; ekranlar bu dallanmayı kendileri yapmaz (`test/owner_preview_baseline_contract_test.dart` bunu kilitler).

`page.tsx` `export const dynamic = "force-dynamic"` kullanır: `generateStaticParams` yalnız yayınlı slug'ları üretiyor ama route `searchParams` okuyor — ikisi birlikte statik modda `DYNAMIC_SERVER_USAGE` ile çöküyordu (canlıda doğrulandı). Veri sorgusu ayrıca `unstable_cache` ile 60 sn önbellekli.

### Flutter katmanları

```
screens/      → sayfa (25 dosya). Büyük ekranlar my_vitrin/ gibi sections/ alt klasörüne bölünür.
controllers/  → ChangeNotifier tabanlı ekran durumu. Büyükleri mixins/ ile parçalanır.
services/     → iş mantığı (60 dosya): yayınlama, OCR, Excel/XML aktarımı, Instagram, SEO, push.
repositories/ → veri erişimi. Her biri soyut arayüz + supabase_* implementasyonu çifti (repositories.dart barrel).
models/       → veri sınıfları (StoreData, Product, …)
config/       → app_router.dart, public_site_config.dart, business_category_config.dart, feature flag'ler
core/         → Result<T> ve supabase_error_mapper.dart
```

Servis ve repository katmanı `Result<T>` (`lib/core/result.dart`) döndürür — `isSuccess`/`isFailure` veya `when(success:, failure:)`. Exception fırlatmak yerine `Failure` taşınır; Supabase `PostgrestException`'ları `supabase_error_mapper.dart` içinde çevrilir.

Ekranlar `AppRouter`'ın statik yardımcılarıyla gezinir. Bunlar `context.go(...)` dener, `catch` içinde düz `Navigator`'a düşer — bu fallback izole widget testleri içindir, kaldırmayın.

### Mimari büyüme yasağı

400 satırı veya 20 dışa açık üyeyi geçen bir controller/modüle **yeni özellik veya sorumluluk eklenmez**; önce ayrı sahip modül ve küçük arayüz oluşturulur. Kodu mixin/extension'a taşımak tek başına refaktör sayılmaz — state, bağımlılık ve test seam'i gerçekten ayrılmalıdır. Zorunlu hata düzeltmesi büyük modülde yapılabilir, fakat dış arayüz büyütülemez. (`AGENTS.md`)

Şu an sınırın üstündekiler: `store_editor_controller.dart` (~1126), `vitrin_form_section.dart` (~1252), `bulk_product_upload_screen.dart` (~993), `home_shell_screen.dart` (~946).

### Sözleşme testleri

`test/` içinde `*_contract_test.dart` dosyaları normal birim testi değildir: **kaynak dosyayı metin olarak okuyup** belirli bir mimari kararın hâlâ geçerli olduğunu doğrularlar (ör. bir ekranın `isLive` dallanması içermemesi, `vercel.json`'ın doğru redirect'leri taşıması, APK workflow'unun beklenen adımları içermesi). Bunlardan biri kırıldığında düzeltilecek şey genellikle test değil, koruduğu karardır. Aynı yaklaşım `public_web/tests/*-contract.test.ts` içinde de kullanılır.

### Supabase

- Şema değişikliği yalnızca `supabase/migrations/` altında sürümlü migration ile. Uygulanmış migration sonradan **değiştirilmez**; düzeltme için yeni migration yazılır (bkz. `20260803190314_..._fix_draft_preview_rpc_and_demo_links.sql`).
- İstemciden erişilen `public` tablolarında RLS açık olmalı; yazma yolları `SECURITY DEFINER` + `SET search_path = ''` RPC'lerinden geçer.
- `DROP`, kolon türü değiştirme, toplu `UPDATE/DELETE`, constraint ve RLS değişiklikleri açık onay ister.
- Edge Functions: `supabase/functions/send-booking-push`, `supabase/functions/vixrex-assistant-nlu`.
- `service_role` anahtarı istemciye konmaz — Next.js tarafında yalnızca `src/lib/supabaseAdmin.ts` (server-only) kullanır.

---

## Dikkat edilecek noktalar

- **Yayın derlemesi bayat kalabiliyor:** `vercel-build.sh` derleme sonrası `main.dart.js` içinde `showScoreCard` arar ve bulursa build'i düşürür. Bu, geçmişte yaşanmış bir bayat-build olayına karşı konmuş bir bekçidir.
- **Kök dizindeki `*_vitrin*.html` ve `design_mockups/`** tasarım referansıdır, uygulama kodu değil — bunları düzenlemek canlı vitrini değiştirmez.
- **Issue takibi** GitHub issues üzerinden `gh` CLI ile (`docs/agents/issue-tracker.md`), triage etiketleri `docs/agents/triage-labels.md`.
- `.scratch/`, `scratch/`, `research/` geçici çalışma alanlarıdır; production özelliği sayılmaz.

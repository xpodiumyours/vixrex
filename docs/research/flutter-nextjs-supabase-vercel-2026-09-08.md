# Vixrex Kurtarma Araştırması — Resmi Doküman Özeti (2026-09-08)

Amaç: Web + mobil uygulamayı mevcut çalışan yapı korunarak profesyonel yapı, görünüm ve çalışma akışına kavuşturmak.
Kural: Tahmin, varsayım, yorum yok. Aşağıdaki her madde resmi dokümanda yazana dayanır.
Sıra: Flutter → Next.js → Supabase → Vercel. Kapsam büyütülmedi, daraltılmadı.
Kullanım: Bu dosya kurtarma operasyonunun veri kaynağıdır. Kod değişikliği bu dosyadaki kanıtlara dayanır.

Vixrex mimarisi (repo içi факт, `C:\Projects\vixrex\CLAUDE.md` madde 35-42):
- `lib/` Flutter yönetim paneli, `vixrex-app` olarak yayınlanır.
- `public_web/` Next.js vitrin sitesi, `vixrex-public` olarak yayınlanır.
- `shared/` iki istemcinin okuduğu tek şema kaynağıdır.
- `supabase/migrations/` canlı şemanın tek değişim yoludur.

---

## 1. Flutter (docs.flutter.dev)

Kaynak kök: `https://docs.flutter.dev/`

### 1.1. UI katmanı ile veri katmanını ayır
Doküman: `https://docs.flutter.dev/app-architecture/guide`
Alıntı: "Your Flutter application should split into two broad layers, the UI layer and the Data layer."
Alıntı: "Views and view models should have a one-to-one relationship."
Vixrex karşılığı: `lib/` içindeki ekran + ViewModel ikilileri bu kurala göre denetlenir. Vitrin düzenleme formu (`VitrinFormSection`, 5 akordeon — bkz `docs/tek-kaynak-gecis.md` F0) bir View, verisi ViewModel'den gelir.
Kurtarma notu: Ekrana iş mantığı gömülmez, veri Repository'den akar.

### 1.2. Tek doğruluk kaynağı Repository'dir
Doküman: aynı guide.
Alıntı: "Repository classes are the source of truth for your model data."
Alıntı: "Repositories should never be aware of each other."
Alıntı: "Services are in the lowest layer of your application. They wrap API endpoints ... one service class per data source."
Vixrex karşılığı: Supabase'e giden tek servis + tip başına Repository. `lib/services/` altında dağınık Supabase çağrısı varsa tek Repository arkasına toplanır. Mevcut çalışan servis silinmez, taşınır.

### 1.3. Tek yönlü veri akışı + değişmez model
Doküman: `https://docs.flutter.dev/app-architecture/concepts` ve `/recommendations`
Alıntı: "Data changes always happen in the SSOT, which is the data layer."
Alıntı: "Use unidirectional data flow. Strongly recommend" / "Use immutable data models. Strongly recommend"
Vixrex karşılığı: `store_working_drafts.draft_data` JSONB yazımı yalnızca data katmanından yapılır, ekrandan doğrudan yazılmaz.

### 1.4. Önerilen paketler
Doküman: `https://docs.flutter.dev/app-architecture/recommendations`
Alıntı: "We recommend you use the provider package to handle dependency injection."
Alıntı: "Use go_router for navigation. Go_router is the preferred way to write 90% of Flutter applications."
Vixrex karşılığı: `pubspec.yaml` içinde `go_router: ^14.3.0` zaten var. Korunur. Yeni yönlendirme eklenmez, mevcut yapı denetlenir.

### 1.5. Uyarlanabilir + duyarlı tasarım
Doküman: `https://docs.flutter.dev/ui/adaptive-responsive`
Alıntı: "responsive design is about fitting the UI into the space and adaptive design is about the UI being usable in the space."
Alt başlıklar: `SafeArea & MediaQuery`, `Large screens & foldables`, `Automatic platform adaptations`, `Best practices`
Vixrex karşılığı: Aynı Flutter kodunun Web + Android'de çalışması bu başlıklara göre elden geçer. Özel ekran dalı açılmadan `MediaQuery`/`SafeArea` ile düzeltilir.

### 1.6. Supabase Flutter başlatma
Doküman: `https://supabase.com/docs/guides/getting-started/quickstarts/flutter`
Alıntı: `supabase_flutter: ^2.0.0` + `await Supabase.initialize(url, publishableKey)`
Alıntı: "Mobile apps don't get environment variables injected at runtime the way a bundler-based web app does. You'd need a build-time mechanism such as `--dart-define-from-file` for Flutter"
Alıntı: "If your app reads or writes through the Data API, review your Row Level Security policies."
Vixrex karşılığı: `pubspec.yaml` içinde `supabase_flutter: ^2.12.4` var. `vercel-build.sh` + `dart_defines.local.json` düzeni korunur. Anahtar koda gömülmez.

### 1.7. Sohbetli asistan (mobil)
Doküman: `https://docs.flutter.dev/ai/ai-toolkit`
Alıntı: "The AI Toolkit is a set of AI chat-related widgets ... organized around an abstract LLM provider API"
Özellikler: `Multiturn chat`, `Streaming responses`, `Function calling: Supports tool calls`, `Cross-platform support: Android, iOS, web, macOS`
Vixrex karşılığı: Mobil tarafta asistan kutusu bu widget setine göre yapılır. Gerçek asistan `public_web` içindedir (CLAUDE.md madde 50: ana sayfadaki telefon mockup'ı çalışmaz, dokunulmaz).

---

## 2. Next.js (nextjs.org/docs)

Kaynak kök: `https://nextjs.org/docs`

### 2.1. Veri çekme + önbellek + akış
Doküman: `https://nextjs.org/docs/app/getting-started/fetching-data`
Alıntı: "Identical `fetch` requests in a React component tree are memoized by default"
Alıntı: "`fetch` requests are not cached by default"
Alıntı: "Use the `use cache` directive to cache results, or wrap the fetching component in `<Suspense>` to stream"
Vixrex karşılığı: `public_web/` içinde `/v/[slug]` vitrin sayfası bu kurala göre denetlenir. Yavaş sorgu tüm sayfayı kilitlemez, `loading.js` / `Suspense` ile bölünür.

### 2.2. Veri erişim katmanı (DAL)
Doküman: `https://nextjs.org/docs/app/guides/data-security`
Alıntı: "For new projects, we recommend creating a dedicated Data Access Layer (DAL)."
Alıntı: "A Data Access Layer should: Only run on the server. Perform authorization checks. Return safe, minimal Data Transfer Objects (DTOs)."
Alıntı: "Secret keys should be stored in environment variables, but only the Data Access Layer should access `process.env`."
Alıntı: "To prevent server-only code from being executed on the client, mark a module with the `server-only` package: `import 'server-only'`"
Vixrex karşılığı: `public_web/src/lib/` içindeki Supabase okuma/yazma bu katmanda toplanır. Ham satır Client Component'e geçirilmez. Dokümanın `EXPOSED` / `BAD` dediği kalıp düzeltilir.

### 2.3. Server Action güvenliği
Doküman: aynı data-security sayfası.
Alıntı: "Always re-verify inside the action"
Alıntı: "Only return what the UI needs, not raw database records."
Alıntı: "A page-level authentication check does not extend to the Server Actions defined within it."
Vixrex karşılığı: `OwnerWorkspaceShell` / `OwnerAssistantPanel` içinden yapılan güncelleme her Action içinde yeniden yetki denetler. Sayfa koruması yeterli sayılmaz.

### 2.4. Ortam değişkeni öneki
Doküman: aynı sayfa + `https://nextjs.org/docs/app/guides/environment-variables`
Alıntı: "By default, environment variables are only available on the Server. Next.js exposes any environment variable prefixed with `NEXT_PUBLIC_` to the client."
Vixrex karşılığı: `public_web/src/lib/supabase.ts` içinde `SUPABASE_URL` / `SUPABASE_PUBLISHABLE_KEY` öncelikli, `NEXT_PUBLIC_` yedek olarak okunur (dosyada satır 3-12). Bu sıra korunur. `SUPABASE_SERVICE_ROLE_KEY` hiçbir zaman `NEXT_PUBLIC_` olmaz (CLAUDE.md madde 115).

### 2.5. Çok kiracılı vitrin
Doküman: `https://nextjs.org/docs/app/guides/multi-tenant`
Alıntı: "If you are looking to build a single Next.js application that serves multiple tenants, we have built an example showing our recommended architecture."
Vixrex karşılığı: Tek Next.js uygulamasından `/v/[slug]` ile çok vitrin sunma bu örneğe göre denetlenir. Hesap başına tek vitrin kuralı DB'de partial unique index ile zaten var (CLAUDE.md madde 51: `ALREADY_OWNS_STORE` hata değil, beklenen davranış).

### 2.6. Denetim listesi
Doküman: data-security sayfası `Auditing` bölümü.
Alıntı: Denetlenecekler: `Data Access Layer`, `"use client" files`, `"use server" files`, `/[param]/`, `proxy.ts and route.ts`
Vixrex karşılığı: Kurtarma öncesi bu 5 noktaya bakılır, başka alan taranmaz.

---

## 3. Supabase (supabase.com/docs)

Kaynak kök: `https://supabase.com/docs`

### 3.1. RLS her tabloda zorunlu
Doküman: `https://supabase.com/docs/guides/database/postgres/row-level-security`
Alıntı: "Danger: A table in an exposed schema without RLS is readable and writable by any role with a grant on it. Enable RLS on every table in an exposed schema."
Alıntı: "Postgres runs two checks before a client touches a table. Grants decide whether a role can run an operation on the table at all. Policies decide which rows that operation applies to. Set both for every table you expose."
Vixrex karşılığı: `supabase/migrations/` içindeki her `public` tablosu bu kurala göre denetlenir. Canlı şema el ile değil migration ile değişir (CLAUDE.md madde 42).

### 3.2. İşlem başına ayrı politika
Doküman: aynı RLS sayfası.
Alıntı: "Write a separate policy for `select`, `insert`, `update`, and `delete`."
Alıntı: "Always name the role a policy applies to, using the `to` clause."
Alıntı: "To perform an `UPDATE` operation, a corresponding `SELECT` policy is required."
Alıntı performans: `using ( (select auth.uid()) = user_id )` + "Add an index on every column your policies filter on."
Vixrex karşılığı: `stores` (sahiplik), `store_working_drafts` (taslak), `assistant_conversations/messages` (konuşma) politikaları bu kalıpla yazılır.

### 3.3. View güvenliği
Doküman: aynı sayfa.
Alıntı: "create view <VIEW_NAME> with(security_invoker = true) as select <QUERY>"
Vixrex karşılığı: `PUBLIC_STORE_SELECT` gibi herkese açık vitrin view'ı bu bayrakla denetlenir.

### 3.4. Politika testi
Doküman: aynı sayfa.
Alıntı: "Create them with `supabase test new <table>_rls.test`, and run them with `supabase test db`."
Alıntı: "Until the suite passes, you don't know whether the policies do what you intended."
Vixrex karşılığı: `supabase/tests/` altında tablo başına test dosyası. CI'daki `grant-guard` işi ayrıca `anon`/`authenticated` rollerinde TRUNCATE/MAINTAIN/REFERENCES/TRIGGER olmadığını doğrular (CLAUDE.md madde 107).

### 3.5. SSR istemci ayrımı
Doküman: `https://supabase.com/docs/guides/auth/server-side/creating-client` ve Next.js alt sayfası.
Alıntı: "You need 2 types of Supabase clients: Client Component client ... Server Component client ..."
Alıntı: "Since Next.js Server Components can't write cookies, you need a Proxy to refresh expired Auth tokens"
Alıntı: "Always use `supabase.auth.getClaims()` to protect pages and user data."
Alıntı: "Never trust `supabase.auth.getSession()` inside server code"
Alıntı: "If your app uses ISR or is deployed behind a CDN, caching of HTTP responses can cause users to receive another user's session."
Vixrex karşılığı: Owner önizleme oturumu (`owner-session` → RPC → HMAC HttpOnly cookie, `public_web/src/lib/ownerSession.ts`) bu kurala göre denetlenir. Zincirin bir halkası bozuksa kapalı kalır (fail closed).

### 3.6. Gizli anahtar
Doküman: `https://supabase.com/docs/guides/getting-started/api-keys` + RLS sayfası.
Alıntı: "Never use a secret key in the browser or expose it to customers."
Alıntı: "A secret key bypasses RLS only when the request carries no user access token."
Vixrex karşılığı: `service_role` yalnızca sunucuda. Tarayıcıya düşmez.

### 3.7. Asistan için AI araçları
Doküman: `https://supabase.com/docs/guides/ai`, `https://supabase.com/docs/guides/functions`, `https://supabase.com/docs/guides/database/extensions/pgvector`
Alıntı: "Supabase provides an open source toolkit for developing AI applications using Postgres and pgvector."
Alıntı: "Runtime: Supabase Edge Runtime (Deno compatible runtime with TypeScript first)."
Alıntı operatörler: `<->`, `<#>`, `<=>`, RPC ile çağrılır.
Vixrex karşılığı: `supabase/functions/` içindeki asistan işleri bu çalışma zamanına göre yazılır. Vitrin güncelleme yazmaları RLS + JWT doğrulamasıyla yapılır.

### 3.8. AI ile çalışma komutları
Doküman: `https://supabase.com/docs/guides/getting-started/quickstarts/flutter` madde 4 + `https://supabase.com/docs/guides/ai-tools/mcp`
Alıntı: `npx skills add supabase/agent-skills`
Vixrex karşılığı: AI ajanı bu skill + MCP ile şemaya bakar. Eğitim verisine dayanarak tablo uydurmaz.

---

## 4. Vercel (vercel.com/docs)

Kaynak kök: `https://vercel.com/docs`

### 4.1. Next.js'in doğal platformu
Doküman: `https://vercel.com/docs/frameworks/full-stack/nextjs`
Alıntı: "Vercel is the native Next.js platform"
Vixrex karşılığı: İki ayrı Vercel projesi korunur: `vixrex-app` (Flutter web) ve `vixrex-public` (Next.js). Biri yeşil diye diğeri yeşil sayılmaz (CLAUDE.md madde 44).

### 4.2. Ortam değişkeni değişimi yeni dağıtımda geçerli olur
Doküman: `https://vercel.com/docs/environment-variables` + `https://vercel.com/kb/guide/how-to-add-vercel-environment-variables`
Alıntı: "Each deployment is an immutable artifact."
Alıntı: "Whichever method you use, the change takes effect on your next deployment, not on the deployment that's already live."
Alıntı: "`NEXT_PUBLIC_` variables ... Next.js inlines them at build time"
Limit: "64 KB in Environment Variables per-Deployment", "Each environment in a project can hold up to 1,000 environment variables"
Vixrex karşılığı: Panelde değişken değiştirip "neden olmadı" denmez, yeniden deploy gerekir. `NEXT_PUBLIC_` değerleri gömülü olduğu için runtime'da değişmez.

### 4.3. Üç ortam
Doküman: `https://vercel.com/docs/deployments/environments`
Alıntı ortamlar: `Local Development`, `Preview`, `Production`
Alıntı komutlar: `vercel link`, `vercel env pull` (`.env.local` dosyasını doldurur)
Vixrex karşılığı: Kök `vercel.json` Flutter projesini, `public_web/vercel.json` Next.js projesini yönetir. Her birinde `ignoreCommand` yol filtresi var, korunur.

### 4.4. Güvenlik başlıkları + önbellek
Vixrex fact (kod içi, `C:\Projects\vixrex\vercel.json` satır 6-68): `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`, `Referrer-Policy`, `HSTS`, `X-Robots-Tag: noindex`, `main.dart.js` / `flutter_bootstrap.js` için `Cache-Control: no-store`
Kural: Bu başlıklar dokümandaki immutable deployment mantığıyla birlikte korunur. Kaldırılmaz.

### 4.5. AI SDK (web asistanı)
Doküman: `https://vercel.com/docs/ai-sdk` + `https://ai-sdk.dev/docs/introduction`
Alıntı: "Build TypeScript agents and AI applications with one API for models, tools, structured output, and streaming"
Alıntı: "Unified API for generating text, structured objects, and tool calls" + "Hooks for building dynamic chat"
Alıntı: `import { generateText } from 'ai'`
Vixrex karşılığı: Webdeki `OwnerAssistantPanel` sohbet kutusu bu SDK'ya göre yapılır. Flutter tarafı ayrı SDK kullanmaz, aynı Supabase kaydına yazar.

---

## 5. Ortak veri kaynağı + kurtarma ilkeleri (mevcut yapı korunarak)

Üç dokümanın aynı cümlede buluştuğu yer:
- Flutter: "Repository classes are the source of truth" (`docs.flutter.dev/app-architecture/guide`)
- Next.js: "This approach centralizes all data access logic" — DAL (`nextjs.org/docs/app/guides/data-security`)
- Supabase: "Think of a policy as adding a WHERE clause to every query." (`supabase.com/docs/guides/database/postgres/row-level-security`)

Vixrex'te tek kaynak zaten bellidir, değiştirilmez:
- Şema: `shared/vitrin_alanlari.json` (46 alan, 6 zorunlu — F0 freeze, `docs/tek-kaynak-gecis.md`)
- Sahiplik: `stores`, taslak: `store_working_drafts`, akış: `owner_flow_states`, konuşma: `assistant_conversations/messages`
- Üretim kodu bu dosyalardan üretilir, elle kopyalanmaz: `tool/sema_disa_aktar.ts` + `tool/alan_semasi_uret.dart` (CI `schema-drift` işi denetler).

Kurtarma sırasında korunacaklar (repo içi fact):
- Vitrin sayfası yalnızca Next.js çizer, Flutter yeniden çizmez (`CLAUDE.md` madde 48).
- İki düzenleyici aynı taslağa yazar: Flutter formu + `OwnerWorkspaceShell` asistanı (madde 49).
- Bilinen borç kopyalanmaz: fiyatın ~10 yerde sabit yazılması, renklerin çift tutulması (madde 55-56). Yeni işte `shared/business_categories.json` örneğindeki üretilmiş-dosya kalıbı izlenir (madde 61).
- Şema değişimi yalnızca `supabase/migrations/` ile olur.
- Her görevde kapılar çalışır: Flutter `dart format / dart analyze --fatal-infos / flutter test`, web `npm run lint / npx tsc --noEmit / npm run test / npm run build` (CLAUDE.md Commands bölümü). Kapı geçmeden "bitti" denmez.
- İnsan onayı gerekenler: ödeme, auth/yetki, `firestore.rules` benzeri kural dosyaları, üretim deploy, şema migration. Plana yazılır, onay beklenir.

Kapsam dışı (bu dosyada yok, ayrı kuyrukta): Logo/GPS taşıma, modal → akordeon dönüşümü TODO(F2b), Instagram senkron bayrağı. Bkz `docs/tek-kaynak-gecis.md` F0 + Backlog.

---

## Kaynak listesi (tekrar erişim için)

- https://docs.flutter.dev/app-architecture/guide
- https://docs.flutter.dev/app-architecture/concepts
- https://docs.flutter.dev/app-architecture/recommendations
- https://docs.flutter.dev/ui/adaptive-responsive
- https://docs.flutter.dev/ai/ai-toolkit
- https://nextjs.org/docs/app/getting-started/fetching-data
- https://nextjs.org/docs/app/guides/data-security
- https://nextjs.org/docs/app/guides/multi-tenant
- https://supabase.com/docs/guides/database/postgres/row-level-security
- https://supabase.com/docs/guides/auth/server-side/creating-client
- https://supabase.com/docs/guides/getting-started/quickstarts/flutter
- https://supabase.com/docs/guides/getting-started/api-keys
- https://supabase.com/docs/guides/ai
- https://supabase.com/docs/guides/functions
- https://vercel.com/docs/frameworks/full-stack/nextjs
- https://vercel.com/docs/environment-variables
- https://vercel.com/docs/deployments/environments
- https://vercel.com/docs/ai-sdk

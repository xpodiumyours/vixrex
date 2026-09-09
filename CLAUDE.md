# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Çalışma kuralı — ÖNCE SOR (2026-09-03, Casper)

Bu repoda hiçbir adımı, hiçbir değişikliği Casper'a sormadan yapma —
küçük görünse bile. "Şunu düzelteyim mi", "bu iki seçenekten hangisi"
diye sor, cevabı bekle, sonra uygula. Bir düzeltmenin "doğru" göründüğü
sana değil ona ait bir karar.

Neden: 2026-09-03'te "Çalışma masası" ekranı bitmeden, onaylanmamış bir
düzeltmeyle akıllı motorun (serbest cümleden alan çıkaran motor) bir
parçası sessizce devre dışı bırakıldı ve doğrudan main'e alındı — Casper
canlıda fark etti, saatlerce token yakıldı, sonuç güvensizlik oldu. Bkz.
`~/.claude/projects/C--Users-Casper/memory/once-sor-onay-bekle.md`.

### Varsayım + tahmin + yorum yasağı (2026-09-09, Casper)

- **Varsayım yasak.** Emin olmadığın şeyi doğru gibi yazma. Bilmiyorsan "bilmiyorum" de, sor, bekle.
- **Tahminle iş yapma.** Koda bakmadan "şöyle olmalı" diye düzeltme, dosya ekleme, silme.
- **Kod içine hiç yorum satırı ekleme.** (`//`, `/* */`, `#`, `<!-- -->`, `--` gibi notlar yasak.) Eski yorumu da değiştirme, silme. Açıklama gerekiyorsa mesaja yaz.
- **Kanıt ver.** Hangi dosyaya baktıysan tam yol + satır numarası yaz. Bakmadıysan "bakmadım" de.

### Görsel/UI hatalarında: önce canlı doğrula, sonra "düzelttim" de (2026-09-03, Casper)

Bir UI/görsel hatayı (ekran görüntüsüyle bildirilen, "kutu kaymış",
"boşluk yanlış" tarzı) koda bakıp tahminle düzeltip commit etme. Önce
Browser pane / preview ile canlı aç, sorunu kendi gözünle gör, düzeltmeyi
uyguladıktan sonra AYNI şekilde tekrar bak ve doğrula — ancak öyle "düzelttim"
de. Canlı doğrulama gerçekten mümkün değilse (ör. sandbox'tan Supabase'e ağ
erişimi yok), bunu açıkça söyle ve Casper'dan ekran görüntüsü/canlı bakış
iste — kör tahminle "olması gerekir" diyerek commit atma.

Neden: Aynı gün içinde bu yüzden iki uzun oturum (807 ve 461 mesaj) büyük
ölçüde verimsiz soru-cevap döngüsüne girdi — biri kısmi/kozmetik bir
düzeltmeyi "tam çözmedi" itirafıyla sundu, diğeri ekran görüntüsünden
tahmin yürütüp hangi kutudan bahsedildiğini defalarca sordu. Canlı
doğrulama araçları (Browser pane) zaten mevcut; kullanılmaması gereksiz
tur ve token'a mal oluyor.

## What this repo is

VixRex — a platform that lets small businesses run a digital storefront (`vitrin`) without writing code. Two independently deployed apps share one Supabase (PostgreSQL) database:

- `lib/` — Flutter app (Web + Android): the business owner's management panel. Deploys as Vercel project `vixrex-app`.
- `public_web/` — Next.js (TypeScript, App Router): the public-facing site — homepage, `/kesfet` discovery pages, `/v/:slug` storefronts, and (in owner mode) the "Vixrex Asistan" click-to-edit panel. Deploys as Vercel project `vixrex-public`.
- `shared/` — single source of truth for data both clients read: `vitrin_alanlari.json` (editable storefront fields), `business_categories.json`, `vixrex_mesajlar.json` (message catalog), `working_hours_contract.json`. Flutter's `lib/config/*.g.dart` and public_web's TS equivalents are *generated* from these — never hand-edit the generated files.
- `supabase/` — versioned SQL migrations (`migrations/`), RLS policies, edge functions (`functions/`). The live schema changes only via migrations, never by hand in the dashboard.

The two Vercel projects are deployed and verified independently — one deploying successfully says nothing about the other.

### Key architectural facts worth knowing before touching code

- **The storefront view is rendered only by Next.js.** `/v/:slug` (customer view) and the owner's preview both come from the one template in `public_web`. Flutter never re-renders this page; it only edits data in Supabase and opens the Next.js link.
- **A storefront field has two editors** that must stay in sync: the Flutter manual form (bulk ops, OCR, offline), and "Vixrex Asistan" in `public_web` (click a field on the live page to edit it inline — `OwnerWorkspaceShell`, `OwnerAssistantPanel`). Both read the same `shared/vitrin_alanlari.json` schema and write the same draft.
- **The homepage assistant chat is a mockup.** It's fixed ad copy in a phone mockup graphic — not wired to any backend, and not meant to be. The real assistant only exists in the owner panel inside `public_web`. Don't "fix" the homepage one into a working chatbot.
- **One storefront per account**, enforced by a partial unique index at the DB level — a second rental returns `ALREADY_OWNS_STORE`, which is expected behavior, not a bug. New-device bootstrap goes through `bootstrap_owner_state()`.
- **"tek-kaynak" (single-source) migration in progress**: recent commits (`feat(tek-kaynak): ...`, `feat(db): PR1 tek-kaynak veritabani temeli`) are consolidating the owner/auth/draft flow onto one canonical path. If you're touching auth return flow, rental claiming, or working-draft continuity, check for the most recent `tek-kaynak-*` commits/tests first — this area is mid-refactor.
- **Owner preview session**: Flutter issues a one-time code → Next.js `owner-session` route exchanges it via Supabase RPC for a session token → token is HMAC-signed into an HttpOnly cookie (`public_web/src/lib/ownerSession.ts`). Any broken link in that chain must fail closed.

### Known architectural debt (don't copy this pattern)

- Price ("299 TL") is hardcoded in ~10 separate places across Flutter, web, and payment code — no single source yet.
- Colors are hand-duplicated: `lib/theme/app_colors.dart` (38 colors) vs `public_web/src/app/globals.css` `--color-lp-*` — nothing keeps them in sync.
- Flutter↔web landing text parity is checked one-directionally only (`landing-esitlik-contract.test.ts` catches web drifting from Flutter, not the reverse).

The *correct* pattern already in the repo: `shared/business_categories.json` is generated into Flutter, read directly by web, and CI proves freshness every run. Follow this shape for new cross-client data, don't hand-copy.

## Commands

### Flutter panel (`lib/`)

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test   # CI gate — must pass, not just `dart format`
dart analyze --fatal-infos
flutter test --reporter expanded                            # all tests
flutter test test/path/to/some_test.dart                    # single file
flutter build web --release --dart-define-from-file=dart_defines.local.json
```

Requires `dart_defines.local.json` locally (git-ignored; `dart_defines.example.json` is the template). `.\dev.ps1` runs Flutter on :5000 + Next.js on :3000 together; `.\run.ps1` runs Flutter alone.

### Next.js public site (`public_web/`)

```bash
cd public_web
npm install
npm run dev          # http://localhost:3000
npm run lint
npx tsc --noEmit      # type check (separate from lint in CI)
npm run test          # vitest run — tests/**/*.test.ts and src/**/*.test.ts
npx vitest run tests/some-file.test.ts   # single file
npm run build
npm run e2e:local     # Playwright against a local build
```

Playwright specs live in `public_web/e2e/*.spec.ts` (not `tests/` — vitest is configured to exclude `e2e/`). **Full E2E only runs in CI on push to `main`**, not on PRs — a green PR is not proof the real browser flow works, check the post-merge `main` run. Visual-regression baselines are OS-specific (`*-chromium-linux.png` vs `*-chromium-win32.png`); CI runs Linux, so a Windows-generated baseline won't turn CI green.

### Schema generation (must be re-run after editing `shared/*.json`)

```bash
cd public_web && npx tsx ../tool/sema_disa_aktar.ts
dart run tool/alan_semasi_uret.dart
dart run tool/business_categories_uret.dart
dart run tool/mesaj_semasi_uret.dart
dart format lib/config/vitrin_alanlari.g.dart lib/config/business_categories.g.dart lib/config/vixrex_mesajlar.g.dart
```
CI's `schema-drift` job re-runs this and fails the PR if the generated files don't match what's committed.

## CI (`.github/workflows/ci.yml`)

Path-classified: a `changes` job (`.github/scripts/changed_surfaces.py`) decides which of `flutter` / `schema` / `public_web` actually need to run; an unrecognized path conservatively runs everything. Jobs: `secret-tarama` (gitleaks), `auth-config-check` (Supabase leaked-password-protection config), `grant-guard` (spins up a local Supabase from the full migration chain and asserts `anon`/`authenticated` never hold TRUNCATE/MAINTAIN/REFERENCES/TRIGGER on any table — those are invisible to RLS), `flutter` (format/analyze/test), `schema-drift`, `public_web` (lint/typecheck/test/build), `public_web_e2e` (main-only, live site).

Note: `README.md`'s "Test ve Kalite Kapıları" table still describes a PR-scope/file-size/Supabase-access-ratchet gate (`verify_pr_scope.py` etc.) — those scripts and their CI job were deliberately removed (PR #394, 2026-08-31) along with `AGENTS.md`/`VIXREX_RULES.md`/`CONTEXT.md`/`docs/` and other agent-governance files, at the repo owner's explicit request, because prior agent sessions had been fabricating "user decided X" provenance in those files. Treat README as stale on that specific table; the `ci.yml` jobs listed above are the actual current gates. Don't recreate root-level rules/governance docs unilaterally — rediscover context from code + README, and build any new persistent docs together with the user rather than asserting them.

## Environment variables

Flutter reads via `--dart-define` (`String.fromEnvironment`): `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY` (required — build fails without them per `vercel-build.sh`), `PUBLIC_SITE_URL`, `ONESIGNAL_APP_ID`, `SENTRY_DSN`, `GOOGLE_WEB_CLIENT_ID`/`GOOGLE_IOS_CLIENT_ID`, `REVALIDATION_SECRET`, `INSTAGRAM_SYNC_ENABLED` (default `false` — Instagram import is code-complete but gated off pending Meta App Review).

`public_web/.env.local` (see `.env.example`): `SUPABASE_URL`/`SUPABASE_PUBLISHABLE_KEY` (client falls back to `NEXT_PUBLIC_SUPABASE_URL`/`NEXT_PUBLIC_SUPABASE_ANON_KEY` but the non-prefixed pair is authoritative — see `src/lib/supabase.ts`), `SUPABASE_SERVICE_ROLE_KEY` (server-only, never `NEXT_PUBLIC_`-prefixed), `OWNER_SESSION_SECRET` (≥32 chars, signs the owner preview cookie), `RATE_LIMIT_SECRET`, `REVALIDATION_SECRET`, `TURNSTILE_SECRET_KEY`/`RECAPTCHA_SECRET_KEY`, Instagram OAuth vars (unused while the sync flag is off).

## Deployment

Two separate Vercel projects, each with its own `ignoreCommand` gating on changed paths (`.github/scripts/changed_surfaces.py`): `vixrex-app` (root `vercel.json`, builds the Flutter web release via `vercel-build.sh`) and `vixrex-public` (`public_web/vercel.json`, `npm run build`). Root `vercel.json` redirects `/v/*`, `/sitemap.xml`, `/robots.txt` to the `vixrex-public` domain — the DB schema itself only changes through `supabase/migrations/`, never by hand on the dashboard.

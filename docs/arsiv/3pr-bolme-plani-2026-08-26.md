# 3 PR'a Bölme Planı — feat/vixrex-core-kalici-hesap (2026-08-26)

> Amaç: 83 dosya / 5.471 satırlık dev dalı `main`'e güvenli sırada taşımak. Her PR tek amaçlı, `verify_pr_scope.py` (12 dosya / 600 satır) ve `verify_dosya_boyutu_ratchet.py` yeşil kalır. Migration → Kod sırası korunur.

## 0) Derleme Doğrulaması (az önce koşuldu — tespitler unutulmadı)

- `flutter analyze --no-pub`: **No issues found (145s)** — `lib/main.dart:17`, `lib/config/*`, `lib/services/*` temiz.
- `npm run lint` (`public_web`): **0 error, 16 warning** — hepsi mevcut warning (örn. `owner-session` err unused).
- `npm test` (`public_web`): **89 dosya, 671 passed / 1 todo** — `public_web/tests/*` yeşil.
- `npm run build`: **52 route, compiled successfully (7.3s + 7.8s TS)** — `/(site)` ve `/kesfet` SSR listede. `next.config.ts:81` turbopack root doğru.
- `flutter test`: **534 passed / 1 failed** — `test/architecture_routing_contract_test.dart:63` FAILED: `public_web/next.config.ts` içinde `https://vixrex-app.vercel.app` bekleniyordu ama yok. Bu dal `next.config.ts`'teki eski fallback origin'i kaldırmış, test güncellenmemiş. PR3'te düzeltilecek (kırık testle merge yok).

## Neden 3 PR? Daha büyük tespit

`docs/agents/vixrex-core-kalici-hesap-notu.md:9` canlı ölçüm: 29 vitrinde `user_id` dolu sayısı **0**, 175 user'ın 172'si anonim. 4 kırık halka tek PR'da düzeltilemez — DB garantisi, Flutter sahiplenme, Web platformu farklı yüzeyler. Ayrıca `docs/seo-mimari-plani.md:42` + `docs/arsiv/gorev-web-uygulama-farklari-2026-08-26.md` sayfayı eşitleme işi (Hero, Keşfet, blog) Web PR'ına ait; DB PR'ı ile karışmamalı. Vibe-yama kültürü (AGENTS.md:25 skill zinciri atlanıyor) bu yüzden büyüdü — tek dev PR = geri alınamaz.

Sıra: **PR1 DB → PR2 Flutter → PR3 Web**. PR2 PR1'e, PR3 PR1'e bağımlı (DB'siz Flutter `claim_store_for_user` 42883 verir). PR3, PR2'den bağımsız deploy olur ama testte PR1'in `is_demo` filtresi gerekir.

---

## PR1 — DB Temel: Kalıcı Hesap Sahipliği

**Dal:** `feat/db-kalici-hesap` (main'den)
**Amaç:** Tek-vitrin kuralını veritabanında kilitlemek + anonim tuzağını kapatmak + boş klon regresyonunu onarmak.

**Dosyalar (3 adet, kapsama yeşil):**
- `supabase/migrations/20260826000000_vixrex_core_kalici_hesap_sahipligi.sql:1` (518 satır)
- `docs/agents/vixrex-core-kalici-hesap-notu.md:1` (doküman, kapsam dışı ama bilgi)
- (opsiyonel) `docs/agents/3pr-bolme-plani-2026-08-26.md` (bu dosya)

**Migration içeriği (kanıtlı):**
- `stores_tek_vitrin_per_user` kısmi UNIQUE index (`user_id IS NOT NULL`) — `vixrex_core_kalici_hesap_sahipligi.sql:61`
- `is_permanent_user()` — `sql STABLE`, `auth.jwt()->>is_anonymous` kontrolü `:70`
- `claim_store_for_user(p_edit_token)` — `SECURITY DEFINER`, 24 satır token check, `ALREADY_OWNS_STORE`, `ANONYMOUS_SESSION`, token 1 yıla uzatma `:89`
- `bootstrap_owner_state()` — edit_token yenileme + `strip_draft_secrets` + `store_working_drafts` tek çağrı `:166`
- `rent_demo_for_account(p_source_slug)` — `consume_assistant_request` rate-limit (5/saat), slug 3 deneme, `clone_demo_store_as_draft` çağrısı `:266`
- `link_store_to_user` kabuğu `:360` (eski APK boolean)
- `clone_demo_store_as_draft` regresyon onarımı `:392` — `_kategori_esleme` temp tablo, kategori+ürün kopyalama, `edit_token_expires_at = now()+24h`

**Doğrulama (PR1 merge öncesi ZORUNLU):**
```
# canlı DB'de rollback testi (veri kaybı yok):
BEGIN;
\i supabase/migrations/20260826000000_vixrex_core_kalici_hesap_sahipligi.sql
SELECT * FROM claim_store_for_user('short'); -- INVALID_TOKEN
SELECT is_permanent_user(); -- anonimse false
ROLLBACK;
# sonra gerçek push:
supabase db push --linked
```
- `flutter analyze` gerekmez (Dart yok), `public_web` etkilenmez.
- CI: `gitleaks`, `supabase migration lint` yeşilse merge.

**Geri dönüş (VIXREX_RULES.md:10):**
```sql
BEGIN;
DROP INDEX IF EXISTS public.stores_tek_vitrin_per_user;
DROP FUNCTION IF EXISTS public.bootstrap_owner_state();
DROP FUNCTION IF EXISTS public.claim_store_for_user(text);
DROP FUNCTION IF EXISTS public.rent_demo_for_account(text);
DROP FUNCTION IF EXISTS public.is_permanent_user();
-- clone/link eski gövdelerine dön: 20260824050000'i yeniden uygula
COMMIT; NOTIFY pgrst, 'reload schema';
```

**Sıcak not:** Bu PR merge olmadan PR2 ASLA merge edilmez — Flutter `Supabase.instance.client.rpc('claim_store_for_user')` 404 verir.

---

## PR2 — Flutter: Kalıcı Hesap + Tek Vitrin Kuralı

**Dal:** `feat/flutter-kalici-hesap` (PR1 merge sonrası main'den)
**Amaç:** Cihaz belleğine sıkışmış hayalet vitrini (`lib/screens/landing_screen.dart:297` hayalet kontrolü) kalıcı hesaba bağlamak, Keşfet 42501'i düzeltmek, kiralama artık sahipli doğsun.

**Dosyalar (9 dosya, ~340 satır, kapsama yeşil):**
- `lib/models/owner_bootstrap_state.dart:1` (182 satır) — `OwnerBootstrapState`, `StoreClaimResult`
- `lib/services/owner_bootstrap_service.dart:1` (178 satır) — `cihazaUygula` ezme kuralı (taslak daha yeni ise koru)
- `lib/services/demo_rental_service.dart:1` (171 satır) — `kaliciHesapVar` + `hesabaKirala`
- `lib/services/auth_service.dart:1` (86 satır değişim) — `getOwnerState`, `claimStore`, `claimDeviceStore`
- `lib/config/app_router.dart:394` — `navigateToRentDemo` hesaplı yol / misafir yolu ayrımı
- `lib/services/store_published_info_lookup_service.dart:43` — edit_token sunucudan da gelebilir
- `lib/repositories/supabase_auth_repository.dart:19` + `lib/repositories/supabase_store_repository.dart:16` — 42501 fix
- `lib/screens/auth_screen.dart:123` — Google bağlayınca `claimDeviceStore` tetik
- `test/vixrex_core_sahiplik_test.dart:1` (268 satır, 21 test) — `OwnerBootstrapState`, `OwnerBootstrapService.cihazaUygula`, `DemoRentalResult`, migration nöbetçileri

**Bağımlılık:** PR1 canlıda. Yoksa `test/vixrex_core_sahiplik_test.dart:501` migration nöbetçisi `stores_tek_vitrin_per_user` index'i bulamaz → kırmızı.

**Doğrulama:**
```
flutter analyze --no-pub          # 0 issue beklenir (az önce 145s yeşil)
flutter test                      # 534 → 535 passed olmalı, architecture_routing_contract hariç PR3'e bırakılır
flutter test test/vixrex_core_sahiplik_test.dart  # 21 passed
flutter test test/auth_service_test.dart test/explore_controller_test.dart  # regresyon
# manuel: Keşfet → Kirala → girişli hesapta vitrin `user_id` doldu mu, ürün sayısı 6 mı, yeni cihazda bootstrap açılıyor mu
```

**Geri dönüş:** `git revert <PR2-merge-commit>` — Dart kodu geri gelir, DB index kalır (veri kaybı yok, sadece Flutter eski anonim akışa döner). Eski APK `link_store_to_user` boolean kabuğu sayesinde çalışmaya devam eder.

**Unutma listesi (bu PR düzeltir):**
- Hayalet vitrin: `StoreLocalStorageService` + `StorePublishService.yayindaMi` artık `bootstrap_owner_state` ile sunucu doğruluyor.
- Boş klon: `clone_demo_store_as_draft` artık ürün/kategori kopyalıyor (PR1 ile birlikte).

---

## PR3 — Web Platform: Landing SSR + Keşfet Dizini (eşitleme)

**Dal:** `feat/web-platform-landing-kesfet` (PR1 sonrası main'den, PR2 ile paralel gidebilir ama PR2'den sonra merge önerilir)
**Amaç:** `public_web/src/app/page.tsx:1` redirect'ini gerçek SSR landing ile değiştirmek, Google'ın tarayabileceği `/kesfet` dizini + kategori sayfaları + sitemap/canonical düzeltmeleri. `docs/research/landing-port-envanteri-2026-08-25.md:8` + `docs/arsiv/gorev-web-uygulama-farklari-2026-08-26.md` sayfayı eşitleme işi burada biter.

**Dosyalar (~48 dosya, ama 600 satır sınırını aşar — Kapsam-Onay gerekir):**
- `public_web/src/app/(site)/page.tsx:1` (59 satır) — `revalidate=300`, `HeroSection` + `ValueBand` + `FeaturesSection` + `ComparisonSection` + `TrustBand` + `StepsSection` + `TemplateCatalog` + `BottomCta` + `MascotFab`
- `public_web/src/app/(site)/layout.tsx:1` (40 satır) — `SiteHeader`/`SiteFooter` + `organizationJsonLd`/`webSiteJsonLd` (route group, `/v/[slug]` sarılmıyor)
- `public_web/src/app/(site)/kesfet/page.tsx:1` (66 satır) + `public_web/src/app/(site)/kesfet/[kategori]/page.tsx:1` (144 satır)
- `public_web/src/components/landing/*` (10 dosya: `HeroSection.tsx:87`, `PhoneMockup.tsx:33`, `PhoneMockupSlaytlari.tsx:92`, `FeaturesSection.tsx:82`, `ComparisonSection.tsx:89`, `ValueBand.tsx:34`, `TrustBand.tsx:35`, `StepsSection.tsx:48`, `TemplateCatalog.tsx:74`, `BottomCta.tsx:46`, `MascotFab.tsx:52`, `mockupProfilleri.ts:51`)
- `public_web/src/components/kesfet/*` (2 dosya) + `public_web/src/components/site/*` (3 dosya: `SiteHeader.tsx:56`, `SiteFooter.tsx:48`, `icons.tsx:116`)
- `public_web/src/lib/*` (5 dosya: `explore.ts:136`, `businessCategories.ts:21`, `categoryTemplates.ts:127`, `jsonLd.ts:35`, `publicStoreSelect.ts:30`, + `siteUrl.ts` değişmez)
- `public_web/src/app/globals.css:23` — `@theme` içinde `lp-*` tokenları (`--color-lp-primary #147DFF` vs), `vitrin` tokenları korunur (palet ayrımı)
- `public_web/src/app/layout.tsx:26` — `next/font Outfit` (300-900) + `Instrument_Serif`, `metadataBase`, `verification.google`
- `public_web/src/app/opengraph-image.tsx:68`, `public_web/src/app/sitemap.xml/route.ts:52` (platformUrlleri + `is_demo` filtre), `public_web/src/app/robots.txt/route.ts:1`, `public_web/src/app/v/[slug]/page.tsx:10` + `urun/[productSlug]/page.tsx:10` + `yazilar/page.tsx:7` (noindex demo), `next.config.ts:22` düzeltmesi
- `public_web/tests/*` (9 yeni contract: `anasayfa-front-door`, `kesfet-veri`, `landing-esitlik`, `sitemap-demo-haric`, `tailwind-tema-additive` vb.) + `public_web/e2e/kesfet-akisi.spec.ts:111` + `playwright.config.ts:32`
- `public_web/public/images/vixrex_mascot.webp` + `vixrex_v_crystal_mascot.png`
- `vercel.json:4` — (bu PR'da EK YOK, `/` ve `/kesfet` redirect'i PR3 sonrası ayrı küçük PR olmalı — SEO planı Q3)
- `docs/research/landing-port-envanteri-2026-08-25.md:718` + `docs/agents/344-demosuz-landing-plani.md:105` (doküman)
- `public_web/next.config.ts` — **düzeltme gerekir**: `test/architecture_routing_contract_test.dart:67` `https://vixrex-app.vercel.app` bekliyor, şu anki dalda silindi. Ya testi güncelle ya `next.config.ts`'e fallback yorumu ekle. Öneri: testi `public_web/src/lib/siteUrl.ts:DEFAULT_APP_URL` kontrolüne çevir.

**Doğrulama (PR3 merge öncesi):**
```
cd public_web && npm run lint && npm test && npm run build
# lint: 16 warning tolere, 0 error
# test: 671 → 680+ passed beklenir (yeni contract'lar)
# build: 52 route, / (5m) ve /kesfet (5m) SSR görünmeli, is_demo filtreli sitemap
curl -s http://localhost:3000/sitemap.xml | grep -c "/kesfet"   # >1
curl -s http://localhost:3000/ | grep -c "Vixrex"                # >0 (SSR HTML)
# görsel: 390px ve 1280px ekran görüntüsü (docs/arsiv/gorev-web-uygulama-farklari-2026-08-26.md:94 doğrulama kesitleri)
flutter analyze lib/ && flutter test  # regresyon (PR2 sonrası, kırmızı olmamalı)
```

**Geri dönüş:** `git revert <PR3-merge-commit>` — `public_web/src/app/page.tsx` tekrar `redirect()` döner, `/kesfet` 404 olur. DB/Flutter etkilenmez. Sitemap eski haline döner.

**Kapsam-Onay notu (AGENTS.md:56):** Bu PR 12 dosya/600 satırı aşar. Açıklamaya yaz:
```
Kapsam-Onay: Landing port envanteri (718 satır) + Keşfet dizini tek PR — 48 dosya, görsel eşitleme contract testleri ile birlikte. Parçalanırsa landing/keşfet arası tutarsızlık doğar. Kanıt: landing-port-envanteri §8 kontrol listesi.
```

**Unutma listesi (bu PR kapatır):**
- Blog "uygulamam SEO değil" saçmalığı: Blog zaten SSR (`yazilar/page.tsx:86` `BreadcrumbList`, `yazilar/[articleSlug]/page.tsx:120` `BlogPosting`), Flutter zaten bilinçli `noindex` (`vercel.json:44`). Bu PR sonrası `vixrex-public` `/` de SSR olunca karışıklık biter.
- Renk paleti: `lp-*` izole, `globals.css:11` vitrin tokenları dokunulmadı — 29 canlı vitrin etkilenmez.
- Eşitleme: `docs/arsiv/gorev-web-uygulama-farklari-2026-08-26.md` Görev 1-4 (arka plan parıltısı, maskot balonu, hero önek, mockup) bu PR'ın devamı — ayrı küçük PR'lar olarak `mockupProfilleri.ts:51` ve `HeroSection.tsx:87` üzerinde ilerler.

---

## Ortak Çalışma Kuralları (3 PR için de)

- **Yama yok:** Her PR `grill-with-docs` → `implement` zinciri, `VIXREX_RULES.md:3` ilgili düzeltme yok.
- **Derleme:** Her PR sonunda `public_web: npm run lint && npm test && npm run build` çıktısı PR açıklamasında gösterilir (docs/arsiv/gorev-web-uygulama-farklari-2026-08-26.md:35).
- **Commit mesajı:** `feat(db): ...`, `feat(flutter): ...`, `feat(web): ...` — tek amaç.
- **Kirli ağaç temizliği (şimdi):** `public_web/scratch-ss/*`, `olcum-gecici.mjs`, `ss-gecici.mjs`, `pr_body*.md` (12 dosya) ya `.gitignore`'a ya da `git clean -fd` ile silinmeli. `linux/flutter/generated_*` `flutter pub get` ile yeniden üretilir, commit'e alınmamalı.

## Sıradaki Adım (onay bekliyor)

1. `feat/db-kalici-hesap` dalını oluştur → PR1 aç.
2. PR1 merge → `feat/flutter-kalici-hesap` ve `feat/web-platform-landing-kesfet`'i main'den aç (paralel).
3. Her PR'da yukarıdaki doğrulamayı koş, mevcut `feat/vixrex-core-kalici-hesap` dalı dondurulur (PR'lar merge olunca silinir).

Onay verirsen PR1'i şimdi oluşturup push edeyim mi, yoksa bu planı `CONTEXT.md`'ye de işleyeyim mi?

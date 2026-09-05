# Vixrex Akıllı Motor — Güncel BUILD Durumu

> Bu dosya yalnız **güncel durum göstergesidir**. Mimari kararlar `akilli-motor-architecture-lock.md` ve ilgili LOCK belgelerindedir. Çelişki halinde bu dosyanın durum işaretleri güncel ilerlemeyi, LOCK belgeleri ise davranış sözleşmesini gösterir.

Son güncelleme: 2026-09-05

## Genel durum

- KATMAN 0 — Mevcut durum denetimi: ✅
- KATMAN 1 — Global araştırma: ✅
- KATMAN 2 — Vixrex FIT: ✅
- KATMAN 2.5 — Esnaf UX FIT: ✅
- KATMAN 3 — Security / State / Data mimari LOCK: ✅
- KATMAN 4 — Final Architecture LOCK: ✅
- KATMAN 5 — CORE BUILD: 🔄
- KATMAN 6 — 46/46 FIELD VERIFY: 🔒
- KATMAN 7 — Esnaf VERIFY: 🔒
- KATMAN 8 — Akıllı Motor Final LOCK: 🔒
- KATMAN 9 — Blog / Dijital Çarşı UNLOCK: 🔒

## KATMAN 5 — Gerçek alt aşama sayısı

KATMAN 5, **5.0–5.10 = 11 alt aşamadır**.

### 5.0 — Baseline / parity üretim hattı ✅
- intent dictionary generator + drift ✅
- shared parity altyapısı ✅
- gerçek `schema-drift` CI kanıtı ✅

### 5.1 — Fail-closed kill-switch ✅
- Flutter + Next client guard ✅
- server guard ✅
- migration zinciri / GRANT guard / dar runtime testler ✅
- production DB migration henüz uygulanmadı

### 5.2 — Matcher + Validator parity 🔄
- matcher BUILD ✅
- validator BUILD ✅
- shared matcher/validator fixture ✅
- son aynı-SHA Flutter + Next dış runtime kanıtı kota nedeniyle bekliyor

### 5.3 — Pure Decision + Typed Action 🔄
- Flutter decision katmanından mutation/save çıkarıldı ✅
- Next erken success metni çıkarıldı ✅
- typed action contract ✅
- Next strict type kontrolü ✅
- Flutter gerçek runtime kanıtı bekliyor

### 5.4 — Canonical Pending State 🔄
- pending envelope v1 ✅
- Flutter Supabase-canonical pending + SharedPrefs cache/offline replay ✅
- Next v1 pending contract ✅
- legacy pending geçiş uyumu ✅
- DB constraint hardening + cross-client runtime kanıtı bekliyor

### 5.5 — Authoritative Assistant Mutation 🔄
- preflight / authoritative sınır LOCK ✅
- mevcut `store_working_drafts` + `audit_logs` kullanılacak ✅
- `expectedDraftVersion`, `actionId`, `commandId` sözleşmesi ✅
- web owner-session + permanent Flutter auth sınırı ✅
- canonical 46 alan → server contract üretim hattı BUILD sırada
- authoritative DB mutation migration/RPC BUILD bekliyor

### 5.6 — Safe Undo + Multi-action 🔄
- preflight LOCK ✅ (`akilli-motor-5-6-safe-undo-multiaction-preflight.md`)
- mevcut sıralı multi-action modeli korunacak ✅
- conflict/global failure stop kuralı ✅
- gerçek Undo = `commandId` + receipt ✅
- manual `Canlı hâline döndür` ayrı kalacak ✅
- runtime BUILD 5.5 receipt katmanından sonra

### 5.7 — Next Owner UX lifecycle ⬜
- real executing
- success/error/partial/undo
- mobile collapse/loading/storefront visible
- accessible status

### 5.8 — Flutter owner-edit adapter/lifecycle ⬜
- canonical working draft
- same ExecutionResult
- async persistence result
- `queued_offline` success değildir

### 5.9 — Special-flow security parity ⬜
- image security parity
- il/ilçe/GPS
- çalışma saatleri
- toggle/url edge cases

### 5.10 — Core Build doğrulaması ⬜
- targeted unit/integration
- same-SHA Flutter + Next parity
- PR CI
- preview / owner screenshots
- motor kaynaklı yeni regresyon = 0

## Dış doğrulama durumu

- GitHub Actions aylık dakika kotası dolu olduğu için yeni runner sonuçları kod failure kanıtı sayılmıyor.
- Vercel deployment kotası da son doğrulama sırasında engeldi.
- Bu durum BUILD'i durdurmaz; fakat ilgili aşamalar dış runtime kanıtı alınmadan tam ✅ yapılmaz.

## Değişmeyen sınırlar

- Main'e doğrudan geliştirme commit'i yok.
- Production DB'ye erken migration yok.
- PR #417 Draft/WIP olarak kalır.
- Blog / Dijital Çarşı assistant BUILD 🔒.
- Success yalnız authoritative persistence sonrası.
- 46/46 VERIFY KATMAN 5.10 tamamlanmadan açılmaz.

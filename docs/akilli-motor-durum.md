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
- canonical 46 alan → generated server-contract generator ✅
- generator için 46/46 + deterministic/privilege-free dar test ✅
- authoritative DB mutation migration/RPC BUILD bekliyor
- production DB değişmedi

### 5.6 — Safe Undo + Multi-action 🔄
- preflight LOCK ✅ (`akilli-motor-5-6-safe-undo-multiaction-preflight.md`)
- mevcut sıralı multi-action modeli korunacak ✅
- conflict/global failure stop kuralı ✅
- gerçek Undo = `commandId` + receipt ✅
- command Undo atomic + conflict-safe ✅
- manual `Canlı hâline döndür` ayrı kalacak ✅
- runtime BUILD 5.5 receipt katmanından sonra

### 5.7 — Next Owner UX lifecycle 🔄
- preflight LOCK ✅ (`akilli-motor-5-7-next-owner-ux-preflight.md`)
- mevcut mobile collapse/loading skeleton korunacak ✅
- `gonder()` lifecycle result sözleşmesi ✅
- needs-input/failed/partial mobilde paneli yeniden açacak ✅
- success panel kapalı kalacak ✅
- aria-busy/status/reduced-motion sınırı ✅
- runtime BUILD 5.5/5.6 ExecutionResult sonrası

### 5.8 — Flutter owner-edit adapter/lifecycle 🔄
- preflight LOCK ✅ (`akilli-motor-5-8-flutter-owner-lifecycle-preflight.md`)
- onboarding local flow ayrı kalacak ✅
- existing `WorkingDraftPort` evrilecek, yeni port yok ✅
- `bootstrap_owner_state` içindeki mevcut draft_version Flutter modele taşınacak ✅
- `saveLocally()` authoritative success değildir ✅
- `queued_offline` ayrı ExecutionResult ✅
- runtime BUILD 5.5 authoritative mutation sonrası

### 5.9 — Special-flow security parity 🔄
- preflight LOCK ✅ (`akilli-motor-5-9-special-flow-security-preflight.md`)
- Flutter WebP/content-signature açığı doğrulandı ✅
- il/ilçe canonical special-flow korunacak ✅
- GPS'in bugünkü 5 paralel field write'ı coupled/atomic bundle'a dönüşecek ✅
- çalışma saatleri gün tahmini yapmayacak ✅
- overnight yanlış açık/kapalı sonucu engellenecek ✅
- toggle/url 5.2 davranışı regresyon olarak korunacak ✅
- runtime BUILD ilgili dependency'ler hazır oldukça

### 5.10 — Core Build doğrulaması ⬜
- targeted unit/integration
- same-SHA Flutter + Next parity
- PR CI
- preview / owner screenshots
- motor kaynaklı yeni regresyon = 0

## Dış / altyapı doğrulama durumu

- GitHub Actions aylık dakika kotası dolu olduğu için yeni runner sonuçları kod failure kanıtı sayılmıyor.
- Vercel deployment kotası da son doğrulama sırasında engeldi.
- Supabase project'te ayrı bir development branch bulunmuyor; yalnız `main` branch görünüyor. Ücretli yeni branch kullanıcı onayı olmadan oluşturulmayacak.
- Local çalışma ortamında Supabase CLI/PostgreSQL yok; migration dosyası sahte timestamp ile elle oluşturulmayacak.
- Bu durum BUILD'i tamamen durdurmaz; fakat DB/runtime gerektiren aşamalar kanıt alınmadan tam ✅ yapılmaz.

## Değişmeyen sınırlar

- Main'e doğrudan geliştirme commit'i yok.
- Production DB'ye erken migration yok.
- PR #417 Draft/WIP olarak kalır.
- Blog / Dijital Çarşı assistant BUILD 🔒.
- Success yalnız authoritative persistence sonrası.
- 46/46 VERIFY KATMAN 5.10 tamamlanmadan açılmaz.

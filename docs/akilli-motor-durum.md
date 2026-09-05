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
- ücretsiz ve production'dan ayrı `vixrex-dev` Supabase test projesi oluşturuldu ✅
- production'dan salt-okunur türetilmiş minimal 5.5 DB test harness kuruldu ✅
- dev PostgreSQL'de kill-switch OFF → `SMART_ENGINE_DISABLED` ✅
- web owner-session authoritative mutation ✅
- permanent/non-anonymous Flutter `auth.uid()` yolu ✅
- anonymous Flutter reject → `OWNER_AUTHORIZATION_REQUIRED` ✅
- server semantic reject: geçersiz URL / koordinat / protected field ✅
- expected-version stale write → `DRAFT_VERSION_CONFLICT` ✅
- aynı action replay → ikinci mutation yok, önceki receipt döner ✅
- aynı actionId farklı payload → `IDEMPOTENCY_KEY_REUSE` ✅
- audit old/new/actionId/commandId/result version receipt ✅
- multi-action version chaining gerçek DB'de 2→3→4 ✅
- 🔄 46/46 generated DB contract'ın gerçek migration'a gömülmesi bekliyor
- 🔄 authoritative migration/RPC'nin repo migration zincirine alınması bekliyor
- 🔄 manuel owner edit regresyonu + full TS/Dart integration kanıtı bekliyor
- production DB değişmedi

### 5.6 — Safe Undo + Multi-action 🔄
- preflight LOCK ✅ (`akilli-motor-5-6-safe-undo-multiaction-preflight.md`)
- mevcut sıralı multi-action modeli korunacak ✅
- conflict/global failure stop kuralı ✅
- gerçek Undo = `commandId` + receipt ✅
- dev DB'de atomik command Undo BUILD edildi ✅
- iki action command Undo: tüm succeeded action'lar old_value'ya döndü ✅
- Undo draft version deterministik 4→6 ilerledi ✅
- ikinci aynı Undo `replayed:true`, duplicate mutation yok ✅
- daha sonra aynı alan değiştirildiyse `UNDO_CONFLICT` ✅
- conflict durumunda sıfır rollback: diğer command alanı da korunuyor ✅
- manual `Canlı hâline döndür` ayrı kalacak ✅
- 🔄 Next/Flutter orchestrator partial/failed/stopped sonucu ve commandId UI entegrasyonu bekliyor
- 🔄 gerçek 46-field production migration entegrasyonu 5.5 ile birlikte bekliyor

### 5.7 — Next Owner UX lifecycle 🔄
- preflight LOCK ✅ (`akilli-motor-5-7-next-owner-ux-preflight.md`)
- mevcut mobile collapse/loading skeleton korunacak ✅
- `gonder()` lifecycle result sözleşmesi ✅
- needs-input/failed/partial mobilde paneli yeniden açacak ✅
- success panel kapalı kalacak ✅
- aria-busy/status/reduced-motion sınırı ✅
- runtime BUILD 5.5/5.6 ExecutionResult entegrasyonu sonrası

### 5.8 — Flutter owner-edit adapter/lifecycle 🔄
- preflight LOCK ✅ (`akilli-motor-5-8-flutter-owner-lifecycle-preflight.md`)
- onboarding local flow ayrı kalacak ✅
- existing `WorkingDraftPort` evrilecek, yeni port yok ✅
- `bootstrap_owner_state` içindeki `draft_version` + `base_live_version` Flutter modele taşındı ✅
- `saveLocally()` authoritative success değildir ✅
- offline patch artık `draftVersion:-1` üretmiyor; `queuedOffline` ayrı state ✅
- hedefli testler eklendi; Flutter gerçek runtime kanıtı bekliyor
- runtime authoritative action adapter entegrasyonu 5.5 sonrası

### 5.9 — Special-flow security parity 🔄
- preflight LOCK ✅ (`akilli-motor-5-9-special-flow-security-preflight.md`)
- Flutter görsel upload extension/MIME yerine gerçek JPEG/PNG/WebP signature doğruluyor ✅
- WebP ham geçişinde codec decode doğrulaması ✅
- görsel spoofing hedefli testleri + Akıllı Motor CI kapsamı ✅
- il/ilçe canonical eşleştirmede `Kemer` belirsizliği ve substring açığı kapatıldı ✅
- çalışma saatleri generic mutation'dan çıkarıldı; Next + Flutter `needs_special_flow` ✅
- overnight `22:00–02:00` public open-state hesabı düzeltildi ✅
- `start == end` 24 saat açık sayılmıyor ve testle kilitli ✅
- GPS location bundle repo migration + ACL hardening + owner API yolu ✅
- GPS owner UI artık 5 paralel field write yerine `/api/owner-location-bundle` kullanıyor ✅
- GPS atomic bundle dev DB gerçek transaction testinden geçti; production DB değişmedi ✅
- toggle explicit allowlist Next/Flutter eşitlendi ✅
- URL `#anchor` kapsamı yalnız `galeriAksiyonLinki`; Next/Flutter/dev DB daraltıldı ✅
- `20260905161400_tighten_storefront_url_anchor_scope.sql` Akıllı Motor validator workflow path kapsamına bağlandı ✅
- `working-hours-overnight.test.ts`, `vixrex-decision-contract.test.ts` ve `vixrex_working_hours_special_flow_test.dart` dedicated validator workflow execution listesine bağlandı ✅
- son CI wiring commit'i: `1d81c8f35b8f21d086bfc3ea4dfe32653461e385` ✅
- son validator run `33977843912`: üç job da runner başlamadan `steps: []`; bu nedenle aynı-SHA runtime sonucu **doğrulanamadı** 🔄
- 5.9 bu dış runtime kanıtı gelmeden ✅ sayılmayacak

### 5.10 — Core Build doğrulaması ⬜
- targeted unit/integration
- same-SHA Flutter + Next parity
- PR CI
- preview / owner screenshots
- motor kaynaklı yeni regresyon = 0

## Dış / altyapı doğrulama durumu

- GitHub Actions aylık dakika kotası dolu olduğu için yeni runner sonuçları kod failure kanıtı sayılmıyor.
- Vercel deployment kotası son doğrulamada engeldi.
- Ücretli Supabase development branch açılmadı.
- Bunun yerine maliyeti `$0/ay` olarak doğrulanan ayrı `vixrex-dev` Supabase projesi kullanılıyor.
- `vixrex-dev` yalnız disposable DB/runtime kanıt ortamıdır; production veri taşınmadı.
- Production DB salt-okunur incelendi; yeni 5.5/5.6 DDL production'a uygulanmadı.
- Bu durum BUILD'i durdurmaz; fakat 46/46 generated migration + aynı-SHA client/runtime kanıtları alınmadan 5.5/5.6 tam ✅ yapılmaz.

## Değişmeyen sınırlar

- Main'e doğrudan geliştirme commit'i yok.
- Production DB'ye erken migration yok.
- PR #417 Draft/WIP olarak kalır.
- Blog / Dijital Çarşı assistant BUILD 🔒.
- Success yalnız authoritative persistence sonrası.
- 46/46 VERIFY KATMAN 5.10 tamamlanmadan açılmaz.

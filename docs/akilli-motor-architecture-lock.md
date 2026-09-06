# Vixrex Akıllı Motor — FINAL ARCHITECTURE LOCK

> **Durum: KATMAN 4 ✅ ARCHITECTURE LOCK**
>
> Bu belge, alt LOCK belgeleri arasındaki son tutarlılık denetiminden sonra Akıllı Motorun nihai mimari sınırını belirler. BUILD bu sınırlar içinde yapılır; BUILD sırasında mimari yeniden icat edilmez.

## 1. Değiştirilemez ana hedef

AI/LLM API kullanmadan; Vixrex'in 46 vitrin alanını esnafın doğal Türkçesinden güvenli ve deterministik biçimde anlayan, doğru alan/değeri doğrulayan, kalıcı state kullanan, yetkili ve idempotent mutation yapan, sonucu dürüst biçimde gösteren, gerektiğinde geri alabilen bir **Vixrex Akıllı Motoru**.

Gelecekte Blog ve Dijital Çarşı aynı çekirdeğe ayrı domain olarak takılabilir; bu iki domainin BUILD'i bu fazda kapalıdır.

## 2. Final tutarlılık sonucu

Alt LOCK belgeleri birlikte incelendi:

- matcher,
- validator / özel akış,
- state / action / executor,
- idempotency / concurrency / audit / undo,
- UX lifecycle / onboarding,
- domain router / kill-switch,
- test / CI.

**Ana mimariyi bozan çelişki bulunmadı.** Aşağıdaki üç sınır final belgede açıklaştırıldı ve önceki belgedeki daha geniş/yoruma açık ifadelerin önüne geçer:

1. **Taslak parity kapsamı:** Flutter ↔ Next canonical draft parity, yayın sonrası **owner-edit `store_working_drafts`** bağlamı içindir. Yayın öncesi Flutter onboarding taslağı mevcut yerel setup akışı olarak bilerek ayrı kalır.
2. **Flutter auth güvenliği:** `auth.uid()` ile owner mutation yalnız **kalıcı / non-anonymous** kullanıcı için geçerlidir. `authenticated` Postgres rolü tek başına sahiplik kanıtı değildir.
3. **Tek veri / tek yazma çekirdeği:** Assistant güvenlik precondition'ları manuel owner edit'i gereksiz yere yeniden tasarlamaz. Manuel ve assistant yüzeyleri aynı `store_working_drafts` hakikatini ve aynı server-side field/semantic validation çekirdeğini kullanır; assistant yolu ek olarak expected-version, action-id, audit ve undo kurallarını taşır. Validation veya persistence iş kuralı iki ayrı yerde kopyalanmaz.

Bu üç madde, önceki LOCK belgelerinde bunlarla çelişebilecek daha geniş wording varsa **nihai yorumdur**.

---

## 3. Nihai mimari

```text
KULLANICI MESAJI
    ↓
RUNTIME KILL-SWITCH
    ↓
DOMAIN ROUTER
    ↓
STOREFRONT DECISION ENGINE
    ↓
Matcher → Extractor → Canonicalizer → Validator
    ↓
Decision
    ├─ not_understood
    ├─ needs_clarification
    ├─ needs_special_flow
    ├─ validated_action
    ├─ validated_action_group
    └─ blocked
    ↓
ORCHESTRATOR
    ↓
ACTION LIFECYCLE
validated → executing → succeeded | queued_offline | failed
    ↓
AUTHORITATIVE EXECUTOR
    ↓
SERVER AUTHORIZATION + VALIDATION
    ↓
store_working_drafts
    ↓
AUDIT / IDEMPOTENCY RECEIPT / SAFE UNDO
    ↓
EXECUTION RESULT
    ↓
ESNAF UX
```

**Decision engine veri yazmaz. Executor intent çözmez. UI server sonucu gelmeden başarı söylemez.**

---

## 4. Tek kaynaklar

### 4.1 46 alan şeması

Kanonik zincir korunur:

```text
public_web/src/lib/vitrinFieldSchema.ts
→ shared/vitrin_alanlari.json
→ lib/config/vitrin_alanlari.g.dart
```

Yeni paralel field schema açılmaz.

### 4.2 Kategori

```text
shared/business_categories.json
```

kanoniktir. Yeni kategori listesi açılmaz.

### 4.3 Niyet sözlüğü

```text
shared/vixrex_niyet_sozlugu.json
```

kanonik kaynak olur. Flutter generated kopyası tek generator ile üretilir ve CI drift kontrolüne girer. Elle iki sözlük bakımı yasaktır.

### 4.4 Mesaj tonu

Mevcut shared Vixrex mesaj kataloğu korunur. Teknik hata kodları esnafa çıplak gösterilmez.

---

## 5. Domain sınırı

İlk aktif domain yalnız:

```text
storefront
```

olur.

Registry:

```text
storefront     → enabled capability
blog           → BUILD LOCKED
digital_carsi  → BUILD LOCKED
```

`blog` kelimesi tek başına Blog domain seçmez; çünkü 46 storefront alanı içinde `blogUstBaslik/blogBaslik` vardır. Domain route keyword değil açık command intent ile yapılır.

Belirsiz domain → mutation yok.

---

## 6. Matcher sözleşmesi

Serbest substring (`includes/contains`) kaldırılır.

Sıra:

```text
exact phrase
> exact token
> kontrollü Türkçe ekli biçim
> fuzzy suggestion
```

- kısa/generik alias yalnız exact,
- fuzzy mutation üretemez,
- iki eşit aday → clarification,
- `tel` → `otel` içinde eşleşemez,
- aynı shared fixture Dart + TypeScript'te aynı sonucu üretir.

Matcher yalnız alanı bulur; mutation kararı değildir.

---

## 7. Validator ve özel akış sınırı

Server authoritative validation zorunludur.

Özel kurallar:

- **adres:** semantik validator,
- **kategori:** shared allowlist,
- **il/ilçe:** mevcut bağlı seçim / ambiguity-safe matcher,
- **enlem/boylam:** GPS öncelikli; açık teknik girdide range,
- **çalışma saatleri:** yapısal özel akış; gün/saat tahmini yok,
- **toggle:** explicit TRUE/FALSE allowlist; bilinmeyen metin `false` değildir,
- **URL:** yalnız izinli protocol; anchor yalnız şemada izinli field,
- **görsel:** mevcut upload akışı; sohbetten URL yazdırmak ana UX değildir,
- **telefon/WhatsApp/e-posta:** mevcut kanonik biçim kuralları.

Protected/legal alanlar generic motor tarafından bypass edilemez.

---

## 8. Decision / typed action

Decision engine yalnız karar üretir.

`validated_action` en az:

```text
contractVersion: 1
domain: storefront
actionType: set_field
fieldKey
normalizedValue
matchClass
```

Client kolon adı yetki girdisi değildir. Server `fieldKey` → kolon eşlemesini kanonik şemadan çözer.

Gerçek mutation için orchestrator:

```text
commandId: UUID
actionId: UUID
expectedDraftVersion
source: web | flutter
```

oluşturur.

---

## 9. Pending state

Kanonik conversational state:

```text
assistant_conversations.pending_slot
```

olur.

SharedPreferences/localStorage yalnız cache/offline devam desteğidir.

Pending envelope:

```text
schemaVersion
domain
kind
fieldKey
fieldType
fieldLabel
proposedValue?
commandId?
attempt
createdAt
```

Güvenlik:
- server envelope biçimini doğrular,
- `fieldKey` 46 alan allowlist'inden doğrulanır,
- label/type yetki veya iş kuralı değildir; kanonik şemadan yeniden türetilebilir,
- `evet` yalnız pending gerçek adayı/değeri taşıyorsa mutation anlamı kazanabilir.

---

## 10. Taslak hakikati ve onboarding sınırı

### Owner-edit

Kanonik hakikat:

```text
Supabase store_working_drafts
```

Flutter ve Next owner-edit aynı taslak sürümünü ve aynı field değerini görmelidir.

### Onboarding

Yayın öncesi Flutter onboarding mevcut `StoreDraftPersistenceService` / setup state-machine akışını korur.

Bu durum owner-edit parity ihlali sayılmaz; lifecycle farklıdır:

```text
onboarding local setup draft
→ publish/handoff
→ owner-edit canonical working draft
```

Onboarding bu projenin UX/state kapsamındadır fakat generic 46-field owner mutation motoruna zorla taşınmaz.

---

## 11. Yetkilendirme

### Web

Mevcut HttpOnly owner-session sınırı korunur.

### Flutter permanent account

Server target store'u `auth.uid()` ile çözer fakat yalnız:

- auth user mevcut,
- kullanıcı anonymous değil / Vixrex'in `is_permanent_user()` eşdeğer kontrolü geçiyor,
- `stores.user_id = auth.uid()`

şartlarında.

`TO authenticated` veya yalnız JWT rolü sahiplik kanıtı değildir.

Client slug/store-id/field/column beyanı tek başına authorization değildir.

Bugünkü UNIQUE(user_id) modeli korunur; çoklu-store bu fazın kapsamı değildir.

---

## 12. Canonical server mutation çekirdeği

Manuel owner edit ve assistant edit aynı:

- `store_working_drafts`,
- field allowlist,
- semantic validation,
- protected-field kuralları,
- server authorization

çekirdeğini paylaşır.

Assistant yolu ayrıca zorunlu olarak:

```text
expectedDraftVersion
actionId
commandId
source
```

taşır.

Assistant write transaction sırası:

```text
authorize
→ lock/read draft row
→ idempotency receipt check
→ expected-version check
→ server semantic validation
→ old_value capture
→ mutation
→ draft_version + 1
→ audit/idempotency receipt
→ commit
```

BUILD sırasında bu çekirdeğin SQL biçimi (tek backward-compatible RPC veya ince wrapper + ortak internal core) yerel Supabase compile/integration testiyle seçilebilir; **iki ayrı validation/persistence iş kuralı oluşturmak yasaktır**.

---

## 13. Idempotency / concurrency

- aynı logical retry = aynı `actionId`,
- aynı actionId + aynı payload → önceki success sonucu, ikinci mutation yok,
- aynı actionId + farklı payload → `IDEMPOTENCY_KEY_REUSE`,
- stale version → `DRAFT_VERSION_CONFLICT`, otomatik overwrite yok,
- DB-level uniqueness zorunlu,
- row lock + unique receipt birlikte savunma sağlar.

PostgreSQL row locking mevcut; expected-version'ın görevi eski state'e dayalı sessiz yazmayı tespit etmektir.

---

## 14. Audit / Undo

Mevcut `audit_logs` kullanılır; yeni genel-purpose task tablosu açılmaz.

Assistant success receipt en az:

```text
action_id
command_id
domain
field_key
source
result_draft_version
old_value
new_value
```

taşır.

Assistant `Geri al` canlı değere dönmek değildir.

Undo:

```text
original action receipt
→ authorize
→ lock row
→ current == original new_value ?
→ old_value restore
→ version + 1
→ rollback receipt
```

Daha yeni değişiklik varsa `UNDO_CONFLICT` ve overwrite yok.

Mevcut owner `Canlı hâline döndür` ayrı fonksiyon olarak korunur.

---

## 15. Çok alanlı komut

Bağımsız alanlarda şeffaf kısmi başarı korunur.

- tek commandId,
- her field ayrı actionId,
- success version sonraki action'ın expectedVersion'ı,
- conflict olursa kalanlar durur,
- kullanıcıya kaydedilen / kaydedilemeyen açık gösterilir.

Coupled özel akışlar generic batch'e girmez:
- il + ilçe,
- enlem + boylam GPS,
- çalışma saatleri,
- upload + image URL write.

---

## 16. Runtime kill-switch

Mevcut `feature_flags` + `get_feature_flags()` kullanılır. Yeni remote-config sistemi yok.

İlk capability:

```text
vixrex_smart_engine_enabled
vixrex_smart_engine_storefront_enabled
```

Kurallar:
- flag unknown/load failure → mutation engine OFF,
- client kontrolü yetmez; authoritative server yolu da kontrol eder,
- manuel owner editing/public storefront çalışmaya devam eder,
- production deploy ilk olarak flag OFF,
- test/smoke sonrası kontrollü ON.

---

## 17. UX lifecycle

Durumlar:

```text
closed_idle
open_idle
needs_input
executing
queued_offline
succeeded
failed
partial_result
```

Kural:

```text
validated_action ≠ Kaydedildi
ExecutionResult.succeeded = gerçek başarı
```

Mobil:

```text
Gönder
→ sheet kapanır/küçülür
→ canonical Vixrex control loading
→ storefront görünür
→ success: vitrin sonucu görünür
→ failed/needs_input/partial: panel kullanıcı için yeniden görünür
```

PR #413'teki mevcut collapse/loading iskeleti korunur, gerçek action lifecycle'a bağlanır.

Loading/success/error yalnız görsel renkle/spinner ile anlatılmaz; erişilebilir status gerekir.

---

## 18. Onboarding UX

Mevcut onboarding state-machine yeniden yazılmaz.

Tanıma mesajı kısa ve dürüst:

- Vixrex Asistan vitrini kurmana/düzenlemene yardımcı olur.
- Bilmediği bilgiyi uydurmaz, gerektiğinde sorar.
- Yayın sonrası vitrin bilgilerini konuşarak değiştirebilirsin.

AI iddiası yapılmaz.

Kurulum sırasında tek gerekli soru gösterilir; kullanıcı 46 alanı öğrenmek zorunda değildir.

---

## 19. Parity ve test kapıları

Tek shared parity fixture Dart + TypeScript tarafından tüketilir.

Zorunlu kanıtlar:

- matcher parity,
- 46/46 extractor + validator parity,
- pure decision/no-side-effect,
- pending cross-client integration,
- expected-version/idempotency parallel tests,
- audit + Undo,
- kill-switch fail-closed,
- Flutter WorkingDraft adapter queue semantics,
- targeted owner-assistant mobile lifecycle Playwright,
- Flutter onboarding/companion widget/controller tests,
- image upload security parity,
- schema/intent generated drift.

46/46 tamam tanımı her field için:

```text
schema
intent
extraction
semantic validation
special-flow
typed action
authorization
persistence
idempotency
Flutter/Next parity
UX result
undo (uygunsa)
```

hepsinin ✅ olmasıdır.

---

## 20. CI ve merge kapısı

Mevcut CI kullanılacak:

- secret scan,
- Supabase auth config,
- Flutter format/analyze/test,
- Next lint/type/test/build,
- schema drift,
- Supabase local grant/security,
- ilgili integration/E2E.

Son doğrulanan main CI kırmızıdır; bu baseline açıkça ayrı tutulur. Fırsatçı refactor yapılmaz. Ancak final Smart Engine LOCK ve main merge için gerekli CI kapıları yeşil olmadan ilerlenmez.

---

## 21. Cerrahi BUILD sırası

Architecture LOCK sonrası sıra:

### 5.0 — Baseline / parity üretim hattı
- niyet sözlüğü generator + CI drift,
- shared parity fixture iskeleti,
- runtime davranış değişikliği yok.

### 5.1 — Fail-closed kill-switch
- mevcut feature_flags entegrasyonu,
- engine default OFF,
- manual edit fallback korunur.

### 5.2 — Matcher + validator parity
- substring matcher kaldırılır,
- shared matcher fixture,
- semantic validator parity,
- özel akış sınıfları.

### 5.3 — Pure Decision + Typed Action
- Flutter decision içinden executor/save side-effect çıkarılır,
- Next decision içinden erken `Kaydettim` çıkarılır,
- ortak canonical action sonucu.

### 5.4 — Canonical Pending State
- Flutter Supabase pending adapter,
- local yalnız cache,
- envelope server validation,
- cross-client test.

### 5.5 — Authoritative Assistant Mutation
- expected version,
- action/command id,
- permanent-user Flutter auth path,
- web owner-session path,
- server semantic validation,
- idempotency + audit receipt.

### 5.6 — Safe Undo + Multi-action orchestration
- action-level undo,
- partial success,
- conflict stop.

### 5.7 — Next Owner UX lifecycle
- existing sheet/loading behavior → real execution state,
- success/error/partial/undo,
- accessibility.

### 5.8 — Flutter Owner-edit adapter + lifecycle
- same action/result contract,
- canonical owner working draft,
- queued_offline ayrı state.

### 5.9 — Special-flow security parity
- images,
- il/ilçe/GPS,
- çalışma saatleri,
- boolean/url edge cases.

### 5.10 — 46/46 + CI + Esnaf verify
- 46 satır matris,
- targeted E2E,
- CI,
- preview/screenshots,
- gerçek esnaf senaryoları.

Her alt adım küçük, geri alınabilir ve ayrı doğrulanabilir commit/PR dilimi olabilir.

---

## 22. Kapsam dışı — LOCKED

Bu CORE BUILD sırasında yapılmayacak:

- Blog içerik motoru,
- Dijital Çarşı görev motoru,
- AI/LLM entegrasyonu,
- çoklu-store mimarisi,
- yeni remote-config platformu,
- yeni upload/GPS/category sistemi,
- owner ekranının baştan tasarlanması,
- onboarding'in baştan yazılması,
- genel workflow/Temporal altyapısı,
- fırsatçı geniş refactor.

---

# ARCHITECTURE LOCK KARARI

**✅ KATMAN 4 — ARCHITECTURE LOCK AÇILDI / TAMAMLANDI.**

Bu karar, motorun çalıştığı anlamına gelmez. Anlamı şudur:

> Araştırma ve mimari karar fazı tamamlandı; artık yalnız bu belgede kilitlenen sınırlar içinde cerrahi CORE BUILD yapılabilir.

**KATMAN 5 — CORE BUILD artık açılabilir.**

**KATMAN 6 / 7 / 8 / 9 hâlâ 🔒.**

# Vixrex Akıllı Motor — State + Action + Executor LOCK

> Kapsam: storefront 46-alan motorunun karar, konuşma state'i ve gerçek mutation sınırı. Bu belge BUILD yapmaz.

## Ana karar

Vixrex Akıllı Motor üç ayrı sorumluluk olarak çalışır:

```text
MESAJ
  ↓
DECISION ENGINE
  ↓
Decision / Pending / SpecialFlow / ValidatedAction
  ↓
ORCHESTRATOR
  ↓
EXECUTOR
  ↓
AUTHORITATIVE WRITE
  ↓
ExecutionResult
  ↓
UX MESSAGE
```

**Decision engine veri yazmaz. Executor intent çözmez. UX kayıt gerçekleşmeden başarı söylemez.**

Bu ayrım Flutter ve Next.js için aynıdır.

---

## 1. Mevcut kanıtlanan sorun — LOCK gerekçesi

### Flutter

`VixrexNluPipeline` bugün `StoreEditorController` verilirse:
- resolver/extractor/validator çalıştırır,
- `VixrexExecutor.execute(...)` çağırır,
- `await controller.saveLocally()` yapar,
- ardından `handled` + başarı mesajı döndürür.

Yani decision + effect aynı sınıftadır.

### Next.js

`handleVixrexNluMessage` bugün gerçek draft yazısını yapmaz; fakat daha yazma gerçekleşmeden `Kaydettim: ...` metni üretir. Çağıran daha sonra `/api/owner-draft` ile alanı yazar.

Yani effect ayrı olsa da success semantiği decision katmanına sızmıştır.

### LOCK

İki runtime da **aynı pure decision contract** üretir. Karar sonucu `Kaydettim` içeremez.

---

## 2. Vixrex yüzey sınırı — LOCKED

Mevcut Flutter `VixRexScreen` iki modu açıkça ayırıyor:

- yayın yok → `VixRexOnboardingChatScreen`
- yayın var → `VixRexCompanionChat`

Yayın öncesi Flutter taslağı `StoreDraftPersistenceService` ile cihazda tutulur; aynı edit token yayın sırasında kullanılır.

### LOCK kararı

- Onboarding bu projenin UX/state kapsamındadır.
- Fakat **genel 46-alan owner mutation motoru onboarding'in yerel kurulum akışını zorla değiştirmez.**
- Onboarding mevcut zorunlu kurulum state-machine'ini korur.
- 46-alan generic action contract owner-edit bağlamında kullanılır.
- Onboarding → owner-edit geçişinde aynı assistant kimliği/mesaj tonu/handoff korunur; executor aynı olmak zorunda değildir.

Bu sınır kapsam büyümesini engeller.

---

## 3. Decision sonucu — LOCKED

Decision engine aşağıdaki sınıflardan yalnız birini döndürür:

```text
not_understood
needs_clarification
needs_special_flow
validated_action
validated_action_group
blocked
```

Decision sonucu persistence durumu içermez.

### `validated_action`

En az:

```text
contractVersion: 1
domain: storefront
actionType: set_field
fieldKey: <46 alan anahtarı>
normalizedValue: <string | number | boolean | null>
matchClass: <matcher LOCK sonucu>
```

**Kolon adı action kontratında yetki girdisi değildir.**

Executor/server `fieldKey` → kolon eşlemesini kanonik Vixrex şemasından çözer. Client tarafından gönderilen kolon adına güvenilmez.

`null`, yalnız validator alanın temizlenmesine izin veriyorsa `set_field` değeri olabilir; ayrı rastgele delete komutu açılmaz.

---

## 4. Action kimliği — LOCKED

Gerçek mutation aşamasında orchestrator her kullanıcı komutu için:

```text
commandId: UUID
```

ve her bağımsız alan mutation'ı için:

```text
actionId: UUID
```

üretir.

Örnek:

```text
"Telefonumu ... yap, Instagramımı ... yap"
commandId = C1
  actionId = A1 → telefon
  actionId = A2 → instagram
```

Kurallar:
- aynı logical retry aynı `actionId` ile gider,
- farklı payload için aynı `actionId` kullanımı hata verir,
- `actionId` kimlik/yetki değildir; yalnız idempotency anahtarıdır,
- store/user hedefini server yetkilendirmesi çözer.

---

## 5. Action yaşam döngüsü — LOCKED

UI ve executor şu durumları ayırmak zorundadır:

```text
proposed
validated
executing
queued_offline
succeeded
failed
rolled_back
```

### Anlamları

- `proposed`: alan/değer adayı var; henüz güvenli action değil.
- `validated`: matcher + extractor + validator geçti.
- `executing`: authoritative write başladı.
- `queued_offline`: cihazda kalıcı kuyruğa alındı ama Supabase'e yazılmadı.
- `succeeded`: authoritative persistence başarılı ve server sonucu alındı.
- `failed`: yazma gerçekleşmedi / conflict / auth / validation / network kalıcı hata.
- `rolled_back`: belirli assistant action'ı güvenli biçimde geri alındı.

**`queued_offline` başarı değildir.**

Esnafa örnek:
- queued: `İnternet yok. Değişiklik sıraya alındı; henüz buluta kaydedilmedi.`
- succeeded: `Telefon güncellendi.`

---

## 6. Pending conversational state — LOCKED

Kanonik konuşma state'i `assistant_conversations.pending_slot` üzerinde kalır; yeni ikinci pending tablosu açılmaz.

Flutter `VixrexConversationMemory` bugün yalnız SharedPreferences kullanıyor; bu LOCK'ta kanonik kaynak olamaz.

### Pending envelope v1

```text
schemaVersion: 1
domain: storefront
kind: missing_value | confirm_candidate | special_flow
fieldKey: <46 alan anahtarı>
fieldType: <tip>
fieldLabel: <etiket>
proposedValue?: <yalnız gerçekten gerektiğinde>
commandId?: <ilgili komut>
attempt: integer
createdAt: ISO timestamp
```

Kurallar:
- Supabase = canonical.
- SharedPreferences/localStorage = yalnız cache/offline devam desteği.
- Kalıcı hesapta Flutter ve Next aynı auth user/conversation state'ini görür.
- pending value yalnız gerekli olduğu sürece tutulur; gereksiz kullanıcı verisi kopyalanmaz.
- state write başarısızsa sistem cross-device state kaydedilmiş gibi davranmaz.
- belirsiz/fuzzy aday onayı gerektiğinde `confirm_candidate` kullanılabilir.
- `evet` ancak pending state gerçekten hangi aday/değeri onayladığını taşıyorsa anlamlıdır; aksi halde mutation yapmaz.

Mevcut `evet → pending temizle ve tekrar sor` davranışı nihai kontrat değildir.

---

## 7. Execution context / yetkilendirme — LOCKED

### Web owner yüzeyi

Mevcut HttpOnly owner session sınırı korunur.

### Kalıcı Flutter hesabı

Canlı DB doğrulaması:
- `stores.user_id` → `auth.users(id)`
- `UNIQUE(user_id)` mevcut
- `bootstrap_owner_state()` kalıcı kullanıcıyı `auth.uid()` ile çözüyor
- `get_or_create_working_draft()` auth.uid sahipliğini edit-token'a alternatif yetki olarak kabul ediyor

Bu nedenle Flutter için yeni gizli owner-token sistemi kurulmaz.

### Ortak güvenlik kararı

Authoritative write yolu iki doğrulanmış yetkilendirme bağlamından birini kabul edebilir:

1. geçerli HttpOnly owner session (web sahiplik yüzeyi), veya
2. kalıcı Supabase Auth kullanıcısı + `stores.user_id = auth.uid()` (Flutter/account yüzeyi).

Target store client'ın beyanından kör alınmaz.

Bugünkü veri modelinde kullanıcı başına tek store olduğu UNIQUE constraint ile doğrulanmıştır. Çoklu-store desteği bu fazın kapsamı değildir.

---

## 8. Mevcut WorkingDraftPort — KORUNACAK, fakat sözleşmesi gerçek yapılacak

Flutter'da zaten:
- `WorkingDraftPort`
- `SupabaseWorkingDraftAdapter`
- `LocalQueueWorkingDraftAdapter`

mevcut.

Bu yüzden yeni port ailesi oluşturulmaz.

### Kanıtlanan açık

`WorkingDraftPort.yamaUygula(...)` bugün:
- `beklenenSurum`
- `clientId`

parametrelerini kabul ediyor ve yorumunda version-controlled write vaat ediyor.

Fakat `SupabaseWorkingDraftAdapter` bu iki parametreyi `update_working_draft_field` RPC'sine göndermiyor. Canlı RPC de bunları kabul etmiyor.

### LOCK kararı

- `beklenenSurum` → gerçek server precondition olur.
- eski `clientId` opaque UI label olarak kalabilir; idempotency için yeni canonical `actionId` kullanılır.
- port sonucu queued/succeeded ayrımını taşımalıdır; `draftVersion: -1` ile sahte success yasaktır.
- port/adaptör mevcut isimlerle evrilebilir; yeni paralel persistence sistemi kurulmaz.

---

## 9. Optimistic concurrency — LOCKED

Canlı `owner_flow_states` zaten doğru deseni kullanıyor:

```text
UPDATE ... WHERE version = expected_version
→ eşleşmezse VERSION_CONFLICT
```

Working draft için aynı prensip uygulanır.

### Server mutation sırası

```text
authorize target
→ lock/read current working-draft row
→ idempotency receipt check
→ expectedDraftVersion check
→ server semantic validation
→ old value read
→ mutation
→ draft_version + 1
→ audit/idempotency receipt
→ return real result
```

PostgreSQL aynı row üzerindeki update'ları zaten yazar seviyesinde serileştirir. Expected-version'ın amacı row lock'u taklit etmek değil; **kullanıcının eski state'e dayanarak sessizce yazmasını tespit etmektir.**

Conflict:
- otomatik overwrite yok,
- kullanıcıya `Vitrin başka yerde değişti. Güncel hâli yükledim; tekrar kontrol et.` benzeri açık durum verilir,
- action aynı payload ile retry ise idempotency receipt önce tanınır ve duplicate mutation olmaz.

---

## 10. Idempotency + audit — LOCKED

Yeni genel-purpose action tablosu bu fazda açılmayacak.

Mevcut `audit_logs` altyapısı kullanılabilir:
- old_value
- new_value
- metadata
- action
- target_type / target_id
- user/session bilgisi

`log_audit_event` istemcilere açık değildir; yalnız privileged roller execute edebilir.

### Minimal idempotency receipt

Assistant field mutation audit kaydında metadata en az:

```text
action_id
command_id
domain = storefront
field_key
source = web | flutter
result_draft_version
```

saklar.

DB seviyesinde assistant action id için **unique** garanti gerekir. Ayrı tablo yerine `audit_logs.metadata->>'action_id'` üzerinde dar/partial unique index kullanılabilir.

Aynı `actionId` tekrar gelirse:
- field/value aynıysa önceki başarılı sonuç döner (`idempotent replay`),
- field/value farklıysa `IDEMPOTENCY_KEY_REUSE` hatası,
- ikinci mutation yok.

Race durumunda yalnız pre-check yetmez; working draft row kilidi alındıktan sonra receipt tekrar kontrol edilir. Unique index ikinci savunmadır.

---

## 11. Undo — LOCKED

Mevcut `restore_working_draft_field` **canlı değere döndürür**. Bu, owner UI'daki `Canlı hâline döndür` davranışı için doğrudur.

Fakat assistant'ın `Geri al` işlemi aynı şey değildir.

Örnek:

```text
canlı telefon = A
taslakta kullanıcı daha önce = B
assistant action = C
```

Assistant `Geri al` derse doğru sonuç **B** olmalıdır; mevcut generic restore ise A'ya döndürür ve kullanıcının önceki taslak değişikliğini kaybettirir.

### LOCK kararı

Assistant action undo, audit kaydındaki `old_value` üzerinden action-level yapılır.

Undo güvenliği:
1. action receipt bulunur,
2. target/store authorization doğrulanır,
3. working draft row kilitlenir,
4. current field value hâlâ action'ın `new_value` değerine eşitse devam eder,
5. değilse `UNDO_CONFLICT` — daha sonraki değişiklik ezilmez,
6. old_value geri yazılır,
7. draft_version artar,
8. rollback audit kaydı `rollback_of_action_id` ile oluşturulur.

Mevcut `Canlı hâline döndür` RPC/UX korunur; assistant undo ile karıştırılmaz.

---

## 12. Çok alanlı komut — LOCKED

Genel 46-alan motorunda **bağımsız alanlar için şeffaf kısmi başarı** korunur; tüm komutu tek transaction'a zorlamak bu fazda yapılmaz.

Neden Vixrex-FIT:
- mevcut Next davranışı başarılı/başarısız alanları ayrı raporluyor,
- bir geçersiz Instagram değeri doğru telefon değişikliğini gereksiz yere iptal etmemeli,
- yeni batch persistence sistemi açılmaz.

Kurallar:
- her alan ayrı actionId,
- tek commandId altında gruplanır,
- action'lar belirli sırada yürür,
- her success yeni `draft_version` döndürür; sonraki action o sürümü expectedVersion olarak kullanır,
- conflict oluşursa kalan action'lar durur,
- kullanıcıya kaydedilen/kaydedilemeyenler açık gösterilir,
- `Geri al` yalnız gerçekten succeeded action'ları command grubu içinde ters sırada geri alabilir.

### Coupled alanlar generic multi-action değildir

Aşağıdakiler özel akışta kalır:
- il + ilçe
- GPS enlem + boylam
- yapısal çalışma saatleri
- görsel upload + URL field write

Bu alanların bağımlılık kuralları özel akış tarafından korunur; generic partial batch bunları parçalamaz.

---

## 13. Flutter / Next executor parity — LOCKED

Her iki yüzey aynı `validated_action` davranışını üretir.

Executor farklı teknoloji adaptörü olabilir; fakat sonuç kontratı aynıdır:

```text
ExecutionResult:
  status: succeeded | queued_offline | failed
  actionId
  commandId
  fieldKey
  normalizedValue
  draftVersion?
  errorCode?
```

UI yalnız bu sonuçtan mesaj üretir.

- `validated_action` → "Kaydettim" YOK.
- `executing` → loading.
- `queued_offline` → açık kuyruk mesajı.
- `succeeded` → gerçek başarı + Undo.
- `failed` → alan + düzeltilebilir hata.

---

## 14. BUILD kapsam sınırı

Bu LOCK uygulandığında YAPILACAK:
- NLU decision katmanından executor/persistence side effect'lerini çıkarmak,
- başarı metnini execution result sonrasına taşımak,
- pending state'i Supabase canonical + local cache yapmak,
- mevcut WorkingDraftPort sözleşmesini gerçek expected-version/action-id davranışına hizalamak,
- authenticated Flutter ownership + existing owner-session web yetki yollarını aynı authoritative mutation sınırında birleştirmek,
- assistant audit/idempotency receipt,
- action-level safe undo,
- parity fixture'ları.

YAPILMAYACAK:
- onboarding local setup akışını yeniden yazmak,
- çoklu-store desteği,
- yeni genel task DB sistemi,
- AI/LLM,
- Blog/Dijital Çarşı,
- yeni upload/category/GPS altyapısı,
- owner UI'yı baştan tasarlamak.

## LOCK sonucu

**State + Action + Executor tasarım kararı: LOCKED.**

Sıradaki kapı: idempotency/concurrency/audit sözleşmesinin canlı DB üzerinde uygulanabilirlik doğrulaması + UX lifecycle/onboarding LOCK. BUILD hâlâ kapalıdır.

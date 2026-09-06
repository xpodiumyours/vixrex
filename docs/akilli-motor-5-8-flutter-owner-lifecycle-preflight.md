# Vixrex Akıllı Motor — 5.8 Flutter Owner-edit Adapter/Lifecycle Preflight LOCK

> Kapsam: yayın sonrası Flutter Vixrex Companion'ın owner-edit mutation yolu. Onboarding local setup akışı bu dilimde değiştirilmez.

## Kanıtlanan mevcut durum

- Flutter `VixRexSessionController` uygulama boyunca tek `StoreEditorController` paylaşır.
- `StoreEditorController.saveLocally()` yalnız `StoreDraftPersistenceService.persist()` üzerinden cihaz belleğine yazar.
- `StoreDraftPersistenceService` canonical owner working draft değildir; local cache/setup persistence katmanıdır.
- `VixRexCompanionChat` 5.3 sonrası decision pipeline'a `controller:null` verir ve typed karar üretir; aktif mutation callback zinciri HomeShell'e delege edilir.
- `HomeShell._handleVixRexUpdateField` bugün `VixrexExecutor` ile local controller'ı değiştirip `saveLocally()` çağırdıktan hemen sonra `Kaydedildi` SnackBar gösterir.
- Bu callback `void`; persistence sonucunu Companion'a geri döndüremez.
- `WorkingDraftPort`, `SupabaseWorkingDraftAdapter`, `LocalQueueWorkingDraftAdapter` repo içinde zaten vardır; yeni paralel port ailesi gerekmiyor.
- `WorkingDraftPort.yamaUygula` bugün `beklenenSurum` parametresi taşır fakat Supabase adapter mevcut RPC'ye iletmez.
- `LocalQueueWorkingDraftAdapter` network yokken `Result.success(WorkingDraftPatchResult(draftVersion:-1))` döndürür; bu queued state'i sahte success gibi gösterir.
- `bootstrap_owner_state()` canlı DB'de `draft_version` döndürür.
- Flutter `OwnerBootstrapState` modeli bugün `draft_version` alanını okumaz; mevcut server verisi model sınırında kaybolur.
- `OwnerBootstrapState.tercihEdilenVeri`, working draft varsa onu canlı veriye tercih eder; canonical draft hydration için mevcut temel vardır.
- `OwnerPreviewService` published vitrin açarken `get_or_create_working_draft` çağırır ancak dönen `_WorkingDraftResult` yalnız slug/conflict taşır; draft version companion mutation lifecycle'a bağlanmaz.

## 5.8 LOCK 1 — Onboarding ve owner-edit ayrımı korunur

Yayın öncesi onboarding:

```text
StoreEditorController
 -> saveLocally
 -> StoreDraftPersistenceService
```

mevcut setup state-machine davranışını korur.

Yayın sonrası Akıllı Motor owner-edit:

```text
validated_action(s)
 -> owner action orchestrator
 -> WorkingDraftPort
 -> 5.5 authoritative assistant mutation RPC
 -> ExecutionResult
 -> local controller/cache yansıtma
 -> UX
```

olur.

`saveLocally()` owner-edit assistant için authoritative write değildir.

## 5.8 LOCK 2 — Yeni persistence portu yok

Mevcut `WorkingDraftPort` evrilir; ikinci assistant-specific persistence port ailesi açılmaz.

Portun assistant mutation çağrısı en az şunları taşımalıdır:

```text
fieldKey
normalizedValue
expectedDraftVersion
actionId
commandId
source=flutter
ownerSessionToken?  // Flutter permanent auth yolunda null olabilir
```

Authoritative 5.5 RPC permanent/non-anonymous `auth.uid()` sahipliğini server'da çözer.

## 5.8 LOCK 3 — Flutter permanent auth zorunlu

Remote authoritative assistant mutation yalnız:

- `auth.currentUser != null`,
- `user.isAnonymous == false`,
- server tarafında `stores.user_id = auth.uid()`

ise kullanılabilir.

Anonymous Flutter kullanıcıya yeni gizli owner token üretilmez.

Permanent auth yoksa owner-edit assistant remote mutation başarılıymış gibi davranmaz.

## 5.8 LOCK 4 — Draft version mevcut bootstrap'tan alınır

Yeni version endpoint'i açılmaz.

`OwnerBootstrapState` en az:

```text
draftVersion
baseLiveVersion
```

alanlarını mevcut `bootstrap_owner_state()` sonucundan taşıyacak şekilde genişletilir.

Working draft yoksa owner-edit mutation öncesi mevcut güvenli draft bootstrap yolu kullanılır; version tahmin edilmez.

## 5.8 LOCK 5 — ExecutionResult canonical

Flutter executor/orchestrator sonucu Next ile aynı semantiği taşır:

```text
status: succeeded | queued_offline | failed
actionId
commandId
fieldKey
normalizedValue
draftVersion?
errorCode?
idempotentReplay?
```

`draftVersion == -1` diye sahte success sözleşmesi kaldırılır.

## 5.8 LOCK 6 — Offline queue başarı değildir

Network yoksa ve action güvenli biçimde kalıcı local queue'ya alındıysa:

```text
status = queued_offline
```

UI:

`Değişiklik sıraya alındı; henüz buluta kaydedilmedi.`

benzeri açık mesaj verir.

`Kaydedildi` / `başarılı` kullanılmaz.

Queue item aynı `actionId`, `commandId`, `expectedDraftVersion`, `fieldKey`, `normalizedValue` bilgilerini korur; reconnect'te yeni action kimliği üretmez.

## 5.8 LOCK 7 — Unknown network sonucu

İstek server'a ulaşmış olabilir fakat response alınamadıysa ikinci yeni action oluşturulmaz.

Aynı `actionId` ile retry yapılır. 5.5 idempotency receipt authoritative sonucu çözer.

Version sonucu çözülmeden sonraki multi-action çalıştırılmaz.

## 5.8 LOCK 8 — Local controller authority değil, projection/cache

Authoritative `succeeded` sonrası:

1. server normalized value/result alınır,
2. `StoreEditorController` aynı field ile güncellenir,
3. `saveLocally()` yalnız cihaz projection/cache'ini kalıcı tutmak için çağrılır,
4. UI canonical server sonucunu success sayar.

Local cache yazma hatası authoritative server success'i geri almaz; sonraki bootstrap/sync server hakikatini tekrar getirir.

`queued_offline` durumunda local optimistic projection yapılabilir, fakat UI açıkça pending/queued state taşır.

## 5.8 LOCK 9 — Callback async sonuç döndürür

Bugünkü:

```text
void onUpdateField(String key, Object? value)
```

owner assistant authoritative lifecycle için yeterli değildir.

5.8 BUILD'de Companion ile HomeShell arasında typed async execution callback/orchestrator sonucu kullanılır.

Decision pipeline persistence çağırmaz. Companion:

```text
decision.actions
 -> await owner executor/orchestrator
 -> ExecutionResult/CommandResult
 -> chat UX
```

akışını kullanır.

## 5.8 LOCK 10 — `VixrexExecutor` rolü

Mevcut `VixrexExecutor` local `StoreEditorController` field projection işini yapabilir; authoritative persistence sınırı değildir.

Intent çözmez, server success üretmez.

5.8 uğruna tüm editor setter'ları yeniden yazılmaz.

## 5.8 LOCK 11 — Cross-client truth

Kalıcı hesapta Flutter açılışında:

- working draft varsa `OwnerBootstrapState.tercihEdilenVeri` tercih edilir,
- `draftVersion` aynı bootstrap'tan alınır,
- Next'te yapılan unpublished owner değişikliği Flutter owner-edit state'inde görünür,
- Flutter authoritative update sonrası Next aynı `store_working_drafts` satırını görür.

Supabase = canonical. Shared/local storage = cache.

## 5.8 LOCK 12 — Multi-action parity

Flutter, 5.6 ile aynı kuralı izler:

- tek `commandId`,
- field başına `actionId`,
- sıralı version chain,
- explicit field reject devam edebilir,
- conflict/auth/kill-switch/rate-limit/network-unknown kalanları durdurur,
- succeeded / failed / stopped ayrımı korunur.

## 5.8 LOCK 13 — UX mesajı execution sonrası

Flutter chat/SnackBar:

- `validated_action` → kayıt başarısı söylemez,
- `executing` → işlem durumu,
- `succeeded` → gerçek server success,
- `queued_offline` → henüz bulutta değil,
- `failed` → açık hata,
- `partial_result` → kaydedilen/kaydedilemeyen/işlenmeyen ayrımı.

Bugünkü `saveLocally(); SnackBar('Kaydedildi')` yolu assistant mutation'dan çıkarılır.

## BUILD bağımlılığı

5.8 runtime BUILD şu 5.5 sonuçları hazır olmadan bağlanmaz:

- authoritative mutation RPC,
- permanent Flutter auth authorization,
- expected-version,
- idempotency receipt,
- ExecutionResult error/result contract.

## Doğrulama kapıları

1. permanent Flutter account + working draft -> authoritative field success
2. anonymous Flutter -> remote assistant mutation reject/no false success
3. bootstrap `draftVersion` modelde korunur
4. succeeded -> local controller projection + same server version
5. local cache write failure after server success -> server success korunur
6. offline queue -> `queued_offline`, `draftVersion:-1` success yok
7. reconnect -> aynı actionId replay, duplicate mutation yok
8. stale version -> conflict, local/server sessiz overwrite yok
9. Next update -> Flutter bootstrap same draft sees change
10. Flutter update -> Next same working draft sees change
11. multi-action version chain parity
12. onboarding pre-publish local flow regresyonu yok

## Sonuç

**5.8 Flutter owner-edit adapter/lifecycle preflight: LOCKED.**

Runtime BUILD 5.5 authoritative mutation katmanından sonra yapılır. Main/production bu belgeyle değişmez.

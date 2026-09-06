# Vixrex Akıllı Motor — 5.6 Safe Undo + Multi-action Preflight LOCK

> Kapsam: owner-edit Akıllı Motor komutlarında birden çok bağımsız alanın yürütülmesi ve gerçek assistant Undo. Production DB değişikliği yapmaz.

## Kanıtlanan mevcut durum

- Next `useOwnerActions.gonder()` çok alanlı motor yazılarını zaten `for ... of` ile **sıralı** gönderiyor; yeni batch persistence sistemi gerekmiyor.
- Her istek bugün `/api/owner-draft` üzerinden ayrı field write yapıyor.
- Bugünkü döngü `actionId`, `commandId` ve `expectedDraftVersion` taşımıyor.
- Bugünkü döngü başarısız bir alan sonrası kalan alanlara devam ediyor; conflict/global failure sınıfı ayrımı yok.
- Bugünkü hızlı cevap payload'ı `geri_al:<alan1,alan2>` biçiminde alan isimleri taşıyor.
- Bugünkü `useFieldRestore.coklaCanliyaDondur()` assistant action geçmişini geri almıyor; alanları `restore_working_draft_field` ile **canlı vitrindeki değere** döndürüyor.
- `restore_working_draft_field` row'u `FOR UPDATE` kilitliyor ve manuel "canlı hâline döndür" davranışı için güvenli kalmalıdır.

## 5.6 LOCK 1 — Multi-action yeni batch değildir

Bağımsız alanlar için mevcut sıralı model korunur:

```text
commandId = C1
expectedVersion = V10

A1 telefon  -> succeeded V11
A2 instagram -> succeeded V12
A3 website   -> failed validation, version V12
A4 eposta    -> succeeded V13
```

Her bağımsız alan:
- ayrı `actionId`,
- aynı `commandId`,
- bir önceki başarılı mutation'dan dönen `draftVersion` ile sonraki `expectedDraftVersion`

taşır.

Yeni batch table, queue veya genel transaction framework açılmaz.

## 5.6 LOCK 2 — Devam / durdurma kuralları

### Devam edilebilir explicit field failure

Sunucu alanı **kesin olarak yazmadığını** bildiriyorsa ve draft version değişmediyse, kalan bağımsız action'lara aynı expected version ile devam edilebilir.

Örnek:
- semantic validation reject,
- field not editable,
- explicit field-level invalid value.

Bu durumda sonuç `partial_result` olabilir.

### Kalan action'ları DURDURAN durumlar

Aşağıdakilerde version/authorization/execution zemini artık güvenli zincir değildir; kalan action'lar gönderilmez:

- `DRAFT_VERSION_CONFLICT`,
- `IDEMPOTENCY_KEY_REUSE`,
- auth / owner-session failure,
- smart-engine kill-switch OFF,
- rate-limit/global service failure,
- network/transport sonucu belirsiz hata,
- server sonucu mutation'ın gerçekleşip gerçekleşmediğini kesin söylemiyorsa.

Özellikle network unknown sonrasında sonraki action'a geçilmez. Aynı `actionId` ile retry idempotent yapılabilir; önceki action'ın gerçek sonucu çözülmeden version zinciri tahmin edilmez.

## 5.6 LOCK 3 — Partial success kullanıcıya dürüst gösterilir

Tek command içinde:

```text
succeeded: [A1, A2]
failed: [A3]
stopped: [A4, A5]
```

ayrımı korunur.

UI tek büyük sahte "hepsi kaydedildi" mesajı vermez.

- `succeeded` alanlar gerçek server receipt sonucu ile listelenir.
- `failed` alan hata nedeniyle yazılmamıştır.
- `stopped` alanlar güvenlik/version zinciri koptuğu için hiç denenmemiştir.

## 5.6 LOCK 4 — Gerçek Assistant Undo `commandId` ile çalışır

Hızlı cevap payload'ı artık alan listesi taşımayacak.

Hedef:

```text
geri_al_command:<commandId>
```

Client'ın gönderdiği alan listesi rollback yetkisi veya rollback kaynağı değildir.

Server aynı `commandId` altındaki **başarılı `assistant_field_update` receipt'lerini** kendi audit kaynağından çözer.

## 5.6 LOCK 5 — Command Undo atomik ve ters sıradadır

Bir komuttaki succeeded action'lar rollback edilirken:

1. target/store authorization doğrulanır,
2. working-draft row tek transaction'da kilitlenir,
3. command receipt'leri server tarafından yüklenir,
4. yalnız gerçekten `succeeded` assistant update receipt'leri alınır,
5. her alan için current value hâlâ ilgili action'ın `new_value` değerine eşit mi kontrol edilir,
6. **herhangi biri eşleşmiyorsa `UNDO_CONFLICT`; hiçbir alan geri alınmaz**,
7. hepsi güvenliyse action'lar ters sırada `old_value` değerlerine döndürülür,
8. `draft_version` deterministik biçimde artırılır,
9. rollback audit kayıtları `rollback_of_action_id` + `command_id` ile yazılır,
10. transaction commit edilir.

Atomic command undo seçimi esnaf için nettir: "Bu komutu geri al" ya tamamen olur ya da daha sonraki değişikliği ezmemek için hiç olmaz.

## 5.6 LOCK 6 — Neden ters sıra

Aynı command içinde bağımsız alanlar ayrı olsa da audit sırasını ters takip etmek gelecekte aynı field'ın yanlışlıkla iki kez action listesine girmesi gibi edge-case'lerde önceki state zincirini korur.

Decision/orchestrator normalde aynı field'ı command içinde tekilleştirmelidir; ters rollback ek güvenliktir.

## 5.6 LOCK 7 — Manual `Canlı hâline döndür` korunur

Mevcut:

```text
/api/owner-draft-restore
restore_working_draft_field
```

manuel owner özelliği olarak korunur.

Bu özellik:
- canlı değeri referans alır,
- assistant receipt kullanmaz,
- assistant `Geri al` ile birleştirilmez.

UI metinleri de iki davranışı ayırmalıdır:
- manuel: `Canlı hâline döndür`
- assistant command: `Geri al`

## 5.6 LOCK 8 — Undo ikinci kez çağrılırsa

Aynı command zaten tamamen rollback edilmişse ikinci çağrı ikinci kez mutation yapmaz.

Server rollback receipt'lerinden bunu tanır ve önceki sonucu idempotent biçimde döndürür.

Aynı rollback operation farklı target/command payload ile tekrar kullanılırsa reuse/conflict hatası verir.

## 5.6 LOCK 9 — Special/coupled flow generic multi-action değildir

Aşağıdakiler bu sıralı partial modelin içine parçalanmaz:
- `il + ilce`,
- GPS `enlem + boylam`,
- yapısal çalışma saatleri,
- görsel upload + URL write.

Bunlar kendi özel akışlarında kalır.

## 5.6 LOCK 10 — 5.5 bağımlılığı

Gerçek 5.6 BUILD, 5.5 authoritative mutation receipt'leri olmadan açılmaz.

Önce 5.5 DB contract şunları üretmelidir:
- `actionId`,
- `commandId`,
- `expectedDraftVersion`,
- `old_value`,
- `new_value`,
- `result_draft_version`,
- idempotency receipt.

Bunlar olmadan gerçek assistant Undo uygulanamaz; alan isimlerinden tahmin edilmez.

## Doğrulama kapıları

5.6 tamamlandı denmeden:

1. iki bağımsız action doğru version zinciriyle success,
2. bir field-level reject sonrası sonraki bağımsız action güvenle devam,
3. version conflict ortasında kalan action'lar hiç gönderilmez,
4. network unknown sonrası kalan action'lar hiç gönderilmez,
5. partial result succeeded/failed/stopped ayrımı doğru,
6. command Undo hemen sonrası tüm succeeded action'ları old_value'ya döndürür,
7. Undo'dan önce alanlardan biri başka yerde değişirse `UNDO_CONFLICT` ve **sıfır rollback**,
8. ikinci aynı Undo duplicate mutation yapmaz,
9. manuel `Canlı hâline döndür` mevcut davranışını korur,
10. Flutter ve Next aynı ExecutionResult/Undo hata kodlarını kullanıcı semantiğine eşler.

## Sonuç

**5.6 Safe Undo + Multi-action preflight: LOCKED.**

Runtime BUILD, 5.5 authoritative mutation receipt/migration katmanından sonra yapılacaktır. Main ve production DB bu belgeyle değişmez.

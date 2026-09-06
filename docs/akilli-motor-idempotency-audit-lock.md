# Vixrex Akıllı Motor — Idempotency + Concurrency + Audit LOCK

> Kapsam: 46-alan assistant mutation'larının retry, eşzamanlı cihaz, audit ve undo güvenliği. BUILD yapmaz.

## Kanıtlanan mevcut durum

Canlı Supabase ve repo birlikte doğrulandı:

- `store_working_drafts` tek store satırı, `draft_version bigint` içeriyor.
- `update_working_draft_field` bugün yalnız `session_token + key + value` alıyor ve sürümü artırıyor.
- RPC expected-version veya action-id almıyor.
- `restore_working_draft_field` satırı `FOR UPDATE` kilitliyor.
- `owner_flow_states` zaten `expected_version` ile optimistic concurrency uyguluyor.
- `WorkingDraftPort` expected-version parametresi taşıyor fakat Supabase adapter bunu RPC'ye iletmiyor.
- `assistant_messages` client-message id için unique index taşıyor; field mutation için eşdeğer receipt yok.
- `audit_logs` RLS açık; old/new/metadata/action/target alanları var.
- `log_audit_event` yalnız privileged roller tarafından çalıştırılabiliyor.
- canlı audit verisinde henüz `action_id` metadata veya `assistant_field_update` kaydı yok.

## LOCK 1 — PostgreSQL concurrency semantiği

PostgreSQL aynı row üzerindeki writer'ları zaten row-level lock ile serileştirir. Read Committed'da bekleyen UPDATE, ilk transaction commit ederse güncel row sürümü üzerinde devam eder.

Bu nedenle Vixrex'in ihtiyacı “UPDATE'a kilit ekleyelim” kadar basit değildir.

Asıl iki garanti:

1. **stale intent detection** — kullanıcı eski `draft_version` üzerinden yazıyorsa sessiz overwrite yapılmaması,
2. **retry idempotency** — aynı logical action tekrar gelirse ikinci mutation/sürüm artışı olmaması.

## LOCK 2 — expected draft version

Assistant mutation her zaman `expectedDraftVersion` taşır.

Server:

```text
current draft_version == expectedDraftVersion
```

değilse ve request daha önce başarıyla uygulanmış aynı action değilse:

```text
DRAFT_VERSION_CONFLICT
```

verir.

Conflict otomatik overwrite ile çözülmez.

## LOCK 3 — action receipt

Her gerçek assistant field mutation:

```text
actionId   = unique UUID
commandId  = aynı kullanıcı mesajındaki action grubu UUID
```

ile çalışır.

Ayrı genel-purpose task/action tablosu bu fazda açılmaz.

Mevcut `audit_logs` assistant action receipt olarak da kullanılır.

Assistant update kaydı:

```text
action      = assistant_field_update
target_type = store_working_draft_field
target_id   = <server-resolved store id>
old_value   = <mutation öncesi değer>
new_value   = <mutation sonrası değer>
metadata = {
  action_id,
  command_id,
  domain: storefront,
  field_key,
  source,
  result_draft_version
}
```

## LOCK 4 — DB uniqueness

`action_id` yalnız uygulama kontrolüne bırakılmaz.

`audit_logs` üzerinde assistant action metadata'sına dar bir **partial unique expression index** ile DB-level tekillik sağlanabilir.

Hedef ilke:

```text
(store target, metadata.action_id) unique
WHERE action = assistant_field_update
```

Bu, mevcut audit schema'yı kullanır; yeni tablo açmaz.

## LOCK 5 — transaction sırası

Assistant field write ve receipt aynı DB transaction içindedir.

Sıra:

```text
1 authorize store
2 validate action-id/command-id biçimi
3 lock/read store_working_drafts row
4 re-check existing receipt for actionId
5 if receipt exists:
    - same field/value → prior success result
    - different field/value → IDEMPOTENCY_KEY_REUSE
6 compare expectedDraftVersion
7 server semantic validation / protected-field check
8 capture old_value
9 update field + draft_version
10 insert audit receipt old/new/result version
11 commit
12 return succeeded
```

Önemli: receipt check row lock'tan sonra tekrar yapılır; iki aynı request aynı anda gelse bile ikincisi duplicate mutation yapamaz. Unique index ek savunmadır.

## LOCK 6 — replay sonucu

Aynı action retry:

- mutation yeniden yapılmaz,
- `draft_version` yeniden artmaz,
- önceki action receipt sonucu döner,
- response içten `idempotentReplay=true` taşıyabilir,
- UX bunu normal başarılı sonuç gibi gösterebilir; kullanıcıya teknik retry detayı gerekmez.

Aynı actionId farklı payload:

```text
IDEMPOTENCY_KEY_REUSE
```

ve mutation yok.

## LOCK 7 — çoklu action concurrency

Bağımsız çoklu alan komutunda:

- her action ayrı id,
- aynı command id,
- ilk action mevcut expected version ile başlar,
- success'ten dönen version sonraki action'ın expected version'ıdır,
- conflict oluştuğunda kalan action'lar durur,
- önceki succeeded action'lar saklanır ve açık raporlanır.

Bu davranış mevcut Vixrex kısmi başarı UX'ini korur ve yeni batch DB sistemi açmaz.

Coupled özel akışlar generic batch'e sokulmaz.

## LOCK 8 — assistant Undo

Generic `restore_working_draft_field` canlı değere döndürme aracıdır; assistant action undo değildir.

Assistant Undo receipt üzerinden çalışır:

```text
find original action
→ authorize same store
→ lock draft row
→ verify current field value == original new_value
→ expected version check
→ restore original old_value
→ draft_version + 1
→ write assistant_field_rollback receipt
```

Current value artık farklıysa:

```text
UNDO_CONFLICT
```

verilir. Daha sonraki kullanıcı değişikliği ezilmez.

Rollback metadata:

```text
rollback_of_action_id
command_id
field_key
```

## LOCK 9 — audit erişimi

Motor audit kayıtlarını client'tan doğrudan insert ettirmez.

- mevcut RLS korunur,
- `log_audit_event` privileged sınırı korunur,
- assistant write transaction'ı receipt'i server/SECURITY DEFINER sınırında üretir,
- raw owner-session token audit'e yazılmaz,
- session kimliği gerekirse token olmayan server-resolved session id kullanılır.

## LOCK 10 — mevcut RPC geçiş güvenliği

Repo taramasında `update_working_draft_field` şu gerçek yüzeylerde kullanılıyor:

- `/api/owner-draft`
- `/api/owner-structured-field`
- Flutter `SupabaseWorkingDraftAdapter`
- ilgili migration/test/doc referansları

BUILD sırasında yeni paralel kalıcı yazma sistemi açılmaz.

Nihai hedef: tüm gerçek caller'lar aynı hardened working-draft mutation contract'ına geçirilir. Geçiş branch içinde tamamlanmadan eski unversioned assistant yolu main'e taşınmaz.

## LOCK 11 — auth bağlamı

Authoritative mutation target server tarafından çözülür.

Geçerli iki bağlam:

1. web owner-session,
2. kalıcı Supabase Auth user ownership (`stores.user_id = auth.uid()`).

`stores.user_id` bugün UNIQUE olduğundan permanent account için store hedefi tekildir.

Client'tan gelen `slug`, `fieldKey`, `source` kimlik/yetki değildir; authorization server tarafında yeniden doğrulanır.

## Uygulama doğrulama kapıları

BUILD sonrası bu testler geçmeden tamamlandı denmez:

1. aynı actionId seri iki çağrı → bir sürüm artışı
2. aynı actionId paralel iki çağrı → bir sürüm artışı
3. aynı actionId farklı payload → reuse error
4. stale expected version → conflict, mutation yok
5. iki farklı field, doğru version zinciri → ikisi de korunur
6. conflict ortasında multi-action → kalanlar durur, ilk başarı açık kalır
7. undo hemen sonrası → old_value döner
8. undo'dan önce alan başka yerde değişmiş → UNDO_CONFLICT
9. audit old/new/action/command doğru
10. anon owner-session başka store'u yazamaz
11. authenticated user başka store'u yazamaz
12. Flutter ve Next aynı ExecutionResult hata kodunu eşler

## LOCK sonucu

**Idempotency + Concurrency + Audit tasarım kararı: LOCKED.**

BUILD hâlâ kilitlidir. Kalan ana mimari kapılar: UX lifecycle + onboarding davranışı, runtime kill-switch/domain router sınırı ve bütün LOCK'ların tek Architecture LOCK altında son doğrulaması.

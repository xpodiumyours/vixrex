# Vixrex Akıllı Motor — 5.5 Authoritative Mutation Preflight

> Durum: **BUILD sözleşmesi kilitlendi; DB migration henüz oluşturulmadı/uygulanmadı.**
>
> Kapsam: yalnız `storefront` Akıllı Motor mutation yolu. Manuel owner edit, Blog ve Dijital Çarşı bu dilimde değiştirilmez.

## 1. Doğrulanmış mevcut durum

- Web manuel + motor mutation bugün aynı `/api/owner-draft` route'undan geçiyor.
- Web sahip yetkisi HttpOnly owner-session cookie + DB session-token kontrolüyle korunuyor.
- `update_working_draft_field` bugün `expected_version`, `action_id`, `command_id` veya audit receipt almıyor.
- `owner_flow_states.update_owner_flow_state` mevcut Vixrex içinde `expected_version` ile sessiz overwrite'ı engelleyen çalışan referans desenidir.
- `audit_logs` old/new/metadata alanlarını zaten taşıyor.
- `log_audit_event` anon/authenticated rollerine kapalı; service-role tarafında kullanılabilir.
- Flutter `WorkingDraftPort.yamaUygula` zaten `beklenenSurum` ve `clientId` parametrelerini taşıyor, fakat `SupabaseWorkingDraftAdapter` bunları mevcut RPC'ye göndermiyor.
- Flutter kalıcı hesap için `bootstrap_owner_state()` yalnız permanent/non-anonymous kullanıcıyı kabul ediyor.
- `get_or_create_working_draft()` mevcut `auth.uid()` sahipliğini edit-token'a alternatif yetki olarak zaten kabul ediyor.
- Web server-loaded `draft` nesnesi `draft_version` değerini zaten taşıyor; yeni version-fetch sistemi gerekmiyor.
- DB'de 46 storefront alanını canonical field key ile doğrulayan ortak bir field-contract/validator fonksiyonu bugün yok.

## 2. Seçilen authoritative sınır

### Seçim

**Supabase/PostgreSQL authoritative assistant mutation RPC.**

Flutter'ın mutation için yeni bir Next.js/CORS backend bağımlılığı açılmayacak. Next.js owner route da aynı authoritative RPC'yi çağıracak.

### Neden

1. Flutter zaten Supabase Auth + RPC omurgasını kullanıyor.
2. Flutter Web ayrı origin'de çalışabildiği için yeni Next Bearer API yolu ek CORS/auth yüzeyi oluşturur.
3. Mutation + idempotency + version check + audit aynı PostgreSQL transaction'ında kalabilir.
4. Web'in mevcut HttpOnly owner-session sınırı korunabilir.
5. Yeni veritabanı veya yeni persistence sistemi gerekmez; mevcut `store_working_drafts` + `audit_logs` kullanılır.

## 3. Tek field-schema kuralı

DB için ikinci elle-maintained 46 alan listesi **yasak**.

Kaynak zinciri değişmez:

```text
public_web/src/lib/vitrinFieldSchema.ts
  -> shared/vitrin_alanlari.json
  -> Flutter generated schema
  -> DB field contract (generated)
```

DB field contract canonical JSON'dan üretilmelidir. En az şu metadata taşınır:

- `anahtar`
- `kolon`
- `tip`
- `zorunlu`
- `minUzunluk` / `maxUzunluk`
- `min` / `max`
- `secenekler`
- `dogrulama`

Yeni alan ekleme = canonical field schema değişikliği + generated outputs. DB'de elle yeni CASE/allowlist satırı ekleme kabul edilmez.

## 4. Assistant mutation RPC sözleşmesi

İsim migration sırasında kesinleştirilecek; davranış sözleşmesi sabittir.

Girdi:

```text
session_token?          // web owner-session yolu; Flutter auth yolunda null
field_key               // canonical 46-field key, DB column DEĞİL
normalized_value
expected_draft_version
action_id               // UUID, tek logical field mutation
command_id              // UUID, tek kullanıcı komutu
```

Server/client `column` iddiası yetki veya field kimliği sayılmaz. DB field contract `field_key -> column` çözer.

## 5. Authorization

RPC iki mevcut Vixrex sahiplik yolundan yalnız birini kabul eder:

### Web

- mevcut HttpOnly cookie Next server'da doğrulanır;
- cookie içinden gelen owner session token RPC'ye taşınır;
- mevcut consumed/unexpired owner-session + store kontrolü korunur.

### Flutter

- `auth.uid()` zorunlu;
- kullanıcı permanent/non-anonymous olmalı;
- `stores.user_id = auth.uid()` sahipliği server'da doğrulanmalı;
- client store ID/slug iddiası authorization değildir.

Anonymous Flutter hesabı authoritative assistant mutation kullanamaz.

## 6. Server semantic validation

İki katman korunur:

1. TS/Dart local/server validator: hızlı UX ve canonical normalization.
2. PostgreSQL authoritative validator: kötü/eskimiş/elle çağrılmış client'ın güvenlik sınırını aşmasını engeller.

DB validator generated field contract'tan karar verir. En az:

- bilinmeyen/protected field reddi,
- JSON değer tipi,
- required/null,
- text min/max,
- numeric min/max,
- seçim allowlist,
- `tr_mobil`,
- URL/görsel http(s) sınırı,
- adres semantic minimumu,
- toggle boolean canonical tipi

kontrol edilir.

DB'ye serbest ham doğal dil gönderilmez; yalnız decision engine'in canonical `normalizedValue` değeri gönderilir.

## 7. Transaction sırası

Tek transaction mantığı:

```text
AUTH
 -> FIELD CONTRACT + SEMANTIC VALIDATION
 -> ACTION RECEIPT LOOKUP
 -> WORKING DRAFT ROW LOCK
 -> EXPECTED VERSION CHECK
 -> OLD VALUE CAPTURE
 -> UPDATE DRAFT + VERSION++
 -> AUDIT RECEIPT
 -> RETURN RESULT
```

### Row lock

Hedef `store_working_drafts` satırı mutation/version kararından önce kilitlenir.

### Stale write

`current_draft_version != expected_draft_version`:

```text
DRAFT_VERSION_CONFLICT
```

Mutation yapılmaz.

## 8. Idempotency

`action_id` authoritative receipt anahtarıdır.

### İlk istek

- mutation uygulanır,
- audit receipt yazılır,
- result version döner.

### Aynı action tekrar gelirse

Aynı:
- store,
- field key,
- normalized value,
- command id

ise mutation tekrar uygulanmaz; önceki receipt sonucu döner.

### Aynı action id farklı payload

```text
IDEMPOTENCY_KEY_REUSE
```

Mutation yok.

DB seviyesinde unique guarantee gereklidir; yalnız uygulama kodu kontrolü yeterli değildir.

## 9. Audit receipt

Yeni genel action tablosu yok. Mevcut `audit_logs` kullanılır.

Assistant mutation receipt metadata en az:

```text
action_id
command_id
domain=storefront
field_key
source=smart_engine
result_draft_version
```

`old_value` ve `new_value` mevcut audit kolonlarında tutulur.

Receipt aynı transaction içinde yazılır.

## 10. Web entegrasyonu

Manuel `/api/owner-draft` davranışı korunur.

Yalnız `source = smart_engine` isteği şu ek precondition'ları taşır:

```text
commandId
actionId
expectedDraftVersion
```

Motor isteği bunlardan biri yoksa fail-closed olur.

Manuel edit eski `update_working_draft_field` yolunda kalabilir; 5.5 assistant hardening manuel düzenlemeyi gereksiz yere yeniden yazmaz.

Web'de `draft_version` zaten server `draft` payload'ında vardır. Bu değer mevcut owner hook/action zincirine taşınır; ayrı version endpoint'i açılmaz.

Çok alanlı command'da ilk action başarılı olursa dönen yeni draft version ikinci action'ın expected version'ı olur. Böylece açık, sıralı partial-success davranışı korunur.

## 11. Flutter entegrasyonu

Yeni persistence sistemi yok.

Mevcut WorkingDraft katmanı korunur; assistant mutation için gereken `actionId/commandId/expectedVersion` authoritative RPC'ye taşınır.

Permanent Supabase Auth yolu session token üretmeye zorlanmaz.

Offline sonuç:

```text
queued_offline
```

olmalıdır. `draftVersion = -1` authoritative success anlamına gelemez ve kullanıcıya "Kaydedildi" dedirtemez.

Bu UX/lifecycle bağlantısı 5.8'de tamamlanır.

## 12. Migration güvenlik kapısı

Migration uygulanmadan önce:

- Supabase CLI/MCP migration akışıyla gerçek migration oluşturulmalı,
- generated DB field contract migration'a dahil edilmeli,
- PUBLIC execute revoke edilmeli,
- gerekli roller açıkça grant edilmeli,
- SECURITY DEFINER ise auth kontrolleri fonksiyon içinde bulunmalı,
- local Supabase reset/migration testi geçmeli,
- GRANT guard geçmeli,
- idempotency race testi geçmeli,
- stale-version testi geçmeli,
- audit receipt testi geçmeli.

**Production DB'ye doğrudan SQL ile erken uygulama yok.**

## 13. 5.5 BUILD kabul kriteri

5.5 ancak aşağıdakilerin tamamıyla ✅ olur:

- [ ] canonical generated DB field contract
- [ ] authoritative assistant mutation RPC
- [ ] web owner-session auth testi
- [ ] permanent Flutter auth ownership testi
- [ ] anonymous Flutter reject
- [ ] server semantic validation
- [ ] expected-version conflict
- [ ] same action replay = tek mutation
- [ ] action-id payload mismatch reject
- [ ] audit old/new receipt
- [ ] multi-action version chaining
- [ ] manual owner edit regresyonu yok
- [ ] relevant DB/TS/Dart tests pass

Şu anki durum: **preflight/contract ✅; runtime BUILD migration kapısı bekliyor.**

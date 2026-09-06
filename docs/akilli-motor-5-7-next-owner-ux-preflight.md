# Vixrex Akıllı Motor — 5.7 Next Owner UX Lifecycle Preflight LOCK

> Kapsam: yalnız Next owner-edit Vixrex Asistan UX lifecycle. 5.5 authoritative mutation sonucu olmadan runtime BUILD açılmaz.

## Kanıtlanan mevcut durum

- PR #413 ile mobilde `FieldInputArea.gonderVeVitriniGoster()` gönder anında canonical Vixrex düğmesi üzerinden sheet'i kapatıyor.
- Aynı akış `body.vixrex-asistan-isliyor` sınıfını ekliyor ve `await gonder()` bitince kaldırıyor.
- CSS canonical Vixrex düğmesini spinner + `Düzenleniyor…` görünümüne çeviriyor; storefront görünür kalıyor.
- `useOwnerActions.kaydediliyor` bugün tek boolean ve karar + network + persistence süresinin tamamını tek state gibi temsil ediyor.
- `FieldInputArea` pseudo-element spinner kullanıyor; canonical Vixrex düğmesinde bugün `aria-busy` yok.
- CSS `pointer-events:none` ile tıklamayı engelliyor fakat bu tek başına keyboard/semantic disabled garantisi değildir.
- `useFieldSelection.alanSec()` işlem sürerken `onAlanSecildi` çağrısını bilinçli bastırıyor; böylece sıradaki alan seçimi sheet'i işlem ortasında açmıyor.
- Bunun yan etkisi: NLU `needsClarification` / kullanıcı müdahalesi gerektiren sonuç döndürürse alan seçiliyor ama işlem sınıfı aktifken panel yeniden açılmıyor; `gonder()` dönüşünde de sonucu yeniden açan lifecycle kontratı bugün yok.
- Başarı mesajı serbest motor yolunda gerçek `/api/owner-draft` cevaplarından sonra üretiliyor; bu doğru davranış korunacak.
- Bugünkü assistant Undo payload'ı alan listesi taşıyor; 5.6 LOCK sonrası `commandId` tabanlı gerçek Undo'ya dönecek.

## 5.7 LOCK 1 — Mevcut mobil skeleton korunur

Yeni sheet/panel sistemi kurulmaz.

Mobil ana akış:

```text
Gönder
 -> sheet canonical Vixrex düğmesiyle kapanır
 -> storefront görünür kalır
 -> canonical Vixrex düğmesi executing görünümüne geçer
 -> authoritative ExecutionResult gelir
 -> lifecycle sonucu uygulanır
```

Masaüstü mevcut açık panel davranışını korur; mobil collapse davranışı masaüstüne taşınmaz.

## 5.7 LOCK 2 — `gonder()` lifecycle sonucu döndürür

`Promise<void>` artık UX kararına yetmez.

Owner action katmanı en az şu kullanıcı-lifecycle sonucunu döndürür:

```text
no_op
needs_input
succeeded
failed
partial_result
queued_offline
```

`executing` dönüş değeri değildir; request sürerken component state'tir.

Bu lifecycle sonucu authoritative execution sonucu ve decision sonucu üzerinden üretilir; DOM/CSS'ten tahmin edilmez.

## 5.7 LOCK 3 — Mobilde hangi sonuç paneli açar?

### Kapalı kalır

- `succeeded`

Neden: kullanıcı vitrindeki gerçek değişikliği görsün; başarı ve Undo chat history'de kalır.

### Yeniden açılır

- `needs_input`
- `failed`
- `partial_result`

Neden: kullanıcı yeni bilgi vermeli veya hangi alanın kaydedilmediğini görmelidir.

### `queued_offline`

Next web owner yüzeyinde normalde authoritative API yazısı kullanıldığı için v1'de beklenen sonuç değildir. Contract'ta parity için korunur; olursa başarı gibi kapalı kalmaz, açık durum mesajı gösterilir.

## 5.7 LOCK 4 — Panel reopen DOM tahminiyle yapılmaz

İşlem sonunda CSS class veya message text okuyup karar verilmez.

`FieldInputArea`/OwnerAssistantPanel arasında açık lifecycle callback/sonuç sözleşmesi kullanılır.

Hedef:

```text
const sonuc = await gonder();
if (mobil && sonuc requires attention) setAcik(true)
```

Canonical button'a ikinci kez querySelector/click ile iş mantığı bağlanmaz. Mevcut ilk collapse davranışı geçiş uyumu olarak korunabilir; sonuç kararı React state üzerinden olmalıdır.

## 5.7 LOCK 5 — Executing gerçek action lifecycle'a bağlanır

`vixrex-asistan-isliyor` sınıfı yalnız `gonder()` Promise süresine kör biçimde bağlı kalmayacak.

Motor yolu için:

```text
decision validated_action
 -> executing=true
 -> authoritative mutation(s)
 -> ExecutionResult
 -> executing=false
```

`needs_clarification` gibi mutation başlamayan kararda sahte uzun persistence loading'i gösterilmez.

## 5.7 LOCK 6 — Success semantiği

Success yalnız:

```text
ExecutionResult.status == succeeded
```

sonrası gösterilir.

Mesajlar:
- server receipt ile gerçekten kaydedilen alanlar,
- gerçek draft version zinciri,
- 5.6 command Undo `commandId`
üzerinden hazırlanır.

`validated_action` metni success mesajına dönüştürülmez.

## 5.7 LOCK 7 — Partial result

Çok alanlı command sonucu üç grup taşır:

```text
succeeded
failed
stopped
```

UI açıkça ayırır.

Örnek semantik:

```text
Kaydedildi: Telefon, Instagram
Kaydedilemedi: Website
İşlenmedi: E-posta — vitrin başka yerde değişti
```

Tek büyük yeşil başarı ikonu ile bütün komut başarılı gösterilmez.

`Geri al` yalnız gerçekten succeeded action receipt'leri olan command için sunulur.

## 5.7 LOCK 8 — Error / conflict metni

Teknik hata kodu kullanıcıya ham verilmez.

Örnek eşleme:
- `DRAFT_VERSION_CONFLICT` → `Vitrin başka yerde değişti. Güncel hâli yükledim; tekrar kontrol et.`
- auth/session → `Sahiplik oturumunun süresi doldu. Önizlemeyi tekrar aç.`
- kill-switch → mevcut dürüst motor kapalı mesajı
- validation → alanın düzeltilebilir Türkçe hatası
- network unknown → `Bağlantı sonucu doğrulanamadı. Değişikliği tekrar kontrol edelim.`

Network unknown'da success söylenmez.

## 5.7 LOCK 9 — Accessibility

Canonical Vixrex düğmesi gerçek state taşır:

- executing sırasında `aria-busy="true"`,
- gerekli durumda gerçek `disabled` veya eşdeğer keyboard-safe guard,
- görünür metin yalnız pseudo-element'e bırakılmaz; screen-reader için status text bulunur.

Owner panelinde sonuç durumu için `role="status"` / `aria-live="polite"` benzeri mevcut DOM'a küçük status yüzeyi eklenir.

Error/needs-input için kullanıcı müdahalesi gereken metin erişilebilir biçimde duyurulur.

Spinner tek bilgi kanalı değildir.

## 5.7 LOCK 10 — Reduced motion

`prefers-reduced-motion: reduce` durumunda spinner/transition animasyonu azaltılır veya kaldırılır; `Düzenleniyor…` metni state'i taşımaya devam eder.

## 5.7 LOCK 11 — Duplicate submit

`kaydediliyor` yalnız görsel opacity/pointer-events değildir.

- button gerçek disabled,
- Enter handler executing sırasında yeni submit başlatmaz,
- action/command idempotency DB'de ikinci savunmadır.

UI guard güvenlik/idempotency yerine geçmez.

## 5.7 LOCK 12 — Manual owner edit ayrımı

Seçili alanın manuel düzenleme UX'i mevcut davranışı korur.

Akıllı Motor'a özgü command lifecycle:
- `source=smart_engine`,
- typed action,
- command/action ids,
- partial/Undo
özellikleri serbest motor komutuna uygulanır.

5.7 uğruna normal owner formunun tüm save UX'i baştan yazılmaz.

## Runtime BUILD bağımlılıkları

5.7 runtime BUILD ancak 5.5/5.6 şu sonucu ürettiğinde bağlanır:

- `ExecutionResult`,
- `commandId`,
- succeeded action receipt'leri,
- failure/error code,
- final draft version,
- gerçek command Undo endpoint/RPC.

Bunlar olmadan UX sahte state üretmez.

## Doğrulama kapıları

1. mobile send -> sheet kapanır, storefront görünür, executing status görünür
2. success -> sheet kapalı kalır, gerçek değişiklik görünür
3. needs_input -> sheet yeniden açılır ve giriş alanı kullanılabilir
4. failed -> sheet yeniden açılır, düzeltilebilir hata görünür
5. partial -> sheet yeniden açılır, succeeded/failed/stopped ayrılır
6. duplicate Enter/click -> tek logical command
7. screen-reader state: aria-busy/status doğrulanır
8. keyboard executing sırasında ikinci submit yok
9. reduced-motion state okunabilir kalır
10. desktop layout/collapse regresyonu yok
11. manual `Canlı hâline döndür` ayrı davranışını korur
12. assistant `Geri al` commandId tabanlı gerçek Undo çağırır

## Sonuç

**5.7 Next Owner UX lifecycle preflight: LOCKED.**

Runtime BUILD, 5.5 Authoritative Mutation + 5.6 Safe Undo sonuç kontratı hazır olmadan başlamaz. Main/production bu belgeyle değişmez.

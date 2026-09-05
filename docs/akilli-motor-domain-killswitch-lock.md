# Vixrex Akıllı Motor — Domain Router + Runtime Kill-Switch LOCK

> Kapsam: mevcut storefront motorunun gelecekte Blog/Dijital Çarşı'ya genişleyebilmesi ve üretimde anında güvenli kapatma. BUILD yapmaz.

## 1. Mevcut kanıt

Repo taramasında üst seviye assistant domain router bulunmadı.

Bugünkü NLU doğrudan 46 storefront alan sözlüğüne gider.

Ayrıca 46 alanın içinde:
- `blogUstBaslik`
- `blogBaslik`

vardır. Bunlar **Blog içerik domain'i değildir**; public vitrindeki Blog bölümünün başlık alanlarıdır.

Bu nedenle router yalnız `blog` kelimesi gördü diye Blog domain'e geçemez.

---

## 2. Domain Router sırası — LOCKED

```text
message
  ↓
GLOBAL KILL-SWITCH
  ↓
DOMAIN ROUTER
  ↓
storefront interpreter
  ├─ 46-field matcher
  ├─ validator
  └─ action contract

future:
  ├─ blog interpreter 🔒 disabled
  └─ digital_carsi interpreter 🔒 disabled
```

İlk BUILD'de **yalnız storefront enabled** olabilir.

Blog ve Dijital Çarşı interpreter'ı bu fazda yazılmaz.

---

## 3. Router kararı — LOCKED

Domain result:

```text
domain: storefront | blog | digital_carsi | unsupported
status: enabled | disabled | ambiguous
```

### Storefront default

Owner-edit yüzeyinde mesaj açık bir başka domain komutu taşımıyorsa `storefront` varsayılandır.

Bu, mevcut kullanıcı beklentisini korur: Vixrex Asistan öncelikle vitrini yönetir.

### Non-storefront domain

Gelecekte Blog/Dijital Çarşı yalnız **açık domain intent kalıpları** ile seçilebilir.

Örnek prensip:
- `blog başlığını değiştir` → storefront field olabilir
- `yeni blog yazısı oluştur` → future Blog domain intent

Yani keyword değil **command intent** route edilir.

### Ambiguous

İki domain aynı güvenle aday ise:
- mutation yok,
- kullanıcıya hangi işi istediği sorulur.

---

## 4. Domain registry — LOCKED

Router if/switch büyümesiyle yönetilmez; küçük bir registry contract kullanır.

İlk registry:

```text
storefront:
  enabledCapability = storefront_46

blog:
  enabledCapability = blog
  BUILD = locked

digital_carsi:
  enabledCapability = digital_carsi
  BUILD = locked
```

Her domain kendi:
- intent matcher'ını,
- action tiplerini,
- validator'ını,
- executor capability'sini
kaydeder.

Bir domain diğerinin field/action sözlüğünü genişletmez.

---

## 5. Mevcut feature-flag altyapısı — KORUNACAK

Canlı DB'de `feature_flags` tablosu ve `get_feature_flags()` RPC'si mevcut.

Flutter'da `FeatureFlagService`:
- `get_feature_flags()` çağırıyor,
- flag'leri cache'liyor,
- yüklenemezse `defaultValue` kullanıyor.

`get_feature_flags()` bugün anon ve authenticated rollerce okunabiliyor ve yalnız:
- `flag_key`
- `is_enabled`
- `target_users`

döndürüyor.

Yeni remote-config sistemi kurulmaz.

---

## 6. Akıllı Motor flag sözleşmesi — LOCKED

İlk BUILD'de iki seviye yeterlidir:

```text
vixrex_smart_engine_enabled
vixrex_smart_engine_storefront_enabled
```

Gelecekte ilgili domain BUILD açıldığında:

```text
vixrex_smart_engine_blog_enabled
vixrex_smart_engine_digital_carsi_enabled
```

eklenebilir.

Blog/Dijital Çarşı flag'lerinin varlığı o domain'in BUILD edildiği anlamına gelmez; capability kodu yoksa router disabled döner.

---

## 7. Fail-closed davranışı — LOCKED

Mutation engine için flag yüklenemiyorsa:

```text
default = OFF
```

olur.

Bu durumda:
- manuel owner düzenleme çalışmaya devam eder,
- public vitrin çalışmaya devam eder,
- assistant guidance/chat güvenli fallback olarak kalabilir,
- 46-alan otomatik mutation devre dışıdır,
- kullanıcıya sahte `Kaydettim` sonucu verilmez.

---

## 8. Kill-switch yalnız UI değildir — LOCKED

Client flag kontrolü tek güvenlik katmanı değildir.

Assistant authoritative mutation yolu server tarafında da global/storefront flag'i kontrol eder.

Amaç:
- UI eski cache yüzünden açık görünse bile server mutation'ı durdurabilsin,
- üretimde kritik sorun olursa DB flag kapatılarak yeni assistant mutation'ları durdurulabilsin.

Manual owner update yolu kill-switch yüzünden kapanmaz.

---

## 9. Flutter mevcut compile-time flag — değişecek sınır

Bugünkü Flutter companion:

```text
static const _pipelineEnabled = true
```

kullanıyor.

Bu gerçek operasyonel kill-switch değildir.

BUILD'de:
- compile-time sabit authoritative flag olmaktan çıkar,
- mevcut `FeatureFlagService` kullanılır,
- flag OFF/unknown → deterministic mutation pipeline çalışmaz,
- eski güvenli rehber/manual düzenleme yolu korunur.

---

## 10. Next.js sınırı

Next owner assistant için de aynı flag semantiği uygulanır.

- client UX flag'i okuyabilir,
- authoritative API/RPC yeniden kontrol eder,
- flag kapalıyken serbest metinden 46-alan mutation yapılmaz,
- manuel field selection/edit çalışır.

Flutter ve Next flag sonucu aynı capability anlamını taşır.

---

## 11. Rollout güvenliği — LOCKED

Core BUILD main'e girmeden önce yeni smart-engine flag üretimde **OFF** başlar.

Sıra:

```text
BUILD branch
→ unit/parity/integration tests
→ preview doğrulama
→ migration/security doğrulama
→ main deploy, flag OFF
→ kontrollü doğrulama
→ storefront flag ON
```

Kill-switch doğrulanmadan production engine ON yapılamaz.

---

## 12. Kapsam sınırı

YAPILACAK:
- küçük DomainRouter contract,
- storefront capability registration,
- mevcut feature_flags entegrasyonu,
- client + server fail-closed kill-switch,
- fallback davranışı.

YAPILMAYACAK:
- Blog interpreter,
- Dijital Çarşı interpreter,
- yeni feature-flag platformu,
- kullanıcı segmentasyonu sistemi,
- A/B test framework'ü,
- AI model router.

## LOCK sonucu

**Domain Router + Runtime Kill-Switch tasarım kararı: LOCKED.**

Architecture LOCK için kalan kapı: test/CI doğrulama sözleşmesi ve bütün LOCK belgelerinin tutarlılık incelemesi. BUILD hâlâ kapalıdır.

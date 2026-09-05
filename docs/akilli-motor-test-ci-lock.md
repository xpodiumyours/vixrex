# Vixrex Akıllı Motor — Test + CI LOCK

> Kapsam: Akıllı Motor BUILD sonrası hangi kanıtlar olmadan “çalışıyor / parity var / güvenli” denemeyeceğimizi kilitler. Yeni test platformu kurmaz; mevcut Flutter test, Vitest, Playwright, Supabase local ve CI yüzeylerini kullanır.

## 1. Mevcut kanıtlanan test altyapısı

Repo bugün zaten şunlara sahip:

- Flutter: `dart format`, `dart analyze --fatal-infos`, `flutter test`
- Next.js: ESLint, TypeScript `tsc --noEmit`, Vitest, production build
- Next.js Playwright: `npm run e2e` ve `npm run e2e:local`
- Şema drift kontrolü: 46 alan şeması, kategori core ve mesaj kataloğu
- Supabase local migration + GRANT security guard
- Secret scan
- Main push sonrası canlı public-vitrin E2E

Yeni test framework'ü eklenmez.

## 2. Kanıtlanan mevcut test açığı

### Niyet sözlüğü drift'i

Next.js `shared/vixrex_niyet_sozlugu.json` kaynağını doğrudan okuyor; Flutter `lib/config/vixrex_niyet_sozlugu.g.dart` generated dosyasını kullanıyor.

Ancak mevcut CI schema-drift job'ı:
- `vitrin_alanlari.g.dart`
- `business_categories.g.dart`
- `vixrex_mesajlar.g.dart`

üretip karşılaştırıyor; **`vixrex_niyet_sozlugu.g.dart` üretimi/drift kontrolü yok.**

Repo taramasında bu Dart niyet sözlüğünü üreten doğrulanmış generator script de bulunmadı.

### LOCK

BUILD'in ilk güvenlik işlerinden biri:
- `shared/vixrex_niyet_sozlugu.json` → Dart generated dosya için tek generator oluşturmak/var olanı doğrulamak,
- CI drift job'ına eklemek.

Elle iki sözlüğü paralel bakım kabul edilmez.

---

## 3. Tek shared parity fixture — LOCKED

Flutter ve Next ayrı ayrı “beklenen değer” testleri yazıp buna parity denmez.

Tek ortak veri dosyası iki runtime tarafından tüketilir.

Örnek hedef:

```text
shared/vixrex_motor_parity_fixtures.json
```

Fixture yalnız test verisidir; production motor mantığı içermez.

Her fixture en az:

```text
id
input
expectedDecision
```

ve ilgili senaryoya göre:

```text
expectedDomain
expectedMatchClass
expectedFieldKey
expectedNormalizedValue
expectedOutcome
expectedSpecialFlow
```

taşır.

Dart ve TypeScript aynı dosyayı okuyup aynı canonical sonucu üretir.

---

## 4. Matcher parity gate — LOCKED

Zorunlu örnek sınıfları:

- exact phrase
- exact token
- Türkçe kontrollü ekli biçim
- kısa/generik alias exact-only
- `otel` → `tel` false-positive olmaması
- `il` kelime içi false-positive olmaması
- punctuation sınırı
- fuzzy yalnız suggestion
- ambiguous → mutation yok
- unrelated sentence → none
- iki bağımsız field span
- aynı span'de specificity çözümü

Matcher LOCK belgesindeki bütün koruma fixture'ları burada çalışır.

---

## 5. 46/46 validator + extractor gate — LOCKED

46 alanın her biri en az:

1. bir geçerli gerçek kullanıcı girdisi,
2. bir geçersiz/unsafe girdi,
3. normalize edilmiş beklenen değer,
4. gerekliyse special-flow sonucu

ile test edilir.

Özel zorunlu senaryolar:
- adres semantik kabul/red
- kategori id/label/alias canonicalization
- il/ilçe ambiguity
- lat/lon range
- çalışma saatleri yapısal riskleri
- overnight saat reddi/özel akış
- toggle unknown text → clarification, false fallback yok
- URL protocol allowlist
- anchor yalnız izinli link field
- görsel anchor reddi
- WhatsApp Türkiye normalizasyonu
- telefon harfli değer reddi
- e-posta formatı

Sonuç Dart = TS olmalıdır.

---

## 6. Decision/action contract parity — LOCKED

Aynı input için iki runtime şu canonical sonucu birebir üretir:

```text
outcome
domain
fieldKey
normalizedValue
matchClass
specialFlowKind
```

Runtime'a özel UI metni parity ölçütü değildir; **karar/action semantiği** ölçüttür.

Decision testlerinde DB veya controller side-effect'i olmamalıdır.

Özel test:
- decision engine çağrısı tek başına StoreData, local storage veya Supabase working draft değiştiremez.

---

## 7. Pending state integration gate — LOCKED

Supabase local/integration testleri:

- pending yaz → Next oku
- pending yaz → Flutter adapter oku
- Flutter yaz → Next oku
- clear → iki yüzeyde yok
- missing_value state devam eder
- confirm_candidate `evet` yalnız kayıtlı adayı onaylar
- `hayır/iptal` mutation yapmadan temizler
- invalid pending envelope server tarafından reddedilir
- state write başarısızsa client cross-device persisted kabul etmez

SharedPreferences/local cache tek başına bu testi geçirmez.

---

## 8. DB mutation / idempotency / concurrency gate — LOCKED

Yerel Supabase üzerinde gerçek RPC/integration testleri zorunlu:

1. aynı actionId seri iki çağrı → bir mutation / bir version artışı
2. aynı actionId paralel iki çağrı → bir mutation / bir version artışı
3. aynı actionId farklı payload → `IDEMPOTENCY_KEY_REUSE`
4. stale expected version → conflict, mutation yok
5. doğru version → mutation + yeni version
6. iki farklı field sırayla → ikisi korunur
7. multi-action ortasında conflict → kalan action'lar durur
8. audit old/new/actionId/commandId doğru
9. Undo → action old_value
10. Undo sonrası alan ayrıca değişmiş → `UNDO_CONFLICT`
11. web owner-session başka store yazamaz
12. authenticated user başka store yazamaz
13. protected/legal field bypass edilemez
14. global/storefront kill-switch OFF → assistant mutation yok
15. manuel owner field write kill-switch yüzünden bozulmaz

SQL fonksiyonunun yalnız kaynak metinde adı geçmesi integration test sayılmaz.

---

## 9. Flutter WorkingDraftPort gate — LOCKED

Mevcut port/adaptör sözleşmesi gerçek davranışla doğrulanır:

- `beklenenSurum` gerçekten server'a gider
- `actionId` gerçekten server'a gider
- normal online success gerçek `draftVersion` döndürür
- network yok → `queued_offline`, success değildir
- queue replay aynı actionId'yi korur
- replay duplicate mutation üretmez
- version conflict queue tarafından sessizce overwrite edilmez
- cache yalnız fallback/read continuation, canonical truth değildir

`draftVersion: -1` ile sahte success nihai sözleşmede kabul edilmez.

---

## 10. UX lifecycle test gate — LOCKED

### Next.js

Vitest/component contract ile:
- validated action success göstermiyor
- executing state duplicate send engelliyor
- succeeded server sonucu sonrası oluşuyor
- failed success kartı üretmiyor
- queued offline açıkça ayrı
- partial result saved/failed ayrılıyor
- Undo yalnız succeeded action'da

### Targeted local Playwright

Mevcut `npm run e2e:local` kullanılır; yeni E2E platformu yok.

Tek hedefli owner-assistant senaryosu:

**Mobil**
- panel açık
- mesaj gönder
- panel küçülür/kapanır
- canonical Vixrex control loading durumuna geçer
- storefront görünür kalır
- success'te değişen alan görünür / loading biter
- validation/server error'da panel kullanıcı müdahalesi için görünür

**Masaüstü**
- mevcut layout kırılmaz
- action state davranışı aynı kalır

Accessibility assertion:
- processing/status yalnız görsel spinner değildir; erişilebilir state/status vardır.

Mevcut `vitrin-duzenleme.spec.ts` yalnız yükleme/responsive smoke yaptığı için bu lifecycle kanıtını bugün sağlamıyor.

### Flutter

Widget/controller testleri:
- onboarding step transition'ları korunur
- busy/error görünür state
- companion decision sonucu doğrudan persistence yapmaz
- execution success/failed/queued state mesajları doğru
- runtime flag OFF iken mutation pipeline çalışmaz

---

## 11. Görsel upload security gate — LOCKED

Web mevcut güvenlik testleri korunur.

Flutter için özel regression:
- uzantısı `.webp` olup gerçek WebP olmayan byte dizisi reddedilir
- gerçek JPEG/PNG/WebP kabul edilir
- 5 MB/web ile birebir limit olması zorunlu değilse ürün kuralı ayrıca tanımlanır; fakat güvenli boyut sınırı olmak zorunda
- content type yalnız filename'dan alınmaz
- işlem sonrası upload tipi doğrulanmış içeriğe göre belirlenir

Bu test geçmeden görsel field special-flow parity tamamlanmaz.

---

## 12. CI yüzeyleri — LOCKED

Akıllı Motor BUILD PR'ında ilgili dosyalar değiştiği için en az şu mevcut job'lar yeşil olmalıdır:

- Secret sızıntı taraması
- Supabase auth security config check
- Flutter format/analyze/test
- Next lint/type/test/build
- schema drift
- Supabase local GRANT guard (migration varsa)

Eklenen motor testleri mevcut job'lara mümkün olduğunca entegre edilir; gereksiz yeni job çoğaltılmaz.

Niyet sözlüğü generator/drift kontrolü mevcut schema-drift job'ına eklenir.

DB idempotency/security integration testi mevcut Supabase local doğrulama hattına veya onun dar bir test adımına eklenir.

---

## 13. Main CI kırmızısı — LOCKED işlem kuralı

Son doğrulanan main CI (`33898210471`, SHA `95af697...`) kırmızıdır.

Bu nedenle bugün “repo tamamen yeşil” denemez.

Akıllı Motor çalışma kuralı:
- BUILD branch'inde önce ilgili baseline hatalar tanımlanır,
- motorun sebep olduğu yeni hata sıfıra indirilir,
- pre-existing ilgisiz kırmızı hata engine PR içine fırsatçı refactor olarak alınmaz,
- fakat gerekli merge gate yeşil değilse bu açıkça blocker olarak raporlanır; kırmızı CI ile Smart Engine LOCK açılmaz.

Yani kapsam kontrolü ile kalite kapısı birlikte korunur.

---

## 14. PR / preview / main sırası — LOCKED

```text
architecture LOCK
→ surgical BUILD branch
→ local/unit/integration verification
→ PR
→ PR CI
→ Vercel/owner preview + mobil ekran doğrulama
→ 46/46 matrix sonucu
→ esnaf senaryoları
→ main merge
→ engine flags OFF deploy
→ production smoke
→ controlled flag ON
```

Main'e doğrudan geliştirme commit'i yok.

Main push'taki canlı E2E post-merge savunmadır; tek başına pre-merge gate yerine geçmez.

---

## 15. “46/46 tamamlandı” tanımı — LOCKED

Bir alan yalnız şunların tamamında ✅ olabilir:

```text
schema
intent
value extraction
semantic validation
special-flow (gerekiyorsa)
typed action
server authorization
persistence
idempotency
Flutter/Next parity
UX result
undo (uygunsa)
```

46 satırın tamamı ✅ olmadan:

**46/46 TAMAM** yazılamaz.

## LOCK sonucu

**Test + CI doğrulama sözleşmesi: LOCKED.**

Bütün ana araştırma/mimari alt kapıları artık LOCK belgesine sahiptir. Sıradaki adım: belgeler arası çelişki/tutarlılık denetimi ve tek nihai `ARCHITECTURE LOCK` kararı. BUILD hâlâ kapalıdır.

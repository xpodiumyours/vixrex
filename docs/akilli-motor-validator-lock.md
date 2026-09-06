# Vixrex Akıllı Motor — Validator LOCK

> Kapsam: storefront 46-alan değer doğrulaması ve canonical normalizasyon. Blog/Dijital Çarşı bu LOCK'un dışındadır.

## Amaç

Flutter ve Next.js aynı alan + aynı ham değerde aynı güvenlik kararını ve aynı canonical kayıt değerini üretmelidir. Validator yeni alan kuralları icat etmez; `public_web/src/lib/vitrinFieldSchema.ts` tek kaynaktır.

## Kanıtlanan mevcut farklar

1. `tool/sema_disa_aktar.ts` canonical şemadaki `min/max` değerlerini JSON'a çıkarıyor; `tool/alan_semasi_uret.dart` bunları Dart modeline taşımıyor.
2. Flutter `VixrexFieldValidator` zorunlu alanları, metin uzunluklarını ve enlem/boylam sınırlarını elle tekrar ediyor.
3. Next `validateField` doğrudan `FIELD_BY_KEY` üzerinden canonical şemayı okuyor.
4. Flutter `acikKapali` için `açık/kapalı`, `göster/gizle` gibi esnaf ifadelerini boolean'a çeviriyor; Next yalnız gerçek boolean kabul ediyor.
5. Flutter kategori doğrulaması `BusinessCategoryConfig` üzerinden ikinci bir karar yolu kullanıyor; Next şemadaki `secenekler` listesini kullanıyor.
6. Flutter adresi `AddressValidator` ile doğruluyor. Canonical `adres` alanında bugün özel `dogrulama` adı yok; owner-draft sunucu sınırı yalnız `validateField` kullandığı için aynı adres kalite kuralını zorunlu tutmuyor.

## LOCK — tek kaynak

Validation metadata zinciri değişmez:

```text
public_web/src/lib/vitrinFieldSchema.ts
  ↓ tool/sema_disa_aktar.ts
shared/vitrin_alanlari.json
  ↓ tool/alan_semasi_uret.dart
lib/config/vitrin_alanlari.g.dart
```

Flutter validator alan başına elle `switch` ile min/max/required/uzunluk listesi tutamaz.

## LOCK — Dart şema modeli

`VitrinAlani` canonical JSON'da zaten bulunan aşağıdaki alanları eksiksiz taşımalıdır:

- `zorunlu`
- `minUzunluk`
- `maxUzunluk`
- `min`
- `max`
- `secenekler`
- `dogrulama`
- `bosDegerler`

Yeni validation metadata gerekiyorsa önce canonical TypeScript şemasına eklenir; Dart'a özel ikinci şema oluşturulmaz.

## LOCK — ortak doğrulama davranışı

### Boş değer

- Optional boş değer → `ok=true`, canonical değer `null`.
- `zorunlu=true` boş değer → `ok=false`.
- Required listesi hiçbir runtime'da elle tutulmaz.

### Metin sınırları

- `minUzunluk` / `maxUzunluk` yalnız canonical şemadan okunur.
- Kullanıcı girdisi önce trim edilir; uzunluk trimmed değer üzerinden kontrol edilir.

### Sayı

- Number veya sayısal string kabul edilir.
- Virgül ondalık ayıracı `.` olarak normalize edilebilir.
- Sonuç finite sayı olmalıdır.
- `min/max` canonical şemadan okunur.

### Telefon

- Genel telefon: yalnız rakamlar canonical değere çevrilir; 10–13 rakam.
- `dogrulama=tr_mobil`: Türkiye mobil normalizasyonu iki runtime'da aynı sonucu üretir (`05xx...` → `905xx...`).

### E-posta

- İki runtime aynı temel e-posta sözleşmesini uygular.

### URL / görsel

- `#...` sayfa içi çapa kabul edilir.
- Diğer değerler yalnız geçerli `http` veya `https` URL olabilir.
- Protokol yazmak tek başına yeterli değildir; URL parser tarafından geçerli adres olmalıdır.

### Seçim

- Geçerli seçenek kaynağı yalnız `alan.secenekler`.
- Validator `BusinessCategoryConfig` gibi ikinci bir seçenek kaynağına gitmez.
- Canonical kayıt değeri şemadaki seçenek değeridir.
- Kategori seçme UX'i/special-flow ayrı katmandır; validator yeni kategori üretmez.

### Açık / kapalı

Esnaf sohbeti string değer üretebildiği için iki runtime aynı sınırlı coercion sözleşmesini kullanır.

`true`:
- gerçek boolean `true`
- `açık`, `acik`, `göster`, `goster`, `evet`, `on`, `true`, `1`

`false`:
- gerçek boolean `false`
- `kapalı`, `kapali`, `gizle`, `hayır`, `hayir`, `off`, `false`, `0`

Bunların dışındaki değer mutation üretemez.

### Adres

Canonical `adres` alanı özel validator kullandığını şemada açıkça taşımalıdır (`dogrulama: "adres"`).

- Flutter mevcut `AddressValidator` davranışını korur.
- Next mevcut `addressValidator.ts` eşdeğerini `validateField` içinde aynı `dogrulama` adıyla uygular.
- Böylece landing/onboarding ve owner-draft motor yazma sınırı aynı adres kalite kuralına gelir.

## API / katman sınırı

- Next: `validateField(anahtar, hamDeger: unknown)` canonical sunucu doğrulama sınırı olmaya devam eder.
- Flutter: motor validator'ı `anahtar` üzerinden generated `alanAnahtarla` metadata'sını bulur; intent sözlüğündeki açıklama metnini validation schema olarak kullanmaz.
- Flutter mevcut çağrı uyumu için intent alanı alan adapter tutabilir, fakat gerçek karar canonical `VitrinAlani` üzerinden verilir.
- Bilinmeyen alan → fail-closed.

## Shared parity fixture

Tek fixture seti iki runtime'da en az şunları kanıtlamalıdır:

- required boş → red
- optional boş → `null`
- min/max metin sınırı
- Türkiye mobil normalize + geçersiz mobil red
- genel telefon normalize
- e-posta geçerli/geçersiz
- URL http/https geçerli, ftp geçersiz
- enlem/boylam min/max
- geçerli/geçersiz seçim
- `açık/göster` → `true`
- `kapalı/gizle` → `false`
- bilinmeyen boolean sözcüğü → red
- geçerli adres → kabul
- `asd` gibi eksik adres → red

Fixture'da iki runtime için beklenen `ok` ve canonical `deger` aynıdır.

## Değiştirilmeyecekler

Bu adımda:

- executor yeniden yazılmaz,
- persistence değiştirilmez,
- pending/task state değiştirilmez,
- Blog/Dijital Çarşı açılmaz,
- 46-alan sayısı değiştirilmez,
- yeni AI/LLM bağımlılığı eklenmez.

## LOCK sonucu

**Validator tasarım kararı: LOCKED.**

BUILD sırası:

1. Dart generated şemaya `min/max` ekle.
2. `adres` canonical validation metadata'sını ekle.
3. Flutter validator'ı canonical generated metadata'ya bağla.
4. Next `acikKapali` + adres davranışını ortak sözleşmeye hizala.
5. Shared validator fixture ekle.
6. Dar Next/Flutter parity CI çalıştır.
7. Matcher + validator kapıları ikisi de yeşil olmadan 5.2 tamamlandı sayma.

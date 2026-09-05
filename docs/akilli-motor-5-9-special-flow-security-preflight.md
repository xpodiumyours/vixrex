# Vixrex Akıllı Motor — 5.9 Special-flow Security Parity Preflight LOCK

> Kapsam: generic 46-field mutation'ın dışında bilinçli özel akışta kalan görsel, il/ilçe/GPS, çalışma saatleri ve ilgili toggle/url güvenlik sınırları.

## Kanıtlanan güncel durum

### Görseller

- Next `/api/owner-upload` daha önce doğrulanan server sınırında JPEG/PNG/WebP magic-byte/content kontrolleri ve yeniden işleme uygular.
- Flutter `ImageOptimizationService` kaynak tipini **caller'ın fileExtension/contentType değerinden** seçiyor.
- Flutter WebP seçilirse bytes decode/signature doğrulaması yapılmadan ham bytes `image/webp` olarak geri dönüyor.
- `StoreShelfUploadService` uzantı/contentType'ı caller'dan alıp optimizer'a veriyor.

Sonuç: Flutter WebP content spoofing parity açığı hâlâ mevcut.

### İl / ilçe

- Next `turkeyPlaceMatcher` kelime-sınırlı eşleşme kullanıyor.
- Aynı isimli/ambiguous ilçe, il metinde açıkça doğrulanmadıkça tahmin edilmiyor.
- Generic motor `il` / `ilce` için `needsSpecialFlow` kullanıyor; kör serbest field mutation yapılmaması doğru.
- Next owner UI il/ilçe dropdown kullanıyor.

### GPS

- Next owner UI browser GPS sonrası `enlem`, `boylam`, `adres`, `il`, `ilçe` alanlarını bugün **5 ayrı `/api/owner-draft` çağrısıyla `Promise.all`** gönderiyor.
- Bu akış kısmi başarı bırakabilir: koordinat yazılıp adres/ilçe yazılmayabilir veya tersi.
- `owner-structured-field` yalnız JSONB kolonlar içindir; location bundle için doğru yüzey değildir.

### Çalışma saatleri

- `workingHours.weekMapFromPlainString()` tek `HH:MM-HH:MM` aralığını Pazartesi–Cumartesi açık, Pazar kapalı olarak varsayıyor.
- Bu, esnafın hangi günleri kastettiğini bilmeden veri üretir.
- `resolveOpenState()` `start < end` varsayımıyla çalışır; `22:00-02:00` overnight aralığını doğru açık-state olarak hesaplamaz.

### Toggle / URL

- 5.2 validator BUILD ile explicit toggle allowlist/canonical boolean ve URL/görsel ayrımı hizalandı.
- Bu davranış 5.9'da ikinci kez yeniden yazılmayacak; special-flow testlerinde regresyon olarak korunacak.

## 5.9 LOCK 1 — Görsel gerçek içerik doğrulaması

Flutter file extension ve MIME header'a güvenmez.

Optimizer input'ta en az magic-byte kontrolü:

```text
JPEG: FF D8 FF
PNG : 89 50 4E 47 0D 0A 1A 0A
WebP: RIFF .... WEBP
```

uygulanır.

Kurallar:
- declared extension/contentType gerçek signature ile uyuşmuyorsa reject,
- desteklenmeyen gerçek içerik reject,
- WebP ham pass-through olsa bile önce gerçek WebP signature + decode/dimension kontrolü,
- mümkün olan formatlarda re-encode metadata/payload riskini azaltmaya devam eder,
- 5 MB ve upload path/bucket kuralları mevcut yüzeyde korunur.

Yeni upload sistemi veya yeni bucket kurulmaz.

## 5.9 LOCK 2 — Görsel URL field ile upload ayrımı

`logo`, `kapakGorseli`, `bantGorsel`, `hakkindaGorsel` generic sohbet alanı olarak düz rastgele string kabul etmez.

- authoritative field value yalnız doğrulanmış `https://` görsel URL olabilir,
- esnaf ana UX'i dosya/hazır görsel akışıdır,
- `#anchor`, `data:`, `javascript:`, `ftp:` görsel alanında reject,
- upload güvenliği field validator yerine upload boundary'de ayrıca korunur.

## 5.9 LOCK 3 — İl/ilçe special flow

Generic NLU:
- il/ilçe intent'ini anlayabilir,
- fakat serbest tahminle mutation yapmaz,
- `needs_special_flow` döndürür.

Kanonik değer yalnız Vixrex Türkiye il/ilçe listesinden gelir.

İl değişirse mevcut ilçe:
- yeni il altında geçerli değilse birlikte temizlenir,
- eski ilçeyi sessizce korumaz.

Ambiguous district için il bilinmiyorsa netleştirme gerekir.

## 5.9 LOCK 4 — GPS location bundle coupled transaction

GPS generic multi-action değildir.

Bundle:

```text
enlem
boylam
adres
il
ilce
```

tek special-flow execution olarak ele alınır.

5.5 authoritative transaction temelinin dar location-bundle varyantı kullanılacaktır:

```text
AUTH
 -> validate latitude/longitude range
 -> validate canonical province/district relation
 -> validate address semantic minimum
 -> lock working draft
 -> expected version check
 -> write bundle atomically
 -> one logical command/audit relation
 -> return new draft version
```

**Ya tamamı yazılır ya hiçbiri.**

Yeni genel batch framework açılmaz.

`location_accuracy_meters` ve `location_source` operasyonel metadata ise canonical storefront field sözleşmesine kör eklenmez; mevcut StoreData/DB güvenlik sınırına göre special-flow metadata olarak ayrıca doğrulanır.

## 5.9 LOCK 5 — GPS reverse-geocode güveni

Reverse-geocode sonucu mutlak hakikat sayılmaz.

- lat/lon browser geolocation'dan gelir,
- province/district sonucu canonical Türkiye listesine normalize edilir,
- listeyle eşleşmeyen il/ilçe yazılmaz,
- address boş/zayıfsa kullanıcıya elle düzeltme imkanı verilir,
- accuracy kullanıcıya gösterilebilir ama authorization/veri doğruluğu kanıtı değildir.

## 5.9 LOCK 6 — Çalışma saatleri generic free-write değildir

Akıllı Motor tek `09:00-18:00` metninden günleri **tahmin etmez**.

Örnek:

`09:00-18:00 açığız`

→ gün bilgisi yoksa doğrudan Mon-Sat yazmak YASAK.

Motor netleştirir:
- hangi günler?
- kapalı gün var mı?

Yapısal week map üretildikten sonra doğrulama yapılır.

Mevcut `weekMapFromPlainString` public legacy/fallback görüntüleme davranışı olabilir; assistant mutation kaynağı değildir.

## 5.9 LOCK 7 — Overnight saat

`22:00-02:00` gibi aralık:

- mevcut open-state algoritması desteklemeden assistant tarafından doğrudan yapısal kayıt edilmez,
- ya overnight algoritması iki runtime/public display için doğrulanarak eklenir,
- ya kullanıcıya bu saat tipinin henüz otomatik uygulanamadığı açıkça söylenir.

Sessizce `Kapalı` hesaplayan veri üretilemez.

## 5.9 LOCK 8 — Çalışma saatleri coupled structure

Haftalık çalışma saati tek field string gibi değil, 7 günün yapısal state'i olarak ele alınır.

Special flow:
- saat biçimi,
- start/end,
- active,
- gün anahtarları,
- overnight desteği
birlikte doğrulanır.

Generic 46-field partial action bunu parçalamaz.

## 5.9 LOCK 9 — Toggle regresyon koruması

5.2 canonical davranış korunur:

True explicit allowlist:
`aç/ac/açık/acik/göster/goster/evet/on/true/1`

False explicit allowlist:
`kapat/kapalı/kapali/gizle/hayır/hayir/off/false/0`

Bilinmeyen:
- `bilmiyorum`,
- ilgisiz metin

→ clarification; false fallback YOK.

## 5.9 LOCK 10 — URL regresyon koruması

- normal URL field: yalnız http/https,
- generic image field: yalnız doğrulanmış https/http görsel URL sınırı,
- `#anchor` yalnız açıkça anchor destekleyen action-link alanında,
- image URL ile gallery action link aynı validator gibi davranmaz.

## 5.9 LOCK 11 — Flutter / Next parity

Aynı special-flow fixture'ları iki runtime/katmanda aynı sonucu üretmelidir:

```text
valid
invalid
needs_special_flow
needs_clarification
blocked
```

Coupled flow persistence testi DB integration katmanında yapılır; yalnız client unit testi yeterli değildir.

## BUILD sırası

5.9 runtime BUILD sırası:

1. Flutter image signature/WebP hardening
2. il/ilçe canonical relation testleri
3. 5.5 authoritative location-bundle transaction
4. GPS owner UI'yi Promise.all field writes'tan bundle execution'a geçir
5. çalışma saatleri structured special-flow contract
6. overnight destek kararı + test
7. toggle/url regression fixtures

5.5 DB katmanı hazır olmadan GPS atomic bundle production yoluna bağlanmaz.

## Doğrulama kapıları

1. fake `.webp` + non-WebP bytes Flutter reject
2. fake MIME/extension JPEG/PNG mismatch reject
3. gerçek WebP decode/signature pass
4. ambiguous district province yok -> mutation yok
5. province değişimi invalid old district'i temizler
6. GPS bundle bir alan fail -> hiçbir field yazılmaz
7. GPS valid -> tüm bundle tek version transaction sonucu
8. plain `09:00-18:00` günsüz -> assistant tahmin yapmaz
9. overnight unsupported -> yanlış open-state üretilmez
10. toggle unknown -> false olmaz
11. image anchor/url invalid reject
12. Flutter/Next special-flow parity fixture sonuçları aynı

## Sonuç

**5.9 Special-flow Security Parity preflight: LOCKED.**

Runtime BUILD 5.5/5.8 dependency'leri hazır oldukça ilgili alt adımlarla uygulanır. Main/production bu belgeyle değişmez.

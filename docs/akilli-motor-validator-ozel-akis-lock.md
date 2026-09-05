# Vixrex Akıllı Motor — Validator + Özel Akış LOCK

> Kapsam: storefront 46 alanın değer doğrulaması ve özel akış kararı. Bu belge BUILD yapmaz; hangi girdinin doğrudan mutation üretebileceğini, hangisinin netleştirme/özel akış gerektirdiğini kilitler.

## Ana ilke

AI API yok. Motorun görevi tahmin etmek değil; kullanıcıdan gelen değeri Vixrex'in gerçek iş kurallarına göre güvenli biçimde kanonikleştirmek, doğrulamak ve yalnız doğrulanmış action üretmektir.

LOCK ilkeleri:

1. **Biçim doğrulaması + semantik doğrulama birlikte zorunlu.** Sadece tip/uzunluk yeterli değildir.
2. **İstemci doğrulaması UX içindir; sunucu doğrulaması otoritedir.** `/api/owner-draft` semantik olarak geçersiz değeri RPC'ye geçiremez.
3. **Allowlist / kanonik sözleşme tercih edilir.** Seçim, toggle, kategori, dosya türü gibi sonlu alanlarda varsayılan/fallback tahmin yoktur.
4. **Belirsiz değer mutation üretmez.** `needsClarification` veya `needsSpecialFlow` döner.
5. **Motor anladı ≠ veri kaydedildi.** Başarı yalnız persistence/executor başarısından sonra gösterilir.
6. **Mevcut güvenli Vixrex yolları korunur.** Yeni upload, yeni kategori listesi, yeni GPS sistemi, yeni yazma yolu açılmaz.

Araştırma dayanağı:
- OWASP Input Validation: syntactic + semantic validation; allowlist/range/structure.
- OWASP File Upload: content-type'a güvenmeme, signature/content doğrulama, izinli türler, boyut limiti, yetki, uygulama üretimli dosya adı.
- W3C form validation: istemci doğrulaması UX sağlar ancak sunucu doğrulaması gereklidir; hata düzeltilebilir ve anlaşılır olmalıdır.
- Google Maps architecture guidance: adres doğrulama ile geocoding ayrı problemler; kullanıcı girdisi için doğruluk/geri bildirim, harita için koordinat çözümü farklıdır.

## Kilitli doğrulama zinciri

```text
ham kullanıcı mesajı
  ↓
matcher → alan
  ↓
value extractor
  ↓
field canonicalizer
  ↓
semantic validator
  ↓
typed action (proposed/validated)
  ↓
server authoritative validation
  ↓
executor / mevcut yazma yolu
  ↓
persistence sonucu
```

Client tarafında kabul edilmiş bir değer, server validator aynı sonucu vermeden kalıcı yazılamaz.

---

## 1. Basit metin / uzun metin alanları — LOCKED

Şema min/max/zorunlu kuralları korunur.

- Kullanıcının metni içerik olarak uydurulmaz.
- Motor otomatik olarak kampanya/fiyat/işletme gerçeği üretmez.
- Normalizasyon yalnız matching/canonicalization için kullanılır; kaydedilecek kullanıcı metninin Türkçe karakterleri bozulmaz.
- Boş değer yalnız şemada izinliyse alan temizleme action'ına dönüşebilir.

Bu sınıf mevcut şema tabanlı `validateField` yaklaşımıyla uyumludur.

---

## 2. Adres — LOCKED

### Kanıtlanan mevcut durum

Flutter `AddressValidator` ve web `addressValidator.ts` aynı dar kurala sahiptir:
- minimum 10 karakter,
- rakam veya sokak/cadde/mahalle benzeri yer belirteci,
- kullanıcıya düzeltme örneği veren hata mesajı.

Fakat `/api/owner-draft` bugün genel `vitrinFieldValidation` kullanır; bu semantik adres kontrolü sunucu yazma sınırına bağlı değildir.

### LOCK kararı

- Adres semantik validator iki runtime'da aynı kalır.
- Sunucu `owner-draft` yazma sınırı da aynı adres semantiğini uygulamak zorundadır.
- `asd`, yalnız şehir adı, telefon numarası gibi değerler adres diye yazılamaz.
- Motor adresi Google/harita servisinden sessizce düzeltmez.
- GPS **opsiyonel özel akıştır**; adres metni yerine geçmesi zorunlu değildir.
- Harici ücretli Address Validation API bu faza eklenmez; kapsam büyütülmez.

Sonuç: `adres` = **doğrudan aday + semantik validator + mevcut GPS özel akışı**.

---

## 3. Kategori — LOCKED

### Tek kaynak

`shared/business_categories.json` kanonik kaynaktır.
- Web doğrudan okur.
- Flutter `tool/business_categories_uret.dart` ile üretilmiş kopyayı kullanır.
- CI drift kontrolü vardır.

### LOCK kararı

Motor kategori için yeni liste tutmaz.

Kabul edilen değer yalnız:
- kanonik kategori label'ı,
- kanonik kategori id'si,
- aynı shared kaynaktaki açık alias

olabilir.

Kanonical kayıt değeri: **shared sözlükteki kategori label'ı**.

Güvenlik:
- Exact normalize id/label/alias eşleşmesi → doğrudan validated action.
- Paragraf içinde partial substring eşleşmesi yalnız extraction ipucu olabilir; tek başına mutation yetkisi değildir.
- Birden fazla kategori adayı → clarification.
- Eşleşmeyen değer → mevcut kategori seçim listesine yönlendirme.
- `Diğer` yalnız kullanıcı açıkça seçerse kullanılabilir; motor bunu fallback varsayılanı yapamaz.

Sonuç: `kategori` = **kanonik allowlist + gerektiğinde seçim özel akışı**.

---

## 4. İl / İlçe / Enlem / Boylam — LOCKED

### Kanıtlanan mevcut Vixrex davranışı

- Next sahiplik panelinde il dropdown, ilçe seçili ile bağlı dropdown olarak mevcut.
- GPS butonu adres/enlem/boylam için mevcut.
- `turkeyPlaceMatcher.ts` il/ilçe adlarında kelime sınırı kullanıyor.
- Aynı ilçe birden fazla ildeyse açık il bilgisi yoksa tahmin etmiyor.

### LOCK kararı

`il` ve `ilce` düz serbest metin mutation alanı değildir.

- Güvenli, benzersiz il eşleşmesi → kanonik il adı.
- Güvenli il + ona bağlı benzersiz ilçe → kanonik çift.
- Belirsiz ilçe → mutation yok, kullanıcıdan il seçmesi istenir.
- İl değişince eski ilçe doğrulanmadan korunamaz.
- UI'da mevcut dropdown/listeler ana özel akıştır.

`enlem` / `boylam`:
- Teknik alanlardır; esnafa ana sohbet UX'inde ham koordinat yazdırmak hedef değildir.
- Ana özel akış mevcut GPS konumudur.
- Kullanıcı açıkça teknik koordinat verirse sayı/range validator kullanılabilir; aksi halde GPS/adres akışına delege edilir.

Sonuç:
- `il`, `ilce` = **özel akış**
- `enlem`, `boylam` = **GPS öncelikli özel akış; açık teknik girdide range validator**

---

## 5. Çalışma Saatleri — LOCKED, mevcut davranış BUILD öncesi düzeltilmeli

### Kanıtlanan mevcut risk

`workingHours.ts` tek bir `HH:MM - HH:MM` aralığını parse ediyor.

Bugünkü public davranış:
- plain string aralığı Pazartesi–Cumartesi açık, Pazar kapalı varsayımına çevriliyor,
- open-state hesabı `minutes >= start && minutes < end` kullanıyor,
- geceyi aşan `22:00 - 02:00` aralığı doğru temsil edilmiyor.

46-alan validator ise bugün `calismaSaatleri` alanını esas olarak metin uzunluğu seviyesinde kabul ediyor.

### LOCK kararı

Motor çalışma saatlerini kör serbest metin olarak yazamaz.

İlk güvenli destek:
- `H:MM - H:MM` veya `HH:MM - HH:MM`,
- saat 00–23,
- dakika 00–59,
- başlangıç ve bitiş geçerli.

Ancak **gün bilgisi belirtilmemişse motor haftanın günlerini tahmin edemez.**

Bu nedenle:
- Kullanıcı sadece saat aralığı verirse motor bunu doğrudan “haftalık program” olarak yorumlamaz.
- Mevcut Vixrex günlük/haftalık saat editörü varsa özel akışa yönlendirir; yoksa netleştirme ister.
- `22:00 - 02:00` gibi geceyi aşan aralık, open-state algoritması gece geçişini desteklemeden otomatik mutation üretemez.
- `09:00 - 09:00` belirsiz/kapalı anlamında yorumlanmaz; clarification gerekir.

Amaç yeni takvim sistemi kurmak değil; yanlış “Açık/Kapalı” göstergesini engellemektir.

Sonuç: `calismaSaatleri` = **semantik/yapısal özel akış**.

---

## 6. Açık / Kapalı (`acikKapali`) — LOCKED

Alanlar:
- `puanGoster`
- `yolTarifiGoster`

### Kanıtlanan mevcut risk

- Flutter validator olumlu/olumsuz doğal dil varyantlarını boolean'a dönüştürüyor.
- Next genel validator yalnız boolean kabul ediyor.
- Next seçili-alan UX'inde birkaç olumlu kelime `true`; **diğer her metin `false`** oluyor. Bu nedenle belirsiz bir ifade yanlışlıkla alanı kapatabilir.

### LOCK kararı

Tek shared boolean parser davranışı:

**TRUE allowlist**
- `aç`, `ac`, `açık`, `acik`, `göster`, `goster`, `evet`, `on`, `true`, `1`

**FALSE allowlist**
- `kapat`, `kapalı`, `kapali`, `gizle`, `hayır`, `hayir`, `off`, `false`, `0`

Bunun dışındaki değer:
- boolean değildir,
- `false` fallback olamaz,
- mutation yok → clarification.

İki runtime aynı parser fixture'ını geçmeden parity tamamlanmış sayılmaz.

Sonuç: `acikKapali` = **explicit allowlist parser**.

---

## 7. URL alanları — LOCKED

Normal URL alanları:
- `website`
- `haritaLinki`
- `referansLinki`

`galeriAksiyonLinki` ayrıca sayfa içi `#anchor` destekleyebilir.

### LOCK kararı

- Normal dış URL'ler: yalnız `http:` / `https:`.
- `#anchor` yalnız şemada açıkça izin verilen link alanında geçerli olabilir.
- URL doğrulaması alan tipine göre yapılır; tek ortak “url/gorsel” helper ile davranış paylaşılmaz.
- `javascript:`, `data:`, `file:` vb. kabul edilmez.

---

## 8. Görsel alanları — LOCKED

Alanlar:
- `logo`
- `kapakGorseli`
- `bantGorsel`
- `hakkindaGorsel`

### Kullanım LOCK'u

Esnaf ana sohbet UX'inde URL yazmaya zorlanmaz.

Ana akış:
1. Fotoğraf seç / hazır görsel seç.
2. Mevcut güvenli upload mekanizması.
3. Dönen `https` URL normal owner-draft yazma yolundan kaydedilir.

### Web tarafında korunacak güvenlik

`/api/owner-upload` bugün:
- HttpOnly owner session,
- yalnız şemadaki `gorsel` alanları,
- JPG/PNG/WebP allowlist,
- gerçek dosya magic-byte kontrolü,
- 5 MB limit,
- rate limit,
- server-generated path/filename,
- 1600px sıkıştırma,
- upload ile field write ayrımı
uyguluyor.

Bu güvenli yol korunur; motor ikinci upload endpoint'i açmaz.

### Flutter güvenlik açığı — BUILD öncesi kapatılmalı

Flutter `ImageOptimizationService`:
- JPEG/PNG için decode/yeniden işleme yapıyor,
- ancak WebP girdisinde yalnız extension/contentType üzerinden `webp` kabul edip raw bytes döndürüyor.

`StoreShelfUploadService` de contentType/extension değerini çağırandan alıyor.

Bu nedenle web'deki “gerçek byte/signature + decode” güvenlik seviyesi Flutter'da WebP için kanıtlanmış değil.

LOCK kararı:
- Flutter da dosyayı yalnız kullanıcı bildirimine göre tür sayamaz.
- JPG/PNG/WebP gerçek dosya içeriği doğrulanmalı.
- WebP de decode/gerçek imza doğrulamasından geçmeli.
- Sonuç dosya tipi işlem sonrası tespit edilen tipe göre belirlenmeli.

Sonuç: görsel alanları = **özel upload akışı + dosya güvenlik parity'si**.

---

## 9. Telefon / WhatsApp — LOCKED

- `whatsapp`: Türkiye mobil normalizasyonu korunur.
- `telefon`: 10–13 rakam sınırı korunur.
- Harf içeren telefon verisi doğrudan mutation olamaz.
- Normalized değer iki runtime'da aynı olmalıdır.

---

## 10. E-posta — LOCKED

Mevcut dar e-posta biçim doğrulaması korunur.

- Format geçmiyorsa mutation yok.
- Motor e-postayı tahmin/tamamlamaz.
- Kullanıcıya düzeltme mesajı gösterilir.

---

## Server authoritative validation — zorunlu LOCK

`/api/owner-draft` yazma sınırı nihai güvenlik kapısıdır.

BUILD sonrası server validator şu semantik kuralları da uygulamalıdır:
- adres,
- kategori kanonik allowlist,
- çalışma saatleri güvenli yapı,
- toggle explicit boolean,
- URL alanına özel protocol/anchor kuralı,
- görsel alanında yalnız güvenli upload sonucu / uygun https URL kontratı,
- sayı range.

Client tarafındaki parser/validator aynı sonucu üretmeli, fakat server sonucu otoritedir.

---

## Özel akış sınıfları — nihai tablo

| Alan / tip | LOCK davranışı |
|---|---|
| normal metin/uzun metin | doğrudan validator |
| whatsapp/telefon | doğrudan + normalize |
| e-posta | doğrudan format validator |
| normal URL | doğrudan http/https validator |
| galeri aksiyon linki | http/https veya izinli anchor |
| kategori | kanonik allowlist; gerekirse seçim |
| adres | semantik validator + opsiyonel GPS |
| il/ilçe | seçim/kanonik yer özel akışı |
| enlem/boylam | GPS öncelikli; açık teknik girdide range |
| çalışma saatleri | yapısal/semantik özel akış |
| açık/kapalı | explicit true/false allowlist; belirsizde clarification |
| görsel | upload/hazır görsel özel akışı |

---

## BUILD'de kapsam sınırı

Bu LOCK uygulandığında:

YAPILACAK:
- mevcut validator'ları ortak davranışa hizalamak,
- server semantik validation kapısını tamamlamak,
- mevcut özel akışlara delegation,
- shared parity fixture'ları,
- görsel Flutter güvenlik parity açığını kapatmak.

YAPILMAYACAK:
- AI/LLM eklemek,
- ücretli adres API'si eklemek,
- yeni kategori sistemi kurmak,
- yeni upload sistemi kurmak,
- Blog/Dijital Çarşı domain'i açmak,
- 46 alan dışı yeni ürün özellikleri eklemek,
- UI'yı bu fazda baştan tasarlamak.

## LOCK sonucu

**Validator + özel akış tasarım kararı: LOCKED.**

Bu LOCK, matcher LOCK ile birlikte 46/46 doğrulama matrisinin karar tarafını sabitler. BUILD hâlâ açılmaz; sıradaki ana kapılar state/action/executor + idempotency/concurrency + UX yaşam döngüsüdür.

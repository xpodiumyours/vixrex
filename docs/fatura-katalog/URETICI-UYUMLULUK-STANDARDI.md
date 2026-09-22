# Vixrex Uyumlu Üretici Standardı

Tarih: 2026-09-22  
Kilitli hedef: `docs/fatura-katalog/KILITLI-HEDEF.md`

Bu belge “hangi üreticileri listeleyelim?” sorusunu değil, **hangi üretici/fatura ilişkisinin güvenilir otomasyona uygun olduğunu** tanımlar.

## 1. Üretici kimliği kanıtlanabilmeli

En az bir güçlü kimlik izi gerekir:

- faturadaki ticari unvan / vergi kimliği,
- üreticinin resmî alan adı,
- doğrulanmış marka–üretici ilişkisi,
- GTIN sahibi şirket bilgisi,
- üreticinin sağladığı resmî bayi/feed bağlantısı.

Sadece arama motorunda benzer bir isim çıkması güçlü kanıt sayılmaz.

## 2. Faturadaki ürünün kararlı bir kimliği olmalı

Üründe aşağıdakilerden biri veya bunların yeterli birleşimi bulunmalıdır:

- GTIN / barkod,
- üretici SKU / model kodu,
- tedarikçi stok kodu,
- ayırt edici ürün adı + varyant/beden/paket bilgisi.

**Barkod zorunlu değildir.** Kimlik yoksa ürün tahmin edilmez.

## 3. Aynı ürün dijital dünyada yeniden bulunabilmeli

Tercih edilen kaynak sırası:

1. üretici/tedarikçi XML, API veya resmî ürün feed'i,
2. üreticinin resmî ürün sayfası veya resmî katalogu,
3. doğrulanmış ürün kimliği sağlayıcısı (ör. GTIN/GS1 kimlik doğrulaması),
4. üreticinin esnafa verdiği resmî dijital katalog,
5. web araması yalnız keşif için.

Arama sonucu tek başına ürün gerçeği veya kullanım hakkı sayılmaz.

## 4. Fatura ürünü ile dijital ürün arasında kanıt bağı kurulmalı

Eşleşme gerekçesi saklanır:

- aynı GTIN,
- aynı üretici SKU/model,
- aynı tedarikçi stok kodu,
- birden fazla alanın birlikte tam eşleşmesi,
- esnaf/tedarikçi doğrulaması.

“İsmi benziyor” tek başına otomatik hazırlama için yeterli değildir.

## 5. Veri ve görsel kullanım dayanağı ayrı tutulmalı

Ürünü bulmak, ürün verisini/görselini kullanma hakkı olduğu anlamına gelmez.

Vixrex teknik olarak şu durumları ayırır:

- `verified_supplier_permission`: üretici/tedarikçi açıkça izin verdi,
- `verified_feed_terms`: sağlanan feed/API kullanım koşulu kapsam içinde,
- `merchant_owned_media`: esnafın kendi çektiği/yüklediği medya,
- `merchant_attestation`: esnaf yetkisi olduğunu beyan etti; platform doğrulaması yok,
- `unknown`: kullanım dayanağı bilinmiyor,
- `denied`: kullanım izni yok veya geri çekilmiş.

Dış üretici görselinin otomatik yayına girmesi için doğrulanmış bir kullanım dayanağı gerekir. `unknown` durumunda Vixrex soru sorar; varsayım yapmaz.

## 6. Üretici uyumluluk sonucu

### Güçlü iz

- üretici kimliği doğrulanmış,
- ürün kimliği güçlü,
- resmî dijital ürün bulunmuş,
- alanların kaynak izi tutulabiliyor.

Sonuç: **taslak kart otomatik hazırlanabilir.**

### Kısmi iz

- üretici veya ürün büyük ölçüde belli,
- fakat kritik bir kimlik/izin/görsel halkası eksik.

Sonuç: **yalnız eksik bilgi sorulur.**

### Zayıf iz

- ürün kimliği veya kaynak bağı güvenilir değil.

Sonuç: **ürün tahmin edilmez ve otomatik kart hazırlanmaz.**

## 7. Tek üreticide ilk kabul kanıtı

İlk üretici üzerinde aşağıdaki zincir çalışmalıdır:

1. gerçek fatura satırı okunur,
2. üretici tanınır,
3. ürün kimliği çözülür,
4. resmî dijital ürün eşleşir,
5. ürün adı/özellik/görsel adaylarının kaynağı tutulur,
6. kullanım izni durumu belirlenir,
7. taslak ürün kartı hazırlanır,
8. satış fiyatı alış fiyatından ayrı kalır,
9. esnaf onaylamadan public olmaz,
10. onay sonrası mevcut Product CORE'a yazılır.

Üreticiye özel parser veya elle yazılmış ürün listesi kullanılırsa bu kabul sağlanmış sayılmaz.

## 8. Üretici havuzu için giriş şartı

Üretici havuzu ancak yukarıdaki çalışan kanıt tamamlandıktan sonra açılır.

Havuza alınan her üreticide en az:

- doğrulanmış şirket/marka kimliği,
- kullanılabilir ürün kimliği yöntemi,
- resmî dijital kaynak,
- veri/görsel kullanım durumu,
- son doğrulama tarihi

tutulur.

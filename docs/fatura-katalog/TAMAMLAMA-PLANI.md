# Faturadan Kataloğa — Uçtan Uca Tamamlama Planı

Tarih: 2026-09-22  
Çalışma dalı: `work/fatura-katalog-e2e-20260922`  
Başlangıç main SHA: `0034fe06942c4fdbe625f24bc338ef8cfa6e8a0b`

## 1. Kilitli hedef

Kullanıcı deneyimi şu sırada kalır:

1. Esnaf faturayı çeker veya seçer.
2. Vixrex faturadaki ürün satırlarını gerçek veriden çıkarır.
3. Model/stok kodu, barkod, ürün adı, varyant/renk, beden, miktar, alış fiyatı ve satır toplamı ayrı alanlara ayrılır.
4. Fatura toplamı ve miktarlar mümkün olduğunda doğrulanır.
5. Vixrex ürünleri kendi ürün hafızası ve izinli tedarikçi/üretici verileriyle zenginleştirir.
6. Gerekiyorsa yalnız belirsiz kayıtlar için yapay zekâ desteği kullanılır.
7. Satış fiyatı alış fiyatından ayrı tutulur.
8. Ürünler taslak kart olarak gösterilir; esnaf kontrol eder.
9. Esnaf onaylamadan hiçbir ürün yayınlanmaz.
10. Onaylanan kartlar mevcut Product CORE üzerinden aynı Vixrex vitrinine yazılır.

Hedef ön yüz, daha önce hazırlanan “Faturanı çek. Ürünlerin hazır olsun.” prototipindeki dört aşamalı akıştır. Prototipteki sahte/önceden yazılmış ürün verisi gerçek uçtan uca sistemle değiştirilir.

## 2. Bu dalın güvenlik sınırı

Bu dal geliştirme alanıdır.

- `main` değiştirilmeyecek.
- PR açılmayacak.
- Merge yapılmayacak.
- Production deploy yapılmayacak.
- Canlı Supabase'e migration uygulanmayacak.
- Canlı veri üzerinde OCR testi yapılmayacak.
- Vercel preview otomatik açılmayacak.
- Dış yapay zekâ API'sine gerçek fatura gönderimi varsayılan olmayacak.
- Esnaf onayı olmadan ürün yayınlanmayacak.
- Rastgele web/Google görseli ürün kartına kopyalanmayacak.

Repo denetiminde iki Vercel yapılandırmasında da genel dallar için deployment kapalıdır; yalnız `main` ve özel `verify-*` dalları deployment alır. CI da yalnız PR ve main push'ında otomatik çalışır. Bu nedenle bu çalışma dalındaki normal commitler deploy veya CI tetiklemez.

## 3. Mevcut durum — kullanılacak çalışan parçalar

### Flutter / OCR

Mevcut:
- `lib/services/ocr/ocr_text_parser.dart`: Android/iOS tarafında Google ML Kit ile gerçek metin okuma.
- `lib/services/ocr/ocr_service.dart`: OCR → fiyat → ürün eşleştirme koordinasyonu.
- `lib/services/ocr/ocr_invoice_parser.dart`: temel fatura satırı ayrıştırma.
- `lib/services/ocr/ocr_product_matcher.dart`: metin/fiyat yakınlığı ve fuzzy eşleştirme.
- `lib/controllers/ocr_controller.dart`: sonuç onayı ve ürüne kaydetme.
- `lib/screens/ocr_scanner_screen.dart`: kullanıcı OCR ekranı.
- `lib/services/ocr/ocr_feedback_service.dart`: düzeltme/öğrenme verisi.
- `public.product_database`: OCR ürün eşleştirme sözlüğü.
- `public.ocr_feedback_dataset`: doğrulama/düzeltme veri seti.

### Product CORE

Mevcut:
- `lib/models/store_product.dart`: marka, barkod, SKU, stok, görseller, varyantlar ve zengin metadata taşıyabiliyor.
- `lib/services/product_catalog_sync_service.dart`: Flutter ürünlerini ortak Product CORE'a eşliyor.
- `public_web/src/app/api/products/batch/route.ts`: toplu ürün oluşturma yolu.
- `lib/services/xml_product_upload_service.dart`: XML'den marka, SKU, görsel ve temel ürün verisi alabiliyor.
- `public_web`: ürün kartı ve ürün detay müşteri yüzeyi mevcut.

## 4. Doğrulanmış boşluklar

1. Flutter web OCR gerçek görüntüyü okumuyor; `ocr_text_parser.dart` web'de sentetik örnek üretiyor.
2. Next.js sahibi tarafında fatura fotoğrafından OCR akışı yok.
3. `DetectedProduct` modeli model/stok kodu, barkod, varyant, beden, satır toplamı ve alan bazlı güven bilgilerini taşımıyor.
4. `ocr_product_matcher.dart` barkod olabilecek uzun sayıları ürün adından temizliyor; barkod ayrı kimlik alanına dönüştürülmüyor.
5. `OcrController._convertToProduct()` OCR'dan gelen zengin bilgilerin çoğunu Product CORE'a aktarmıyor.
6. Fatura satır yapısı sütun bazlı güçlü şekilde çıkarılmıyor; mevcut ayrıştırıcı ağırlıklı olarak ad/miktar/fiyat/toplam seviyesinde.
7. `product_database` OCR sözlüğü ürün kimliği için barkod/GTIN, tedarikçi kodu, görsel kaynağı ve veri kaynağı izini yeterince taşımıyor.
8. OCR, XML, ürün hafızası ve dış zenginleştirme tek bir ürün hazırlama hattında birleşmiş değil.
9. Next.js'te prototipteki “fatura → hazırlanan kartlar → satış fiyatı → onay → yayın” ekranı gerçek veriye bağlı değil.
10. Ürün görselinin nereden geldiğini ve kullanım iznini kanıtlayan ortak kaynak modeli yok.

## 5. Hedef veri sözleşmesi

Faturadan çıkan her satır önce yayın ürünü değil, `InvoiceProductDraft` benzeri bir taslak olmalı.

Zorunlu çekirdek:
- source_line
- model_code
- barcode_gtin
- raw_name
- normalized_name
- brand
- variant
- size
- quantity
- purchase_unit_price
- purchase_line_total
- currency
- extraction_confidence
- validation_flags

Zenginleştirme sonrası:
- canonical_product_id
- display_name
- category
- description
- supplier_sku
- image_urls
- image_source
- image_usage_basis
- attributes
- variants
- enrichment_source
- enrichment_confidence

Esnafa özel ve ortak ürün bilgisinden ayrı:
- sale_price
- stock_quantity
- visibility
- approval_state

Alış fiyatı müşteri ürün kartının satış fiyatı alanına otomatik kopyalanmayacak.

## 6. Tamamlama fazları

### Faz 0 — Ölçüm motoru ve başlangıç çizgisi

Amaç: ürünü geliştirmeden önce her sonraki değişikliğin gerçekten daha iyi mi daha kötü mü olduğunu aynı cetvelle ölçebilmek.

Sıra:
1. Önce bağımsız ölçüm motoru kurulur.
2. Referans faturanın doğru cevabı motora verilir.
3. Motorun kendisi doğru ve bozuk örneklerle sınanır.
4. Sonra mevcut Vixrex çıktısı motora bağlanır.
5. Faz 1'e geçmeden mevcut Vixrex'in başlangıç raporu üretilir.

Ölçüm motoru şunları ayrı ayrı gösterecek:
- kaç ürün satırı eşleşti,
- kaç ürün eksik/fazla,
- model doğruluğu,
- barkod doğruluğu,
- ürün adı doğruluğu,
- renk/varyant doğruluğu,
- beden doğruluğu,
- adet doğruluğu,
- birim alış fiyatı doğruluğu,
- satır toplamı doğruluğu,
- toplam adet farkı,
- toplam tutar farkı,
- genel alan doğruluğu.

Referans fatura:
- 13 ürün satırı,
- 75 toplam adet,
- 6.034,00 TL toplam,
- her satırın model/barkod/ad/renk/beden/adet/fiyat/toplam değeri sabit gerçek kabul edilir.

Kabul:
- kusursuz örnek motorda %100 üretmeli,
- eksik barkod, yanlış adet, eksik ürün ve fazla ürün birbirinden ayrı görünmeli,
- mevcut Vixrex aynı motordan geçirilip başlangıç raporu çıkarılmalı,
- production OCR, UI, DB ve Product CORE davranışı bu fazda değiştirilmemeli.

### Faz 1 — Fatura satırı veri modeli

Amaç: OCR metnini ürün kartı olmadan önce kayıpsız taşımak.

Yapılacak:
- yeni fatura satırı/taslak modeli,
- model kodu, barkod, varyant, beden, miktar, fiyat, toplam alanları,
- ham metin ve kaynak satır ilişkisi,
- alan bazlı confidence ve doğrulama hataları.

Kabul:
- örnek faturanın 13 satırı barkodları silinmeden bellekte temsil edilebilecek.

### Faz 2 — Gerçek fatura ayrıştırıcı

Amaç: tablo görünümündeki teklif/fatura belgelerini sütun ilişkisiyle çözmek.

Yapılacak:
- başlık satırlarını tespit,
- sütun konumlarını belirleme,
- çok satırlı ürün adını birleştirme,
- model/barkod/varyant/beden/miktar/birim fiyat/toplam ayrımı,
- Türkçe sayı biçimi doğrulama,
- satır toplamı = miktar × birim fiyat kontrolü,
- belge toplamı ve toplam adet çapraz kontrolü.

Kabul:
- referans faturada 13 ürün, 75 adet ve 6.034,00 TL toplamı testte doğrulanacak.
- yanlış okunan tek satır tüm belgeyi geçerli saydırmayacak.

### Faz 3 — Ürün kimliği ve Vixrex ürün hafızası

Amaç: aynı ürünü her faturada yeniden keşfetmemek.

Öncelik:
1. barkod/GTIN tam eşleşme,
2. tedarikçi + model/SKU tam eşleşme,
3. Vixrex `product_database`,
4. kontrollü fuzzy eşleşme,
5. belirsiz kayıt.

Yapılacak:
- ürün hafızasında barkod/GTIN ve tedarikçi kimliği,
- canonical ürün kaydı ile mağazaya özel ürün kaydını ayırma,
- aynı barkod tekrar geldiğinde mevcut doğrulanmış ürünü kullanma,
- yanlış eşleşmeyi önleyen confidence eşiği.

Kabul:
- daha önce doğrulanmış ürün ikinci faturada dış API çağrısı olmadan bulunacak.

### Faz 4 — Zenginleştirme zinciri ve maliyet kapısı

Amaç: en ucuz kaynaktan başlayarak ürün adı/açıklama/kategori/görsel elde etmek.

Sıra:
1. Vixrex ürün hafızası,
2. esnafın/tedarikçinin bağlı XML/API verisi,
3. doğrulanmış barkod/ürün veri sağlayıcısı,
4. yalnız eksik/belirsiz alanlar için yapay zekâ,
5. esnaftan eksik bilgi/fotoğraf isteme.

Kurallar:
- her satır için yapay zekâ çağrısı yapılmaz,
- aynı ürün için tekrar tekrar dış sorgu yapılmaz,
- harici sonuç cache'lenir,
- AI serbest metin değil şemalı çıktı üretir,
- AI barkod/fiyat gibi kaynakta olmayan gerçeği uyduramaz,
- düşük güvenli alan esnafa açıkça işaretlenir.

Kabul:
- bilinen ürün AI kullanmadan hazırlanır.
- AI kapalıyken sistem çalışmaya devam eder.

### Faz 5 — Görsel kaynağı

Amaç: esnafa tek tek ürün fotoğrafı yükletmeyi son seçenek yapmak.

Kaynak sırası:
1. esnafın bağlı tedarikçi/üretici feed'i,
2. Vixrex'te daha önce izinli ve doğrulanmış aynı ürün görseli,
3. resmi veri sağlayıcısının kullanım şartlarına uygun görseli,
4. esnafın yüklediği fotoğraf.

Her görselde:
- kaynak,
- ürün kimliği,
- kullanım dayanağı,
- alındığı tarih
izlenebilir olmalı.

Rastgele web görseli toplama bu planın parçası değildir.

### Faz 6 — Ortak fatura hazırlama servisi

Amaç: Flutter, Next.js ve ileride OpenAI/ChatGPT gibi dış kapıların aynı motoru kullanması.

Tek giriş sözleşmesi:
- image/document
- store context
- optional supplier context

Tek çıkış:
- invoice summary
- product drafts
- confidence/errors
- enrichment status

Flutter ve Next.js kendi ayrı OCR iş kuralını üretmeyecek. Platforma özgü görüntü okuma adapter olabilir; fatura ürün mantığı ortak kontrata bağlı kalacak.

### Faz 7 — Ön yüzü prototip hedefe bağlama

#### Flutter

Mevcut OCR ekranı prototipteki dört aşamalı deneyime yaklaştırılır:
- fatura seç/çek,
- işleniyor,
- ürün taslaklarını kontrol et,
- satış fiyatlarını belirle/onayla,
- Product CORE'a yaz.

#### Next.js

Web sahibine eksik olan eşdeğer yol eklenir:
- `/app/urunler` içinden “Faturadan ürün ekle”,
- fotoğraf/dosya seçimi,
- işleme durumu,
- hazırlanan kartlar,
- toplu satış fiyatı,
- onay,
- mevcut batch API ile kayıt.

Kabul:
- aynı fatura Flutter ve Next.js'te aynı ürün taslaklarını üretir.
- müşteri vitrin kartı yine mevcut Next.js Product CORE render yolundan gelir; yeni ikinci vitrin sistemi yapılmaz.

### Faz 8 — Yayın/kayıt köprüsü

Amaç: prototipin son butonunu gerçek yapmak.

Yapılacak:
- ürünler önce mağaza ürün taslağı olarak kaydedilir,
- onaysız ürün public olmaz,
- batch yazma barkod/SKU/varyant/zengin alanları taşıyacak hale gelir,
- kısmi hata durumunda başarılı ve hatalı satırlar ayrı döner,
- idempotency ile aynı fatura çift dokunmada kopya ürün üretmez.

Kabul:
- 13 üründen bir satır sorunluysa diğer 12 ürün kaybolmaz.
- tekrar gönderimde çift ürün oluşmaz.

### Faz 9 — Veri güvenliği ve saklama

Kurallar:
- orijinal fatura varsayılan olarak kalıcı ürün verisi değildir,
- mümkünse işleme sonrası ham görüntü silinir,
- gerekli olduğunda yalnız sınırlı hata/feedback verisi tutulur,
- kişisel/firma üst bilgileri ürün zenginleştirme için gerekmiyorsa dış AI'a gönderilmez,
- dış API sağlayıcısı ve gönderilen alanlar kayıt altına alınır,
- secret yalnız server-side ortam değişkeninde tutulur.

### Faz 10 — Maliyet ölçümü

Her fatura için ölçülecek:
- yerel OCR süresi,
- dış ürün sorgusu sayısı,
- AI çağrısı sayısı,
- AI giriş/çıkış boyutu,
- görsel sorgu sayısı,
- cache hit oranı,
- ürün başına ortalama dış maliyet.

Başarı ilkesi:
- “her şeyi AI'a gönder” değil,
- “yalnız sistemin çözemediği kısmı AI'a gönder”.

### Faz 11 — Kabul kapıları

Kod tamam sayılmadan:
- referans fatura fixture testi,
- parser testleri,
- barkodun korunması testi,
- toplam/adet doğrulama testi,
- aynı ürün cache testi,
- AI kapalı fallback testi,
- batch kısmi başarı testi,
- idempotency testi,
- Flutter analyze/test,
- Next lint/typecheck/test/build,
- veri güvenliği/RLS kontrolü,
- ayrı görsel doğrulama.

Canlı doğrulama ayrı bir son adımdır; kullanıcı açık onayı olmadan yapılmaz.

## 7. Beklenen ana dosya yüzeyleri

Mevcut dosyaların hepsi değişecek anlamına gelmez. Faz sırasında yalnız gerekli olanlara dokunulur.

Flutter:
- `lib/models/detected_product.dart`
- `lib/models/ocr_*.dart`
- `lib/services/ocr/*`
- `lib/controllers/ocr_controller.dart`
- `lib/screens/ocr_scanner_screen.dart`
- `lib/widgets/ocr/*`
- `lib/models/store_product.dart`
- `lib/services/product_catalog_sync_service.dart`
- `lib/services/xml_product_upload_service.dart`

Next.js:
- `public_web/src/app/app/urunler/*`
- `public_web/src/components/owner/*`
- `public_web/src/app/api/products/batch/route.ts`
- yeni server-side invoice analyze endpoint/adapters
- Product CORE sözleşmesini kullanan ortak TS modelleri

Shared:
- yalnız iki istemcinin gerçekten ortak okuyacağı kontratlar.

Supabase:
- `product_database` kimlik/zenginleştirme alanları için migration,
- gerekirse fatura işleme taslak/iş kayıtları,
- mevcut `ocr_feedback_dataset` ile uyum.

## 8. Yapılmayacaklar

Bu çalışma:
- ödeme sistemini değiştirmez,
- Vixrex 46 vitrin alanını değiştirmez,
- asistan NLU motorunu yeniden yazmaz,
- public vitrin tasarımını yeniden tasarlamaz,
- yeni e-ticaret/ödeme motoru kurmaz,
- üretici görseli için izinsiz scraping sistemi kurmaz,
- mevcut ürünleri topluca dönüştürmez,
- canlı DB'yi doğrudan değiştirmez.

## 9. Çalışma düzeni

Her fazdan önce:
1. ilgili mevcut dosyalar salt-okuma denetlenir,
2. aynı dosyalardaki son commitler kontrol edilir,
3. etki alanı sabitlenir,
4. yalnız o faz uygulanır,
5. ilgili hafif testler çalıştırılır.

Ağır tam kapılar yalnız kilometre taşlarında çalıştırılır.

PR/merge/deploy ayrı işlemlerdir. Bu dalın geliştirilmesi bunlardan hiçbirini otomatik olarak yapmaz.

## 10. Sapma kilidi ve görünür ilerleme

Bu bölüm planın çalışma sözleşmesidir.

- Faz sırası kullanıcı onayı olmadan değiştirilmez.
- Bir faz sırasında sonraki fazın işi uygulanmaz.
- Yeni fikir veya ihtiyaç çıkarsa doğrudan kodlanmaz; `DURUM.md` içindeki “Park alanı”na yazılır.
- Kilitli hedefi, veri sözleşmesini veya “Yapılmayacaklar” bölümünü değiştiren iş kapsam değişikliğidir ve kullanıcı onayı gerektirir.
- Her geliştirme adımı tek bir ölçülebilir hedef taşır. Aynı adımda ilgisiz refactor, tasarım yenileme veya başka ürün borcu kapatma yapılmaz.
- Her adım başlamadan önce “önce” durumu ölçülür; bittikten sonra aynı ölçüm tekrar yapılır.
- Her tamamlanan adımda aynı commit içinde `DURUM.md` güncellenir. Kod değişip durum defteri güncellenmeden adım tamam sayılmaz.
- Deneme commitleri biriktirilmez. Bir adım için doğrulanmış tek teslim commit'i hedeflenir.
- Bir test yeşil diye faz tamam sayılmaz. Fazın kendi kabul maddesi ayrıca kanıtlanır.
- PR, merge, preview/deploy ve canlı migration bu planın geliştirme adımlarından ayrı kapılardır.

Her adım sonunda kullanıcıya aynı beş başlıkla rapor verilir:

1. **Neyi geliştirdik**
2. **Neyi değiştirdik**
3. **Ne elde ettik**
4. **Neye dokunmadık**
5. **Kanıt / test durumu**

Bu beş başlığın karşılığı `docs/fatura-katalog/DURUM.md` içinde kalıcı olarak tutulur.

# Ürün kartı çalışması — devir belgesi

> 2026-09-15. İşi devralan ajan buradan devam eder.
> Kaynak dal: `work/product-live-ready-20260914` (PR #489) — **merge edilmedi,
> kanonik geliştirme dalı olarak duruyor, silinmeyecek.**

## GÜNCEL DURUM (2026-09-15, son güncelleme)

**#489 tamamlanmadı. Main'e merge edilmedi. Canlıya alınmadı.**

Main'de daha önce birleşen ürün kartı fazları yerel olarak doğrulanmıştı:

| Kapı | Son bilinen sonuç |
|---|---|
| `flutter analyze` | temiz |
| `flutter test` | 737 test geçti |
| `tsc --noEmit` | temiz |
| `vitest run` | 1513 test geçti |
| `eslint` | 0 hata (3 uyarı, önceden vardı) |
| `next build` | başarılı |

Bu sonuçlar #489'un bugünkü yeni batch/upsert değişikliklerini **kanıtlamaz**.
Yeni delta için kapılar yeniden koşmadan "tamamlandı" denmez.

## Kanonik gerçeklik

- `main`: çalışan ürün sistemi ve daha önce birleşen #491–#495 fazları.
- `work/product-live-ready-20260914` / PR #489: yalnız devam eden ürün geliştirmesi.
- #497/#499/#500/#501/#502/#503 kapalıdır; bağımsız merge edilmeyecek.
- Bu daldan main'e tek parça merge yapılmayacak; doğrulanan fazlar küçük PR'lar
  halinde alınacak.

## Şu an #489'da kodlanan delta

1. `StorePublishValidator` eski 4 görsel sınırından ortak 11 görsel politikasına
   bağlandı; 11 kabul / 12 red / geçersiz URL testleri eklendi.
2. Toplu içe aktarma için yayın kapısından ayrı görsel doğrulaması eklendi:
   0–2 görselli taslak içe aktarılabilir, 11 üst sınırı korunur.
3. Next.js batch API tek kötü satır yüzünden bütün partiyi düşürmeyecek şekilde
   satır bazlı hataya ayrıldı.
4. Batch API `external_product_id`, barkod ve SKU kimlik verisini Product CORE
   yoluna taşıyacak şekilde genişletildi.
5. Batch sonucunda `eklenen / güncellenen / değişmeyen / hatalı` sayaçları
   ayrıldı.
6. Canlıdaki mevcut `batch_create_products(uuid,text,jsonb)` fonksiyonunun birebir
   geri dönüş kaynağı repo içine
   `20260915109000_snapshot_live_batch_create_products.sql` olarak kaydedildi.
7. Hedef batch migration'ı kimlik önceliği
   `external_product_id -> barkod/GTIN -> SKU` olacak şekilde upsert davranışına
   çevrildi. Mevcut üründe yalnız dolu/gelen alanlar güncelleniyor; boş alanlar
   mevcut veriyi silmiyor; otomatik ürün silme yok.

## Canlı `batch_create_products` için geri dönüş kaynağı

15 Eylül kontrolünde production Supabase'teki `batch_create_products` sürümünün
repodaki migration geçmişinde birebir kaydı olmadığı doğrulandı. Bu nedenle
hedef migration uygulanmadan önce canlı fonksiyon gövdesi ve mevcut EXECUTE
izinleri snapshot migration olarak repoya alındı.

Snapshot hedef davranış değildir; rollback kaynağıdır. Hedef migration daha
sonra aynı imzayı `create or replace` eder.

## Upsert kararı

Yeniden XML/Excel yükleme **atlama değil upsert** davranışıdır:

1. Kimlik sırası: `external_product_id` → yoksa barkod/GTIN → yoksa SKU.
2. Ürün adı/slug kimlik değildir.
3. Eşleşen üründe yalnız dolu/gelen alan güncellenir; boş veya gelmeyen alan
   mevcut esnaf verisini silmez.
4. Sonuç dört ayrı sayaç verir: eklendi / güncellendi / değişmedi / hatalı.
5. Feed'den düşen ürün otomatik silinmez.

Kimlik birden fazla mevcut ürüne eşleşirse yanlış ürünü rastgele güncellemek
yerine satır hata verir (`PRODUCT_IDENTITY_AMBIGUOUS_*`).

## vixrex-dev ürün-alt-sistemi provası — KANITLANDI

Production'a DDL uygulanmadı. Ayrı `vixrex-dev` projesinde mevcut test verileri
silinmeden, yalnız ürün alt sistemi için additive prova iskeleti kuruldu ve
Product CORE + hedef batch RPC orada çalıştırıldı.

Bu prova **112 migration'ın tamamının sıfırdan kurulumu değildir**. Tam migration
zinciri provası CI/local Supabase kapısında ayrıca geçmek zorundadır.

DB üzerinde alınan gerçek sonuçlar:

| Senaryo | Sonuç |
|---|---|
| İlk yükleme: external id + fiyat + stok + marka + barkod + SKU + 2 görsel | `inserted=1, updated=0, unchanged=0, errors=0` |
| Aynı external id, yalnız fiyat 100→125.50 ve stok 5→9 | `updated=1, inserted=0, unchanged=0, errors=0` |
| Aynı veri üçüncü kez | `unchanged=1, updated=0, inserted=0, errors=0` |
| Barkod kimlikli + yalnız SKU kimlikli iki yeni ürün | `inserted=2, errors=0` |
| Aynı barkod/SKU ile fiyat-stok değişikliği | `updated=2, errors=0` |
| İlk satır hatalı ad, ikinci satır geçerli | hatalı satır `PRODUCT_NAME_REQUIRED`, geçerli satır `inserted=1` |
| 12 görsel + 11 görsel iki satır | 12 görsel satırı `PRODUCT_IMAGES_MAX_11`, 11 görsel satırı `inserted=1` |
| metadata + varyant güncellemesi | metadata içindeki mevcut SKU korundu, yeni attribute ve varyant DB'de okundu |
| sonraki import metadata/varyant göndermedi | `unchanged=1`; mevcut metadata/varyant silinmedi |

Ayrıca fiyat/stok-only ikinci yükleme sonrasında DB'den yeniden okundu:
- esnaf açıklaması korundu,
- 2 mevcut görsel korundu,
- marka/barkod korundu,
- `metadata.identifiers.sku` korundu,
- fiyat ve stok gerçekten değişti,
- ürün slug'ı değişmedi.

### Prova sırasında bulunan gerçek hata

İlk update denemesi şu DB hatasını verdi:

`function pg_catalog.jsonb_object_length(jsonb) does not exist`

Bu hata canlıya gitmeden `vixrex-dev` provasının içinde yakalandı. Henüz production'a
uygulanmamış hedef migration içinde düzeltildi; yeni bir "yama migration" eklenmedi.
Boş metadata kontrolü artık doğrudan `jsonb <> '{}'::jsonb` ile yapılıyor.
Düzeltme commit'i: `c16c629`.

## GRANT/RLS prova durumu

CI'daki mevcut `GRANT güvenlik bekçisi`, fonksiyonların `EXECUTE` yetkisini değil,
`anon/authenticated` rollerinin public tablolarda tehlikeli
`TRUNCATE / MAINTAIN / REFERENCES / TRIGGER` yetkilerini denetler.

`vixrex-dev` ürün prova tabloları ilk oluşturulduğunda Supabase varsayılan
ayrıcalıkları nedeniyle bu dört yetki görüldü. Production'daki mevcut products ve
product_categories ACL'leri referans alınarak dev prova tablolarında bu tehlikeli
yetkiler geri çekildi ve aynı sorgu tekrar çalıştırıldı:

`dangerous_count = 0`

Bu, **dev ürün-alt-sistemi için manuel GRANT kanıtıdır**; CI'daki tam sıfırdan
migration zinciri koşusunun yerine geçmez.

`batch_create_products`, `create_store_product_v3` ve `update_store_product_v2`
fonksiyonlarının `anon/authenticated` EXECUTE yetkisi vardır; her fonksiyon kendi
`SECURITY DEFINER` gövdesinde edit-token/owner yetkilendirmesi yapar. Bu fonksiyon
ACL sözleşmesi ayrıca regression testi/incelemesi gerektirir; mevcut GRANT bekçisi
bunu otomatik kontrol etmiyor.

## CI kapıları — hâlâ tamamlanmadı

Aşağıdaki kapılar gerçekten koşup yeşil olmadan #489 main'e giremez:

- Flutter analiz/test,
- şema sapma kontrolü,
- GRANT güvenlik bekçisi,
- Next typecheck/lint/test/build,
- tam migration zinciri provası,
- ürün regresyonları.

Son kontrol anında #489'un son commit CI koşusu **queued** durumundaydı; yeşil
kabul edilmedi.

## Daha önce main'e alınan ürün fazları

| PR | Ne |
|---|---|
| #491 | Erişilemez sahip paneli dalı + kullanılmayan katalog prop'u temizliği |
| #492 | Zengin ürün kartı + hızlı bakış + zengin ürün detay sayfası (okuma yolu) |
| #493 | Esnaf zengin alan girişi + asgari çekirdek migration |
| #494 | Kategori şablonları esnaf yönetiminde |
| #495 | Flutter tarafı zengin ürün modeline eşitlendi |

Canlıya uygulanan temel zengin ürün migration'ı:
`20260915010000_product_rich_core_minimal`.

## Bilerek geri getirilmemesi gereken davranışlar

1. Kategori `service` olunca marka/barkod/stok/özellik silinmesi.
2. Şablon dışı kalan ürün özelliklerinin düzenlemede silinmesi.
3. Eski `metadata.templateKey` yüzünden ürünün kalıcı 422 ile kilitlenmesi.
4. En az 3 görsel kuralının DB trigger olarak uygulanması.

Minimum 3 görsel yalnız uygun yayın kalite kapısında uygulanacak. Canlı eski
ürünler 0–2 görsel nedeniyle düzenlenemez hâle getirilmeyecek.

## Kalan fazlar

### A — Toplu yükleme / Product CORE

DB batch upsert davranışı `vixrex-dev` üzerinde kanıtlandı. A fazının tamamlanması
için hâlâ gerekenler:

- Flutter Excel/CSV payload'larını aynı batch kimlik/upsert sözleşmesine bağla,
- XML parser/payload'ında `external_product_id`/barkod/SKU alanlarını ayrı taşı,
- Flutter/XML UI'nın yeni dört sayaç sonucunu doğru göstermesini sağla,
- false-success regresyon testlerini ekle,
- Next typecheck/lint/test/build ve Flutter analyze/test çalıştır,
- tam migration zincirini sıfırdan çalıştıran CI kapılarını gerçekten geçir.

### B — Görsel kalite + yayın kapısı

A fazı doğrulanmadan tamamlanmış sayılmaz. Kurallar:

- min-3 yalnız yayın kapısında, DB trigger değil,
- maksimum 11 ortak politika,
- yalnız Vixrex'e ait ve başka üründe kullanılmayan ürün dosyası silinebilir,
- dış CDN / başka vitrin görselleri asla silinmez,
- kabul testi özellikle "silinmedi" durumlarını kanıtlar.

## Tek veri kaynağı — açık borç

`shared/product_attribute_schema.json` Flutter ve Next.js tarafından ortak
okunuyor; ancak sayısal sınırlar ve enum etiketleri hâlâ elle kopyalanmış.
Ürün şeması için JSON'dan üretim + drift CI kapısı henüz kurulmadı.

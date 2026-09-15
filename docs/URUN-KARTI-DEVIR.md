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

## Şu an #489'da kodlanan ama henüz tamamlanmış sayılmayan delta

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

**Önemli:** Yukarıdaki maddeler şu anda yalnız kodlanmış durumdadır. Dev DB
provası, CI, migration/RLS/GRANT güvenliği ve uçtan uca kanıt tamamlanmadan
"doğrulandı" veya "tamamlandı" sayılmaz.

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

## Dev prova durumu

Ayrı Supabase projesi mevcut: `vixrex-dev`.

Kontrol sonucu dev proje şu anda güncel Product CORE migration zincirine sahip
**değil**: `create_store_product_v3`, `update_store_product_v2` ve
`batch_create_products` yok. Bu nedenle yalnız yeni batch migration'ı dev'e
uygulamak doğru prova olmaz.

Sıradaki DB işi:

1. vixrex-dev üzerinde güncel migration zincirini güvenli biçimde sıfırdan kur,
2. snapshot → Product CORE → batch upsert sırasını doğrula,
3. aynı ürünü iki kez yükleyerek ilk sefer `inserted`, ikinci sefer fiyat/stok
   değişmişse `updated`, değişmemişse `unchanged` kanıtı al,
4. hatalı tek satırın diğer geçerli satırları durdurmadığını doğrula,
5. production'a DDL uygulama.

## CI kapıları — hâlâ tamamlanmadı

Aşağıdaki kapılar gerçekten koşup yeşil olmadan #489 main'e giremez:

- Flutter analiz/test,
- şema sapma kontrolü,
- GRANT güvenlik bekçisi,
- Next typecheck/lint/test/build,
- migration provası,
- ürün regresyonları.

Özellikle batch RPC `SECURITY DEFINER` ve istemci rolleriyle çalıştığı için
EXECUTE izinları GRANT bekçisiyle doğrulanmadan güvenli kabul edilmez.

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

Henüz tamamlanmadı. Kalanlar:

- Flutter Excel/CSV payload'larını aynı kimlik/upsert sözleşmesine bağla,
- XML payload'ında `external_product_id`/barkod/SKU zincirini doğrula,
- metadata/varyant/fiyat alanlarının gerçek DB write-read paritesini kanıtla,
- UI'nın yeni dört sayaç sonucunu doğru göstermesini sağla,
- false-success regresyon testlerini ekle,
- vixrex-dev uçtan uca prova.

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

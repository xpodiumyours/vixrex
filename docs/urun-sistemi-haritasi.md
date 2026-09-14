# Vixrex Ürün Sistemi Haritası (main gerçekliği)

> Tarih: 2026-09-15 · Kaynak: `main` dalı (yalnız okuma ile çıkarıldı, main'e dokunulmadı).
> Amaç: Büyük çalışma dalından (`work/product-live-ready-20260914`, 245+ commit, 109 dosya)
> canlıya taşınacak her değişikliğin yerine "bugün çalışan sistem" üzerinden karar vermek.

---

## 1. Ürün Vixrex'e nasıl giriyor? (4 yol)

| Yol | Flutter | Next.js (web panel) | Not |
|---|---|---|---|
| Manuel ürün | `product_editor_sheet.dart` | `OwnerProductManager.tsx` → `/api/products` | İkisi de aynı Supabase tablosuna yazar |
| Excel / CSV toplu | `bulk_product_upload_service.dart` (5 MB limit, sütun eşleme: "Ürün Adı"/"Name") | `BulkProductUpload.tsx` | İşlev matrisinde eşit kabul edilmiş |
| XML feed | `xml_product_upload_service.dart` (URL indir → parse → kaydet) | — | Yalnız Flutter |
| OCR (fiş/katalog foto) | `ocr_controller.dart` + `lib/services/ocr/*` | — | Yalnız Flutter; kaynak ürünler `source: 'ocr*'` ile işaretlenir |

Her yol `sourceType`/`source` alanıyla işaretlenir (`manual`, `ocr*`, xml vb.).
Bu işaretleme müşteri tarafında görsel kalite filtresinde kullanılıyor (bkz. §4).

## 2. Tek gerçek ürün verisi nerede?

Zincir:

```
Flutter:  ProductController → ProductService → ProductRepository (arayüz)
          → SupabaseProductRepository → Supabase `products` tablosu
Web:      OwnerProductManager → /api/products (sahip çerezi) → productCoreServer.ts
          → RPC create_store_product_v2 / update → aynı `products` tablosu
Veritabanı: slug'ı SAHİBİ olan trigger (`set_product_canonical_slug`,
          20260811053804_product_core_slug_authority.sql) — slug'ı istemci değil
          DB üretir/dondurur. Eski istemciler create_store_product kullanır.
```

`products` tablosunda canlıda saklanan alanlar (main `Product` modeli):
id, name, price (metin), priceAmount, description, imagePath + imageUrls,
categoryId (+ kategori adı ayrı tablodan maplenir), stockStatus (Mevcut / Tükendi /
Son birkaç adet), isVisible + is_active, sortOrder, slug, source, sourceMediaId,
sourcePermalink, importedAt, brand, sku, oldPriceAmount, badgeTag, fulfillmentLocation.

**main'de OLMAYAN şeyler:** zengin öznitelikler (renk/beden/KDV/materyal…),
varyantlar, barkod, stok adedi, kategori şablon anahtarı, 11 görsel limiti
(main 4 ile sınırlıyor).

## 3. Flutter ne yapıyor, Next.js ne yapıyor?

| Konu | Flutter (esnaf uygulaması) | Next.js (web) |
|---|---|---|
| Ürün oluştur/düzenle/sil | Editor sheet → ProductService | OwnerProductManager → /api/products |
| Kategori | `product_category_management_screen.dart` | `OwnerCategoryManager.tsx` + `/api/product-categories` |
| Görsel | galeri seçici + sıkıştırma (jpg/png yeniden kodlama) | `/api/product-image-upload` + `gorselSikistir.ts` |
| Fiyat | metin fiyat + priceAmount | `productCoreServer.ts` ayrıştırma |
| Stok | yalnız durum (3 seçenek) | aynı alan |
| Varyant | YOK | YOK |
| Yayınlama | StorePublishValidator → publish RPC | PublishBar → publish |


## 4. Müşteri ne görüyor? (public katman, main)

- `ProductCatalog.tsx` (v/[slug]): sayfalama 24'lük, kategori filtreleri.
- `products.ts` tek kural kaynağı:
  - `isPublicCatalogProduct`: adı boş olmayan + görünür + çöp adı olmayan (test/deneme/xxx regex).
  - `getProductImages`: tekrarsız, **en fazla 4** görsel.
  - `resolveCatalogImage`: OCR/fiş kaynaklı üründe ürün fotoğrafına güvenmez,
    vitrin kapağına düşer; şüpheli ekran görüntüsü URL'lerini atar; yoksa maskot.
- Detay sayfası: `v/[slug]/urun/[productSlug]/page.tsx` (main'de mevcut, sade).
- İletişim: WhatsApp / iletişim bağlantıları (TrackedWhatsAppLink, TrackedContactLink).

## 5. Yayınlama kuralları (bugün çalışan davranış)

`store_publish_validator.dart`:
- Vitrin (hizmet) ise ürün kontrolü **yapılmaz**; mağaza ise yapılır.
- Ürün kuralları: adı boş olamaz, kategorisi boş olamaz, **en fazla 4 görsel**.
- Ortak hazırlık: zorunlu vitrin alanları + geçerli Türkiye WhatsApp numarası
  + bağlantı/teklif kontrolleri + hukuki onay damgası.

## 6. Görsel sistemi

- Yükleme: Flutter galeri → `image_optimization_service.dart` (uzun kenar hedefi,
  jpg/png yeniden kodlama, kalite 82→65 ikinci deneme) → Supabase Storage → URL listesi.
- Web: `/api/product-image-upload` + tarayıcıda sıkıştırma (`gorselSikistir.ts`).
- Limit: model `take(4)` + validator 4 kuralı. Ürün silinince Storage dosyası
  temizliği main'de özel servis olarak **yok** (dalda `product_image_cleanup` ekleniyor).

## 7. SEO ve public veri

- Ürün slug'ı: DB trigger sahipliğinde (Türkçe karakter dönüşümü + çakışma soneki,
  güncellemede slug dondurulur). İstemciler sadece "tohum" verebilir.
- Sitemap: `app/sitemap.xml/route.ts`.
- Structured data (JSON-LD) main'de ürün için **yok** (dalda `productStructuredData.ts` ekleniyor).
- Ürün görüntüleme sayacı: `ProductViewTracker.tsx`.

## 8. Davranışı koruyan testler (emniyet kemeri)

- Model/çekirdek: `product_test.dart`, `product_core_creation_test.dart`,
  `product_table_lock_contract_test.dart`
- Widget: `product_widgets_test.dart`
- Toplu: `bulk_product_field_update_service_test.dart`, `xml_product_upload_service_test.dart`
- Yayınlama: `store_publish_validator_test.dart`, `store_publish_payload_builder_test.dart`,
  `store_publish_service_test.dart`, `publish_legal_stamp_fix_test.dart`
- Görsel: `image_optimization_service_test.dart`, `gallery_image_file_validator_test.dart`
- OCR: `test/ocr/*` (servis, fiyat ayrıştırma, ürün eşleme, eğitim)

Her küçük PR bu testler + dala eklenen yeni testlerle açılır; yeşil olmadan merge yok.


## 9. Daldaki değişikliklerin haritadaki yeri

| # | Daldaki geliştirme | Mevcut davranış | Neden gerekli | Bağımlılık | Risk |
|---|---|---|---|---|---|
| 1 | Ürün görsel limiti 4 → 11 (`product_image_policy`, model, validator, editor, web `products.ts`/OwnerProductManager) + **DB trigger migrasyonu** (`20260914175500_product_image_limit_11.sql`: 3–11 aralığı, additive) | 4 görsel sabit (model `take(4)`, validator, XML, editor, web panel) | Rakip platformlarda 8-10 görsel standart; kart kalitesinin ilk adımı | **DB migrasyonu VAR** (trigger replace, additive; yeni kolon yok) | Düşük-orta — sıralama kuralı: migrasyon önce, kod sonra (bkz. §12) |
| 2 | `productCardPresentation.ts` (fiyat/etiket/stok sunumu) | Catalog düz metin | Kartların rakip kalitesinde görünümü | 1 gerekmez; bağımsız | Düşük — salt sunum |
| 3 | Hızlı bakış (ProductQuickView) + zengin detay sayfası | Sade detay sayfası | Müşteri satın alma kararı için detay | 2 ile birlikte iyi çalışır | Orta — yeni bileşen, eski sayfa kalır |
| 4 | Zengin öznitelikler (shared şema v2: Marka, KDV, Renk, Beden, Materyal, Model…) + `ProductRichMetadata` | Yalnız ad/fiyat/açıklama | Ürün kartı kalitesinin çekirdeği (rakip "özellikler" bloğu) | DB kolonu (metadata) migrasyonu | Orta — yeni kolon, eski veri null kalır |
| 5 | Kategori şablon anahtarı (`productTemplateKey` + metadata servisi) | Kategori = ad + sıra | Hangi kategoride hangi alanların sorulacağı | 4 (şema şablonları) | Orta |
| 6 | Varyant editörü (beden/renk varyantı, 11 görsel) | Varyant yok | Giyim/ayakkabı gibi kategoriler için zorunlu | 4 + 1 | Yüksek — en büyük yeni kavram; en son alınmalı |
| 7 | Structured data (JSON-LD Product) | Yok | SEO: Google ürün bilgisi | 4 (alan doluysa anlamlı) | Düşük — ek katman |
| 8 | Görsel temizlik servisi (ürün silinince storage temizliği) | Silince URL gider, dosya kalır | Maliyet + hijyen | Bağımsız | Düşük |
| 9 | Kategori senkron motoru (`product_category_sync_service`) | Elle kategori yönetimi | Şablonlu kategorilerin dağıtımı | 5 | Orta-sonra — PR için zorunlu DEĞİL, ertelenebilir |
| 10 | OCR tarafı iyileştirmeleri | OCR yalnız Flutter | Matris zaten "eşit değil" kabul ediyor | Bağımsız | Ayrı iz |

## 10. Önerilen küçük PR sırası (her biri: dal → test → preview → main)

1. **PR-1 Görsel limiti 11** (madde 1) — en küçük, en görünür kazanç.
2. **PR-2 Ürün kartı sunumu + hızlı bakış** (madde 2+3) — salt görüntüleme.
3. **PR-3 Zengin öznitelik çekirdeği** (madde 4) — DB migrasyonu + editör alanları + web görüntüleme; kategori şablonu önce "generic".
4. **PR-4 Kategori şablonları** (madde 5) — giyim/elektronik/kozmetik/gıda/ev/otomotiv alan açılımları.
5. **PR-5 JSON-LD + görsel temizlik** (madde 7+8) — bağımsız iyileştirmeler.
6. **PR-6 Varyantlar** (madde 6) — en son; 1-5 sağlam olduktan sonra.
7. **Ertelenen:** kategori senkron motoru (madde 9), OCR parite (madde 10).

**Kural:** Büyük dal referans, `main` gerçeklik. Her PR'da yukarıdaki tablodaki
"mevcut davranış" satırı bozulmadan taşınır; testler yeşil; preview gözle denetlenir.

## 11. Geçmiş oturumda dalda yapılmış emniyet düzeltmeleri

- Dal testleri tamamen yeşile çekildi (758/758), analiz 0 hata.
- WebP dosyaları yeniden kodlanmadan korunuyor (görsel kalite kaybı önlenir).
- Şema servisine yalnız-test geçersiz kılma kancası (`debugSchemaOverride`) eklendi.

## 12. Parçalı canlıya geçiş: sıralama yöntemi (koddan doğrulama)

> Kural: Vixrex'i yalnızca koddan tanırız. Doküman, işlev matrisi, hatırlatma
> veya sözlü bilgi kodla çelişirse **kod kazanır**. Her adımın sırası, aşağıdaki
> kod kanıtlarıyla belirlenir; sezgiyle değil.

### 12.1 Her adım için çıkarılan 5 kod kanıtı

1. **Dokunma listesi:** `git diff main...dal -- <konu dosyaları>` → hangi dosyalar
   değişiyor? Değişen dosya sayısı = dokunma alanı (blast radius).
2. **DB bağımlılığı:** konuyla ilgili migrasyon var mı?
   `supabase/migrations` içinde konu başlığına uyan dosya + içerik okunur
   (yeni kolon mu, trigger replace mi, additive mi, geri alınabilir mi).
3. **İstemci-DB sözleşme yönü:** DB sınırı ile istemci sınırı hangi yönde değişiyor?
   - DB'yi **gevşetme** (4→11): önce DB, sonra kod → eski kod + yeni DB sorunsuz.
   - DB'yi **kısma**: önce kod, sonra DB → tersi sırada veri kaybı/ reddi olur.
4. **Eski okuyucu güvenliği:** yeni alan nullable / eski kodun okumadığı alansa,
   eski kod bozulmaz (kodla kanıtlanır: alanı okuyan tüm yerler grep edilir).
5. **Test kalkanı:** konuyu koruyan mevcut testler (§8) + daldaki yeni testler
   listelenir; PR'da hepsi yeşil koşar.

### 12.2 Sıralama kuralları (bu kanıtlardan türetilmiş)

- **Önce: salt sunum + geri alınabilir** değişiklikler (UI sunumu, ekleme katmanları).
- **DB migrasyonu gerektiren ilk iş, migrasyon + kod aynı PR'da** ve
  migrasyon önce canlı DB'ye uygulanır; deploy sırası §12.1-3 yönüne göre.
- **Yeni kavram** (varyant gibi, yeni veri girişi gerektiren) en sona — değeri
  ancak esnaf veri girdiğinde görünür, riski en yüksek.
- **Bağımlılık zinciri import/çağrılarla kanıtlanır**, dokümandan değil:
  örn. varyant editörü `ProductImagePolicy.maxImages` ve rich metadata
  modelini import ediyor → 1 ve 4'ten önce gelemez (grep kanıtı).
- **Erteleme kararı da kodla gerekçelenir:** konu, o PR'ın dokunduğu
  davranış için çağrılmıyorsa sonraya (ör. kategori senkron motoru).

### 12.3 Her PR'ın canlıya çıkış kapısı

1. Dalda: ilgili tüm testler yeşil (§8 listesi + yeni testler).
2. Preview: canlı kopyasında mevcut davranış (§9 tablosundaki "mevcut davranış"
   satırı) gözle + testle doğrulanır.
3. DB migrasyonlu PR'da: migrasyon canlı DB'ye uygulanır → eski kodla uyum
   kontrolü (12.1-3 yönü) → kod deploy.
4. Canlı sonrası: ilgili canlı sayfa (ör. ürün kartı) 5 dakika gözle denetlenir;
   geri alma planı PR açıklamasında yazılı olur (revert commit).

### 12.4 Kod kanıtı örnekleri (bu haritada yapıldı)

- PR-1: doküman başta "DB yok" demişti; kod kontrolü **yanlışladı** —
  daldaki `20260914175500_product_image_limit_11.sql` trigger'ı 3–11 aralığını
  DB'de zorunlu kılıyor. Dolayısıyla PR-1 migrasyonlu PR olarak sıralandı
  ve §12.2 yön kuralı uygulanır (DB önce, kod sonra).
- main'de 4-limiti 5 ayrı yerde: `store_product.dart:74`, `store_publish_validator.dart:75`,
  `xml_product_upload_service.dart:279`, `product_editor_sheet.dart:28`,
  `OwnerProductManager.tsx:475/523` (+ web `products.ts` görüntüleme).
  PR-1 dokunma listesi bu 6 dosyadır; başka yere dokunmaz.

- Taşıma sırasında mevcut davranış korundu; canlıya ve DB'ye dokunulmadı.

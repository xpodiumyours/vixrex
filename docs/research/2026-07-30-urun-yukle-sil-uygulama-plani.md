# Ürün Yükleme / Silme — Uygulama Planı (Canlı)

**Tarih:** 30 Temmuz 2026  
**Durum:** Kullanıcı kararları kilitlendi — kod henüz yazılmadı  
**Dal bağlamı:** `security/bootstrap-all` (kurtarma commit’i ayrı; bu iş ayrı dilim)

## Kilitli ürün kararları

1. Gizli / taslak ürün **yok**. Ürün ya yüklenir ya silinir.
2. Silme **geri alınamaz** (kalıcı).
3. Uygulama **canlıda**; veri kaybı riski olan toplu silme yasak.
4. Önceki araştırma notu: `docs/research/2026-07-30-urun-yukleme-silme-sistem-uyumu.md`  
   Bu plan, o nottaki “taslak/gizle/soft delete” önerisini **bilinçli olarak ezer** (kullanıcı kararı).

## Hedef

- Yükleme: ürün create/update ile uzağa yazılsın; Atmosfer alanları (eski fiyat, rozet, teslim) dahil.
- Silme: yalnız kullanıcının seçtiği ürün(ler) kalıcı silinsin; çift onay.
- **Otomatik “listede yok → uzak ürünleri sil” senkronu kalksın** (canlı veri koruması).

## Koruma sınırları

- Kullanıcı ürünlerine toplu `DELETE` yok.
- Migration ile mevcut ürün satırı silinmez.
- Publish / vitrin silme / hesap silme bu dilimin dışında.
- `is_visible` alanı DB’de kalabilir; UI’da “gizle” birincil yol olmaz (ayrı temizlik dilimi).
- Canlı RPC imzası değişince geriye dönük istemciler kırılmasın (yeni param’lar DEFAULT’lu).

## Dilimler (sırayla)

### Dilim 1 — Veri kaybı kilidi (önce bu)

**Ne:** `syncCatalogToRemote` içindeki “yerelde olmayan uzak ürünü `deleteProduct`” döngüsünü kaldır.

**Dosyalar:**
- `lib/controllers/store_editor_controller.dart`

**Davranış sonrası:**
- Sync yalnız create/update (upsert) yapar.
- Silme yalnız açık `removeProduct` / sheet `_delete` → tek ürün RPC.

**Test:**
- Uzakta A,B varken yerelde yalnız A kaydedilince B **silinmemeli**.
- Tek ürün silme hâlâ çalışmalı.

**Kanıt:** unit/widget veya mevcut sync testine regresyon; yoksa yeni sözleşme testi.

---

### Dilim 2 — Açık silme UX (geri alınamaz)

**Ne:**
- Onay metni: “Bu ürün kalıcı silinecek. Geri alınamaz.”
- “Yayınlamayı unutmayın / taslaktan silindi” yanıltıcı metinleri kaldır.
- Silme başarısızsa başarı mesajı yok; yerel listeden de geri alma veya sync retry net olsun.
- `removeProduct` uzak `Result` başarısızsa yerel silmeyi yapmasın (veya net hata + geri al).

**Dosyalar:**
- `lib/widgets/product/product_management_sheet.dart`
- `lib/controllers/store_editor_controller.dart`

**Not:** Sheet bugün `_persist` → sync çağırıyor. Dilim 1’den sonra silme, sync’e güvenmeden **doğrudan `removeProduct` / `deleteProduct`** ile yapılmalı (seçilen id).

---

### Dilim 3 — Yükleme alanları (Atmosfer)

**Ne:** create/update yoluna yaz:
- `old_price_amount`
- `badge_tag`
- `fulfillment_region`
- (mümkünse) `price_text` yanına parse edilmiş `price_amount`

**Dosyalar:**
- Yeni migration: `create_store_product` / `update_store_product` param + UPDATE/INSERT
- `lib/repositories/product_repository.dart`
- `lib/repositories/supabase_product_repository.dart`
- `lib/services/product_service.dart`
- `lib/controllers/store_editor_controller.dart` (add/update/sync çağrıları)
- İsteğe bağlı: Next ürün detay select’ine aynı alanlar

**Canlı migration kuralı:** `ADD` / `CREATE OR REPLACE` ile param ekle; mevcut satırlara `DELETE` yok. Uygulamadan önce kullanıcı onayı.

---

### Dilim 4 — Gizle UI sadeleştirme (sonra)

**Ne:** “Vitrinde görünüyor” switch’ini kaldır veya sabitle (hep görünür).  
DB kolonu şimdilik kalsın (canlı şema riski düşük).

Bu dilim zorunlu değil; Dilim 1–3 yeterliyse ertelenebilir.

---

## Bilinçli yapılmayanlar

- Soft delete / `deleted_at` / çöp kutusu
- “Önce taslak, sonra yayınla” ürün modeli (kullanıcı reddetti)
- Kiralık / PayTR / Keşfet
- Toplu uzak katalog wipe

## Önerilen uygulama sırası

1. Dilim 1 (kilit) → test  
2. Dilim 2 (metin + Result) → test  
3. Dilim 3 (RPC + Flutter yazma) → migration onayı → test  
4. Dilim 4 isteğe bağlı

## Başarı ölçüsü

- Canlıda yanlışlıkla “eksik liste → toplu ürün silme” olamaz.
- Kullanıcı bir ürünü silince yalnız o ürün gider; geri yok; metin bunu söyler.
- Yüklenen eski fiyat / rozet / teslim public katalogda görünür (Dilim 3 sonrası).

## Açık onay noktaları

- [x] Model: ya yükle ya sil; gizle yok  
- [x] Silme geri alınamaz  
- [x] Dilim 1 koduna başla  
- [x] Dilim 2 açık silme UX  
- [x] Dilim 3 Flutter + migration dosyası (canlıya uygulama ayrı onay)  
- [ ] Dilim 3 migration canlıya uygulama (ayrı onay)
- [ ] Dilim 4 gizle UI (isteğe bağlı)

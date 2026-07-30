# Ürün Yükleme / Gizleme / Silme — VixRex Sistem Uyumu Araştırması

**Tarih:** 30 Temmuz 2026  
**Kapsam:** Kullanım (UX) + işlem/teknik model; Flutter panel, Next public vitrin, Supabase  
**İşlem sınırı:** Bu belge araştırma notudur. Kod, veritabanı, Git ve canlı sistem değiştirilmedi.

> “Çıkarım / ürün kararı” işaretli maddeler Vixrex’in uygulaması gereken kurallardır; Shopify veya Supabase’in hazır garantisi değildir.

## Kısa karar

1. **VixRex’in kendi korunan akış sözleşmesi, ürün ekleme/düzenleme/silmenin taslakta kalmasını ister.** Bugünkü kod her katalog değişiminde uzak senkron yapıp listede olmayan ürünleri kalıcı `DELETE` eder; bu sözleşme ile çelişir. [`docs/product/PROTECTED_FLOWS.md` §2.7](../product/PROTECTED_FLOWS.md), [`lib/controllers/store_editor_controller.dart` `syncCatalogToRemote`](../../lib/controllers/store_editor_controller.dart), [`lib/widgets/product/product_management_sheet.dart` `_persist`](../../lib/widgets/product/product_management_sheet.dart)

2. **Sektör modeli (Shopify): ürün görünürlüğü durumla yönetilir; silmek ile gizlemek ayrıdır.** Active / Draft / Archived (ve Unlisted). Draft ve Archived müşteriye görünmez; Active satışa hazırdır. [Shopify Help — Product status](https://help.shopify.com/en/manual/products/details/product-details-page), [Shopify Admin API `ProductStatus`](https://shopify.dev/docs/api/admin-graphql/latest/enums/ProductStatus)

3. **Supabase resmi rehberi: kurtarılabilir veri için soft delete önerir.** `deleted_at` ile işaretle; sorguda/view’da hariç tut; kalıcı silmeyi sonradan toplu iş olarak yap. [Supabase — Data deletion / Soft deletes](https://supabase.com/docs/guides/database/postgres/data-deletion)

4. **VixRex’e uygun çıkarım:** Gizle = `is_visible=false` (veya Draft). Arşivle/sil (kullanıcı dili) = soft delete. Kalıcı `DELETE` varsayılan yol olmamalı. Yayın = açık “Yayınla” ile public yüzün güncellenmesi. [`PROTECTED_FLOWS.md` §2.9–2.10](../product/PROTECTED_FLOWS.md), [`B2B_LIFECYCLE.md` §3](../product/B2B_LIFECYCLE.md)

5. **Atmosfer alanları (eski fiyat, rozet, teslim) formda var; create/update RPC’ye yazılmıyor.** Bu, silme modelinden bağımsız bir yazma boşluğudur; yükleme düzeltmesinde ele alınmalıdır. Kod kanıtı: [`supabase_product_repository.dart`](../../lib/repositories/supabase_product_repository.dart), canlı RPC imzası (eski fiyat/rozet/teslim parametresi yok).

---

## 1. Soru

VixRex’te ürün yükleme, gizleme ve silme hem **kullanım** hem **işlem** olarak sisteme nasıl uygun olmalı — özellikle kullanıcı verisinin yanlışlıkla bir daha silinmemesi için?

---

## 2. Bugünkü VixRex gerçek durumu (kanıtlı)

### Sözleşme (hedeflenen)

| Akış | Kritik davranış | Kaynak |
|------|-----------------|--------|
| 2.7 Ürün ekleme/düzenleme/silme | **Taslakta kalır** | `PROTECTED_FLOWS.md` |
| 2.9 Kaydet | Yerel depolama; publish olmaz | aynı |
| 2.10 Yayınla | Public vitrin **bir kez** güncellenir | aynı |
| B2B uçtan uca | Kişiselleştirme → açık “Yayınla” → public | `B2B_LIFECYCLE.md` §3 |

Belge durumu: “Kullanıcı onayı bekliyor” — yani sözleşme taslak/onay aşamasında; yine de mevcut ürün niyeti budur.

### Kod (fiili)

1. `ProductManagementSheet._persist` her değişiklikte `onCatalogChanged` çağırır.  
2. Form bunu `syncCatalogToRemote`’a bağlar.  
3. `syncCatalogToRemote`: UUID’si uzakta olanları update, olmayanları create; **yerelde olmayan uzak ürünleri `delete_store_product` ile siler**.  
4. `delete_store_product` SQL: `DELETE FROM public.products WHERE id = ...` (kalıcı). Kaynak: `supabase/migrations/20260720_add_product_crud_rpcs.sql`.  
5. UI metni silmede “taslaktan silindi, yayınlamayı unutmayın” der; yayınlı vitrinde işlem anında uzağa gider — metin ile davranış uyumsuz.  
6. `is_visible` gizleme için kullanılıyor; public Next yalnız `is_active + is_visible` okur.  
7. Form: `oldPriceAmount`, `badgeTag`, `fulfillmentLocation` → repository create/update parametrelerinde yok.

### Sonuç

**Sözleşme = taslak + açık yayın.**  
**Kod = anında uzak senkron + eksik satırları kalıcı sil.**  
Bu fark, veri kaybı riskinin köküdür.

---

## 3. Sektör / platform modelleri

### Shopify — ürün durumu

Resmi durumlar ([Help Center](https://help.shopify.com/en/manual/products/details/product-details-page), [ProductStatus enum](https://shopify.dev/docs/api/admin-graphql/latest/enums/ProductStatus)):

| Durum | Anlam |
|-------|--------|
| Active | Satışa hazır; kanal yayını ayrı konu |
| Draft | Hazır değil; müşteriye kapalı |
| Archived | Artık satılmıyor; vitrinden ve ana listeden gizlenir |
| Unlisted | Aktif ama yalnızca doğrudan linkle |

**VixRex çıkarımı:** “Gizle” ≈ Draft/görünmez; “Kaldır / arşivle” ≈ Archived; “Kalıcı sil” ayrı, nadir ve daha ağır onaylı bir işlem olmalı. Shopify’ın varsayılanı “her kayıtta remote DELETE sync” değildir.

### Supabase — soft delete

[Resmi Data deletion rehberi](https://supabase.com/docs/guides/database/postgres/data-deletion): kurtarma isteniyorsa `deleted_at` güncelle; view/sorgu ile hariç tut; kalıcı silmeyi düşük trafikte toplu iş olarak planla.

**VixRex çıkarımı:** Ürün kataloğu “yanlışlıkla silinirse geri gelsin” sınıfındadır → soft delete birincil yol.

### KVKK notu

KVKK silme/yok etme kuralları **kişisel veri** içindir. Ürün kartı (fiyat, görsel, stok metni) işletme içeriğidir; kişisel veri değildir. Yine de “deneme bitince veri silme” ile “ürün silme” karıştırılmamalıdır: deneme araştırmasında öneri **veriyi silme, yayın hakkını kapat** idi. [`docs/research/kiralik-vitrin-14-gun-deneme-resmi-arastirma-2026-07-29.md`](./kiralik-vitrin-14-gun-deneme-resmi-arastirma-2026-07-29.md)

---

## 4. Kullanım (UX) seçenekleri

| | Model | Kullanıcı ne görür | Artı | Eksi |
|---|--------|-------------------|------|------|
| **A** | Anında canlı (bugün) | Her kayıt/silme public’e yansır | Hızlı | Veri kaybı, sözleşme ihlali, yanıltıcı metin |
| **B** | Taslak + Yayınla (sözleşme) | Düzenle → Kaydet (taslak) → Yayınla (canlı) | Galeri/kapak ile tutarlı; geri alınabilir | Yayın unutulursa vitrin eski kalır |
| **C** | Hibrit | Gizle anında; ekle/düzenle taslak; sil onay+soft | Gizleme hızlı | İki hız → eğitim gerekir |

### Önerilen (çıkarım): **B, gizleme için net dil**

- **Ekle / düzenle / sırala:** taslak (yerel + isteğe bağlı uzak taslak kaydı). Public değişmez.  
- **Gizle / göster:** `is_visible`; metin: “Vitrinde gizle” / “Vitrinde göster”. Anında canlı yapılacaksa bile **DELETE değil UPDATE**.  
- **Sil:** iki adımlı onay + “Çöp / arşiv (geri alınabilir)” dili; varsayılan soft delete.  
- **Yayınla:** tek açık eylem; public katalog bu anda hizalanır.  
- Mesajlar asla “yayınla unutma” dememeli eğer işlem zaten canlıya gittiyse; tersi de geçerli.

Gerekçe: `PROTECTED_FLOWS` 2.7–2.10, B2B “açık Yayınla”, kullanıcı “bir daha veri silme” talebi, Shopify durum ayrımı.

---

## 5. İşlem / teknik seçenekleri

| | Senkron | Silme | Gizleme |
|---|---------|-------|---------|
| **T1 (bugün)** | Diff sync: eksik = DELETE | Hard DELETE | `is_visible` |
| **T2** | Upsert-only: id ile create/update; otomatik silme yok | Soft (`deleted_at` veya `is_active=false`) | `is_visible` |
| **T3** | Yayın anında tam replace (transaction) | Soft + nadir hard purge | `is_visible` |

### Önerilen (çıkarım): **T2 şimdi; T3 yayın adımında kontrollü**

1. **`syncCatalogToRemote` içindeki “listede yok → DELETE” kaldırılmalı veya kapalı bayrakla bırakılmalı.** Silme yalnız açık `remove/archive` RPC ile.  
2. **`delete_store_product` soft delete’e çevrilmeli** (`deleted_at` veya mevcut `is_active=false` + public filtre). Hard delete ayrı RPC / saklama süresi sonrası. Kaynak uyumu: [Supabase soft deletes](https://supabase.com/docs/guides/database/postgres/data-deletion). Not: Bugün `is_active` zaten fetch’te filtreleniyor; soft delete için kullanılabilir mi teknik inceleme gerekir — `is_active`’in başka anlamı varsa `deleted_at` daha temiz.  
3. **Yükleme:** create/update’e `old_price_amount`, `badge_tag`, `fulfillment_region` (+ isteğe `price_amount` parse) eklenmeli.  
4. **Hata yutma kalkmalı:** uzak başarısızsa yerel “başarılı silindi/eklendi” denmemeli.  
5. **Kategori:** yerel `category-*` id’leri remote UUID’ye map edilmeden `category_id` yazılmamalı; yoksa kategori sessizce düşer.  
6. **Public:** katalog + ürün detay aynı alan setini okumalı (eski fiyat/rozet/teslim).

`VIXREX_RULES.md`: çalışan akış kanıtsız kaldırılmaz; DROP/toplu DELETE yüksek risk — soft delete bu kurala daha uyumlu.

---

## 6. Kesinlikle yapılmamalı

1. Panelde her tuşta “eksik satırları hard DELETE et”.  
2. “Taslak” deyip canlıya yazmak / silmek.  
3. Silme başarısız olsa bile başarı snackbar’ı.  
4. Kullanıcı ürünlerini migration/seed ile toplu silmek.  
5. Atmosfer alanlarını formda gösterip RPC’de yok saymak (sessiz veri kaybı).  
6. Boş ürün listesiyle “tüm uzak kataloğu temizle” davranışını varsayılan bırakmak.

---

## 7. Açık ürün kararları (uygulama öncesi)

Her soruda önerilen cevap + gerekçe:

1. **Ürün ekle/düzenle public’e ne zaman yansısın?**  
   - **Öneri: Yalnız “Yayınla”.** Gerekçe: `PROTECTED_FLOWS` 2.7/2.10; kapak/galeri ile aynı dil.

2. **“Gizle” anında canlıya gitsin mi?**  
   - **Öneri: Evet (UPDATE `is_visible`), soft/hard silmeden.** Gerekçe: hızlı stok/menü ihtiyacı; veri kaybı yok.

3. **“Sil” ne yapsın?**  
   - **Öneri: Soft arşiv (geri alınabilir 30 gün); kalıcı silme ayrı/ileri.** Gerekçe: Supabase soft delete; kullanıcı veri koruma talebi.

4. **Yayınlanmamış vitrinde ürün nereye yazılsın?**  
   - **Öneri: Yerel taslak yeterli; uzak yazma yalnız yayın/editToken sonrası.** Gerekçe: mevcut “önce yayınlayın” mesajı ile uyumlu; yarı yazılmış remote katalog oluşmasın.

5. **Toplu yükleme (XML/OCR) gizlileri ne yapsın?**  
   - **Öneri: Varsayılan gizli taslak; kullanıcı işaretleyince görünür + yayın.** Gerekçe: Shopify duplicate→Draft benzeri; yanlış toplu yayını önler.

---

## 8. Kaynakça

### Repo
- `docs/product/PROTECTED_FLOWS.md`
- `docs/product/B2B_LIFECYCLE.md`
- `docs/product/KNOWN_DEFECTS.md` (ürün CRUD maddesi yok; ilgili kapak/GPS geçmişi)
- `VIXREX_RULES.md`
- `lib/widgets/product/product_management_sheet.dart`
- `lib/controllers/store_editor_controller.dart`
- `lib/repositories/supabase_product_repository.dart`
- `supabase/migrations/20260720_add_product_crud_rpcs.sql`
- `docs/research/kiralik-vitrin-14-gun-deneme-resmi-arastirma-2026-07-29.md`

### Dış birincil
- [Shopify Help — Product details / status](https://help.shopify.com/en/manual/products/details/product-details-page)
- [Shopify Admin GraphQL — ProductStatus](https://shopify.dev/docs/api/admin-graphql/latest/enums/ProductStatus)
- [Supabase Docs — Postgres data deletion (soft deletes)](https://supabase.com/docs/guides/database/postgres/data-deletion)

---

## Uygulama notu (henüz yapılmadı)

Onay sonrası önerilen sıra:

1. Ürün kararlarını (bölüm 7) kilitle.  
2. Soft delete + “otomatik DELETE sync” kaldırma (veri koruma).  
3. Create/update’e Atmosfer ürün alanları.  
4. UX metinlerini gerçek davranışa hizala.  
5. Test: gizle / soft sil / yayın / geri al — hard DELETE yok.

**Kanıt seviyesi:** Araştırma ve kod okuma = kodda görüldü. Yerelde uçtan uca akış bu belgede çalıştırılmadı.

# P0-01 — Görsel hakları için kesintisiz gölge denetimi

**Kapsam:** Yalnızca fatura fotoğrafından ürün kartı oluşturma hattında hak kayıtlarını *ayrı* ve denetlenebilir olarak saklamak. Bu değişiklik **yayın politikasını sıkılaştırmaz**.

## Korunan davranışlar

- Fatura fotoğrafı okunur, ürün araştırılır, otomatik taslak kaydedilir.
- Esnaf satış fiyatını ve stok durumunu kontrol eder; ayrı **Yayınla** eylemi korunur.
- `invoice_image_rights.usage_status = unknown` tek başına kartı durdurmaz.
- Mevcut `denied` kontrolü aynen kalır.
- Mevcut ürün, fiyat, stok, görsel ve vitrin görünürlüğü değişmez.
- Ek sorgu, migration, ağ çağrısı, veri silme veya görev kuyruğu yoktur.

## Eklenen denetim

Zaten okunan `invoice_image_rights` kayıtları salt-okunur sınıflandırılır. Faturadan hazırlanıp kendi depomuza aktarılmış üretici görsellerinin **mevcut** `fatura_kanit.gorselKaynaklari` öğesine iki ek alan yazılır:

- `hakKayitDurumu`: `verified_supplier_permission`, `unknown`, `denied`, `kayit_yok`
- `hakIncelemeGerekiyor`: denetim için işaret; otomatik yayın kilidi değildir.

**Önemli:** Bu alanlar doğrulanmış hukuki lisans belgesi yerine geçmez. `verified_supplier_permission` dahi kaynağın kayıt iddiasıdır; üretici sözleşmesi ayrıca teyit edilir.

## Gözlem / kabul

1. Fatura, bilinmeyen görsel izniyle eskisi gibi taslak oluşturur.
2. Onay ve Yayınla davranışları değişmez; kodda yeni engel veya SQL yayın kuralı bulunmaz.
3. Görsel kaynağına ait mevcut `usage_status` ayrı kayıtta görülebilir.
4. Bir URL için `denied` durumu `verified` ile çakışırsa denetim ret olarak raporlar.
5. Satırda hak kaydı yoksa `kayit_yok` yazılır, bu açık izin sayılmaz.

## Sonraki aşama (bu değişikliğin dışında)

Üretici ret ve izin geri çekme işleminin **önceden yayımlanmış** ürünlerde nasıl uygulanacağı, gerçek etki analizi ve açık onay gerektirir. Mevcut 13 yayımlanmış mağaza ürünü / 16 `unknown` görsel hak kaydı otomatik gizlenmez. Yöneticiye bildirim, hak belgesi yükleme ve kontrollü geri çekme mekanizması ayrı iş kalemidir.

## Operasyonel güvence

Çalışma dalı üretime merge edilmeden uygulama ve veritabanı etkilenmez. Bu değişiklik migration, üretim ayarı veya canlı kayıt güncellemesi içermez. CI ve önizleme otomasyonu ayrı dalda tetiklenebilir; üretim dağıtımı yapılmaz.

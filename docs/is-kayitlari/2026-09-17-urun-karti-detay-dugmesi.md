# İş Kaydı — Ürün kartındaki "Tüm ürün detayları" düğmesi

Şablon: `.specify/templates/overrides/giris-kapisi-karti.md`
Anayasa: `.specify/memory/constitution.md`

---

## 1. İş — tek cümle

> Vitrindeki ürün kartı, esnafın girdiği bütün kategori bilgilerini gösterir;
> kartın içinde ürün sayfasına götüren **"Tüm ürün detayları"** düğmesi **bulunmaz**.

İsteyen: proje sahibi · Tarih: 17.09.2026

## 2. Nereden başlıyoruz

- **Başlangıç halkası:** Etkilenen yüzeyler
- **Neden:** Alanlar, kayıt ve gösterim aynı bilgiyi iki yüzeyde (kart + ürün sayfası)
  tutuyor. Kırık olan zincir halkası "tek kaynak / etkilenen yüzeyler".
- **Kanıt:** `public_web/src/components/ProductQuickViewBase.tsx` satır 458-468 —
  kartın içindeki düğme `/v/<vitrin>/urun/<ürün>` adresine gidiyor; aynı kart
  satır 163'ten itibaren `buildProductDetailFacts` ile **tam** listeyi gösteriyor.
- **İçeriği kim üretecek:** Esnaf (kendi formundan) — elle doldurma yok.

## 3. Zincirin bugünkü hâli (ölçüm)

| Halka | Durum | Kanıt |
|---|---|---|
| Kural | VAR ama **kart yüzeyi boş** | `public_web/src/lib/productAttributeSchema.ts:6` üç yüzey tanımlıyor: `card`, `quick`, `detail`. Ortak şema (`shared/product_attribute_schema.json`) 47 alan tanımlıyor: `card` = **0**, `quick` = 20, `detail` = 47. Yani "ürün kartı" yüzeyinin kuralı yazılmamış |
| Girdi | VAR | `public_web/src/components/owner/OwnerRichProductFields.tsx` + `lib/widgets/product/product_rich_fields_editor.dart` |
| Doğrulama | VAR | Şema + sunucu kontrolü: `PRODUCT_METADATA_INVALID`, `PRODUCT_TEMPLATE_MISMATCH` (`supabase/migrations/20260915010000_product_rich_core_minimal.sql`) |
| Saklama | VAR | `products.metadata` jsonb — `create_store_product_v3` / `update_store_product_v2` |
| Yetki | VAR ama **ölçülmedi** | Fonksiyonlar `security definer`; içinde `_check_store_authorization(store_id, edit_token)`. `anon` yetkisi verilmiş (satır 373, 565). Üç kimlikle denenmedi |
| Geçiş kapısı | VAR | `is_visible = true` filtresi: `public_web/src/app/v/[slug]/page.tsx:242`, `.../urun/[productSlug]/PublicProductDetailPage.tsx:100` |
| **Etkilenen yüzeyler** | **KIRIK** | Kart, ürün sayfasının işini de yapıyor ve ona yol veriyor |
| Çıktı | İki yüzeyde aynı | `buildProductDetailFacts` hem kartta (satır 163) hem ürün sayfasında (`PublicProductDetailPage.tsx:247`) |
| Geri alma | Kayıtlı değil | Geçmişte gerçek geri alma yapıldı (`f0eb834e` "Revert ... #509") ama yazılı yol yok |

## 4. Neyi değiştirecek — işin sınırı

| Yüzey | Ne değişecek |
|---|---|
| Ürün kartı | "Tüm ürün detayları" düğmesi kalkar |
| Ürün kartı + vitrin kataloğu | Kullanılmaz hale gelen `productUrl` aktarımı temizlenir |

## 5. Neye dokunmayacak

- Ürün sayfası (`.../urun/[productSlug]/`) — çalışıyor, değişmez
- Arama motoru listesi (`sitemap.xml`) — karar bekliyor
- Esnaf formları, veritabanı, kayıt yolu
- Flutter paneli (`lib/`) — izinsiz dokunulmaz

## 6. Onaylanan kararlar

| # | Karar | Tarih |
|---|---|---|
| 1 | Ürün kartı **ana yüzey**. Listede ürüne tıklayınca kart açılır; ürün sayfası tıklamayla açılmaz | 17.09.2026 |
| 2 | Kart, esnafın girdiği bütün kategori bilgilerini gösterir | 17.09.2026 |
| 3 | Karttan ürün sayfasına giden düğme **kaldırılır** | 17.09.2026 |

Onay: ☑ verildi · 17.09.2026

## 7. Bitince bakılacak adres

- **Adres:** yerel üretim derlemesinde bir vitrinin ürün listesi
- **Ne görülmeli:** ürüne tıklayınca kart açılır; kartta "Tüm ürün detayları"
  düğmesi **yoktur**; WhatsApp düğmesi durur

## 8. Geri alma

> Tek kaydı geri al (düğmeyi silen değişikliği geri al). Yöntem geçmişte
> kullanıldı: `git revert <kayıt>`

## 9. Durum

- ☐ Dalda duruyor — dal adı:
- ☐ Ana dala indi — kayıt numarası:
- ☐ Yayına dağıtıldı — tarih:
- ☐ Canlıda gözle doğrulandı — adres:

## 10. Yarım kalan

> Uygulama henüz başlamadı. Aşağıdaki "Ek" bölümündeki üç bulgu ayrı iş olarak
> kaydedilmeli.

---

## Ek — ölçüm sırasında çıkan, bu işin dışındaki bulgular

1. **Yetki ölçülmedi.** Ürün/kategori oluşturma ve güncelleme fonksiyonları
   "herkes" kimliğine açık; içinde düzenleme anahtarı kontrolü var. Anayasa V:
   üç kimlikle denenmeli. Denenmedi → "güvenli" denemez.
2. **Yerel ana dal 5 kayıt geride.** GitHub ana dalı `37a5d402` (#512),
   yerel ana dal `13046248`. Bu yüzden ilk ölçümde "canlıda değil" yanlışı yapıldı.
   Dal açarken taban **uzaktan** alınmalı (AGENTS.md madde 8).
3. **Kaynak kodda kelime arayan test.** `public_web/tests/urun-yuzeyi-ikiz-kontrol.test.ts`
   dosyalardaki metni sayıyor, ekrana bakmıyor. Anayasa IV ile çelişiyor:
   yeşil olması çalıştığının kanıtı değil.
4. **Ürün sayfası aranabilir kalıyor.** `sitemap.xml` ürün sayfalarını listeliyor
   (`sitemap.xml/route.ts:184`). Karttan yol kalkarsa, arama motorundan gelen
   müşteri ürün sayfasına düşer ama sitede geri yolu kalmaz. Karar gerekli.
5. **Kök neden — "ürün kartı" yüzeyinin kuralı yok.** Ortak şema üç yüzey
   tanımlıyor ama `card` yüzeyine **tek alan bile** işaretlenmemiş (`card` = 0,
   `quick` = 20, `detail` = 47). Şema **iki istemcinin ortak dosyası**
   (`shared/product_attribute_schema.json`), yani değişikliği Flutter panelini de
   etkiler. Bu boşluk kapanmadan kart işi her açıldığında başlangıç noktası
   tartışmalı kalır. Ayrı iş olarak kaydedilmeli.
6. **Ölçüm sırasında yapılan hata.** İlk ölçümde yerel ana dala bakılıp
   "değişiklik canlıda değil" denildi; GitHub ana dalı ölçülünce tersi çıktı
   (#512 canlıya giden yolda). Ders: ölçümde önce `origin/main` okunur.

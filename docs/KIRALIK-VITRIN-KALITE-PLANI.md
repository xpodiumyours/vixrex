# Kiralık vitrin kalite planı — tek liste

**Ne:** kiralık (hazır) vitrinlerin ürün kartı kalitesini profesyonel seviyeye çıkarma planı.
**Ölçüm tarihi:** 2026-09-18 (9 vitrin) · **yeniden ölçüm:** 2026-09-25 (30 vitrin) · **Ölçüm yeri:** canlı `vixrex.com`, gerçek tarayıcı.
**Dayanak:** `GOREV-vitrin-kalite.md` (Casper'ın 2026-09-17 kararı) + bu dosyadaki canlı ölçüm.
**Kural:** Bu dosya ölçümle güncellenir. Ölçülmeyen satıra "ölçülmedi" yazılır, tahmin yazılmaz.

**Adlandırma:** Kullanıcıya görünen ad **kiralık vitrin** (kiralanabilir hazır şablon). Veritabanındaki teknik işaret `stores.is_demo`; bu dosyada "demo" yalnız teknik alan/slug adlarında (`is_demo`, `demo-teknofix`) geçer.

---

## 1. Bugünkü gerçek (2026-09-25 canlı ölçümü — geçerli olan)

Ölçüm komutu (proje içinde, salt okunur): `node tool/canli_durum.ts`
Ayrıntılı demo içerik ölçümü: `node .scratch/demo-icerik-olcum.cjs`

| Ölçülen | Değer |
|---|---|
| Keşfet'te kiralık duran vitrin (`is_published`, `is_demo`) | **30** (30'unun tamamı `is_demo`; 5 gerçek müşteri vitrini henüz yayında değil) |
| Aktif demo ürün | **182** (hepsi 3+ fotoğraf) |
| Özelliği/hizmeti dolu ürün | 164 → **182** (aşağıdaki düzeltmeden sonra) |
| Özelliği boş ürün | **18** — üçü de şu vitrinlerde: Aymira Giyim (6), Lezzet Durağı (6), Nova Kuaför (6) |
| Boşluğun sebebi | Bu üç vitrinin **9 ürün kategorisi** `product_template_key = generic`; kart satırı yalnız `metadata.templateKey` ile geliyor (`public_web/src/lib/productCardPresentation.ts:102`) |
| Puan bandı açık vitrin | **0 / 30** (üç vitrin aynı 4.9/128) |

**Düzeltme (2026-09-25, `supabase/migrations/20260925100000_kiralik_vitrin_urun_ozniteliklerini_tamamla.sql`):** kiralık vitrinlerin `generic` kategorileri ortak listedeki şablonla doldurulur (`shared/business_categories.json`: Giyim→fashion, Gıda→food, Kafe/Lokanta→cafe_restaurant, Kuaför→service, Butik→fashion, Teknik Servis→technical_service); ardından ürünlerin `metadata.templateKey`, `attributes`/`service` ve marka alanları dolar.

**Yerel doğrulama (2026-09-25, gerçek Postgres):** `supabase db reset` sonrası iki migration sırayla koştu → 9 kategori şablonu düzeldi, 144 ürünün alanları doldu, **boş ürün 0**, **generic kategori 0**, guard'lar geçti. Puan migration'ı (`20260925110000_kiralik_vitrin_puanlari.sql`) → **30/30 bant açık**, **30 farklı puan çifti**, tekrar eden çift 0. Görsel kanıt: yerel önizlemede Aymira Giyim kartlarında özellik satırı ("Siyah") ve hero'da "4.6 (74 değerlendirme)" görünüyor.

**Canlıya uygulama (2026-09-25):** henüz **uygulanmadı** — ölçüm yolu kapalı (`exec_sql` RPC yok, CLI oturumu yok). Dosyalar hazır; uygulandıktan sonra ölçüm aynı komutla tekrarlanır.

---

## 1b. 2026-09-18 ölçümü (9 vitrin dönemi — tarihsel kayıt)

| # | Vitrin | Mağaza adı | Ürün | Tek fotoğraflı | Özelliği boş | Hizmet mi |
|---|---|---|---|---|---|---|
| 1 | `kiralik-teknik` | Hızlı Teknik | 6 | 6 | 6 | evet |
| 2 | `kiralik-kuafor` | Stil Studio | 6 | 6 | 6 | evet |
| 3 | `kiralik-gida` | Doğal Market | 6 | 6 | 6 | hayır |
| 4 | `kiralik-kafe` | Kahve Köşesi | 6 | 6 | 6 | hayır |
| 5 | `kiralik-butik` | Atmosfer Butik | 6 | 6 | **0** | hayır |
| 6 | `demo-teknofix` | TeknoFix | 8 | 8 | 8 | evet |
| 7 | `demo-lezzet-duragi` | Lezzet Durağı | **0** | – | – | – |
| 8 | `demo-nova-kuafor` | Nova Kuaför | **0** | – | – | – |
| 9 | `demo-aymira-giyim` | Aymira Giyim | **0** | – | – | – |
| | **TOPLAM** | | **38** | **38** | **32** | 20 |

**Kartta bugün görünen:** kategori etiketi, ürün adı, fiyat, üstü çizili eski fiyat, "Hizmet/Ürün" etiketi, "Hızlı incele" düğmesi.

**Kartta bugün görünmeyen:** özellik satırı (marka, renk, beden, süre...).
Sebebi **veri**, kod değil: 38 ürünün 32'sinde özellik verisi boş. Dolu olan tek vitrin `kiralik-butik` (Renk, Beden, Materyal, Desen, Beden sistemi) — ve o veri canlıda **hızlı bakış penceresinde görünüyor**, kartın üstünde görünmüyor.

**Doğru çalışanlar (bu turda dokunulmayacak):** "6 Hizmet Listeleniyor" (hizmet dili doğru), rozet artık kesilmiyor (`BİLGİSAYAR & LAPTOP SERVİSİ` tam görünüyor), hızlı bakış penceresi açılıyor, 9 vitrinde konsol/ağ hatası **0**.

**Ürün detay sayfası (ölçüldü):** tek fotoğraf, özellik bölümü yok, yalnız kategori + ad + açıklama + fiyat + stok + WhatsApp.

---

## 2. Sıra (bozulmaması için bu sırayla)

0. **Araç önce canlıya:** PR #519 (esnaf formu + kartta özellik satırı). Bu çıkmadan içerik girilirse kartta yine görünmez.
1. **3 boş vitrin** — en görünür eksik, kiralanacak vitrinin hiç ürünü yok.
2. **32 ürünün özellikleri** — kartın "profesyonel" görünmesini sağlayan asıl iş.
3. **38 ürünün fotoğrafı** — hepsi tek fotoğraflı.
4. **Ürün detay sayfası** — özellik bölümü yok; `feat/zengin-urun-detay-sayfasi` dalı (1 commit, birleşmemiş) bu iş için duruyor.
5. **Ölçülmeyi bekleyen:** vitrinde puan tekrarı (GOREV'de "4.9 / 128 yorum dört vitrinde aynı" yazıyor). Canlı vitrin ve hızlı bakış yüzeylerinde puan **görünmedi**; hangi yüzeyde olduğu ölçülmedi.

---

## 3. Her adımın kabul ölçütü

| Adım | Bitti demek için |
|---|---|
| 0 | PR #519 ana dalda; canlıda bir ürün kartında özellik satırı görünüyor |
| 1 | 3 vitrinde en az 4'er ürün, her üründe en az 3 fotoğraf, kategoriye özel alanlar dolu |
| 2 | 182 ürünün **0**'ında boş özellik kalıyor (ölçüm betiği aynı tabloyu üretiyor) |
| 3 | 182 ürünün **0**'ı tek fotoğraflı (her üründe en az 3 fotoğraf) — canlıda **tamamlandı** (182/182) |
| 4 | Detay sayfasında özellik bölümü + birden çok fotoğraf |
| 5 | Puanın hangi yüzeyde olduğu yazılı (`page.tsx:573-577`); aynı puandan kurtulmuş — migration hazır, canlıya uygulanmayı bekliyor |

---

## 4. Karar bekleyen noktalar (Casper)

1. ~~**Fotoğraf kuralı:** 38 ürünün hepsi tek fotoğraflı.~~
   **KARAR (Casper, 2026-09-18): 38 ürünün hepsine fotoğraf eklenecek.** Yani "en az 3 fotoğraf" kuralı herkes için geçerli olacak; sıra 3. adım.
2. **İçerik girişi nasıl:** kuralın "elle SQL yok, formdan geçer". 32 ürün × alan girişi elde ciddi emek.
   Seçenekler: (a) esnaf formundan elle, (b) Vixrex Asistan ile toplu, (c) toplu yükleme (Excel/XML) — kodu hazır ama dalda bekliyor.
3. **`demo-*` vitrinler:** `demo-teknofix` canlı ve 8 ürünlü; diğer üçü boş. Bu üçü landing'de "kiralanabilir" gösterilecek mi, yoksa yalnız `kiralik-*` beşlisi mi kalacak?
4. **Eski fiyatlar:** kartlarda üstü çizili fiyat var (`-25%`, `-20%`, `-18%`). Formda yasal uyarı metni duruyor; vitrin içeriklerinde bu kural nasıl uygulanacak?

---

## 5. Bu ölçümü tekrar etmek (2026-09-25'te güncellendi)

Canlı durum tek komutla: `node tool/canli_durum.ts` (vitrin/ürün/foto/özellik sayıları)
Demo içerik ayrıntısı: `node .scratch/demo-icerik-olcum.cjs` (boş ürün, generic kategori, puan bandı, tekrar eden puan)


Ölçüm betiği projenin dışında, geçici klasörde duruyor (projeye dosya eklenmedi):

```
node C:/Users/Casper/Temp/vixrex-matris.cjs kiralik-teknik kiralik-kuafor kiralik-gida kiralik-kafe kiralik-butik demo-teknofix demo-lezzet-duragi demo-nova-kuafor demo-aymira-giyim
```

Çıktı: `C:/Users/Casper/Temp/vixrex-canli/matris.json` (her ürün için fotoğraf sayısı, özellik listesi, kategori, görünürlük).

Ekran görüntüleri: `C:/Users/Casper/Temp/vixrex-canli/*.png` (9 vitrin + hızlı bakış + detay sayfaları).

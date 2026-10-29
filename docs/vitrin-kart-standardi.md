# Vitrin ürün kartı standardı

Bu dosya kartın "kurumsal kalite" eşiğini yazar. Ölçümü `node tool/kart-kalite.js`
yapar; çıktı `standart altı` ise birleştirme öncesi engel sayılır.

## 1. Tek ürün = tek kart

Aynı ürün ikinci kez kart açmaz. Fatura satırı var olan ürüne bağlanırken
`ayniUrunMu` şu dördü birlikte arar:

- marka (Türkçe harf farkı katlanır: `SÜTAŞ` = `SUTAŞ`)
- ad gövdesi (parantezli ek ve miktar adı çıktıktan sonra; baştaki marka adı düşer)
- miktar (`1 kg` = `1000 g`, `1 L` = `1000 ml`)
- varyant imzası (seçenekler çakışmıyorsa ayrı kart kalır)

Miktar farklıysa (`250 ml` / `330 ml`) kart ayrı kalır: bunlar ayrı üründür.

Barkod okunmamış satırda ad yazımı vitrindeki karttan farklıysa aynı ürün olduğu
makinece kanıtlanamaz. Bu durumda kart **sessizce açılmaz**: satır "onay
bekliyor" olarak işaretlenir ve esnafa tek soru sorulur — `Aynı ürün, kartı
birleştir` ya da `Farklı ürün, ayrı kart aç`. Karar
`invoice_job_lines.merge_decision` alanında saklanır; cevap gelene kadar o satır
ne karta bağlanır ne de yeni kart açar. Tahminle birleştirme hiçbir koşulda
yapılmaz, iki dolu farklı barkod birleşmez.

## 2. Fotoğraf eşiği

Kart fotoğrafı, fatura akışında seçilirken şu sırayla aranır:

1. kısa kenarı en az 1200 px olan adaylar (kaynak: `shared/product_image_policy.json`)
2. hiçbiri geçmiyorsa en büyük aday; küçük adaylar listenin sonuna düşer

Kart kutusu telefondan 2 kat çözünürlükle çizildiği için 390 px genişlikte
326×408 px gerekir; altındaki görsel büyütülmüş ve bulanık görünür.

## 3. Kart görünümü

- görsel, marka, ad (en fazla 2 satır), tek özellik satırı, fiyat, birim fiyat, stok
- kategori **tek yerde**: özellik satırında; rozet yalnız indirim/esnaf rozeti
- fiyat, rozet ve buton dili `src/lib/vitrinGorunum.ts` + `src/lib/productCardPresentation.ts`'den gelir

## 4. Ölçüm

```
node tool/kart-kalite.js https://vixrex.com/v/<vitrin>
```

Saydığı bulgular: tekrar grubu, kutuya yetmeyen görsel, kategori tekrarı,
yatay taşma (bunlar hata), kesik metin (uyarı). Hata varsa çıkış kodu 1'dir.

Mevcut tekrarlar ve küçük fotoğraflar yalnız kural değişikliğiyle silinmez;
var olan kartları birleştirmek veri silme demektir, ayrı onay ister.

## 5. Var olan tekrar kartları birleştirme

Birleştirmeyi `public.tekrar_urunleri_birlestir(store_id, uygula)` yapar
(`supabase/migrations/20261029130000_tekrar_urun_kartlarini_birlestir.sql`).
İki aşamalıdır ve iki kez koşulabilir (ikinci koşu bulgu üretmez):

1. **Barkod aşaması:** barkodu aynı olan kartlar tek karta iner. GTIN aynıysa
   üründür aynı üründür; iki farklı GTIN asla birleşmez.
2. **Barkodsuz aşama:** barkodu boş kart, adı + markası + miktarı birebir aynı
   olan barkodlu karta bağlanır. Miktar boşsa bağlanmaz.

Kurallar:

- **Toplanan:** stok (boş + boş = boş), fotoğraf listesi (tutulan kartınki önde,
  en fazla 11), varyantlar, özellik satırı, barkod, kategori, satış sırası.
- **Tutulan kart:** barkodu olan; eşitse en eski kart. Satış fiyatı tutulan
  kartınkidir, ortalama alınmaz.
- **Kapanan kart silinmez:** `is_visible=false`, `is_active=false` olur ve
  `metadata.birlestirildi` alanında hedefini taşır; geri alınabilir.
- **Bağlar taşınır:** `invoice_job_lines.product_id` ve varsa alış fiyatı
  satırı tutulan karta geçer.
- **Farklı GTIN ayrı kalır:** iki kartın barkodu dolu ve farklıysa birleştirme
  reddedilir; bunlar ayrı üründür (farklı gramaj/ambalaj/çeşit).

2026-10-29 canlı ölçümü: `elf-market-test-3` vitrininde 12 kartın 3'ü kapandı
(Coca-Cola 330 ml, Popkek 60 g, Sütaş Ayran 300 ml). Kalan isim ikizleri
(Popkek 40 g / 60 g, iki farklı barkodlu Pınar Süzme Peynir, 1 L Pınar sütler)
ayrı GTIN taşıdığı için birleştirilmedi.

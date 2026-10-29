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

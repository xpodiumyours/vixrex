# Bulgular

Ölçüm sırasında çıkan on bir eksik. Her biri hangi halkada olduğu, kanıtı ve
hangi iş türüne girdiğiyle yazıldı. Hiçbiri henüz düzeltilmedi.

## 1. Detay sayfası var, kimse ulaşamıyor

Halka: public detay. Kart ürün adresini taşıyor ama tıklama iptal edilip hızlı
bakış açılıyor. Detaya yalnız ctrl ile tıklayarak, site haritasından veya
adresi elle yazarak ulaşılıyor. İş türü: karar sonrası değişiklik.

## 2. Ters gelişimin kanıtı commit mesajında duruyor

Halka: karar. 37a5d40 numaralı commit "ayrı bir ürün detay sayfası olmadığı
için kart artık tam listeyi gösterir" diyor; oysa detay rotası o sırada da
vardı. Karar, yanlış bir ölçüme dayanmış. İş türü: kayıt, düzeltme değil.

## 3. Ölü ikinci detay uygulaması

Halka: public detay. PublicProductDetailPage.tsx hiçbir yerden çağrılmıyor;
geri alınan çalışmadan kalmış. İş türü: hata (temizlik).

## 4. Kart alanlarını seçen fonksiyon üretimde kullanılmıyor

Halka: ürün kartı. buildProductQuickFacts yalnız testte çağrılıyor; hızlı bakış
bilerek tüm alanları veren fonksiyonu kullanıyor. Test yeşil ama kullanıcı o
davranışı hiç görmüyor. İş türü: hata.

## 5. Görsel kuralının kaynağı yok

Halka: doğrulama. lib/config/product_image_policy.g.dart kendini üretilmiş ilan
edip shared/product_image_policy.json kaynağını gösteriyor; o dosya da
üreticisi de depoda yok. Aynı beş sayı üç yerde elle duruyor. İş türü: hata.

## 6. Ölçü kuralı hiç çalışmıyor

Halka: doğrulama. Görsel ölçü doğrulaması hem web hem Flutter tarafında tanımlı
ama hiçbir yerden çağrılmıyor. İş türü: hata.

## 7. Web panelinde görünürlük anahtarı yok

Halka: görünürlük kapısı. API görünürlüğü kabul ediyor, Flutter paneli
değiştirebiliyor, web panelinde hiç geçmiyor. İki editör eşit değil.
İş türü: değişiklik.

## 8. Ürünü yayından kaldırma yolu yok

Halka: görünürlük kapısı. is_active hiçbir ekrandan değiştirilemiyor; yalnız
silme yolunda ve veritabanı yordamlarında yazılıyor. İş türü: değişiklik.

## 9. Kiralık vitrin tohumu kendi kuralını deliyor

Halka: doğrulama ve veri. Sunucu yalnız Vixrex yükleme kapısından geçmiş görsel
adresini kabul ediyor; kiralık vitrin tohumunda 45 dış adres var. Ürün ile
görselin uyuşup uyuşmadığını denetleyen hiçbir kod yok. İş türü: hata.

## 10. Sunucuda uzunluk sınırı yok

Halka: doğrulama. Ad 80, açıklama 500 sınırı yalnız ekranda; sunucu ve
veritabanı sınırsız kabul ediyor. İş türü: hata.

## 11. Arama motoruna yanlış marka çıkıyor

Halka: arama çıktısı. Ürünün markası yerine mağaza adı yazılıyor; ürünün kendi
marka ve stok kodu alanları hiç çıkmıyor. İş türü: hata.

## Ölçüp eledim

Kategori sayısında uyumsuzluk olduğu ileri sürüldü; saydım, kaynak dosyada da
üretilen dosyada da 19 kategori var ve kimlikler birebir aynı. Bulgu değil.

## Ölçmediklerim

Geri alınan çalışmanın neden geri alındığını **bilmiyorum**; commit mesajında
gerekçe yazılı değil. Detay sayfasının veriyi doğru çektiğini doğrulayan bir
test de yok.

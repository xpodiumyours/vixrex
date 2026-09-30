# VixRex — Ajanlar için proje talimatları

Fatura, firma keşfi, ürün eşleştirme, görsel, kart ve yayınlama işlerinde **[Faturadan Vitrine Master Plan](docs/FATURADAN-VITRINE-MASTER-PLAN.md)** esas alınır. Mevcut işleri bu plandaki eksiklerle eşleştir; ikinci bir plan veya paralel ürün akışı kurma. Fazları yalnız kod var diye tamamlandı sayma; gerçek kabul kanıtını kaydet. Kullanıcıdan bu hedefi yeniden tarif etmesini isteme.

## Faturadan dijital vitrine: değiştirilmeyecek ürün kapsamı

Bu bölüm, proje sahibinin 30 Eylül 2026 tarihinde açıkça belirttiği ürün hedefidir. Fatura, OCR, firma keşfi, katalog eşleştirme, ürün bilgisi, görsel ve ürün yayınlama çalışmalarında bu hedefi esas al. Kullanıcıya aynı kapsamı yeniden anlattırma. Eski planlar, mevcut firma listeleri veya uygulamadaki eksikler bu hedefi daraltmaz. Kullanıcının sonraki açık talimatı kapsamı güncelleyebilir.

### Kime, hangi anda yardımcı oluyoruz?

Küçük esnaf, toptancıdan veya üreticiden ürününü alıp ürün ve faturasıyla baş başa kaldığında VixRex devreye girer. Amaç, esnafın raftaki ürünlerini tek tek fotoğraflayıp açıklama yazarak yüklemesini gerektirmeden dijital ürün kartlarına ve tüketicinin görebileceği vitrine dönüştürmektir. VixRex, üretici ile küçük esnaf arasında dijital köprüdür.

### Gerçek kapsam ve eşleştirme sınırı

- Hedef, İstanbul toptancıları ve Türkiye üreticileridir. Kapsam tek bir marka, sektör veya önceden hazırlanmış firma listesi değildir.
- Gıda, tekstil, temizlik, ev tekstili ve tuhafiye dahil farklı ürün grupları kapsamdadır. Tutku yalnızca bir örnektir; bakkalın faturasındaki Eti ve Ülker ürünleri de aynı yaklaşımın içindedir.
- **16 firma ve 54 firmalık havuz, OpenRouter token maliyetini azaltmak için düşünülmüştür. Bunlar kapsam sınırı, izin verilen firmalar listesi veya yalnız bu firmalarla çalışma kararı değildir.** Havuz dışında olmak tek başına eleme gerekçesi olamaz.
- Belirleyici koşul, faturadaki firma ve ürün bilgilerinin firmanın resmî dijital kaynaklarındaki ürünlerle doğrulanabilir biçimde eşleşmesidir. Faturayı kesen toptancı ile ürünün üreticisi aynı firma olmak zorunda değildir; doğru ürün ve üretici ilişkisi çözülmelidir.
- Basılı veya el yazısı fatura olması tek başına kabul ya da ret nedeni değildir. Bilgiler okunabiliyor ve dijital karşılığı bulunabiliyorsa akışın konusudur.
- Sadece benzerlik nedeniyle başka ürünün görselini veya bilgisini kullanma. Eşleşmeyen ya da belirsiz ürünü eşleşmiş gibi sunma. Tekil bir eşleşme sorunu üzerinden bütün bir sektörü veya firmaları kapsamdan çıkarma.
- Sistem, her yeni firma veya faturada yorucu elle araştırma gerektirmeden bu köprüyü kurabilmelidir. Maliyet azaltma çalışmaları bu hedefi korumalıdır.

### Uçtan uca başarı ölçütü

1. Esnaf faturanın fotoğrafını verir.
2. Firma ve ürün bilgileri okunur; ilgili toptancı, üretici veya marka belirlenir.
3. Faturadaki ürünler, ilgili firmanın resmî dijital ürünleriyle eşleştirilir.
4. Eşleşen ürünlerin doğru bilgileri ve görselleri ürün kartlarına yerleştirilir.
5. Kartlar, tüketicinin görebileceği dijital vitrine kadar ulaşır; yayınlama ve görüntüleme zinciri gerçek akışta doğrulanır.

Sadece OCR çıktısı, firma bağlantısı, katalog arama sonucu veya görselsiz ara taslak bu hedefin tamamlandığı anlamına gelmez. Birkaç seçilmiş marka üzerinde çalışan örnek de genel kapsamın tamamlandığının kanıtı değildir. Kullanıcının “%100 çalışmalı” beklentisini kapsamı küçülterek karşılama; zincirin tamamını çalıştır ve doğrulanmamış noktaları açıkça belirt.

### Çalışan sistem ve firma izin görüşmeleri

Kullanıcının sıralaması: **önce görseller ve tüketiciye gösterilebilen ürün kartları dahil çalışan sistemi somut olarak ispatlamak, ardından bu çalışan sistemle firmalarla kullanım izni görüşmesi yapmak.** İzin görüşmesini teknik geliştirmeyi sürekli durduran veya kapsamı daraltan bir önkoşula dönüştürme. İzin süreci hedefin bir parçasıdır; yok sayılacak bir konu değildir.

Firmalara sunulacak değer: “Ürünlerinizi satan küçük esnafla dijital köprünüz olalım; esnafın rafındaki ürünlerinizi dijital vitrinde kataloğa dönüştürelim.” Amaç, henüz çalışmayan bir fikre izin istemek değil, işleyen akışı gösterebilmektir.

Bu ürün hedefi, firmalardan izin alınmış olduğu veya sistemin bugün tamamlandığı anlamına gelmez. Teknik kabiliyet, doğrulanmış uçtan uca sonuç, canlı yayın ve alınmış firma iznini raporlarken ayrı ayrı belirt. Bu belge tek başına firma adına iletişim kurma, canlıya dağıtım veya dış ayar değişikliği için işlem yetkisi vermez; ilgili işin kullanıcı talimatını esas al.

### Ajanların çalışma biçimi

- Bu hedefi yeniden tartışmaya açmak yerine mevcut eksikleri hedefe göre belirle.
- Tutku'ya, sabit firma havuzlarına veya izin konusuna takılıp büyük hedefi daraltma.
- Mevcut çalışan davranışı ve kullanıcı verilerini koru; yalnız istenen iş kapsamında değişiklik yap.
- Hedefi, uygulanmış özelliği ve doğrulanmış sonucu birbirine karıştırma. Çalıştırmadığın testi veya görmediğin canlı sonucu tamamlandı diye raporlama.

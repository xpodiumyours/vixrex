from pathlib import Path
import json
p=Path('public_web/src/data/blogYazilari.ts')
s=p.read_text(encoding='utf-8')
def article(slug,baslik,ozet,soru,kategori,sektorler,govde,ilgili):
 return dict(slug=slug,baslik=baslik,ozet=ozet,govde=govde,cozduguSoru=soru,kategori=kategori,icerikTuru='rehber',sektorler=sektorler,yazar=dict(ad='Vixrex',tur='kurum',url='/hakkimizda'),inceleyen=None,kaynaklar=[],urunDogrulamaOrtami=None,kapak=None,kapakAlt=None,gorselKaynagi=None,gorselKullanimHakki=None,yayinTarihi=None,guncellemeTarihi=None,sonKontrolTarihi='2026-09-11',guncellemeNotlari=[],durum='taslak',kontrolSinifi='genel',ilgiliYazilar=ilgili,asistanKullaniminaUygun=False,yayinda=False)
items=[article('dijital-vitrin-hazirlik-listesi','İlk dijital vitrinin: yayın öncesi hazırlık listesi','İşletme bilgilerini, hizmetlerini ve fotoğraflarını bir araya getir. Sayfanı paylaşmadan önce müşterinin gözüyle kontrol et.','İlk dijital vitrinimi hazırlarken hangi bilgileri toplamalı ve yayın öncesinde neleri denemeliyim?','Dijital Vitrin',[],'''Dijital vitrin hazırlamaya boş bir sayfadan başlamak zorunda değilsin. Önce müşterinin seni tanıması, sunduğun hizmeti anlaması ve sana ulaşması için gereken bilgileri topla. Bu rehber, sayfanı hangi araçla hazırlarsan hazırla kullanabileceğin bir başlangıç listesidir.

## İşletmeni bir cümlede anlat

İşletmenin gerçek adını, ne yaptığını ve hizmet verdiğin bölgeyi yaz. “En iyi kalite, benzersiz hizmet” gibi genel ifadeler yerine müşterinin anlayabileceği somut bir açıklama seç.

Örnek bir tanıtım kalıbı: “[İşletme adı], [bölge] içinde [temel hizmetler] sunar.” Bir terzi için bunu “Kadıköy’de paça kısaltma, fermuar değişimi ve kıyafet tadilatı” biçiminde doldurabilirsin. Bu bir yazım örneğidir; gerçek bir işletme referansı değildir.

## Bilgileri tek yerde topla

Sayfayı düzenlemeye geçmeden aşağıdaki listeyi hazırla:

- Tabelanda veya müşterilerle iletişimde kullandığın işletme adı
- Hizmet verdiğin açık adres ya da bölge
- İşletme telefonu ve kullandığın iletişim kanalı
- Haftalık çalışma saatlerin ve kapalı günlerin
- Gerçekten sunduğun ürün veya hizmetler
- Varsa güncel fiyat, süre ve seçenek bilgileri

Başka platformlardaki işletme bilgilerini de karşılaştır. Eski bir telefonun veya farklı bir çalışma saatinin müşteriye ulaşmasını önlemek için değişen bilgileri aynı gün düzelt.

## Her hizmeti ayrı ve anlaşılır yaz

Uzun bir tanıtım paragrafının içine bütün hizmetleri sıkıştırma. Her hizmet için ad, kısa kapsam ve gerekiyorsa süre veya fiyat bilgisi hazırla. “Bakım” yerine “Sakal kesimi ve şekillendirme” gibi somut bir ad kullan.

Fiyat değişkense hangi seçeneğe göre değiştiğini açıkla. Kapsama dahil olmayan işi dahilmiş gibi gösterme. Bilmediğin bir tutarı örnek fiyat olarak yayına bırakma.

## Görselleri bir amaçla seç

İlk görsel işletmenin ne yaptığını anlatmalı. Devamında mekânı, ürünleri veya çalışmalarını gösteren net fotoğraflar kullan. Aynı açıdan çekilmiş çok sayıda fotoğraf yerine her biri farklı bilgi veren bir seçki hazırla.

Fotoğrafları telefonda küçük boyutta da kontrol et. Kesilmiş ürün, okunmayan tabela veya karanlık bir kadraj varsa başka bir görsel seç. Sana ait olmayan bir çalışmayı kendi işin gibi sunma.

## Bir müşterinin izleyeceği yolu dene

Sayfanı yalnız düzenleme ekranından kontrol etme. Müşteriye göndereceğin bağlantıyı ayrı bir tarayıcıda aç ve şu işlemleri sırayla dene:

1. İşletmenin ne yaptığını ve nerede olduğunu bul.
2. Bir hizmetin kapsamını ve varsa fiyatını oku.
3. Telefon veya mesaj bağlantısının doğru işletmeye gittiğini kontrol et.
4. Adresi ve varsa harita hedefini karşılaştır.
5. Sayfayı dar bir telefon ekranında incele; yazılar kesiliyor mu bak.
6. Paylaşacağın bağlantının giriş istemeden açıldığını doğrula.

Bir yakınının da aynı adımları açıklama yapmadan denemesini isteyebilirsin. Sorduğu sorular, sayfada eksik kalan bilgileri görmene yardımcı olabilir.

## Paylaştıktan sonra güncel tut

Vitrin bir kez hazırlanıp unutulacak bir afiş değildir. Telefon, çalışma saati, hizmet veya fiyat değiştiğinde sayfayı da güncelle. Kendine bu bilgileri yeniden kontrol edeceğin bir tarih belirle; özellikle tatil ve geçici kapanışlardan önce sayfayı gözden geçir.''',['kuafor-icin-internet-sitesi','musteri-mesajlari-icin-yanit-ornekleri']),
article('musteri-mesajlari-icin-yanit-ornekleri','Müşteri mesajlarına açık yanıtlar: 5 örnek','Fiyat, çalışma saati, konum ve randevu soruları için işletmene uyarlayabileceğin kısa yanıt örnekleri.','Müşterinin sorusuna eksik bilgi vermeden, kısa ve anlaşılır nasıl cevap verebilirim?','Müşteri İletişimi',[],'''Müşteriye yanıt verirken uzun bir tanıtım metni göndermek yerine önce sorusunu cevapla. Ardından gerekiyorsa bir sonraki adımı söyle. Aşağıdaki metinler örnektir; köşeli parantez içindeki alanları kendi doğruladığın bilgilerinle değiştir.

## Fiyat sorulduğunda

“Merhaba, [hizmet adı] için güncel ücretimiz [tutar]. Bu hizmete [kapsam] dahil. [Seçenek] istiyorsan fiyatı ayrıca netleştirebiliriz.”

Tek bir fiyat veremiyorsan bunun nedenini söyle: “Tutar, [ölçü/adet/işlem] bilgisine göre değişiyor. Bunları paylaşırsan kapsamı ve toplam tutarı sana yazalım.” Müşterinin hangi bilginin eksik olduğunu anlamasını sağla; yalnız “özelden bilgi” gibi belirsiz bir cevapla bırakma.

## Çalışma saati sorulduğunda

“Bugün [açılış]–[kapanış] arasında açığız. [Varsa mola veya özel durum]. [Gün] günü kapalıyız.”

Müşteri “Bugün açık mısınız?” diyorsa bütün haftanın saatleri yerine o günü cevapla. Tatil veya geçici kapanış varsa normal saatleri kopyalamadan önce kontrol et. Vitrindeki saat farklıysa onu da güncelle.

## Konum istendiğinde

“Adresimiz: [açık adres]. [Varsa kısa tarif]. Konum bağlantımız: [kontrol edilmiş bağlantı].”

Tarifi yalnız yerel bir lakaba veya herkesin bilmediği bir binaya bağlama. Harita bağlantısını göndermeden açıp doğru noktaya gittiğini kontrol et. Bina girişi farklı bir sokaktaysa bunu ayrıca belirt.

## Randevu talebi geldiğinde

“[Hizmet] için [tarih] günü [saat] uygun. Bu saati senin için ayıralım mı?”

Bu mesaj bir teklif metnidir. Müşteri kabul ettikten ve sen kayıtlarını kontrol ettikten sonra ayrı bir onay gönder: “Randevun onaylandı: [tarih], [saat], [hizmet]. Adresimiz [adres]. Değişiklik gerekirse bu numaradan bize yazabilirsin.”

Tarih, saat veya hizmet belli değilken “Tamamdır” demek yerine eksik bilgiyi sor. Bu örnek herhangi bir otomatik randevu özelliği vaat etmez; kullandığın kayıt yöntemiyle birlikte uygulanacak bir iletişim düzenidir.

## Hemen cevap veremediğinde

“Mesajını aldık. [Gerçekçi yanıt zamanı] içinde dönüş yapacağız. Bu sırada hizmet ve adres bilgilerine [vitrin bağlantısı] üzerinden bakabilirsin.”

Tutamayacağın bir yanıt süresi verme. Bir otomatik mesaj kullanıyorsan yanıt zamanını çalışma düzenin değiştiğinde güncelle. Mesajın alınmış olmasıyla talebin onaylanmış olmasını birbirinden ayır.

## Göndermeden önce kontrol et

1. Müşterinin sorduğu asıl soruyu cevapladın mı?
2. Örnekteki bütün parantezleri gerçek bilgilerle değiştirdin mi?
3. Tarih, saat, tutar ve bağlantılar doğru mu?
4. Müşterinin şimdi ne yapması gerektiği anlaşılıyor mu?

Sık sorulan bir bilgi her konuşmada tekrar eksik kalıyorsa o bilgiyi vitrinin ilgili bölümüne de ekle. Böylece mesaj ile sayfadaki bilgi birbiriyle tutarlı kalır.''',['dijital-vitrin-hazirlik-listesi','kuafor-icin-internet-sitesi']),
article('kafe-dijital-menu-hazirlama','Kafe menüsünü telefonda okunur hâle getir','Kategori adlarından ürün açıklamalarına kadar, dijital menünü müşterinin kolayca okuyabileceği şekilde hazırlamak için bir rehber.','Kafemin dijital menüsünü telefonda anlaşılır ve güncel tutmak için nasıl düzenlemeliyim?','Dijital Vitrin',['kafe','restoran'],'''Basılı menünün fotoğrafını çekmek bir başlangıç olabilir; ancak küçük yazıları telefonda okumak için büyütmek gerekebilir. Dijital menünü hazırlarken bilgileri ürünler ve kategoriler halinde düzenlemeyi dene. Buradaki öneriler bir menü yazma ve kontrol yöntemi sunar.

## Kategorileri müşterinin kelimeleriyle adlandır

“Sıcak içecekler”, “Soğuk içecekler”, “Kahvaltı” ve “Tatlılar” gibi içerdiği ürünleri açıklayan başlıklar kullan. İşletmende bulunmayan bir grubu sırf menü dolu görünsün diye ekleme.

Bir ürünün nereye ait olduğu belirsizse müşterinin onu ilk nerede arayacağını düşün. Aynı ürünü farklı kategorilerde tekrar yazıyorsan fiyat ve açıklamaların birbirinden kopmamasına dikkat et.

## Her üründe aynı bilgi sırasını kullan

Bir ürün için ad, kısa açıklama, seçenek ve fiyat bilgisini sırayla hazırla. Kendi ürün bilgilerinle doldurabileceğin bir örnek:

- Ad: [Ürün adı]
- Açıklama: [Temel içerik veya hazırlanış]
- Seçenek: [Boy/porsiyon gibi gerçekten sunulan seçenekler]
- Fiyat: [O seçenek için güncel tutar]

İsimden anlaşılmayan bir üründe kısa açıklama özellikle yararlı olabilir. “Özel karışım” demek yerine doğrulayabildiğin temel içeriği belirt. İçeriğinden emin olmadığın ürüne özellik yakıştırma.

## Seçenekleri fiyatla birlikte kontrol et

Aynı içeceğin farklı boyları varsa hangi fiyatın hangi boya ait olduğunu yaz. Ekstra bir seçeneği sunuyorsan ücretinin dahil olup olmadığını açıkla. Sayfadaki bilgiyi işletmede müşteriye sunduğun menüyle karşılaştır.

Bu kontrolü yalnız ilk yayında yapma. Ürün veya fiyat değiştiğinde kullanılan bütün menü yüzeylerini gözden geçir; masadaki basılı menüyle telefondaki menü farklı kalmasın.

## Fotoğraf sayısını değil açıklığını önemse

Her ürüne bir görsel eklemek zorunda değilsin. Eklediğin fotoğraf gerçekten sunduğun ürünü ve porsiyonu temsil etsin. Başka bir ürünün veya işletmenin fotoğrafını kendi sunumun gibi kullanma.

Birden fazla ürün fotoğrafında benzer ışık ve kadraj tercih ederek menü boyunca tutarlı bir görünüm oluşturabilirsin. Koyu veya bulanık bir görsel yerine iyi yazılmış ürün bilgisiyle devam etmek daha anlaşılır olabilir.

## Masadan telefona geçişi dene

Menü bağlantısını veya QR kodunu müşterinin kullanacağı koşullarda kontrol et:

1. Bağlantı doğru menüyü açıyor mu?
2. Telefon ekranında ürün adı ve fiyat birlikte okunuyor mu?
3. Kategoriler arasında geçiş kolay mı?
4. Güncel olmayan ürün veya boş kategori var mı?
5. QR basılıysa baskı boyutunda ve gerçek masa ışığında taranabiliyor mu?

Bir ürün geçici olarak yoksa menüyü buna göre düzenle. Güncelliği koruyamayacağın çok uzun bir liste yerine gerçekten sunabildiğin ürünleri açık biçimde göster.''',['dijital-vitrin-hazirlik-listesi','urun-fotografi-cekme-rehberi']),
article('urun-fotografi-cekme-rehberi','Telefonla ürün fotoğrafı: sade bir çekim planı','Işık, arka plan ve kadraj için uygulanabilir bir hazırlık listesi. Vitrininde ürünü doğru anlatan bir fotoğraf seçkisi oluştur.','Telefonla çektiğim ürün fotoğraflarını vitrinde kullanmak için nasıl hazırlamalı ve seçmeliyim?','Dijital Vitrin',['perakende','kafe','el işi'],'''Bu rehber, telefonla çekim için uygulayabileceğin bir çalışma planıdır. Amaç ürünü olduğundan farklı göstermek değil; müşterinin biçimini, ayrıntılarını ve sunumunu anlayabileceği fotoğraflar hazırlamaktır.

## Çekmeden önce ürünü ve alanı hazırla

Ürünü temizle, pakette istemediğin etiket veya kişisel bilgi olup olmadığını kontrol et. Arka planda dikkat dağıtan eşyaları kaldır. Ürünle benzer renkte bir zemin seçtiysen sınırlarının hâlâ belirgin olup olmadığına bak.

Birden fazla ürün çekeceksen aynı köşeyi ve zemini kullanmayı deneyebilirsin. Böylece her üründe çekim düzenini yeniden kurmak zorunda kalmazsın.

## Işığı küçük bir denemeyle seç

Pencereye yakın bir yerde deneme çekimi yap. Sert gölgeler veya parlak yüzeyde yansıma varsa ürünün ve telefonun açısını değiştir. Farklı ışık kaynaklarını birlikte kullanınca renkler farklı görünüyorsa tek bir ışık düzeniyle yeniden dene.

Çektiğin fotoğrafı gerçek ürünün yanında karşılaştır. Renkler belirgin biçimde değişmişse filtre ekleyerek düzeltmeye çalışmadan önce ışığı ve telefon ayarını gözden geçir.

## Üç farklı soruya cevap veren kareler çek

Aynı açıdan çok sayıda fotoğraf yerine şu üç amacı dene:

1. Genel görünüm: Ürünün bütünü ve şekli anlaşılır mı?
2. Ayrıntı: Malzeme, doku veya önemli bir parça görülebiliyor mu?
3. Kullanım veya sunum: Ürün müşteriye hangi şekilde teslim ediliyor?

Bir sunum fotoğrafında ürüne dahil olmayan aksesuarlar varsa açıklamada bunu belirt. Fotoğraf ürünün boyutunu tek başına anlatamıyorsa ölçü bilgisini ürün açıklamasına ekle.

## Kadrajda biraz boşluk bırak

Ürünü çerçevenin kenarına çok yaklaştırmadan çek. Vitrindeki kart fotoğrafı kırpıyorsa bu boşluk farklı ekranlarda işe yarayabilir. Yatay ve dikey birkaç deneme alıp kendi sayfandaki görünümü karşılaştır.

Önemli bilgiyi yalnız fotoğrafın üzerine yazma. Ürün adı, seçenek ve fiyatın sayfanın metninde de bulunmasını sağla; fotoğraf küçüldüğünde üzerindeki yazı okunmayabilir.

## Yükledikten sonra tekrar bak

Fotoğrafı telefondaki galeri uygulamasında beğenmiş olman, sayfadaki kırpmanın doğru olduğu anlamına gelmez. Yayın önizlemesinde şu kontrolleri yap:

- Ürünün önemli bir bölümü kesiliyor mu?
- Görsel bulanık veya gereğinden karanlık mı?
- Mobilde ve masaüstünde aynı ürün anlaşılabiliyor mu?
- Ürün adı, açıklama ve fotoğraf birbiriyle uyuşuyor mu?

İlk fotoğrafı ürünün genel görünümü için, diğerlerini ayrıntı için seç. Aynı bilgiyi tekrar eden kareleri çıkar ve üründe değişiklik olduğunda eski fotoğrafı güncelle.''',['kafe-dijital-menu-hazirlama','dijital-vitrin-hazirlik-listesi'])]
pos=s.index('export const BLOG_YAZILARI: BlogYazisi[] = [')+len('export const BLOG_YAZILARI: BlogYazisi[] = [')
s=s[:pos]+'\n'+',\n'.join(json.dumps(item,ensure_ascii=False,indent=2) for item in items)+','+s[pos:]
s=s.replace("Vixrex'in mevcut alan şemasında işletme adı, kategori, işletme türü, kısa tanıtım, WhatsApp, telefon, açık adres, il, ilçe ve çalışma saatleri ayrı alanlar olarak tutulur.","İşletme adı, kısa tanıtım, iletişim bilgileri, açık adres ve çalışma saatleri sayfada kolayca bulunabilmelidir.")
s=s.replace('    kontrolSinifi: "vixrex_urun",','    kontrolSinifi: "genel",')
s=s.replace('"kuafor-icin-internet-sitesi"],','"kuafor-icin-internet-sitesi", "dijital-vitrin-hazirlik-listesi"],')
p.write_text(s,encoding='utf-8')

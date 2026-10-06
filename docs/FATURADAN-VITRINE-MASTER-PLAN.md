# Faturadan dijital vitrine — Master plan

> Tarihsel kayıt. Güncel iş listesi değildir. Telefon ekranı okuma ucuna bağlıdır. Yayın kapısının çalışan tanımı `supabase/migrations/20261006180000_fatura_kart_katmanlari.sql` dosyasındadır.

Tarih: 30 Eylül 2026

Durum: Uygulama ve kabul planı. Planın yazılması, sistemin tamamlandığı anlamına gelmez.

> **2026-10-03 notu:** Bu belge tarihli bir plandır; hangi işin bittiği
> GitHub Issues ve commit geçmişinde izlenir. Buradaki durum satırları
> 30 Eylül itibarıyla geçerlidir.

## 1. Teslim edilecek sonuç

Küçük esnaf, aldığı ürünlerle ve faturasıyla baş başa kaldığında VixRex devreye girer. Esnaf **tek bir okunabilir fatura fotoğrafı** verir. Sistem firmayı ve ürünleri çözer; resmî dijital kaynakta karşılığı bulunan ürünlerin doğru bilgilerini ve gerçek görsellerini mevcut VixRex ürün kartlarına taşır. Esnaf satış fiyatını ve mevcut stoğunu kontrol eder. Ürünler, tüketicinin kullanabileceği kalitede dijital vitrinde gösterilir.

Firma görüşmesine götürülecek teslimat; gerçek sağlayıcıları kullanan, kalıcı ürün kaydı oluşturan, gerçek kart ve vitrin bileşenlerinde çalışan bir akıştır. Sabit örnek ekran, elle doldurulmuş katalog kartı, sahte servis cevabı veya sadece OCR metni bu teslimatın yerine geçmez.

Firmaya söylenmek istenen söz:

> “Ürünlerinizi satan küçük esnafın bir fatura fotoğrafından, doğru ürün bilgileri ve görselleriyle dijital vitrin hazırlayabiliyoruz. Çalışan sistemimiz bu. Veri ve görsel kullanım izninizle bu köprüyü küçük esnaflarınızın kullanımına açalım; raftaki ürünlerinizi tüketiciyle buluşturalım.”

**“Yalnız sizin veri ve görsel kullanım izniniz kaldı” ancak o firmanın gerçek ürünlerinde teknik akış tamamlanmışsa söylenir.** Bulunamamış ürün görseli, eksik katalog erişimi, bağlanmamış yayın düğmesi veya doğrulanmamış veri kaydı izin meselesinin arkasına saklanmaz.

## 2. Kapsam sabittir

- Hedef: İstanbul toptancıları ve Türkiye üreticileri; bunlardan ürün alan küçük esnaf.
- Gıda, tekstil, temizlik, ev tekstili ve tuhafiye dahil farklı sektörler kapsamdadır. Tutku, Eti, Ülker ve Işılay örnektir; izin verilen markalar listesi değildir.
- 16 katalog ve geçmişte 54 olarak anılan firma havuzu maliyet ve hız içindir. İncelenen yerel kopyada 55 firma kaydı olması da kapsam kararı değildir. Yeni firma keşfi ana işin içindedir.
- Sınır: faturadaki ürünün ve firma ilişkisinin resmî dijital kaynakla doğrulanabilir eşleşmesi. Basılı veya el yazısı olması tek başına eleme nedeni değildir.
- Toptancı ile üretici aynı olmak zorunda değildir. Çok markalı bir toptancı faturası normal bir senaryodur.
- Tek fotoğraf ana giriş yoludur. İkinci belge veya ambalaj fotoğrafı destekleyici olabilir; her esnafa zorunlu ek fotoğraf görevi verilmez.
- Bulunamayan bilgi uydurulmaz. Tek satırdaki eksik nedeniyle diğer doğrulanmış ürünler kaybolmaz; eksik satır gerekçesiyle korunur.
- Mevcut ürünler, kullanıcı verileri, Flutter ve Next.js'in çalışan davranışları korunur. Yeni bir paralel katalog/kart uygulaması kurulmaz.

## 3. Başlangıç durumu: yapılan iş ile doğrulanmış sonuç ayrımı

Bu tablo 30 Eylül yerel Git geçmişi ve çalışma dosyaları incelemesidir. Aktif çalışmalar sürdüğünden uygulamaya başlamadan önce yeniden kontrol edilir. Canlı servis, veritabanı veya dağıtım doğrulaması değildir.

| Mevcut çalışma | Kanıt | Nasıl devam edilecek? |
| --- | --- | --- |
| Ortak fatura okuyucu ve ürün zinciri | `8ef16500`; `faturaGoru.ts`, `/api/fatura-oku` | Aynı okuyucu korunacak; belge ve tutar ayrımları tamamlanacak. |
| Dinamik ürün izi ve dört sonuç | `40757ea9`, `eb942930` | Kaynak erişimi, firma doğrulaması ve marka ayrımı tamamlanacak. |
| Kalıcı fatura ve kanıt kaydı | `5d746b8c` | Kaydın ürünle bağlantısı, geri açılması ve tekrar işlem güvenliği tamamlanacak. |
| Eşleşmeden kart taslağı | `69e467af` | Gerçek `products` kaydı ve kart kalitesiyle birleştirilecek. |
| Web/telefon durumları ve stok onayı | `7fbce286` | Onay döngüsü ve telefonun eksik ekran bağlantıları tamamlanacak. |
| Ayrı yayın ucu, yayın RPC'si, yeni testler | Çalışma ağacındaki devam eden, henüz commit edilmemiş geliştirmeler | Eksik diye yeniden yazılmayacak; mevcut uygulama tamamlanıp doğrulanacak. |

İncelemede ilgili son commit `preview/faturadan-urun-karti-p1` dalındaydı; yerelde görünen `origin/main` kaydına dahil değildi. Kök çalışma klasörü `faturadankataloga` dalında, farklı bir taban üzerinde çok sayıda devam eden değişiklik içeriyordu. Dosya bulunması, commit edilmesi, testin geçmesi ve canlıda çalışması ayrı kanıtlardır.

Önceki tamamlanma ve durum notları `.fatura-kurtarma/eski-notlar/` altında korunur; uygulamayı durduran talimat veya güncel kabul kanıtı olarak kullanılmaz. “Harici firma araması ayrı iş” gibi hedefi daraltan eski notlar bu planın kapsamını değiştirmez. API anahtarı veya veritabanı için eski “eksik” notu güncel ortam kontrolünün yerine geçmez.

### 1 Ekim: aynı çalışma üzerinde tamamlama

Mevcut `integration/fatura-birlestirme` çalışmasında kaynak eşleştirme, kayıt, telefon ekranları ve yayın parçaları birleştirilmiştir. Yeni ürün akışı kurulmamıştır. Bulut oturumunun okunabilen değişiklik kayıtları kurtarma alanında korunmuştur; erişilemeyen son dosyaların bütünü kurtarılmış sayılmaz.

| Plan işi | Uygulanan tamamlayıcı parça | Kabul sınırı |
| --- | --- | --- |
| F1–F2 | Gerçek barkod ayrımı, açık kart/stok onayı ve kayıtlı esnaf seçimleri | Gerçek belgedeki okuma ve alışveriş eşliği ayrıca gösterilmelidir. |
| F3–F4 | Üretici kimliğiyle eşleştirme, resmî bağlı PDF/sosyal katalog okuma, kalıcı görsel ve kaldığı yerden arama | Erişilemeyen katalog veya belirsiz ürün kesin eşleşme sayılmaz. PDF'nin tamamı taranmadan sonuç kesinleştirilmez. |
| F5 | İlk işlem, satır/kanıt ve ürün bağlantısı atomik kaydedilir; tekrar aynı kaydı döndürür | `supabase/tests/invoice_atomic_smoke.sql` ayrı yerel veritabanında çalıştırılmıştır; canlı kurulum kanıtı değildir. |
| F6 | Web/telefon geçmişi, taslağa dönüş, güvenli çıkış, sunucuda düzeltme ve ayrı yayın | Ekran ve servis kontrolleri gerçek sağlayıcıyla fatura kabulünün yerine geçmez. |
| F7 | Çok üreticili faturada ayrı izin hedefleri, mevcut talebe yeni kart bağlantısı ve güncel ret kontrolü | Firma adına gönderim veya izin alınması yapılmış sayılmaz. |
| F8 | Gerçek belge kabulü açık | `14544.jpg`, `14545.jpg`, `14550.jpg` bu çalışma dosyalarında bulunamamıştır; Işılay 16747 ve sektörler arası gerçek kabul tamamlanmış sayılmaz. |

Güncel sekiz fatura değişikliği `supabase/migrations/` altındaki `20260929000000`–`20261001000000` numaralı migrasyonlardır; şemanın tek kaynağı budur. Mevcut ürün çekirdeği ve alış fiyatı tablosu önkoşuldur. Migrasyonların hazırlanması canlıya uygulanmış olduğu anlamına gelmez.

`faturadankataloga` dalı yeniden kod üzerinden karşılaştırılmıştır: ayrışık 15 yönetim kaydının içeriği ana dalda zaten vardır; üç fatura kaydının temeli mevcut birleşimde korunur. Eksik kalan metin desteği ve yalnız taslak filtresi, eski izin sistemini çoğaltmadan mevcut kayıt zincirine bağlanmıştır. Aynı modelin farklı satırları artık tek kalıcı karta ve ayrı beden/renk seçeneklerine bağlanır. Kayıt tekrarı stok eklemez; düzeltme miktarı değiştirir. Assorti toplamı bedenlere dağıtılmaz. Bu davranışlar `supabase/tests/invoice_variant_group_smoke.sql` ile ayrı yerel veritabanında doğrulanmıştır.

Ürün yönetimi içerik sütunundan ayrı pencereye alınmıştır; fatura ve geri açma aynı ürün yöneticisinde kalır. Bu yerleşim düzeltmesi Flutter görünümünün tümüyle eşitlendiği anlamına gelmez. Gerçek belge kabulü ve canlı aktarım açık kalır.

## 4. Esnafın yaşayacağı tek akış

1. **Faturayı yükle:** Fotoğraf alınır; işlem kaydı oluşturulur. Aynı alışveriş tekrar eklenmez.
2. **Ürünlerini hazırlıyoruz:** Firma, marka, kod/barkod, miktar ve alış bilgisi çözülür; doğru resmî kaynak ve görseller bulunur. İşlem kesilirse kaybolmaz.
3. **Hazırlanan kartları gör:** Gerçek ürün görseli, ürün adı, açıklama, marka, bilinen beden/renk bilgileri görünür. Kaynak ve eşleşme açıklaması esnaf panelinde incelenebilir. Tüketiciye teknik kanıt alanları gösterilmez.
4. **Yalnız sana ait bilgileri tamamla:** Satış fiyatı ve mevcut stok kontrol edilir. Belgede olmayan beden dağılımı gibi gerekli bir bilgi için kısa, somut soru sorulur. Ürün açıklaması, görsel araması ve firma araştırması esnafa geri yüklenmez.
5. **Kartı kaydet ve vitrinde göster:** Kart mevcut ürün sistemine yazılır. Taslak kaydetme ile yayınlama ayrı eylemdir; düğmeler birbirini kilitlemez. Kaydedilen taslak ürün yönetiminden yeniden açılabilir.
6. **Firma iznini yönet:** Çalışan görselli örneğin yanında “Veri ve görsel kullanım iznini sen mi isteyeceksin, biz senin için isteyelim mi?” seçimi sunulur. Talep ve firma cevabı takip edilir.

Ürün hazırlama durumu, firma izni durumu ve yayın durumu ayrı anlam taşır. İzin henüz sorulmadı diye keşif, görsel seçimi, kalıcı kart hazırlığı ve tüketiciyle aynı kart görünümünün doğrulanması durmaz. Esnafın “biz isteyelim” seçimi firma izni alınmış sayılmaz. Gösterim gerçek ürün kaydını ve mevcut vitrin bileşenlerini kullanır; ayrı bir maket hazırlanmaz.

## 5. Tamamlama işleri ve bağımlılıkları

### F0 — Devam eden işleri tek uygulama tabanında toplama

**İş:** İlgili dallar, commitler, henüz commit edilmemiş dosyalar ve bunların sahipleri belirlenir. Aynı dosyayı eşzamanlı değiştiren işler çakıştırılmaz. Mevcut emeği koruyan uygun çalışma dalı/kopyası seçilir. Çalışma kopyası, migration sürümleri ve test kanıtı aynı sürüme bağlanır. Bu sırada ilgisiz temizlik veya refaktör yapılmaz.

**Çıktı:** Hangi geliştirmelerin gerçekten bu sürümde olduğunu gösteren tek envanter ve uygulanacak dosya listesi.

**Bitiş:** Sonraki fazların hangi sürüm üzerinde çalıştığı belli; hiçbir devam eden değişiklik kaybolmamış. Eski notlardan hareketle bitmiş iş yeniden yapılmıyor.

### F1 — Onay, görsel ve yayın kurallarını tutarlı hâle getirme

**İşler:**

- “Kartı onayla” düğmesinin açılmak için önceden kart onayı beklemesi düzeltilir. Bilgi yeterliliği, esnaf onayı ve yayına hazırlık ayrı değerlendirilir.
- Toplu onay da tekil onayla aynı kurala bağlanır; gönderilen stok onayı gerçek kullanıcı seçimini taşır. İstek içine koşulsuz `true` yazılmaz.
- Ürün eşleşmesi doğrulanmış ama firma izni henüz sonuçlanmamış kartın görseli hazırlık/gösterim sırasında boşaltılmaz. Kaynak ve izin durumu kartla korunur.
- **Bu planın uygulama kararı:** Doğrulanmış fatura ürününde en az bir doğru, kullanılabilir gerçek ürün görseli kartı hazırlamak ve görselli akışı kanıtlamak için yeterlidir. Aynı görsel üç kez çoğaltılarak sayı tamamlanmaz. Faturaya özel yayın koşulu web, telefon ve veritabanında tutarlı uygulanır; diğer ürün girişlerinin mevcut üç görsel kuralı kendiliğinden değiştirilmez.
- İzin henüz sorulmadı, cevap bekleniyor, izin verildi ve açıkça reddedildi durumları birbirine çevrilmez. “Kayıt yok” otomatik olarak “firma reddetti” değildir.

**Bitiş:** Tek bir doğru ürün görseli olan kanıtlı satır, tekil onayla gerçek kart taslağına dönüşebilir. İzin takibi kaybolmaz; hiçbir katman diğerinin hazırladığı kartı açıklamasız boşaltmaz.

### F2 — Faturayı ürün kimliğine ve tek alışverişe bağlama

**İşler:**

- Ham satır, satıcı/tedarikçi kimliği, satırdaki marka, model, gerçek barkod, adet, birim ve alış tutarı korunur. Model kodu barkod alanına sırf boş kalmasın diye yazılmaz.
- Mal bedeli, KDV, indirim ve ödenecek toplam ayrılır. Belgenin toplamı yanlış okunmuşsa üç defa aynı hatayı tekrarlamak yerine belirsiz alan açıklanır; doğru satırlar korunur.
- Belge türü, mevcutsa belge numarası ve tarih gibi bilgiler aynı alışverişin farklı fotoğraflarını ilişkilendirmede kullanılır. Dosya özeti tek başına alışveriş kimliği sayılmaz. Aynı işlem olduğu kesin değilse esnafa kısa teyit sorulur.
- Tekrar yükleme, tekrar kaydetme, ağ kesintisi sonrası yeniden deneme ve aynı belgenin farklı fotoğrafı çift kart veya çift stok üretmez.
- Faturadaki adet stok önerisidir; satış fiyatı esnafın kararıdır. Beden/renk seçenekleri, satın alınan varyant adetleriyle karıştırılmaz.

**Bitiş:** Işılay bilgi fişi ile e-Arşiv faturası bir model ve sekiz adetlik aynı alımı temsil eder; toplam 16 adede çıkmaz. Tek e-Arşiv fotoğrafı ana akışı başlatmaya yeterlidir.

### F3 — Havuz dışında da resmî firma ve doğru ürüne ulaşma

**İşler:**

- Yerel katalog önce kullanılır; sonuç yoksa firma ve ürün keşfi devam eder. Havuz dışı firma araması bu fazın zorunlu parçasıdır.
- Resmî kaynak doğrulaması yalnız alan adında firma adının geçmesine dayanmaz. Faturadaki firma bilgisi, resmî sitedeki iletişim/adres ve birbirine bağlı resmî hesaplar birlikte değerlendirilir.
- Satıcı/toptancı, üretici ve marka ayrı tutulur. Toptancının faturasında başka marka bulunması otomatik çelişki değildir; ilgili markanın doğrulanmış kaynağında arama sürer.
- Shopify/WooCommerce ve yapılandırılmış ürün sayfalarına ek olarak resmî PDF katalogları, resmî sosyal hesaplar ve firmanın sağladığı katalog dosyaları için erişim yolları tamamlanır. Erişilemeyen özel hesap veya kapalı kaynak aşılmış gibi gösterilmez.
- İlk dört sayfaya bakıp “ürün yok” deme kaldırılır. Model/barkod hedefli arama, ilgili sitemap seçimi ve gerektiğinde kaldığı yerden devam eden sınırlı tarama kullanılır. Süre sınırına gelmek, kaynağın bulunmadığı anlamına çevrilmez.
- Eşleştirme firma/marka + model veya doğrulanmış barkodla yapılır; varyant tutarlılığı kontrol edilir. Yalnız ürün adı veya görsel benzerliği kesin eşleşme sayılmaz. Çelişkide adaylar korunur.

**Bitiş:** Havuz dışı, resmî dijital karşılığı erişilebilir firmalar aynı ana akışta çalışır. Kaynak hatası, arama hizmeti kapalı olması ve gerçekten sonuç bulunmaması ayrı açıklanır.

### F4 — Bulunan görseli tüketici kalitesinde karta taşıma

**İşler:**

- Resmî ürün sayfası/katalog öğesi ile seçilen görselin bağı kaydedilir. Aynı kodun başka markadaki, başka varyanttaki veya benzer bir üründeki görseli kullanılmaz.
- Görselin gerçekten açıldığı, ürünle eşleştiği ve gösterim kalitesinin yeterli olduğu doğrulanır. Kırık bağlantı, logo, boş görsel veya ilgisiz katalog kapağı ürün fotoğrafı sayılmaz.
- Gerçek kaynak görselini mevcut medya altyapısında saklama ve kaynağa geri bağlama tamamlanır; süreli dış bağlantının kaybolması kartı sessizce bozmaz. Mevcut erişim ve kaynak koşulları dikkate alınır.
- Görsel seçimi, sırası, kapak görseli ve varyantla ilişkisi korunur. Resmî fotoğraf yoksa yapay görsel üretilip gerçek ürün kanıtı gibi sunulmaz.
- Kartta başlık, anlaşılır açıklama, marka, satış fiyatı, doğrulanmış varyantlar ve stok bilgisi mevcut kategori şablonlarıyla gösterilir. Bilinmeyen kumaş bileşimi, gramaj veya sertifika gibi özellikler üretilmez.
- Alış fiyatı, fatura fotoğrafı, müşteri kimliği ve iç eşleştirme notları tüketici kartına sızmaz.

**Bitiş:** Aynı gerçek kayıt telefon ve masaüstü vitrininde doğru görselle açılır; kırık resim, taşan metin veya başka varyantı temsil eden kapak yoktur. Görselin kaynağı esnaf panelinden izlenebilir.

### F5 — Fatura satırını mevcut ürün kaydına güvenilir biçimde yazma

**İşler:**

- Mevcut `invoice_jobs`, satır ve kanıt kayıtları kullanılır; ürün oluşturma isteği işlem ve satır kimliğini taşır. Sunucu sahipliği, eşleşmeyi, seçilen görselleri ve güncel durumu bu kayıtlardan yeniden okur.
- Tarayıcıdan gelen “kanıtlı” etiketi tek başına yeterli olmaz. Fatura satırı ile `products` kaydı arasında kalıcı ilişki kurulur.
- Ürün kartı mevcut ürün oluşturma/güncelleme yolundan hazırlanır. Tek modelin beden/renkleri mevcut varyant yapısına bağlanır; gereksiz kopya kartlar oluşturulmaz.
- Kaydetme tekrarı aynı kartı döndürür. Yeni bir alışverişte aynı ürün geldiyse mevcut ürün ilişkisi korunur; stok ekleme/değiştirme belirsizliği otomatik tahmin edilmez.
- Ürün yazılmış, kanıt yazılmamış gibi yarım kayıtlar başarılı işlem sayılmaz. Hata sonrası güvenli devam veya geri alma sağlanır.
- Kaynak, onay ve izin bilgileri tüketiciye açık ürün alanlarına gereksiz özel belge verisi koymadan saklanır.

**Bitiş:** Faturanın satırından ürüne, üründen kaynağına gidilebilir. Yeniden kaydetme kopya üretmez; istemcide değiştirilen bir etiket doğrulanmamış ürünü yayımlatamaz.

### F6 — Taslağa geri dönme, web/telefon ve yayın zinciri

**İşler:**

- Esnaf işlemi kapatıp açabilir; başka cihazda aynı kayıt ve durumdan devam edebilir. İşlem geçmişi yalnız yazılan ama geri okunmayan kayıt olarak kalmaz.
- Eksik/çelişkili satırın bilgisini düzeltip yeniden eşleştirme yolu tamamlanır. Düzeltilen satır için bütün faturayı baştan yüklemek gerekmez.
- Ürün yönetiminde fatura taslağı yeniden açılır; fiyat, stok, varyant ve görsel değişikliği aynı kaydı günceller. Gerekli onaylar anlamlı değişiklikten sonra yeniden değerlendirilir.
- Flutter'daki `FaturaYayinlaServisi` gerçek ekran ve kaydedilmiş ürün kimlikleriyle bağlanır. Web ve telefon aynı sunucu doğrulamasını kullanır.
- Ayrı Yayınla eylemi gerçek kayıt üzerinde çalışır. İstek başarılı dönmüş olmasıyla yetinilmez; tüketici sorgusunun ürünü getirdiği, vitrin ve ürün detayının aynı bilgileri gösterdiği doğrulanır. Gerekli önbellek yenilemesi mevcut sisteme eklenir.
- Mevcut yayındaki ürünler topluca gizlenmez; geçmiş ürünler yeni akışa zorla sokulmaz.

**Bitiş:** Yükle → kartı gör → taslak kaydet → ekranı kapat → tekrar aç → tamamla → yayınla → tüketici vitrini ve detay sayfasında gör adımları webde ve telefonda tamamlanır.

### F7 — Çalışan kart üzerinden firma izni talebi ve takip

**İşler:**

- Esnafa “Ben isteyeceğim” ve “VixRex benim için istesin” seçenekleri sunulur. İzin zaten kayıtlıysa aynı kapsam için tekrar sorulmaz.
- “Ben isteyeceğim” seçimi doğru firma, ilgili ürün/katalog kapsamı ve çalışan vitrin örneğiyle paylaşılabilir talep hazırlar.
- “VixRex istesin” seçimi takip edilebilir görev oluşturur. Gönderim gerçekleşmediyse arayüz “gönderildi” demez. Aynı firmaya her faturada yeniden talep yağdırılmaz.
- Firmanın doğrulanmış cevabı, veri/görsel kapsamı, geçerliliği ve ilgili ürünlerle bağlantısı kaydedilir. Esnafın talebi firma onayı yerine geçmez.
- İzin verildiğinde mevcut kartlar ve ilişkiler korunur; faturayı yeniden okutmak gerekmez. Ret veya geri çekme ilgili içerikler için izlenebilir biçimde uygulanır; ilgisiz esnaf ürünleri silinmez.

**Bitiş:** Bir firma talebinin kimin sorumluluğunda olduğu, gönderilip gönderilmediği, cevabı ve hangi kartları kapsadığı görülebilir. Teknik hazırlık izin görüşmesine kadar tamamlanmıştır.

### F8 — Gerçek kabul ve firmaya gösterilecek kanıt paketi

**İş:** Aşağıdaki kabul matrisi gerçek uygulama üzerinde tamamlanır. Kod testleri bunun hazırlığıdır; gerçek sağlayıcı, kalıcı kayıt ve tüketici görünümü yerine sayılmaz.

**Bitiş:** Firma bazında gösterilebilir gerçek örnek, giriş belgesiyle ilişkilendirilmiş ürün kaydı, kaynak kanıtı, tüketici görünümü, ölçülen süre/maliyet ve kalan izin durumu birlikte hazırdır. Teknik eksik kalmışsa “yalnız izin kaldı” denmez.

## 6. Işılay / Glisa örneğinin değişmez kabul beklentisi

Kullanıcının gönderdiği `14545.jpg` bilgi fişi, `14544.jpg` e-Arşiv faturası ve `14550.jpg` ürün fotoğrafı bu çalışmanın ilk gerçek referansıdır. Alıcıya ait özel bilgiler test raporlarına veya herkese açık örneklere taşınmaz.

| Kontrol | Beklenen sonuç |
| --- | --- |
| Tek fatura fotoğrafı | `14544.jpg` ile akış başlar; ikinci belge zorunlu değildir. |
| Ürün | IŞILAY 16747 — interlok penye erkek takım. |
| Firma ilişkisi | Faturadaki Glisa ile Işılay ilişkisi resmî dijital kaynakla doğrulanır. |
| Miktar | Bir ürün modeli, toplam 8 adet; bilgi fişi de eklenirse 16 olmaz. |
| Alış bilgisi | 450 TL birim, 3.600 TL mal bedeli, 360 TL KDV, 3.960 TL toplam ayrı korunur. |
| Satış fiyatı | Esnaf belirler/onaylar; alış fiyatı otomatik tüketici fiyatı olmaz. |
| Varyantlar | M/L/XL/XXL yazısından her bedenden ikişer adet varsayılmaz. Renk-adet dağılımı kanıtsız doldurulmaz. |
| Diğer ürün | Fotoğrafta görünen YNS ürünü bu faturaya dayanarak Işılay kartına veya stoğuna eklenmez. |
| Görsel | Tam 16747 modelinin doğrulanmış gerçek ürün görseli karta gelir; benzer model kabul edilmez. |
| Kalıcılık | Kaydetme, yeniden açma, cihaz değiştirme ve tekrar deneme aynı doğru kaydı korur. |
| Tüketici | Ürün kartı ve detay sayfası gerçek kayıt üzerinden görseli, satış fiyatını ve doğru varyantları gösterir. |
| İzin | Hazır örnek üzerinden talep başlatılabilir; henüz alınmamış izin alınmış gösterilmez. |

Araştırmada Işılay/Glisa adına dijital hesap izleri bulunmuş, fakat 16747 modelinin tam resmî görseli doğrulanmamıştır. Bu açık F3–F4'ün somut işidir. Firmanın dijitalde olmadığı veya bu örneğin tamamlandığı varsayılmaz. Ürün kaynağına erişim eksik kaldığı sürece Işılay için teknik tamamlanma işaretlenmez.

## 7. Kabul matrisi: birkaç örnekle kapsam daraltılmayacak

| Senaryo | Kabul koşulu |
| --- | --- |
| Havuzdaki firma | Bilinen katalog hızlı kullanılır; doğru ürün/görsel gerçek karta ulaşır. |
| Havuz dışı firma | Firma ve ürün keşfi yapılır; havuzda olmadığı için reddedilmez. |
| Toptancı başka, marka başka | Doğru markanın resmî kaynağına gidilir; çok markalı fatura yanlış çelişki üretmez. |
| Kod çakışması | Başka firmanın aynı kodu yanlış ürüne dönüşmez. |
| El yazısı/kısaltmalı belge | Okunabilen ve eşleşebilen satır işlenir; belirsiz alan açıklanır. |
| Yalnız resmî PDF/sosyal katalog | Desteklenen erişim yoluyla ürün kimliği ve görsel birlikte doğrulanır. |
| Aynı belgenin tekrarı | İkinci kart, ikinci stok veya ikinci izin talebi oluşmaz. |
| Farklı fotoğraflar, aynı alışveriş | Belgeler ilişkilendirilir; belirsizlik varsa kısa teyit alınır. |
| Eksik fiyat/stok/varyant | Taslak korunur; eksik bilginin tamamlanması aynı kartı günceller. |
| Tek doğru görsel | Üç farklı fotoğraf uydurma/çoğaltma gerekmeden faturaya özel akış çalışır. |
| Kaynak/görsel erişim hatası | Yanlış ürün veya boş görsel “hazır” sayılmaz; işlem sonradan sürdürülebilir. |
| Sayfa kapanması/telefon geçişi | İşlem, kart ve onay durumları tutarlı geri yüklenir. |
| Yayın | Onaylı gerçek kayıt tüketici vitrini ve ürün detayında görünür. |
| İzin talebi | Esnaf seçimi, gönderim ve firma cevabı ayrı doğru durumları gösterir. |

İlk kabul paketi Işılay örneğine ek olarak gıda, tekstil/tuhafiye, temizlik ve ev tekstilinden gerçek belgelerle genişletilir; en az iki havuz dışı firma ve bir çok markalı toptancı senaryosu içerir. Bunlar asgari genellenebilirlik kanıtıdır, ürün kapsamının üst sınırı değildir. Gerçek belge bulunmayan senaryo tamamlandı sayılmaz; yapay örnek yalnız yazılım kuralını sınamak için kullanılır.

Kabul örneklerinde yanlış ürün, yanlış görsel ve mükerrer ürün/stok toleransı sıfırdır. Dijital karşılığı önceden doğrulanmış erişilebilir örneklerin tamamı açıklanabilir şekilde işlenmelidir. Bu ölçüm tüm Türkiye faturalarında ölçülmemiş bir “%100 doğruluk” iddiasına dönüştürülmez. Kullanıcının beklentisi, akışın hiçbir aşamasının yarım bırakılmamasıdır.

## 8. Maliyet ve hız: kapsamı kesmeden

- Firma/ürün kimliği ve kaynak kataloğu doğrulandıktan sonra tekrar kullanılabilir. Her esnaf aynı ürünü aldığında firma baştan araştırılmaz; güncellik ve izin kapsamı ayrıca izlenir.
- Yapay zekâ belge okuma ve anlam çözmede kullanılır; kesin kod/barkod eşleştirmeleri mümkün olduğunda katalog indeksinden yapılır.
- Kaynak sağlayıcısının koşullarıyla uyumlu veri saklanır. Arama sonucu özeti ile firmanın doğrudan kaynağından doğrulanan ürün kaydı aynı şey sayılmaz.
- OCR, firma keşfi, ürün/görsel alma ve kart yazma süreleri ayrı ölçülür. İlk kez görülen firma maliyeti ile tekrar kullanım maliyeti ayrı raporlanır.
- Süre veya maliyet sınırına gelince iş kaybolmaz; kaldığı yerden devam eder. Fatura başına ölçüm yapılmadan süre, token maliyeti veya tasarruf yüzdesi vaat edilmez.

## 9. Uygulama ve teslim disiplini

F0 tamamlandıktan sonra F1–F2 temeli kurulur; F3–F4 kaynak ve medya zinciri, F5 kalıcı kart bağlantısı tamamlanır. F6 gerçek kullanıcı yolunu, F7 firma görüşmesi sürecini bağlar. F8 teslimi kanıtlar. Birden fazla ajan çalışacaksa dosya sahipliği ayrılır; aynı dosyaya eşzamanlı yazılmaz. Yeni bir plan veya ikinci bir uygulama hattı açmak yerine bu listedeki mevcut iş sürdürülür.

Her faz şu bilgileri taşır: sorumlu çalışma/dal, dokunulan dosyalar, değişiklik sürümü, çalıştırılan kontrol, somut kanıt ve kalan engel. Durumlar **başlamadı / sürüyor / kod tamam / gerçek akış doğrulandı** şeklindedir. “Kod tamam” tek başına fazın gerçek kullanıcı kabulünü kapatmaz.

| Faz | Plan yazılırken durum | Kapanış kanıtı |
| --- | --- | --- |
| F0 | Ön inceleme var; uygulama tabanı henüz sabitlenmedi | Korunmuş işler ve tek sürüm envanteri |
| F1 | Kodda doğrulanmış çelişkiler var | Tekil/toplu onay ve tek görselli kartın gerçek akışı |
| F2 | Okuyucu var; belge ilişkisi ve alan ayrımları eksik | Işılay tek fotoğraf + mükerrer belge kontrolü |
| F3 | Yerel/dinamik arama var; erişim ve kimlik açıkları var | Havuz dışı ve çok markalı gerçek eşleşmeler |
| F4 | Görsel adayları var; tam Işılay görseli doğrulanmadı | Kaynakla bağlı, açılan doğru ürün görseli |
| F5 | İş ve ürün kayıtları var; bağlantı tamamlanmalı | Sunucudan doğrulanan, tekrarda çoğalmayan kart |
| F6 | Web parçaları var; geri açma ve telefon bağlantısı eksik | İki cihazda aynı kart ve gerçek tüketici görünümü |
| F7 | İzin alanları var; talep/cevap süreci eksik | Hazır kart üzerinden takip edilen firma talebi |
| F8 | Bu örneklerle gerçek akış doğrulanmadı | Sürümü belli, gerçek kanıt paketi |

Uygulama sırasında ilgili kural testleri, API/veritabanı entegrasyonu ve gerçek tarayıcı/telefon yolu ölçülür. Model ve veritabanını taklit eden testler gerçek hizmet kanıtı sayılmaz. Dağıtım, gerekli veritabanı değişiklikleri ve gerçek ortam ayarlarının hazır olduğu ayrıca doğrulanır; dosyalarının bulunması uygulanmış olduklarını göstermez.

**Bu doküman talebinde yalnız plan ve yönlendirme belgeleri yazılır.** Uygulama başlatma, test/model çağrısı, veritabanı değişikliği, push, dağıtım ve firmaya mesaj gönderme bu yazım işleminin parçası değildir. Sonraki uygulama işi bu master planı esas alır; kullanıcıdan hedefini veya teknik çözümü tekrar tarif etmesi istenmez.

## 10. Firma görüşmesine hazır sayılma

Aşağıdakilerin tamamı ilgili firma örneği için sağlanmadan plan “firma görüşmesine hazır” diye kapatılmaz:

- [ ] Gerçek, tek fatura fotoğrafından doğru firma ve ürün çıkarıldı.
- [ ] Tam ürünün resmî bilgisi ve gerçek görseli kaynakla doğrulandı.
- [ ] Ürün mevcut sistemde kalıcı karta dönüştü; elle perde arkasından doldurulmadı.
- [ ] Satış fiyatı ve stok esnafın kontrolüyle doğru kaydedildi.
- [ ] Kartı kapatıp açma ve tekrar işlem kopya/yanlış stok üretmedi.
- [ ] Web ve telefon akışları ilgili yayın yoluna bağlı ve doğrulandı.
- [ ] Gerçek tüketici kartı, ürün detayı ve görselleri hedef ortamda açıldı.
- [ ] Mevcut ürünler ve diğer giriş yolları korunarak ilgili kontroller geçti.
- [ ] İzin talebi, firma cevabı ve ilgili kart ilişkisi takip edilebiliyor.
- [ ] Teknik engel kalmadı; kalan konu gerçekten firmanın veri/görsel kullanım izni.

## 11. Mevcut kodda çalışılacak ana noktalar

Bu liste çalışma yönünü gösterir; dosyalar aktif geliştiği için satır numaraları sabit sözleşme değildir.

| Alan | Mevcut kaynak |
| --- | --- |
| Fotoğraf okuma ve yanıt | [faturaGoru.ts](../public_web/src/lib/faturaGoru.ts), [fatura-oku](../public_web/src/app/api/fatura-oku/route.ts) |
| Firma ve ürün keşfi | [firmaArama.ts](../public_web/src/lib/firmaArama.ts), [faturaDijitalIz.ts](../public_web/src/lib/faturaDijitalIz.ts), [faturaEslestir.ts](../public_web/src/lib/faturaEslestir.ts) |
| Katalog, kart ve taslak | [ureticiKatalog.ts](../public_web/src/lib/ureticiKatalog.ts), [faturaKartDurumu.ts](../public_web/src/lib/faturaKartDurumu.ts), [faturaTaslagi.ts](../public_web/src/lib/faturaTaslagi.ts) |
| İşlem ve kanıt kaydı | [faturaIslemKaydi.ts](../public_web/src/lib/faturaIslemKaydi.ts), [işlem şeması](../supabase/migrations/20260929000000_fatura_islem_kaniti.sql) |
| Esnaf ekranları | [InvoiceToProducts.tsx](../public_web/src/components/owner/InvoiceToProducts.tsx), [OwnerProductManager.tsx](../public_web/src/components/owner/OwnerProductManager.tsx) |
| Ürün yazma ve yayınlama | [products/batch](../public_web/src/app/api/products/batch/route.ts), [products](../public_web/src/app/api/products/route.ts), [fatura-yayinla](../public_web/src/app/api/fatura-yayinla/route.ts), [yayın şeması](../supabase/migrations/20260930000000_fatura_yayin_kapisi.sql) |
| Flutter akışı | [ocr_controller.dart](../lib/controllers/ocr_controller.dart), [ocr_scanner_screen.dart](../lib/screens/ocr_scanner_screen.dart), [fatura_yayinla_servisi.dart](../lib/services/invoice_catalog/fatura_yayinla_servisi.dart) |
| Görsel politikası | [product_image_policy.json](../shared/product_image_policy.json), [productImagePolicy.ts](../public_web/src/lib/productImagePolicy.ts) |
| Tüketici vitrini | [vitrin sayfası](../public_web/src/app/v/%5Bslug%5D/page.tsx), [ürün kataloğu](../public_web/src/app/v/%5Bslug%5D/ProductCatalog.tsx) |

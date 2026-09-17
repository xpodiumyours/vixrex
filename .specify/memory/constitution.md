# VixRex Anayasası

Bu dosya bir özelliğin **nasıl tasarlanacağını** belirler. Her plan
adımında otomatik okunur; plan bu ilkelere uymuyorsa geçmez.

Ortak çalışma kuralları `AGENTS.md`, zorunlu gelişim süreci
`DEVELOPMENT.md` dosyasındadır. Araçlara özel dosyalar bu sistemin kaynağı
veya zorunlu kapısı değildir. Çelişme olursa sıra: bu dosya →
`DEVELOPMENT.md` → `AGENTS.md`.

## Temel İlkeler

### I. Zincir atlanmaz

Her iş girdiden çıktıya doğru kurulur. Sıra: kural → girdi → doğrulama →
saklama → yetki → geçiş kapısı → etkilenen yüzeyler → çıktı → geri alma.

Yeni özellik ve davranış değişiklikleri tam zinciri izler ve her zaman
Keşif ile başlar: bugünkü çalışan hâl ölçülür, işin nereden başlayıp nerede
biteceği, ne ve nasıl gözükeceği, esnafa, Vixrex'e ve tüketiciye ne katacağı
yazılır ve Furkan onaylar. Keşif onaylanmadan Specify başlamaz. Hata
düzeltmeleri önce hatayı yeniden görür, gerçek sebebi bulur, en küçük doğru
düzeltmeyi yapar ve asıl hatayı tekrar dener. Yeni fikirler uygulamadan önce araştırılır ve
karara bağlanır. Bir hata yeni kullanıcı sonucu, veri yapısı, güvenlik kuralı,
ekran akışı veya yayın davranışı doğuruyorsa tam zincire geçer.

Kaynağı olmayan çıktı üretilmez. Saklanamayan bilgi gösterilmez. Bir
halka eksikse altındaki halka tamamlanmış sayılmaz.

Plan yazılmadan önce bu zincirin bugünkü hâli **kodda ölçülür**, tahmin
edilmez. Hangi halkanın var, hangisinin eksik olduğu kanıtla yazılır.

Bir adım önerilmeden önce üç soru geçilir:

1. Bu adım zincirin hangi halkası? Halka değilse listeye girmez.
2. Bu kuralı bugünkü veri kaç kayıtla geçiyor? Sıfırsa o kural değil,
   bariyerdir.
3. Bu adımın gerektirdiği içeriği kim üretecek? Cevap "elle doldururum"
   ise adım yanlıştır.

### II. Tek kaynak

İki tarafta da lazım olan her şey tek kaynaktan üretilir. Aynı bilgi iki
yerde elle tutulmaz. İki kopya zorunluysa kaymayı engelleyen otomatik bir
kontrol eklenir.

Veritabanı yalnız sürümlenmiş göç dosyalarıyla değişir. Panelden elle
yapılan değişiklik geçersizdir. Canlı şema ile göç zinciri arasında fark
bulunursa yeni veritabanı işi başlamaz; önce fark kapatılır.

Belge kanıt değildir. Bir iddia belgeye değil, güncel koda veya canlı
veriye dayandırılır.

Fark ölçmek değil, farkın oluşmasını engellemek esastır.

### III. Etkilenen bütün yüzeyler aynı işte

Bir değişiklik birden fazla yerde görünüyor veya çalışıyorsa — panel, web,
veritabanı, telefon uygulaması, otomatik kontroller — hepsi aynı işin
içindedir. Dışarıda kalan yüzey varsa gerekçesi yazılır ve açık iş olarak
kaydedilir.

Hedef tek yüzdür: web Next.js, mobil onun kabuğu. Next.js o seviyeye
gelene kadar Flutter paneli en iyi çalışan yerdir; oraya dokunmak ayrıca
izin ister.

Giriş, hesap bağlama, düzenleme izni, taslak, yayınlama ve cihaz değişimi
tek bir yoldan yürür. İkinci bir yol açılamaz.

### IV. Kanıt (tartışılmaz)

Yeşil test çalıştığının kanıtı değildir. Kaynak kodda kelime arayan bir
kontrol hiçbir iddianın dayanağı olamaz.

Yeni bir koruma testi, koruduğu hata bilinçli olarak geri konduğunda
kırmızıya döndüğü gösterilmeden geçerli sayılmaz.

Şu dört durum ayrı ayrı yazılır ve asla birbirinin yerine kullanılmaz:
dalda duruyor / ana dala indi / yayına dağıtıldı / canlıda doğrulandı.
Her raporda hangisi olduğu ve test adresi bulunur.

Görünen her değişiklik tarayıcıda açılıp ölçülür. Veritabanı değişikliği
canlıda uygulandığı doğrulanmadan iş bitmez. Karar veren her parça —
asistan, arama, eşleme — gerçek esnaf cümleleriyle sınanır; cümle
listesinde Türkçe harfler ve ekler bulunur.

Ölçülmemiş şey söylenmez. Bilinmiyorsa "bilmiyorum" yazılır.

### V. Güvenlik özellikle aynı işte

Veri erişim kuralları ve yetkiler, özelliği yazan işin içinde yazılır,
sonraya bırakılmaz. Her yeni veri yolu üç kimlikle denenir: herkes,
misafir, giriş yapmış kullanıcı. Yetki kaldırılırken üçünden de
kaldırıldığı doğrulanır.

### VI. Kapsam kilitli

Bir iş tek bir kabul kriteri için açılır: Furkan'ın dilinde, teknik
olmayan tek cümle. Kabul kriterini değiştirmeyen teknik dosya, test ve
altyapı gereksinimleri aynı işin içindedir; ajan bunları araştırır, kayda
ekler ve kullanıcıya teknik seçim sorusu sormadan tamamlar. Yeni kullanıcı
sonucu, ekran, ürün kuralı, maliyet, hukuki sonuç, veri kaybı veya canlı
yetki doğuran genişleme ayrı karardır.

Aynı anda en fazla iki açık iş bulunur. Yarım iş bırakıp yenisine
geçilmez. Bekleyen iş kuyruğu veya tıkanmış yayın hakkı varsa önce o
temizlenir, yeni iş açılmaz.

### VII. Onay ve kapı

Zincir ölçülüp plan çıkarıldıktan sonra uygulama yetkisi aranır. Furkan'ın
"yap", "düzelt" veya "başla" sözü, tarif edilen kabul kriteri içindeki teknik
uygulama yetkisidir; aynı iş için dosya, test, dal, araç, yöntem veya mimari
ayrıntı tekrar sorulmaz. Ekranı, akışı, görünümü, ürün kuralını, maliyeti,
hukuki sonucu, veri güvenliğini veya canlı sistemi ayrıca değiştiren bir karar
varsa tek sade soruyla açık onay alınır. Bir işte verilen onay başka bir
kabul kriterini kapsamaz.

Zorunlu bir kontrol çalışmadıysa, atlandıysa veya altyapısı erişilemez
durumdaysa sonuç yeşil sayılmaz ve iş ilerleyemez. Kontrol sisteminin
kendisi çalışmıyorsa önce o onarılır.

Etkilenen her istemcinin gerçek üretim derlemesi başarıyla alınmadan iş
bitmiş sayılmaz.

### VIII. Üretim sonrası

Yayın, işin sonu değildir. Yayından sonra gerçek kullanıcı yolu ve hata
izleme kontrol edilir. Kritik bozulmada uygulanabilir durumda kayıtlı bir
geri alma yolu bulunur; geri alma en az üç ayda bir gerçekten denenir.

Canlıda patladığında kimin haberi olacağı ve esnafın nereye başvuracağı
yazılı değilse özellik yarımdır.

### IX. Ortak gelişim omurgası

Her VixRex işi, üreticinin insan veya yapay zekâ olmasına ve kullanılan araca
bakılmadan ortak sistemden geçer. Araçlara özel dosyalar yalnız kullanım
kolaylığı sağlar; kural kaynağı olamaz ve başka bir aracın çalışmasını
engelleyemez.

Yeni özellik ve davranış değişikliğinin yolu:

Anayasa → Keşif → Specify → Clarify → Plan → Checklist → Tasks → Analyze →
Implement → Converge → eksik varsa Implement ve Converge tekrarı → Review / PR.

Keşif Vixrex'in kendi halkasıdır: Furkan doğal Türkçeyle isteğini söyler,
üretici bugünkü hâli gerçek dosya yollarıyla ölçer, işin sınırlarını ve üç
tarafa kazancını yazar. Merkezi kontrol keşifte gösterilen yolların depoda
gerçekten bulunduğunu ve değişen her ürün dosyasının kayıtlarda geçtiğini
doğrular; kayıtta geçmeyen değişiklik teslim edilemez.

Hata düzeltmesinin yolu:

Anayasa → hatayı tekrar gör → gerçek sebebi bul → Tasks → Implement →
Converge → eksik varsa tekrar → Review / PR.

Yeni fikir önce araştırılır; uygulama kararı verilmeden ürün kodu değiştirilmez.
Her aşamanın kalıcı kanıtı `specs/<iş-kimliği>/` altında tutulur. GitHub'daki
merkezi kontrol seçilen iş türünün eksik kaydını, açık görevini, yakınsamamış
uygulamasını veya başarısız incelemesini gördüğünde teslimatı durdurur.

Kod, belge, canlı yüzey ve yetkili araçlarla bulunabilen bilgi Furkan'a
sorulmaz. Teknik seçimi üretici yapar ve kanıtlar. Yalnız birbirini dışlayan
ürün sonuçları veya para, hukuk, görünüm, içerik, veri kaybı, gizlilik ve canlı
işlem kararları Furkan'a gelir.

Ana dala alma canlı yayın değildir. Otomatik canlı yayın kapalı tutulur; yayın
ayrı sahip kararı, önizleme doğrulaması ve geri alma hazırlığı gerektirir.

## Bitti Tanımı

Bir iş ancak hepsi doğruysa bitmiştir; biri eksikse yarım diye raporlanır.

1. Kabul kriteri baştan yazılmıştı ve karşılandı
2. Zincirin bütün halkaları kapandı veya gerekçesi yazıldı
3. Bilgi kaydediliyor ve geri okunuyor
4. Güvenlik üç kimlikle denendi
5. Etkilenen bütün yüzeyler ele alındı
6. Zorunlu kontroller gerçekten koştu ve yeşil
7. Etkilenen istemcilerin üretim derlemesi alındı
8. Canlıda görüldü, adresi yazıldı
9. Veritabanı değişikliği canlıda uygulandı, şema göç zinciriyle aynı
10. Geri alma yolu kayıtlı ve uygulanabilir
11. Hata izleme ve destek yolu yazılı
12. Gerçek kullanıcının gerçek yolundan bir kez geçti

## Yönetim

Bu anayasa diğer belgelerin üstündedir. Yalnız Furkan değiştirir; hiçbir
ajan kendi başına madde ekleyemez, çıkaramaz, gevşetemez. Her değişiklik
tarihli olur ve sebebi yazılır.

Bir madde işi engelliyorsa çözüm maddeyi atlamak değil, gerekçesiyle
değişiklik önermektir. Bu belgeyi veya otomatik kontrolleri kaldırma
önerisi kırmızı bayraktır.

Her ilke geçmişte yaşanmış somut bir aksaklığa dayanır. Dayanağı olmayan
madde eklenmez.

**Version**: 2.2.0 | **Ratified**: 2026-09-17 | **Last Amended**: 2026-09-17

2.2.0 (2026-09-17, Furkan'ın isteğiyle): Keşif halkası eklendi. Sebep: kapı
yalnız belgelerin varlığını ölçüyordu; doğal dilde söylenen isteğin nereden
başlayıp nerede biteceği, ne gözükeceği ve kime ne katacağı hiçbir yerde
yazılı değildi.

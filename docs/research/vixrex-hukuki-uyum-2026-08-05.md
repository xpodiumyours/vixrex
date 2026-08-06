# VixRex Türkiye Hukuki Uyum Araştırması

**Tarih:** 5 Ağustos 2026  
**Kapsam:** Dijital vitrin, işletme paneli, ürün/hizmet gösterimi, müşteri ve randevu yönetimi, WhatsApp yönlendirmesi; koşula bağlı olarak üyelik, ödeme, ticari ileti, çerez ve üretken yapay zekâ.  
**Kaynak sınırı:** Yalnızca mevzuat ve kamu kurumlarının birincil/resmî açıklamaları kullanılmıştır.

> Bu belge hukuk müşavirliği veya bağlayıcı hukuk görüşü değildir. Ürün akışı, şirket yapısı, ciro/çalışan sayısı, kullanılan tedarikçiler ve sözleşmeler görülmeden “tam uyum” sonucu verilemez. Özellikle ödeme, sağlık/güzellik randevuları, çocuk kullanıcılar ve yurt dışı servisler devreye alınmadan önce Türkiye’de bilişim, tüketici ve veri koruma hukuku çalışan bir avukat ile mali müşavirden yazılı kontrol alınmalıdır.

## 1. Yönetici özeti: önce kapatılması gereken riskler

| Öncelik | Risk | VixRex için eylem |
|---|---|---|
| Kritik | Veri rollerinin ve veri akışının bilinmemesi | VixRex–işletme–vitrin ziyaretçisi için veri sorumlusu/veri işleyen rollerini işlem bazında çıkar; Supabase, Vercel, AI, e-posta, analitik ve hata izleme aktarım haritasını tamamla. |
| Kritik | Yurt dışı altyapıya hukuki aktarım mekanizması olmadan kişisel veri gönderimi | Her tedarikçinin veri merkezi, alt işleyeni ve rolünü doğrula; KVKK m.9 mekanizmasını seç, gerekiyorsa standart sözleşmeyi imzala ve beş iş günü içinde Kuruma bildir. |
| Kritik | Müşteri/randevu verilerinde eksik aydınlatma, fazla veri veya süresiz saklama | Her toplama noktasında katmanlı aydınlatma; amaç/hukuki sebep/süre/alıcı matrisi; silme ve ilgili kişi başvuru akışı kur. Sağlık bilgisi toplamama varsayılanı uygula. |
| Yüksek | Pazarlama mesajı ile işlem mesajının karıştırılması | Ticari iletiyi ayrı izinle ve İYS kaydıyla yönet; ret kanalını ücretsiz/kolay tut. Randevu durum bildirimi içine kampanya ekleme. |
| Yüksek — koşula bağlı | Platform içinde sipariş/ödeme veya mesafeli sözleşme kurulması | Canlıya almadan önce 6502/mesafeli sözleşme ve 6563 rollerini tasarla; ön bilgilendirme, cayma/iptal/iade ve kalıcı veri saklayıcısı akışını kur; ETBİS kapsamını doğrula. |
| Yüksek | Zorunlu olmayan çerezlerin rızadan önce çalışması | Çerez envanteri çıkar; zorunlu olmayan analitik/reklam çerezlerini önceden kapalı tut; reddetmeyi kabul kadar kolay yap. |
| Yüksek | İşletmenin yüklediği görsel/metin veya AI çıktısının hak ihlali | Lisans/yetki beyanı, bildirim-kaldırma kanalı, tekrar ihlal süreci ve AI çıktısı için insan onayı kur. |

## 2. KVKK: temel yükümlülükler

6698 sayılı Kanun; kimliği belirli veya belirlenebilir gerçek kişiye ilişkin verinin elde edilmesi, kaydedilmesi, saklanması, aktarılması ve silinmesini kapsar. VixRex’te işletme sahibi hesabı, telefon/e-posta, müşteri randevusu, IP/cihaz kayıtları, destek konuşmaları ve AI istemleri bu kapsama girebilir. Kanunun güncel metni ve ikincil düzenlemeler için [KVKK mevzuat sayfası](https://www.kvkk.gov.tr/Icerik/4184/Kisisel-Verilerin-Korunmasi-Kanunu) esas alınmalıdır.

### Zorunlu tasarım kararları

- Her işlem için veri sorumlusu belirlenmeli. VixRex kendi hesap, güvenlik, faturalama ve ürün analitiğinin amaçlarını belirliyorsa bu işlemlerde veri sorumlusudur. İşletmenin müşteri/randevu amaçlarını yalnız talimatla yürütüyorsa veri işleyen olabilir. **Koşula bağlı:** Rol sözleşmedeki etikete değil, fiilen amaç ve araçları kimin belirlediğine göre işlem bazında değerlendirilir.
- KVKK m.4 ilkelerine göre veri belirli, açık ve meşru amaçla; amaçla bağlantılı, sınırlı, ölçülü ve gerekli süre kadar tutulmalı. Her veri alanı için amaç, hukuki sebep, erişen rol, alıcı, saklama süresi ve silme yöntemi içeren envanter hazırlanmalı.
- Veri toplanırken KVKK m.10’a uygun olarak veri sorumlusunun kimliği, amaç, aktarım, toplama yöntemi/hukuki sebep ve ilgili kişi hakları anlatılmalı. Açık rıza gereken işlem varsa aydınlatmadan ayrı ve özgür seçimle alınmalı; hizmetin zorunlu olmayan pazarlama rızasına bağlanmaması gerekir.
- Erişim, düzeltme, silme/yok etme, itiraz gibi KVKK m.11 talepleri için kimlik doğrulamalı başvuru kanalı ve süre takibi kurulmalı. İşleme şartları bittiğinde silme/yok etme/anonimleştirme gerekir; aktarılan üçüncü kişilere de işlem bildirilir ([Silme, Yok Etme veya Anonim Hale Getirme Yönetmeliği](https://www.kvkk.gov.tr/Icerik/5441/KISISEL-VERILERIN-SILINMESI-YOK-EDILMESI-VEYA-ANONIM-HALE-GETIRILMESI-HAKKINDA-YONETMELIK)).
- KVKK m.12 uyarınca uygun teknik ve idari tedbirler gerekir: asgari yetki/RLS, MFA, sır yönetimi, şifreleme, erişim ve işlem logları, yedek, tedarikçi denetimi, ayrılan personel erişiminin kapatılması, testte gerçek veri kullanılmaması ve düzenli olay tatbikatı.

### Özel nitelikli veri

Randevu özelliği sağlık, cinsel hayat, engellilik veya benzeri serbest metin toplamamalıdır. Kuaför/sağlık/terapi gibi kategorilerde “not” alanı özel nitelikli veri doğurabilir. **Koşula bağlı:** Böyle veri gerçekten gerekliyse KVKK m.6’daki işleme şartı, ek güvenlik tedbirleri, dar erişim ve kısa saklama süresi ayrıca tasarlanmalıdır; yalnız genel açık rıza kutusu yeterli güvence değildir.

### VERBİS

VERBİS kaydı bütün veri sorumluları için aynı sonucu vermez; güncel istisna kararı işletmenin çalışan sayısı, yıllık mali bilançosu ve ana faaliyetinin özel nitelikli veri işleme olup olmadığına bağlıdır. 2025/1572 sayılı karara ilişkin Kurum duyurusuna göre ana faaliyeti özel nitelikli veri işleme olmayan, çalışanı 50’den ve yıllık mali bilançosu 100 milyon TL’den az veri sorumluları istisna kapsamındadır; ana faaliyeti özel nitelikli veri işleme olanlar için ayrıca 10 çalışan/10 milyon TL eşiği açıklanmıştır ([KVKK duyurusu](https://www.kvkk.gov.tr/Icerik/8577/kisisel-verileri-koruma-kurulunun-04-09-2025-tarihli-ve-2025-1572-sayili-kararinin-uygulama-esaslarina-iliskin-kamuoyu-duyurusu), [istisnalar listesi](https://www.kvkk.gov.tr/Icerik/5273/Istisna)). **Koşula bağlı:** Güncel mali tablolar, çalışan hesabı ve ana faaliyet teyit edilmeden “VERBİS’ten muaftır” denmemeli. Kayıt istisnası KVKK’nın diğer yükümlülüklerini kaldırmaz.

### Veri ihlali

Yetkisiz elde etme öğrenildiğinde Kurula bildirim gecikmeksizin ve en geç 72 saat içinde; etkilenen kişilere bildirim ise kişi belirlendikten sonra makul en kısa sürede yapılmalıdır ([KVKK kamuoyu duyurusu ve 2019/10 karar açıklaması](https://www.kvkk.gov.tr/Icerik/8595/kamuoyu-duyurusu)). Olay planı; karar yetkilisi, 72 saat sayacı, delil koruma, etki analizi, Kurul formu, ilgili kişi metni ve tedarikçinin VixRex’i derhal haberdar etme süresini içermeli.

## 3. Yurt dışına veri aktarımı

Vercel, Supabase, AI modeli, analitik, hata izleme, e-posta veya destek tedarikçisi Türkiye dışında veriye erişiyor ya da veriyi saklıyorsa KVKK m.9 gündeme gelir. Veri merkezi bölgesi tek başına yeterli değildir; destek erişimi ve alt işleyenler de haritalanmalıdır.

- 2024 sonrası rejimde yeterlilik kararı, uygun güvence (ör. bağlayıcı şirket kuralları veya standart sözleşme) ve sınırlı arızi hâller ayrı mekanizmalardır. Sürekli bulut hizmetini sırf açık rızaya dayandırmak güvenli varsayım değildir.
- Standart sözleşme seçilirse tarafların rolüne uygun şablon kullanılmalı; sözleşme imzadan itibaren **beş iş günü içinde** Kuruma bildirilmelidir. Kurum, dört rol kombinasyonu için metin yayımlamıştır ([yönetmelik ve standart sözleşmeler duyurusu](https://www.kvkk.gov.tr/Icerik/7998/Standart-Sozlesme-Metinlerinin-Ingilizce-Cevirisine-Iliskin-Duyuru), [uygulama hususları duyurusu](https://www.kvkk.gov.tr/Icerik/8170/Yurt-Disina-Kisisel-Veri-Aktariminda-Kullanilacak-Standart-Sozlesmelerde-Dikkat-Edilmesi-Gereken-Hususlara-Iliskin-Kamuoyu-Duyurusu)).
- DPA/SCC imzalanmadan önce veri kategorileri, amaç, ilgili kişi grupları, aktarım sıklığı, saklama, teknik tedbirler ve alt işleyen listesi gerçek sistemle eşleştirilmeli.

## 4. Çerezler ve benzeri takip teknolojileri

KVKK’nın [Çerez Uygulamaları Hakkında Rehberi](https://www.kvkk.gov.tr/Icerik/7353/Cerez-Uygulamalari-Hakkinda-Rehber) uyarınca her çerez için amaç, süre, birinci/üçüncü taraf niteliği ve hukuki sebep belirlenmelidir. Hizmet için kesin gerekli olmayan analitik, reklam ve çapraz-site takip araçları açık rıza gerekiyorsa rızadan önce çalışmamalıdır.

Uygulama standardı:

- “Kabul et” ve “Reddet” aynı görünürlük ve kolaylıkta olsun; yalnız “ayarlar” bağlantısı ile ret gizlenmesin.
- Kategoriler önceden seçili olmasın; zorunlu çerezler ayrı açıklansın.
- Rıza geri alınabilsin; çerez yönetim paneli sürekli erişilebilir olsun.
- Çerez adı/sağlayıcı/amaç/süre/aktarım tablosu yayımlansın ve gerçek taramayla periyodik doğrulansın.
- Local storage, SDK, piksel ve cihaz kimliği yalnız adına bakılarak kapsam dışında sayılmasın.

## 5. Ticari elektronik ileti ve İYS

Randevu oluşturuldu/onaylandı gibi talep edilen hizmete ilişkin, reklam içermeyen işlem mesajları ile kampanya/tanıtım mesajları teknik ve hukuki olarak ayrılmalıdır. Pazarlama SMS’i, e-postası veya araması için kural olarak gönderimden önce onay gerekir; onay istemek için ticari elektronik ileti gönderilemez. Tacir/esnaf alıcılarda ön onay istisnası vardır ancak ret sonrasında gönderim durmalıdır ([Ticaret Bakanlığı genel bilgiler](https://www.ticaret.gov.tr/ic-ticaret/ticari-elektronik-iletiler/genel-bilgiler)).

- VixRex kendi kampanyasını gönderiyorsa kendi hizmet sağlayıcı kimliği/onayı gerekir. İşletme adına gönderim altyapısı sunuyorsa aracı rolü ve talimat/sorumluluklar ayrıca sözleşmeye bağlanmalı.
- Onay, ret ve ileti kayıtları ispatlanabilir tutulmalı; onay-ret bildirimleri üç iş günü içinde İYS’ye kaydedilmelidir ([Ticaret Bakanlığı 2025 entegratörlük açıklaması](https://ticaret.gov.tr/haberler/entegratorluk-yetkisi-basin-aciklamasi), [İYS bilgi sayfası](https://ticaret.gov.tr/ic-ticaret/ticari-elektronik-iletiler/ileti-yonetim-sistemi-iys)).
- Her pazarlama iletisinde gönderen kimliği ve kolay/ücretsiz ret yolu bulunmalı; ret sonrası mevzuattaki sürede durdurma uygulanmalı. WhatsApp da elektronik ileti kanalı olarak izin tasarımından otomatik hariç tutulmamalı.
- Ticari ileti onayı ile KVKK açık rızası tek ve belirsiz bir kutuda birleştirilmemeli; amaçlar ayrılmalı.

## 6. 6563, e-ticaret rolleri ve ETBİS

Bugünkü “ürünü göster, işletmenin WhatsApp’ına yönlendir” akışı tek başına VixRex’i kesin olarak pazaryeri/aracı hizmet sağlayıcı yapar denemez. **Koşula bağlı:** Sipariş veya sözleşme VixRex içinde kuruluyor, ödeme alınıyor, sipariş yönetiliyor ya da platform satıcı ile alıcı arasında mesafeli sözleşme kurulmasına aracılık ediyorsa 6563 ve ikincil mevzuattaki hizmet sağlayıcı/aracı hizmet sağlayıcı yükümlülükleri doğabilir. Resmî mevzuat listesi: [Ticaret Bakanlığı elektronik ticaret mevzuatı](https://ticaret.gov.tr/ic-ticaret/mevzuat/elektronik-ticaret).

Bu kapı açılmadan önce:

- VixRex’in sözleşmenin tarafı mı, yalnız teknik sağlayıcı mı, elektronik ticaret aracı hizmet sağlayıcı mı olduğu yazılı belirlenmeli.
- Ticari unvan/MERSİS-VKN/KEP ve iletişim bilgileri, işlem rehberi, sözleşme saklama/erişim, sipariş teyidi ve hukuka aykırı içerik süreçleri role göre uygulanmalı.
- ETBİS’e faaliyetten önce kayıt gerekip gerekmediği doğrulanmalı. Bakanlık, kendi e-ticaret ortamında faaliyet gösteren hizmet sağlayıcıları ve aracı hizmet sağlayıcıları kayıt kapsamında saymaktadır ([ETBİS resmî bilgi](https://ticaret.gov.tr/ic-ticaret/bilgi-sistemleri/elektronik-ticaret-bilgi-sistemi-etbis-ve-e-ticaret-bilgi-platformu), [ETBİS SSS](https://etbis.ticaret.gov.tr/tr/SSS?category=%2FFAQ%2Fetbis-sistem-kullan%C4%B1m%C4%B1-1)).

## 7. Tüketici ve mesafeli sözleşmeler

### VixRex premium üyeliği

VixRex bir tüketiciye uzaktan ücretli premium hizmet satarsa 6502 ve Mesafeli Sözleşmeler Yönetmeliği gündeme gelir. Müşteri yalnız ticari/mesleki amaçla hareket eden işletmeyse 6502’deki “tüketici” sıfatı olmayabilir; bunu yalnız “B2B” etiketi değil kayıt ve kullanım amacı desteklemelidir.

Ödeme öncesinde hizmetin temel nitelikleri, sağlayıcı kimliği/adresi/telefonu, vergiler dâhil toplam fiyat, süre/otomatik yenileme, fesih, şikâyet ve varsa cayma hakkı açık ve kalıcı veri saklayıcısıyla sunulmalı; sipariş düğmesi ödeme yükümlülüğünü açıkça anlatmalıdır. Dijital hizmetin cayma süresi içinde başlatılması ve cayma istisnası gibi konular özel teyit/koşullar gerektirir; otomatik kutu kullanılmamalı.

### İşletme–müşteri satışı

**Koşula bağlı:** VixRex üzerinden mesafeli sözleşme kurulursa platform ön bilgilendirme, teyit/ispat ve cayma bildirim sistemi bakımından aracı hizmet sağlayıcı sorumlulukları üstlenebilir. Bakanlığın resmî rehberi ön bilgilendirmenin içeriğini, 14 günlük genel cayma hakkını ve platformun kesintisiz cayma bildirim/takip sistemi sorumluluğunu açıklar ([Mesafeli sözleşmeler bilgilendirmesi](https://tuketici.ticaret.gov.tr/yayinlar/tuketici-bilgi-rehberi/mesafeli-sozlesmeler-hakkinda-bilgilendirme), [Yönetmelik metni](https://tuketici.ticaret.gov.tr/data/5e819a8e13b876a1b04c7a4a/Mesafeli%20S%C3%B6zle%C5%9Fmeler%20Y%C3%B6netmeli%C4%9Fi.pdf)). Yalnız WhatsApp’a yönlendirme varsa sözleşmenin nerede/ne zaman kurulduğu gerçek akış üzerinden hukukçu tarafından değerlendirilmelidir.

## 8. Çocuklar

VixRex işletmelere yönelik olsa da halka açık vitrin ve randevu formu çocuk tarafından kullanılabilir. Türkiye’de tüm çevrim içi hizmetler için tek bir genel “dijital rıza yaşı” varsayımıyla hareket edilmemeli. Çocuk verisinde şeffaflık, veri minimizasyonu ve velayet/temsil yetkisinin gerçek akışa göre doğrulanması gerekir. Kurul, çocuğun verisinin veli açık rızası olmadan pazarlama amacıyla kullanılmasını hukuka aykırı değerlendirmiştir ([2022/776 karar özeti](https://www.kvkk.gov.tr/Icerik/7572/2022-776)).

- Varsayılan olarak doğum tarihi isteme; çocuk hedeflenmiyorsa yaş profillemesi ve çocuk pazarlaması yapma.
- Çocuklara yönelik hizmet varsa çocuk-dostu aydınlatma, yüksek mahremiyet varsayılanı, reklam/profilleme yasağı, veli/temsil doğrulaması ve güvenli silme süreci için ayrı hukuk tasarımı yap.
- AI asistanına çocuğun veya üçüncü kişinin kişisel verisini yazmama uyarısı koy; hassas girdileri engelle/redakte et.

## 9. AI asistan

Üretken AI’ya gönderilen kullanıcı mesajı, işletme içeriği, müşteri verisi ve loglar ayrı veri işleme faaliyetidir. Canlıya almadan önce model sağlayıcı, veri konumu, eğitimde kullanım, saklama, kötüye kullanım logları, alt işleyen ve silme imkânı doğrulanmalıdır. KVKK’nın [Üretken Yapay Zekâ ve Kişisel Verilerin Korunması Rehberi](https://www.kvkk.gov.tr/Icerik/8547/uretken-yapay-zeka-ve-kisisel-verilerin-korunmasi-rehberi-15-soruda) yaşam döngüsü boyunca veri sorumlularına yol göstermeyi amaçlar; [Yapay zekâ tavsiyeleri](https://kvkk.gov.tr/SharedFolderServer/CMSFiles/d4a738b6-5a86-454f-8788-b97758cab0da.pdf) veri minimizasyonu, şeffaflık ve hesap verebilirliği vurgular.

- AI’nın insan olmadığını, hata üretebileceğini ve nihai yayın/işlem öncesi insan onayı gerektiğini açıkça belirt.
- Müşteri verisini varsayılan olarak modele göndermeme; gerekiyorsa maskeleme ve amaçla sınırlı alan seçimi uygula.
- AI çıktısı otomatik fiyat, kampanya, sağlık/hukuk iddiası veya ayrımcı karar olarak doğrudan yayımlanmasın.
- İstem ve çıktı saklama süresi ayrı olsun; kullanıcıya silme imkânı sağla; tedarikçi aktarımını KVKK m.9 sürecine bağla.

## 10. İçerik sorumluluğu ve fikri mülkiyet

İşletmenin yüklediği fotoğraf, logo, menü, ürün metni, müşteri yorumu ve AI üretimi üzerinde kullanım hakkı bulunmalıdır. Fikir ve sanat eserleri için temel mevzuat 5846 sayılı Kanundur; güncel mevzuat bağlantısı [Kültür ve Turizm Bakanlığı Telif Hakları Genel Müdürlüğü mevzuat sayfasından](https://www.telifhaklari.gov.tr/Mevzuat) doğrulanmalıdır.

- Kullanım şartlarında işletmeden içerik üzerinde gerekli hak/izinlere sahip olduğuna dair beyan ve VixRex’e hizmet için sınırlı lisans alın; mülkiyeti toptan devralan belirsiz hüküm kullanma.
- Hak sahibi ve kişilik hakkı şikâyetleri için görünür bildirim-kaldırma kanalı, delil muhafazası, karşı bildirim ve tekrar ihlal prosedürü kur.
- İşletme içeriğini reklamda, model eğitiminde veya başka vitrinde yeniden kullanmak ayrı amaç/lisans olarak açıkça kararlaştırılmadıkça yapma.
- 5651 kapsamındaki içerik sağlayıcı/yer sağlayıcı rolü ve yükümlülükleri, kullanıcı içeriğinin barındırılma biçimine göre **koşula bağlıdır**; yayına çıkmadan rol ve BTK bildirim/yükümlülükleri uzmanla doğrulanmalıdır. Resmî mevzuat için [BTK mevzuat sayfası](https://www.btk.gov.tr/kanunlar) kullanılmalıdır.

## 11. Erişilebilirlik

Özel bir B2B vitrin SaaS’ının tüm web/mobil yüzeyleri için uygulanacak kapsam bu araştırmada kesinleştirilememiştir; bu nedenle idari para cezası doğuran özel kapsam **koşula bağlıdır**. 2025 tarihli Web Siteleri ve Mobil Uygulamaların Erişilebilirliği Genelgesi kapsamındaki kurum/kuruluş türleri ayrıca şirket statüsüne göre incelenmelidir ([Aile ve Sosyal Hizmetler Bakanlığı erişilebilirlik kaynakları ve kontrol listeleri](https://aile.gov.tr/eyhgm/sayfalar/hizli-erisim-erisilebilirlik/), [Genelgenin resmî alternatif metni](https://www.aile.gov.tr/media/268283/web_siteleri_ve_mobil_uygulamalarin_erisilebilirligi_genelgesinin_alternatif_metin_versiyonu.pdf)).

Hukuki kapsam sonucu ne olursa olsun; klavye kullanımı, görünür odak, form etiketleri/hata mesajları, yeterli kontrast, görsel alternatif metni, metin büyütme ve ekran okuyucu testi tüketici uyuşmazlığı ve ayrımcılık riskini azaltan ürün kabul kriterleri olmalıdır.

## 12. Fatura ve vergi — yalnız doğrulanabilen sınır

- VixRex’in ücretli üyelik/hizmet satışı varsa bu satış için vergi mükellefiyeti ve belge düzeni doğar; hangi belge ve vergi oranının uygulanacağı şirket/müşteri/işlem yapısına göre mali müşavirce belirlenmelidir.
- GİB, e-Arşiv Faturayı e-Fatura mükellefi olmayan vergi mükellefleri ve nihai tüketicilere mal/hizmet karşılığı elektronik oluşturulan belge olarak açıklar ([GİB e-Arşiv infografiği](https://cdn.gib.gov.tr/api/gibportal-file/file/getFileResources?objectKey=arsiv%2Fyardim-kaynaklar%2Finfografikler%2Fpdfs%2Fe_arsiv_fatura.pdf)). Güncel eşik ve zorunluluklar değişebildiğinden [509 Sıra No.lu VUK Tebliği güncel metni](https://cdn.gib.gov.tr/api/gibportal-file/file/getFile?objectKey=MEVZUAT_TEBLIGLER%2FUNIVERSAL%2F2026%2FMEVZUAT_TEBLIGLER_2026_VukTeb509_Guncel.pdf) üzerinden mali müşavir teyidi gerekir.
- VixRex yalnız yazılım aboneliğinin faturasından sorumludur varsayılmamalı: **Koşula bağlı:** İşletme–müşteri bedelini tahsil eder, komisyon keser veya satıcı adına belge üretirse ödeme hizmetleri, belge ve muhasebe sorumluluğu ayrıca tasarlanır. Lisanslı ödeme kuruluşu kullanmak VixRex’in tüketici, sözleşme ve kayıt yükümlülüklerini otomatik kaldırmaz.

## 13. Canlıya çıkış hukuk kapıları

### Her durumda

- [ ] Şirket/unvan/adres/iletişim ve hukuk bildirim kanalı görünür.
- [ ] Veri akış ve tedarikçi/alt işleyen envanteri gerçek sistemle eşleşiyor.
- [ ] Gizlilik/aydınlatma metni veri toplama noktalarında katmanlı sunuluyor; sürüm ve kanıt tutuluyor.
- [ ] Veri sahibi başvurusu, hesap kapatma, dışa aktarma ve silme akışı test edildi.
- [ ] Saklama süreleri otomatik uygulanıyor; yedek silme davranışı belgelendi.
- [ ] Yetki/RLS, log, sır yönetimi, yedek ve olay müdahale testi tamamlandı.
- [ ] Yurt dışı aktarım mekanizması ve gerekiyorsa beş iş günlük bildirim süreci tamamlandı.
- [ ] Çerez taraması yapıldı; ret öncesi zorunlu olmayan izleyici çalışmıyor.
- [ ] İçerik lisansı, şikâyet-kaldırma ve tekrar ihlal prosedürü yayımlandı.
- [ ] VERBİS durumu eşik ve ana faaliyet üzerinden yazılı kayda bağlandı.

### Özellik açılırsa

- [ ] Pazarlama mesajı: ayrı onay, İYS, ret ve ispat kayıtları.
- [ ] Platform içi sipariş/ödeme: 6563 rol analizi, ETBİS, tüketici ön bilgilendirme, cayma/iptal/iade sistemi.
- [ ] Otomatik yenilenen premium: fiyat/dönem/fesih/cayma ve yenileme iletişimi.
- [ ] AI: sağlayıcı DPA/aktarım, veri minimizasyonu, insan onayı, istem/çıktı silme.
- [ ] Çocuk hedefi: yaş/veli ve çocuk-dostu mahremiyet tasarımı.
- [ ] Sağlık veya başka özel nitelikli veri: m.6 şartı, Kurul tedbirleri ve çok dar erişim.

## 14. Avukata ve mali müşavire verilecek kanıt paketi

Bağlayıcı görüş istemeden önce şu belgeler hazırlanmalı: ekran-akış videosu; tüm formlar ve alan listesi; veritabanı şeması ve RLS özeti; veri akış diyagramı; tedarikçi/alt işleyen ve ülke listesi; DPA/SCC taslakları; çerez taraması; saklama-imha tablosu; üyelik/fiyat/iptal ekranları; WhatsApp/SMS/e-posta örnekleri; işletme ve son kullanıcı sözleşmeleri; ciro/çalışan sayısı; tahsilat ve fatura akışı. Görüş, her özellik için “VixRex’in rolü, uygulanacak madde, yapılacak iş, sorumlu, son tarih ve ceza riski” tablosu şeklinde istenmelidir.


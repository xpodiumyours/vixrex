# PayTR kiralık vitrin ödeme altyapısı — resmî kaynak araştırması

**Tarih:** 29 Temmuz 2026  
**Kapsam:** Vixrex kiralık vitrinlerinin aylık 499 TL bedelle kiralanması ve yenilenmesi.  
**Kaynak sınırı:** Yalnızca PayTR'nin resmî sitesi (`paytr.com`) ve resmî geliştirici merkezi (`dev.paytr.com`) kullanılmıştır.  
**Kanıt sınırı:** PayTR mağaza başvurusunun onaylandığı kullanıcı beyanı kabul edilmiştir. Bu kabul, Abonelik Yöntemi, Direkt API, Kart Saklama API veya Non3D yetkisinin mağazada açıldığını; entegrasyonun kurulup test edildiğini ya da canlıda çalıştığını kanıtlamaz.

## Kısa karar

Vixrex'in sabit fiyatlı, aylık yenilenen 499 TL kiralık vitrin modeli için **birinci tercih PayTR Abonelik Yöntemi** olmalıdır. PayTR bu ürünü aylık/haftalık/yıllık periyotlarda otomatik tahsilat, plan yönetimi, kart güncelleme, müşteri iptali, başarısız ödemelerde yeniden deneme ve webhook bildirimleriyle tanımlıyor. Ürünün API belgeleri ve test ortamı, üyelik etkinleştirildikten sonra PayTR tarafından iletiliyor. Bu nedenle uygulamaya başlamadan önce Vixrex mağazasında bu ürünün ayrıca aktif olduğuna dair PayTR'den yazılı teyit ve güncel özel doküman alınmalıdır: [PayTR Abonelik Yöntemi](https://www.paytr.com/abonelik-yontemi).

**İkinci tercih**, PayTR'nin yönetilen abonelik ürünü Vixrex mağazasına açılamazsa veya ihtiyaçları karşılamazsa, **Direkt API + Kart Saklama API + Kayıtlı Kart Tekrarlayan Ödeme** akışıdır. PayTR'nin açık dokümanına göre bu yöntemde kayıtlı karttan istenen zaman veya aralıkta ödeme isteğini mağaza gönderir; işlem Non3D gerçekleşir ve ayrıca Non3D yetkisi gerekir. Direkt API'nin entegrasyonu, testleri ve güvenliği mağazanın sorumluluğundadır: [Direkt API](https://dev.paytr.com/direkt-api), [Kayıtlı Kart Tekrarlayan Ödeme](https://dev.paytr.com/direkt-api/kart-saklama-api/kayitli-kart-tekrarlayan-odeme).

Bu iki yol aynı sorumluluk düzeyinde değildir:

| Konu | PayTR Abonelik Yöntemi | Direkt API + Kart Saklama + Recurring |
|---|---|---|
| Periyodik tahsilat | PayTR, belirlenen periyotlarda otomatik tahsilat ve plan yönetimi sunduğunu belirtiyor. [Kaynak](https://www.paytr.com/abonelik-yontemi) | Her dönem ödeme isteğini mağaza kendi yapısından gönderir. [Kaynak](https://dev.paytr.com/direkt-api/kart-saklama-api/kayitli-kart-tekrarlayan-odeme) |
| Başarısız ödeme | Otomatik yeniden deneme, bilgilendirme ve belirli denemelerden sonra askıya alma tanımlanıyor. [Kaynak](https://www.paytr.com/abonelik-yontemi) | Senkron yanıtta `failed`, `wait_callback`, `success` ve bazı hatalarda `try_again` bilgisi döner; zamanlama ve tekrar deneme yönetimini Vixrex kurar. [Kaynak](https://dev.paytr.com/direkt-api/kart-saklama-api/kayitli-kart-tekrarlayan-odeme) |
| İptal/kart güncelleme | Müşterinin aboneliği iptal edebileceği veya kartını güncelleyebileceği belirtiliyor. [Kaynak](https://www.paytr.com/abonelik-yontemi) | Açık belgede abonelik nesnesi veya abonelik iptal uç noktası gösterilmiyor. Mağaza yeni çekimleri durdurur; istenirse kart CAPI Delete ile silinir. [Recurring](https://dev.paytr.com/direkt-api/kart-saklama-api/kayitli-kart-tekrarlayan-odeme), [Kart silme](https://dev.paytr.com/direkt-api/kart-saklama-api/kayitli-kart-silme) |
| Webhook/bildirim | Başarılı/başarısız ödeme, iade ve abonelik durumu değişikliklerinin webhook ile iletildiği belirtiliyor. Güncel alanlar özel dokümandan alınmalı. [Kaynak](https://www.paytr.com/abonelik-yontemi) | Direkt API Bildirim URL akışı açıkça belgelenmiş; HMAC doğrulaması, tekrar bildirim ve `OK` yanıtı mağazanın sorumluluğunda. [Kaynak](https://dev.paytr.com/direkt-api/direkt-api-2-adim) |
| Güvenlik yükü | PayTR, tokenizasyon ve PCI-DSS altyapısını ürünün parçası olarak tanımlıyor. [Kaynak](https://www.paytr.com/abonelik-yontemi) | PayTR, Direkt API'de güvenlik dahil tüm akışın mağaza sahibinin kontrol ve sorumluluğunda olduğunu açıkça söylüyor. [Kaynak](https://dev.paytr.com/direkt-api) |

## 1. Uygulamadan önce PayTR'den doğrulanması gereken yetkiler

Genel mağaza veya Sanal POS onayı aşağıdaki yetkilerin açıldığını tek başına kanıtlamaz:

1. **Abonelik Yöntemi aktivasyonu:** PayTR'nin resmî ürün sayfası bu ürün için ayrı başvuru, aktivasyon ve sonrasında gönderilen entegrasyon dokümanlarından söz ediyor. [Kaynak](https://www.paytr.com/abonelik-yontemi)
2. **Direkt API aktivasyonu:** PayTR, Direkt API kullanım talebinin ayrıca onaylanıp mağazaya tanımlandığını belirtiyor. [Kaynak](https://dev.paytr.com/direkt-api)
3. **Kart Saklama/Recurring erişimi:** Kart Saklama API açık geliştirici merkezinde Direkt API altında belgeleniyor. [Kaynak](https://dev.paytr.com/direkt-api/kart-saklama-api)
4. **Non3D yetkisi:** Kayıtlı karttan tekrarlayan ödeme Non3D çalışıyor ve PayTR, bu yetki için ayrıca talep iletilip onay alınması gerektiğini belirtiyor. [Kaynak](https://dev.paytr.com/direkt-api/kart-saklama-api/kayitli-kart-tekrarlayan-odeme)

PayTR desteğine uygulamadan önce tek talepte şu sorular gönderilmelidir:

- Vixrex mağazasında **Abonelik Yöntemi** aktif mi?
- Aktifse güncel API dokümanı, test ortamı, webhook imza doğrulaması, abonelik oluşturma/güncelleme/iptal uç noktaları ve yeniden deneme kuralları nedir?
- Aktif değilse **Direkt API, CAPI Kart Saklama, Recurring Payment ve Non3D** yetkileri açık mı?
- Sunucudan otomatik yenileme çağrısında zorunlu `user_ip` alanına hangi değer gönderilmelidir? Açık recurring belgesi alanı zorunlu gösteriyor ancak aktif müşteri oturumu olmayan yenileme için özel kural açıklamıyor. [Kaynak](https://dev.paytr.com/direkt-api/kart-saklama-api/kayitli-kart-tekrarlayan-odeme)
- Sözleşmedeki güncel abonelik komisyonu, BSMV, varsa sabit işlem bedeli, başarısız ödeme maliyeti ve iade sonrası ilk işlem komisyonunun durumu nedir?

## 2. Önerilen kullanıcı ödeme akışı

### Birinci tercih: yönetilen Abonelik Yöntemi

PayTR'nin özel dokümanı doğrulandıktan sonra hedef akış şu olmalıdır:

1. Kullanıcı “Kiralık Vitrin — aylık 499 TL” planını, yenileme periyodunu ve iptal koşulunu açıkça görür.
2. İlk ödeme ve kart saklama, PayTR'nin Abonelik Yöntemi dokümanında tarif ettiği güvenli/tokenize akışla yapılır. PayTR, ilk işlemde kartı token formatına dönüştürüp sakladığını ve gerçek kart numarasının mağaza sisteminde saklanmadığını belirtiyor. [Kaynak](https://www.paytr.com/abonelik-yontemi)
3. Vitrin erişimi tarayıcı yönlendirmesiyle değil, doğrulanmış başarılı webhook sonrasında etkinleştirilir. PayTR, ödeme ve abonelik durumu değişikliklerini webhook ile ilettiğini belirtiyor. [Kaynak](https://www.paytr.com/abonelik-yontemi)
4. Başarısız yenileme durumunda PayTR'nin yeniden deneme ve askıya alma olayları alınır; Vixrex erişim politikasını kendi ürün kuralına göre uygular. PayTR'nin ürün sayfası yeniden deneme, müşteri bildirimi ve belirli denemelerden sonra askıya alma davranışını tanımlıyor. [Kaynak](https://www.paytr.com/abonelik-yontemi)
5. Kullanıcı panelinde “aboneliği iptal et” ve “kartı güncelle” işlemleri bulunur. PayTR, müşterilerin aboneliklerini iptal edebileceğini veya kart bilgilerini güncelleyebileceğini belirtiyor. [Kaynak](https://www.paytr.com/abonelik-yontemi)

Bu akışın uç nokta adları, istek alanları veya imza algoritması kamuya açık ürün sayfasından tahmin edilmemelidir; PayTR, güncel dokümanları üyelik aktivasyonundan sonra ilettiğini söylüyor. [Kaynak](https://www.paytr.com/abonelik-yontemi)

### Yedek tercih: Direkt API ile mağaza tarafından yönetilen yenileme

PayTR Abonelik Yöntemi kullanılamazsa açık belgelerdeki akış şöyledir:

1. İlk ödeme sırasında kullanıcıya kartını kaydetmeyi seçebileceği bir onay kutusu sunulur. İlk kartta `store_card`; mevcut kullanıcıya yeni kart eklerken `utoken` ve `store_card` birlikte gönderilir. [Kaynak](https://dev.paytr.com/direkt-api/kart-saklama-api/yeni-kart-ekleme)
2. PayTR'nin döndürdüğü `utoken`, Vixrex kullanıcısıyla eşleştirilir. PayTR, mevcut kullanıcıya ait `utoken` yeniden gönderilmezse kartların farklı token gruplarında kalacağını belirtiyor. [Kaynak](https://dev.paytr.com/direkt-api/kart-saklama-api/yeni-kart-ekleme)
3. Vade gününde Vixrex, CAPI List ile ilgili `ctoken` değerini bulur ve benzersiz `merchant_oid` ile recurring ödeme isteği gönderir. [CAPI List](https://dev.paytr.com/direkt-api/kart-saklama-api/kayitli-kart-listesi), [Recurring](https://dev.paytr.com/direkt-api/kart-saklama-api/kayitli-kart-tekrarlayan-odeme)
4. Senkron yanıttaki `success`, `wait_callback` veya `failed` sonucu kaydedilir; nihai yetkilendirme Bildirim URL sonucuna göre yapılır. Recurring belgesi hem senkron JSON yanıtı hem Bildirim URL bildirimi gönderildiğini; Direkt API belgesi ise siparişin Bildirim URL'de onaylanması/iptal edilmesi gerektiğini söylüyor. [Recurring](https://dev.paytr.com/direkt-api/kart-saklama-api/kayitli-kart-tekrarlayan-odeme), [Bildirim URL](https://dev.paytr.com/direkt-api/direkt-api-2-adim)
5. `failed` yanında `try_again=false` dönerse aynı kartla tekrar çekim yapılmaz; `try_again=true` ise devam eden işlem sonuçlandıktan sonra kontrollü tekrar denenebilir. [Kaynak](https://dev.paytr.com/direkt-api/kart-saklama-api/kayitli-kart-tekrarlayan-odeme)

Bu yedek yöntemde abonelik takvimi, her dönemin benzersiz sipariş numarası, tekrar deneme sınırı, başarısız ödeme bildirimi, askıya alma, yeniden etkinleştirme ve iptal durumu PayTR'deki tek bir abonelik nesnesine bırakılamaz; çünkü açık recurring belgesi ödemeyi mağazanın kendi yapısının başlattığını tarif ediyor. Bu, PayTR belgesinden çıkarılan Vixrex mimari sonucudur. [Kaynak](https://dev.paytr.com/direkt-api/kart-saklama-api/kayitli-kart-tekrarlayan-odeme)

## 3. Bildirim URL / webhook güvenlik kuralları

Direkt API kullanılacaksa aşağıdaki kurallar zorunlu kabul edilmelidir:

- PayTR her işlem sonucunu tanımlı Bildirim URL'ye POST eder; Vixrex siparişi bu bildirimle onaylar veya iptal eder. [Kaynak](https://dev.paytr.com/direkt-api/direkt-api-2-adim)
- Gelen `hash`, `merchant_oid + merchant_salt + status + total_amount` verilerinden `merchant_key` ile HMAC-SHA256 kullanılarak doğrulanmalıdır. PayTR, hash kontrolü yapılmazsa maddi zarar oluşabileceğini açıkça belirtiyor. [Kaynak](https://dev.paytr.com/direkt-api/direkt-api-2-adim)
- Başarı sayfasına yönlendirme ödeme kanıtı değildir. PayTR, `merchant_ok_url` sayfasına gelindiğinde siparişin henüz onaylanmış olmayabileceğini belirtiyor. [Kaynak](https://dev.paytr.com/direkt-api/direkt-api-1-adim)
- Bildirim sayfası müşteri oturumunu kullanamaz; işlem `merchant_oid` ile bulunmalıdır. [Kaynak](https://dev.paytr.com/direkt-api/direkt-api-2-adim)
- Aynı `merchant_oid` için birden fazla bildirim gelebilir. Yalnız ilk geçerli bildirim durum değişikliği yapmalı; tekrar bildirimler yeni hizmet süresi eklememeli ve yalnız `OK` ile sonlandırılmalıdır. [Kaynak](https://dev.paytr.com/direkt-api/direkt-api-2-adim)
- Yanıtta yalnızca düz `OK` bulunmalı; öncesinde veya sonrasında HTML/başka içerik olmamalıdır. [Kaynak](https://dev.paytr.com/direkt-api/direkt-api-2-adim)
- Bildirim kaybolmuş veya yerel kayıtla uyuşmuyor görünüyorsa Durum Sorgu API ile sipariş tutarı, kesinti, net tutar ve iadeler uzlaştırılabilir. [Kaynak](https://dev.paytr.com/durum-sorgu)

Vixrex için güvenli eşleme önerisi:

- Her abonelik dönemi için tek ve benzersiz `merchant_oid`.
- Aynı dönem için ikinci “başarılı” webhook erişim süresini ikinci kez uzatmamalı.
- `wait_callback` veya yalnız tarayıcı başarı yönlendirmesi alan kullanıcıya ücretli erişim açılmamalı.
- Webhook doğrulanmadan “ödendi” durumu yazılmamalı.

Bu dört madde, PayTR'nin benzersiz sipariş numarası, Bildirim URL ile onay ve tekrarlayan bildirim kurallarından çıkarılan Vixrex uygulama gereklilikleridir. [Recurring](https://dev.paytr.com/direkt-api/kart-saklama-api/kayitli-kart-tekrarlayan-odeme), [Bildirim URL](https://dev.paytr.com/direkt-api/direkt-api-2-adim)

## 4. İptal, kart silme ve iade birbirinden ayrılmalıdır

Üç işlem aynı şey değildir:

1. **Abonelik iptali:** Gelecek dönem çekimlerini durdurur. PayTR Abonelik Yöntemi müşterinin aboneliği iptal edebilmesini desteklediğini belirtiyor. [Kaynak](https://www.paytr.com/abonelik-yontemi)
2. **Kart silme:** PayTR'deki belirli kart tokenını `utoken` ve `ctoken` ile siler. Bu işlem CAPI Delete servisinde ayrıca belgelenmiştir. [Kaynak](https://dev.paytr.com/direkt-api/kart-saklama-api/kayitli-kart-silme)
3. **İade:** Daha önce başarıyla alınmış bir tutarın tamamını veya bir kısmını müşteriye geri gönderir. PayTR İade API, `merchant_oid` ve `return_amount` ile tam/kısmi iadeyi destekler. [Kaynak](https://dev.paytr.com/iade-api)

Vixrex'te “aboneliği iptal et” işlemi varsayılan olarak geçmiş ödemeyi otomatik iade etmemelidir; iade politikası ayrıca uygulanmalıdır. Direkt API yedeğinde iptal önce Vixrex'in gelecekteki çekim planını durdurmalı, kart silme ise kullanıcı ayrıca isterse çalıştırılmalıdır. Bu ayrım, PayTR'nin ayrı recurring, kart silme ve iade servislerinden çıkarılan ürün gerekliliğidir. [Recurring](https://dev.paytr.com/direkt-api/kart-saklama-api/kayitli-kart-tekrarlayan-odeme), [Kart silme](https://dev.paytr.com/direkt-api/kart-saklama-api/kayitli-kart-silme), [İade](https://dev.paytr.com/iade-api)

PayTR'nin destek sayfasına göre aynı gün yapılan işlem “iptal”, sonraki günlerde yapılan işlem “iade” olarak adlandırılır; yapılan iptal/iade geri alınamaz ve iptal/iade işlemine ayrıca ek ücret uygulanmaz. Bu ifade, ilk satışta kesilen komisyonun mutlaka geri verileceği anlamına gelmez; o konu sözleşme ve PayTR panelinden ayrıca doğrulanmalıdır. [Kaynak](https://www.paytr.com/destek-merkezi/odemeler)

PayTR Abonelik Yöntemi ürün sayfası, abonelik ödemelerinde tam/kısmi iadenin yönetim panelinden başlatılabildiğini belirtiyor. Açık İade API de tam/kısmi iade isteğini ve isteğe bağlı `reference_no` alanını belgeliyor. [Abonelik Yöntemi](https://www.paytr.com/abonelik-yontemi), [İade API](https://dev.paytr.com/iade-api)

## 5. 499 TL fiyat ve PayTR komisyonunun gösterimi

PayTR, Abonelik Yöntemi komisyonunun sektör ve aylık ciroya göre belirlendiğini; yalnız başarılı işlemlerden komisyon alındığını ve başarısız tahsilat denemelerinden komisyon alınmadığını belirtiyor. Güncel oran PayTR Mağaza Paneli'nin Bilgi sayfasından görülebiliyor. [Abonelik Yöntemi](https://www.paytr.com/abonelik-yontemi), [PayTR Genel Destek](https://www.paytr.com/destek-merkezi/genel-destek)

Bu nedenle **“PayTR komisyonu kesin %3,99” araştırmayla doğrulanmış bir gerçek değildir**. Bu oran ancak Vixrex'in güncel PayTR teklifi/sözleşmesi veya mağaza paneliyle doğrulanır. PayTR ayrıca gerçek maliyetin komisyon, varsa sabit işlem ücreti, taksit farkı ve BSMV gibi kalemlerden etkilenebileceğini belirtiyor. [Kaynak](https://www.paytr.com/blog/sanal-pos-komisyonlari-nasil-hesaplanir)

Kiralık vitrin için önerilen müşteri gösterimi:

- Kullanıcıya tek ve açık son fiyat gösterilsin: **“499 TL / ay”**.
- PayTR kesintisi Vixrex'in ödeme alma maliyeti olarak iç hesapta izlensin.
- Vixrex'in eline net 499 TL geçmesi isteniyorsa komisyon fiyatın içine önceden brütlenerek yeni nihai fiyat belirlenebilir; ödeme adımında sonradan ayrı “PayTR komisyonu” eklenmemelidir.

PayTR'nin resmî açıklaması, sanal POS komisyonunu işletmeden kesilen hizmet bedeli olarak tanımlıyor; “brütleme” yöntemini komisyon maliyetini baştan satış fiyatına dahil etmek olarak açıklıyor. Aynı kaynak, komisyonu ayrıca müşteriye yansıtmanın hukuki çerçevesinin değişebildiğini ve uygulamadan önce güncel mevzuat/hukuk görüşü alınmasını öneriyor. [Kaynak](https://www.paytr.com/blog/sanal-pos-komisyonlari-nasil-hesaplanir)

Durum Sorgu API, müşterinin ödediği `payment_total`, işlem için kesilen `kesinti_tutari` ve kesinti sonrası `net_tutar` alanlarını ayrı döndürür. Vixrex mutabakat ve gelir raporunda bu üç değeri karıştırmamalıdır. [Kaynak](https://dev.paytr.com/durum-sorgu)

## 6. Güvenlik gereklilikleri

### Anahtarlar ve sunucu sınırı

`merchant_id`, `merchant_key` ve `merchant_salt` PayTR entegrasyon bilgileridir; PayTR bunları yalnız Ana Kullanıcı ve Teknik Kullanıcı rollerinin görebildiğini ve istek/bildirim doğrulamasında kullanıldığını belirtiyor. [Direkt API](https://dev.paytr.com/direkt-api), [Bildirim URL](https://dev.paytr.com/direkt-api/direkt-api-2-adim)

Bundan çıkan Vixrex güvenlik gereği şudur: `merchant_key` ve `merchant_salt` Flutter uygulamasına, Next.js tarayıcı paketine, public Supabase tablo/kolonlarına, loglara veya hata mesajlarına konmamalı; yalnız güvenli sunucu ortamında tutulmalıdır. Aksi halde saldırgan geçerli `paytr_token` veya webhook hash'i üretebilir. Bu sonuç, PayTR'nin HMAC üretim ve doğrulama akışından çıkarılmıştır. [Direkt API 1. adım](https://dev.paytr.com/direkt-api/direkt-api-1-adim), [Direkt API 2. adım](https://dev.paytr.com/direkt-api/direkt-api-2-adim)

### Kart verisi ve token

PayTR, kart bilgilerinin kendi PCI-DSS sertifikalı sunucularında token formatında saklandığını ve gerçek kart numaralarının açık formatta tutulmadığını belirtiyor. Kart Saklama API de saklanan kartın PayTR'de tutulduğunu, mağazanın `utoken` ve `ctoken` ile işlem yaptığını belgeliyor. [Abonelik Yöntemi](https://www.paytr.com/abonelik-yontemi), [Kart Saklama API](https://dev.paytr.com/direkt-api/kart-saklama-api)

Vixrex veritabanında tam kart numarası veya CVV tutulmamalı; uygulama logları ve hata izleme araçları bu alanları kaydetmemelidir. Vixrex yalnız PayTR'nin verdiği kullanıcı/kart tokenlarını, maskeli son dört haneyi ve gerekli durum bilgisini saklamalıdır. Bu, PayTR'nin tokenizasyon ve kart listeleme alanlarından çıkarılan güvenlik gereğidir. [Abonelik Yöntemi](https://www.paytr.com/abonelik-yontemi), [CAPI List](https://dev.paytr.com/direkt-api/kart-saklama-api/kayitli-kart-listesi)

### Non3D riski

PayTR'nin açık recurring servisi Non3D çalışır. PayTR destek merkezi, 3D'siz işlemde kartın izinsiz kullanımı dahil risklerin firmaya ait olduğunu ve Non3D için Mağaza Paneli Destek sayfasından talep açılması gerektiğini belirtiyor. [Recurring](https://dev.paytr.com/direkt-api/kart-saklama-api/kayitli-kart-tekrarlayan-odeme), [PayTR Ödemeler](https://www.paytr.com/destek-merkezi/odemeler)

Bu nedenle ilk ödeme/onay kaydı, otomatik yenileme izni, iptal zamanı ve her dönem tahsilat kaydı denetlenebilir biçimde tutulmalıdır. PayTR Abonelik Yöntemi ilk işlemde onay alındıktan sonra otomatik tahsilat yapıldığını belirtiyor. [Kaynak](https://www.paytr.com/abonelik-yontemi)

### TLS ve bağlantı doğrulaması

PayTR'nin örnek kodları, üretimde SSL sertifika doğrulamasının kapatılmaması gerektiğini özellikle belirtiyor. Vixrex'in PayTR'ye yaptığı sunucu isteklerinde TLS sertifika doğrulaması açık kalmalıdır. [Kaynak](https://dev.paytr.com/iade-api)

## 7. Vixrex için asgari ödeme durumları

En az şu durumlar ayrı tutulmalıdır:

- `pending_initial_payment`
- `active`
- `renewal_pending`
- `past_due`
- `suspended`
- `cancel_at_period_end`
- `cancelled`
- `refund_pending`
- `refunded`

Bu adlar PayTR alan adları değil, Vixrex ürün durumlarıdır. Ayrı tutulmaları; PayTR'nin `success` / `failed` / `wait_callback`, yeniden deneme/askıya alma, abonelik iptali ve tam/kısmi iade olaylarını birbirine karıştırmamak için önerilmiştir. [Recurring](https://dev.paytr.com/direkt-api/kart-saklama-api/kayitli-kart-tekrarlayan-odeme), [Abonelik Yöntemi](https://www.paytr.com/abonelik-yontemi), [İade API](https://dev.paytr.com/iade-api)

Ödeme kaydı ile vitrin yayını aynı kayıt olmamalıdır. Webhook yalnız ödeme/abonelik hakkını güncellemeli; vitrin içeriğini değiştirmemelidir. Aktif ödeme hakkı ile kullanıcının “Yayınla” tercihi ayrı denetlenmelidir. Bu, PayTR'nin ödeme sonucunu `merchant_oid` ile siparişe bağlayan modelinden çıkarılan Vixrex alan ayrımıdır. [Kaynak](https://dev.paytr.com/direkt-api/direkt-api-2-adim)

## 8. Uygulama öncesi kabul kapıları

Kodlama başlamadan önce:

- PayTR'nin hangi ürününün kullanılacağı yazılı olarak kesinleştirilmeli.
- İlgili ürün/yetkiler mağazada açık olmalı.
- Güncel komisyon ve tüm ek maliyetler panel/sözleşmeyle doğrulanmalı.
- PayTR'nin güncel özel Abonelik Yöntemi dokümanı arşivlenmeli.
- İptal zamanı, kullanım döneminin sonu, başarısız ödemede ek süre ve iade politikası ürün kararı olarak yazılmalı.

Test ortamında:

- İlk ödeme başarılı/başarısız akışları.
- Geçersiz webhook hash'i.
- Aynı `merchant_oid` için tekrarlayan webhook.
- Recurring için `success`, `wait_callback`, `failed + try_again=true/false`.
- Yenilemeden önce iptal.
- Kart güncelleme ve kart silme.
- Tam ve kısmi iade.
- Durum Sorgu ile ödeme/kesinti/iade mutabakatı.

PayTR, Direkt API testlerinin mağaza tarafından yürütüldüğünü; test kartlarını, test modunu, Bildirim URL'yi, İade API'yi ve Durum Sorgu API'yi ayrı ayrı belgeliyor. [Direkt API](https://dev.paytr.com/direkt-api), [Test kartları](https://dev.paytr.com/direkt-api/test-kart-bilgileri), [Bildirim URL](https://dev.paytr.com/direkt-api/direkt-api-2-adim), [İade API](https://dev.paytr.com/iade-api), [Durum Sorgu](https://dev.paytr.com/durum-sorgu)

Canlı açılış için yalnız “PayTR onay verdi” yeterli değildir. En az bir gerçek düşük tutarlı veya PayTR'nin onayladığı canlı test işlemi, doğrulanmış webhook, tek seferlik hak tanımlama, yenileme, iptal ve iade akışı uçtan uca kanıtlanmadan entegrasyon “canlıya hazır” sayılmamalıdır. Bu kontrol kapısı, PayTR'nin mağazaya bıraktığı entegrasyon/test sorumluluğu ve Bildirim URL'nin sipariş onayındaki belirleyici rolüne dayanır. [Direkt API](https://dev.paytr.com/direkt-api), [Bildirim URL](https://dev.paytr.com/direkt-api/direkt-api-2-adim)

## Sonuç

PayTR, Vixrex'in aylık 499 TL kiralık vitrin modelini destekleyecek resmî bir **Abonelik Yöntemi** sunuyor. Ancak mevcut bilgiyle yalnız mağaza başvurusunun onaylı olduğu kabul edilebilir; abonelik ürünü, Direct API, Kart Saklama ve Non3D yetkilerinin açıldığı veya entegrasyonun çalıştığı söylenemez.

En düşük operasyonel riskli yol:

1. PayTR'den Vixrex mağazasında Abonelik Yöntemi aktivasyonunu ve güncel özel dokümanı yazılı doğrulamak.
2. 499 TL/ay planını yönetilen abonelik ürünüyle kurmak.
3. Webhook doğrulanmadan vitrin hakkı açmamak.
4. PayTR komisyonunu güncel sözleşme/panelden doğrulamak; müşteriye “499 TL/ay” nihai fiyatını göstermek.
5. İptal, kart silme ve iadeyi ayrı işlemler olarak tasarlamak.
6. Direkt API + CAPI + Recurring yolunu yalnız yönetilen ürün kullanılamazsa, ek Non3D riski ve Vixrex'e geçen abonelik yaşam döngüsü sorumluluğu kabul edilerek seçmek.


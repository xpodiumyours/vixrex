# Kiralık Vitrin — 14 Günlük Ücretsiz Deneme Resmî Araştırması

**Tarih:** 29 Temmuz 2026  
**Kapsam:** PayTR Abonelik Yöntemi, Supabase Auth ve KVKK resmî kaynakları  
**İşlem sınırı:** Kod, veritabanı, Git, PayTR/Supabase paneli ve canlı sistem değiştirilmedi.

> Bu belge hukuki görüş değildir. Resmî ürün dokümanları ile mevzuat kaynaklarını teknik ürün kararlarına bağlayan bir araştırma notudur. “Çıkarım / ürün kararı” olarak işaretlenen maddeler PayTR veya Supabase’in hazır garantisi değil, Vixrex’in uygulaması gereken kurallardır.

## Kısa karar

1. **PayTR, yönetim panelinde “deneme süresi” içeren abonelik planları tanımlanabildiğini açıkça söylüyor.** Ancak kamuya açık sayfa denemenin kart alınmadan mı, kart alınıp ilk tahsilat ertelenerek mi başladığını; deneme süresi için API alanlarını; kart doğrulama/tahsilat zamanını açıklamıyor. Entegrasyon ayrıntılarının üyelik aktifleştirildikten sonra gönderilen özel dokümanlarla verildiğini belirtiyor. Bu nedenle kart gereksinimi veya “14 gün sonra otomatik çekim” davranışı bugün varsayılamaz. [PayTR Abonelik Yöntemi](https://www.paytr.com/abonelik-yontemi)

2. **PayTR bağlanana kadar 14 günlük deneme, ödeme aboneliği değil Vixrex’in kendi erişim yetkisi olmalıdır.** Bu süreçte kart istenmemeli, PayTR kaydı oluşturulmamalı, deneme sonunda otomatik tahsilat vaadi verilmemeli ve deneme hiçbir koşulda kendiliğinden ücretli üyeliğe dönüşmemelidir. Bu, PayTR’nin sağladığı bir davranış değil, **Vixrex’e özgü çıkarım / ürün kararıdır**.

3. **Deneme yalnız doğrulanmış, kalıcı bir Supabase kullanıcısına sunulmalıdır.** E-posta üyeliğinde `Confirm Email` açık olmalı; Google girişinde başarılı Supabase OAuth oturumu ve Google identity kaydı aranmalıdır. Supabase kullanıcı kimliği (`auth.users.id` / JWT `sub`) denemenin birincil anahtarı olmalıdır. Supabase’in e-posta doğrulaması ve Google OAuth’u bir kişinin “tek ve gerçek insan”, işletme sahibi veya daha önce hiç deneme kullanmamış olduğunu garanti etmez. [Supabase kullanıcı modeli](https://supabase.com/docs/guides/auth/users), [Google ile giriş](https://supabase.com/docs/guides/auth/social-login/auth-google)

4. **14 gün bitince veri silinmemeli; yayın hakkı kapatılmalıdır.** Vitrin, ürünler, tema, blog, Hakkımızda ve SSS içeriği taslak olarak korunur; müşteri linki yayından kaldırılır. Ücretli üyelik doğrulandığında aynı veri tekrar yayınlanabilir. Bu, **Vixrex’e özgü çıkarım / ürün kararıdır**. KVKK bakımından denemenin bitmesi tek başına tüm kişisel verilerin hemen silinmesi anlamına gelmez; fakat veriler ancak belirlenmiş amaç, hukuki sebep ve azami saklama süresi boyunca tutulabilir. İşleme şartlarının tamamı ortadan kalktığında silme, yok etme veya anonimleştirme gerekir. [KVKK Silme, Yok Etme veya Anonim Hale Getirme Yönetmeliği](https://www.kvkk.gov.tr/Icerik/5441/KISISEL-VERILERIN-SILINMESI-YOK-EDILMESI-VEYA-ANONIM-HALE-GETIRILMESI-HAKKINDA-YONETMELIK)

## 1. PayTR deneme süresi gerçekte ne sağlıyor?

### Resmî olarak doğrulananlar

- PayTR yönetim panelinde farklı fiyat ve ödeme periyotlarına sahip planlar ile **deneme süresi, indirimli dönem ve farklı hizmet paketleri için ayrı planlar** tanımlanabildiğini söylüyor. [PayTR Abonelik Yöntemi — plan özelleştirme](https://www.paytr.com/abonelik-yontemi)
- PayTR abonelik modelini kart saklama ve periyodik otomatik tahsilat olarak tanımlıyor. İlk ödeme işleminde kart bilgisinin güvenli tokena dönüştürüldüğünü; sonraki periyotlarda otomatik ödeme istendiğini; sonuçların webhook ile bildirildiğini belirtiyor. [PayTR Abonelik Yöntemi — çalışma biçimi](https://www.paytr.com/abonelik-yontemi)
- İlk ödeme işleminde müşterinin onayının alınması gerektiğini, sonrasında periyodik tahsilat yapıldığını; müşterinin aboneliği iptal edebildiğini veya kartını güncelleyebildiğini söylüyor. [PayTR Abonelik Yöntemi — müşteri onayı ve iptal](https://www.paytr.com/abonelik-yontemi)
- Başarısız tahsilatlarda otomatik yeniden deneme, bilgilendirme ve belirli sayıda başarısız denemeden sonra aboneliği askıya alma mekanizması olduğunu; ödeme tamamlanınca yeniden etkinleştirme yapılabildiğini belirtiyor. [PayTR Abonelik Yöntemi — başarısız ödeme](https://www.paytr.com/abonelik-yontemi)
- Entegrasyon dokümanları ve API bilgilerinin başvuru/aktivasyondan sonra mağazaya iletildiğini söylüyor. [PayTR Abonelik Yöntemi — başvuru ve entegrasyon](https://www.paytr.com/abonelik-yontemi)

### Kamuya açık kaynakta doğrulanamayanlar

PayTR’nin herkese açık sayfasında aşağıdakiler tanımlanmıyor:

- Denemenin başında kart zorunlu mu?
- İlk anda sıfır tutarlı veya doğrulama amaçlı bir işlem yapılıyor mu?
- İlk ücret tam olarak hangi olay ve zamanla tahsil ediliyor?
- Deneme planının API alanları, webhook olay adları ve idempotency kuralları neler?
- Yeniden deneme sayısı ve aralıkları nedir?
- PayTR’nin “askıya alındı” durumu ile Vixrex’in müşteri linkini ne zaman kapatması gerekir?

**Sonuç:** Bunlara cevap verilmeden “PayTR 14 gün kart istemeden ücretsiz deneme sağlar” veya “14 gün sonunda otomatik çeker” denilemez. PayTR’nin Vixrex mağazası için ilettiği özel Abonelik Yöntemi dokümanı ve test ortamı görülmeden bu davranışlar uygulama planına kesin kural olarak yazılmamalıdır.

## 2. PayTR bağlanana kadar ödeme almayan denemenin güvenli sınırı

Aşağıdaki bölümün tamamı **Vixrex’e özgü çıkarım / ürün kararıdır**:

1. Kullanıcı e-posta doğrulamasını veya Google OAuth girişini tamamlar.
2. Kullanıcı “14 günlük ücretsiz denemeyi başlat” eylemini açıkça gerçekleştirir. Hesap oluşturulması tek başına deneme saatini başlatmaz. Böylece e-posta teslim gecikmesi veya onboarding gecikmesi kullanıcının 14 gününden yemez.
3. Sunucu değiştirilemez bir `trial_started_at` ve `trial_ends_at` üretir. Süre istemci cihaz saatinden hesaplanmaz.
4. Deneme kaydı yalnızca Supabase’in doğrulanmış kanonik kullanıcı kimliğine bağlanır. İstemci deneme başlangıcı, bitişi veya statüsünü yazamaz.
5. Bu geçici sürümde kart alanı, PayTR tokenı, otomatik yenileme ve “14 gün sonra tahsil edilir” beyanı bulunmaz.
6. Deneme ekranında “kart gerekmez”, “otomatik ücretlendirme yoktur” ve kesin bitiş tarihi/saat dilimi açıkça gösterilir.
7. Deneme sonu yalnızca Vixrex yayın yetkisini değiştirir; bir ödeme işlemi başlatmaz.
8. PayTR etkinleştikten sonra ücretli üyelik, kullanıcı tarafından ayrıca başlatılan ve fiyat/yenileme koşulları gösterilen ayrı bir akış olur. Ücretli hak yalnız doğrulanmış PayTR durum bildirimiyle açılır.

Bu ayrım, sonradan PayTR eklendiğinde “eski deneme kayıtlarının yanlışlıkla ücretli aboneliğe dönüşmesi” riskini önler.

## 3. Supabase e-posta üyeliği neyi garanti eder?

### Resmî garanti

- `Confirm Email` açıksa kullanıcı ilk girişten önce e-posta adresini doğrulamalıdır. Kapalıysa Supabase doğrulama gerekmiyormuş gibi davranır ve adresi veritabanında örtük olarak doğrulanmış sayar. [Supabase Auth genel yapılandırma](https://supabase.com/docs/guides/auth/general-configuration)
- Flutter `signUp()` çağrısında `Confirm Email` açıkken kullanıcı nesnesi dönebilir fakat oturum `null` olur; doğrulama kapalıysa kullanıcı ve oturum birlikte döner. [Supabase Flutter `signUp`](https://supabase.com/docs/reference/dart/auth-signup)
- Kullanıcı nesnesinde `id`, `email`, `email_confirmed_at`, `confirmed_at`, `app_metadata`, `user_metadata`, `identities`, `created_at`, `updated_at` ve `is_anonymous` gibi alanlar bulunur. `email_confirmed_at` değeri `null` ise e-posta doğrulanmamıştır. [Supabase kullanıcı nesnesi](https://supabase.com/docs/guides/auth/users)
- Mevcut, doğrulanmış bir e-posta için yeniden `signUp()` çağrısı bazı ayarlarda sahte/örtük bir kullanıcı yanıtı döndürebilir. Bu, kullanıcı numaralandırma saldırısını azaltmak içindir. Dolayısıyla `signUp()` yanıtı “bu kişi ilk defa kayıt oldu ve denemeye hak kazandı” kanıtı değildir. [Supabase Flutter `signUp`](https://supabase.com/docs/reference/dart/auth-signup)
- Supabase’in varsayılan e-posta servisi üretim için tasarlanmamıştır; yalnız önceden yetkilendirilmiş takım adreslerine gönderim ve düşük/değişebilir limitler gibi kısıtları vardır. Gerçek kullanıcı doğrulama akışı için özel SMTP gerekir. [Supabase Custom SMTP](https://supabase.com/docs/guides/auth/auth-smtp)

### Garanti etmediği şeyler

Aşağıdakiler **çıkarımdır**:

- E-posta doğrulaması yalnız o posta kutusuna erişimi gösterir; kişinin hukuki kimliğini, işletme sahipliğini veya birden fazla e-posta kullanmadığını kanıtlamaz.
- Bir e-posta adresinin doğrulanması “bu insan daha önce başka hesapla deneme kullanmadı” garantisi değildir.
- Bu nedenle deneme hakkı `signUp()` başarısına veya e-posta metnine göre değil, sunucudaki ayrı entitlement kaydına göre verilmelidir.

## 4. Supabase Google OAuth neyi garanti eder?

### Resmî garanti ve veri alanları

- Supabase Google ile web, yerel uygulama ve Chrome uzantısı girişini destekler. Gerekli kapsamlar `openid`, `userinfo.email` ve `userinfo.profile` olarak belgelenmiştir. Bu kapsamlar Google hesap kimliği ile e-posta/profil bilgisinin OAuth akışında alınmasına izin verir. [Supabase Google ile giriş](https://supabase.com/docs/guides/auth/social-login/auth-google)
- Supabase identity nesnesi `provider_id`, `user_id`, `identity_data`, `id`, `provider`, isteğe bağlı `email` ve zaman damgalarını içerir. OAuth sağlayıcısında `provider_id`, sağlayıcıdaki hesabı; `identity_data`, sağlayıcıdan alınan kullanıcı verisini temsil eder. [Supabase identity nesnesi](https://supabase.com/docs/guides/auth/identities)
- Kullanıcı nesnesindeki `app_metadata.provider` ilk kayıt sağlayıcısını, `app_metadata.providers` kullanıcının giriş yapabildiği sağlayıcı listesini; `identities` ise bağlı kimlikleri gösterir. `user_metadata` kullanıcı tarafından değiştirilebildiğinden güvenlik/izin kararı için kullanılamaz. [Supabase kullanıcı nesnesi](https://supabase.com/docs/guides/auth/users)
- Supabase, aynı e-posta adresine sahip identity kayıtlarını otomatik olarak tek kullanıcıda bağlamaya çalışır; doğrulanmamış identity kayıtları için hesap ele geçirme riskine karşı ek önlem uygular. Aynı e-postayla önce OAuth, sonra e-posta hesabı açma girişiminde örtük yanıt verebilir. [Supabase identity linking](https://supabase.com/docs/guides/auth/auth-identity-linking)

### Garanti etmediği şeyler

Aşağıdakiler **çıkarımdır**:

- Google OAuth, kullanıcının bir Google hesabına başarıyla giriş yaptığını gösterir; tekil gerçek kişi, resmî kimlik, işletme yetkilisi veya tek deneme hakkı olduğunu kanıtlamaz.
- Aynı e-postanın otomatik bağlanması, e-posta ve Google ile aynı adres üzerinden çift deneme riskini azaltır; farklı Google hesapları, farklı e-posta adresleri veya takma adresler üzerinden tekrar denemeyi tek başına engellemez.
- Deneme hakkı sağlayıcıya veya e-posta metnine değil, kanonik Supabase `user.id` / JWT `sub` değerine bağlanmalıdır.

## 5. Kimlik ve entitlement sınırı

### Resmî teknik dayanak

- Supabase JWT içindeki `sub` alanını kullanıcı UUID’si olarak tanımlar; `role`, `session_id`, `email`, `is_anonymous`, `app_metadata` ve `user_metadata` gibi claim’ler de belgelenmiştir. [Supabase JWT claim referansı](https://supabase.com/docs/guides/auth/jwt-fields)
- Sunucuda `getUser()` Auth sunucusuna istek yaptığı için dönen değer doğrulanmış kabul edilip yetkilendirme kararında kullanılabilir. Buna karşılık istemci saklama alanı veya çerezden okunan `getSession()` verisi sunucu tarafında özgün olmayabilir ve yetkilendirme temeli yapılmamalıdır. [Supabase `getUser`](https://supabase.com/docs/reference/javascript/auth-getuser), [Supabase `getSession`](https://supabase.com/docs/reference/javascript/auth-getsession)
- RLS dokümanı, son kullanıcının değiştirebildiği `user_metadata` alanının yetkilendirme için kullanılmamasını söyler. `app_metadata` kullanıcı tarafından değiştirilemez; ancak JWT yenilenene kadar eski kalabilir. Service/secret anahtarları RLS’yi aşabildiği için tarayıcıda veya müşteriye açık istemcide bulunmamalıdır. [Supabase RLS](https://supabase.com/docs/guides/database/postgres/row-level-security)

### Vixrex için önerilen kural — çıkarım / ürün kararı

Entitlement, kullanıcı profilinden ve vitrin içeriğinden ayrı, sunucu kontrollü bir kayıt olmalıdır. Asgari mantıksal alanlar:

- `user_id`: kanonik Supabase kullanıcı UUID’si
- `plan_code`: ör. `rental_trial_14d`, `rental_monthly`
- `status`: `trial_active`, `trial_expired`, `checkout_pending`, `paid_active`, `past_due`, `suspended`, `cancelled`
- `trial_started_at`, `trial_ends_at`, `trial_consumed_at`
- `paid_through_at`
- `paytr_subscription_ref` veya eşdeğer sağlayıcı referansı
- `last_verified_payment_event_at`
- durum değişikliği için denetim kaydı

Koruma sınırları:

- Aynı `user_id` için 14 günlük deneme hakkı yalnız bir kez üretilir; hesabı çıkış yapıp tekrar açmak yeni deneme oluşturmaz.
- `trial_consumed_at` kullanıcı profilinde veya `user_metadata` içinde değil, istemcinin yazamadığı sunucu kontrollü kayıtta tutulur.
- Yayınlama işlemi yalnız ekranın gösterdiği statüye değil, her kritik sunucu işleminde güncel entitlement kaydına bakar.
- Yetki değişikliği JWT içine konulsa bile JWT’nin eski kalabileceği hesaba katılır; yayın açma/kapatma gibi kritik kararlar güncel sunucu kaydından doğrulanır.
- Deneme hakları anonymous kullanıcıya verilmez; Supabase anonymous kullanıcıları kimliğe bağlı olmadığından aynı kişi olarak tekrar giriş garantisi sunmaz. [Supabase kalıcı ve anonim kullanıcılar](https://supabase.com/docs/guides/auth/users)

## 6. Deneme suistimalini önleme — ne Supabase’in işi, ne Vixrex’in işi?

Supabase Auth kimlik doğrulama, aynı e-postalı identity linking, auth endpoint rate limitleri ve CAPTCHA desteği sağlar. Auth rate limitleri kötüye kullanımı azaltır; CAPTCHA giriş/kayıt/şifre sıfırlama formlarında bot ve kötü amaçlı scriptlere karşı kullanılabilir. [Supabase rate limits](https://supabase.com/docs/guides/auth/rate-limits), [Supabase CAPTCHA](https://supabase.com/docs/guides/auth/auth-captcha)

Ancak “bir gerçek kişi yalnız bir kez 14 gün kullanabilir” iş kuralını Supabase hazır olarak sağlamaz. Aşağıdaki katmanlar **Vixrex’e özgü çıkarım / ürün kararıdır**:

1. **Birincil sınır:** Doğrulanmış Supabase kullanıcı UUID’si başına tek deneme.
2. **Bot sınırı:** Kayıt ve girişte Supabase rate limitleri; risk yükselirse CAPTCHA.
3. **Davranış sınırı:** Çok kısa sürede çok sayıda hesap/vitrin/yayın denemesi için sunucu taraflı hız sınırı ve manuel inceleme.
4. **İkincil kimlik sınırı:** Telefon veya işletme doğrulaması ancak ölçülen suistimal bunu gerçekten gerektiriyorsa ve hukuki/ürün kararı verildiyse eklenmeli.
5. **Cihaz/IP sınırı:** IP veya cihaz sinyali tek başına “aynı kişi” kararı olmamalı; ortak ağ, aile cihazı, VPN ve değişken IP nedeniyle yanlış engelleme yaratabilir. Bu sinyaller kullanılacaksa yalnız risk işareti olmalı.

KVKK Kurulu bir kararında IP adresini açıkça kişisel veri olarak nitelendiriyor. Kişisel veri işleme faaliyetleri belirli, açık ve meşru amaçla; amaçla bağlantılı, sınırlı ve ölçülü yürütülmeli ve gerekli süre kadar saklanmalıdır. Bu nedenle gizli ve süresiz cihaz parmak izi/IP profili varsayılan çözüm olmamalıdır. [KVKK e-ticaret ve çerez kararı 2022/229](https://www.kvkk.gov.tr/Icerik/7275/2022-229), [KVKK temel ilkeler](https://www.kvkk.gov.tr/Icerik/6721/KAMUOYU-DUYURUSU-Covid-19-ile-Mucadele-Surecinde-Kisisel-Verilerin-Korunmasi-Kanunu-Kapsaminda-Bilinmesi-Gerekenler-)

## 7. 14 gün sonunda veri silmeden yayın durdurma modeli

Aşağıdaki durum makinesi **Vixrex’e özgü çıkarım / ürün kararıdır**:

```text
trial_active
  ├─ süre doldu ───────────────> trial_expired
  └─ kullanıcı ödeme başlattı ─> checkout_pending

checkout_pending
  ├─ doğrulanmış başarılı olay ─> paid_active
  └─ başarısız/terk edildi ─────> trial_active veya trial_expired
                                  (sunucu saatine göre)

paid_active
  ├─ dönem ödemesi başarısız ───> past_due
  └─ dönem sonunda iptal ───────> suspended

past_due
  ├─ ödeme kurtarıldı ──────────> paid_active
  └─ tanımlı politika/PayTR askı> suspended

trial_expired veya suspended
  └─ ödeme doğrulandı ──────────> paid_active
```

### Ayrı tutulması gereken üç durum

- **Ödeme durumu:** deneme, aktif ücretli, gecikmiş, iptal, askıda
- **Yayın durumu:** taslak, yayında, entitlement nedeniyle yayından kaldırılmış
- **Veri saklama durumu:** aktif veri, saklama süresinde kısıtlı veri, silme/anonimleştirme bekliyor

Bu ayrım sayesinde “ödeme yok” olayı “veriyi sil” komutuna dönüşmez.

### 14 gün dolduğunda

- Sunucu `trial_ends_at` zamanını geçtiğinde yeni bir ödeme başlatmaz.
- Müşteri linki için yayın yetkisi kapanır; vitrin keşfet ve herkese açık müşteri rotasında aktif görünmez.
- Vitrin içeriği ve medya silinmez; kullanıcı hesabında korunur.
- Yeniden ödeme doğrulanırsa aynı içerik yeniden yayınlanabilir.
- Deneme sonrasında editörün salt okunur kalması mı, düzenlemeye izin verip yalnız yayını mı engellemesi gerektiği ayrıca ürün kararıdır. Güvenlik sınırı, ödeme hakkı yokken herkese açık yayın yapılamamasıdır.

### Ücretli yenileme başarısız olduğunda

PayTR resmî sayfası yeniden deneme yapıldığını, belirli sayıda başarısız denemeden sonra aboneliğin askıya alındığını ve sonuçların webhook ile iletildiğini söylüyor. Fakat yeniden deneme sayısı/aralığı kamuya açık değildir. [PayTR başarısız ödeme ve webhook](https://www.paytr.com/abonelik-yontemi)

Bu nedenle:

- Tek bir istemci dönüşü veya tek başarısız ağ yanıtı kalıcı askı kararı olmamalıdır.
- Vixrex `past_due` durumunu ayrı tutmalı; PayTR’nin doğrulanmış olaylarını işlemelidir.
- Kullanıcının önceden ödediği dönem bitmeden erişim kesilip kesilmeyeceği sözleşme ve ürün politikasına göre kararlaştırılmalıdır.
- Ek bir Vixrex tolerans süresi verilecekse süresi ve başlangıç olayı açıkça kararlaştırılmalı; bu araştırma rastgele gün sayısı varsaymaz.
- Nihai askıda yayın kapanır, veri silinmez; ödeme kurtarılırsa yeniden açılır.

## 8. KVKK koruma sınırları

- Kişisel veriler elde edilirken veri sorumlusunun kimliği, işleme amacı, aktarılabilecek alıcılar ve amaçları, toplama yöntemi ve hukuki sebep ile ilgili kişi hakları açıklanmalıdır. Aydınlatma, açık rızadan veya başka bir işleme şartından bağımsız bir yükümlülüktür. [KVKK Aydınlatma Yükümlülüğü](https://www.kvkk.gov.tr/Icerik/2033/Aydinlatma-Yukumlulugu-), [Aydınlatma Tebliği](https://www.kvkk.gov.tr/Icerik/4132/aydinlatma-yukumlulugunun-yerine-getirilmesinde-uyulacak-usul-ve-esaslar-hakkinda-teblig)
- Deneme suistimali önleme amacıyla IP, çerez veya başka sinyal işlenecekse hangi veri, hangi amaç, hangi hukuki sebep ve ne kadar süreyle tutulduğu açıkça belirlenmelidir. Kesinlikle gerekli olmayan çerezler bakımından uygun işleme şartı ve gerektiğinde aktif `opt-in` mekanizması aranmalıdır. [KVKK Çerez Uygulamaları Rehberi](https://www.kvkk.gov.tr/Icerik/7353/Cerez-Uygulamalari-Hakkinda-Rehber), [KVKK 2022/229 kararı](https://www.kvkk.gov.tr/Icerik/7275/2022-229)
- Saklama politikasında veri kategorisi, amaç/hukuki sebep, azami saklama süresi, teknik-idari tedbirler ve imha yöntemi tanımlanmalıdır. İşleme şartlarının tamamı ortadan kalktığında silme, yok etme veya anonimleştirme gerekir. [KVKK Silme, Yok Etme veya Anonim Hale Getirme Yönetmeliği](https://www.kvkk.gov.tr/Icerik/5441/KISISEL-VERILERIN-SILINMESI-YOK-EDILMESI-VEYA-ANONIM-HALE-GETIRILMESI-HAKKINDA-YONETMELIK)
- Trial bitişi ile kişisel veri saklama süresinin bitişi aynı teknik olay değildir. **Çıkarım:** yayın hakkı anında kapanabilir; hesap/vitrin verisi ise belirlenmiş saklama ve imha politikasına göre kısıtlanır, sonra silinir veya anonimleştirilir.

## 9. Uygulamaya geçmeden önce cevaplanması gereken önemli kararlar

1. **Deneme başlangıcı:** Hesap doğrulanınca otomatik mi, kullanıcının açık “denemeyi başlat” eyleminde mi? Öneri: açık eylem.
2. **Tek deneme tanımı:** Yalnız `user_id` başına mı; doğrulanmış telefon veya işletme kimliği daha sonra gerekli olacak mı?
3. **Deneme bitişi:** Editör salt okunur mu olacak, yoksa düzenleme açık kalıp yalnız yayın mı kapanacak?
4. **Vitrin görünürlüğü:** Süresi dolan vitrin Keşfet’ten tamamen kalkacak mı, yoksa kullanıcıya özel yönetim ekranında “yayın durduruldu” olarak mı kalacak? Öneri: herkese açık yüzeylerden kalksın, sahibinin panelinde kalsın.
5. **Ücretli başarısız ödeme:** PayTR’nin askı olayına ek Vixrex tolerans süresi olacak mı? Süre ve hangi olaydan başladığı açıkça belirlenmeli.
6. **PayTR deneme semantiği:** Kart deneme başında mı alınacak, ilk ödeme ne zaman ve hangi webhook ile kesinleşecek? Yalnız PayTR’nin mağazaya özel dokümanı/testi cevaplayabilir.
7. **Saklama ve imha:** Süresi bitmiş deneme hesabı/vitrin/medya/audit kayıtlarının her biri için amaç, hukuki sebep ve azami saklama süresi nedir?
8. **Kötüye kullanım eşiği:** CAPTCHA, telefon doğrulaması veya ikincil risk sinyalleri hangi ölçülmüş suistimal seviyesinde devreye girecek?

## Sonuç

14 günlük ücretsiz deneme bugün PayTR beklenmeden güvenle tasarlanabilir; fakat bu, ödeme sistemi değil **kimlik doğrulanmış kullanıcıya verilen süreli Vixrex yayın entitlement’ı** olmalıdır. En güvenli ilk sürüm; kart istemeyen, otomatik tahsilat yapmayan, sunucu saatli, kullanıcı başına tek denemeli ve süresi dolunca yalnız yayın hakkını kapatan modeldir.

PayTR entegrasyonu geldiğinde bu geçici deneme kaydı otomatik olarak ödeme aboneliğine çevrilmemeli; kullanıcı ayrı bir ücretli üyelik işlemi başlatmalı ve `paid_active` hakkı yalnız doğrulanmış PayTR bildirimiyle verilmelidir. PayTR’nin kart/deneme/ilk tahsilat ayrıntıları özel entegrasyon dokümanı ve test sonucu görülmeden kesin kabul edilmemelidir.

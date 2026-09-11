# Vixrex sahiplik ve konuşarak özelleştirme değerlendirmesi

## Güncelleme — 11 Eylül 2026 (kod geçmişinden doğrulandı)

Aşağıdaki ana rapor 9 Eylül 2026 tarihlidir. O tarihten sonra koddaki
kayıtlara göre rapordaki kritik bulguların çoğu kapatıldı:

- Çok günlük çalışma saatleri kaybolmuyor: hafta içi, cumartesi, pazar
ayrı ayrı korunuyor. Kaynak: 9 Eylül kaydı
`fix(asistan): çok günlük çalışma saatlerini kayıpsız ayır`
ve `serbest-metin-cikarim.test.ts` içindeki "çok günlü saatler" testleri.
- Seçili alanın dışına yanlış yazma engellendi: zengin bir cümle
yazılınca ham metin kutuya yapışmıyor, önce soruluyor. Kaynak: 3 Eylül
kaydı `fix(sahiplik): secili alana zengin cumle yazilinca baska
alanlarin bilgisi yapismasin` ve
`serbest-anlatim-mevcut-kutuya-katildi.test.ts`.
- Gerçek son işlem geri alma eklendi ve komut kimliğine bağlandı.
Kaynak: 9 Eylül kayıtları `feat(asistan): gerçek son işlem geri alma
API kapısını ekle` + `fix(asistan): geri almayı command kimliğine
bağla` ve `owner-assistant-real-undo-contract.test.ts`.
- Sahiplik ekranı masaüstünde çubuk ve yerleşik asistan sütununa geçti,
sohbete yalnız yapılan işin raporu yazılıyor. Kaynak: Eylül kayıtları
`feat(sahiplik): masaustunde editor kabugu` ve `sahiplik-editor-kabugu.test.ts`.

Hâlâ açık kalanlar: PayTR ödemesi gerçek parayla denenmedi
(`public_web/src/lib/paytr.ts` başındaki DOĞRULANACAK notu duruyor),
müşteri sayfasının yayına çıkışı bu raporda kanıtlanmadı, 5-8 esnafla
kabul çalışması yapılmadı.

9 Eylül 2026. Hedef: Teknik bilgisi olmayan esnafın hazır vitrini kendi işletmesine uyarlaması. İncelenen canlı yüzey: Next.js /v/kiralik-kafe ve yayınlanmamış kontrol taslağı /v/kiralik-kafe-6978131e.

## Karar ve yöntem

**Uzman değerlendirmesi: 50/100.** Bu bir kullanıcı araştırmasından çıkan başarı oranı değildir. Gözlenen deneyimin hedefe uygunluğuna ilişkin ağırlıklı değerlendirmedir. Hazır vitrinin görsel ve içerik kapasitesi, onu konuşarak güvenilir biçimde özelleştirme deneyiminden daha güçlüdür. 46 alanın varlığı tek başına web sitesi kalitesini veya konuşmayla tamamlanabilirliği ölçmez.

Canlı tarayıcıda masaüstü ve 390×844 dar ekran, alan seçme, metin gönderme, sayfa yenileme, SSS düzenleyicisini açma incelendi. Kaynak kod, üretim veritabanındaki yalnız kontrol taslağının alanları ve mevcut altı test dosyası kontrol edildi. 45 test geçti. Gerçek esnaf katılımı, fiziksel telefon/klavye, ekran okuyucu, performans ölçümü, APK, ödeme ve yeni bir vitrini canlı yayınlama yapılmadı. Bunlara geçer puan verilmedi; doğrulanmamış olmaları arıza olarak sunulmadı.

## Puanlama

| Boyut | Puan | Kesintinin gerekçesi |
|---|---:|---|
| Vitrinin görsel ve içerik kapasitesi | 12/15 | Görsel hiyerarşi, ürünler, galeri, SSS, iletişim ve yazılar mevcut. Buna karşılık kapasitenin esnafa ait içerikle tamamlandığını gösteren bir kalite denetimi yok; dolu örnek içerik hazır kabul ediliyor. |
| 46 alanın kapsamı ve anlamı | 9/15 | Ortak şema güçlü. Ürün, galeri ve SSS gerçek içerikleri bu sayının dışında; başlıklar ve teknik konum alanları aynı envanterde. |
| Konuşmayı güvenilir anlama | 5/15 | Kısa işletme adı kaydedildi. Çok bilgili doğal isim cümlesi reddedildi; çalışma saatleri adresi değiştirdi ve yalnız ilk saat aralığı saklandı. |
| Masaüstü yerleşimi ve odak | 6/15 | Vitrine tıklama ve sabit giriş iyi. Sağ panel, alan balonu, sıradaki alanlar ve hesap bağlama aynı anda yarışıyor; panel vitrinin üstüne biniyor. |
| Dar ekran deneyimi | 4/10 | Tek giriş ve geçmiş kontrolü var. Asistan ekranın çoğunu kaplıyor; değişikliğin kendisini aynı anda değerlendirmek zor. “Şimdi İl” ile WhatsApp giriş sorusu çelişiyor. |
| İlerleme ve durum doğruluğu | 3/10 | Taslak uyarısı açık. Yüzde, kaliteyi değil dolu/atlanmış alanları sayıyor; yanlış adres de ilerleme sayılıyor. |
| Kayıt, geri dönüş ve güven | 6/10 | Taslak kalıcılığı gözlendi. Ancak çapraz alan yazımı var; “canlı hâline döndür” son işlem öncesine dönmekle aynı değil. |
| İçerik düzenlemeyi bulma ve sade dil | 5/10 | SSS, galeri gibi editörler var; ek açılımların arkasında. Hero, enlem/boylam, üst başlık gibi kavramlar esnafın işiyle doğrudan örtüşmüyor. |
| **Toplam** | **50/100** | **Kesintiler gözlenen örnekler ve kodda doğrulanan davranışlarla sınırlıdır.** |

## İncelenen adımlar

1. Sahiplik taslağını açma: İyi. Taslak uyarısı, içerik ve asistan erişilebilir. Bu audit önceki kontrolde oluşturulan taslağı yeniden açtı; kiralama tıklaması bu audit içinde tekrar edilmedi.
2. Masaüstü rehberi: Zayıf. Seçili alan balonu ve sağ panel birlikte görünür; soru/giriş ve “Şimdi” listesi farklı alanları gösterebilir.
3. İşletme adıyla konuşma: Kısmi. Doğal çoklu cümle reddedildi, kısa ad kaydedildi.
4. WhatsApp kullanmama cevabı: Zayıf. İhtiyaç açıklaması yerine telefon biçimi hatası verildi. WhatsApp'ın zorunlu oluşu mevcut ürün kuralıdır; bunun bütün esnafı kapsayıp kapsamadığı ürün kararıdır.
5. Dar ekran: Zayıf. Asistan açıkken vitrin çıktısı büyük ölçüde kapanıyor. Fiziksel telefon klavyesi test edilmedi.
6. Çalışma saatleri: Başarısız. İkinci saat aralığı adrese yazıldı; veritabanında doğrulandı.
7. SSS düzenleyicisi: Erişilebilir. Tüm alanlar → Sık Sorulan Sorular ile açıldı; soru/cevap girdileri, ekleme ve kaydetme mevcut. Bu audit SSS kaydı yapmadı.
8. Ziyaretçi şablonu: Görsel ve içerik bakımından güçlü. Menü, kampanya, galeri, yazılar, SSS ve iletişim mevcut. Bu, özelleştirilen taslağın yayına çıktığını kanıtlamaz.

## Ekran kanıtları

### Masaüstü

![Masaüstünde asistan ve alan rehberi](01-desktop.png)

Sağ panel yaklaşık ekranın üçte birini kaplıyor; ayrıca alanın yanında ikinci bir yardım yüzeyi açılıyor. Esnafın bakışı vitrin, balon, sonraki işler ve giriş arasında bölünüyor. Panelin varlığı yararlı; sorun, vitrine ayrılmış alan yerine üstüne yerleşmesi ve aynı talimatın birden fazla yerde gösterilmesi.

### Dar ekran

![390 piksel genişlikte asistan](02-mobile.png)

“Şimdi İl” görünürken giriş WhatsApp istiyor. Bu yalnız görsel tercih değil, görev yönlendirmesi çelişkisi. Üstte hesap bağlama, ortada iş listesi ve mesaj, altta kayıt, onay, yayın ve değişiklikleri bırak kontrolleri aynı görünümde. Fiziksel klavye açıldığındaki sonuç bu ekran görüntüsünden çıkarılamaz.

### Çalışma saatleri hatası

![Saat bilgisinin adresin üzerine yazılması](03-hours.png)

### SSS düzenleme

![SSS editörü](04-faq-editor.png)

### Ziyaretçinin gördüğü şablon

![Ziyaretçi görünümü](05-public-template.png)

## 46 alanın tamamı

Kaynak: public_web/src/lib/vitrinFieldSchema.ts. Z = zorunlu, K = kalite işaretli, İ = isteğe bağlı. Toplam 6 zorunlu, 8 kalite, 32 isteğe bağlı alan. Otomatik doldurulabilir işareti 14 alanda var; bu, hepsinin her seferinde doldurulduğu anlamına gelmez.

| No | Alan | Tür | Katkı / daha verimli sunum |
|---:|---|:---:|---|
| 1 | İşletme Adı | Z | Kimlik. Doğrudan sorulmalı. |
| 2 | Hero Rozet Metni | K | Kısa farklılık cümlesi. “Seni öne çıkaran özellik” denmeli. |
| 3 | Kısa Tanıtım | İ | Ne sunduğunu anlatır; web sitesi kalitesinde temel içeriklerden biri. |
| 4 | Hero Konum Metni | İ | İl/ilçeden türetilmeli; ayrı yazdırmak çoğunlukla gereksiz. |
| 5 | İşletme Kategorisi | Z | Sektör seçimi; şablondan önerilip doğrulatılabilir. |
| 6 | İşletme Türü | İ | Alt uzmanlık. Kategoriyle birlikte tek konuşmada alınabilir. |
| 7 | Logo | K | Marka tanınması; fotoğraf/dosya seçimi gerekir. |
| 8 | Kapak / Hero Görseli | K | İlk izlenim; “Kapak fotoğrafı” yeterli. |
| 9 | Değerlendirme Puanını Göster | İ | Yalnız gerçek değerlendirme varsa anlamlı. |
| 10 | WhatsApp Numarası | Z | Dönüşüm kanalı; kullanmayan işletme için mevcut kural yolu kapatıyor. |
| 11 | Telefon | İ | Arama kanalı. Aynı numarayı yeniden yazdırmadan seçim sunulmalı. |
| 12 | E-posta | İ | Teklif ve kurumsal iletişim. |
| 13 | Açık Adres | Z | Ulaşım. Saat veya kullanıcı adıyla değişmemeli. |
| 14 | İl | Z | Konumun parçası; adres konuşmasıyla birlikte. |
| 15 | İlçe | Z | Konumun parçası; il ile ilişkili seçenek. |
| 16 | Mahalle | K | Yerel tanım; konum kartının içinde. |
| 17 | Harita Kartı Etiketi | İ | “Dükkânı bulmak için tarifin var mı?” olarak sorulabilir. |
| 18 | Çalışma Saatleri | K | Gün bazında doğru açık/kapalı bilgisi gerekir. |
| 19 | Instagram Kullanıcı Adı | İ | Sosyal kanıt; alan seçiliyken geçerli kullanıcı adı doğrudan alınmalı. |
| 20 | Web Sitesi | İ | Mevcut başka siteye bağlantı; çoğu yeni esnafa ilk aşamada sorulmamalı. |
| 21 | Google İşletme / Harita Bağlantısı | K | Harita kaydı; konum adımıyla birleştirilmeli. |
| 22 | Konum — Enlem | İ | Teknik veri; varsayılan konuşmanın dışında tutulmalı. |
| 23 | Konum — Boylam | İ | Haritada nokta seçimiyle doldurulmalı. |
| 24 | Yol Tarifi Butonunu Göster | İ | Fiziksel mekân/uzaktan hizmet tercihinden türetilebilir. |
| 25 | Kategori Bölümü Başlığı | İ | Kozmetik; “Menü” gibi sektör varsayılanı yeterli. |
| 26 | Ürün Bölümü Başlığı | İ | Ürünün kendisi değildir; ilk kurulumda sormaya gerek yok. |
| 27 | Kampanya Etiketi | İ | Kampanya varsa anlamlı. |
| 28 | Kampanya Başlığı | İ | Teklifin özeti; kampanya konuşmasının parçası. |
| 29 | Kampanya Açıklaması | İ | Teklif koşulları; kullanıcıdan alınmalı. |
| 30 | Kampanya Görseli | İ | Teklif fotoğrafı. |
| 31 | Kampanya Fiyat Metni | İ | Gerçek fiyat; uydurulmamalı. |
| 32 | Hakkımızda Üst Başlık | İ | Kozmetik; varsayılan yeterli. |
| 33 | Hakkımızda Başlığı | K | Güven ve farklılık; işletme bilgilerine dayanmalı. |
| 34 | Hakkımızda Yazısı | K | İşletmenin gerçek hikâyesi; şablon doluluğu kişiselleştirme değildir. |
| 35 | Hakkımızda Görseli | İ | Gerçek ekip/mekân fotoğrafı güveni artırır. |
| 36 | Görsel Alt Yazısı | İ | Fotoğrafın bağlamı; fotoğraf adımında alınabilir. |
| 37 | Referanslar Bağlantısı | İ | Referansı olan işletmede anlamlı. |
| 38 | Galeri Üst Başlık | İ | Kozmetik. |
| 39 | Galeri Başlığı | İ | Kozmetik; galeri fotoğraflarını içermez. |
| 40 | Galeri Buton Metni | İ | Eylem açıklaması; bağlantıyla birlikte alınmalı. |
| 41 | Galeri Buton Bağlantısı | İ | Hedef varsa gösterilmeli. |
| 42 | Blog Üst Başlık | İ | Kozmetik; blog yazısı değildir. |
| 43 | Blog Bölüm Başlığı | İ | Kozmetik; yazı yoksa ilk kurulumda sorulmamalı. |
| 44 | SSS Üst Başlık | İ | Kozmetik. |
| 45 | SSS Bölüm Başlığı | İ | Kozmetik; soruların kendisi değildir. |
| 46 | SSS Bölüm Açıklaması | İ | Açıklama; soru/cevap içerikleri ayrıca düzenlenir. |

Bu düzenleme alanları, küçük işletme için zengin bir vitrin sunmaya yeterli bir temel oluşturuyor. Ancak 46/46 dolu olması; gerçek ürünlerin, doğru fiyatların, işletme fotoğraflarının, yararlı SSS'nin, erişilebilirliğin, hızın veya başarılı yayının kanıtı değildir. Ürün/fiyat, fotoğraf ve soru-cevap gibi müşteri kararını etkileyen içerikler kalite değerlendirmesine ayrıca katılmalı.

## Canlı konuşma denemeleri

| Bağlam | Yazılan | Gözlenen sonuç |
|---|---|---|
| İşletme Adı seçili | İşletmemin adı Deneme Kahve. İstanbul Kadıköy’deyiz. | “Birden fazla bilgi” yanıtı; isim kaydedilmedi. Son kontrolde il/ilçe de null. |
| İşletme Adı seçili | Deneme Kahve | Kaydedildi, başlık değişti; sonraki sayfa açılışında korundu. |
| WhatsApp seçili | WhatsApp kullanmıyorum, müşteriler beni telefonla arasın. | “Geçerli bir Türkiye cep telefonu olmalı.” Kullanıcının açıklamasına uygun yol sunulmadı. |
| Çalışma Saatleri seçili | Hafta içi 09:00-18:00, cumartesi 10:00-16:00, pazar kapalı. | working_hours = 09:00 - 18:00; address = cumartesi 10:00-16:00. Veritabanından doğrulandı. |

Son örnek iki farklı kusur içeriyor: seçili alanın dışına yanlış yazma ve çok günlük saat bilgisinin kaybı. Önceki konuşmadaki Instagram denemesini bu audit puanının bağımsız kanıtı olarak kullanmak gerekmiyor; saat örneği aynı sorunu bu incelemede yeniden üretti.

## Teknik nedenler

- useOwnerActions.ts: 15 karakterden uzun seçili alan cevapları temizlenmisSeciliDeger üzerinden ayrıştırılıyor. Ek alanlar bonusAlanlariCikarVeKaydet ile ayrı isteklerle kaydediliyor. Bu yol öneri üretmekle yetinmiyor, gerçek taslağı değiştiriyor.
- addressValidator.ts: En az 10 karakter ve herhangi bir rakam VEYA yer belirteci, adresi geçerli sayabiliyor. Bu, “cumartesi 10:00-16:00” gibi metinleri adres sanmaya elverişli.
- workingHours.ts: findTimeRange yalnız ilk saat aralığını buluyor. weekMapFromPlainString bu aralığı pazartesi-cumartesiye yayarak pazar kapalı varsayıyor. Haftanın gerçek dağılımı ayrı yapı olarak tutulmalı.
- UpNextList.tsx: Sonraki alanların ilkine “ŞİMDİ” deniyor. vitr inReadiness içindeki sonrakiRehberAlanlar seçili alanı özellikle dışarıda bırakıyor. Dolayısıyla mevcut soru ile “Şimdi” başka alan olabiliyor.
- vitrinReadiness.ts: Dolu veya isteğe bağlı olarak atlanmış alan / 46 yüzdesi hesaplanıyor. İşletmeye özel doğrulama veya içerik kalitesi puanı değil.
- useFieldRestore.ts: “Geri al” yolu canlı/kök kayıttaki değere dönüyor. Son düzenlemeden hemen önceki taslak değerini geri getiren işlem geçmişiyle aynı davranış değil.
- SSS ve galeri editörleri mevcut. “Konuşarak tüm içerik” vaadi için bunların yetenekleri asistanın mevcut konuşma akışına bağlanmalı; yeniden bir yönetim ekranı icat etmek gerekmiyor.

## En verimli, üretken yapay zekâ gerektirmeyen çözüm

Mevcut düzenleme yolu zaten sözlük, kurallar, alan şeması ve doğrulayıcılarla çalışıyor. İncelenen konuşma yolunda LLM çağrısı bulunmadı. Bütün ürünün hiçbir yerinde yapay zekâ yok iddiasında bulunulmuyor.

Önerilen işlem sırası: **cevap → alan adayları → doğrulama → gerekiyorsa kısa özet → tek kayıt → görünür sonuç → son işlemi geri al.**

1. Seçili alan varsa önce o alanın türüne göre cevap işle. Instagram alanındaki geçerli kullanıcı adını genel adres çıkarıcısına gönderme. Açık bir başka alan komutu yoksa başka kolon yazma.
2. Birden çok bilgi varsa taslağa doğrudan yazma. “Ad: Deneme Kahve; İl: İstanbul; İlçe: Kadıköy. Böyle kaydedeyim mi?” kartı göster. Esnaf tek dokunuşla onaylayabilsin. Her basit alan cevabına fazladan onay ekleme.
3. Anlam belirsizse tek netleştirme sorusu sor. “09:00-18:00 hangi günlerde?” gibi; “birden fazla bilgi var” diyerek tüm cümleyi tekrar yazdırma.
4. Bir cevapla gelen değişiklikleri tek işlem olarak kaydet. Her kolonu ayrı ve kontrolsüz kaydetmek kısmi sonuç ve yarış riski yaratır. Önceki taslak değerlerini sakla; geri al yalnız son işlemi tersine çevirsin.
5. Saatleri yedi günlük yapı olarak sakla. Gün adları, hafta içi, hafta sonu, her gün, kapalı ve istisna kurallarını ayrı işle. Çelişki varsa kullanıcıya göster.
6. Konuşma eylemlerini açık bir listeye bağla: ad değiştir, iletişim güncelle, saat düzenle, ürün ekle/fiyat değiştir, fotoğraf ekle, SSS düzenle, bölüm gizle, önizle, geri al. Bilinmeyen komutta ilgili birkaç seçenek sun.
7. Yeni teknik katmanlar yerine mevcut şema ve düzenleyicileri kullan. Alan başına Türkçe soru, örnek cevap, kabul edilen biçim ve hata mesajı aynı kaynaktan gelsin.

## Esnafla nasıl konuşmalı?

Aşağıdaki diyaloglar önerilen davranıştır; mevcut ürünün başarılı çıktısı olarak sunulmuyor.

| Amaç | Asistanın sorusu | Örnek cevap | Sistem ne yapmalı? |
|---|---|---|---|
| Kimlik | Dükkânının adı ne? | Deneme Kahve | Adı değiştir; vitrinde vurgula. |
| Konum | Hangi il ve ilçedesin? | İstanbul Kadıköy | İkisini tek seferde çöz, eşleşme belirsizse seçenek sun. |
| İletişim | Müşteriler sana nasıl ulaşsın? | Telefonla | Telefon adımına geç; ürün politikası WhatsApp zorunluysa nedeni açıkla. |
| Saat | Hangi günler, kaçta açıksın? | Hafta içi 9-18, cumartesi 10-16, pazar kapalı | Yedi günlük özeti göster, onayla, adresi değiştirme. |
| Tanıtım | En çok ne için tercih ediliyorsun? | Günlük pasta ve taze kahve | Kullanıcının verdiği bu iki bilgiden editör onaylı cümle kalıbı oluştur. |
| Hikâye | Ne zamandır hizmet veriyorsun? | 2021'den beri | Yalnız verilen tarihi kullan; deneyim/ödül uydurma. |
| Ürün | İlk ürününün adı ve fiyatı ne? | Filtre kahve 90 TL | Ürün taslağı oluştur; mevcut ürünle eşleşiyorsa hangisi olduğunu göster. |
| Fotoğraf | Dükkânından birkaç fotoğraf eklemek ister misin? | Evet | Mevcut yükleme/seçim kontrolünü aynı konuşmada aç. |
| SSS | Müşteriler en çok neyi soruyor? | Evcil hayvan kabul ediyor musunuz? | Cevabını sor; mevcut SSS editörünün kayıt yolunu kullan. |
| Kampanya | Şu an özel bir teklifin var mı? | Yok | Kampanyayı atla; başlık, fiyat, görsel için ayrı sorular sorma. |
| Tamamlama | İşletme bilgilerin hazır. Ürün ve fotoğrafları da kontrol edelim mi? | Önce önizleme | Yardımları kapatıp ziyaretçi görünümünü göster. |

Sohbet için sınırsız dil anlama sözü gerekmiyor. Dar ama güvenilir bir iş alanı, tanımlı komutlar, doğru takip soruları ve görünür seçenekler yeterli bir ürün oluşturabilir. Bu sistemin gerçek esnaflardaki yeterliliği ayrıca ölçülmeli.

“Konuşmak” sesli kullanım demekse: Bu sayfada mikrofon düğmesi gözlenmedi; public_web/src taramasında SpeechRecognition/webkitSpeechRecognition/speechSynthesis eşleşmesi bulunmadı. Sesin metne çevrilmesi ayrı bir konuşma tanıma teknolojisi gerektirir. LLM kullanmadan yapılabilir; fakat modern ses tanımayı “hiç yapay zekâ yok” diye tanımlamak doğru olmaz. Kesinlikle hiçbir AI modeli istenmiyorsa metinle sohbet ve dokunmalı seçenekler hedeflenmeli.

## UI/UX nasıl olmalı?

- Masaüstünde mevcut asistan sağ sütunda kalsın, vitrin kalan alana sığsın. Asistan vitrinin üzerine binmesin. Alanın yanındaki büyük balon yerine kısa vurgu ve gerekirse “Neden?” açıklaması kullanılsın.
- Panelde tek güncel soru ve onun cevabı baskın olsun. “Sırada” başlığı gelecek işleri açıkça ayırsın; ilk sonraki işe “Şimdi” denmesin.
- Mobilde mevcut alt panel iki açık duruma sahip olsun: konuşma ve sonucu görme. Kaydın ardından küçük bir sonuç önizlemesi veya “Vitrinde gör” kontrolü sunulsun. Ekranı mesaj, rehber, hesap ve yayın şeritleriyle sürekli doldurma.
- Hesap bağlama görünür fakat ana soruyla yarışmayacak kadar sakin olsun. Kullanıcının veri kaybı riskini anlaması için tek kısa açıklama yeterli.
- 46 alan erişilebilir kalsın; ilk kurulum 46 soru olmasın. Kozmetik başlıklar sektör varsayılanlarından gelsin. İşletme bilgileri, içerik ve yayın kontrolü şeklinde anlamlı işler izlensin.
- “%57 hazır” yerine “İşletme bilgileri 2/6”, “Ürünlerini kontrol et”, “Fotoğraflar örnek” gibi durumlar kullanılsın. Kullanıcının özelleştirdiği, şablondan gelen ve atlanan alanlar ayrı izlensin.
- Etiketleri sadeleştir: “Hero” → “Üst bölüm”, “Enlem/Boylam” → “Haritada işaretle”, “SSS üst başlık” → gelişmiş görünüm ayarı.
- Küçük, soluk yardımcı metinler ve simgeyle kapanan pencereler ayrıca erişilebilirlik kontrolüne alınmalı. Bu audit kontrast oranı veya tam WCAG uyumu ölçmedi; yalnız görünen riskleri belirledi.

## Öncelik ve tamamlanma ölçütü

| Öncelik | İş | Bitti sayılma koşulu |
|---|---|---|
| P0 | Seçili alandan başka alana yanlış yazımı engelle | Saat/kullanıcı adı/ürün fiyatı gibi girdiler adresi değiştirmiyor; belirsizlikte kayıt olmuyor. |
| P0 | Gün bazında saatleri koru | Hafta içi, cumartesi, pazar ve istisnalar kaydet/yenile sonrasında aynı. |
| P1 | Tek güncel soru ve doğru “Şimdi” | Panel, rehber, giriş ve klavye odağı aynı alanı gösteriyor. |
| P1 | Gerçek geri al | Son işlem geri alındığında daha önceki taslak düzenlemeleri korunuyor. |
| P1 | Kaliteyi doluluktan ayır | Yanlış veya yalnız örnek değerler “işletmeye özelleşti” sayılmıyor. |
| P1 | Ürün/galeri/SSS'yi konuşmaya bağla | Esnaf mevcut sayfadan ayrılmadan ilgili içerik işini tamamlayabiliyor. |
| P2 | 46 alanın teknik ayrıntılarını geri plana al | İlk kullanımda teknik alan adlarıyla karar vermek gerekmiyor. |
| P2 | Şablon sayısını artır | Önce farklı sektörlerden temsilî konuşmalarla aynı düzenleme kalitesi doğrulanıyor. |

Önerilen kabul çalışması: teknik deneyimi olmayan 5–8 esnafla adı/iletişimi değiştirme, günlere göre saat girme, ürün fiyatı güncelleme, fotoğraf ekleme, SSS değiştirme, yanlış işlemi geri alma ve önizlemeyi bulma görevleri. Bu sayı ve eşikler çalışma önerisidir, yapılmış araştırma değildir. Yardımsız bitirme, yanlış alan değişikliği, yeniden yazma sayısı ve takılma noktaları kaydedilmeli. Yanlış alan yazımı için hedef sıfır olmalı; süre hedefi ilk ölçümden sonra belirlenmeli.

## Kaynaklar ve doğrulama sınırı

Yerel kaynaklar: public_web/src/lib/vitrinFieldSchema.ts; vitrinReadiness.ts; serbestMetinCikarim.ts; addressValidator.ts; workingHours.ts; vixrexNluPipeline.ts; app/v/[slug]/hooks/useOwnerActions.ts; useFieldRestore.ts; components/UpNextList.tsx; OwnerAssistantPanel.tsx.

Tasarım önerileri için: [W3C açık adım adım yönergeler](https://www.w3.org/WAI/WCAG2/supplemental/patterns/o4p07-step-instructions/), [NN/g aşamalı açıklama](https://www.nngroup.com/articles/progressive-disclosure/), [NN/g kullanılabilirlik ilkeleri](https://www.nngroup.com/articles/ten-usability-heuristics/). Bunlar Vixrex'te hata olduğunun kanıtı değil; gözlenen sorunlara önerilen çözümün tasarım dayanaklarıdır.

Kontrol taslağı yayınlanmadı. Kaynak şablon ve uygulama kodu değiştirilmedi. Önceki turlarda verilen genel “çoğalt/çoğaltma” kararları bu raporun yerine geçmez: bu değerlendirme mevcut konuşarak özelleştirme deneyimine odaklanır.

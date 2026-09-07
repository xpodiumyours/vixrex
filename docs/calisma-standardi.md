# Vixrex çalışma ve teslimat akışı

Sürüm 1 — 7 Eylül 2026. Bu belge bir çalışma standardıdır; koşucunun, GitHub korumasının veya yayın otomasyonunun kurulduğuna dair kanıt değildir. Güncel kullanıcı isteği önceliklidir.

## 1. Kullanıcı isteğini tek teslim edilebilir işe çevir

İstenen davranışı bir cümleyle yaz. Gerekirse en fazla üç gözlemlenebilir kabul ölçütü ekle. Örnek: Flutter'daki üç başlangıç seçeneği Next'te aynı sırada görünür; her biri aynı akışa gider; yenilemede doğru kayıt geri gelir.

Ürün kapsamı belirsizse mevcut kod ve kullanıcı isteğinden doğrulanabileni yap; geri kalan kritik kararı sor. Yeni mimari, yeni ekran veya yeni servis seçimini kullanıcı kararıymış gibi yazma. Bir hata düzeltmesini bütün uygulamayı yeniden kurmaya dönüştürme.

Flutter referans commit'ini, ilgili ekranı ve Next hedefini kaydet. Görsel işlerde aynı ekran boyutu/veri durumu ile önce ve sonra bak. Kullanıcıyı ekran ekran testçi olarak çalıştırma. Erişilemeyen hesap veya cihaz doğrulamasının sınırını belirt.

## 2. İşe başlamadan ucuz ön kontrol

- Uzak main'in güncel SHA'sı okunabiliyor mu? Okunamıyorsa son bilinen sürümü güncel diye sunma; final teslimat yapma.
- Mevcut PR var mı; aynı iş main'e başka yoldan girmiş mi? Dalın geride olması tek başına işin eksik olduğunu kanıtlamaz.
- Çalışma kopyası temiz mi ve bu işe mi ait? Kayıtsız dosyaların sahibini bilmeden temizleme, stash veya toplu commit yapma.
- Gerekli koşucu çevrimiçi mi, test ortamı hazır mı? Bekleyen işin sadece durumunu okumak için yeni koşu başlatma.
- Push iki Vercel projesinden hangisini tetikleyecek? Otomatik preview kotayı tüketiyorsa yayın politikasını önce çöz; deneme commit'lerini topluca push etme.

Ortam engeli ürün kodu hatası değildir. Geliştirme yerelde sürdürülebiliyorsa sürdür; ama geçmeyen zorunlu doğrulamayı geçmiş sayma. Aynı anda yalnız bir aday final doğrulama/merge aşamasında olur.

## 3. Küçük fark, uygun test, sınırlı tekrar

| Değişiklik | Gerekli kanıt |
|---|---|
| Yalnız Markdown talimat/belge | Değişen dosyaların incelemesi, bağlantı/yol kontrolü, secret taraması; sırf belge için ürün build'i yok |
| Next davranışı | İlgili regresyon/akış kontrolü, lint, tip kontrolü, Next testleri ve production build |
| Flutter davranışı | Biçim, analiz, Flutter testleri; değişen akış için uygun widget/integration doğrulaması |
| Ortak sözleşme | Üretim çıktılarının güncelliği, iki istemcinin etkilenen sözleşme ve davranış kontrolleri |
| Veri/yetki/oturum/ödeme | İzole ortamda değişikliğe uygun migration, yetki ve olumsuz senaryolar; canlı veriyi test için değiştirme |
| Teslimat/CI kodu | Gerçek karar kodunda başarısız kontrol, atlanan kontrol, devam eden kontrol, değişen SHA ve tekrar sınırı senaryoları |

Bu tablo, mevcut sunucu tarafı zorunlu kontrolü atlama yetkisi vermez. Mevcut kapı belge değişikliğinde ilgisiz ürün testlerini zorunlu tutuyorsa bu sınıflandırma hatasını ayrı ve dar bir düzeltmeyle gider; sonucu elle yeşile çevirme.

Geliştirme sırasında yalnız problemi gösteren hızlı kontrolü kullan. Aday hazır olduğunda gerekli geniş doğrulamayı bir kez çalıştır. Aynı SHA, temel sürüm, ortam ve test kapsamına ait güvenilir sonucu yeniden kullan; testten sonra ilgili kod/bağımlılık/ortam değişirse gereken sonucu yenile. Her küçük düzeltmede bütün test zincirini tekrar başlatma.

Yerel başarılı sonucu CI başarılı diye yazma. PR kaynak metin testi, gerçek tarayıcı davranışının kanıtı değildir. UI/akış işinde kısa gerçek kullanım senaryosu da gerekir. Test baselines'ını sırf kırmızıyı kapatmak için yeniden üretme.

## 4. Hata kararları

| Durum | Eylem |
|---|---|
| Yeni değişikliğin kod/akış hatası | Hedefli yeniden üret, düzelt, ilgili kontrolü çalıştır |
| Main'de de aynı hata | Main üzerinde kanıtla, ayrı temel sürüm düzeltmesi yap; ilgisiz ürün koduna karıştırma |
| Güvenlik hatası veya gerekli güvenlik kontrolü eksik | Teslimatı durdur; kontrolü güvenilir ortamda tamamla |
| Koşucu çevrimdışı / kalıcı kota engeli | Yeni koşu başlatma; ortam engelini kaydet ve gider |
| Geçici ağ hatası | Aynı SHA için en fazla bir otomatik tekrar; düzelmezse nedeni araştır |
| İptal edilen koşu | Hangi adımın ve neden iptal edildiğini oku; tam PASS veya kod hatası diye genelleme |
| Atlanan kontrol | Yalnız değişiklik kapsamına göre gerekli olmadığı kanıtlanmışsa 'uygulanmaz'; zorunlu kontrol atlandıysa teslimat yok |

Vercel, TestSprite veya başka servis adına bakarak hata türünü belirleme. Hata mesajı/adım kaydı gerekir. Kod build hatasıyla kota hatası aynı değildir.

## 5. Main'e teslim

1. Yetki ve kapsamı kontrol et. Kullanıcının bu iş için verdiği main'e teslim yetkisini sıradan adımlarda tekrar sorma. Canlı veri silme, ücretli kaynak açma veya istek dışı davranış değişikliği için bu standardı yetki sayma.
2. PR'ın gerçek dosya farkını güncel main'e karşı incele; başka işlerin karışmadığını doğrula. Gerekliyse dalı güncelle, çakışmayı çöz ve etkilenen doğrulamayı yenile.
3. Aday HEAD, temel main, test komutları/koşu bağlantıları, sonuçlar ve kalan engelleri iş kaydına yaz. Güvenilir sonuç olmadan 'hazır' deme.
4. Taslak durumu, gerekli onay ve kontroller tamamlandıysa PR'ı teslimata hazır hâle getir. Sadece taslak işaretini kaldırmak veya etiket koymak doğrulama değildir.
5. Merge sırasında beklenen PR HEAD SHA'sını gönder. Tam bu aday incelenmiş olmalı. Sunucu korumaları ve mevcut teslimat şartları sağlanmalı; doğrudan main push veya kontrol atlatan admin merge kullanma.
6. Merge yanıtında gerçek başarıyı doğrula; PR'ın birleştiğini ve çıkan commit'in main'de olduğunu kontrol et. Squash commit'ini kaynak PR SHA'sıyla karıştırma.
7. Ürün değiştiyse ilgili uygulamanın yayına çıktığı sürümü doğrula; o sürümde kısa akış kontrolünü çalıştır. Yalnız belge değişikliğinde uygulama yayını gerekmez.

Durumlar: `HAZIRLANIYOR` → `DOĞRULANIYOR` → `MAIN'DE` → ürün işiyse `YAYINDA DOĞRULANDI`. Engel varsa `ENGEL: <somut neden>` ekle. PR açılması bitiş değildir. Vercel kota nedeniyle yayınlanmadıysa açıkça `MAIN'DE / YAYIN BEKLİYOR` de.

## 6. Oturumlar arası tek iş kaydı

PR varsa açıklamadaki aşağıdaki bölümü güncelle; ayrı tekrar eden yorumlar üretme. PR öncesinde aynı kaydı görevin yerel notunda tut; PR açılınca oraya taşı. Kullanıcı başka göreve geçtiğinde yeni ajan mevcut kaydı ve son gerçek sonuçları okuyarak devam eder.

```text
İş / kullanıcı isteği:
Kabul ölçütleri:
Flutter referansı (SHA + ekran/akış):
Dal / PR / çalışma kopyası:
Aday HEAD / temel main:
Son doğrulama (komut veya koşu bağlantısı + sonuç + ortam):
Mevcut durum / somut engel:
Sıradaki tek adım:
Merge commit / yayın kanıtı (varsa):
```

Yalnız gerçekleştirilen ve doğrulanan işleri yaz. Diğer ajanın sohbet açıklamasını kontrol sonucu sayma. Yeni bilgi geldiğinde kaydı güncelle; kullanıcıya tekrar uzun proje geçmişi okutma. Kullanıcı durdurmadıkça yetkili işi teslimata kadar takip et. Tur sonunda canlı takip gerekecekse gerçekten kurulu bir takip mekanizmasına devret; yoksa yok de.

## 7. Kota ve çalışma ortamı

GitHub Actions hosted dakika hakkının bitmesi nedeniyle uygun işler yerel koşucuda çalıştırılır. Windows'ta çalışmayan Docker/Linux işi sadece etiket değiştirilerek taşınmaz. Veritabanı güvenliği ve yedekleme sessizce kaldırılmaz.

Ara commit'lerde Vercel preview yerine yerel build/tarayıcı kullanılır. Yayın tetikleme politikası iki Vercel projesinde de ayrıca doğrulanır; bu belge ayarı değiştirmez. Canlı yayın engeli main'deki kaydı kaybettirmez. Bu düzen kota sıfırlamaz, sınırsız kullanım veya hata bulunmaması garantisi vermez.

## 8. Bu sürümün bilinen uygulama engelleri

7 Eylül denetimi, main `cb0111ea` temelinde: iki koşucu çevrimdışıydı; main korumasızdı; `teslimat.py` atlanan zorunlu kontrolleri PASS kabul ediyor ve bazı devam eden güvenlik kontrollerini beklemiyordu. Son durum yeniden doğrulanmalıdır.

Bu kusurlar düzeltilip gerçek karar kodunda doğrulanmadan otomatik teslimat için `merge-approved` etiketi verme. Standart kusurlu otomasyonu güvenli hâle getirmez. Gerekli kontrolleri tamamlanmış, açık yetkili PR'ı elle teslim etmek mümkündür; bu yol kontrolleri atlamaz.

`GITHUB_TOKEN` ile otomatik PR güncelleme yeni CI için onay gerektirebilir; aynı token'ın push olayı main CI'ını kendiliğinden başlatmaz. Otomasyon yeni kontrolün gerçekten başladığını doğrulamalı, gerekiyorsa açık tetikleme kullanmalıdır.

Kaynaklar: [GitHub workflow tetikleme](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/trigger-a-workflow), [GitHub yerel koşucular](https://docs.github.com/en/actions/reference/runners/self-hosted-runners), [Vercel yayın tetikleme](https://vercel.com/docs/project-configuration/git-configuration).

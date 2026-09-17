# Bu istek kaç işe bölünüyor

Ölçüme göre yedi iş çıkıyor. Sıra bağımlılıktan geliyor, aceleden değil:
alttaki halka kurulmadan üstteki halka çalışamaz.

## 1. Çarşı bağı — veri temeli

İş türü: özellik. Bugün yok, sıfırdan kurulur.
Kullanıcı sonucu: İki vitrin arasında, karşı taraf kabul ettiğinde geçerli olan
bir komşuluk kaydı tutulur.
Neye dayanır: Hiçbir şeye; zincirin ilk halkası budur.
İçerir: Yeni ilişki tablosu, istek ve kabul durumları, erişim kuralları
(kimse kendi vitrini olmayan bir bağı kuramaz), üç kimlikle güvenlik denemesi.
Not: Vitrin sahibinin kimliği bugün herkese açık okumadan bilerek çıkarılmış;
bağ kaydı bunu geri açmamalı.

## 2. Esnafın komşu eklemesi — panel

İş türü: özellik.
Kullanıcı sonucu: Esnaf komşu arar, istek gönderir, gelen isteği kabul veya
reddeder.
Neye dayanır: 1. iş.
İçerir: Flutter paneli ve web'deki Vixrex Asistan paneli aynı işin içinde;
yeni metinler mesaj kataloğuna eklenir.

## 3. Vitrinde komşular bölümü — tüketici yüzü

İş türü: özellik.
Kullanıcı sonucu: Ziyaretçi bir vitrini gezerken aynı çarşıdaki komşuları görür
ve tek dokunuşla geçer.
Neye dayanır: 1 ve 2.
İçerir: Vitrin sayfasına yeni bölüm, mevcut bölüm görünürlük anahtarıyla aynı
davranış, komşusu yokken bölümün hiç görünmemesi.

## 4. Keşifte çarşı

İş türü: değişiklik. Keşif bugün düz liste; çarşı gruplama demek.
Kullanıcı sonucu: Ziyaretçi keşifte tek tek vitrinleri değil çarşıları da görür.
Neye dayanır: 1, 2, 3.
Karar gerektirir: Çarşı keşifte ayrı bir yüzey mi olacak, yoksa mevcut keşfin
bir süzgeci mi?

## 5. Esnafın vitrin görünümünü seçebilmesi

İş türü: özellik. "Görünüm olarak bağlantı" isteğinin eksik ön halkası.
Kullanıcı sonucu: Esnaf vitrininin görünümünü kendisi seçer.
Neye dayanır: Hiçbir şeye; 1. işle aynı anda yürüyebilir.
Neden ayrı iş: Tema altyapısı yazılmış ama kullanılmıyor ve esnafın
düzenleyebildiği 46 alanın hiçbiri görünümle ilgili değil. Ortak çarşı imzası,
tek tek vitrin görünümü seçilemeden kurulamaz.

## 6. Çarşının ortak görünüm imzası

İş türü: özellik.
Kullanıcı sonucu: Aynı çarşıdaki vitrinler ortak bir görsel imza taşır;
ziyaretçi baktığında aynı çarşıda olduklarını anlar.
Neye dayanır: 1, 2 ve 5.
Karar gerektirir: İmza ne kadar ileri gider — yalnız bir rozet mi, ortak renk mi,
yoksa ortak düzen mi?

## 7. Hediyeleşme

İş türü: özellik. Bugün hiçbir parçası yok.
Neye dayanır: Kim kime hediye edecek kararına; parayla ilgiliyse ödemenin
canlıda çalışmasına.
Ölçülen engel: Ödeme sunucu tarafında yazılmış ama kimlikler ortamda yokken
istek reddediliyor; ayrıca ödeme her zaman vitrinin kendi sahibinin oturumuyla
başlıyor, başkası adına ödeme kavramı yok.
İki ayrı ürün: Parasız hediyeleşme (esnafın esnafa teşekkür, rozet, öne çıkarma)
bugün başlayabilir. Paralı hediyeleşme (birinin başkasının kirasını ödemesi)
ödeme canlıya alınmadan ve iade, iptal, fatura ve hukuki metin yazılmadan
başlayamaz.

## Bugün ne başlayabilir

1 ve 5 hemen başlayabilir. 2, 3, 4 ve 6 sırayla onların üstüne biner.
7 için önce "kim kime hediye eder ve para var mı" kararı gerekir.

## Kapsam kilidi

Anayasa aynı anda en fazla iki açık iş söylüyor. Yedi iş bir arada açılmaz;
biri bitmeden diğeri başlamaz.

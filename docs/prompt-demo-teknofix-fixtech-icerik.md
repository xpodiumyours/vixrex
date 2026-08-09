# Prompt: demo-teknofix'e hedef kalitede içerik girişi (manuel panel üzerinden)

## Amaç

`demo-teknofix` (TeknoFix, Şişli/İstanbul, telefon-bilgisayar teknik
servisi) şu an Hakkımızda, SSS, ürün listesi, galeri ve blog bölümleri
boş/jenerik. Hedef: bu mağazayı `C:\teknik_vitrin_asistan.html`
(FixTech referansı) kalitesine getirmek — Keşfet ekranında gerçek,
dolu bir vitrin olarak yayınlanabilsin.

**Bu iş aynı zamanda bir test:** Aşağıdaki her alan **Flutter manuel
üyelik panelinden** girilecek — mevcut ekranlarda gerçekten dolduruluyor
mu diye. Panelde ulaşamadığın bir alan çıkarsa (ekranı yok, kaydetmiyor,
vs.) **atlama, düzeltmeye çalışma** — sadece not al ve rapor et. Bu,
panelin eksikliğinin somut kanıtı olacak, ayrı ele alınacak.

## Ön koşul

- `demo-teknofix` mağazasına manuel panelden (Flutter) giriş yapılmış
  olmalı — hangi hesapla bağlı olduğunu kontrol et, gerekiyorsa Casper'a
  sor.
- Değişiklikler **yalnızca yerel/test ortamında** doğrulanacak; canlıya
  yazma işlemi normal panel akışı üzerinden olacağı için zaten güvenli,
  ekstra bir "yayınla" adımına gerek yok (mağaza zaten `is_published: true`).

## Girilecek içerik

Aşağıdaki tüm metinler önceden yazıldı, olduğu gibi kullan — kendi
metnini üretme, çeviri/kısaltma yapma.

### 1. Hero / Kimlik
- Hero rozet metni: `Yetkili Teknik Servis · Şişli`
- Kısa tanıtım: `10 yıllık tecrübeyle telefon, tablet ve bilgisayar onarımında hızlı, garantili ve şeffaf hizmet.`
- Hero konum metni: `Şişli, İstanbul`

### 2. İletişim
- Çalışma saatleri: `Pzt–Cmt 09:00–19:30, Pazar kapalı`
- Telefon: `0212 234 56 78`
- E-posta: `info@teknofix.com.tr`
- Harita etiketi: `Atatürk Caddesi, Şişli — Metro Şişli-Mecidiyeköy 5 dk`
- (Adres zaten dolu, değiştirme: Atatürk Cad. No:24, Şişli, İstanbul)

### 3. Bölüm başlıkları
- Kategori bölüm başlığı: `Hizmet Kategorileri`
- Ürün bölüm başlığı: `Servis Fiyat Listesi`
- Galeri kicker: `Atölyeden` / başlık: `Çalışmalarımız`
- Galeri aksiyon: `Tüm çalışmalarımızı gör` → `#iletisim`
- Blog kicker: `Teknik Rehber` / başlık: `Bilmeniz Gerekenler`
- SSS kicker: `Sıkça Sorulan Sorular` / başlık: `Merak Edilenler`
- SSS açıklama: `Onarım süreci, garanti ve teslim süreleri hakkında sık sorulan sorular.`

### 4. Kategoriler (4 adet)
1. Telefon Ekran & Batarya Değişimi
2. Bilgisayar & Laptop Servisi
3. Tablet Onarımı
4. Aksesuar & Yedek Parça

### 5. Ürün/Hizmet listesi (8 kalem)

| Ad | Kategori | Fiyat | Açıklama | Teslim/Garanti |
|---|---|---|---|---|
| iPhone Orijinal Ekran Değişimi | Telefon Ekran & Batarya Değişimi | 2.450 TL | Apple onaylı orijinal ekran, dokunmatik ve renk kalibrasyonu test edilerek teslim edilir. | Aynı gün, 6 ay garanti |
| Samsung Galaxy Batarya Değişimi | Telefon Ekran & Batarya Değişimi | 850 TL | Orijinal kapasiteli batarya, değişim sonrası kalibrasyon yapılır. | Aynı gün, 6 ay garanti |
| MacBook Klavye & Tuş Takımı Değişimi | Bilgisayar & Laptop Servisi | 1.850 TL | Kelebek/makas mekanizma değişimi, tüm tuşlar test edilir. | 2 iş günü, 6 ay garanti |
| Laptop Anakart Arıza Tespiti & Onarımı | Bilgisayar & Laptop Servisi | 600 TL (tespit) | Ücretsiz ön inceleme sonrası net onarım fiyatı bildirilir. | 2-3 iş günü, 3 ay garanti |
| iPad Ekran Değişimi | Tablet Onarımı | 1.950 TL | Orijinal ekran + dokunmatik katman, su sızdırmazlık testiyle teslim. | Aynı gün, 6 ay garanti |
| Telefon Kamera Modülü Değişimi | Telefon Ekran & Batarya Değişimi | 1.100 TL | Otofokus ve netlik testi yapılarak teslim edilir. | Aynı gün, 6 ay garanti |
| Data Kurtarma (HDD/SSD) | Bilgisayar & Laptop Servisi | 950 TL'den başlar | Fiziksel/mantıksal arızalı disklerden veri kurtarma. | 3-5 iş günü |
| Orijinal Şarj Aleti & Kablo Seti | Aksesuar & Yedek Parça | 450 TL | Apple/Samsung uyumlu, orijinal amper değeriyle hızlı şarj. | Stoktan aynı gün |

**Öne çıkan kampanya:**
- Etiket: `Bu Ay Öne Çıkan`
- Başlık: `Ekran Değişiminde %15 İndirim`
- Açıklama: `Ağustos ayı boyunca tüm telefon ekran değişimlerinde geçerli, orijinal parça garantisiyle.`
- Fiyat metni: `%15 İndirim`

### 6. Hakkımızda
- Kicker: `Hakkımızda`
- Başlık: `10 yıllık tecrübeyle şeffaf ve garantili teknik servis`
- Kurumsal metin (2 paragraf, panel tek metin alanıysa boş satırla ayır):

  > TeknoFix, 2015 yılından bu yana Şişli'de telefon, tablet ve bilgisayar onarımı yapan bağımsız bir teknik servistir. Apple, Samsung ve genel Android/Windows cihazlarında orijinal ve OEM eşdeğeri parçalarla çalışıyor, her onarım öncesi ücretsiz arıza tespiti sunuyoruz.
  >
  > Müşterilerimize açık fiyatlandırma ve yazılı garanti veriyoruz — onarım başlamadan önce net fiyat söylenir, sürpriz ek ücret çıkmaz. Ekibimiz düzenli olarak üretici sertifikalı eğitimlerden geçiyor.

- Görsel altyazısı: `Atölyemizde titiz bir onarım süreci`
- Değer kartları (3 adet, panelde bu alan varsa):
  1. **Şeffaf Fiyatlandırma** — Tespit sonrası net fiyat, onayınız alınmadan işlem başlamaz.
  2. **Orijinal Parça Garantisi** — Kullanılan tüm parçalarda 6 ay yazılı garanti, iş takibi SMS ile bildirilir.
  3. **Aynı Gün Teslim** — Ekran ve batarya değişimlerinin büyük kısmı 1-2 saat içinde tamamlanır.

### 7. Galeri (5 kare, başlık olarak gir)
1. Atölyemizden bir kare — hassas komponent onarımı
2. Orijinal parça stok alanımız
3. iPhone ekran değişimi anı
4. Laptop anakart tamiri, mikroskop altında
5. Teslim öncesi son kalite kontrolü

**Görsel notu:** Elimizde gerçek atölye fotoğrafı yok. Panelde görsel
zorunluysa mevcut/geçici stok görseli kullan ama **bunu raporunda açıkça
belirt** — bu madde gerçek fotoğrafla değiştirilene kadar "geçici" sayılacak.

### 8. SSS (4 soru-cevap)
1. **S:** Cihazımı bırakmadan önce fiyat öğrenebilir miyim?
   **C:** Evet, ücretsiz arıza tespiti sonrası net fiyatı WhatsApp veya telefonla bildiriyoruz, onayınız olmadan işlem başlamaz.
2. **S:** Garanti süresi ne kadar?
   **C:** Tüm ekran, batarya ve parça değişimlerinde 6 ay yazılı garanti veriyoruz.
3. **S:** Verilerim onarım sırasında güvende mi?
   **C:** Evet, veri güvenliği önceliğimiz; onarım öncesi isterseniz yedekleme desteği de sağlıyoruz.
4. **S:** Aynı gün teslim garantisi var mı?
   **C:** Ekran ve batarya değişimlerinin büyük kısmı stok müsaitse aynı gün teslim edilir; anakart onarımları 2-3 iş günü sürebilir.

### 9. Blog (3 tam yazı)

**1. Telefon Ekranı Kırıldığında İlk 24 Saatte Yapılması Gerekenler**
Özet: `Ekranınız kırıldıysa panik yapmadan önce bu adımları takip edin — veri kaybını ve maliyeti azaltabilirsiniz.`

> Telefon ekranınız kırıldığında ilk yapmanız gereken cihazı kapatmak ve daha fazla baskı uygulamamaktır. Çatlak ekranla kullanmaya devam etmek, dokunmatik katmana zarar vererek onarım maliyetini artırabilir.
>
> Cihazınızı mümkünse anti-statik bir poşete koyun ve doğrudan güneş ışığından uzak tutun. Sıvı teması varsa cihazı kesinlikle şarja takmayın.
>
> TeknoFix'te ücretsiz arıza tespiti ile hem ekranın hem alttaki panelin durumu kontrol edilir. Çoğu iPhone ve Samsung modelinde orijinal ekran değişimi aynı gün, 1-2 saat içinde tamamlanır.

**2. Laptop Aşırı Isınıyorsa Nedenleri ve Çözümleri**
Özet: `Laptopunuz çalışırken aşırı ısınıyorsa bu nedenleri kontrol edin.`

> Laptop aşırı ısınmasının en sık nedeni toz birikimi ve kurumuş termal pattır — fan ve radyatör düzenli temizlenmezse performans düşer.
>
> İkinci yaygın neden arka planda çalışan yoğun uygulamalardır; görev yöneticisinden yüksek CPU kullanan süreçler kontrol edilmeli.
>
> TeknoFix'te laptop temizliği ve termal pat yenileme hizmeti sunuyoruz; ortalama işlem süresi 45 dakikadır ve cihazınızı beklerken teslim alabilirsiniz.

**3. Orijinal Parça ile Muadil Parça Arasındaki Fark Nedir?**
Özet: `Ekran ve batarya değişiminde "orijinal" ile "muadil" parça arasındaki gerçek farkı anlatıyoruz.`

> Orijinal parça, üreticinin kendi fabrikasında ürettiği veya sertifikalı tedarikçiden gelen parçadır; renk doğruluğu, dokunmatik hassasiyeti ve dayanıklılık açısından cihazın orijinaline en yakın sonucu verir.
>
> Muadil (OEM eşdeğeri) parçalar daha uygun fiyatlıdır ama kalite aralığı geniştir — bazı muadiller orijinale çok yakın performans gösterirken bazıları daha kısa ömürlü olabilir.
>
> TeknoFix'te hangi parçayı kullandığımızı işlem öncesi açıkça belirtiyoruz, karar her zaman müşteriye ait.

## Kapsam DIŞI (bu prompt'ta yapma)

- Galeri/blog görselleri gerçek fotoğrafla değiştirme — yok, ayrı iş.
- `marketplace_links` düzeltme (şu an ikisi de google.com'a gidiyor) — ayrı madde.
- `logo_url` girişi — panelde zaten yok, ayrı madde.
- "Bu vitrini kirala" butonu — ayrı madde.
- Diğer 8 demo mağaza — bu iş yalnız `demo-teknofix` içindir, iyi sonuç
  alınırsa sırada diğerleri var.

## Bitirme kriteri

1. Yukarıdaki 9 bölümün tamamı manuel panelden girilmiş ve kaydedilmiş.
2. Panelde ulaşılamayan alan varsa (ör. değer kartları, galeri başlığı)
   **listelen** — atlama, uydurma, kodu değiştirme.
3. Next.js tarafında (`/v/demo-teknofix`) her bölümün göründüğü
   ekran görüntüsüyle kanıtlanmış (Hakkımızda, SSS, ürünler, galeri,
   blog, kampanya — hepsi).
4. `dart format`/`flutter analyze` temiz (panelde kod değişikliği
   olmayacağı için muhtemelen gerekmeyecek, ama girişte bug çıkarsa
   uygulanır).

Bitince rapor et: hangi alanlar sorunsuz girildi, hangi alan(lar)a
panelden ulaşılamadı.

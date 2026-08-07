# Tur bulguları — 6 Ağustos 2026 akşam

Casper'ın kendi turunda gördükleri. Tur bitmeden düzeltmeye girilmez;
liste burada birikir.

**Test adresi:** `vixrex-app-git-docs-canli-test-bulgulari-...vercel.app`
(production değil — düzeltmeler orada yok)

---

## 1. Kategori balonları dağınık

**Nerede:** Kurulum sohbeti, "İşini seç" adımı

**Ne oluyor:** Balonlar ortalanmış, satırları düzensiz sarıyor
(4 / 2 / 2 / 2 / 2). Genişlikler farklı, aralar eşit değil.
Ayrıca 12 kategori görünüyor; karşılama ekranındaki katalogda 19 tane var.

**Olması gereken:** Eşit hücreli ızgara, sabit satır düzeni.
Kategori sayısı katalogla aynı olmalı.

---

## 2. GPS koordinat alıyor, adresi bulmuyor

**Nerede:** Kurulum sohbeti, konum adımı

**Ne oluyor:** "Koordinat kaydedildi (41.0250, 29.1542)" yazıyor —
koordinat doğru (İstanbul, Ataşehir civarı). Ama İl, İlçe ve
açık adres alanları boş kalıyor.

**Sebep:** Koordinattan adrese çeviren adım (ters coğrafi kodlama) yok.
6 Ağustos sabahı yapılan düzeltme hassasiyet eşiğiydi (30m → 10m);
şikayet bu değildi.

**Olması gereken:** GPS sonrası il/ilçe/mahalle otomatik dolsun.

---

## 3. Kapak fotoğrafı kategoriye uymuyor ve seçilmemiş — ✅ KAPANDI

**Nerede:** Yayınlanmış vitrin, `/v/dene-dene-yoruldum`

**Ne oluyor:** İşletme dekorasyon kategorisinde, kapakta kot pantolon
fotoğrafı var. Esnaf böyle bir fotoğraf seçmedi.

**Durum:** 2026-08-07 turunda doğrulandı — yeni kurulan vitrinde
(claude22, ELEKTRONİK) uydurma kapak fotoğrafı gelmiyor. Kapandı.

---

## 4. Sahip oturumu 15 dakikada ölüyor, yenilenmiyor

**Nerede:** `public_web/src/lib/ownerSession.ts:14`

**Ne oluyor:** `OWNER_SESSION_TTL_MS = 15 * 60 * 1000`. Süre işlem
yapıldıkça uzamıyor; 15. dakikada panel fail-closed kapanıyor.

**Neden 15 dakika konmuş:** Güvenlik. Link paylaşılsa veya ortak
bilgisayarda açık kalsa sonsuz düzenleme hakkı vermesin.

**Sorun:** Kişiselleştirme kabul senaryosunun 5. adımı — "işin kalbi".
Esnaf orada 15 dakikadan fazla kalıyor.

**Olması gereken:** Her başarılı kayıtta süre yenilensin (kayan süre),
üstüne mutlak tavan (örn. 8 saat). Güvenlik korunur, esnaf yarıda kalmaz.

---

## 5. 44 alanın 32'sine ulaşılamıyor

**Nerede:** Sahip paneli, `/v/dene-dene-yoruldum`

**Ne oluyor:** Panel "Doluluk %33 · 4/12 alan" diyor. Şemada 44 alan var.
`vitrinReadiness.ts` yalnız "temel" (4) ve "kalite" (8) alanları sayıyor;
32 "isteğe bağlı" alan ne yüzdeye ne de eksikler listesine giriyor.

**Neden kritik:** Bir alana ulaşmanın iki yolu var —
(a) vitrinde o yazıya tıklamak: alan boşsa vitrinde çizilmiyor,
tıklanacak bir şey yok;
(b) eksikler listesinden seçmek: o 32 alan listede yok.
Sonuç: 32 alan hiçbir yoldan erişilemez.

**Düzenleme motoru çalışıyor** — ekranda "Düzenleniyor: Hero Rozet Metni"
görünüyor. Sorun erişim, mekanizma değil.

**Olması gereken:** Panelde "tüm alanlar" görünümü — 44 alan bölümlere
ayrılmış ve hepsi tıklanabilir. Yüzde 12 üzerinden kalabilir (hazırlık
ölçüsü odur), erişim 44 üzerinden olmalı.

---

## 6. Sahip modunda eylem butonları düzenlenmiyor, dışarı atıyor

**Nerede:** `VitrinProfileView.tsx:389` (hero butonları) ve
"İletişim & Konum" kartındaki bağlantılar

**Ne oluyor:** WhatsApp, Yol Tarifi, Instagram, web sitesi butonları
sahip modunda da düz `<a href>` olarak çiziliyor. Tıklayınca esnaf
kendi kendine WhatsApp mesajı açıyor ya da kendi Instagram sayfasına
gidiyor. Düzenleme kutusu açılmıyor.

**Sebep:** Bu butonlara `editableProps` uygulanmamış. Panelin tıklama
dinleyicisi yalnız `data-vixrex-editable` taşıyan öğelerde
`preventDefault()` çağırıyor; işaret olmayınca tarayıcı normal link
davranışını sürdürüyor.

**Olması gereken:** Sahip modunda buton ilgili alanı açsın —
WhatsApp → WhatsApp numarası, Yol Tarifi → adres, web sitesi → site
adresi. Ziyaretçi modunda hiçbir şey değişmez (koruma sınırı 3:
sahip araçları müşteri yanıtına sızmaz).

---

## 7. Sahip, müşterinin gördüğünü göremiyor

**Nerede:** Sahip paneli

**Ne oluyor:** Vitrin adresi tektir; sahip çerezi varsa sahip modu, yoksa
müşteri görünümü açılır. Doğrulandı (2026-08-07): çerezsiz istekte sahip
panelinden tek iz yok, müşteri sayfası dönüyor. Link paylaşımı güvenli.

**Eksik:** Sahibin kendi vitrinini müşteri gözüyle görecek bir yolu yok.
Başka bir gizli pencere açmak zorunda kalıyor.

**Olması gereken:** Panelde "Müşterinin gördüğü hâli" bağlantısı —
aynı adresi sahip modu kapalı olarak açar.

---

## 8. Kurulum sonu iki kapı, ikisi de aynı yere

**Nerede:** Kurulum sohbetinin son ekranı

**Ne oluyor:** "Canlı vitrini aç" ve "Vitrinimi birlikte düzenleyelim"
aynı sayfayı açıyor. Esnaf önce bakıyor, geri dönüyor, sonra ikinci
düğmeye basıyor — tek iş için iki yolculuk. Üstelik yeni sekmede açılıyor,
telefonda yön kaybettiriyor.

**Olması gereken:** Tek düğme — "Vitrinini aç" → sahip modunda, aynı
sekmede. Müşteri görünümü panelin içinde bir bağlantı olur.

---

## 9. Paylaş kutusundaki adres ölü

**Nerede:** Yayınlanmış vitrin, paylaşım bölümü

**Ne oluyor:** `vixrex.com/v/<slug>` gösteriliyor ve "Kopyala" onu
kopyalıyor. **O alan adı bağlı değil, açılmıyor.** Esnaf ölü link
paylaşıyor.

**Neden kritik:** Ürünün tek cümlelik vaadi "tek linkte hazır vitrin".
Link ölüyse geri kalan her şey anlamsız.

**Olması gereken:** Alan adı bağlanana kadar çalışan adres gösterilmeli.

---

## 10. Sürüm uyarısının çaresi yok — taslak tazelenemiyor

**Nerede:** Sahip paneli, turuncu "canlı vitrin değişmiş" kutusu

**Ne oluyor:** Esnaf manuel üyelik panelinden vitrinini düzenleyip
yayınlıyor. Keşfet güncelleniyor (doğrudan `stores` okur), Next.js paneli
güncellenmiyor (taslağı okur). Turuncu kutu farkı bildiriyor ama
"yeniden yükle" aynı eski taslağı tekrar getiriyor.

**Sebep:** `get_working_draft_for_session` taslağı YALNIZ ilk seferde
`stores`'tan kopyalıyor. Taslak varsa olduğu gibi dönüyor; sadece
`version_conflict = true` işaretleniyor. Taslağı canlı sürümden
tazeleyen bir yol yok.

**Bugünkü tek çıkış:** "Değişiklikleri bırak" — taslağı siler, sonraki
açılışta canlıdan yeniden kurulur. Ama esnaf için bu "işimi kaybedeceğim"
demek; kimse basmaz.

**Olması gereken:** "Canlı sürümü al" düğmesi — taslağı yayındaki
vitrinden tazeler, uyarı kapanır. Esnafın taslakta bekleyen değişikliği
varsa önce sorulmalı.

---

## 11. Maskot balonu rozetlerin üstüne biniyor

**Nerede:** Karşılama ekranı, telefon

**Ne oluyor:** "Dijital vitrinini hazırlayayım mı?" balonu "Kredi kartı
gerekmez" ve "Link ve QR hazır" rozetlerini kapatıyor. Yazılar okunmuyor.

**Olması gereken:** Balon rozetlerin üstüne binmemeli; ya yukarı kaysın
ya rozetler için yer bıraksın.

---

## 12. Karşılama metni "siz" kipinde

**Nerede:** Karşılama ekranı, giriş paragrafı

**Ne oluyor:** "İşletme bilgilerinizi... tek vitrinde toplayın." Tek
asistan kararı (2026-08-06) her yerde "sen" idi; Next.js tarafı çevrildi,
Flutter karşılama metni kaldı.

**Olması gereken:** "İşletme bilgilerini... tek vitrinde topla."

---

## 13. Zorunlu alanlar boşken "devam" basılabiliyor

**Nerede:** Kurulum sohbeti, konum adımı

**Ne oluyor:** İl, İlçe ve Açık Adres yıldızlı (zorunlu) ama üçü de boşken
"Konumu onayla, devam" düğmesi çalışıyor. Zorunluluk işareti var,
karşılığı yok.

**Olması gereken:** Ya alanlar dolana kadar düğme pasif olsun, ya da
yıldız kaldırılsın. İkisinden biri — ikisi birden yanlış.

---

## 14. 119 deneme vitrini yayında ve Google'a açık

**Nerede:** Bulut veritabanı, `stores` tablosu

**Ne oluyor (2026-08-07 sayımı):**
- 128 vitrin kayıtlı, hepsi yayında
- 9'u demo (`is_demo=true`) — karşılama ekranının örnekleri, kalmalı
- **119'u deneme çöpü** — `xxxx`, `deneme-55`, `cccc`, `sxxx`, `xxxd`...

`robots.txt` dizine almaya izin veriyor, site haritası da onları listeliyor.
Marka adıyla arandığında çıkacak ilk sayfalar bunlar olabilir.

**Neden şimdi önemli:** Casper'ın kendi ifadesiyle "temiz defter açmak"
isteniyor. Gerçek esnaf gelmeden önce temizlenmezse ilk izlenim bu olur.

**Olması gereken:** 119 deneme kaydı silinsin, 9 demo kalsın. Silme
geri alınamaz; önce yedek alınmalı.

**Ayrıca:** Deneme vitrinlerinin bir daha birikmemesi için yol lazım —
ya kurulum sırasında işaretlensinler ya da düzenli temizlik.

---

## 15. Yazı tipi yüzeyler arasında tutarsız

**Nerede:** Uygulama (Flutter) ve vitrin (Next.js)

**Ne oluyor:**
- Uygulama: `lib/main.dart:135` → `fontFamily: 'Helvetica'`. O yazı tipi
  uygulamayla birlikte GELMİYOR; her cihaz kendi bulduğuna düşüyor
  (Android'de Roboto, tarayıcıda Arial). Cihazdan cihaza değişiyor.
- Vitrin: `Outfit` (gövde), `Instrument Serif` (başlık).

İki yüzey iki ayrı marka gibi duruyor.

**Casper (2026-08-07):** "landing ekranındaki Vixrex'in yazı tipi ve
diğer ekranlardaki yazı tipi farklı... her ekranda aynı tarz yazı tipi
olmalı."

**Olması gereken:** Tek yazı tipi — `Outfit`. Müşterinin gördüğü yüzeyde
zaten o var; kalite çıtası orası. Uygulamaya gömülür (pubspec'e eklenir),
temada tanımlanır, ekranlar ondan miras alır. Ayrıca sözleşme testi:
`fontFamily` tek bir yerde tanımlı olmalı, ekranlar kendi yazı tipini
belirlememeli.

---

## 16. Asistanın yüzü ekrandan ekrana değişiyor

**Nerede:** Kurulum sohbeti ve uygulama içi asistan

**Ne oluyor:** Kurulum sohbetinde her cümlenin başında Vixrex maskotu
duruyor; uygulama içindeki asistanda yok. Aynı asistan, iki farklı yüz.

**Neden önemli:** 2026-08-06'da "tek asistan" kararı verildi ve dil
birleştirildi ("sen" kipi). Görünüm birleştirilmedi — karar yarım kaldı.

**Olması gereken:** Balon biçimi tek yerde tanımlansın; maskotun görünüp
görünmeyeceği her ekranda ayrı ayrı değil, tek kuraldan gelsin.

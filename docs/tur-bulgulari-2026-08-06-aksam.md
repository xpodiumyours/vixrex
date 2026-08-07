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

## 3. Kapak fotoğrafı kategoriye uymuyor ve seçilmemiş

**Nerede:** Yayınlanmış vitrin, `/v/dene-dene-yoruldum`

**Ne oluyor:** İşletme dekorasyon kategorisinde, kapakta kot pantolon
fotoğrafı var. Esnaf böyle bir fotoğraf seçmedi.

**Not:** Görüntü production adresinden alındı; B1 düzeltmesi orada yok.
Önizleme adresinde tekrar bakılacak.

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

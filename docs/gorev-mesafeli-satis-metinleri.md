# Görev — Mesafeli satış metinleri ve yasal sayfa bağlantıları

**Yazan:** Claude (28 Ağustos 2026) · **Yürüten:** Codex/Freebuff · **Doğrulayan:** Claude
**Taban:** `main` — dalı **uzak** main'den aç (`git checkout -B <dal> origin/main`)

---

## Neden bu iş

PayTR başvurusu iki kez reddedildi. Ödeme kuruluşları başvuruyu incelerken
sitede şu sayfaların **yayında ve erişilebilir** olmasını arıyor:

- Mesafeli Satış Sözleşmesi
- İptal, İade ve Cayma Hakkı
- İletişim / satıcı kimliği (unvan, adres, telefon, vergi no)

Bugün hiçbiri yok. Ayrıca Mesafeli Sözleşmeler Yönetmeliği m.5, ücretli
hizmet satan her sağlayıcıya bu bilgileri **sözleşme kurulmadan önce**
verme yükümlülüğü getiriyor.

**Kapsam notu:** bu metinler yalnız **Vixrex abonelik hizmetini** kapsıyor.
Dropshipping (fiziksel ürün satışı) başladığında teslimat, kargo ve ürün
iadesi maddeleri ayrıca eklenecek — o ayrı bir iş, şimdi yapma.

---

## Yapılacak

### 1. İki yeni statik sayfa

Örnek alınacak dosya: `public_web/src/app/privacy/page.tsx` — aynı deseni
izle (sunucu bileşeni, arama motoruna açık, `metadata` başlığı olan).

| Yol | Başlık |
|---|---|
| `/mesafeli-satis` | Mesafeli Satış Sözleşmesi |
| `/iptal-iade` | İptal, İade ve Cayma Hakkı |

Metinler aşağıda birebir hazır — **kelime değiştirme, kısaltma, özetleme.**
Hukuki metin; her cümle bir yükümlülüğü karşılıyor.

### 2. Altbilgi bağlantıları

Her iki sayfa da altbilgiden erişilebilir olmalı. Mevcut yasal bağlantıların
(`/privacy`, `/terms`) yanına eklenir. Landing metinleri **çift yönlü
eşitlik bekçisine** bağlı — web'e cümle eklersen ya Flutter'a da ekle ya da
`landingEsitlikIstisnalariWeb.ts` içine gerekçesiyle yaz.

### 3. `vixrex.app@gmail.com` → `destek@vixrex.com`

Üç yerde geçiyor, üçü de değişecek:

- `lib/config/legal_config.dart:26` (`privacyEmail` varsayılanı)
- `public_web/src/app/privacy/page.tsx:18`
- `supabase/seed.sql:40-42`

**ÖN KOŞUL:** posta kutusu gerçekten kurulmadan bu değişikliği yapma.
Çalışmayan bir başvuru adresi yazmak KVKK m.13 başvuru hakkını fiilen
engeller.

### 4. Bekçi testi

`public_web/tests/yasal-sayfa-iletisim.test.ts`:

- `/mesafeli-satis` ve `/iptal-iade` sayfa dosyaları var
- Her ikisinde de satıcı unvanı (`Aksakal Ticaret`), vergi no
  (`0340472476`) ve telefon geçiyor
- Kod tabanında `vixrex.app@gmail.com` **hiç geçmiyor**
- Kod tabanında `privacy@vixrex.app` **hiç geçmiyor**

---

## METİN 1 — `/mesafeli-satis`

**Başlık:** Mesafeli Satış Sözleşmesi
**Alt başlık:** Vixrex abonelik hizmetinin satışına ilişkin ön bilgilendirme ve sözleşme koşulları.

### Madde 1 — Taraflar

**SAĞLAYICI**
Unvan: Aksakal Ticaret (Furkan Aksakal)
Adres: Esenevler Mah. Lokman Hekim Cad. No:18 İç Kapı No:10 Ümraniye/İstanbul
Vergi Dairesi / No: Ümraniye — 0340472476
Telefon: 0542 180 25 73
E-posta: destek@vixrex.com
İnternet adresi: https://vixrex.com

**ALICI**
Hizmeti satın alan ve sipariş sırasında bildirdiği ad, adres, telefon ve
e-posta bilgileri kayıt altına alınan kişi veya işletmedir.

### Madde 2 — Sözleşmenin Konusu

İşbu sözleşmenin konusu, Alıcı'nın Sağlayıcı'ya ait https://vixrex.com
adresli internet sitesi ve mobil uygulaması üzerinden elektronik ortamda
satın aldığı Vixrex dijital vitrin hizmetine ilişkin olarak tarafların hak
ve yükümlülüklerinin belirlenmesidir.

### Madde 3 — Hizmetin Temel Nitelikleri

Vixrex, Alıcı'nın kendi işletmesine ait ad, açıklama, kategori, adres,
iletişim bilgileri, çalışma saatleri, ürün ve hizmet listesi, görseller ve
sosyal medya bağlantılarını dijital bir vitrin sayfası olarak internette
yayınlamasını sağlayan bir yazılım hizmetidir. Hizmet, abonelik süresince
kesintisiz erişime açık tutulur.

Vixrex bir pazaryeri değildir. Alıcı'nın kendi müşterileriyle kurduğu
ticari ilişkiye, tahsilata, kargoya ve iadeye taraf olmaz.

### Madde 4 — Fiyat ve Ödeme

Hizmet bedeli, sipariş anında internet sitesinde gösterilen ve Alıcı
tarafından onaylanan tutardır. Tüm fiyatlar Türk Lirası cinsinden ve
vergiler dâhil olarak gösterilir.

Ödeme, ödeme kuruluşunun sunduğu kredi kartı, banka kartı veya havale/EFT
yöntemleriyle yapılır. Kart bilgileri Sağlayıcı tarafından görülmez ve
saklanmaz; doğrudan ödeme kuruluşunun sistemi üzerinden işlenir.

Sağlayıcı, hizmet bedellerinde değişiklik yapma hakkını saklı tutar. Fiyat
değişiklikleri yürürlüğe girmeden en az 30 gün önce Alıcı'ya e-posta veya
uygulama içi bildirim ile duyurulur. Devam eden ödenmiş dönem için fiyat
değişikliği uygulanmaz.

### Madde 5 — İfa ve Süre

Hizmet, ödemenin onaylanmasının ardından derhâl ve elektronik ortamda ifa
edilir; Alıcı'nın hesabı ve vitrini aynı anda kullanıma açılır. Fiziksel
teslimat söz konusu değildir.

Abonelik belirsiz sürelidir ve Alıcı feshetmediği sürece dönem sonunda
kendiliğinden yenilenir.

### Madde 6 — Cayma Hakkı

Mesafeli Sözleşmeler Yönetmeliği m.15/1-(ğ) uyarınca, elektronik ortamda
anında ifa edilen hizmetler ve tüketiciye anında teslim edilen gayrimaddi
mallar bakımından cayma hakkı bulunmamaktadır.

Alıcı, siparişi onaylayarak hizmetin ifasına derhâl başlanmasını talep
ettiğini ve bu nedenle cayma hakkının bulunmadığını bilerek kabul eder.

Bununla birlikte Alıcı, aboneliğini dilediği zaman, gerekçe göstermeden ve
cezai şart ödemeden feshedebilir. Fesih hâlinde hizmet, ödenmiş dönemin
sonuna kadar sunulmaya devam eder; o döneme ait ücret iade edilmez.

Cayma ve fesih bildirimleri destek@vixrex.com adresine veya 0542 180 25 73
numarasına iletilir.

### Madde 7 — Alıcı'nın Yükümlülükleri

Alıcı, vitrinine eklediği tüm içerikten münhasıran sorumludur. Yanıltıcı
fiyat, taklit ürün, yasa dışı mal ve hizmet tanıtımı yasaktır. Alıcı,
yüklediği içerik üzerinde gerekli haklara sahip olduğunu ve içeriğin üçüncü
kişilerin haklarını ihlal etmediğini beyan eder.

### Madde 8 — Sağlayıcı'nın Yükümlülükleri ve Sorumluluk Sınırı

Sağlayıcı, hizmeti kullanıma hazır tutmakla yükümlüdür; ancak hizmetin
kesintisiz ve hatasız sunulacağını taahhüt etmez. Bakım, güncelleme,
altyapı sağlayıcı kaynaklı arıza ve mücbir sebep hâllerinde geçici
kesintiler yaşanabilir.

Sağlayıcı'nın sorumluluğu, zararın doğduğu tarihten önceki son 12 ayda
Alıcı'nın ödediği toplam hizmet bedeliyle sınırlıdır. Bu sınırlama, kanunen
sınırlandırılamayan sorumluluk hâlleri bakımından uygulanmaz.

### Madde 9 — Kişisel Veriler

Alıcı'nın kişisel verileri, Aydınlatma Metni'nde belirtilen amaç, hukuki
sebep ve saklama süreleri çerçevesinde işlenir. Aydınlatma Metni'ne
https://vixrex.com/privacy adresinden ulaşılabilir.

### Madde 10 — Kayıt ve Delil

İşbu sözleşme elektronik ortamda kurulur ve Sağlayıcı nezdinde saklanır.
Taraflar, uyuşmazlık hâlinde Sağlayıcı'nın sistem kayıtlarının, elektronik
kayıtlarının ve işlem loglarının kesin delil teşkil edeceğini kabul eder.

### Madde 11 — Uyuşmazlıkların Çözümü

İşbu sözleşmeye Türkiye Cumhuriyeti hukuku uygulanır.

Tüketici sıfatını haiz Alıcılar, ilgili parasal sınırlar dâhilinde
Tüketici Hakem Heyetlerine veya kendi yerleşim yerindeki Tüketici
Mahkemelerine başvurabilir. Diğer hâllerde İstanbul Anadolu Mahkemeleri ve
İcra Daireleri yetkilidir.

### Madde 12 — Yürürlük

Alıcı'nın siparişi elektronik ortamda onaylaması ile işbu sözleşme
kurulmuş ve yürürlüğe girmiş sayılır.

---

## METİN 2 — `/iptal-iade`

**Başlık:** İptal, İade ve Cayma Hakkı
**Alt başlık:** Vixrex abonelik hizmetinde iptal ve iade nasıl işler.

### Cayma hakkı neden yok

Vixrex, elektronik ortamda **anında ifa edilen** bir hizmettir. Ödeme
onaylandığı anda hesabınız ve vitriniz kullanıma açılır. Mesafeli
Sözleşmeler Yönetmeliği m.15/1-(ğ) uyarınca, bu nitelikteki hizmetlerde
cayma hakkı bulunmaz.

Siparişi onaylarken hizmetin derhâl başlatılmasını talep etmiş olursunuz.

### Aboneliğinizi istediğiniz zaman iptal edebilirsiniz

Cayma hakkının bulunmaması, aboneliğe mahkûm olduğunuz anlamına gelmez.

- Aboneliğinizi **gerekçe göstermeden** iptal edebilirsiniz.
- **Cezai şart ödemezsiniz**, taahhüt süresi yoktur.
- İptal, hesap ayarlarından veya destek@vixrex.com adresine bildirim ile
  yapılır.
- İptal sonrası hizmet, **ödediğiniz dönemin sonuna kadar** çalışmaya
  devam eder; o dönem bitince yenileme yapılmaz.
- Kullanılmış döneme ait ücret iade edilmez.

### İade yapılan durumlar

Aşağıdaki hâllerde ödediğiniz tutar iade edilir:

1. **Çift tahsilat** — aynı hizmet için mükerrer ödeme alınmışsa fazla
   tutar iade edilir.
2. **Hizmetin hiç sunulamaması** — teknik bir sebeple hesabınız veya
   vitriniz hiç açılmamışsa ödediğiniz tutarın tamamı iade edilir.
3. **Sağlayıcı kaynaklı fesih** — hizmet Sağlayıcı tarafından sonlandırılırsa
   kullanılmamış döneme ait tutar oranlanarak iade edilir.

İade, ödemenin yapıldığı yönteme ve aynı karta yapılır. Talep tarafımıza
ulaştıktan sonra en geç **14 gün içinde** iade işlemi başlatılır. Tutarın
hesabınıza yansıma süresi bankanıza bağlıdır.

### Fiyat değişikliği

Hizmet bedelleri değişebilir. Değişiklik yürürlüğe girmeden en az **30 gün
önce** size bildirilir. Yeni fiyatı kabul etmiyorsanız, bildirimden sonra
ücretsiz ve cezai şart ödemeden aboneliğinizi iptal edebilirsiniz. Devam
eden ödenmiş döneminize zam uygulanmaz.

### Hesabınızın askıya alınması

Kullanım Şartları'nın ihlali, yasa dışı veya yanıltıcı içerik, ödeme
yükümlülüğünün yerine getirilmemesi veya sistemin güvenliğini tehdit eden
kullanım hâllerinde hesabınız askıya alınabilir. Ağır ihlal hâlleri
dışında, askıya almadan önce durumu düzeltmeniz için size makul süre
tanınır. Bu sebeple yapılan fesihlerde iade yapılmaz.

### Bize ulaşın

Aksakal Ticaret (Furkan Aksakal)
Esenevler Mah. Lokman Hekim Cad. No:18 İç Kapı No:10 Ümraniye/İstanbul
Vergi Dairesi / No: Ümraniye — 0340472476
E-posta: destek@vixrex.com
Telefon: 0542 180 25 73

Tüketici sıfatını haiz kullanıcılar, ilgili parasal sınırlar dâhilinde
Tüketici Hakem Heyetlerine veya yerleşim yerindeki Tüketici Mahkemelerine
başvurabilir.

---

## Doğrulama

```
cd public_web && npm run lint && npm test && npm run build
```

Canlıda kontrol (Claude yapacak):
- https://vixrex.com/mesafeli-satis açılıyor
- https://vixrex.com/iptal-iade açılıyor
- Altbilgide ikisinin de bağlantısı var
- Arama motoruna kapalı değil

---

## Kapsam dışı — dokunma

- `supabase/migrations/20260828_legal_documents_v2.sql` — o ayrı, Claude uygulayacak
- Dropshipping / fiziksel ürün iade metinleri — tedarikçi anlaşması olunca
- Sepet, ödeme akışı, PayTR entegrasyonu
- Yeni `document_type` eklemek — `legal_documents` tablosunda CHECK kısıtı
  yalnız privacy/terms/consent/dataDeletion'a izin veriyor; bu metinler
  **statik sayfa** olarak duracak, veritabanına girmeyecek

## Çalışma kuralları

1. Klasörde tek ajan.
2. Dalı uzak main'den aç, `git log --oneline origin/main..HEAD` ile doğrula.
3. Kendi işini kendine denetletme — `code-review` skill'ini çalıştırma.
4. Uzun rapor yazma; bitince dal adını söyle.
5. PR sınırı 12 dosya / 600 satır.
6. Main'e indirme Claude'da.

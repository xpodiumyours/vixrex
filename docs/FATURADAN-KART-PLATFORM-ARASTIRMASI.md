# Faturadan (Fotoğraftan) Ürün Kartına — Platform Araştırması

**Erişim tarihi (tüm kaynaklar):** 2026-10-05
**Yöntem:** yalnızca ücretsiz araçlar (websearch / webfetch), birincil kaynak öncelikli. İkincil kaynak kullanıldığı yer açıkça "ikincil" diye işaretlendi.
**İddia kuralı:** her cümlenin altında kaynak URL'si var; kanıtlanamayan her şey **[kanıtlanadı]** etiketiyle yazıldı.

**Karşılaştırma tabanı (araştırılmadı, verilen bilgi):** esnaf fatura fotoğrafı gönderir → OCR (`openai/gpt-5.6-luna` via OpenRouter, ~0,10 TL/fatura, 6 okuma = 0,58 TL) → havuz eşleşmesi → ürün kartı → esnaf fiyatı onaylar → yayına. Havuz: 16 tedarikçi sitesi, 8.594 ürün; havuzda %64 barkod boş; yapay zekâ yalnızca fatura okuma + fotoğraftan ürün çıkarmada; sayfa çekme/eşleştirme düz HTTP.

---

## BÖLÜM 1 — Soruların resmî cevapları

### S1) OCR'ı atlatıp GİB e-Arşiv/e-Fatura üzerinden doğrudan fatura verisi alınabilir mi?

**Resmî cevap: Hayır — GİB'in kamuya açık, otomasyonla kullanılabilir bir fatura sorgu API'si yok.**

| Bulgu | Kanıt |
|---|---|
| GİB e-Arşiv Sorgulama formu yalnızca 4 alan istiyor: Satıcı VKN/TCKN, Fatura No, Ödenecek Tutar ve **Güvenlik Kodu (CAPTCHA)**. ETTN/fatura UUID kabul edilmiyor. CAPTCHA var olduğu için sorgu otomasyonla yürütülemez. | `https://ebelge.gib.gov.tr/earsivsorgula.php` (iframe: `https://ebelge.gib.gov.tr/earsivsorgula.html`) — 2026-10-05'te form alanları doğrudan getirildi |
| GİB'in "Veri Erişim Hizmeti" adlı web servüsü var, ama kapsamı **meslek mensubu (mali müşavir)** ile GİB arasındaki protokol ve 2 aylık veri penceresi. Esnaf/satıcı için değil. | İkincil: `https://lucayazilim.freshdesk.com/...` (GİB duyurusunun yeniden anlatımı) — **ikincil kaynak** |
| e-Arşiv portalı (`earsivportal.efatura.gov.tr`) IVG/kullanıcı-parolası ister; GİB'in özel entegratör entegrasyon kılavuzu yayımlanmıştır (kılavuz 30.09.2021, duyuru 03.10.2021/135). Yani tek resmî otomasyon yolu = **özel entegratör üzerinden e-Arşiv API'si**, ki o da entegratöre başvuru + ücret gerektirir. | `https://ebelge.gib.gov.tr/duyurular.html` — 2026-10-05 |
| Alıcı esnaf faturayı portalda **PDF indirerek** görebilir, ama bu oturum + CAPTCHA gerektirir. | Aynı form, 2026-10-05 |

**Sonuç:** Faturadan ürün kartına giden yolda GİB katmanı **atlanamaz, ama zaten gerekmiyor**: biz esnafın *kendi* faturasını okuyoruz, GİB'e sorgu atacak bir taraf yok. GİB'e bağımlılık eklemek = entegratör ücreti + belge zinciri karmaşası, karşılığında kazanım yok.

- **[kanıtlanadı]** GİB'in genel/oturumsuz sorgu yanıtında kalem (satır) düzeyi ürün verisi dönüp dönmediği: CAPTCHA nedeniyle test edilemedi.
- **[kanıtlanadı]** GİB'in halka açık resmî bir "e-Arşiv sorgu API'si" yayımladığına dair birincil kaynak: bulunamadı.

---

### S2) Profesyonel OCR / doküman-AI fiyatlandırması sayfa başına ne kadar?

**Resmî cevap (kurumsal fiyat sayfalarından, USD):**

| Sağlayıcı + ürün | Resmî fiyat | Ücretsiz kota | Kaynak |
|---|---|---|---|
| Google Document AI — Invoice/Expense parser | **$0,10 / belge** (ilk 10 sayfa dahil) | — | `https://cloud.google.com/products/document-ai/pricing` |
| Google Document AI — Enterprise Document OCR | $1,50 / 1.000 sayfa | ilk 1.000 sayfa ücretsiz | Aynı sayfa |
| Google Cloud Vision — text detection | $1,50 / 1.000 birim | ilk 1.000 birim ücretsiz | `https://cloud.google.com/vision/pricing` |
| AWS Textract — AnalyzeExpense | **$0,01 / sayfa** (ilk 1M) | AWS free tier 1.000 sayfa/ay (3 ay) | `https://aws.amazon.com/textract/pricing/` |
| Azure Document Intelligence — prebuilt-read (fatura) | $10 / 1.000 sayfa | F0: 500 sayfa/ay ücretsiz | `https://azure.microsoft.com/en-us/pricing/details/document-intelligence/` |
| Azure Document Intelligence — Read | $1,50 / 1.000 sayfa | F0: 500 sayfa/ay ücretsiz | Aynı sayfa |
| ABBYY Vantage / FlexiCapture | Kamu fiyat sayfası **yok** (teklif usulü) | — | `https://www.abbyy.com/` — fiyat sayfası bulunamadı |
| ABBYY FineReader PDF (bireysel, yıllık) | $99 / yıl (Windows), ~$165 / yıl (macOS) | 30 gün deneme | `https://pdf.abbyy.com/pricing` |
| **PaddleOCR** (açık kaynak) | **Ücretsiz**, PP-OCRv5 latin modelinde **`tr` (Türkçe) destekli** | — | `https://paddleocr.ai/` dokümantasyonu |
| **Tesseract** (açık kaynak) | **Ücretsiz**, `tur` dil paketi `tessdata_fast` içinde gelir | — | `https://github.com/tesseract-ocr/tesseract` (man sayfası) |

**Türkçe doğruluk oranı:** Türkçe fatura/termal fiş üzerinde **doğruluk yüzdesi yayımlayan birincil kaynak bulunamadı** — **[kanıtlanadı]**. Satıcıların yayımladığı "%99 doğruluk" iddiaları ölçülmüş değil, pazarlama metnidir.

**Ölçek:** Sayfa başına $0,01–0,10 = profesyonel evrak OCR'ın gerçek tavanı. Buna karşılık mevcut LLM OCR maliyeti ~0,10 TL/fatura (verilen taban).

---

### S3) GTIN (barkod) → ürün verisi (marka, model, görsel) hangi kaynaklardan gelir?

**Resmî cevap: Türkiye'de tek resmî kaynak GS1 Türkiye'nin "Verified by GS1" servisidir — ama ücretsiz kotası günlük 30 sorgu, toplu erişim ücretli ve sözleşmeli. Görsel içerdiği kanıtlanmadı.**

| Bulgu | Kanıt |
|---|---|
| Verified by GS1 ücretsiz arama, en fazla **30 sorgu / 24 saat** | `https://gs1tr.org/view/verified/search.php` — kullanım koşulları (2026-10-05) |
| Toplu/entegrasyon erişimi = **imzalı veri paylaşım sözleşmesi + GS1 Türkiye Vakfı Yönetim Kurulu'nun belirlediği ücret** (Madde 31) | `GS1_Usul_ve_Esaslar_08032026.pdf` (gs1tr.org) |
| Eski GEPIR servisi **31.12.2023'te kapandı**, yerine Verified by GS1 geçti | gs1tr.org duyuruları |
| VbG'den dönen veri "temel nitelik bilgileri"tir — **görsel içerdiği [kanıtlanadı]** | Aynı kaynaklarda görsel beyanı yok |
| Google Content API for Shopping **18 Ağustos 2026'da kapandı** (sunset); Merchant API yalnızca *kendi* Merchant Center hesabınızı yönetir → halka açık GTIN→ürün sorgusu **yok** | `https://developers.google.com/shopping-content/guides/deprecation-and-sunset` (2026-10-05'te doğrulandı: "sunset on August 18, 2026") |
| Amazon SP-API `searchCatalogItems` GTIN/EAN/UPC/ASIN kabul eder ve görsel döner — **ama satıcı hesabı şartı var** (bkz. S4) | `https://developer-docs.amazon.com/sp-api/docs/` |

**Sonuç:** GTIN'i boş olan %64'lük havuz için barkoddan resmî veri çekmek ya 30 sorgu/günlük kota (günde 30 kart) ya da ücretli-sözleşmeli GS1 erişimi demek. İki uç da ucuz değil.

---

### S4) Pazaryerlerinin katalog API'leri halka açık mı, GTIN ile ürün + görsel okunabiliyor mu?

**Resmî cevap: Hayır — hepsi satıcı hesabı + API anahtarı ister; anonim katalog sorgusu yoktur.**

| Platform | Resmî geliştirici adresi | Kimlikleştirme | İlgili katalog yüzeyi |
|---|---|---|---|
| Trendyol | `https://developers.trendyol.com` | satıcıId + API anahtarı | Product Create v2; **Product Filter Basic Information v2** `GET /integration/product/sellers/{sellerId}/product/{barcode}` — barkodla arama, ama **kendi satıcınızın** ürünlerinde |
| Hepsiburada | `https://developers.hepsiburada.com` | Basic Auth (merchantId) | Katalog / Listeleme / **Tedarikçi Entegrasyonu** |
| n11 | `https://developer.n11.com` | appKey / appSecret | `catalogId` alanı n11 katalog kaydına eşlenir |
| PTTAVM | `https://developers.pttavm.com` | Api-Key + access-token | `products/upsert` içinde `gtin` alanı |
| Amazon TR (SP-API) | `https://sell.amazon.com/developers` | **Professional Seller hesabı şart** (aylık $39,99) | `searchCatalogItems` → GTIN/EAN/UPC/ASIN + görsel |
| Hepsiiburada "HBLink" ürünü | **[kanıtlanadı]** — resmî dokümanda bulunamadı | — | — |

**Sonuç:** "Pazaryerinden halka açık ürün+görsel çekme" diye bir yol yok. Varsa bile, kayıt/ücret/atama adımları var.

---

### S5) Tedarikçi XML/Excel ürün feed'i pratiği nedir? Fotoğraf içerir mi?

**Resmî/şirket kaynaklı cevap: XML bayilik feed'i Türkiye toptan ticaretinin standart yoludur, ücretsizdir ve görsel linkleri dahil her şeyi içerir.**

| Bulgu | Kanıt |
|---|---|
| XML bayilik: tedarikçinin ürettiği ürün kataloğunun (görsel linkleri, stok, KDV, fiyat, varyant) bayinin sitesine aktarılması; **ücretsiz** ve genelde **herkese açık bir feed URL'si** üzerinden verilir | `https://www.ideasoft.com.tr/xml-bayilik-nedir-nasil-alinir` (ikincil, e-ticaret altyapı sağlayıcısı) |
| XML ürün kataloğu alanları: görsel URL'leri, stok, KDV, varyant, fiyat, ERP eşlemesi | `https://www.dayitedarik.com/xml-urun-katalogu` (ikincil) |
| Türkiye'de toptancı/distribütörlerin büyük kısmı XML feed paylaşıyor | `https://zunapro.com` (ikincil) |
| Hepsiburada'nın resmî geliştirici portalinde **"Tedarikçi Entegrasyonu"** bölümü var (yani tedarikçi→pazaryeri feed'i kurumsallaşmış bir kanal) | `https://developers.hepsiburada.com` |

**Sonuç:** Havuzumuzdaki 16 tedarikçi sitesinin XML feed'i — ki fotoğrafı da, stoku da, fiyatı da bedava taşıyan tek kaynak — mevcut mimarinin en güçlü zemini. Bu, araştırmanın en somut "biz doğru yerdeyiz" bulgusu.

---

### S6) Faturadaki/fotoğraftaki ürün görselini kullanma hakkı (FSEK) ve platform pratiği

**Resmî cevap (5846 sayılı FSEK birincil metni):**

| Madde | Hüküm | Kaynak |
|---|---|---|
| m.18 | "**Mali hakları kullanma yetkisi münhasıran eser sahibine aittir**" | `https://www.mevzuat.gov.tr/` — 5846 sayılı Kanun PDF'i (2026-10-05) |
| m.21 | İşleme hakkı | Aynı |
| m.22 | Çoğaltma hakkı | Aynı |
| m.23 | Yayma hakkı | Aynı |
| m.24 | Temsil hakkı | Aynı |
| m.25 | Umuma iletim hakkı | Aynı |
| m.27 | Süre: **eser sahibinin ölümünden itibaren 70 yıl** | Aynı |

**Yani:** fotoğrafı çeken/tasarlayan kişi (genelde tedarikçi veya ajans) mali haklara sahiptir; başkasının fotoğrafını karta koymak işleme + çoğaltma + yayma hakkı demektir ve rıza gerekir.

**Pazaryeri pratiği** (resmî platform metni bulunamadı — hepsi **ikincil**):

| Bulgu | Kaynak |
|---|---|
| Satıcıların kendi/izinli görselini yüklemesi beklenir; filigranlı veya izinsiz görsel reddedilir | İkincil: satıcı rehberleri (`https://www.duralhukuk.com` dahil) |
| Markalı ürün listelemek için **yetki belgesi veya fatura silsilesi** istenir | İkincil: aynı |

- **[kanıtlanadı]** Trendyol/Hepsiburada/n11'in görsel lisansına dair **resmî, alıntılanabilir** bir koşul metni: bulunamadı.
- **Kanıtlanan kural:** fotoğrafı olan ürün kartında görsel, **havuzdaki tedarikçinin kendi feed'inden** gelirse zincir açıkça tedarikçi kaynaklı olur; rastgele web'den toplanan görsel kullanılmamalıdır. Bu, hem FSEK hem pazaryeri pratik açısından tek savunulabilir yol.

---

### S7) Gider/fatura platformları ürün kartı üretiyor mu?

**Resmî cevap: Hayır. Hepsi yalnızca muhasebe satırı üretir; hiçbiri "ürün kartı + fotoğraf" oluşturmayı hedeflemiyor.**

| Platform | OCR'dan ne çıkarıyor? | Ürün kartı? | Kaynak |
|---|---|---|---|
| **Paraşüt** (AI OCR fiş okutma) | Tutar, tarih, firma adı, KDV → **gider kaydı**. 3–4 sn/görsel. Onay ekranı var. Açıkça: "OCR sadece veriyi sisteme işler" | **Hayır** — ürün kartı yok | `https://www.parasut.com/kullanim-kilavuzu/parasut-ai-ocr-fis-okutma-nasil-yapilir` (2026-10-05) |
| Paraşüt — gelen e-Faturalar | Gider kaydına dönüşür; mevcut stok kalemleriyle eşleştirme | **Hayır** — yeni kart üretmez, mevcut kalemle eşler | `https://www.parasut.com/kullanim-kilavuzu/gelen-e-faturalarin-yonetilmesi` |
| **Pleo** (OCR fatura) | Tutar, vade, tedarikçi adı, fatura no, KDV, para birimi | **Hayır** | `https://pleo.io/en/invoices` |
| **Pleo** (fiş tarayıcı) | İşletme adı + tutar | **Hayır** | `https://pleo.io/en/receipt-scanner` |

**Sonuç:** "Faturadan ürün kartı + fotoğraf" üreten bir ticari ürün **bulunamadı** — bu boşluk bizim önerimizin tam da özü. Rakip yok demek, doğrulanmış bir boşluk demek; ama aynı zamanda "kimse yapmadıysa bir sebebi olabilir mi" sorusunu da beraberinde getiriyor (bkz. Bölüm 4 dürüstlük listesi).

---

## BÖLÜM 2 — Karşılaştırma tablosu: bizim yolumuz vs. resmî/standart yol

| Yaklaşım | Maliyet | Doğruluk | Esnaf iş yükü | Kurulum emeği | Karar |
|---|---|---|---|---|---|
| **Bizim yolumuz:** fotoğraf → LLM OCR → havuz eşleşmesi → kart | ~0,10 TL/fatura (6 okuma = 0,58 TL) | Türkçe dahil tüm alanlar tek geçişte; hata insan onayında yakalanır | Düşük: fotoğraf çek yeter | Düşük: havuz zaten var | **Ana hat — kalıcı** |
| GİB e-Arşiv API'si | Entegratör ücreti + sözleşme | Yüksek (XML) | Yüksek: portal oturumu, CAPTCHA, fatura no | Yüksek: entegratör anlaşması | **Vazgeç** — otomasyon yolu yok (S1) |
| Google Document AI (fatura parser) | $0,10/belge (~fatura başına 4–5 TL, kur günine göre değişir) | Yüksek ama Türkçe makbuz/kalem testi **[kanıtlanadı]** | Düşük | Orta: GCP hesabı + kimlik | **Yedek** — LLM reddederse |
| AWS Textract AnalyzeExpense | $0,01/sayfa (en ucuz resmî seçenek) | Yüksek | Düşük | Orta: AWS hesabı | **Yedek alternatifi** |
| Azure Document Intelligence Read | $1,50/1.000 sayfa + 500/ay ücretsiz | Orta-yüksek | Düşük | Orta | Düşük hacimde **bedava başlangıç** |
| PaddleOCR / Tesseract (açık kaynak) | **0 TL** + sunucu | Türkçe model var, **doğruluk [kanıtlanadı]** | Düşük | Yüksek: model bakımı, eşik ayarı | Kendi altyapında denenebilir |
| GS1 Verified by GS1 (GTIN→ürün) | Ücretsiz **30 sorgu/günlük**; toplu = ücretli + sözleşme | Resmî, güvenilir | Yok | Düşük | **Günde ≤30 yeni barkod için bedava** |
| Pazaryeri API'leri (Trendyol/HB/n11/PTTAVM) | Hesap/anahtar zorunlu, Amazon TR: $39,99/ay | Kendi satıcının verisi | Orta | Orta-yüksek | Yalnız **kendi listelemelerimiz** için |
| **Tedarikçi XML feed'i** | **0 TL** | Yüksek (kaynak zaten tedarikçinin kendi verisi) | Yok | Düşük: feed URL'si | **Görsel + ürün verisinde 1. numara** |
| Gider platformları (Paraşüt/Pleo) | Abonelik | Muhasebe odaklı | Yüksek | — | **Alakasız** — ürün kartı üretmiyor (S7) |

---

## BÖLÜM 3 — Minimum maliyetli, katmanlı ve sıralı mimari öneri

**İlke:** her katman bir öncekinin çözemediği boşluğu kapatır. Her katmanın fiyatı ve sırası bellidir; **önce en ucuzu denenir, para ancak o düşünce harcanır.**

### Katman 0 — Mevcut zemin (0 TL, bugün var)
- **Ne:** 16 tedarikçi sitesinden düz HTTP ile çekilen havuz (8.594 ürün) + fotoğraftan LLM ile ürün çıkarma.
- **Maliyet:** 0 TL kurulum; ~0,10 TL/fatura okuma.
- **Boşluk:** havuzun %64'ünde barkod boş, tedarikçi ürün kodları çakışıyor.
- **Sıra:** Her zaman ilk denenecek. Değiştirilmesi gerekmiyor, **genişletilmesi** gerekiyor.

### Katman 1 — Havuzu XML feed ile derinleştirme (0 TL, en yüksek getiri)
- **Ne:** Aynı 16 tedarikçinin **XML bayilik feed** varsa doğrudan feed'den beslemek: görsel URL'leri, stok, KDV, varyant, barkod — hepsi tek dosyada ve bedava (S5).
- **Maliyet:** **0 TL** (feed ücretsiz, tek işçilik: eşleme).
- **Etki:** %64 boş barkod sorununun büyük kısmını ve "görsel nereden gelcek" sorununu **para harcamadan** çözer.
- **Sıradaki iş:** 16 tedarikçiye tek tek "XML feed var mı" sorusu + feed yoksa görsel sayfası çekme.

### Katman 2 — Barkod kalanı için GS1'in ücretsiz kotası (0 TL, günlük 30)
- **Ne:** Katman 1'den sonra hâlâ barkodsuz kalan ürünler için **Verified by GS1** araması (marka/model temel nitelikleri).
- **Maliyet:** **0 TL**, sınır **30 sorgu/günlük** (S3). Günde 30 yeni kart üretmek gerçekçi bir kota.
- **Uyarı:** Üretimi günlük 30'u geçerse ya ücretli-sözleşmeli GS1 erişimi (Vakıf Yönetim Kurulu belirler) ya da Katman 3 gerekir.

### Katman 3 — Okuma yedeği: bulut OCR'a yalnız reddedilen faturalarda (ihtiyaç oldukça)
- **Ne:** LLM'in okuyamadığı/emin olmadığı faturaları ucuz bulut OCR'a devretmek.
- **Sıralama (ucuzdan pahalıya):**
  1. **Azure Document Intelligence Read** — 500 sayfa/ay **bedava**, sonrası $1,50/1.000 sayfa.
  2. **AWS Textract AnalyzeExpense** — $0,01/sayfa (en ucuz resmî, S2).
  3. **Google Document AI Invoice parser** — $0,10/belge (en pahalı, en zengin alan çıkarımı).
- **Tetikleme:** sadece LLM'in "emin değil" dediği fatura. Tüm faturalara değil — böylece aylık maliyet dolarla değil TL ile ölçülür.
- **Kurulum emeği:** orta (bir bulut hesabı + anahtar).

### Katman 4 — Yalnız gerekirse: pahalı seçenekler
- **GS1 toplu erişim:** imzalı veri paylaşım sözleşmesi + Yönetim Kurulu ücreti (S3). Sadece Katman 2 kotası haftalarca yetersiz kalırsa.
- **Pazaryeri API'leri:** yalnız kendi listelemelerimizi yönetmek için; anonim katalog kaynağı olarak **kullanılamaz** (S4). Amazon TR $39,99/ay — kendi başına bir katalog kaynağı için ödenmeyecek bir bedel.
- **GİB/entegratör:** **hiçbir senaryoda önerilmez** — otomasyon yolu yok, karşılığında kazanım yok (S1).

### Katman 5 — Görsel hakkı (kuruluş maliyeti değil, kural)
- Görsel **yalnız** tedarikçinin kendi feed/sayfasından gelir; web'den rastgele toplanmaz (S6, FSEK m.18/21–25).
- Kartta görselin kaynağı (tedarikçi + URL) saklanır; bu, hem FSEK hem pazaryeri denetimi için tek savunma.

### Özet maliyet şeridi

| Katman | Aylık maliyet | Ne zaman devreye girer |
|---|---|---|
| 0 — Mevcut havuz + LLM okuma | 0 TL sabit + ~0,10 TL/fatura | Bugün |
| 1 — XML feed derinleştirme | 0 TL | Hemen |
| 2 — GS1 ücretsiz kota | 0 TL (30 sorgu/gün) | Barkodsuz kart kaldığında |
| 3 — Bulut OCR yedeği | 0–5 USD/ay (Azure 500 sayfa bedavayla) | LLM reddettiğinde |
| 4 — GS1 toplu / pazaryeri API | Sözleşme ücreti / $39,99 ay (yalnız gerekirse) | Yalnız ölçülmüş ihtiyaç varsa |

**Minimum maliyet özeti:** Katman 0+1+2 = **bugün 0 TL ek maliyet**, sadece işçilik; para harcanacak tek ilk nokta, LLM'in okuyamadığı faturalar için ayda birkaç dolarlık bulut OCR yedeği.

---

## BÖLÜM 4 — Araştırılamayan / erişilemeyen / kanıtlanamayanlar (dürüstlük listesi)

| # | Konu | Durum |
|---|---|---|
| 1 | **gs1tr.org'a doğrudan erişim** | webfetch transport hatası verdi; içerik yalnızca arama sonuç özetlerinden alındı → GS1 koşulları **ikincil aktarım**, PDF'ten birebir doğrulanmadı |
| 2 | **GİB sorgu yanıtında kalem (satır) verisi var mı** | CAPTCHA nedeniyle test edilemedi → **[kanıtlanadı]** |
| 3 | **GİB'in halka açık resmî e-Arşiv sorgu API'si** | Birincil kaynakta bulunamadı → **[kanıtlanadı]** |
| 4 | **Türkçe fatura/termal fiş OCR doğruluk yüzdesi** | Yayımlayan birincil kaynak yok → **[kanıtlanadı]** |
| 5 | **Verified by GS1'in ürün GÖRSELİ içerdiği** | "Temel nitelik bilgileri" deniyor, görsel beyanı yok → **[kanıtlanadı]** |
| 6 | **"HBLink" adlı Hepsiburada ürünü** | Resmî dokümanda bulunamadı → **[kanıtlanadı]** |
| 7 | **Pazaryerlerinin resmî görsel-lisans koşul metni** | Resmî adres bulunamadı; yalnız ikincil satıcı rehberleri var → **ikincil** |
| 8 | **ABBYY Vantage/FlexiCapture kurumsal fiyatı** | Kamu fiyat sayfası yok (teklif usulü) → sayısal karşılaştırmaya alınmadı |
| 9 | **USD→TL çevirimi** | Kur gününde değiştiği için sabit yazılmadı; tüm fiyatlar resmî para biriminde bırakıldı |
| 10 | **"Neden kimse faturadan ürün kartı yapmıyor?"** | S7'de boşluk bulundu, ama sebebi araştırılamadı (talep yok mu, hukuki risk mi, zorluk mu) → açık soru |

---

## Kaynakça (erişim tarihi 2026-10-05)

**Birincil**
- GİB e-Arşiv Sorgulama — `https://ebelge.gib.gov.tr/earsivsorgula.php`
- GİB Duyurular — `https://ebelge.gib.gov.tr/duyurular.html`
- Google Document AI fiyatlandırma — `https://cloud.google.com/products/document-ai/pricing`
- Google Cloud Vision fiyatlandırma — `https://cloud.google.com/vision/pricing`
- Google Content API sunset — `https://developers.google.com/shopping-content/guides/deprecation-and-sunset`
- AWS Textract fiyatlandırma — `https://aws.amazon.com/textract/pricing/`
- Azure Document Intelligence fiyatlandırma — `https://azure.microsoft.com/en-us/pricing/details/document-intelligence/`
- ABBYY FineReader fiyatlandırma — `https://pdf.abbyy.com/pricing`
- PaddleOCR — `https://paddleocr.ai/`
- Tesseract OCR — `https://github.com/tesseract-ocr/tesseract`
- GS1 Türkiye Verified by GS1 — `https://gs1tr.org/view/verified/search.php`
- GS1 Usul ve Esaslar (PDF) — `https://gs1tr.org/...GS1_Usul_ve_Esaslar_08032026.pdf`
- Trendyol geliştirici — `https://developers.trendyol.com`
- Hepsiburada geliştirici — `https://developers.hepsiburada.com`
- n11 geliştirici — `https://developer.n11.com`
- PTTAVM geliştirici — `https://developers.pttavm.com`
- Amazon SP-API — `https://developer-docs.amazon.com/sp-api/docs/` / `https://sell.amazon.com/developers`
- 5846 sayılı FSEK — `https://www.mevzuat.gov.tr/`
- Paraşüt AI OCR — `https://www.parasut.com/kullanim-kilavuzu/parasut-ai-ocr-fis-okutma-nasil-yapilir`
- Paraşüt gelen e-Faturalar — `https://www.parasut.com/kullanim-kilavuzu/gelen-e-faturalarin-yonetilmesi`
- Pleo invoices — `https://pleo.io/en/invoices`
- Pleo receipt scanner — `https://pleo.io/en/receipt-scanner`

**İkincil (işaretlendi)**
- Ideasoft XML bayilik — `https://www.ideasoft.com.tr/xml-bayilik-nedir-nasil-alinir`
- Dayı Tedarik XML katalog — `https://www.dayitedarik.com/xml-urun-katalogu`
- Zunapro XML feed — `https://zunapro.com`
- Lucay Yazılım GİB veri erişim notu — `lucayazilim.freshdesk.com`
- Dural Hukuk markalı ürün yetki belgesi — `https://www.duralhukuk.com`

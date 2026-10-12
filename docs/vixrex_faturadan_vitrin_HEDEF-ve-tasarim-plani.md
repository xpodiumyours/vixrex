# Faturadan resmî vitrine — hedef ve prototip tasarım planı

**Kapsam:** `vixrex_faturadan_katalog_prototip_v3-coklu-fatura.html` yerine, hedefi **tek bakışta** anlatan yeni prototipin (v4) tasarımı.
**Okuyucu:** Bu planı ve prototipi eline alan herkes — başka bir yapay zekâ ajanı, geliştirici, firma sahibi, insan.
**Kaynak:** `docs/FATURADAN-VITRINE-MASTER-PLAN.md` (F2/F3/F4, §4), `public_web/src/lib/firmaArama.ts`, `faturaDijitalIz.ts`, `firmaDogrula.ts`, `faturaEslestir.ts`, `ureticiKatalog.ts`, `product_image_policy.json`.

---

## 1. Tek cümlelik hedef (prototipin en üstünde, her ekranda görünecek)

> **Hedef:** Faturayı okuyan, faturadaki firmayı tespit eden, firmanın dijital izlerinden resmî web sitesini bulan, fatura satırlarını o resmî siteyle eşleştiren ve ürün kartlarını (görselleriyle birlikte) resmî siteden hazırlayan bir akış.

Bu cümle banner'da, altındaki 5 ok adımının üstünde durur. İzleyen kimse bu cümleyi okumadan bir ekran açmaz.

---

## 2. Zincirin 5 ekranı (v3'teki 4 ekrana firma keşfi ekranı eklenir)

| # | Ekran | Ne kanıtlar | Ekranın üstünde yazan tek satır |
|---|-------|-------------|-------------------------------|
| E1 | **Faturalar** | Hedef tek fatura değil, çoklu fatura akışı | "Her fatura kendi satırlarıyla okunur, hepsi tek vitrine çıkar." |
| E2 | **Firma tespiti** (yeni) | Faturadaki firma + dijital iz + resmî site doğrulaması | "Faturadaki satıcı adı internette araştırılır; resmî site bulunur ve doğrulanır." |
| E3 | **Ürün keşfi ve eşleşme** | Resmî siteden ürün ve görsel, koda/barkoda dayalı eşleşme | "Eşleşme kod/barkodla kurulur; yalnızca ürün adı benzerliği kesin sayılmaz." |
| E4 | **Kartlar** | Kartta gerçek fotoğraf, kaynaklı, görseli olmayan yayınlanmaz | "Görseli olmayan satır kart olmaz." |
| E5 | **Vitrin** | Tüketici görünümü: gerçek görsel + satış fiyatı + stok; alış fiyatı görünmez | "Alış bedeli ve fatura fotoğrafı tüketiciye gitmez." |

### E2 — Firma tespiti ekranının içeriği (bu ekran prototipin kalbidir)

Ekran, kararı **kademeli kanıt** olarak gösterir; hiçbir adımı atlamaz:

1. **OCR satırı:** faturadaki satıcı adı, vergi/adres varsa, belge türü/no/tarih — ham metin olarak korunur (düzeltilmiş hâliyle değil).
2. **Havuz kontrolü:** "Bu firma 55 firmalık listede mi?" → Evet = hızlı yol (jeton tasarrufu), Hayır = arama.
3. **Dijital iz araması:** `"{firma adı} resmi site"` sorgusu. Ekran, **pazar yeri ve sosyal hesapların resmî site sayılmadığını** gri listeyle gösterir: sahibinden, trendyol, hepsiburada, amazon, n11, facebook, instagram, youtube, tiktok, wikipedia.
4. **Resmî site doğrulaması:** alan adında firma adının geçmesi **tek başına yeterli değil** → sitedeki iletişim/adres + birbirine bağlı resmî hesaplar birlikte değerlendirilir. Doğrulama 3 satırlık kontrol listesi olarak görünür.
5. **Durum etiketleri (4 ayrı anlam, birbirine çevrilmez):**
   - `BULUNDU` — resmî site doğrulandı
   - `BULUNAMADI` — arandı, resmî karşılık yok (kaynak hatası değil)
   - `KAPALI` — arama servisi anahtarı yok / süre doldu (kaynak hatası değil, "firma yok" hiç değil)
   - `İPUCU` — esnaf resmî site adresini elle yazabilir, akış durmaz
6. **Satıcı / üretici / marka ayrımı:** toptancının faturasında başka marka bulunması otomatik çelişki değildir; ilgili markanın doğrulanmış kaynağında arama sürer. Bu ayrım ekranda 3 etiketle gösterilir.

### E3 — Ürün keşfi ve eşleşme ekranının içeriği

- **Havuz (yerel katalog) önce** kullanılır — ama ekranda "hızlı yol / jeton tasarrufu" olarak etiketlenir, **hedef olarak değil**.
- Havuzda yoksa → resmî sitede keşif: Shopify/WooCommerce ürün sayfaları, sitemap hedefli arama, yapılandırılmış JSON-LD, resmî PDF katalog, resmî sosyal hesap. "İlk dört sayfaya bakıp ürün yok" ekranda yasaklanmış madde olarak yazar.
- **Eşleşme dayanağı:** firma/marka + model kodu veya doğrulanmış barkod. Varyant tutarlılığı kontrol edilir. "Yalnız ürün adı veya görsel benzerliği kesin eşleşme değildir" uyarısı kart üzerinde durur.
- **Aynı kod birden çok markadaysa** (gerçek belirsizlik) → esnaf seçer. Aynı kod birden çok **mağazadaysa** bu belirsizlik değil, bilgidir: "2 mağazada listeleniyor". (v3'te düzeltildi, aynen korunacak.)

### E4 / E5 — Kart ve vitrin kuralları

- Kartta en az **1 gerçek ürün görseli** zorunlu; resmî kaynakta görsel yoksa kart yayınlanamaz (gri şerit + sayacı düşer). **Görsel yerine üretilmiş görsel/emoji yok.**
- Görselle ürün sayfası bağı kayıtlı: kırık bağlantı, logo, katalog kapağı ürün fotoğrafı sayılmaz.
- **İzin ayrı katman:** izin sorulmadı / cevap bekliyor / verildi / reddedildi — kart hazırlığı ve keşif bunlarda durmaz; sadece yayım reddi izne bağlıdır. "Resmî sitede görünmek izin değildir."
- Tüketici kartında görünmeyenler: alış fiyatı, KDV, fatura fotoğrafı, müşteri kimliği, iç eşleştirme notu, OCR metni.

---

## 3. Yanlış okumayı öldüren 4 savunma satırı (prototipin altında "Bu prototip ne DEĞİL")

1. **"Yerel katalog dosyalarından görsel çekiyor" değil.** Katalog havuzu yalnızca hız içindir; hedef, faturadaki firmayı internette bulup **resmî sitesinden** ürünü ve görseli almaktır. Prototipte hem havuzdan hem "havuzda yok → resmî site" yolu temsil edilir.
2. **"Görsel bulamayınca üretiriz" değil.** Görsel yoksa kart yok; yapay görsel gerçek ürün kanıtı gibi sunulmaz.
3. **"Resmî sitede olan her şeyi paylaşabiliriz" değil.** Veri ve görsel izni ayrı ve zorunlu bir katmandır; izin verilmeden tüketiciye açılmaz.
4. **"Fatura verisi vitrine taşınır" değil.** Vitrine yalnızca marka, açıklama, satış fiyatı, stok ve gerçek görsel geçer; alış ve belge bilgisi sızmaz.

---

## 4. Şeffaflık köşeleri (ajanın "gerçek mi" diye takılmasını engeller)

Her ekranın sol üstünde küçük etiket:
- `DEMO` — sentetik fatura/firma (B1, C1)
- `GERÇEK ÖLÇÜM` — 15.09.2026 fişi, ölçülmüş satırlar (13 satır / 75 adet / 6.034,00 TL)
- `KAYNAK:` — hangi dosyadan türetildi (`fis_4`, katalog havuzu)
- `PROTOTİP — gerçek Vixrex verisine YAZMAZ, hiçbir servise istek atmaz`

Arama/servis adımları (Brave vb.) prototipte **simüle edilir** ve `SİMÜLASYON` etiketi taşır; gerçek anahtar, gerçek yanıt olarak sunulmaz.

---

## 5. Kabul ölçütü (plan bittiğinde bunlar doğru olmalı)

1. Dosya ilk açılışta tek cümlelik hedefi ve 5 adımı gösterir; aşağı kaydırmadan zincir okunur.
2. Bir ajan, prototipe bakıp zinciri şu sırayla yazabilmeli: **fatura → firma → resmî site → eşleşme → kart + görsel** (hiçbir adımda "yerel dosyadan eşleşti" iması yok).
3. Her ekranın üstünde "bu ekranda ne kanıtlanıyor / ne yapılmıyor" kutusu var.
4. 4 savunma satırı prototipte metin olarak mevcut.
5. Chrome'da 5 ekran da ekran görüntüsüyle alınır; yatay taşma yok; kartlar görünür; v2-1 dosyası değişmez.

---

## 6. Uygulama sırası

1. `prototip_v3_sablon.html`'ten fork et (v3'teki düzeltmeler: çoklu fatura, gömülü gerçek görsel, aynı-marka-kuralı korunur).
2. E2 "Firma tespiti" ekranı ekle; okuma animasyonunu bu ekrana bağla.
3. Üst banner + 5 ok + altta 4 savunma satırı.
4. E3'te "havuz = hızlı yol, resmî site = hedef" ayrımını görünür yap.
5. Ekran görüntüsüyle kabul ölçütlerini kontrol et, tek satır sonuç ver.

**Yapılmayacaklar:** gerçek arama anahtarı/servis kullanmak (simülasyon + etiket), gerçek Vixrex verisine yazmak, eski prototiplere dokunmak, izin/kart yazma akışını prototipte uçtan uca kurgulamak.

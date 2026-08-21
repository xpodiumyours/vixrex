# VixRex — Google'da Ürün Kartı ve Yerel SEO Araştırması

**Tarih:** 15 Ağustos 2026
**Soru:** Esnaf vitrinlerindeki ürünler (ve Instagram'dan aktarılan foto/reels içerikleri) Google'da "görünür ürün kartı" hâline nasıl gelir, yerel SEO ile konum bazlı görünürlük ne kadar mümkün?
**Kaynak sınırı:** Google Search Central (developers.google.com/search), Google Merchant Center Yardım (support.google.com/merchants), Google Business Profile Yardım/API dokümanları (support.google.com/business, developers.google.com/my-business), Instagram Yardım Merkezi / Meta Developers. İkincil kaynaklar (blog, ajans siteleri) yalnız birincil kaynağa ulaşamadığım tek bir iddia için (Instagram indeksleme değişikliği, aşağıda açıkça işaretli) ihtiyatla kullanıldı.

> Bu belge bağlayıcı bir SEO garantisi değildir. Google, yapılandırılmış veri sağlansa bile zengin sonuç gösterimini garanti etmez (bkz. §1). Sayılar/tarihler/API durumları yayın tarihinde doğrulanmıştır; Google bu yüzeyleri sık değiştirir.

> **Not (2026-08-21):** Bu belge, aynı günkü daha yüzeysel bir ilk taramanın yerine geçer — repo taraması (§Repo bulguları) somut dosya/satır referanslarıyla ayrıca doğrulandı (2 ana iddia kod üzerinden tekrar kontrol edildi, ikisi de doğrulandı — `price` regex bulgusu doğrulamada beklenenden de ciddi çıktı, bkz. Sıradaki adımlar §1).

---

## Yönetici özeti

| Kanal | Ücretsiz / self-servis mi? | Harici hesap+onay gerekiyor mu? | VixRex'te bugünkü durum |
|---|---|---|---|
| Sayfada `Product` JSON-LD (rich sonuç) | Evet, tamamen ücretsiz — yalnız doğru HTML/JSON-LD yeterli | Hayır | **Zaten var** — `urun/[productSlug]/page.tsx` içinde `productJsonLd` |
| Google Merchant Center'a kayıt (feed + ücretsiz listeleme) | Evet (araç ücretsiz) | **Evet** — hesap açma + site/işletme doğrulaması | Yok |
| Google Business Profile "Ürünler" (manuel ürün editörü) | Evet | **Evet** — GBP hesabı + işletme doğrulaması (video/telefon/posta/e-posta) | Yok; `google_business_link` alanı yalnız dış link olarak tutuluyor |
| Google Business Profile "In-store products" (POS/otomatik senkron) | Araç ücretsiz | **Evet** — GBP + Merchant Center + POS/uygulama entegrasyonu; **yalnız ABD/Kanada/İngiltere/İrlanda/Avustralya** | Yok, coğrafi kapsam dışı (TR yok) |
| `VideoObject` JSON-LD (kendi sayfanda barındırılan/embed video) | Evet, tamamen ücretsiz | Hayır | Yok — hiçbir dosyada `VideoObject` bulunamadı |
| Instagram reels/gönderilerinin doğrudan Google'da çıkması | Instagram tarafında ücretsiz ayar | Hayır (VixRex'in kontrolü dışında — Instagram/Meta tarafında) | VixRex'in etkisi yok; ayrıca içe aktarma özelliği Meta App Review onayı bekliyor |
| `LocalBusiness` JSON-LD (yerel SEO temeli) | Evet, tamamen ücretsiz | Hayır | **Zaten var** — `v/[slug]/page.tsx` içinde `businessType` (`LocalBusiness`/`HairSalon`/`BeautySalon`) |

**En önemli sonuç:** VixRex'in "esnaf kod bilmesin" felsefesiyle en uyumlu adım (kod tarafında, hesapsız, ücretsiz) zaten büyük ölçüde **uygulanmış durumda** — ama gerçek gap'ler var (aşağıda §"Repo bulguları").

---

## 1. Google'da "ürün kartı" — Product structured data ve Merchant Center

### 1.1 Structured data tek başına yeterli mi?

Google'ın resmi "Intro to Product structured data" sayfasına göre, ürün verinizi Google'a ulaştırmanın üç yolu var: sayfaya `Product` structured data eklemek, Google Merchant Center'a veri akışı (feed) yüklemek, ya da ikisini birden yapmak. İkisi de **birbirinden bağımsız, tek başına yeterli** yollardır. ([Intro to Product structured data on Google](https://developers.google.com/search/docs/appearance/structured-data/product))

Bu, 2022'de resmî olarak genişletildi: Google Search Central blogundaki duyuruya göre, önceden "merchant listing" deneyimleri (Alışveriş bilgi paneli, Popüler Ürünler, Google Images/Lens alışveriş deneyimleri gibi zenginleştirilmiş gösterimler) çoğunlukla yalnızca Merchant Center feed'i olan satıcılara açıktı; artık **Merchant Center hesabı olmadan, yalnızca web sayfasındaki `Product` structured data ile de bu deneyimlere uygun olunabiliyor.** ([New Search Console Merchant Listings report: expanding eligibility with Product structured data](https://developers.google.com/search/blog/2022/09/merchant-listings))

Google, hem sayfa structured data'sı hem Merchant Center feed'i sağlamanın uygunluğu (eligibility) maksimize ettiğini ve Google'ın veriyi doğru anlayıp doğrulamasına yardımcı olduğunu belirtiyor — yani ikisi rakip değil, tamamlayıcı. ([aynı kaynak](https://developers.google.com/search/blog/2022/09/merchant-listings))

### 1.2 "Product Snippet" mi, "Merchant Listing" mi — VixRex için kritik ayrım

Google iki farklı deneyimi ayırıyor:

- **Product Snippet:** Ürün hakkında bilgi veren ama **sayfada satın alma gerçekleşmeyen** sayfalar için (ör. inceleme/karşılaştırma sayfaları).
- **Merchant Listing:** **Müşterinin sayfadan doğrudan satın alabildiği** sayfalar için — daha zengin veri (beden, kargo, iade politikası) destekler ve Alışveriş paneli/Popüler Ürünler gibi ek gösterimlere uygunluk sağlar. Google'ın kendi ifadesiyle uygunluk sorusu: *"Can customers purchase products from you? Consider adding merchant listing markup."* ([How To Add Merchant Listing Structured Data](https://developers.google.com/search/docs/appearance/structured-data/merchant-listing))

**VixRex'e uygulanışı:** Ürün sayfaları "sipariş" değil "WhatsApp'tan sor" akışı sunuyor — sayfada gerçek bir checkout/satın alma yok. Google'ın dokümanları bu senaryoyu (iletişim/teklif isteme akışı) açıkça "satın alma" saymıyor; dolayısıyla VixRex ürün sayfaları muhtemelen tam "Merchant Listing" uygunluğundan çok "Product Snippet" davranışına daha yakın duruyor. Bu, mevcut `productJsonLd`'nin (aşağıda incelendi) çalışmayacağı anlamına gelmez — Google structured data'yı okur, hata vermez — ama SERP'te fiyat/yıldız gösteren tam "alışveriş kartı" deneyiminin garanti olmadığı, yalnızca daha temel bir zengin sonucun beklenebileceği anlamına gelir. Bunu netleştiren tek kaynak product-snippet dokümanının kendisidir; net bir "iletişim CTA'sı satın alma sayılır mı" cümlesi Google dokümanlarında yer almıyor — bu kısım yorum, kesin hüküm değil.

### 1.3 Zorunlu ve önerilen alanlar (Merchant Listing)

Google'ın "How To Add Merchant Listing Structured Data" sayfasına göre zorunlu alanlar: `name`, `image`, `offers` (bir `Offer` nesnesi içinde `price` — sıfırdan büyük — ve ISO 4217 `priceCurrency`). Önerilen (ama zorunlu olmayan) alanlar: `aggregateRating`, `review`, `availability`, `itemCondition`, `description`, `brand`, `sku`/`gtin`. ([How To Add Merchant Listing Structured Data](https://developers.google.com/search/docs/appearance/structured-data/merchant-listing))

`LocalBusiness` structured data'da ise zorunlu alanlar yalnızca **işletme adı** ve **fiziksel adres** (`PostalAddress`: sokak, şehir, bölge, posta kodu, ülke). ([Local Business (LocalBusiness, Restaurant, ...) structured data](https://developers.google.com/search/docs/appearance/structured-data/local-business))

### 1.4 Garanti yok

Google, structured data sağlanmasının zengin sonuç olarak gösterileceğini **garanti etmediğini** açıkça belirtiyor — Google'ın algoritmaları, mevcut yönergelere uyan tüm sayfalarda zengin sonucu göstermeyebilir. ([Local Business structured data — genel uyarı, tüm structured data sayfalarında tekrarlanan standart Google ifadesi](https://developers.google.com/search/docs/appearance/structured-data/local-business))

### 1.5 Puan/yorum (aggregateRating) — dikkat: politika riski

Google'ın review-snippet politikası, **incelenen tarafın kendi hakkındaki puanları kontrol ettiği** durumları (self-serving reviews) star-özelliği için **uygunsuz** sayıyor; "ratings must be sourced directly from users" ve "don't rely on human editors to create, curate, or compile ratings" şartları var. ([Review snippet — General guidelines](https://developers.google.com/search/docs/appearance/structured-data/review-snippet))

**VixRex'e uygulanışı:** `stores.rating_score` / `stores.review_count` alanları VixRex panelinde esnaf tarafından girilen/serbest sayılar gibi görünüyor (üçüncü taraf bağımsız bir inceleme platformundan gelmiyor). Bu değerleri doğrudan `Product`/`LocalBusiness` JSON-LD'sinde `aggregateRating` olarak yayınlamak Google'ın self-serving review politikasına aykırı olabilir ve zengin sonucun bastırılmasına (manuel eylem riskine kadar) yol açabilir. Şu an kod bu alanları JSON-LD'ye **koymuyor** (yalnız UI'da `showStorefrontRating` ile gösteriyor) — bu doğru bir temkinlilik, korunmalı.

---

## 2. Google Business Profile "Ürünler" — API mi, yalnız arayüz mü?

### 2.1 API yüzeyinin durumu

Google, 2022'de tekil "My Business API"yi emekliye ayırıp beş ayrı amaç odaklı API'ye böldü (Account Management, Business Information, Notifications, vb.) — bunlar 2026 itibarıyla aktif ve bakımlı. Ancak **bu API ailesinde "Products" (ürün kataloğu) için ayrı, genel bir kaynak/endpoint yok.** Resmî "deprecation schedule" sayfası taranmış, ürünlerle ilgili herhangi bir endpoint adı geçmiyor. ([Deprecation schedule | Google Business Profile APIs](https://developers.google.com/my-business/content/sunset-dates))

Sonuç: Google, geçmişte ürün yönetimini programatik (API) yapmayı desteklemiyor gibi görünüyor; ürün ekleme akışı **arayüz-öncelikli** (Business Profile web/uygulama editörü, POS entegrasyonları) — genel geliştirici API'si üzerinden değil.

### 2.2 Ürün ekleme yolları (arayüz üzerinden, API değil)

Google Business Profile Yardım'a göre üç yol var:

1. **Product editor (manuel):** Business Profile → "Ürünleri düzenle" → "Ürün ekle". Barkodu olmayan ürünler için; işletmenin "fiziksel mal satan yerel mağaza" olması gerekiyor. Eğer işletmeye zaten bir Merchant Center hesabı bağlıysa, "Ürünleri düzenle" sizi doğrudan Merchant Center'a yönlendiriyor — yani bağlı değilse Merchant Center hesabı **şart değil**, bağlıysa yönetim oraya kayıyor. ([About product editor](https://support.google.com/business/answer/9124203?hl=en))
2. **Local Inventory app / POS entegrasyonu:** Clover, Square, Lightspeed gibi POS sistemleriyle otomatik senkron; bu yol **Merchant Center hesabı gerektiriyor**. ([Manage products in Merchant Center](https://support.google.com/business/answer/13161234?hl=en))
3. **In-store products (Google Alışveriş vitrin ürünleri):** Bu, sadece **ABD, Kanada, İngiltere, İrlanda ve Avustralya**'da uygun işletmeler için sunuluyor — Türkiye kapsam dışı. ([Showcase in-store products on Google Search & Maps](https://support.google.com/business/answer/9934993?hl=en))

**VixRex'e uygulanışı:** GBP "Ürünler" özelliği esnafın **kendisinin, kendi Google hesabıyla** girmesi gereken bir şey — VixRex'in Next.js/Flutter kod tabanından programatik olarak bu ürünleri Google'a "push" edebileceği genel bir API yok. VixRex olsa olsa esnafa "GBP hesabını doğrula, şu adımları izle" rehberliği verebilir; ürünü otomatik senkronlayamaz (POS entegrasyonu olmadıkça, ki o da coğrafi/donanım bağımlı).

### 2.3 İşletme doğrulaması (verification) gereksinimleri

Business Profile doğrulaması; telefon, e-posta, video, posta kartı (postcard) ve (Search Console'da site zaten doğrulanmışsa) anlık doğrulama gibi birden çok yöntemle yapılabiliyor; hangi yöntemin sunulacağı işletme kategorisine ve geçmişe göre değişiyor, posta kartı 5-14 gün sürebiliyor. Bu, VixRex'in kontrolü dışında, tamamen esnafın kendi Google hesabı üzerinden yürüttüğü bir süreç. (İkincil kaynaklardan derlenen özet; Google'ın kendi "Verify your Business Profile" yardım sayfası birincil kaynaktır ama bu oturumda doğrudan alıntı çekilemedi — kaynak sınırlaması olarak işaretlendi.)

---

## 3. Video içerik — reels/shorts Google'da nasıl görünür?

### 3.1 `VideoObject` zorunlu alanları

Google'ın video structured data dokümanına göre üç alan **zorunlu**: `name` (başlık, her video için benzersiz metin), `thumbnailUrl`, `uploadDate` (ISO 8601). Video dosyasının konumu için `contentUrl` (gerçek dosya, tercih edilen) veya alternatif olarak `embedUrl` (oynatıcı sayfası) kabul ediliyor — ikisi de geçerli, biri diğerinin zorunlu ön koşulu değil: *"If `contentUrl` isn't available, provide `embedUrl` as an alternative."* Önerilen ek alanlar: `description`, `duration` (ISO 8601), `interactionStatistic`. ([Video (VideoObject) structured data](https://developers.google.com/search/docs/appearance/structured-data/video))

### 3.2 Video barındırma yeri — kendi sayfa mı, Instagram mı?

Google'ın video SEO rehberi, video sonuçlarının bir "izleme sayfası" (watch page) — kararlı, kendine ait URL'i olan bir sayfa — gerektirdiğini vurguluyor; desteklenen formatlar arasında video site haritaları (sitemap) ve `VideoObject` yer alıyor. ([Video best practices](https://developers.google.com/search/docs/appearance/video))

**Instagram'ın kendi sayfası crawl edilebilir mi?** Burada tek doğrulanabilir birincil-kaynak-benzeri iddia şu: Meta, 10 Temmuz 2025'ten itibaren profesyonel (işletme/içerik üretici) hesapların herkese açık gönderilerinin (reels dahil) Google/Bing tarafından varsayılan olarak indekslenmesine izin verdiğini duyurdu; kullanıcı bunu hesap ayarlarından kapatabiliyor. **Kaynak sınırlaması:** Instagram'ın kendi Yardım Merkezi sayfalarını (`help.instagram.com/673535278719288`, `help.instagram.com/147542625391305`) bu oturumda doğrudan çekmeye çalıştım; sayfalar JavaScript ile render edildiği için içerik alınamadı — bu da aslında sorunun bir parçası olan "Instagram JS-ağırlıklı, otomatik araçlarla okunması zor" gözlemini destekliyor. Bu yüzden bu tarih/kapsam bilgisi yalnızca çok sayıda birbirini doğrulayan **ikincil** basın kaynağına dayanıyor (ör. [PPC Land](https://ppc.land/instagram-content-becomes-searchable-on-google-starting-july-10/), [Search Engine World](https://www.searchengineworld.com/its-live-instagram-posts-are-ranking-and-showing-in-google-and-bing-seo-meets-social)) ve VixRex bunu birincil kaynaktan teyit etmeden kesin gerçek olarak kullanmamalı.

Ayrıca Instagram'ın kendi platform API'si (Instagram Graph API / Instagram Platform), üçüncü taraf uygulamaların kullanıcı medyasını (Business/Creator hesabından, App Review sonrası) çekip kendi sitesinde göstermesine ve gömmesine ("Embed Instagram photo and video posts in your websites") izin veriyor — VixRex'in içe aktarma özelliği bunu kullanıyor ve tam da App Review onayını bekliyor. ([Instagram Platform](https://developers.facebook.com/docs/instagram-platform))

**Teknik sonuç (mantıksal çıkarım, ikisi de resmî kaynaklı iki ayrı gerçekten):**
- Instagram'ın kendi sayfasının doğrudan Google'da çıkması artık (Meta'nın duyurduğu politika değişikliğiyle) mümkün olabilir — ama bu VixRex'in kontrolünde değil, Instagram/Meta'nın kontrolünde ve **her esnafın hesap ayarına bağlı**.
- VixRex'in kendi vitrin sayfasında videoyu barındırmak veya en azından `VideoObject` + `embedUrl` ile Instagram'a referans vermek, Google'ın **resmî ve garantili** watch-page/structured-data mekanizmasını kullanır — bu VixRex'in kontrolündedir ve Instagram'ın politika değişikliklerine bağımlı değildir. Bu yüzden VixRex'in kendi sayfasında schema eklemek, teknik güvenilirlik açısından Instagram'ın kendi indekslenmesine güvenmekten daha sağlamdır.

---

## 4. Yerel SEO — `LocalBusiness` + `Product` birlikte kullanımı

Google'ın resmi `LocalBusiness` dokümanı, zorunlu alanları (`name`, `address`) karşılamanın "içeriğinizi zengin sonuç için uygun hale getirdiğini" söylüyor, ama görünürlüğü **garanti etmiyor**; "near me" / bölgesel sıralama ayrı bir sıralama sinyalleri kümesine (mesafe, ilgi, öne çıkma — prominence) dayanıyor ve bu sinyaller Google Business Profile'dan besleniyor, `LocalBusiness` structured data'sı GBP'nin **yerine geçmiyor**, onu **tamamlıyor** — ikisinin ilişkisi Google'ın `LocalBusiness` dokümanında açıkça tartışılmıyor (dokümanın kendisi bu konuda sessiz). ([Local Business structured data](https://developers.google.com/search/docs/appearance/structured-data/local-business))

**VixRex'e uygulanışı:** Kod tabanında `businessType` zaten kategoriye göre (`HairSalon`/`BeautySalon`/`LocalBusiness`) seçiliyor, `address`+`geo` (lat/long) + `openingHoursSpecification` dolduruluyor — bunlar `LocalBusiness`'ın hem zorunlu hem önerilen alanlarının çoğunu karşılıyor. Ama **`Product` şemasındaki `offers.seller`**, sadece `{"@type": "LocalBusiness", "name": store.name}` — adres/geo/`@id` referansı içermiyor (bkz. §Repo bulguları, doğrulandı). Google'ın ürün + yerel işletme birlikteliği için ideali, `seller`'ın işletme sayfasındaki `LocalBusiness` düğümüne `@id` ile referans vermesi (VixRex zaten `v/[slug]/page.tsx`'te `${publicUrl}#business` `@id`'sini üretiyor — ürün sayfasında bu `@id` kullanılmıyor, bağımsız bir `seller` nesnesi kuruluyor).

---

## 5. Maliyet/erişim matrisi — ayrıntılı

| Yüzey | Maliyet | Hesap/onay gereksinimi | Esnaf eforu | VixRex'in kod-tarafı katkısı |
|---|---|---|---|---|
| `Product` JSON-LD (product snippet seviyesi) | Ücretsiz | Yok | Sıfır (otomatik) | Tam — kod ekler, esnaf hiçbir şey yapmaz |
| `Product` JSON-LD (tam merchant listing) | Ücretsiz | Yok, ama "satın alma sayfada gerçekleşmeli" belirsizliği var | Sıfır | Kod ekler; VixRex'in "sipariş" akışı olmadığı için tam uygunluk garanti değil |
| Google Merchant Center (feed + ücretsiz listeleme) | Araç ücretsiz | **Var** — hesap açma + site doğrulama (Search Console benzeri) | Orta (esnaf ya da VixRex hesap açar, doğrular) | VixRex feed'i otomatik üretebilir ama hesabı esnaf adına açmak/doğrulamak insan işi |
| GBP Product editor (manuel) | Ücretsiz | **Var** — GBP hesabı + işletme doğrulama (video/telefon/posta/e-posta, günler sürebilir) | Yüksek (esnaf bizzat girer) | Yok — API yok, VixRex bunu otomatikleştiremez |
| GBP Local Inventory / POS senkron | Araç ücretsiz | **Var** — GBP + Merchant Center + POS entegrasyonu | Yüksek | Yok, coğrafi+donanım kısıtlı |
| `VideoObject` JSON-LD (VixRex'te barındırılan video) | Ücretsiz | Yok | Sıfır | Tam — kod ekler |
| Instagram içeriğinin Google'da doğrudan çıkması | Ücretsiz | Instagram hesap ayarı (VixRex dışı) | Düşük (bir ayar) ama VixRex kontrolünde değil | Yok |
| Instagram içe aktarma (VixRex'e ürün/foto çekme) | Ücretsiz (Meta API) | **Var** — Meta App Review onayı (şu an bekliyor) | Düşük (bir kere OAuth) | Kod hazır, onay bekleniyor (`INSTAGRAM_SYNC_ENABLED=false`) |
| `LocalBusiness` JSON-LD | Ücretsiz | Yok | Sıfır | Tam — zaten var |

**"Esnaf kod bilmesin, tek tık, hızlı" felsefesiyle uyum sırası (yalnız teknik gerçek, değerlendirme kısa):** JSON-LD tabanlı üç madde (`Product`, `VideoObject`, `LocalBusiness`) felsefeyle tam uyumlu — hiçbir esnaf etkileşimi gerektirmiyor. GBP ve Merchant Center maddeleri, esnafın kendi Google kimliğiyle doğrulama yapmasını gerektirdiği için felsefeyle **doğası gereği** gerilimli; VixRex olsa olsa rehberlik/ön-doldurma sağlayabilir, süreci esnaf adına tamamen yürütemez.

---

## Repo taraması bulguları

### `public_web/src/app/v/[slug]/page.tsx` (mağaza sayfası)

- `generateMetadata`: `title`, `description`, `canonical`, Open Graph, Twitter Card — hepsi dolu (satır 296-341).
- JSON-LD `@graph` içinde (satır 567-623):
  - `businessType` (`LocalBusiness`/`HairSalon`/`BeautySalon`, kategoriye göre seçiliyor — satır 521-531), `address`+`PostalAddress`, `geo`+`GeoCoordinates`, `openingHoursSpecification` (satır 570-593) — Google'ın zorunlu (`name`, `address`) ve çoğu önerilen alanını karşılıyor.
  - `WebPage` düğümü.
  - `ItemList` (ürünlerin `@id`/`url`/`name`'i, en fazla 12 ürün) — bu **`Product` değil**, yalnızca bir liste; ürün-seviyesi zengin sonuç bu düğümden gelmiyor, asıl `Product` şeması ürün detay sayfasında.
  - `BreadcrumbList`.
  - **`aggregateRating` yok** — §1.5'teki self-serving-review riskinden kaçınılmış, iyi.

### `public_web/src/app/v/[slug]/urun/[productSlug]/page.tsx` (ürün sayfası)

- `generateMetadata`: dolu, ürün görseli OG/Twitter'a veriliyor (satır 143-184).
- `productJsonLd` (satır 225-251): `@type: Product`, `name`, `description`, `image`, `brand` (mağaza adı), `category`, `offers` (`availability`, `priceCurrency: "TRY"`, `price`, `url`, `seller`).
- `breadcrumbJsonLd` (satır 253-276): ayrı `BreadcrumbList`.

**Somut eksik/risk noktaları — 2026-08-21'de kod üzerinden yeniden doğrulandı:**

1. **`price` alanı kırılgan — DOĞRULANDI, tahmin edilenden ciddi** (satır 244): `product.price?.match(/\d/) ? product.price.replace(/[^0-9.,]/g, "").replace(",", ".") : undefined`. `price`, `price_text || price_amount+currency` olarak geliyor (satır 107-110). Regex yalnız rakam/nokta/virgül BIRAKIYOR — aralık fiyatlarda ("150-200 TL") `-` işareti de silindiği için sonuç **"150200"** gibi anlamsız bir sayı oluyor. Türkçe biçimli fiyatlarda ("1.250,50 TL") da bozuluyor: nokta zaten binlik ayracıyken virgül de noktaya çevrilince **"1.250.50"** gibi geçersiz (iki nokta üst üste) bir `price` değeri üretiyor. Google'ın merchant listing'i `price`'ı **zorunlu** sayıyor (§1.3) — bu alan bozuk/eksik kaldığında zengin sonuç uygunluğu düşebilir.
2. **`offers.seller` kopuk — DOĞRULANDI** (satır 246-249): yalnız `{"@type": "LocalBusiness", "name": store.name}` — mağaza sayfasındaki zengin `LocalBusiness` düğümüne (`${publicUrl}#business`, satır 607'de üretiliyor, adres/geo/telefon dolu) **`@id` ile referans vermiyor**. Bugün iki düğüm birbirinden kopuk.
3. **`VideoObject` hiçbir yerde yok.** Instagram reels/shorts içe aktarıldığında (`INSTAGRAM_SYNC_ENABLED=true` olduğunda) bu içerikler muhtemelen `imageUrls` gibi statik görsellere indirgenecek; video için ayrı bir şema/alan planlanmamış görünüyor (`ProductItem` tipinde `videoUrl` gibi bir alan yok — `public_web/src/lib/products.ts`).
4. **`aggregateRating`/`review` ürün JSON-LD'sinde yok** — §1.5'teki riskten kaçınılmış (muhtemelen bilinçli), korunmalı.
5. **`sku`/`gtin`/`mpn` yok** — el yapımı/yerel esnaf ürünlerinde genelde zaten mevcut olmayacağından bu düşük öncelikli bir eksik (Google bunları yalnız "önerilen", zorunlu değil).

### `public_web/src/lib/vitrinProfile.ts`

- Kategori bazlı `family` (`product`/`service`/`venue`) ve `PrimaryActionId` (`whatsapp`/`maps`/`booking`/`website`) modeli var — Google `businessType`'ı belirlemekte kullanılan `store.kategori` ile bu profil dosyası **ayrı** eşleştirme mantıkları kullanıyor (`page.tsx` basit `includes()` kontrolü yapıyor, `vitrinProfile.ts`'teki zengin kategori haritasını kullanmıyor). Bu, gelecekte daha fazla schema.org `@type` (ör. `Bakery`, `ClothingStore`, `Restaurant`) eklenmek istendiğinde `vitrinProfile.ts`'teki kategori haritasına bağlanarak genişletilebilir — bugün bağlı değil.

### `lib/config/instagram_sync_config.dart`

- `INSTAGRAM_SYNC_ENABLED` derleme-zamanı flag'i, varsayılan `false`. Yorum satırları Meta App Review onayını beklediğini doğruluyor. Bu flag açıldığında içe aktarılacak veri modelinin (fotoğraf + video/reels ayrımı) bugünkü `ProductItem` tipinde henüz karşılığı yok (yalnız `imageUrls`, video alanı planlanmamış) — §"Repo bulguları" madde 3 ile aynı gap.

---

## Sıradaki adımlar (öncelik sırası, gerçekçi)

**1. En düşük çaba / en yüksek etki — kod-tarafı, hesapsız, ücretsiz (esnaf hiçbir şey yapmaz):**

- **Ürün `price` alanını sağlamlaştır** (`urun/[productSlug]/page.tsx` satır ~244): fiyat serbest metinse ve net bir sayı çıkarılamıyorsa `offers.price`'ı tamamen `undefined` bırakmak yerine, ya `price_amount` alanını (varsa) doğrudan kullan ya da `priceValidUntil`/aralık fiyat için Google'ın desteklediği `priceSpecification` yaklaşımına bak — bugünkü regex kırılgan (2026-08-21'de kod üzerinden doğrulandı, düzeltme henüz yapılmadı).
- **`offers.seller`'ı mağaza sayfasındaki `LocalBusiness` düğümüne `@id` ile bağla** (`${publicUrl.replace(/\/urun\/.*/, '')}#business` gibi) — iki dosyada zaten üretilen veriyi birbirine referanslamak, ek veri toplamadan yerel-SEO tutarlılığını artırır.
- **`VideoObject` desteğini `ProductItem` tipine ekle** (`public_web/src/lib/products.ts`): Instagram reels içe aktarma açıldığında (`INSTAGRAM_SYNC_ENABLED=true`) videoyu VixRex'in kendi sayfasında barındırmak/embed etmek ve `name`+`thumbnailUrl`+`uploadDate` (zorunlu üçlü) + `contentUrl`/`embedUrl` ile JSON-LD üretmek — bu, Instagram'ın kendi indekslenmesine güvenmekten daha güvenilir (§3.2). Bu iş, Instagram onayından **bağımsız olarak** şimdiden veri modeli tarafında hazırlanabilir (ör. `videoUrl`/`videoThumbnailUrl`/`videoUploadedAt` alanları migration'la eklenip UI hazır olduğunda kullanılabilir hale getirilebilir).

**2. Orta çaba — kod + tek seferlik karar, hesapsız:**

- Ürün sayfasının "satın alma" değil "iletişim" akışı sunduğu göz önüne alınarak, Google'a **product snippet** olarak daha net sinyal vermek (§1.2) — ya da tersine, gerçek bir "sipariş formu"/"stok rezervasyonu" akışı eklenirse tam merchant-listing uygunluğuna geçiş planlanabilir. Bu bir ürün kararı, araştırma kapsamı dışında.

**3. Yüksek sürtünme — esnafın harici hesap açıp doğrulaması gerekiyor, VixRex yalnız rehberlik edebilir:**

- **Google Merchant Center**: VixRex ürün feed'ini otomatik üretebilir (teknik olarak ucuz) ama hesabı esnaf adına açma/doğrulama insan-insan sürtünmesi gerektirir; VixRex "esnaf kod bilmesin" felsefesiyle en çok gerilen adım budur.
- **Google Business Profile Ürünler**: API yok (§2.1) — VixRex bunu otomatikleştiremez, yalnızca esnafa "GBP hesabını doğrula, şu ürünleri gir" türünde bir kontrol listesi/rehber verebilir. Doğrulama günler sürebilir (§2.3).
- **GBP In-store products**: Türkiye kapsam dışı (§2.2) — bugün için tamamen ele alınamaz, coğrafi kısıt VixRex'in kontrolünde değil.

**Not:** Bu belge yalnızca teknik gerçekleri ve mevcut kod durumunu tespit eder; hangi adımın hangi sprint'te yapılacağına dair karar kullanıcıya aittir.

# Vitrin Alan Şeması — İnsan Tarafı

Bu doküman, esnafın vitrininde düzenleyebildiği **46 alanın** her birinin
Vixrex içinde gerçekte ne işe yaradığını, boş kaldığında neyin kaybolduğunu
ve otomatik doldurulup doldurulamayacağını tek tabloda toplar.

**Tek doğru kaynak kodda kalır.** Bu dosya `public_web/src/lib/vitrinFieldSchema.ts`
dosyasındaki `VITRIN_FIELDS` listesinin insan tarafı özetidir — alan
eklenir/değişirse önce oradaki satır güncellenir, bu doküman ondan türetilir.
Aşağıdaki dört koddan derlenmiştir:

- `public_web/src/lib/vitrinFieldSchema.ts` — alan tanımları, `neden` metinleri, `zorunlu`/`kalite`/`otomatikDoldurulabilir` işaretleri
- `public_web/src/lib/vitrinReadiness.ts` — "boş mu / işlemiş mi" ve önem sınıflandırma kuralı (`alanOnemi`, `doluMu`)
- `public_web/src/app/v/[slug]/page.tsx` — alanların gerçekte sayfada, SEO meta verisinde ve `schema.org` JSON-LD'de nasıl kullanıldığı
- `public_web/src/lib/otomatikVitrinIcerik.ts` — asistanın kiralanan şablonu doldururken hangi alanlara dokunduğu/dokunmadığı

Bu dosya birkaç yerde koddan zaten referans veriliyordu (`owner-accept-legal/route.ts`,
`vixrex_guidance_service.dart`, `vixrex_profile_snapshot.dart`, `store_data.dart`) ama
repo'da karşılığı yoktu — bu doküman o boşluğu dolduruyor.

> **Kapsam notu:** Bu doküman yalnız "46 alan Vixrex'te ne işe yarar?" sorusunu
> cevaplar — esnaf danışma isteğinde tarif edilen dört adımlı planın **birinci
> adımı**. "Hangi alan hangi işletme türü için ne kadar önemli?" eşleştirmesi
> (esnaf bilgi tabanı + alan×esnaf ilişkisi + gerçek kullanım verisiyle
> doğrulama) ayrı, sonraki bir iştir ve burada ele alınmadı. `otomatikVitrinIcerik.ts`
> içindeki `KATEGORIYE_OZEL_METIN` (4 alan × 19 kategori) o yöndeki tek mevcut
> tohum — herhangi bir önem eşleştirmesi değil, yalnız otomatik metin üretimi.

## Önem sınıfları

`vitrinReadiness.ts`'teki `alanOnemi()` her alanı üç sınıftan birine koyar —
sıralama önceliklidir (bir alan hem `zorunlu` hem `kalite` olamaz):

| Önem | Ne anlama gelir | Boşken ne olur |
|---|---|---|
| **temel** (`zorunlu: true`) | Vitrinin yayında durabilmesi için şart. | `temelTamam=false` — vitrin yayına hazır sayılmaz, rehber bunu her zaman ilk sırada ister. |
| **kalite** (`kalite: true`) | Yayına engel değil ama vitrini "şablon" değil "gerçek işletme" gibi gösterir. | Doluluk yüzdesini düşürür; rehberin ikinci turunda önerilir; aşağıda alan bazında somut karşılığı var. |
| **isteğe bağlı** | Ne yayına engel ne genel kalite skoruna dahil. | İlgili küçük bileşen/satır/bölüm görünmez; "eksik" listesine hiç girmez. |

46 alanın **6'sı temel**, **8'i kalite**, **32'si isteğe bağlıdır**.

`otomatikDoldurulabilir: true` ayrı bir boyuttur (önemle çakışabilir): asistan
kiralanan bir şablonu kategoriye göre uyarlarken bu alanlara kendi metnini
yazabilir. **Hiçbir zaman** otomatik doldurulmayan alanlar bilinçli bir
kural: gerçek işletme kimliği (ad, WhatsApp, adres, il/ilçe, çalışma
saatleri, ürünler), sahte olamayacak "hikâye" metni (`hakkindaMetin`),
yanlışsa utandırıcı ince ayrımlar (`isletmeTuru`) ve kampanya bandı (`bant*`
— gerçek kampanya yoksa asistan sahte fiyat/indirim yazmaz, bölümü kapalı
bırakır).

---

## Hero / işletme kimliği (`bolum: hero`)

| Anahtar | Kolon | Tip | Önem | Ne işe yarar | Boşsa ne olur | Otomatik |
|---|---|---|---|---|---|---|
| `isletmeAdi` | `name` | metin | **temel** | Müşterinin ilk gördüğü isim; sayfa `<title>`, Google araması, paylaşım kartı ve `schema.org` `name` alanı buradan gelir. | Vitrin yayına alınamaz (`temelTamam=false`); SEO başlığı ve JSON-LD kimliksiz kalır. | Hayır |
| `heroRozet` | `hero_badge` | metin | kalite | Adının yanındaki küçük vurgu — seni benzer işletmelerden ayıran cümle. | Hero'da ayırt edici vurgu görünmez, sayfa daha genel görünür. | Evet |
| `kisaTanitim` | `description` | uzunMetin | isteğe bağlı | Sayfaya girenin iki saniyede "ne yapıyor" anladığı özet; boşsa `corporate_bio` veya sabit metin SEO açıklaması olarak devreye girer (bkz. `generateMetadata`). | Hero sessiz görünür; meta açıklama `hakkindaMetin`'e veya jenerik "{ad} Dijital Vitrini" metnine düşer. | Evet |
| `konumMetni` | `hero_location_text` | metin | isteğe bağlı | Üstte duran "neredeyim" bilgisi — yakındaki müşteri için ilk güven sinyali. | Hero'da konum ipucu görünmez. | Hayır |
| `kategori` | `kategori` | seçim | **temel** | Vitrinin renk paleti, hazır butonlar ve kategoriye özel görseller buna göre gelir. `"Diğer"` teknik olarak dolu ama **işlevsel olarak boş** sayılır (`bosDegerler`). | Kategoriye bağlı hiçbir şey (renk/buton/görsel şablonu, otomatik doldurma metinleri) çalışmaz; vitrin yayına hazır sayılmaz. | Hayır (kendisi seçim yapılır) |
| `isletmeTuru` | `business_type` | metin | isteğe bağlı | Kategorinin altındaki ince tanım — "Kuaför" yerine "Erkek kuaförü" gibi. | Sadece genel kategori adı görünür, alt ayrım yapılmaz. | **Hayır — kural gereği hiç yazılmaz** (yanlış tahmin boş bırakmaktan kötü). |
| `logo` | `logo_url` | görsel | kalite | Küçük de olsa bir logo, vitrini şablon değil gerçek bir işletme gibi gösterir; `shelf_image_url` yoksa SEO/OG görseli olarak da kullanılır. | Vitrin şablon hissi verir; kapak görseli de yoksa paylaşım kartı görselsiz kalır. | Hayır |
| `kapakGorseli` | `shelf_image_url` | görsel | kalite | Sayfanın en üstündeki büyük görsel; ilk izlenimin yarısı. Ayrıca `generateMetadata`'da OG/Twitter kart görseli, JSON-LD `image` alanı olarak kullanılır. | Hero görselsiz/placeholder kalır; paylaşım kartı `logo_url`'e düşer, o da yoksa görselsiz paylaşılır. | Evet (gerçek fotoğraf yüklenene kadar kategoriye uygun bir yer tutucu). |

## İletişim ve konum (`bolum: contact`)

| Anahtar | Kolon | Tip | Önem | Ne işe yarar | Boşsa ne olur | Otomatik |
|---|---|---|---|---|---|---|
| `whatsapp` | `whatsapp` | telefon | **temel** | Tek dokunuşla sohbet açan ana CTA; `wa.me` bağlantısı ve `schema.org` `telephone` alanı (telefon boşsa) buradan üretilir. | Vitrin yayına hazır sayılmaz; en hızlı iletişim yolu hiç yok. | Hayır |
| `telefon` | `phone` | telefon | isteğe bağlı | Arayarak ulaşmak isteyenler için; WhatsApp kullanmayan müşteri de var. | "Ara" butonu görünmez, yalnız WhatsApp kalır. | Hayır |
| `eposta` | `email` | e-posta | isteğe bağlı | Kurumsal iş/teklif isteyenlerin yazacağı adres. | E-posta ile iletişim seçeneği görünmez. | Hayır |
| `adres` | `address` | uzunMetin | **temel** | Açık adres; haritada işaretlenen yer ve yol tarifi bağlantısının (koordinat yoksa) kaynağı. | Vitrin yayına hazır sayılmaz; harita/yol tarifi hiç çalışmaz. | Hayır |
| `il` | `province_name` | metin | **temel** | Yayın için gerekli; ilin aramalarında (ör. "İstanbul kuaför") çıkmanı sağlar. | Vitrin yayına hazır sayılmaz. | Hayır |
| `ilce` | `district_name` | metin | **temel** | Yayın için gerekli; "Kadıköy kuaför" gibi yerel aramalarda öne çıkarır. | Vitrin yayına hazır sayılmaz. | Hayır |
| `mahalle` | `neighborhood_name` | metin | kalite | İl/ilçeden daha yerel arama sinyali. | En yerel SEO sinyali eksik kalır (il/ilçe yine de yayın şartını karşılar). | Hayır |
| `haritaEtiketi` | `map_label` | metin | isteğe bağlı | Harita kartının üstündeki kısa not (ör. "Çarşı içi, otopark var"). | Harita kartı notsuz görünür. | Hayır |
| `calismaSaatleri` | `working_hours` | metin | kalite | Açık/kapalı rozeti buradan hesaplanır; `schema.org` `openingHoursSpecification` bu alandan üretilir. | Açık/kapalı rozeti gösterilmez; JSON-LD saat bilgisi eksik kalır; müşteri boşuna gelme riski taşır. | Hayır |
| `instagram` | `instagram` | metin | isteğe bağlı | Instagram hesabı vitrine bağlanır. | Instagram bağlantısı/simgesi görünmez. | Hayır |
| `website` | `website` | url | isteğe bağlı | Ayrı bir sitesi varsa oraya yönlendirme. | Web sitesi bağlantısı görünmez. | Hayır |
| `haritaLinki` | `google_business_link` | url | kalite | Google İşletme kaydı — yol tarifi ve yorumlar oraya bağlanır. | Google İşletme'ye doğrudan bağlantı yok; yorum/puan görünürlüğü zayıflar. | Hayır |
| `enlem` | `latitude` | sayı | isteğe bağlı | Haritadaki iğnenin tam yeri. **`boylam` ile birlikte** doluysa `schema.org`'da `PostalAddress`/`GeoCoordinates` bloğu üretilir (`hasPhysicalLocation`); tekli eksikse bu blok hiç yazılmaz. | Yol tarifi butonu yine çalışır (adres metniyle Google Maps aramasına düşer) ama JSON-LD'de yapılandırılmış adres/konum verisi olmaz. | Hayır |
| `boylam` | `longitude` | sayı | isteğe bağlı | Enlemle birlikte çalışır — bkz. yukarıdaki `enlem` satırı. | Aynı: adres metniyle yol tarifi çalışır, yapılandırılmış konum verisi olmaz. | Hayır |
| `yolTarifiGoster` | `show_directions_link` | açık/kapalı | isteğe bağlı | Açıksa müşteri tek dokunuşla yol tarifi alır. **Varsayılan açık** (`!== false`). | Kapatılırsa yol tarifi butonu hiç gösterilmez (adres/koordinat dolu olsa bile). | Hayır |

## Kategori/ürün bölüm başlıkları

| Anahtar | Kolon | Bölüm | Tip | Önem | Ne işe yarar | Boşsa ne olur | Otomatik |
|---|---|---|---|---|---|---|---|
| `kategoriBolumBaslik` | `category_section_title` | categories | metin | isteğe bağlı | Ürün gruplarının üstündeki başlık; "Kategoriler" yerine kendi cümlesi. | Varsayılan "Kategoriler" başlığı görünür. | Evet (19 kategoriye özel metin) |
| `urunBolumBaslik` | `product_section_title` | products | metin | isteğe bağlı | Ürün listesinin üstündeki başlık; "Ürünler" yerine "Menümüz" gibi. | Varsayılan "Ürünler" başlığı görünür. | Evet (19 kategoriye özel metin) |

## Öne çıkan kampanya bandı (`bolum: featured`)

Bu beş alan **hep birlikte** bir bölümü oluşturur: `featured_banner_*`
kolonlarının **hepsi** boşsa (`page.tsx`'teki `featuredBanner` hesaplaması)
bölümün tamamı gizlenir — tek tek alan eksikliği değil, hepsinin boşluğu
bölümü kapatır. Asistan da bu yüzden bu alanları **hiç otomatik doldurmaz**:
gerçek kampanya yoksa sahte fiyat/indirim yazmak yerine bölümü kapalı bırakır.

| Anahtar | Kolon | Tip | Önem | Ne işe yarar | Boşsa ne olur | Otomatik |
|---|---|---|---|---|---|---|
| `bantEtiket` | `featured_banner_label` | metin | isteğe bağlı | Kampanya kutusunun köşesindeki küçük etiket (ör. "Bu haftaya özel"). | Etiket görünmez; diğer dört alandan biri doluysa bölüm yine de gösterilir. | Hayır |
| `bantBaslik` | `featured_banner_title` | metin | isteğe bağlı | Öne çıkarılan teklifin başlığı — sayfanın en dikkat çeken yeri. | Başlıksız kalır. | Hayır |
| `bantAciklama` | `featured_banner_description` | uzunMetin | isteğe bağlı | Kampanyayı bir iki cümleyle anlatır. | Açıklama görünmez. | Hayır |
| `bantGorsel` | `featured_banner_image_url` | görsel | isteğe bağlı | Kampanyanın yanındaki fotoğraf. | Görselsiz, yalnız metin görünür. | Hayır |
| `bantFiyat` | `featured_banner_price_text` | metin | isteğe bağlı | Fiyatı yazarsan müşteri sormadan karar verir (ör. "499 TL'den başlayan"). | Fiyat bilgisi görünmez. | Hayır |

## Hakkımızda (`bolum: about`)

| Anahtar | Kolon | Tip | Önem | Ne işe yarar | Boşsa ne olur | Otomatik |
|---|---|---|---|---|---|---|
| `hakkindaUstBaslik` | `about_kicker` | metin | isteğe bağlı | Hakkında bölümünün üstündeki küçük yazı (ör. "Biz kimiz"). | Üst başlıksız, doğrudan ana başlıkla başlar. | Hayır |
| `hakkindaBaslik` | `about_title` | metin | kalite | "Hakkımızda" yerine kendi cümlesi (ör. "Kadıköy'ün 12 yıllık teknik servisi"). | Jenerik "Hakkımızda" başlığı kalır. | Evet |
| `hakkindaMetin` | `corporate_bio` | uzunMetin | kalite | Hikâye anlatılan yer; `description` boşsa SEO açıklaması ve JSON-LD `description` olarak da kullanılır. Güven burada kurulur — şablon vitrinden ayıran asıl alan. | Hakkında bölümü boş/zayıf kalır; SEO açıklaması `description`'a veya jenerik metne düşer. | **Hayır — kural gereği hiç yazılmaz** (sahte "hikâye" güven kırar). |
| `hakkindaGorsel` | `about_image_url` | görsel | isteğe bağlı | Dükkânın/ekibin fotoğrafı — gerçek bir yer olduğunu gösterir. | Hakkında bölümü görselsiz kalır. | Hayır |
| `hakkindaGorselAlt` | `about_image_caption` | metin | isteğe bağlı | Fotoğrafın altındaki kısa yazı (ör. "Atölyemiz, 2019"). | Görsel altyazısız kalır. | Hayır |
| `referansLinki` | `references_link` | url | isteğe bağlı | Çalışılan firmalar/işler varsa bağlantısı. | Referans bağlantısı görünmez. | Hayır |

## Galeri (`bolum: gallery`)

| Anahtar | Kolon | Tip | Önem | Ne işe yarar | Boşsa ne olur | Otomatik |
|---|---|---|---|---|---|---|
| `galeriUstBaslik` | `gallery_section_kicker` | metin | isteğe bağlı | Galerinin üstündeki küçük yazı (ör. "İşlerimizden"). | Üst başlıksız kalır. | Evet (tek evrensel metin) |
| `galeriBaslik` | `gallery_section_title` | metin | isteğe bağlı | "Galeri" yerine kendi başlığı (ör. "Önce ve sonra"). | Varsayılan "Galeri" başlığı görünür. | Evet |
| `galeriAksiyonMetni` | `gallery_action_label` | metin | isteğe bağlı | Galerinin yanındaki bağlantı yazısı (ör. "Hepsini gör"). | Buton/bağlantı metni görünmez. | Evet |
| `galeriAksiyonLinki` | `gallery_action_href` | url | isteğe bağlı | O yazının gideceği yer — Instagram hesabı veya başka bir sayfa. | Bağlantı hedefsiz kalır, aksiyon metni olsa da tıklanamaz. | Hayır |

Galeri bölümünün kendisi (fotoğraf kartları) bu dört başlık/aksiyon alanından
değil, ayrı yüklenen galeri öğelerinden gelir — bunlar şemadaki tek tek "alan"
değildir, bu yüzden tabloda yer almaz.

## Blog (`bolum: blog`)

| Anahtar | Kolon | Tip | Önem | Ne işe yarar | Boşsa ne olur | Otomatik |
|---|---|---|---|---|---|---|
| `blogUstBaslik` | `blog_section_kicker` | metin | isteğe bağlı | Yazıların üstündeki küçük yazı (ör. "Bilgi köşesi"). | Üst başlıksız kalır. | Evet |
| `blogBaslik` | `blog_section_title` | metin | isteğe bağlı | "Yazılar" yerine kendi başlığı. Yazı yazmak Google'da görünürlüğü artırır. | Varsayılan "Yazılar" başlığı görünür. | Evet |

## SSS (`bolum: faq`)

| Anahtar | Kolon | Tip | Önem | Ne işe yarar | Boşsa ne olur | Otomatik |
|---|---|---|---|---|---|---|
| `sssUstBaslik` | `faq_section_kicker` | metin | isteğe bağlı | Soru bölümünün üstündeki küçük yazı (ör. "Merak edilenler"). | Üst başlıksız kalır. | Evet |
| `sssBaslik` | `faq_section_title` | metin | isteğe bağlı | "Sıkça sorulan sorular" yerine kendi cümlesi. | Varsayılan başlık görünür. | Evet |
| `sssAciklama` | `faq_section_description` | uzunMetin | isteğe bağlı | Bölümün altındaki açıklama; müşterinin en çok sorduklarının özeti. | Açıklama satırı görünmez. | Evet |

## Görünürlük — hero/contact'a dağılmış tekil anahtarlar

| Anahtar | Kolon | Bölüm | Tip | Önem | Ne işe yarar | Boşsa/varsayılanken ne olur | Otomatik |
|---|---|---|---|---|---|---|---|
| `puanGoster` | `show_storefront_rating` | hero | açık/kapalı | isteğe bağlı | Değerlendirme puanı varsa üstte gösterir. **Varsayılan kapalı** (`=== true` şartı). | Puan hesaplanmış olsa bile açılana kadar gösterilmez. | Hayır |
| `yolTarifiGoster` | `show_directions_link` | contact | açık/kapalı | isteğe bağlı | Bkz. "İletişim ve konum" tablosu. | — | Hayır |

---

## Sayılar

- **Toplam alan:** 46
- **Temel (zorunlu):** 6 — `isletmeAdi`, `kategori`, `whatsapp`, `adres`, `il`, `ilce`
- **Kalite:** 8 — `heroRozet`, `logo`, `kapakGorseli`, `mahalle`, `calismaSaatleri`, `haritaLinki`, `hakkindaBaslik`, `hakkindaMetin`
- **İsteğe bağlı:** 32
- **Otomatik doldurulabilir:** 14 (yalnız yapısal/kozmetik alanlar — gerçek kimlik, hikâye metni ve kampanya bandı hiçbir zaman dahil değil)

## Sonraki adım (bu dokümanın kapsamı dışında)

Bu tablo yalnız "alan Vixrex'te ne işe yarar" sorusunu cevaplıyor. Esnaf
danışma isteğinde tarif edilen planın geri kalan üç adımı — Ticaret
Bakanlığı NACE Rev.2.1 altılı sınıflarına dayanan esnaf bilgi tabanı, 46
alan × işletme türü önem eşleştirmesi (temel/değerli/duruma bağlı/ilgisiz) ve
bunun gerçek kullanım verisiyle doğrulanması — ayrı, bu dokümanın üstüne
kurulacak bir sonraki iştir.

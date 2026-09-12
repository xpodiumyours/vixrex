/**
 * VIXREX BLOGU — merkezî kurumsal blog kaynağı.
 *
 * `store_articles` işletme vitrini yazıları içindir. Kurumsal Vixrex blogu
 * dosya tabanlı kalır; yeni CMS/veritabanı bu kapsamda eklenmez.
 *
 * `yayinda` mevcut yayın anahtarıdır ve geriye dönük güvenlik sözleşmesidir.
 * `durum` editoryal yaşam döngüsünü taşır. Taslak ve arşiv içerik normal blog,
 * sitemap ve RSS yüzeylerine giremez.
 */

export const BLOG_KATEGORILERI = [
  "Dijital Vitrin",
  "Google ve Keşfedilme",
  "Müşteri İletişimi",
  "Vixrex’te Yenilikler",
  "İşletme Hikâyeleri",
] as const;

export type BlogKategori = (typeof BLOG_KATEGORILERI)[number];
export type BlogIcerikTuru =
  "rehber" | "haber" | "urun_guncellemesi" | "isletme_hikayesi";
export type BlogDurumu = "taslak" | "yayinda" | "inceleme_gerekli" | "arsiv";
export type BlogKontrolSinifi = "harici_platform" | "vixrex_urun" | "genel";

export type BlogYazar = {
  ad: string;
  tur: "kisi" | "kurum";
  url?: string;
};

export type BlogKaynak = {
  baslik: string;
  url: string;
};

export type BlogGuncellemeNotu = {
  tarih: string;
  aciklama: string;
};

export type BlogYazisi = {
  slug: string;
  baslik: string;
  ozet: string;
  /** Sınırlı Markdown: düz paragraf, ##, ###, - liste, 1. liste. Ham HTML yok. */
  govde: string;

  /** İçerik kalite kapısı */
  cozduguSoru: string;
  kategori: BlogKategori;
  icerikTuru: BlogIcerikTuru;
  sektorler: string[];
  yazar: BlogYazar;
  inceleyen: BlogYazar | null;
  kaynaklar: BlogKaynak[];
  urunDogrulamaOrtami: string | null;

  /** Görsel kalite kapısı */
  kapak: string | null;
  kapakAlt: string | null;
  gorselKaynagi: string | null;
  gorselKullanimHakki: string | null;

  /** Güncellik */
  yayinTarihi: string | null;
  guncellemeTarihi: string | null;
  sonKontrolTarihi: string;
  guncellemeNotlari: BlogGuncellemeNotu[];
  durum: BlogDurumu;
  /** Güncellik hedefini kategoriye bağlamadan açıkça belirler. */
  kontrolSinifi: BlogKontrolSinifi;

  /** Gezinme / gelecek asistan hazırlığı */
  ilgiliYazilar: string[];
  asistanKullaniminaUygun: boolean;

  /** Mevcut yayın anahtarı — güvenlik sözleşmesi korunur. */
  yayinda: boolean;
};

export type YayindakiBlogYazisi = BlogYazisi & { yayinTarihi: string };

/**
 * Blog ana sayfasına gönderilen hafif görünüm modeli. Tam gövde, kaynaklar,
 * editoryal notlar ve kalite alanları Client Component'e taşınmaz.
 */
export type BlogListeYazisi = Pick<
  YayindakiBlogYazisi,
  | "slug"
  | "baslik"
  | "ozet"
  | "kategori"
  | "icerikTuru"
  | "sektorler"
  | "kapak"
  | "kapakAlt"
  | "yayinTarihi"
  | "guncellemeTarihi"
> & {
  okumaDakika: number;
};

export const BLOG_YAZILARI: BlogYazisi[] = [
  {
    slug: "dijital-vitrin-hazirlik-listesi",
    baslik: "İlk dijital vitrinin: yayın öncesi hazırlık listesi",
    ozet: "İşletme bilgilerini, hizmetlerini ve fotoğraflarını bir araya getir. Sayfanı paylaşmadan önce müşterinin gözüyle kontrol et.",
    govde: `Dijital vitrin hazırlamaya boş bir sayfadan başlamak zorunda değilsin. Önce müşterinin seni tanıması, sunduğun hizmeti anlaması ve sana ulaşması için gereken bilgileri topla. Bu rehber, sayfanı hangi araçla hazırlarsan hazırla kullanabileceğin bir başlangıç listesidir.

## İşletmeni bir cümlede anlat

İşletmenin gerçek adını, ne yaptığını ve hizmet verdiğin bölgeyi yaz. “En iyi kalite, benzersiz hizmet” gibi genel ifadeler yerine müşterinin anlayabileceği somut bir açıklama seç.

Örnek bir tanıtım kalıbı: “[İşletme adı], [bölge] içinde [temel hizmetler] sunar.” Bir terzi için bunu “Kadıköy’de paça kısaltma, fermuar değişimi ve kıyafet tadilatı” biçiminde doldurabilirsin. Bu bir yazım örneğidir; gerçek bir işletme referansı değildir.

## Bilgileri tek yerde topla

Sayfayı düzenlemeye geçmeden aşağıdaki listeyi hazırla:

- Tabelanda veya müşterilerle iletişimde kullandığın işletme adı
- Hizmet verdiğin açık adres ya da bölge
- İşletme telefonu ve kullandığın iletişim kanalı
- Haftalık çalışma saatlerin ve kapalı günlerin
- Gerçekten sunduğun ürün veya hizmetler
- Varsa güncel fiyat, süre ve seçenek bilgileri

Başka platformlardaki işletme bilgilerini de karşılaştır. Eski bir telefonun veya farklı bir çalışma saatinin müşteriye ulaşmasını önlemek için değişen bilgileri aynı gün düzelt.

## Her hizmeti ayrı ve anlaşılır yaz

Uzun bir tanıtım paragrafının içine bütün hizmetleri sıkıştırma. Her hizmet için ad, kısa kapsam ve gerekiyorsa süre veya fiyat bilgisi hazırla. “Bakım” yerine “Sakal kesimi ve şekillendirme” gibi somut bir ad kullan.

Fiyat değişkense hangi seçeneğe göre değiştiğini açıkla. Kapsama dahil olmayan işi dahilmiş gibi gösterme. Bilmediğin bir tutarı örnek fiyat olarak yayına bırakma.

## Görselleri bir amaçla seç

İlk görsel işletmenin ne yaptığını anlatmalı. Devamında mekânı, ürünleri veya çalışmalarını gösteren net fotoğraflar kullan. Aynı açıdan çekilmiş çok sayıda fotoğraf yerine her biri farklı bilgi veren bir seçki hazırla.

Fotoğrafları telefonda küçük boyutta da kontrol et. Kesilmiş ürün, okunmayan tabela veya karanlık bir kadraj varsa başka bir görsel seç. Sana ait olmayan bir çalışmayı kendi işin gibi sunma.

## Bir müşterinin izleyeceği yolu dene

Sayfanı yalnız düzenleme ekranından kontrol etme. Müşteriye göndereceğin bağlantıyı ayrı bir tarayıcıda aç ve şu işlemleri sırayla dene:

1. İşletmenin ne yaptığını ve nerede olduğunu bul.
2. Bir hizmetin kapsamını ve varsa fiyatını oku.
3. Telefon veya mesaj bağlantısının doğru işletmeye gittiğini kontrol et.
4. Adresi ve varsa harita hedefini karşılaştır.
5. Sayfayı dar bir telefon ekranında incele; yazılar kesiliyor mu bak.
6. Paylaşacağın bağlantının giriş istemeden açıldığını doğrula.

Bir yakınının da aynı adımları açıklama yapmadan denemesini isteyebilirsin. Sorduğu sorular, sayfada eksik kalan bilgileri görmene yardımcı olabilir.

## Paylaştıktan sonra güncel tut

Vitrin bir kez hazırlanıp unutulacak bir afiş değildir. Telefon, çalışma saati, hizmet veya fiyat değiştiğinde sayfayı da güncelle. Kendine bu bilgileri yeniden kontrol edeceğin bir tarih belirle; özellikle tatil ve geçici kapanışlardan önce sayfayı gözden geçir.`,
    cozduguSoru:
      "İlk dijital vitrinimi hazırlarken hangi bilgileri toplamalı ve yayın öncesinde neleri denemeliyim?",
    kategori: "Dijital Vitrin",
    icerikTuru: "rehber",
    sektorler: [],
    yazar: {
      ad: "Vixrex",
      tur: "kurum",
      url: "/hakkimizda",
    },
    inceleyen: null,
    kaynaklar: [],
    urunDogrulamaOrtami: null,
    kapak: null,
    kapakAlt: null,
    gorselKaynagi: null,
    gorselKullanimHakki: null,
    yayinTarihi: null,
    guncellemeTarihi: null,
    sonKontrolTarihi: "2026-09-11",
    guncellemeNotlari: [],
    durum: "taslak",
    kontrolSinifi: "genel",
    ilgiliYazilar: [
      "kuafor-icin-internet-sitesi",
      "musteri-mesajlari-icin-yanit-ornekleri",
    ],
    asistanKullaniminaUygun: false,
    yayinda: false,
  },
  {
    slug: "musteri-mesajlari-icin-yanit-ornekleri",
    baslik: "Müşteri mesajlarına açık yanıtlar: 5 örnek",
    ozet: "Fiyat, çalışma saati, konum ve randevu soruları için işletmene uyarlayabileceğin kısa yanıt örnekleri.",
    govde: `Müşteriye yanıt verirken uzun bir tanıtım metni göndermek yerine önce sorusunu cevapla. Ardından gerekiyorsa bir sonraki adımı söyle. Aşağıdaki metinler örnektir; köşeli parantez içindeki alanları kendi doğruladığın bilgilerinle değiştir.

## Fiyat sorulduğunda

“Merhaba, [hizmet adı] için güncel ücretimiz [tutar]. Bu hizmete [kapsam] dahil. [Seçenek] istiyorsan fiyatı ayrıca netleştirebiliriz.”

Tek bir fiyat veremiyorsan bunun nedenini söyle: “Tutar, [ölçü/adet/işlem] bilgisine göre değişiyor. Bunları paylaşırsan kapsamı ve toplam tutarı sana yazalım.” Müşterinin hangi bilginin eksik olduğunu anlamasını sağla; yalnız “özelden bilgi” gibi belirsiz bir cevapla bırakma.

## Çalışma saati sorulduğunda

“Bugün [açılış]–[kapanış] arasında açığız. [Varsa mola veya özel durum]. [Gün] günü kapalıyız.”

Müşteri “Bugün açık mısınız?” diyorsa bütün haftanın saatleri yerine o günü cevapla. Tatil veya geçici kapanış varsa normal saatleri kopyalamadan önce kontrol et. Vitrindeki saat farklıysa onu da güncelle.

## Konum istendiğinde

“Adresimiz: [açık adres]. [Varsa kısa tarif]. Konum bağlantımız: [kontrol edilmiş bağlantı].”

Tarifi yalnız yerel bir lakaba veya herkesin bilmediği bir binaya bağlama. Harita bağlantısını göndermeden açıp doğru noktaya gittiğini kontrol et. Bina girişi farklı bir sokaktaysa bunu ayrıca belirt.

## Randevu talebi geldiğinde

“[Hizmet] için [tarih] günü [saat] uygun. Bu saati senin için ayıralım mı?”

Bu mesaj bir teklif metnidir. Müşteri kabul ettikten ve sen kayıtlarını kontrol ettikten sonra ayrı bir onay gönder: “Randevun onaylandı: [tarih], [saat], [hizmet]. Adresimiz [adres]. Değişiklik gerekirse bu numaradan bize yazabilirsin.”

Tarih, saat veya hizmet belli değilken “Tamamdır” demek yerine eksik bilgiyi sor. Bu örnek herhangi bir otomatik randevu özelliği vaat etmez; kullandığın kayıt yöntemiyle birlikte uygulanacak bir iletişim düzenidir.

## Hemen cevap veremediğinde

“Mesajını aldık. [Gerçekçi yanıt zamanı] içinde dönüş yapacağız. Bu sırada hizmet ve adres bilgilerine [vitrin bağlantısı] üzerinden bakabilirsin.”

Tutamayacağın bir yanıt süresi verme. Bir otomatik mesaj kullanıyorsan yanıt zamanını çalışma düzenin değiştiğinde güncelle. Mesajın alınmış olmasıyla talebin onaylanmış olmasını birbirinden ayır.

## Göndermeden önce kontrol et

1. Müşterinin sorduğu asıl soruyu cevapladın mı?
2. Örnekteki bütün parantezleri gerçek bilgilerle değiştirdin mi?
3. Tarih, saat, tutar ve bağlantılar doğru mu?
4. Müşterinin şimdi ne yapması gerektiği anlaşılıyor mu?

Sık sorulan bir bilgi her konuşmada tekrar eksik kalıyorsa o bilgiyi vitrinin ilgili bölümüne de ekle. Böylece mesaj ile sayfadaki bilgi birbiriyle tutarlı kalır.`,
    cozduguSoru:
      "Müşterinin sorusuna eksik bilgi vermeden, kısa ve anlaşılır nasıl cevap verebilirim?",
    kategori: "Müşteri İletişimi",
    icerikTuru: "rehber",
    sektorler: [],
    yazar: {
      ad: "Vixrex",
      tur: "kurum",
      url: "/hakkimizda",
    },
    inceleyen: null,
    kaynaklar: [],
    urunDogrulamaOrtami: null,
    kapak: null,
    kapakAlt: null,
    gorselKaynagi: null,
    gorselKullanimHakki: null,
    yayinTarihi: null,
    guncellemeTarihi: null,
    sonKontrolTarihi: "2026-09-11",
    guncellemeNotlari: [],
    durum: "taslak",
    kontrolSinifi: "genel",
    ilgiliYazilar: [
      "dijital-vitrin-hazirlik-listesi",
      "kuafor-icin-internet-sitesi",
    ],
    asistanKullaniminaUygun: false,
    yayinda: false,
  },
  {
    slug: "kafe-dijital-menu-hazirlama",
    baslik: "Kafe menüsünü telefonda okunur hâle getir",
    ozet: "Kategori adlarından ürün açıklamalarına kadar, dijital menünü müşterinin kolayca okuyabileceği şekilde hazırlamak için bir rehber.",
    govde: `Basılı menünün fotoğrafını çekmek bir başlangıç olabilir; ancak küçük yazıları telefonda okumak için büyütmek gerekebilir. Dijital menünü hazırlarken bilgileri ürünler ve kategoriler halinde düzenlemeyi dene. Buradaki öneriler bir menü yazma ve kontrol yöntemi sunar.

## Kategorileri müşterinin kelimeleriyle adlandır

“Sıcak içecekler”, “Soğuk içecekler”, “Kahvaltı” ve “Tatlılar” gibi içerdiği ürünleri açıklayan başlıklar kullan. İşletmende bulunmayan bir grubu sırf menü dolu görünsün diye ekleme.

Bir ürünün nereye ait olduğu belirsizse müşterinin onu ilk nerede arayacağını düşün. Aynı ürünü farklı kategorilerde tekrar yazıyorsan fiyat ve açıklamaların birbirinden kopmamasına dikkat et.

## Her üründe aynı bilgi sırasını kullan

Bir ürün için ad, kısa açıklama, seçenek ve fiyat bilgisini sırayla hazırla. Kendi ürün bilgilerinle doldurabileceğin bir örnek:

- Ad: [Ürün adı]
- Açıklama: [Temel içerik veya hazırlanış]
- Seçenek: [Boy/porsiyon gibi gerçekten sunulan seçenekler]
- Fiyat: [O seçenek için güncel tutar]

İsimden anlaşılmayan bir üründe kısa açıklama özellikle yararlı olabilir. “Özel karışım” demek yerine doğrulayabildiğin temel içeriği belirt. İçeriğinden emin olmadığın ürüne özellik yakıştırma.

## Seçenekleri fiyatla birlikte kontrol et

Aynı içeceğin farklı boyları varsa hangi fiyatın hangi boya ait olduğunu yaz. Ekstra bir seçeneği sunuyorsan ücretinin dahil olup olmadığını açıkla. Sayfadaki bilgiyi işletmede müşteriye sunduğun menüyle karşılaştır.

Bu kontrolü yalnız ilk yayında yapma. Ürün veya fiyat değiştiğinde kullanılan bütün menü yüzeylerini gözden geçir; masadaki basılı menüyle telefondaki menü farklı kalmasın.

## Fotoğraf sayısını değil açıklığını önemse

Her ürüne bir görsel eklemek zorunda değilsin. Eklediğin fotoğraf gerçekten sunduğun ürünü ve porsiyonu temsil etsin. Başka bir ürünün veya işletmenin fotoğrafını kendi sunumun gibi kullanma.

Birden fazla ürün fotoğrafında benzer ışık ve kadraj tercih ederek menü boyunca tutarlı bir görünüm oluşturabilirsin. Koyu veya bulanık bir görsel yerine iyi yazılmış ürün bilgisiyle devam etmek daha anlaşılır olabilir.

## Masadan telefona geçişi dene

Menü bağlantısını veya QR kodunu müşterinin kullanacağı koşullarda kontrol et:

1. Bağlantı doğru menüyü açıyor mu?
2. Telefon ekranında ürün adı ve fiyat birlikte okunuyor mu?
3. Kategoriler arasında geçiş kolay mı?
4. Güncel olmayan ürün veya boş kategori var mı?
5. QR basılıysa baskı boyutunda ve gerçek masa ışığında taranabiliyor mu?

Bir ürün geçici olarak yoksa menüyü buna göre düzenle. Güncelliği koruyamayacağın çok uzun bir liste yerine gerçekten sunabildiğin ürünleri açık biçimde göster.`,
    cozduguSoru:
      "Kafemin dijital menüsünü telefonda anlaşılır ve güncel tutmak için nasıl düzenlemeliyim?",
    kategori: "Dijital Vitrin",
    icerikTuru: "rehber",
    sektorler: ["kafe", "restoran"],
    yazar: {
      ad: "Vixrex",
      tur: "kurum",
      url: "/hakkimizda",
    },
    inceleyen: null,
    kaynaklar: [],
    urunDogrulamaOrtami: null,
    kapak: null,
    kapakAlt: null,
    gorselKaynagi: null,
    gorselKullanimHakki: null,
    yayinTarihi: null,
    guncellemeTarihi: null,
    sonKontrolTarihi: "2026-09-11",
    guncellemeNotlari: [],
    durum: "taslak",
    kontrolSinifi: "genel",
    ilgiliYazilar: [
      "dijital-vitrin-hazirlik-listesi",
      "urun-fotografi-cekme-rehberi",
    ],
    asistanKullaniminaUygun: false,
    yayinda: false,
  },
  {
    slug: "urun-fotografi-cekme-rehberi",
    baslik: "Telefonla ürün fotoğrafı: sade bir çekim planı",
    ozet: "Işık, arka plan ve kadraj için uygulanabilir bir hazırlık listesi. Vitrininde ürünü doğru anlatan bir fotoğraf seçkisi oluştur.",
    govde: `Bu rehber, telefonla çekim için uygulayabileceğin bir çalışma planıdır. Amaç ürünü olduğundan farklı göstermek değil; müşterinin biçimini, ayrıntılarını ve sunumunu anlayabileceği fotoğraflar hazırlamaktır.

## Çekmeden önce ürünü ve alanı hazırla

Ürünü temizle, pakette istemediğin etiket veya kişisel bilgi olup olmadığını kontrol et. Arka planda dikkat dağıtan eşyaları kaldır. Ürünle benzer renkte bir zemin seçtiysen sınırlarının hâlâ belirgin olup olmadığına bak.

Birden fazla ürün çekeceksen aynı köşeyi ve zemini kullanmayı deneyebilirsin. Böylece her üründe çekim düzenini yeniden kurmak zorunda kalmazsın.

## Işığı küçük bir denemeyle seç

Pencereye yakın bir yerde deneme çekimi yap. Sert gölgeler veya parlak yüzeyde yansıma varsa ürünün ve telefonun açısını değiştir. Farklı ışık kaynaklarını birlikte kullanınca renkler farklı görünüyorsa tek bir ışık düzeniyle yeniden dene.

Çektiğin fotoğrafı gerçek ürünün yanında karşılaştır. Renkler belirgin biçimde değişmişse filtre ekleyerek düzeltmeye çalışmadan önce ışığı ve telefon ayarını gözden geçir.

## Üç farklı soruya cevap veren kareler çek

Aynı açıdan çok sayıda fotoğraf yerine şu üç amacı dene:

1. Genel görünüm: Ürünün bütünü ve şekli anlaşılır mı?
2. Ayrıntı: Malzeme, doku veya önemli bir parça görülebiliyor mu?
3. Kullanım veya sunum: Ürün müşteriye hangi şekilde teslim ediliyor?

Bir sunum fotoğrafında ürüne dahil olmayan aksesuarlar varsa açıklamada bunu belirt. Fotoğraf ürünün boyutunu tek başına anlatamıyorsa ölçü bilgisini ürün açıklamasına ekle.

## Kadrajda biraz boşluk bırak

Ürünü çerçevenin kenarına çok yaklaştırmadan çek. Vitrindeki kart fotoğrafı kırpıyorsa bu boşluk farklı ekranlarda işe yarayabilir. Yatay ve dikey birkaç deneme alıp kendi sayfandaki görünümü karşılaştır.

Önemli bilgiyi yalnız fotoğrafın üzerine yazma. Ürün adı, seçenek ve fiyatın sayfanın metninde de bulunmasını sağla; fotoğraf küçüldüğünde üzerindeki yazı okunmayabilir.

## Yükledikten sonra tekrar bak

Fotoğrafı telefondaki galeri uygulamasında beğenmiş olman, sayfadaki kırpmanın doğru olduğu anlamına gelmez. Yayın önizlemesinde şu kontrolleri yap:

- Ürünün önemli bir bölümü kesiliyor mu?
- Görsel bulanık veya gereğinden karanlık mı?
- Mobilde ve masaüstünde aynı ürün anlaşılabiliyor mu?
- Ürün adı, açıklama ve fotoğraf birbiriyle uyuşuyor mu?

İlk fotoğrafı ürünün genel görünümü için, diğerlerini ayrıntı için seç. Aynı bilgiyi tekrar eden kareleri çıkar ve üründe değişiklik olduğunda eski fotoğrafı güncelle.`,
    cozduguSoru:
      "Telefonla çektiğim ürün fotoğraflarını vitrinde kullanmak için nasıl hazırlamalı ve seçmeliyim?",
    kategori: "Dijital Vitrin",
    icerikTuru: "rehber",
    sektorler: ["perakende", "kafe", "el işi"],
    yazar: {
      ad: "Vixrex",
      tur: "kurum",
      url: "/hakkimizda",
    },
    inceleyen: null,
    kaynaklar: [],
    urunDogrulamaOrtami: null,
    kapak: null,
    kapakAlt: null,
    gorselKaynagi: null,
    gorselKullanimHakki: null,
    yayinTarihi: null,
    guncellemeTarihi: null,
    sonKontrolTarihi: "2026-09-11",
    guncellemeNotlari: [],
    durum: "taslak",
    kontrolSinifi: "genel",
    ilgiliYazilar: [
      "kafe-dijital-menu-hazirlama",
      "dijital-vitrin-hazirlik-listesi",
    ],
    asistanKullaniminaUygun: false,
    yayinda: false,
  },
  {
    slug: "kuafor-icin-internet-sitesi",
    baslik: "Kuaför salonu için dijital vitrin nasıl hazırlanır?",
    ozet:
      "Kuaför ve berberler için müşterinin temel sorularını tek sayfada " +
      "yanıtlayan, gerçek işletme bilgilerine dayalı bir dijital vitrin kontrol rehberi.",
    govde: `## Önce müşterinin aradığı temel bilgileri tamamlayın

Bir kuaför vitrini yalnız güzel görünmemeli; ziyaretçinin işletme hakkında temel sorularına cevap verebilmelidir. İşletme adı, kısa tanıtım, iletişim bilgileri, açık adres ve çalışma saatleri sayfada kolayca bulunabilmelidir.

Yayın öncesinde ilk kontrolünüz şu olmalı:

- İşletme adı gerçek hayatta kullanılan adla aynı mı?
- Kuaför, berber, kadın kuaförü veya erkek kuaförü gibi işletme türü doğru mu?
- WhatsApp ve telefon numarası gerçekten işletmeye mi ait?
- Açık adres, il ve ilçe doğru mu?
- Çalışma saatleri güncel mi?

Bu bilgilerden biri eskiyse, iyi tasarlanmış bir vitrin bile müşteriye yanlış bilgi verebilir.

## İşletme adını ve kısa tanıtımı sade yazın

İşletme adını slogan, telefon numarası veya gereksiz anahtar kelimelerle uzatmak yerine gerçek adını kullanın. Kısa tanıtımda ise müşterinin vitrini açtığında ilk bakışta anlayacağı bilgiler yeterlidir: ne tür hizmet verdiğiniz ve hangi bölgede olduğunuz.

Örnek biçim:

- İşletme adı: gerçek tabela veya marka adı
- İşletme türü: Erkek kuaförü
- Kısa tanıtım: Saç kesimi, sakal bakımı ve bakım hizmetleri
- Konum metni: Kadıköy, İstanbul

Buradaki amaç reklam cümlesi üretmek değil, işletmeyi doğru ve anlaşılır biçimde tanımlamaktır.

## İletişimi tek dokunuşta kontrol edin

Vitrindeki WhatsApp ve telefon alanları yalnız yazılı bilgi olarak bırakılmamalıdır. Yayın öncesinde bağlantıları gerçek cihazdan açın ve doğru numaraya ulaştığını kontrol edin.

Yanlış numara, eksik ülke kodu veya başka bir kişiye ait iletişim bilgisi yayınlanmamalıdır. İşletme iletişim bilgisi değiştiğinde vitrin de aynı anda güncellenmelidir.

## Adres ve çalışma saatlerini gerçek işletmeyle karşılaştırın

Adres alanında müşterinin işletmeyi bulmasına yetecek açık ve güncel bilgi bulunmalıdır. İl ve ilçe bilgileri de gerçek adresle uyuşmalıdır.

Çalışma saatleri özellikle değişken bir bilgidir. Haftalık düzen, geçici kapanış veya çalışma saati değişikliği olduğunda vitrindeki bilgi de kontrol edilmelidir. Yayında görünen saat, işletmenin gerçekten müşteri kabul ettiği saat olmalıdır.

## Hizmetleri müşterinin anlayacağı adlarla yazın

Hizmet listesi, işletmenin gerçekten sunduğu hizmetleri göstermelidir. İçeride kullanılmayan mesleki ifadeler yerine müşterinin anlayacağı açık adlar tercih edin.

Örneğin işletme gerçekten sunuyorsa şu tür adlar kullanılabilir:

- Saç kesimi
- Sakal kesimi ve şekillendirme
- Saç boyama
- Saç bakımı
- Gelin saçı

Fiyat gösterecekseniz yalnız işletmenin güncel olarak doğruladığı fiyatı kullanın. Fiyat bilinmiyorsa tahmin üretmeyin; yanlış fiyat göstermek yerine alanı güncel bilgi gelene kadar boş bırakmak daha doğrudur.

## Görselleri seçerken gerçeklik ve kullanım hakkını birlikte kontrol edin

Kapak ve galeri görselleri işletmenin kendisine ait olmalı veya kullanım izni açıkça bulunmalıdır. Başka bir salonun çalışmasını kendi işi gibi gösterecek fotoğraf kullanılmamalıdır.

İyi bir görsel seçimi için üç basit kontrol yeterlidir:

1. Fotoğraf gerçekten bu işletmeye veya bu işletmenin çalışmasına mı ait?
2. Görsel yeterince net ve güncel mi?
3. Bu görseli yayınlama hakkı işletmede mi?

Bu üç sorudan biri cevaplanamıyorsa görsel yayınlanmamalıdır.

## Yayın öncesi son kontrol

Vitrini yayınlamadan önce masaüstü ve telefondan açarak aşağıdaki sırayla kontrol edin:

1. İşletme adı ve işletme türü doğru mu?
2. WhatsApp ve telefon bağlantıları doğru kişiye gidiyor mu?
3. Adres, il, ilçe ve harita bilgisi gerçek konumla uyumlu mu?
4. Çalışma saatleri ve hizmetler güncel mi?
5. Kullanılan görseller gerçek ve izinli mi?

Bu rehberin amacı vitrini daha çok metinle doldurmak değil; müşterinin karşısına çıkan bilgilerin doğru, anlaşılır ve kontrol edilmiş olmasını sağlamaktır.`,
    cozduguSoru:
      "Kuaför veya berber vitrini hazırlanırken hangi işletme bilgileri ve görseller yayın öncesinde kontrol edilmelidir?",
    kategori: "Dijital Vitrin",
    icerikTuru: "rehber",
    sektorler: ["kuaför", "berber"],
    yazar: { ad: "Vixrex", tur: "kurum", url: "/hakkimizda" },
    inceleyen: null,
    kaynaklar: [],
    urunDogrulamaOrtami:
      "public_web/src/lib/vitrinFieldSchema.ts — alan şeması, 10 Eylül 2026 kontrolü",
    kapak: null,
    kapakAlt: null,
    gorselKaynagi: null,
    gorselKullanimHakki: null,
    yayinTarihi: null,
    guncellemeTarihi: null,
    sonKontrolTarihi: "2026-09-10",
    guncellemeNotlari: [],
    durum: "taslak",
    kontrolSinifi: "genel",
    ilgiliYazilar: ["isletmemi-googleda-nasil-gosteririm"],
    asistanKullaniminaUygun: false,
    yayinda: false,
  },
  {
    slug: "isletmemi-googleda-nasil-gosteririm",
    baslik: "İşletmemi Google'da nasıl gösterebilirim?",
    ozet:
      "Google İşletme Profili, doğrulama seçenekleri ve web sayfanızın " +
      "Google tarafından keşfedilmesi için resmi Google belgelerine dayalı uygulama rehberi.",
    govde: `## Önce işletmenizin Google İşletme Profili için uygun olup olmadığını kontrol edin

Google İşletme Profili; müşterilerin ziyaret edebildiği fiziksel konuma sahip işletmeler veya müşterilere bulundukları yerde hizmet veren uygun hizmet bölgesi işletmeleri için kullanılabilir. İşletmeniz Google'da zaten görünüyorsa yeni bir profil açmak yerine mevcut profili sahiplenmeniz gerekebilir.

İlk adımınız, Google'da işletme adınızı aramak ve mevcut bir profil olup olmadığını kontrol etmektir.

## İşletmeyi gerçek hayattaki haliyle temsil edin

Google'ın resmi kuralları, işletmenin gerçek dünyada nasıl tanınıyorsa o şekilde temsil edilmesini ister. İşletme adı tabela, web sitesi ve diğer gerçek işletme materyallerindeki adla uyumlu olmalıdır.

Profilde özellikle şu bilgileri dikkatle kontrol edin:

- İşletme adı
- Adres veya hizmet bölgesi
- Ana işletme kategorisi
- Telefon numarası
- Web sitesi
- Normal çalışma saatleri
- Tatil veya geçici dönemler için özel çalışma saatleri

İşletme adına şehir, hizmet veya anahtar kelime ekleyerek adı yapay biçimde uzatmak doğru değildir. Adres ve hizmet bölgesi de gerçek işletme faaliyetini yansıtmalıdır.

## Google'ın size sunduğu doğrulama yöntemini kullanın

Google, doğrulama yöntemlerini otomatik olarak belirlediğini ve kullanıcının istediği yöntemi seçemeyeceğini açıkça belirtiyor. Kullanılabilir seçenekler işletme türüne, herkese açık bilgilere, bölgeye veya çalışma saatlerine göre değişebilir. Bazı işletmeler için birden fazla yöntem gerekebilir.

Bu nedenle “Google her işletmeye kartpostal gönderir” şeklinde sabit bir yöntem yoktur. Profilinizde görünen doğrulama seçeneklerini kullanın.

Video doğrulaması sunulursa Google, kaydın işletmenin konumunu, işletmenin varlığını ve işletmeyi yönetmeye yetkili olduğunuzu doğrulayacak bilgileri gösterebilmesini ister. Google'ın güncel yardım sayfasındaki koşullar doğrulama başlamadan önce kontrol edilmelidir.

## İşletme bilgilerinin farklı yüzeylerde birbiriyle çelişmemesine dikkat edin

Google, işletme adının gerçek dünyadaki kullanımını, adres veya hizmet bölgesinin doğruluğunu ve işletmeye ait telefon/web sitesi bilgisini açıkça vurguluyor.

Bu nedenle Google profilinizle kendi web sayfanız arasında şu bilgileri karşılaştırmanız yararlıdır:

- İşletme adı
- Telefon
- Adres veya hizmet bölgesi
- Çalışma saatleri
- İşletmenin sunduğu temel hizmetlerin tanımı

Buradaki hedef “Google'a sinyal göndermek” gibi doğrulanması zor bir iddia değildir. Hedef, müşterinin farklı yerlerde birbirini tutmayan işletme bilgileriyle karşılaşmasını önlemektir.

## Web sayfanızın Google tarafından taranabilir olmasını sağlayın

Bir web sayfasının Google Search'e girebilmesi için Googlebot'un sayfaya erişebilmesi, sayfanın başarılı bir HTTP yanıtı vermesi ve indekslenebilir içeriğe sahip olması temel teknik gereksinimler arasındadır.

Fakat bu koşulları karşılamak “kesin indekslenme” anlamına gelmez. Google, tarama ve indeksleme için sabit süre garantisi vermiyor.

Yeni veya önemli ölçüde değiştirilmiş birkaç URL için Search Console'daki URL Denetleme aracı kullanılabilir. Çok sayıda URL için sitemap, Google'ın URL'leri keşfetmesine yardımcı olan yöntemlerden biridir.

## Tarama isteğini sıralama garantisi gibi görmeyin

Google'ın yeniden tarama belgesi, tarama isteğinin arama sonuçlarına anında veya kesin dahil edilme garantisi olmadığını açıkça belirtir. Aynı URL için tekrar tekrar istek göndermek de taramayı hızlandırmaz.

Bu nedenle şu tür kesin vaatlerden kaçının:

- “24 saatte Google'da çıkar.”
- “Bir haftada ilk sayfaya gelir.”
- “Doğrulamadan sonra sıralama garanti olur.”
- “Aynı isteği çok kez gönderirsek daha hızlı indekslenir.”

Bu ifadelerin hiçbiri Google'ın resmi belgeleri tarafından garanti edilmiyor.

## Profil yayınlandıktan sonra bilgileri güncel tutun

İşletme adı, adres, telefon veya çalışma saatleri değiştiğinde Google profilini de güncelleyin. Google, normal çalışma saatlerine ek olarak tatil veya geçici dönemler için özel çalışma saatlerinin girilebildiğini belirtiyor.

Özellikle adres değişikliği gibi büyük değişikliklerde yeniden doğrulama gerekebilir. Bu nedenle profil bir kez açılıp unutulacak sabit bir kayıt olarak görülmemelidir.

## Uygulama kontrol listesi

İşletmenizi Google'da yönetirken şu sırayla ilerleyebilirsiniz:

1. Google'da mevcut işletme profilinizi arayın.
2. Yoksa uygunluk koşullarını kontrol ederek ekleyin; varsa sahiplenin.
3. İşletme adı, adres/hizmet bölgesi, kategori, telefon ve çalışma saatlerini gerçek bilgilerle doldurun.
4. Google'ın profiliniz için sunduğu doğrulama yöntemini tamamlayın.
5. Kendi web sayfanızın taranabilir ve indekslenebilir olduğundan emin olun.
6. Gerekirse Search Console ile URL Denetleme veya sitemap kullanın.
7. İşletme bilgileri değiştikçe profilinizi ve web sayfanızı güncel tutun.

Bu rehber, Google'da belirli bir sıralama veya belirli sürede indekslenme vaadi vermez; yalnız Google'ın güncel resmi belgelerinde doğrulanabilen adımları açıklar.`,
    cozduguSoru:
      "Bir işletme Google İşletme Profili ve kendi web sayfası için hangi doğrulanmış adımları izleyebilir, hangi sonuçları ise garanti olarak görmemelidir?",
    kategori: "Google ve Keşfedilme",
    icerikTuru: "rehber",
    sektorler: [],
    yazar: { ad: "Vixrex", tur: "kurum", url: "/hakkimizda" },
    inceleyen: null,
    kaynaklar: [
      {
        baslik:
          "Google İşletme Profili Yardım — İşletmenizin Google'da gösterilmesiyle ilgili kurallar",
        url: "https://support.google.com/business/answer/3038177?hl=tr",
      },
      {
        baslik: "Google İşletme Profili Yardım — İşletme Profilinizi düzenleme",
        url: "https://support.google.com/business/answer/3039617?hl=tr",
      },
      {
        baslik: "Google Business Profile Help — Verify your business on Google",
        url: "https://support.google.com/business/answer/7107242",
      },
      {
        baslik: "Google Search Central — Technical requirements",
        url: "https://developers.google.com/search/docs/essentials/technical",
      },
      {
        baslik: "Google Search Central — Ask Google to recrawl your URLs",
        url: "https://developers.google.com/search/docs/crawling-indexing/ask-google-to-recrawl",
      },
      {
        baslik:
          "Google Search Central — Creating helpful, reliable, people-first content",
        url: "https://developers.google.com/search/docs/fundamentals/creating-helpful-content?hl=tr",
      },
    ],
    urunDogrulamaOrtami: null,
    kapak: null,
    kapakAlt: null,
    gorselKaynagi: null,
    gorselKullanimHakki: null,
    yayinTarihi: null,
    guncellemeTarihi: null,
    sonKontrolTarihi: "2026-09-10",
    guncellemeNotlari: [],
    durum: "taslak",
    kontrolSinifi: "harici_platform",
    ilgiliYazilar: [
      "kuafor-icin-internet-sitesi",
      "dijital-vitrin-hazirlik-listesi",
    ],
    asistanKullaniminaUygun: false,
    yayinda: false,
  },
];

const GUN_MS = 24 * 60 * 60 * 1000;
const ISO_TARIH_DESENI = /^\d{4}-\d{2}-\d{2}$/;

/** Yalnız gerçek takvim günlerini kabul eder; ör. 2026-02-31 geçersizdir. */
function isoTarihMs(iso: string | null): number | null {
  if (!iso || !ISO_TARIH_DESENI.test(iso)) return null;
  const ms = Date.parse(`${iso}T00:00:00Z`);
  if (Number.isNaN(ms)) return null;
  return new Date(ms).toISOString().slice(0, 10) === iso ? ms : null;
}

function utcGunBaslangici(tarih: Date): number {
  return Date.UTC(
    tarih.getUTCFullYear(),
    tarih.getUTCMonth(),
    tarih.getUTCDate(),
  );
}

/**
 * Planın kontrol hedefleri:
 * - Haricî platform rehberi: en geç 60 günde yeniden kontrol.
 * - Genel işletme rehberi: 90 günde yeniden kontrol.
 * - Vixrex ürün değişiklikleri: zaman sayacıyla değil ürün değiştiğinde.
 *
 * 30–60 günlük Google kontrol penceresinin üst sınırı olan 60 gün,
 * otomatik "inceleme gerekli" eşiğidir; 30. gün içerik eskimiş sayılmaz.
 */
function otomatikKontrolEsigiGun(yazi: BlogYazisi): number | null {
  if (yazi.kontrolSinifi === "harici_platform") return 60;
  if (yazi.kontrolSinifi === "vixrex_urun") return null;
  return 90;
}

export function yaziDurumunuHesapla(
  yazi: BlogYazisi,
  bugun = new Date(),
): BlogDurumu {
  if (yazi.durum === "arsiv") return "arsiv";
  if (!yazi.yayinda || yazi.durum === "taslak") return "taslak";
  if (yazi.durum === "inceleme_gerekli") return "inceleme_gerekli";

  const kontrolMs = isoTarihMs(yazi.sonKontrolTarihi);
  const bugunMs = utcGunBaslangici(bugun);
  if (kontrolMs === null || kontrolMs > bugunMs) return "inceleme_gerekli";

  const esikGun = otomatikKontrolEsigiGun(yazi);
  if (esikGun === null) return "yayinda";

  const gecenGun = Math.floor((bugunMs - kontrolMs) / GUN_MS);
  return gecenGun > esikGun ? "inceleme_gerekli" : "yayinda";
}

/**
 * Yayın anahtarına ek kalite kapısı. İçerik eksikliği yazıyı otomatik
 * düzeltmez; yalnız yanlışlıkla yayına açılmasını engeller.
 */
export function yaziYayinKalitesiUygun(
  yazi: BlogYazisi,
  bugun = new Date(),
): boolean {
  if (!yazi.cozduguSoru.trim() || !yazi.yazar.ad.trim()) return false;

  const bugunMs = utcGunBaslangici(bugun);
  const kontrolMs = isoTarihMs(yazi.sonKontrolTarihi);
  if (kontrolMs === null || kontrolMs > bugunMs) return false;

  if (
    yazi.kaynaklar.some(
      (kaynak) => !kaynak.baslik.trim() || !/^https:\/\//i.test(kaynak.url),
    )
  ) {
    return false;
  }

  if (yazi.kontrolSinifi === "harici_platform" && yazi.kaynaklar.length === 0) {
    return false;
  }

  if (
    yazi.kontrolSinifi === "vixrex_urun" &&
    !yazi.urunDogrulamaOrtami?.trim()
  ) {
    return false;
  }

  if (yazi.kapak) {
    if (!yazi.kapakAlt?.trim()) return false;
    if (!yazi.gorselKaynagi?.trim()) return false;
    if (!yazi.gorselKullanimHakki?.trim()) return false;
  }

  const yayinMs = isoTarihMs(yazi.yayinTarihi);
  const guncellemeMs = isoTarihMs(yazi.guncellemeTarihi);

  if (yazi.yayinTarihi && yayinMs === null) return false;
  if (yazi.guncellemeTarihi && guncellemeMs === null) return false;
  if (yazi.guncellemeTarihi && !yazi.yayinTarihi) return false;

  if (yayinMs !== null) {
    if (yayinMs > bugunMs || kontrolMs < yayinMs) return false;

    if (guncellemeMs !== null) {
      if (
        guncellemeMs < yayinMs ||
        guncellemeMs > bugunMs ||
        kontrolMs < guncellemeMs
      ) {
        return false;
      }

      if (
        yazi.guncellemeTarihi !== yazi.yayinTarihi &&
        yazi.guncellemeNotlari.length === 0
      ) {
        return false;
      }
    }
  }

  for (const not of yazi.guncellemeNotlari) {
    const notMs = isoTarihMs(not.tarih);
    if (notMs === null || notMs > bugunMs || !not.aciklama.trim()) return false;
    if (guncellemeMs !== null && notMs > guncellemeMs) return false;
  }

  return true;
}

function yayinaUygun(yazi: BlogYazisi): yazi is YayindakiBlogYazisi {
  return (
    yazi.yayinda === true &&
    yazi.durum !== "taslak" &&
    yazi.durum !== "arsiv" &&
    typeof yazi.yayinTarihi === "string" &&
    yazi.yayinTarihi.length > 0 &&
    yaziYayinKalitesiUygun(yazi)
  );
}

/** Taslak ve arşiv içerikleri dışarı sızdırmadan yeniden eskiye sıralar. */
export function blogOnizlemeMi(): boolean {
  return (
    process.env.NODE_ENV === "development" && process.env.BLOG_ONIZLEME === "1"
  );
}

export function yayindakiYazilar(): YayindakiBlogYazisi[] {
  const kaynak = blogOnizlemeMi()
    ? BLOG_YAZILARI.filter((yazi) => yazi.durum !== "arsiv").map((yazi) => ({
        ...yazi,
        yayinda: true,
        durum: "yayinda" as const,
        yayinTarihi: yazi.yayinTarihi || yazi.sonKontrolTarihi,
      }))
    : BLOG_YAZILARI;
  return kaynak
    .filter(yayinaUygun)
    .sort((a, b) => b.yayinTarihi.localeCompare(a.yayinTarihi));
}

/** Yayındaki bir yazıyı adresinden bulur. Taslak/arşiv asla dönmez. */
export function yaziyiBul(slug: string): YayindakiBlogYazisi | undefined {
  return yayindakiYazilar().find((yazi) => yazi.slug === slug);
}

export function blogYayindaMi(): boolean {
  return yayindakiYazilar().length > 0;
}

/** Süresi dolan veya editörce işaretlenen yazıları tek yerde toplar. */
export function incelemeGerekenYazilar(bugun = new Date()): BlogYazisi[] {
  return BLOG_YAZILARI.filter(
    (yazi) =>
      yazi.yayinda && yaziDurumunuHesapla(yazi, bugun) === "inceleme_gerekli",
  );
}

/** Blog ve yazı sitemap lastmod için yalnız anlamlı yayın/güncelleme tarihleri. */
export function blogSonAnlamliDegisiklikTarihi(): string | null {
  const tarihler = yayindakiYazilar()
    .map((yazi) => yazi.guncellemeTarihi || yazi.yayinTarihi)
    .filter((tarih): tarih is string => Boolean(tarih))
    .sort((a, b) => b.localeCompare(a));

  return tarihler[0] || null;
}

/** Boş kategorileri göstermemek için yayımlanmış içerikten kategori listesi üretir. */
export function aktifBlogKategorileri(): BlogKategori[] {
  const aktif = new Set(yayindakiYazilar().map((yazi) => yazi.kategori));
  return BLOG_KATEGORILERI.filter((kategori) => aktif.has(kategori));
}

/** En fazla üç ilgili içerik; yalnız yayımlanmış yazılardan. */
export function ilgiliYazilariBul(yazi: BlogYazisi): YayindakiBlogYazisi[] {
  if (yazi.ilgiliYazilar.length === 0) return [];
  const yayin = new Map(yayindakiYazilar().map((aday) => [aday.slug, aday]));
  return yazi.ilgiliYazilar
    .map((slug) => yayin.get(slug))
    .filter((aday): aday is YayindakiBlogYazisi => Boolean(aday))
    .slice(0, 3);
}

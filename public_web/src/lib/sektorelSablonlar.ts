import { resolveBusinessCategory } from "./businessCategories";

export interface SektorelVitrinPaketi {
  hero_badge: string;
  description: string;
  category_section_title: string;
  product_section_title: string;
  featured_banner_label: string;
  featured_banner_title: string;
  featured_banner_description: string;
  about_kicker: string;
  about_title: string;
  corporate_bio: string;
  about_values: Array<{ id: string; title: string; description: string }>;
  faq_section_kicker: string;
  faq_section_title: string;
  faq_section_description: string;
  faq_items: Array<{ id: string; question: string; answer: string }>;
  gallery_section_kicker: string;
  gallery_section_title: string;
}

const BUTIK_VE_GIYIM_PAKETI: SektorelVitrinPaketi = {
  hero_badge: "Özenle Seçilmiş Parçalar",
  description:
    "Sezonun en trend parçalarını ve zamansız şıklığı samimi butik anlayışıyla sizlerle buluşturuyoruz. Tarzınıza değer katan özenli seçki.",
  category_section_title: "Koleksiyonlar",
  product_section_title: "Öne Çıkan Ürünlerimiz",
  featured_banner_label: "Yeni Sezon",
  featured_banner_title: "Sonbahar & Kış Koleksiyonu Vitrinde",
  featured_banner_description:
    "Gardırobunuzu tazeleyecek en yeni modeller ve seçili parçalarda butiğimize özel avantajlar.",
  about_kicker: "Hikayemiz",
  about_title: "Butik Modasında Samimi Dokunuş",
  corporate_bio:
    "Modayı kalıplardan çıkarıp mahallemizin sıcaklığıyla harmanlıyoruz. Her bir parçayı kumaş kalitesinden dikişine kadar bizzat seçiyor, kendimiz giymeyeceğimiz hiçbir ürünü askımıza asmıyoruz. Tarzınızı yansıtan kombinler için dükkânımıza her zaman bir kahveye bekleriz.",
  about_values: [
    {
      id: "val-1",
      title: "Özenli Seçki",
      description: "Seri üretim yerine her bedene ve zevke uygun özel parçalar.",
    },
    {
      id: "val-2",
      title: "Kaliteli Kumaş",
      description:
        "Yıkandığında formunu kaybetmeyen, gün boyu rahat hissettiren dokular.",
    },
    {
      id: "val-3",
      title: "Güler Yüzlü Hizmet",
      description:
        "Stilinize en uygun kombini bulma konusunda samimi danışmanlık.",
    },
  ],
  faq_section_kicker: "Merak Edilenler",
  faq_section_title: "Sıkça Sorulan Sorular",
  faq_section_description:
    "Alışverişiniz öncesinde ve sonrasında aklınıza takılabilecek konuları derledik.",
  faq_items: [
    {
      id: "faq-1",
      question: "Ürünlerde değişim imkanı var mı?",
      answer:
        "Evet, kullanılmamış ve faturası/etiketi korunan ürünlerde 14 gün içinde mağazamızdan birebir değişim yapabilirsiniz.",
    },
    {
      id: "faq-2",
      question: "Mağazanızda kredi kartı geçerli mi?",
      answer:
        "Evet, tüm banka ve kredi kartlarıyla temassız veya taksitli ödeme yapabilirsiniz.",
    },
    {
      id: "faq-3",
      question: "WhatsApp üzerinden sipariş veya ayırtma yapabilir miyim?",
      answer:
        "Elbette, beğendiğiniz ürünün fotoğrafını ileterek gün sonuna kadar adınıza ayırtabilirsiniz.",
    },
    {
      id: "faq-4",
      question: "Çalışma saatleriniz nedir?",
      answer:
        "Haftanın her günü 10:00 - 20:00 saatleri arasında mağazamızda hizmetinizdeyiz.",
    },
  ],
  gallery_section_kicker: "İşlerimizden",
  gallery_section_title: "Mağaza & Vitrin Görselleri",
};

const GIDA_VE_FIRIN_PAKETI: SektorelVitrinPaketi = {
  hero_badge: "Taze ve Günlük",
  description:
    "Her sabah özenle hazırlanan taze lezzetleri ve güvenilir ürünleri mahallenize taşıyoruz.",
  category_section_title: "Ürün Gruplarımız",
  product_section_title: "Günün Taze Seçkisi",
  featured_banner_label: "Günün Öne Çıkanı",
  featured_banner_title: "Taptaze Ürünler Tezgâhta",
  featured_banner_description:
    "Doğal malzemelerle hazırlanan, günün en taze ve sevilen lezzetleri sizi bekliyor.",
  about_kicker: "Hakkımızda",
  about_title: "Geleneksel Lezzet, Güvenilir Hizmet",
  corporate_bio:
    "Soframıza koymayacağımız hiçbir ürünü tezgâhımıza koymuyoruz. Yerel üreticilerden temin ettiğimiz kaliteli hammaddelerle, hijyenik koşullarda en taze ürünleri hazırlıyoruz.",
  about_values: [
    {
      id: "val-1",
      title: "Günlük Tazelik",
      description: "Her gün taze pişen ve hazırlanan ürünler.",
    },
    {
      id: "val-2",
      title: "Doğal Malzeme",
      description: "Katkısız ve güvenilir içerikler.",
    },
    {
      id: "val-3",
      title: "Mahalle Sıcaklığı",
      description: "Yıllardır değişmeyen güler yüz ve esnaf samimiyeti.",
    },
  ],
  faq_section_kicker: "Merak Edilenler",
  faq_section_title: "Sıkça Sorulan Sorular",
  faq_section_description:
    "Sipariş ve ürünlerimizle ilgili en çok sorulan sorular.",
  faq_items: [
    {
      id: "faq-1",
      question: "Paket servisiniz var mı?",
      answer:
        "Evet, civar mahallelere belirli saatler arasında hızlı paket servisimiz bulunmaktadır.",
    },
    {
      id: "faq-2",
      question: "Toplu sipariş verebilir miyim?",
      answer:
        "Özel günleriniz ve davetleriniz için en az 1 gün önceden haber vererek toplu sipariş oluşturabilirsiniz.",
    },
    {
      id: "faq-3",
      question: "Ürünler günlük mü çıkıyor?",
      answer:
        "Tüm mamullerimiz her sabah erken saatlerde günlük ve taze olarak üretilmektedir.",
    },
  ],
  gallery_section_kicker: "Tezgâhımızdan",
  gallery_section_title: "Ürün & Tezgâh Kareleri",
};

const KAFE_VE_LOKANTA_PAKETI: SektorelVitrinPaketi = {
  hero_badge: "Keyifli Bir Mola",
  description:
    "Günün her saatinde taze kahveler, lezzetli atıştırmalıklar ve samimi bir ortam sizi bekliyor.",
  category_section_title: "Menümüz",
  product_section_title: "Öne Çıkan Lezzetler",
  featured_banner_label: "Şefin Önerisi",
  featured_banner_title: "Günün Özel Lezzetini Keşfedin",
  featured_banner_description:
    "Taze malzemelerle hazırlanan özel spesiyallerimiz ve aromatik kahve çeşitlerimiz masanızda.",
  about_kicker: "Biz Kimiz?",
  about_title: "Lezzetin ve Sohbetin Buluşma Noktası",
  corporate_bio:
    "İyi kahvenin, taze yemeğin ve güzel sohbetin paylaşıldıkça çoğaldığına inanıyoruz. Rahatınız için özenle tasarladığımız mekanımızda sizleri ağırlamaktan mutluluk duyuyoruz.",
  about_values: [
    {
      id: "val-1",
      title: "Taze Çekirdek Kahve",
      description: "Nitelikli çekirdeklerden taze demlenen kahveler.",
    },
    {
      id: "val-2",
      title: "Özel Tarifler",
      description: "Kendi mutfağımızda hazırlanan ev yapımı lezzetler.",
    },
    {
      id: "val-3",
      title: "Huzurlu Mekan",
      description:
        "Çalışmak, dinlenmek veya buluşmak için ferah ortam.",
    },
  ],
  faq_section_kicker: "Merak Edilenler",
  faq_section_title: "Sıkça Sorulan Sorular",
  faq_section_description:
    "Mekanımız ve servislerimiz hakkında merak ettikleriniz.",
  faq_items: [
    {
      id: "faq-1",
      question: "Rezervasyon gerekli mi?",
      answer:
        "Gündüz saatlerinde rezervasyonsuz gelebilirsiniz; akşam saatleri veya kalabalık gruplar için önceden haber vermenizi rica ederiz.",
    },
    {
      id: "faq-2",
      question: "Wi-Fi ve çalışma alanı mevcut mu?",
      answer:
        "Evet, hızlı internetimiz ve dizüstü bilgisayarla çalışmaya uygun prizli masalarımız bulunmaktadır.",
    },
    {
      id: "faq-3",
      question: "Al-götür (take-away) sipariş var mı?",
      answer:
        "Tüm kahve ve menü ürünlerimizi al-götür olarak hızlıca paket yaptırabilirsiniz.",
    },
  ],
  gallery_section_kicker: "Mekanımızdan",
  gallery_section_title: "Kahve & Mekan Anları",
};

const KUAFOR_VE_BAKIM_PAKETI: SektorelVitrinPaketi = {
  hero_badge: "Stil ve Bakım Uzmanı",
  description:
    "Kişisel tarzınızı ve güzelliğinizi ön plana çıkaran profesyonel saç ve bakım hizmetleri.",
  category_section_title: "Hizmetlerimiz",
  product_section_title: "Öne Çıkan İşlemler",
  featured_banner_label: "Özel Bakım",
  featured_banner_title: "Yeni Sezon Saç & Bakım Trendleri",
  featured_banner_description:
    "Yüz hatlarınıza ve saç yapınıza en uygun kesim, renklendirme ve derinlemesine bakım seansları.",
  about_kicker: "Uzman Kadro",
  about_title: "Saçınıza ve Tarzınıza Değer Katan Dokunuş",
  corporate_bio:
    "Yılların mesleki deneyimi ve güncel trendleri takip eden vizyonumuzla, salonumuzdan her ayrılışınızda kendinizi özel ve yenilenmiş hissetmenizi amaçlıyoruz.",
  about_values: [
    {
      id: "val-1",
      title: "Uzman Eller",
      description: "Eğitimli ve deneyimli stilist kadrosu.",
    },
    {
      id: "val-2",
      title: "Kaliteli Ürünler",
      description:
        "Saç sağlığını koruyan profesyonel salon markaları.",
    },
    {
      id: "val-3",
      title: "Kişiye Özel İlgi",
      description: "İhtiyacınıza ve tarzınıza göre özel analiz ve bakım.",
    },
  ],
  faq_section_kicker: "Merak Edilenler",
  faq_section_title: "Sıkça Sorulan Sorular",
  faq_section_description:
    "İşlemler ve randevu hakkında sıkça sorulanlar.",
  faq_items: [
    {
      id: "faq-1",
      question: "Randevusuz gelebilir miyim?",
      answer:
        "Müsaitliğe göre yardımcı oluyoruz ancak bekleme yaşamamanız için randevu almanızı tavsiye ederiz.",
    },
    {
      id: "faq-2",
      question: "Hangi markaları kullanıyorsunuz?",
      answer:
        "Yalnızca dermatolojik testlerden geçmiş, profesyonel kuaför ve bakım markalarını tercih ediyoruz.",
    },
  ],
  gallery_section_kicker: "Çalışmalarımız",
  gallery_section_title: "Öncesi & Sonrası ve Tasarımlar",
};

const EVRENSEL_VARSAYILAN_PAKET: SektorelVitrinPaketi = {
  hero_badge: "Güvenilir Hizmet",
  description:
    "Müşteri memnuniyetini merkezine alan, kaliteli ve özenli hizmet anlayışı.",
  category_section_title: "Hizmet ve Ürün Gruplarımız",
  product_section_title: "Öne Çıkanlar",
  featured_banner_label: "Öne Çıkan",
  featured_banner_title: "Kaliteli Hizmet ve Avantajlı Seçenekler",
  featured_banner_description:
    "İhtiyaçlarınıza en uygun çözümleri sunuyor, her adımda memnuniyetinizi hedefliyoruz.",
  about_kicker: "Hakkımızda",
  about_title: "İşimize Tutku, Müşterimize Güven",
  corporate_bio:
    "Faaliyet gösterdiğimiz alanda güvenilirlik ve kalite standardını koruyarak sizlere en iyi hizmeti sunmak için çalışıyoruz.",
  about_values: [
    {
      id: "val-1",
      title: "Güvenilirlik",
      description: "Verdiğimiz sözün ve işimizin arkasındayız.",
    },
    {
      id: "val-2",
      title: "Kaliteli Hizmet",
      description: "Her aşamada titiz ve özenli çalışma.",
    },
    {
      id: "val-3",
      title: "Müşteri Odaklılık",
      description:
        "İhtiyaçlarınızı dinliyor ve en doğru çözümü üretiyoruz.",
    },
  ],
  faq_section_kicker: "Merak Edilenler",
  faq_section_title: "Sıkça Sorulan Sorular",
  faq_section_description:
    "Hizmetlerimiz ve çalışma prensiplerimiz hakkında merak edilenler.",
  faq_items: [
    {
      id: "faq-1",
      question: "Nasıl iletişime geçebilirim?",
      answer:
        "Telefon veya WhatsApp hattımız üzerinden mesai saatleri içinde bize doğrudan ulaşabilirsiniz.",
    },
    {
      id: "faq-2",
      question: "Ödeme yöntemleri nelerdir?",
      answer:
        "Nakit ve tüm kredi/banka kartları ile güvenli ödeme yapabilirsiniz.",
    },
  ],
  gallery_section_kicker: "İşlerimizden",
  gallery_section_title: "Görseller & Çalışmalar",
};

export function sektorelPaketUret(
  kategoriEtiketi: string | null | undefined,
  mevcutAciklama?: string | null,
): SektorelVitrinPaketi {
  const kategori = kategoriEtiketi ? resolveBusinessCategory(kategoriEtiketi) : null;
  const kategoriId = kategori?.id ?? "";

  let secilenPaket: SektorelVitrinPaketi;
  if (kategoriId === "butik" || kategoriId === "giyim") {
    secilenPaket = BUTIK_VE_GIYIM_PAKETI;
  } else if (kategoriId === "gida" || kategoriId === "firin") {
    secilenPaket = GIDA_VE_FIRIN_PAKETI;
  } else if (kategoriId === "kafe_lokanta") {
    secilenPaket = KAFE_VE_LOKANTA_PAKETI;
  } else if (kategoriId === "kuafor") {
    secilenPaket = KUAFOR_VE_BAKIM_PAKETI;
  } else {
    secilenPaket = EVRENSEL_VARSAYILAN_PAKET;
  }

  // Eğer kullanıcı onboarding'de zaten özel bir açıklama yazdıysa onu koru
  const nihaiAciklama =
    typeof mevcutAciklama === "string" && mevcutAciklama.trim().length > 0
      ? mevcutAciklama.trim()
      : secilenPaket.description;

  return {
    ...secilenPaket,
    description: nihaiAciklama,
  };
}

// ============================================================================
// FAZ 2: ASİSTAN YARATICI YÖNETMEN SEÇENEKLERİ (5 KURUMSAL KATMAN)
// ============================================================================

export interface YonetmenKampanyaSecenegi {
  id: string;
  etiket: string;
  baslik: string;
  aciklama: string;
  rozet: string;
}

export interface YonetmenHikayeSecenegi {
  id: string;
  tonAdi: string;
  kicker: string;
  title: string;
  bio: string;
  values: Array<{ id: string; title: string; description: string }>;
}

export interface SektorelYonetmenSecenekleri {
  kampanyalar: YonetmenKampanyaSecenegi[];
  hikayeler: YonetmenHikayeSecenegi[];
}

const BUTIK_YONETMEN: SektorelYonetmenSecenekleri = {
  kampanyalar: [
    {
      id: "camp-butik-1",
      rozet: "YENİ SEZON",
      etiket: "Sezon Koleksiyonu",
      baslik: "Sonbahar & Kış Koleksiyonu Vitrinde",
      aciklama: "Gardırobunuzu tazeleyecek en yeni modeller ve seçili parçalarda butiğimize özel avantajlar.",
    },
    {
      id: "camp-butik-2",
      rozet: "FIRSAT HAFTASI",
      etiket: "Tanışma İndirimi",
      baslik: "Seçili Triko & Kabanlarda %20 İndirim",
      aciklama: "Bu haftaya özel tüm triko gruplarında ve kaban modellerinde butik esnafı samimiyetiyle indirim fırsatı.",
    },
    {
      id: "camp-butik-3",
      rozet: "SINIRLI STOK",
      etiket: "Özel Kombinler",
      baslik: "Haftanın Özel Kombinleri Askıda!",
      aciklama: "Seri üretim yerine özenle seçilmiş, tükenmeden yakalamanız gereken sınırlı adetli stil parçaları.",
    },
  ],
  hikayeler: [
    {
      id: "story-butik-1",
      tonAdi: "Samimi Aile Butiği",
      kicker: "HİKAYEMİZ",
      title: "Butik Modasında Samimi Dokunuş",
      bio: "Modayı kalıplardan çıkarıp mahallemizin sıcaklığıyla harmanlıyoruz. Her bir parçayı kumaş kalitesinden dikişine kadar bizzat seçiyor, kendimiz giymeyeceğimiz hiçbir ürünü askımıza asmıyoruz. Tarzınızı yansıtan kombinler için dükkânımıza her zaman bir kahveye bekleriz.",
      values: [
        { id: "val-1", title: "Özenli Seçki", description: "Seri üretim yerine her bedene ve zevke uygun özel parçalar." },
        { id: "val-2", title: "Kaliteli Kumaş", description: "Yıkandığında formunu kaybetmeyen, gün boyu rahat hissettiren dokular." },
        { id: "val-3", title: "Güler Yüzlü Hizmet", description: "Stilinize en uygun kombini bulma konusunda samimi danışmanlık." },
      ],
    },
    {
      id: "story-butik-2",
      tonAdi: "Modern & Trend Butik",
      kicker: "DURUŞUMUZ",
      title: "Şehrin Ritmine Uygun Seçkiler",
      bio: "Modanın hızlı tüketimine inat, zamansız ve kaliteli parçalarla gardırobunuzu sadeleştiriyor, stilinize modern bir imza atıyoruz. Az ama öz giyinmeyi seven kadınlar için her hafta yenilenen dinamik koleksiyon.",
      values: [
        { id: "val-1", title: "Zamansız Çizgi", description: "Yıllarca giyilebilecek kaliteli dikiş ve kumaş." },
        { id: "val-2", title: "Özel Tasarım", description: "Pazaryerlerinde bulunmayan özgün stiller." },
        { id: "val-3", title: "Hızlı Stil Danışmanlığı", description: "WhatsApp'tan anlık stil ve beden desteği." },
      ],
    },
    {
      id: "story-butik-3",
      tonAdi: "Dürüst Fiyat & Kalite Güvencesi",
      kicker: "GÜVENCEMİZ",
      title: "Ulaşılabilir Şıklık ve Sağlam Kumaş",
      bio: "En kaliteli yerli dokumaları aracı olmadan doğrudan tezgâhımıza getiriyor, dürüst esnaflık ilkesiyle her bütçeye şıklık sunuyoruz. Ne aldığınızı bildiğiniz, sürpriz faturasız güvenli butik alışverişi.",
      values: [
        { id: "val-1", title: "Dürüst Fiyat", description: "Aracı komisyonu olmadan net esnaf fiyatı." },
        { id: "val-2", title: "Kumaş Garantisi", description: "Çekmeyen, renk atmayan garantili dokular." },
        { id: "val-3", title: "Koşulsuz Değişim", description: "14 gün boyunca mağazadan birebir değişim." },
      ],
    },
  ],
};

const GIDA_YONETMEN: SektorelYonetmenSecenekleri = {
  kampanyalar: [
    {
      id: "camp-gida-1",
      rozet: "GÜNÜN TAZESİ",
      etiket: "Taş Fırın",
      baslik: "Taş Fırından Yeni Çıkan Taptaze Lezzetler",
      aciklama: "Doğal ekşi maya ve katkısız unlarla her sabah fırınlanan sıcacık ekmek ve unlu mamuller.",
    },
    {
      id: "camp-gida-2",
      rozet: "ÇAY SAATİ",
      etiket: "İkindi Lezzeti",
      baslik: "İkindi Çayına Özel Kurabiye & Pasta Seçkisi",
      aciklama: "Geleneksel tariflerle tereyağlı un kurabiyeleri ve günlük tatlılarda komşularımıza özel tatlar.",
    },
    {
      id: "camp-gida-3",
      rozet: "KAHVALTI KEYFİ",
      etiket: "Hafta Sonu",
      baslik: "Kahvaltı Sofralarına Özel Çıtır Simit & Börek",
      aciklama: "Ailenizle yapacağınız kahvaltı için çıtır çıtır simit ve su böreği tezgâhta sıcak hazır.",
    },
  ],
  hikayeler: [
    {
      id: "story-gida-1",
      tonAdi: "Geleneksel Mahalle Fırını",
      kicker: "HİKAYEMİZ",
      title: "Dededen Toruna Taş Fırın Emeği",
      bio: "Unun, suyun ve sabrın hikayesi... Katkı maddesi kullanmadan, atalık tohum unlarıyla yoğurduğumuz hamurlarımızı taş fırının odun ateşinde pişiriyor, sofralarınıza sağlık ve bereket taşıyoruz.",
      values: [
        { id: "val-1", title: "Doğal Ekşi Maya", description: "Geleneksel fermantasyonla sindirimi kolay ekmekler." },
        { id: "val-2", title: "Katkısız Un", description: "Koruyucu ve kimyasal içermeyen temiz tahıllar." },
        { id: "val-3", title: "Sıcak Çıkarım", description: "Günün belirli saatlerinde dumanı üstünde taze pişirim." },
      ],
    },
    {
      id: "story-gida-2",
      tonAdi: "Modern Butik Pastane",
      kicker: "LEZZET YOLCULUĞUMUZ",
      title: "Her Dilimde Özenli Ustalık",
      bio: "En kaliteli çikolatalar ve mevsiminde taze meyvelerle hazırladığımız pasta ve tatlılarımızla en güzel anlarınıza lezzet katıyoruz.",
      values: [
        { id: "val-1", title: "Gerçek Tereyağı", description: "Margarin yerine hakiki tereyağlı geleneksel tarifler." },
        { id: "val-2", title: "Günlük Taze Üretim", description: "Tezgâhta beklemeyen, siparişe göre hazırlanan lezzetler." },
        { id: "val-3", title: "Özel Sipariş Desteği", description: "Doğum günü ve kutlamalarınız için kişiye özel tasarım." },
      ],
    },
    {
      id: "story-gida-3",
      tonAdi: "Temiz ve Sağlıklı Beslenme",
      kicker: "İLKEMİZ",
      title: "Temiz İçerik, Güvenilir Gıda",
      bio: "GDO'suz, koruyucusuz ve tam tahıllı ürünlerle sağlıklı beslenmeyi mahallenize ve sofranıza taşıyoruz.",
      values: [
        { id: "val-1", title: "Şeffaf Reçete", description: "İçinde ne olduğunu bildiğiniz katkısız ürünler." },
        { id: "val-2", title: "Yerel Üretici Desteği", description: "Tarladan doğrudan temin edilen temiz hammaddeler." },
        { id: "val-3", title: "Hijyenik Üretim", description: "Açık mutfak disiplininde titiz standartlar." },
      ],
    },
  ],
};

const KAFE_YONETMEN: SektorelYonetmenSecenekleri = {
  kampanyalar: [
    {
      id: "camp-kafe-1",
      rozet: "ŞEFİN MENÜSÜ",
      etiket: "Ev Yemekleri",
      baslik: "Günün Ev Yemekleri & Anne Eli Lezzetleri",
      aciklama: "Her gün mevsiminde sebzeler ve taze etlerle hazırlanan doyurucu ve sağlıklı tabaklar masanızda.",
    },
    {
      id: "camp-kafe-2",
      rozet: "KAHVE MOLASI",
      etiket: "Nitelikli Kahve",
      baslik: "Taze Çekilmiş Nitelikli Kahve & Tatlı İkilisi",
      aciklama: "Özel kavrum çekirdeklerden demlenen kahvenizin yanında günlük fırınlanmış tatlı avantajı.",
    },
    {
      id: "camp-kafe-3",
      rozet: "ÖĞLE ARASI",
      etiket: "Hızlı Menü",
      baslik: "Çalışanlara Özel Hızlı & Doyurucu Öğle Menüsü",
      aciklama: "Vaktinizi iyi değerlendirmeniz için hızlı servis, sıcak çorba ve ana yemek menüsü hazır.",
    },
  ],
  hikayeler: [
    {
      id: "story-kafe-1",
      tonAdi: "Sıcak Esnaf Lokantası",
      kicker: "HİKAYEMİZ",
      title: "Aynı Kazandan Kardeşçe Sofralar",
      bio: "Kapımızdan giren her misafiri evimize gelmiş gibi ağırlıyoruz. Taze malzeme, bol porsiyon ve güler yüzlü hizmetle mahallemizin sofrası olmaktan gurur duyuyoruz.",
      values: [
        { id: "val-1", title: "Mevsiminde Malzeme", description: "Hale bizzat gidilerek seçilen taze sebze ve etler." },
        { id: "val-2", title: "Doyurucu Porsiyon", description: "Gözü de gönlü de doyuran esnaf cömertliği." },
        { id: "val-3", title: "Güler Yüzlü Hizmet", description: "Yıllardır değişmeyen mahalle sıcaklığı." },
      ],
    },
    {
      id: "story-kafe-2",
      tonAdi: "Nitelikli Butik Kafe",
      kicker: "RUHUMUZ",
      title: "Sakin Bir Mola, İyi Bir Fincan",
      bio: "Şehrin gürültüsünden kaçıp kitabınızı okuyabileceğiniz, dostlarınızla sohbet edebileceğiniz samimi bir yaşam alanı.",
      values: [
        { id: "val-1", title: "Özel Çekirdekler", description: "Dünyanın en iyi kahve çiftliklerinden nitelikli seçki." },
        { id: "val-2", title: "Huzurlu Atmosfer", description: "Çalışmaya ve dinlenmeye uygun rahat ortam." },
        { id: "val-3", title: "Taze Eşlikçiler", description: "Kahvenize eşlik eden ev yapımı tatlılar." },
      ],
    },
    {
      id: "story-kafe-3",
      tonAdi: "Usta Şef Mutfağı",
      kicker: "USTALIĞIMIZ",
      title: "Gelenekten Geleceğe Lezzet İmzası",
      bio: "Klasik lezzetleri modern dokunuşlarla yeniden yorumluyor, damaklarda unutulmaz tatlar bırakıyoruz.",
      values: [
        { id: "val-1", title: "Özel Reçeteler", description: "Ustasından sırrını alan özgün tabaklar." },
        { id: "val-2", title: "Yüksek Hijyen", description: "A sınıfı gıda güvenliği ve titiz mutfak." },
        { id: "val-3", title: "Hızlı Servis", description: "Yemeğinizi soğutmadan masanıza getiren özen." },
      ],
    },
  ],
};

const EVRENSEL_YONETMEN: SektorelYonetmenSecenekleri = {
  kampanyalar: [
    {
      id: "camp-univ-1",
      rozet: "ÖNE ÇIKAN",
      etiket: "Haftanın Fırsatı",
      baslik: "Vitrinin En Çok Tercih Edilen Seçkisi",
      aciklama: "Müşterilerimizin en çok ilgi gösterdiği kaliteli ve güvenilir ürünlerde avantajlı teklifler.",
    },
    {
      id: "camp-univ-2",
      rozet: "YENİ DÖNEM",
      etiket: "Özel Seçki",
      baslik: "Sezonun Yeni ve Gözde Modelleri",
      aciklama: "İşletmemizin özenle hazırladığı güncel koleksiyon ve geniş ürün yelpazesi yayında.",
    },
    {
      id: "camp-univ-3",
      rozet: "TANIŞMA",
      etiket: "Müşteri Memnuniyeti",
      baslik: "İlk Alışverişe Özel Esnaf Avantajı",
      aciklama: "Bizimle tanışan tüm müşterilerimize samimi hizmet ve avantajlı alışveriş deneyimi.",
    },
  ],
  hikayeler: [
    {
      id: "story-univ-1",
      tonAdi: "Güvenilir Mahalle Esnafı",
      kicker: "HİKAYEMİZ",
      title: "Dürüst Hizmet ve Müşteri Güveni",
      bio: "Yılların tecrübesiyle kapımızdan giren her müşterimize dürüst esnaflık anlayışıyla hizmet veriyoruz. İşimizi sevgiyle yapıyor, mahallemize değer katıyoruz.",
      values: [
        { id: "val-1", title: "Dürüstlük", description: "Şeffaf fiyatlandırma ve açık iletişim." },
        { id: "val-2", title: "Kalite Güvencesi", description: "Arkadasında durduğumuz sağlam ürünler." },
        { id: "val-3", title: "Hızlı Destek", description: "Satış sonrasında da yanınızda olan esnaf yaklaşımı." },
      ],
    },
    {
      id: "story-univ-2",
      tonAdi: "Modern ve Dinamik İşletme",
      kicker: "VİZYONUMUZ",
      title: "Gelişen Dünyada Kalıcı Kalite",
      bio: "Müşterilerimizin ihtiyaçlarını yakından takip ediyor, en güncel ürün ve hizmetleri en yüksek kalite standartlarında sunuyoruz.",
      values: [
        { id: "val-1", title: "Yenilikçi Seçki", description: "Sürekli güncellenen modern ürün çeşitliliği." },
        { id: "val-2", title: "Müşteri Odaklılık", description: "Sizin memnuniyetinizi merkeze alan çözümler." },
        { id: "val-3", title: "Kolay İletişim", description: "WhatsApp üzerinden hızlı ve doğrudan iletişim." },
      ],
    },
    {
      id: "story-univ-3",
      tonAdi: "Özenli ve Usta Hizmet",
      kicker: "İLKEMİZ",
      title: "İşin Ehli Olmanın Verdiği Güven",
      bio: "Yaptığımız her işte ustalığı ve titizliği ön planda tutuyoruz. Bizi tercih eden herkesin memnun ayrılması en büyük sermayemizdir.",
      values: [
        { id: "val-1", title: "Ustalık", description: "Yılların birikimiyle doğru yönlendirme." },
        { id: "val-2", title: "Özenli Seçim", description: "Yalnızca beğendiğimiz ürünleri tezgâha koyma." },
        { id: "val-3", title: "Koşulsuz Memnuniyet", description: "Sorunsuz ve güvenli alışveriş deneyimi." },
      ],
    },
  ],
};

export function sektorelYonetmenSecenekleri(
  kategoriEtiketi: string | null | undefined,
): SektorelYonetmenSecenekleri {
  const kategori = kategoriEtiketi ? resolveBusinessCategory(kategoriEtiketi) : null;
  const kategoriId = kategori?.id ?? "";

  if (kategoriId === "butik" || kategoriId === "giyim") {
    return BUTIK_YONETMEN;
  }
  if (kategoriId === "gida" || kategoriId === "firin") {
    return GIDA_YONETMEN;
  }
  if (kategoriId === "kafe_lokanta") {
    return KAFE_YONETMEN;
  }
  return EVRENSEL_YONETMEN;
}


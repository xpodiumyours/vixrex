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

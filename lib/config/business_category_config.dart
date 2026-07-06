import 'package:flutter/material.dart';
import 'package:vixrex/utils/text_utils.dart';

class BusinessCategoryConfig {
  final String id;
  final String label;
  final String sectionTitle;
  final String ctaLabel;
  final String whatsappTemplate;
  final String emoji;
  final IconData icon;
  final List<SuggestedOffering> suggestedOfferings;

  const BusinessCategoryConfig({
    required this.id,
    required this.label,
    required this.sectionTitle,
    required this.ctaLabel,
    required this.whatsappTemplate,
    required this.emoji,
    required this.icon,
    required this.suggestedOfferings,
  });

  static const List<BusinessCategoryConfig> categories = [
    BusinessCategoryConfig(
      id: 'giyim',
      label: 'Giyim',
      sectionTitle: 'Yeni Sezon',
      ctaLabel: 'Ürün Sor',
      whatsappTemplate: 'Merhaba, {storeName}. Ürünleriniz hakkında bilgi almak istiyorum.',
      emoji: '👕',
      icon: Icons.checkroom_rounded,
      suggestedOfferings: [
        SuggestedOffering(title: 'Yeni Sezon Günlük Giyim', description: 'Mevsimlik mont, ceket, pantolon seçenekleri'),
        SuggestedOffering(title: 'Basic & Rahat Kombinler', description: 'Günlük pamuklu t-shirt ve sweat modelleri'),
        SuggestedOffering(title: 'Dış Giyim & Kaban Modelleri', description: 'Şık trençkot ve mont alternatifleri'),
        SuggestedOffering(title: 'Spor Giyim ve Aktif Yaşam', description: 'Eşofman takımları, spor tayt ve büstiyerler'),
      ],
    ),
    BusinessCategoryConfig(
      id: 'butik',
      label: 'Butik',
      sectionTitle: 'Özel Tasarımlar',
      ctaLabel: 'Ürün Sor',
      whatsappTemplate: 'Merhaba, {storeName}. Özel tasarım / butik ürünleriniz hakkında bilgi almak istiyorum.',
      emoji: '🛍',
      icon: Icons.local_mall_rounded,
      suggestedOfferings: [
        SuggestedOffering(title: 'Kişiye Özel Tasarım Elbiseler', description: 'Özel gün ve davetler için sınırlı üretim tasarımlar'),
        SuggestedOffering(title: 'Butik Takı & Aksesuar Serisi', description: 'El yapımı kolyeler, küpeler ve tasarım çantalar'),
        SuggestedOffering(title: 'Sınırlı Sayıda Özel Koleksiyonlar', description: 'Sezonluk özel kumaş ve dikim ürünler'),
        SuggestedOffering(title: 'Tarz & Kombin Danışmanlığı', description: 'Müşterinin stiline uygun kombin öneri hizmeti'),
      ],
    ),
    BusinessCategoryConfig(
      id: 'gida',
      label: 'Gıda',
      sectionTitle: 'Taze Ürünler',
      ctaLabel: 'Sipariş Talebi',
      whatsappTemplate: 'Merhaba, {storeName}. Taze gıda ürünleriniz için sipariş talebi oluşturmak istiyorum.',
      emoji: '🍎',
      icon: Icons.local_grocery_store_rounded,
      suggestedOfferings: [
        SuggestedOffering(title: 'Organik & Taze Sebze/Meyve', description: 'Yerel üreticilerden doğrudan temin edilen taze gıdalar'),
        SuggestedOffering(title: 'Şarküteri & Yöresel Ürünler', description: 'Özel peynir, zeytin ve doğal kahvaltılık çeşitleri'),
        SuggestedOffering(title: 'Doğal Ev Yapımı Soslar & Reçeller', description: 'Katkısız, geleneksel yöntemlerle hazırlanan kavanozlar'),
        SuggestedOffering(title: 'Sağlıklı Atıştırmalık & Kuru Meyveler', description: 'Diyet ve ketojenik beslenmeye uygun kuruyemiş setleri'),
      ],
    ),
    BusinessCategoryConfig(
      id: 'firin',
      label: 'Fırın',
      sectionTitle: 'Bugün Neler Var?',
      ctaLabel: 'Sipariş Talebi',
      whatsappTemplate: 'Merhaba, {storeName}. Taze unlu mamulleriniz için sipariş vermek istiyorum.',
      emoji: '🍞',
      icon: Icons.bakery_dining_rounded,
      suggestedOfferings: [
        SuggestedOffering(title: 'Ekşi Mayalı Taş Fırın Ekmeği', description: 'Geleneksel uzun fermantasyon ekmekler'),
        SuggestedOffering(title: 'Taze Çıkan Simit, Poğaça & Börek', description: 'Sabah saatlerinde sıcak servis edilen unlu mamuller'),
        SuggestedOffering(title: 'Butik Pasta & Tatlı Tasarımı', description: 'Doğum günleri ve özel kutlamalar için sipariş üzeri pastalar'),
        SuggestedOffering(title: 'Günlük Taze Kurabiye & Makaronlar', description: 'Çay ve kahve yanına tatlı/tuzlu kurabiye tepsileri'),
      ],
    ),
    BusinessCategoryConfig(
      id: 'kozmetik',
      label: 'Kozmetik',
      sectionTitle: 'Hizmetler',
      ctaLabel: 'Bilgi Al',
      whatsappTemplate: 'Merhaba, {storeName}. Kişisel bakım hizmetleriniz hakkında bilgi almak istiyorum.',
      emoji: '💄',
      icon: Icons.face_retouching_natural_rounded,
      suggestedOfferings: [
        SuggestedOffering(title: 'Profesyonel Cilt Analizi', description: 'Cilt tipinize en uygun bakım ürünlerinin belirlenmesi'),
        SuggestedOffering(title: 'Doğal / Organik Makyaj Ürünleri', description: 'Cilde zarar vermeyen bitkisel içerikli makyaj malzemeleri'),
        SuggestedOffering(title: 'Dökülme Karşıtı Saç Serumları', description: 'Dökülme karşıtı ve uzatıcı profesyonel saç serumları'),
        SuggestedOffering(title: 'Özel Kalıcı Parfümler', description: 'Teninize en uygun kokuların seçimi ve satışı'),
      ],
    ),
    BusinessCategoryConfig(
      id: 'dekorasyon',
      label: 'Dekorasyon',
      sectionTitle: 'Hizmetler',
      ctaLabel: 'Teklif İste',
      whatsappTemplate: 'Merhaba, {storeName}. Ev dekorasyonu / çiçek tasarımı için teklif almak istiyorum.',
      emoji: '🪴',
      icon: Icons.local_florist_rounded,
      suggestedOfferings: [
        SuggestedOffering(title: 'İç Mekan Salon Bitkileri', description: 'Ev ve ofis ortamları için canlı yeşil bitki yerleşimi'),
        SuggestedOffering(title: 'Özel Gün Çiçek Aranjmanı', description: 'Söz, nişan ve kutlamalara özel şık çiçek buketleri'),
        SuggestedOffering(title: 'El Yapımı Seramik Saksı & Obje', description: 'El yapımı seramik saksılar ve modern ev aksesuarları'),
        SuggestedOffering(title: 'Yapay Çiçek / Teraryum Tasarımı', description: 'Bakım gerektirmeyen şık cam fanus tasarımları'),
      ],
    ),
    BusinessCategoryConfig(
      id: 'elektronik',
      label: 'Elektronik',
      sectionTitle: 'Hizmetler',
      ctaLabel: 'Ürün Sor',
      whatsappTemplate: 'Merhaba, {storeName}. Elektronik ürünleriniz hakkında bilgi almak istiyorum.',
      emoji: '📱',
      icon: Icons.devices_rounded,
      suggestedOfferings: [
        SuggestedOffering(title: 'Telefon Kılıfı & Ekran Koruyucu', description: 'Kılıf, ekran koruyucu ve hızlı şarj setleri'),
        SuggestedOffering(title: 'Bluetooth Kablosuz Kulaklık', description: 'Aktif gürültü engelleyici (ANC) özellikli kulaklıklar'),
        SuggestedOffering(title: 'Akıllı Saat & Spor Bileklik', description: 'Adım sayar ve sağlık takibi yapan modern saatler'),
        SuggestedOffering(title: 'Yüksek Kapasiteli Powerbank', description: 'Taşınabilir şarj bataryaları ve dayanıklı kablolar'),
      ],
    ),
    BusinessCategoryConfig(
      id: 'kirtasiye',
      label: 'Kırtasiye',
      sectionTitle: 'Hizmetler',
      ctaLabel: 'Sipariş Talebi',
      whatsappTemplate: 'Merhaba, {storeName}. Kırtasiye malzemeleri için sipariş talebi oluşturmak istiyorum.',
      emoji: '📚',
      icon: Icons.menu_book_rounded,
      suggestedOfferings: [
        SuggestedOffering(title: 'Okul & Kırtasiye Başlangıç Seti', description: 'Defter, kalem, silgi ve boyaları içeren temel okul paketi'),
        SuggestedOffering(title: 'Akrilik Boya & Sanatsal Hobi Seti', description: 'Resim yapmaya yeni başlayanlar için boya ve fırça seti'),
        SuggestedOffering(title: 'Haftalık/Aylık Planner & Ajanda', description: 'Haftalık ve aylık planlama yapabileceğiniz şık defterler'),
        SuggestedOffering(title: 'Ofis Kırtasiye İhtiyaçları', description: 'Klasör, zımba, dosya ve fotokopi kağıtları paketi'),
      ],
    ),
    BusinessCategoryConfig(
      id: 'kafe_lokanta',
      label: 'Kafe / Lokanta',
      sectionTitle: 'Menüden Öne Çıkanlar',
      ctaLabel: 'WhatsApp’tan Sipariş',
      whatsappTemplate: 'Merhaba, {storeName}. Günün menüsü hakkında bilgi almak ve sipariş vermek istiyorum.',
      emoji: '☕',
      icon: Icons.restaurant_menu_rounded,
      suggestedOfferings: [
        SuggestedOffering(title: 'Zengin Serpme Kahvaltı (2 Kişilik)', description: 'Yöresel ürünlerle donatılmış sıcak kahvaltı tabağı'),
        SuggestedOffering(title: 'Günün Sıcak Çorbası', description: 'Her gün taze pişirilen ev yapımı sıcak çorba'),
        SuggestedOffering(title: 'Hamburger & Patates Sepeti', description: 'Özel ev yapımı köfte ve soslarla hazırlanan burger'),
        SuggestedOffering(title: 'Yeni Nesil Soğuk/Sıcak Kahve', description: 'Yeni nesil kahve çekirdekleriyle hazırlanan içecekler'),
        SuggestedOffering(title: 'Izgara Köfte Menüsü', description: 'Pilav, patates kızartması ve salata eşliğinde ızgara köfte'),
      ],
    ),
    BusinessCategoryConfig(
      id: 'kuafor',
      label: 'Kuaför',
      sectionTitle: 'Hizmetler',
      ctaLabel: 'Randevu Talebi',
      whatsappTemplate: 'Merhaba, {storeName}. Hizmetleriniz için randevu talebi oluşturmak istiyorum.',
      emoji: '✂️',
      icon: Icons.content_cut_rounded,
      suggestedOfferings: [
        SuggestedOffering(title: 'Saç Kesimi & Yıkama', description: 'Yüz hattınıza özel modern saç tasarımı ve yıkama', durationMinutes: 45, isBookable: true),
        SuggestedOffering(title: 'Fön Çekimi (Düz/Kırık/Maşa)', description: 'Profesyonel fön işlemi ve şekillendirme', durationMinutes: 30, isBookable: true),
        SuggestedOffering(title: 'Saç Boyama (Dip veya Komple)', description: 'Kaliteli profesyonel saç boyama uygulaması', durationMinutes: 120, isBookable: true),
        SuggestedOffering(title: 'Keratin Bakımı & Fönü', description: 'Yıpranmış saçlar için besleyici keratin yüklemesi', durationMinutes: 90, isBookable: true),
        SuggestedOffering(title: 'Medikal Cilt Bakımı', description: 'Derinlemesine gözenek temizliği, nemlendirme ve maske', durationMinutes: 60, isBookable: true),
        SuggestedOffering(title: 'Manikür & Pedikür', description: 'Profesyonel el ve ayak tırnak bakımı', durationMinutes: 60, isBookable: true),
        SuggestedOffering(title: 'Profesyonel Gece Makyajı', description: 'Özel gün, nişan ve gece davetlerine uygun makyaj', durationMinutes: 45, isBookable: true),
      ],
    ),
    BusinessCategoryConfig(
      id: 'teknik_servis',
      label: 'Teknik Servis',
      sectionTitle: 'Servisler',
      ctaLabel: 'Servis Talebi',
      whatsappTemplate: 'Merhaba, {storeName}. Cihaz onarımı için servis talebi oluşturmak istiyorum.',
      emoji: '🔧',
      icon: Icons.construction_rounded,
      suggestedOfferings: [
        SuggestedOffering(title: 'Telefon Ekran Değişimi', description: 'Hızlı ve orijinal yedek parça ile ekran yenileme', durationMinutes: 45, isBookable: true),
        SuggestedOffering(title: 'Batarya & Pil Yenileme', description: 'Pil sağlığı düşmüş cihazlar için yeni batarya montajı', durationMinutes: 30, isBookable: true),
        SuggestedOffering(title: 'Anakart & Donanım Onarımı', description: 'Sıvı teması veya şarj entegresi arızalarının tamiri', durationMinutes: 60, isBookable: true),
        SuggestedOffering(title: 'Laptop Temizlik & Fan Bakımı', description: 'Fan temizliği ve termal macun değişimi', durationMinutes: 60, isBookable: true),
        SuggestedOffering(title: 'Yazılım Kurulumu / Format', description: 'Format atma, işletim sistemi kurulumu ve veri yedekleme', durationMinutes: 45, isBookable: true),
      ],
    ),
    BusinessCategoryConfig(
      id: 'hizmet_danismanlik',
      label: 'Hizmet & Danışmanlık',
      sectionTitle: 'Hizmetler',
      ctaLabel: 'Teklif Al',
      whatsappTemplate: 'Merhaba, {storeName}. Danışmanlık / profesyonel hizmetleriniz hakkında bilgi almak istiyorum.',
      emoji: '💼',
      icon: Icons.business_center_rounded,
      suggestedOfferings: [
        SuggestedOffering(title: 'Mali Müşavirlik & Muhasebe', description: 'Gelir-gider takibi, vergi süreçleri ve finansal planlama'),
        SuggestedOffering(title: 'Hukuki Danışmanlık', description: 'Sözleşme hazırlama, hukuki danışma ve dava analizi'),
        SuggestedOffering(title: 'Proje / Marka Yönetimi', description: 'Marka konumlandırma ve kurumsal proje yönetim danışmanlığı'),
        SuggestedOffering(title: 'CV & Kariyer Koçluğu', description: 'CV hazırlama, mülakat simülasyonu ve kariyer hedefleri'),
      ],
    ),
    BusinessCategoryConfig(
      id: 'egitim_ders',
      label: 'Eğitim & Ders',
      sectionTitle: 'Eğitimler',
      ctaLabel: 'Bilgi Al',
      whatsappTemplate: 'Merhaba, {storeName}. Ders programlarınız ve eğitim ücretleriniz hakkında bilgi almak istiyorum.',
      emoji: '🎓',
      icon: Icons.school_rounded,
      suggestedOfferings: [
        SuggestedOffering(title: 'Birebir Özel Matematik Dersi', description: 'İlkokul, ortaokul veya lise düzeyinde okula takviye özel ders'),
        SuggestedOffering(title: 'İngilizce Pratik Seansları', description: 'Akıcı konuşma ve dil pratiği odaklı birebir görüşmeler'),
        SuggestedOffering(title: 'Sınav Hazırlık Koçluğu', description: 'LGS, YKS veya KPSS hazırlık süreçleri için haftalık takip ve planlama'),
        SuggestedOffering(title: 'Online Yazılım Eğitimi', description: 'Sıfırdan programlama dilleri ve web geliştirme dersleri'),
      ],
    ),
    BusinessCategoryConfig(
      id: 'ev_temizlik',
      label: 'Ev & Temizlik',
      sectionTitle: 'Hizmetler',
      ctaLabel: 'Rezervasyon Yap',
      whatsappTemplate: 'Merhaba, {storeName}. Ev / ofis temizliği hizmetiniz için rezervasyon yaptırmak istiyorum.',
      emoji: '🧹',
      icon: Icons.clean_hands_rounded,
      suggestedOfferings: [
        SuggestedOffering(title: 'Detaylı Ev Temizliği', description: 'Günlük veya haftalık dip köşe ev temizliği hizmeti'),
        SuggestedOffering(title: 'Koltuk & Halı Yıkama', description: 'Yerinde profesyonel makinelerle koltuk ve halı yıkama'),
        SuggestedOffering(title: 'İnşaat Sonrası Temizlik', description: 'Yeni teslim alınan boş dairelerin inşaat artığı temizliği'),
        SuggestedOffering(title: 'Dezenfeksiyon Hizmeti', description: 'Ev veya iş yerleri için özel ilaçlama ve dezenfeksiyon'),
      ],
    ),
    BusinessCategoryConfig(
      id: 'spor_fitness',
      label: 'Spor & Fitness',
      sectionTitle: 'Programlar',
      ctaLabel: 'Randevu Al',
      whatsappTemplate: 'Merhaba, {storeName}. Spor salonu / antrenman programlarınız hakkında bilgi almak istiyorum.',
      emoji: '🏋️‍♂️',
      icon: Icons.fitness_center_rounded,
      suggestedOfferings: [
        SuggestedOffering(title: 'Birebir Personal Trainer (PT)', description: 'Kişisel hedeflerinize uygun özel eğitmen eşliğinde antrenman'),
        SuggestedOffering(title: 'Kişiye Özel Beslenme Programı', description: 'Kilo alma, verme veya kas kütlesi artırmaya yönelik liste'),
        SuggestedOffering(title: 'Online Pilates Seansı', description: 'Ev konforunda canlı bağlantı ile pilates dersleri'),
        SuggestedOffering(title: 'Fonksiyonel Antrenman', description: 'Güç, denge ve dayanıklılık odaklı yüksek yoğunluklu grup dersi'),
      ],
    ),
    BusinessCategoryConfig(
      id: 'pet_shop_veteriner',
      label: 'Pet Shop & Veteriner',
      sectionTitle: 'Hizmetler',
      ctaLabel: 'Bilgi Al',
      whatsappTemplate: 'Merhaba, {storeName}. Pet shop ürünleriniz veya veteriner/klinik hizmetleriniz hakkında bilgi almak istiyorum.',
      emoji: '🐾',
      icon: Icons.pets_rounded,
      suggestedOfferings: [
        SuggestedOffering(title: 'Kaliteli Mama & Aksesuar Satışı', description: 'Kedi, köpek ve diğer evcil hayvanlar için premium mamalar'),
        SuggestedOffering(title: 'Pet Kuaför & Banyo Hizmeti', description: 'Tüy kesimi, banyo ve tırnak kesimi gibi bakım işlemleri'),
        SuggestedOffering(title: 'Kedi/Köpek Pansiyonu', description: 'Seyahatlerinizde güvenle bırakabileceğiniz konaklama alanı'),
        SuggestedOffering(title: 'Veteriner Hekim Muayenesi', description: 'Aşı takibi, sağlık muayenesi ve tahlil işlemleri'),
      ],
    ),
    BusinessCategoryConfig(
      id: 'saglik_yasam',
      label: 'Sağlık & Yaşam',
      sectionTitle: 'Hizmetler',
      ctaLabel: 'Randevu Al',
      whatsappTemplate: 'Merhaba, {storeName}. Sağlık, beslenme veya terapi randevusu almak istiyorum.',
      emoji: '🏥',
      icon: Icons.medical_services_rounded,
      suggestedOfferings: [
        SuggestedOffering(title: 'Diyetisyen Seansı & Takibi', description: 'Kişiye özel beslenme analizi ve haftalık vücut ölçümü'),
        SuggestedOffering(title: 'Fizyoterapi Seansı', description: 'Bel, boyun ve kas ağrıları için rehabilitasyon seansları'),
        SuggestedOffering(title: 'Klinik Psikolog Görüşmesi', description: 'Bireysel terapi ve psikolojik danışmanlık hizmetleri'),
        SuggestedOffering(title: 'Sağlıklı Yaşam Danışmanlığı', description: 'Bütünsel sağlık, uyku düzeni ve alışkanlık yönetimi koçluğu'),
      ],
    ),
    BusinessCategoryConfig(
      id: 'oto_arac',
      label: 'Oto & Araç Hizmetleri',
      sectionTitle: 'Hizmetler',
      ctaLabel: 'Randevu Al',
      whatsappTemplate: 'Merhaba, {storeName}. Aracım için servis / bakım randevusu almak istiyorum.',
      emoji: '🚗',
      icon: Icons.directions_car_filled_rounded,
      suggestedOfferings: [
        SuggestedOffering(title: 'Detaylı Oto Yıkama & Kuaför', description: 'İç-dış detaylı temizlik, motor yıkama ve pasta cila'),
        SuggestedOffering(title: 'Periyodik Araç Bakımı', description: 'Motor yağı, filtre değişimleri ve genel araç kontrolü'),
        SuggestedOffering(title: 'Lastik Değişimi & Rot-Balans', description: 'Sezonluk lastik değişimi ve rot-balans ayarı'),
        SuggestedOffering(title: 'Oto Ekspertiz Raporu', description: 'İkinci el araç alım satımı öncesi detaylı ekspertiz incelemesi'),
      ],
    ),
    BusinessCategoryConfig(
      id: 'diger',
      label: 'Diğer',
      sectionTitle: 'Hizmetler',
      ctaLabel: 'Bilgi Al',
      whatsappTemplate: 'Merhaba, {storeName}. Sunduğunuz hizmetler hakkında bilgi almak istiyorum.',
      emoji: '🏪',
      icon: Icons.storefront_rounded,
      suggestedOfferings: [
        SuggestedOffering(title: 'Genel Bilgi & Danışmanlık', description: 'Hizmet detaylarımız hakkında yüz yüze veya online görüşme', durationMinutes: 30, isBookable: true),
        SuggestedOffering(title: 'Özel Hizmet Talebi', description: 'İşletmemizden talep etmek istediğiniz özel işler', durationMinutes: 30, isBookable: true),
      ],
    ),
  ];



  /// Eski key formatlarından (ör: 'butik_giyim') güncel label'a eşleme.
  /// [StoreLocalStorageService.loadPendingCategoryKey] tarafından kullanılır.
  static String? labelForKey(String key) {
    const legacyMappings = {
      'butik_giyim': 'Giyim',
      'kuafor_guzellik': 'Kuaför',
      'kafe_restoran': 'Kafe / Lokanta',
      'berber': 'Kuaför',
      'oto_kuafor': 'Oto & Araç Hizmetleri',
      'market_bakkal': 'Gıda',
      'pastane_tatlici': 'Fırın',
      'mobilya_dekorasyon': 'Dekorasyon',
      'spor_salonu': 'Spor & Fitness',
      'dis_klinigi': 'Sağlık & Yaşam',
      'eczane': 'Sağlık & Yaşam',
      'teknik_servis': 'Teknik Servis',
    };
    if (legacyMappings.containsKey(key)) return legacyMappings[key];

    // Güncel ID ile de dene
    for (final category in categories) {
      if (category.id == key) return category.label;
    }
    return null;
  }

  static BusinessCategoryConfig fromCategoryLabel(String label) {
    final cleanLabel = label.trim().toLowerCase();

    // 1. Try exact match (case-insensitive) against category labels or IDs first
    for (final category in categories) {
      if (category.label.toLowerCase() == cleanLabel || category.id == cleanLabel) {
        return category;
      }
    }
    
    // Also try exact match with normalized values to catch "kuafor" matching exactly the ID "kuafor" or matching a normalized label
    final normalizedLabel = TextUtils.normalizeTurkish(cleanLabel);
    for (final category in categories) {
      if (TextUtils.normalizeTurkish(category.label.toLowerCase()) == normalizedLabel || TextUtils.normalizeTurkish(category.id) == normalizedLabel) {
        return category;
      }
    }
    
    // 2. Fallback to keyword mappings for partial/heuristic matching:
    // (Specific/distinctive terms are placed first; generic terms like 'hizmet' or 'servis' are last)
    const keywordMappings = {
      'kafe': 'kafe_lokanta',
      'restoran': 'kafe_lokanta',
      'lokanta': 'kafe_lokanta',
      'kuaför': 'kuafor',
      'güzellik': 'kuafor',
      'giyim & butik': 'giyim',
      'giyim': 'giyim',
      'butik': 'butik',
      'gıda & fırın': 'gida',
      'gıda': 'gida',
      'fırın': 'firin',
      'evcil hayvan': 'pet_shop_veteriner',
      'veteriner': 'pet_shop_veteriner',
      'pet': 'pet_shop_veteriner',
      'eğitim': 'egitim_ders',
      'ders': 'egitim_ders',
      'temizlik': 'ev_temizlik',
      'spor': 'spor_fitness',
      'fitness': 'spor_fitness',
      'sağlık': 'saglik_yasam',
      'yaşam': 'saglik_yasam',
      'oto': 'oto_arac',
      'araç': 'oto_arac',
      'araba': 'oto_arac',
      'teknik': 'teknik_servis',
      'danışmanlık': 'hizmet_danismanlik',
      'servis': 'teknik_servis',
      'hizmet': 'hizmet_danismanlik',
    };

    for (final entry in keywordMappings.entries) {
      final normalizedKey = TextUtils.normalizeTurkish(entry.key);
      if (normalizedLabel.contains(normalizedKey)) {
        return categories.firstWhere((c) => c.id == entry.value);
      }
    }
    
    return categories.firstWhere(
      (c) => c.id == 'diger',
    );
  }
}

class SuggestedOffering {
  final String title;
  final String description;
  final String price;
  final int durationMinutes;
  final bool isBookable;

  const SuggestedOffering({
    required this.title,
    this.description = '',
    this.price = '',
    this.durationMinutes = 30,
    this.isBookable = false,
  });
}

import 'package:flutter/material.dart';

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
      id: 'giyim_butik',
      label: 'Giyim & Butik',
      sectionTitle: 'Öne Çıkanlar',
      ctaLabel: 'Ürün Sor',
      whatsappTemplate: 'Merhaba, {storeName}. Ürünleriniz hakkında bilgi almak istiyorum.',
      emoji: '🛍',
      icon: Icons.checkroom_rounded,
      suggestedOfferings: [
        SuggestedOffering(title: 'Yeni Sezon Elbiseler', description: 'Farklı beden ve renk seçenekleriyle özel tasarım elbiseler'),
        SuggestedOffering(title: 'Triko, Hırka & Kazak', description: 'Kışlık ve mevsimlik kaliteli triko modeller'),
        SuggestedOffering(title: 'Ceket & Kaban Modelleri', description: 'Şık ve modern günlük veya klasik dış giyim'),
        SuggestedOffering(title: 'Kişiye Özel Kombin Danışmanlığı', description: 'Tarzınıza özel kıyafet kombin önerileri'),
        SuggestedOffering(title: 'Aksesuar & Çanta Çeşitleri', description: 'Şık kombin tamamlayıcı aksesuarlar ve çantalar'),
      ],
    ),
    BusinessCategoryConfig(
      id: 'gida_firin',
      label: 'Gıda & Fırın',
      sectionTitle: 'Bugün Neler Var?',
      ctaLabel: 'Sipariş Talebi',
      whatsappTemplate: 'Merhaba, {storeName}. Paket servis sipariş talebi oluşturmak istiyorum.',
      emoji: '🍞',
      icon: Icons.bakery_dining_rounded,
      suggestedOfferings: [
        SuggestedOffering(title: 'Doğal Ekşi Mayalı Ekmek', description: 'Taş fırında geleneksel yöntemlerle pişirilmiş ekmek'),
        SuggestedOffering(title: 'Taş Fırından Sıcak Simit & Pide', description: 'Sabah saatlerinde taze çıkan hamur işleri'),
        SuggestedOffering(title: 'Butik Doğum Günü Pastası', description: 'Özel günleriniz için siparişe özel tasarım pastalar'),
        SuggestedOffering(title: 'Ev Yapımı Mantı & Hamur İşleri', description: 'Anne eli lezzetinde el açması mantı ve börekler'),
        SuggestedOffering(title: 'Günün Sıcak Çorbası & Yemek', description: 'Ev yapımı sıcak günün çorbası ve sulu yemek alternatifi'),
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

  static BusinessCategoryConfig fromCategoryLabel(String label) {
    final cleanLabel = label.trim().toLowerCase();
    
    // Alias mappings to preserve legacy category names and handle edge cases:
    if (cleanLabel.contains('kafe') || cleanLabel.contains('restoran') || cleanLabel.contains('lokanta')) {
      return categories.firstWhere((c) => c.id == 'kafe_lokanta');
    }
    if (cleanLabel.contains('kuaför') || cleanLabel.contains('güzellik')) {
      return categories.firstWhere((c) => c.id == 'kuafor');
    }
    if (cleanLabel.contains('teknik') || cleanLabel.contains('servis')) {
      return categories.firstWhere((c) => c.id == 'teknik_servis');
    }
    if (cleanLabel.contains('giyim') || cleanLabel.contains('butik')) {
      return categories.firstWhere((c) => c.id == 'giyim_butik');
    }
    if (cleanLabel.contains('gıda') || cleanLabel.contains('fırın')) {
      return categories.firstWhere((c) => c.id == 'gida_firin');
    }
    
    return categories.firstWhere(
      (c) => c.label.toLowerCase() == cleanLabel || c.id == cleanLabel,
      orElse: () => categories.firstWhere((c) => c.id == 'diger'),
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

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
        SuggestedOffering(title: 'Elbise Seçenekleri', description: 'Yeni sezon özel tasarım elbiseler'),
        SuggestedOffering(title: 'Triko & Hırka', description: 'Farklı renk ve beden alternatifleriyle'),
        SuggestedOffering(title: 'Yeni Sezon Ceket', description: 'Şık ve modern günlük ceketler'),
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
        SuggestedOffering(title: 'Sıcak Ekmek & Pide', description: 'Taş fırından taze çıkmış sıcak lezzetler'),
        SuggestedOffering(title: 'Günün Çorbası', description: 'Ev yapımı sıcak günün çorbası'),
        SuggestedOffering(title: 'Ekşi Mayalı Ekmek', description: 'Doğal ekşi mayalı özel üretim ekmek'),
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
        SuggestedOffering(title: 'Cilt Bakımı', description: 'Derinlemesine temizleme ve nemlendirme maskeleri'),
        SuggestedOffering(title: 'Makyaj Danışmanlığı', description: 'Yüz tipinize özel profesyonel makyaj'),
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
        SuggestedOffering(title: 'İç Mekan Bitki Tasarımı', description: 'Ev ve ofisler için canlı bitki yerleşimi'),
        SuggestedOffering(title: 'Özel Gün Çiçek Aranjmanı', description: 'Söz, nişan ve kutlamalara özel buketler'),
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
        SuggestedOffering(title: 'Telefon Aksesuarları', description: 'Kılıf, ekran koruyucu ve şarj kabloları'),
        SuggestedOffering(title: 'Bluetooth Kulaklık', description: 'Yüksek ses kaliteli kablosuz modeller'),
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
        SuggestedOffering(title: 'Okul Hazırlık Seti', description: 'Temel kırtasiye ve defter ihtiyaç paketi'),
        SuggestedOffering(title: 'Hobi Boyama Seti', description: 'Akrilik ve sulu boya başlangıç setleri'),
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
        SuggestedOffering(title: 'Günün Menüsü', description: 'Ana yemek + çorba + içecek menüsü'),
        SuggestedOffering(title: 'Ev Yapımı Mantı', description: 'Yoğurtlu ve tereyağlı soslu el yapımı mantı'),
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
        SuggestedOffering(title: 'Saç Kesimi & Tasarım', description: 'Yıkama ve fön dahil komple saç tasarımı'),
        SuggestedOffering(title: 'Saç Boyama & Keratin', description: 'Saç yapısına özel organik keratin bakımı'),
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
        SuggestedOffering(title: 'Telefon Ekran Değişimi', description: '30 dakikada hızlı ekran değişimi ve garanti'),
        SuggestedOffering(title: 'Batarya Değişimi', description: 'Yüksek kapasiteli batarya yenilemesi'),
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
        SuggestedOffering(title: 'Özel Hizmet Danışmanlığı', description: 'İhtiyaçlarınıza özel detaylı bilgi'),
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

  const SuggestedOffering({
    required this.title,
    this.description = '',
    this.price = '',
  });
}

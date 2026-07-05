import 'package:flutter/material.dart';
import 'package:vixrex/models/store_data.dart';

class HeroDemoAction {
  final IconData icon;
  final Color color;
  final String? title;

  const HeroDemoAction(this.icon, this.color, [this.title]);
}

class HeroDemoLink {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const HeroDemoLink(this.title, this.subtitle, this.icon, this.color);
}

class HeroDemoProfile {
  final String name;
  final String category;
  final String status;
  final String description;
  final IconData icon;
  final Color accentColor;
  final IconData badgeIcon;
  final String badgeText;
  final IconData secondaryBadgeIcon;
  final String secondaryBadgeText;
  final List<HeroDemoAction> actions;
  final List<HeroDemoLink> links;
  final String coverImageUrl;
  final List<String> galleryImages;
  /// Kategori sablon sistemi icin key
  /// Ornek: 'butik_giyim', 'kuafor_guzellik', 'kafe_restoran', 'teknik_servis'
  final String? templateCategoryKey;

  const HeroDemoProfile({
    required this.name,
    required this.category,
    required this.status,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.badgeIcon,
    required this.badgeText,
    required this.secondaryBadgeIcon,
    required this.secondaryBadgeText,
    required this.actions,
    required this.links,
    required this.coverImageUrl,
    required this.galleryImages,
    this.templateCategoryKey,
  });

  Color get secondaryBadgeColor {
    if (links.isEmpty) return accentColor;
    return links.last.color;
  }

  StoreData toStoreData() {
    final galleryItems = [
      StoreGalleryItem(id: 'cover', imageUrl: coverImageUrl),
      ...galleryImages.asMap().entries.map(
        (e) => StoreGalleryItem(id: 'gallery-${e.key}', imageUrl: e.value),
      ),
    ];

    List<StoreOffering> parsedOfferings = [];
    String mappedKategori = 'Diğer';
    double? lat;
    double? lng;
    String phone = '05551234567';
    String web = '';
    String addr = 'Atatürk Cad. No:24, Şişli, İstanbul';

    if (name.contains('Aymira')) {
      mappedKategori = 'Giyim';
      lat = 41.0606;
      lng = 28.9878;
      web = 'aymiragiyim.com';
      parsedOfferings = [
        StoreOffering(
          id: '1',
          title: 'Elbise Seçenekleri',
          description: 'Yeni sezon özel tasarım elbiseler',
          price: 'Mağazada sorunuz',
        ),
        StoreOffering(
          id: '2',
          title: 'Triko & Hırka',
          description: 'Farklı renk ve beden alternatifleriyle',
          price: 'Mağazada sorunuz',
        ),
        StoreOffering(
          id: '3',
          title: 'Yeni Sezon Ceket',
          description: 'Şık ve modern günlük ceketler',
          price: 'Mağazada sorunuz',
        ),
      ];
    } else if (name.contains('Lezzet')) {
      mappedKategori = 'Kafe / Lokanta';
      lat = 41.0422;
      lng = 29.0084;
      web = 'lezzetduragi.com';
      parsedOfferings = [
        StoreOffering(
          id: '1',
          title: 'Günün Menüsü',
          description: 'Ana yemek + çorba + içecek menüsü',
          price: '120 TL',
        ),
        StoreOffering(
          id: '2',
          title: 'Ev Yapımı Mantı',
          description: 'Yoğurtlu ve tereyağlı soslu el yapımı mantı',
          price: '95 TL',
        ),
      ];
    } else if (name.contains('Nova')) {
      mappedKategori = 'Kuaför';
      lat = 41.0370;
      lng = 28.9850;
      web = 'novakuafor.com';
      parsedOfferings = [
        StoreOffering(
          id: '1',
          title: 'Saç Kesimi & Tasarım',
          description: 'Yıkama ve fön dahil komple saç tasarımı',
          price: '180 TL',
        ),
        StoreOffering(
          id: '2',
          title: 'Saç Boyama & Keratin',
          description: 'Saç yapısına özel organik keratin bakımı',
          price: '450 TL',
        ),
      ];
    } else if (name.contains('TeknoFix')) {
      mappedKategori = 'Teknik Servis';
      lat = 41.0150;
      lng = 28.9740;
      web = 'teknofix.com';
      parsedOfferings = [
        StoreOffering(
          id: '1',
          title: 'Telefon Ekran Değişimi',
          description: '30 dakikada hızlı ekran değişimi ve garanti',
          price: 'Mağazada sorunuz',
        ),
        StoreOffering(
          id: '2',
          title: 'Batarya Değişimi',
          description: 'Yüksek kapasiteli batarya yenilemesi',
          price: 'Mağazada sorunuz',
        ),
      ];
    }

    return StoreData(
      name: name,
      businessType: category,
      description: description,
      status: status,
      theme: 'Premium',
      isEsnafMode: true,
      whatsapp: phone,
      website: web,
      address: addr,
      latitude: lat,
      longitude: lng,
      kategori: mappedKategori,
      galleryItems: galleryItems,
      offerings: parsedOfferings,
      marketplaceLinks: links
          .asMap()
          .entries
          .map(
            (e) => MarketplaceLink(
              id: '${e.key}',
              platform: e.value.title,
              url: e.value.title == 'Trendyol'
                  ? 'trendyol.com/magaza/demo'
                  : 'google.com',
              subtitle: e.value.subtitle,
            ),
          )
          .toList(),
    );
  }
}

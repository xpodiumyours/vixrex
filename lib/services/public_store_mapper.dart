import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:vixrex/models/store_data.dart';

/// Supabase public store satırını [StoreData]'ya çevirir (logo + Google dahil).
class PublicStoreMapper {
  const PublicStoreMapper._();

  static StoreData mapStoreFromSupabase({
    required String slug,
    required Map<String, dynamic> data,
  }) {
    final description = _readString(data['description']);
    final corporateBio = _readString(
      data['corporate_bio'],
      fallback: description,
    );

    final rawBooking = data['booking_settings'];
    dynamic bookingMap;
    if (rawBooking is List && rawBooking.isNotEmpty) {
      bookingMap = rawBooking.first;
    } else if (rawBooking is Map) {
      bookingMap = rawBooking;
    }

    final bookingSettings =
        bookingMap != null
            ? BookingSettings.fromJson(Map<String, dynamic>.from(bookingMap))
            : null;

    final storeId = _readString(data['id']);

    return StoreData(
      id: storeId.isEmpty ? null : storeId,
      slug: slug,
      name: _readString(data['name']),
      businessType: _readString(data['business_type']),
      description: description,
      whatsapp: _readString(data['whatsapp']),
      instagram: _readString(data['instagram']),
      website: _readString(data['website']),
      address: _readString(data['address']),
      latitude: _readDouble(data['latitude']),
      longitude: _readDouble(data['longitude']),
      locationAccuracyMeters: _readDouble(data['location_accuracy_meters']),
      locationConsentAt: _readDateTime(data['location_consent_at']),
      locationSource: _readString(data['location_source']),
      theme: _readString(data['theme'], fallback: 'Premium'),
      status: _readString(data['status']),
      isEsnafMode: true,
      isStore: _readBool(data['is_store']),
      corporateBio: corporateBio,
      referencesLink: _readString(data['references_link']),
      shelfImageUrl: _readString(data['shelf_image_url']),
      logoUrl:
          _readString(data['logo_url']).isEmpty
              ? null
              : _readString(data['logo_url']),
      googleBusinessLink: _readString(data['google_business_link']),
      galleryItems: _parseGalleryItems(data['gallery_items']),
      marketplaceLinks: _parseMarketplaceLinks(data['marketplace_links']),
      // Ürünler ilişkisel products tablosundan yüklenir
      products: [],
      offerings: _parseOfferings(data['offerings']),
      kategori: _readString(data['kategori']),
      workingHours: _readString(data['working_hours']),
      bookingSettings: bookingSettings,
    );
  }

  static List<StoreOffering> _parseOfferings(Object? rawOfferings) {
    try {
      final decodedOfferings =
          rawOfferings is String ? jsonDecode(rawOfferings) : rawOfferings;
      if (decodedOfferings is! List) return [];

      return decodedOfferings
          .whereType<Map>()
          .map((o) => StoreOffering.fromJson(Map<String, dynamic>.from(o)))
          .where((o) => o.title.trim().isNotEmpty)
          .take(6)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static String _readString(Object? value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static bool _readBool(Object? value) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }

  static double? _readDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  static DateTime? _readDateTime(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static List<MarketplaceLink> _parseMarketplaceLinks(Object? rawLinks) {
    try {
      final decodedLinks = rawLinks is String ? jsonDecode(rawLinks) : rawLinks;

      if (decodedLinks is! List) return [];

      return decodedLinks
          .whereType<Map>()
          .map(
            (link) => MarketplaceLink(
              id: UniqueKey().toString(),
              platform: _readString(link['platform']),
              url: _readString(link['url']),
              subtitle: _readString(link['subtitle'] ?? ''),
            ),
          )
          .where(
            (link) =>
                link.platform.trim().isNotEmpty && link.url.trim().isNotEmpty,
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  static List<StoreGalleryItem> _parseGalleryItems(Object? rawItems) {
    try {
      final decodedItems = rawItems is String ? jsonDecode(rawItems) : rawItems;

      if (decodedItems is! List) return [];

      return decodedItems
          .whereType<Map>()
          .map(
            (item) =>
                StoreGalleryItem.fromJson(Map<String, dynamic>.from(item)),
          )
          .where((item) => item.imageUrl.trim().isNotEmpty)
          .take(12)
          .toList();
    } catch (_) {
      return [];
    }
  }
}

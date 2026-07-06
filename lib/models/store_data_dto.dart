import 'package:vixrex/models/store_data.dart';

class StoreDataDto {
  const StoreDataDto();

  static Map<String, dynamic> toJson(StoreData data) {
    final shelfImageUrl =
        data.shelfImageUrl.trim().isNotEmpty
            ? data.shelfImageUrl.trim()
            : data.coverImageUrl.trim();

    return {
      'id': data.id,
      'name': data.name,
      'businessType': data.businessType,
      'description': data.description,
      'whatsapp': data.whatsapp,
      'instagram': data.instagram,
      'website': data.website,
      'address': data.address,
      'theme': data.theme,
      'status': data.status,
      'slug': data.slug,
      'isEsnafMode': data.isEsnafMode,
      'logoUrl': data.logoUrl,
      'products': data.products.map((e) => e.toJson()).toList(),
      'productCategories': data.productCategories.map((e) => e.toJson()).toList(),
      'marketplaceLinks': data.marketplaceLinks.map((e) => e.toJson()).toList(),
      'corporateBio': data.corporateBio,
      'referencesLink': data.referencesLink,
      'shelfImageUrl': shelfImageUrl,
      'galleryItems': data.galleryItems.map((e) => e.toJson()).toList(),
      'offerings': data.offerings.map((e) => e.toJson()).toList(),
      'isStore': data.isStore,
      'kategori': data.kategori,
      'workingHours': data.workingHours,
      'province_code': data.provinceCode,
      'province_name': data.provinceName,
      'district_code': data.districtCode,
      'district_name': data.districtName,
      'google_business_link': data.googleBusinessLink,
      'latitude': data.latitude,
      'longitude': data.longitude,
      'locationAccuracyMeters': data.locationAccuracyMeters,
      'locationConsentAt': data.locationConsentAt?.toIso8601String(),
      'locationSource': data.locationSource,
      'bookingSettings': data.bookingSettings?.toJson(),
      'privacyNoticeAcknowledged': data.privacyNoticeAcknowledged,
      'privacyNoticeAcknowledgedAt':
          data.privacyNoticeAcknowledgedAt?.toIso8601String(),
      'privacyNoticeVersion': data.privacyNoticeVersion,
      'privacyNoticeHash': data.privacyNoticeHash,
      'termsAccepted': data.termsAccepted,
      'termsAcceptedAt': data.termsAcceptedAt?.toIso8601String(),
      'termsVersion': data.termsVersion,
      'termsHash': data.termsHash,
      'publicationConsentAccepted': data.publicationConsentAccepted,
      'publicationConsentAcceptedAt':
          data.publicationConsentAcceptedAt?.toIso8601String(),
      'publicationConsentWithdrawnAt':
          data.publicationConsentWithdrawnAt?.toIso8601String(),
      'publicationConsentVersion': data.publicationConsentVersion,
      'publicationConsentHash': data.publicationConsentHash,
    };
  }

  static StoreData fromJson(Map<String, dynamic> json) {
    final parsedProducts =
        (json['products'] as List?)
            ?.whereType<Map>()
            .map((item) => Product.fromJson(Map<String, dynamic>.from(item)))
            .toList() ??
        <Product>[];

    final parsedGalleryItems = _parseGalleryItems(
      json['galleryItems'] ?? json['gallery_items'],
    );
    final parsedOfferings = _parseOfferings(json['offerings']);
    final parsedProductCategories = _parseProductCategories(
      json['productCategories'] ?? json['product_categories'],
      parsedProducts,
    );

    return StoreData(
      id: _getString(json, 'id'),
      name: _getString(json, 'name') ?? '',
      businessType:
          _getString(json, 'businessType', 'business_type') ?? 'Butik',
      description: _getString(json, 'description') ?? '',
      whatsapp: _getString(json, 'whatsapp') ?? '',
      instagram: _getString(json, 'instagram') ?? '',
      website: _getString(json, 'website') ?? '',
      address: _getString(json, 'address') ?? '',
      theme: _getString(json, 'theme') ?? 'Premium',
      status: _getString(json, 'status') ?? 'Açık',
      slug: _getString(json, 'slug') ?? '',
      isEsnafMode:
          (json['isEsnafMode'] ?? json['is_esnaf_mode'] ?? true) as bool,
      logoUrl: _getString(json, 'logoUrl', 'logo_url'),
      products: parsedProducts,
      productCategories: parsedProductCategories,
      marketplaceLinks:
          ((json['marketplaceLinks'] ?? json['marketplace_links']) as List?)
              ?.map((e) => MarketplaceLink.fromJson(e as Map<String, dynamic>))
              .toList(),
      corporateBio: _getString(json, 'corporateBio', 'corporate_bio') ?? '',
      referencesLink:
          _getString(json, 'referencesLink', 'references_link') ?? '',
      shelfImageUrl: _getString(json, 'shelfImageUrl', 'shelf_image_url') ?? '',
      galleryItems: parsedGalleryItems,
      offerings: parsedOfferings,
      isStore: (json['is_store'] ?? json['isStore'] ?? false) as bool,
      kategori: _getString(json, 'kategori', 'category') ?? '',
      workingHours: _getString(json, 'workingHours', 'working_hours') ?? '',
      provinceCode: _getString(json, 'provinceCode', 'province_code') ?? '',
      provinceName: _getString(json, 'provinceName', 'province_name') ?? '',
      districtCode: _getString(json, 'districtCode', 'district_code') ?? '',
      districtName: _getString(json, 'districtName', 'district_name') ?? '',
      googleBusinessLink:
          _getString(json, 'googleBusinessLink', 'google_business_link') ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      locationAccuracyMeters:
          ((json['locationAccuracyMeters'] ?? json['location_accuracy_meters'])
                  as num?)
              ?.toDouble(),
      locationConsentAt: _parseDateTime(
        json['locationConsentAt'] ?? json['location_consent_at'],
      ),
      locationSource: _getString(json, 'locationSource', 'location_source'),
      bookingSettings:
          json['bookingSettings'] != null || json['booking_settings'] != null
              ? BookingSettings.fromJson(
                Map<String, dynamic>.from(
                  (json['bookingSettings'] ?? json['booking_settings']) as Map,
                ),
              )
              : null,
      privacyNoticeAcknowledged:
          (json['privacyNoticeAcknowledged'] ??
                  json['privacy_notice_acknowledged'] ??
                  false)
              as bool,
      privacyNoticeAcknowledgedAt: _parseDateTime(
        json['privacyNoticeAcknowledgedAt'] ??
            json['privacy_notice_acknowledged_at'],
      ),
      privacyNoticeVersion:
          _getString(json, 'privacyNoticeVersion', 'privacy_notice_version') ??
          '',
      privacyNoticeHash:
          _getString(json, 'privacyNoticeHash', 'privacy_notice_hash') ?? '',
      termsAccepted:
          (json['termsAccepted'] ?? json['terms_accepted'] ?? false) as bool,
      termsAcceptedAt: _parseDateTime(
        json['termsAcceptedAt'] ?? json['terms_accepted_at'],
      ),
      termsVersion: _getString(json, 'termsVersion', 'terms_version') ?? '',
      termsHash: _getString(json, 'termsHash', 'terms_hash') ?? '',
      publicationConsentAccepted:
          (json['publicationConsentAccepted'] ??
                  json['publication_consent_accepted'] ??
                  false)
              as bool,
      publicationConsentAcceptedAt: _parseDateTime(
        json['publicationConsentAcceptedAt'] ??
            json['publication_consent_accepted_at'],
      ),
      publicationConsentWithdrawnAt: _parseDateTime(
        json['publicationConsentWithdrawnAt'] ??
            json['publication_consent_withdrawn_at'],
      ),
      publicationConsentVersion:
          _getString(
            json,
            'publicationConsentVersion',
            'publication_consent_version',
          ) ??
          '',
      publicationConsentHash:
          _getString(
            json,
            'publicationConsentHash',
            'publication_consent_hash',
          ) ??
          '',
    );
  }

  static String? _getString(
    Map<String, dynamic> json,
    String camel, [
    String? snake,
  ]) {
    final v = json[camel] ?? (snake != null ? json[snake] : null);
    return v as String?;
  }

  static DateTime? _parseDateTime(Object? raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  static List<StoreGalleryItem> _parseGalleryItems(Object? rawItems) {
    if (rawItems is! List) return [];

    return rawItems
        .whereType<Map>()
        .map(
          (item) => StoreGalleryItem.fromJson(Map<String, dynamic>.from(item)),
        )
        .where((item) => item.imageUrl.trim().isNotEmpty)
        .take(12)
        .toList();
  }

  static List<StoreOffering> _parseOfferings(Object? rawItems) {
    if (rawItems is! List) return [];

    return rawItems
        .whereType<Map>()
        .map((item) => StoreOffering.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.title.trim().isNotEmpty)
        .take(6)
        .toList();
  }

  static List<ProductCategory> _parseProductCategories(
    Object? rawItems,
    List<Product> products,
  ) {
    final parsed =
        rawItems is List
            ? rawItems
                .whereType<Map>()
                .map(
                  (item) => ProductCategory.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .where(
                  (category) =>
                      category.id.trim().isNotEmpty &&
                      category.name.trim().isNotEmpty,
                )
                .toList()
            : <ProductCategory>[];

    if (parsed.isEmpty) {
      final labels = <String>[];
      for (final product in products) {
        final label = product.category.trim();
        if (label.isEmpty || label.toLowerCase() == 'tümü') continue;
        if (!labels.any(
          (existing) => existing.toLowerCase() == label.toLowerCase(),
        )) {
          labels.add(label);
        }
      }
      for (var index = 0; index < labels.length; index++) {
        parsed.add(
          ProductCategory(
            id: 'legacy-category-${index + 1}',
            name: labels[index],
            sortOrder: index,
          ),
        );
      }
    }

    parsed.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    for (final product in products) {
      if (product.categoryId.trim().isNotEmpty) continue;
      final match = parsed.where(
        (category) =>
            category.name.trim().toLowerCase() ==
            product.category.trim().toLowerCase(),
      );
      if (match.isNotEmpty) product.categoryId = match.first.id;
    }
    return parsed;
  }
}

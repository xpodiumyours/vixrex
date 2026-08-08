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
      'phone': data.phone,
      'email': data.email,
      'heroBadge': data.heroBadge,
      'instagram': data.instagram,
      'website': data.website,
      'address': data.address,
      'theme': data.theme,
      'status': data.status,
      'slug': data.slug,
      'isEsnafMode': data.isEsnafMode,
      'logoUrl': data.logoUrl,
      'products': data.products.map((e) => e.toJson()).toList(),
      'productCategories':
          data.productCategories.map((e) => e.toJson()).toList(),
      'marketplaceLinks': data.marketplaceLinks.map((e) => e.toJson()).toList(),
      'corporateBio': data.corporateBio,
      'aboutKicker': data.aboutKicker,
      'aboutTitle': data.aboutTitle,
      'aboutImageUrl': data.aboutImageUrl,
      'aboutImageCaption': data.aboutImageCaption,
      'aboutValues': data.aboutValues.map((e) => e.toJson()).toList(),
      'gallerySectionKicker': data.gallerySectionKicker,
      'gallerySectionTitle': data.gallerySectionTitle,
      'heroLocationText': data.heroLocationText,
      'mapLabel': data.mapLabel,
      'categorySectionTitle': data.categorySectionTitle,
      'productSectionTitle': data.productSectionTitle,
      'galleryActionLabel': data.galleryActionLabel,
      'galleryActionHref': data.galleryActionHref,
      'blogSectionKicker': data.blogSectionKicker,
      'blogSectionTitle': data.blogSectionTitle,
      'faqSectionKicker': data.faqSectionKicker,
      'faqSectionTitle': data.faqSectionTitle,
      'faqSectionDescription': data.faqSectionDescription,
      'sectionVisibility': data.sectionVisibility,
      'showStorefrontRating': data.showStorefrontRating,
      'showDirectionsLink': data.showDirectionsLink,
      'featuredBannerLabel': data.featuredBannerLabel,
      'featuredBannerTitle': data.featuredBannerTitle,
      'featuredBannerDescription': data.featuredBannerDescription,
      'featuredBannerImageUrl': data.featuredBannerImageUrl,
      'featuredBannerPriceText': data.featuredBannerPriceText,
      'referencesLink': data.referencesLink,
      'shelfImageUrl': shelfImageUrl,
      'galleryItems': data.galleryItems.map((e) => e.toJson()).toList(),
      'offerings': data.offerings.map((e) => e.toJson()).toList(),
      'faqItems': data.faqItems.map((e) => e.toJson()).toList(),
      'isStore': data.isStore,
      'isDemo': data.isDemo,
      'storefront_kind': data.storefrontKind,
      'rental_access_status': data.rentalAccessStatus,
      'rental_access_until': data.rentalAccessUntil?.toIso8601String(),
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
    final parsedFaqItems = _parseFaqItems(
      json['faqItems'] ?? json['faq_items'],
    );
    final parsedAboutValues = _parseAboutValues(
      json['aboutValues'] ?? json['about_values'],
    );
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
      phone: _getString(json, 'phone') ?? '',
      email: _getString(json, 'email') ?? '',
      heroBadge: _getString(json, 'heroBadge', 'hero_badge') ?? '',
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
      aboutKicker: _getString(json, 'aboutKicker', 'about_kicker') ?? '',
      aboutTitle: _getString(json, 'aboutTitle', 'about_title') ?? '',
      aboutImageUrl: _getString(json, 'aboutImageUrl', 'about_image_url') ?? '',
      aboutImageCaption:
          _getString(json, 'aboutImageCaption', 'about_image_caption') ?? '',
      aboutValues: parsedAboutValues,
      gallerySectionKicker:
          _getString(json, 'gallerySectionKicker', 'gallery_section_kicker') ??
          '',
      gallerySectionTitle:
          _getString(json, 'gallerySectionTitle', 'gallery_section_title') ??
          '',
      heroLocationText:
          _getString(json, 'heroLocationText', 'hero_location_text') ?? '',
      mapLabel: _getString(json, 'mapLabel', 'map_label') ?? '',
      categorySectionTitle:
          _getString(json, 'categorySectionTitle', 'category_section_title') ??
          '',
      productSectionTitle:
          _getString(json, 'productSectionTitle', 'product_section_title') ??
          '',
      galleryActionLabel:
          _getString(json, 'galleryActionLabel', 'gallery_action_label') ?? '',
      galleryActionHref:
          _getString(json, 'galleryActionHref', 'gallery_action_href') ?? '',
      blogSectionKicker:
          _getString(json, 'blogSectionKicker', 'blog_section_kicker') ?? '',
      blogSectionTitle:
          _getString(json, 'blogSectionTitle', 'blog_section_title') ?? '',
      faqSectionKicker:
          _getString(json, 'faqSectionKicker', 'faq_section_kicker') ?? '',
      faqSectionTitle:
          _getString(json, 'faqSectionTitle', 'faq_section_title') ?? '',
      faqSectionDescription:
          _getString(
            json,
            'faqSectionDescription',
            'faq_section_description',
          ) ??
          '',
      sectionVisibility: _parseSectionVisibility(
        json['sectionVisibility'] ?? json['section_visibility'],
      ),
      showStorefrontRating:
          (json['showStorefrontRating'] ??
                  json['show_storefront_rating'] ??
                  false)
              as bool,
      showDirectionsLink:
          (json['showDirectionsLink'] ?? json['show_directions_link'] ?? true)
              as bool,
      featuredBannerLabel:
          _getString(json, 'featuredBannerLabel', 'featured_banner_label') ??
          '',
      featuredBannerTitle:
          _getString(json, 'featuredBannerTitle', 'featured_banner_title') ??
          '',
      featuredBannerDescription:
          _getString(
            json,
            'featuredBannerDescription',
            'featured_banner_description',
          ) ??
          '',
      featuredBannerImageUrl:
          _getString(
            json,
            'featuredBannerImageUrl',
            'featured_banner_image_url',
          ) ??
          '',
      featuredBannerPriceText:
          _getString(
            json,
            'featuredBannerPriceText',
            'featured_banner_price_text',
          ) ??
          '',
      referencesLink:
          _getString(json, 'referencesLink', 'references_link') ?? '',
      shelfImageUrl: _getString(json, 'shelfImageUrl', 'shelf_image_url') ?? '',
      galleryItems: parsedGalleryItems,
      offerings: parsedOfferings,
      faqItems: parsedFaqItems,
      isStore: (json['is_store'] ?? json['isStore'] ?? false) as bool,
      isDemo: (json['is_demo'] ?? json['isDemo'] ?? false) as bool,
      storefrontKind:
          _getString(json, 'storefrontKind', 'storefront_kind') ?? 'standard',
      rentalAccessStatus:
          _getString(json, 'rentalAccessStatus', 'rental_access_status') ?? '',
      rentalAccessUntil: _parseDateTime(
        json['rentalAccessUntil'] ?? json['rental_access_until'],
      ),
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

  static Map<String, bool> _parseSectionVisibility(Object? raw) {
    if (raw is! Map) return {};
    final result = <String, bool>{};
    for (final entry in raw.entries) {
      final value = entry.value;
      if (value is bool) {
        result[entry.key.toString()] = value;
      } else if (value is String && (value == 'true' || value == 'false')) {
        result[entry.key.toString()] = value == 'true';
      }
    }
    return result;
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

  static List<StoreFaqItem> _parseFaqItems(Object? rawItems) {
    if (rawItems is! List) return [];

    return rawItems
        .whereType<Map>()
        .map((item) => StoreFaqItem.fromJson(Map<String, dynamic>.from(item)))
        .where(
          (item) =>
              item.question.trim().isNotEmpty && item.answer.trim().isNotEmpty,
        )
        .take(20)
        .toList();
  }

  static List<StoreAboutValue> _parseAboutValues(Object? rawItems) {
    if (rawItems is! List) return [];

    return rawItems
        .whereType<Map>()
        .map(
          (item) => StoreAboutValue.fromJson(Map<String, dynamic>.from(item)),
        )
        .where((item) => item.title.trim().isNotEmpty)
        .take(3)
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
                  (item) =>
                      ProductCategory.fromJson(Map<String, dynamic>.from(item)),
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

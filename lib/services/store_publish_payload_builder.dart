import 'package:vixrex/config/public_site_config.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/store_publish_slug_generator.dart';

class StorePublishPayloadBuilder {
  final StorePublishSlugGenerator slugGenerator;

  const StorePublishPayloadBuilder({
    this.slugGenerator = const StorePublishSlugGenerator(),
  });

  String generateSlug(String name) => slugGenerator.generateSlug(name);

  /// Yayın öncesi gösterilen öngörülen vitrin linki (canlı rezervasyon değildir).
  String previewVitrinLink(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '';
    return PublicSiteConfig.buildVitrinLink(generateSlug(trimmed));
  }

  Map<String, dynamic> toStoreInsertMap(
    StoreData data,
    String slug,
    String editToken,
  ) {
    return {'slug': slug, 'edit_token': editToken, ...toStoreUpdateMap(data)};
  }

  Map<String, dynamic> toStoreUpdateMap(StoreData data) {
    final shelfImageUrl =
        data.shelfImageUrl.trim().isNotEmpty
            ? data.shelfImageUrl.trim()
            : data.coverImageUrl.trim();

    return <String, dynamic>{
      'name': data.name.trim(),
      'business_type': data.businessType.trim(),
      'description': data.description.trim(),
      'corporate_bio': data.corporateBio.trim(),
      'about_kicker': data.aboutKicker.trim(),
      'about_title': data.aboutTitle.trim(),
      'about_image_url': data.aboutImageUrl.trim(),
      'about_image_caption': data.aboutImageCaption.trim(),
      'about_values': aboutValuesToJson(data),
      'gallery_section_kicker': data.gallerySectionKicker.trim(),
      'gallery_section_title': data.gallerySectionTitle.trim(),
      'hero_location_text': data.heroLocationText.trim(),
      'map_label': data.mapLabel.trim(),
      'category_section_title': data.categorySectionTitle.trim(),
      'product_section_title': data.productSectionTitle.trim(),
      'gallery_action_label': data.galleryActionLabel.trim(),
      'gallery_action_href': data.galleryActionHref.trim(),
      'blog_section_kicker': data.blogSectionKicker.trim(),
      'blog_section_title': data.blogSectionTitle.trim(),
      'faq_section_kicker': data.faqSectionKicker.trim(),
      'faq_section_title': data.faqSectionTitle.trim(),
      'faq_section_description': data.faqSectionDescription.trim(),
      'section_visibility': data.sectionVisibility,
      'show_storefront_rating': data.showStorefrontRating,
      'show_directions_link': data.showDirectionsLink,
      'featured_banner_label': data.featuredBannerLabel.trim(),
      'featured_banner_title': data.featuredBannerTitle.trim(),
      'featured_banner_description': data.featuredBannerDescription.trim(),
      'featured_banner_image_url': data.featuredBannerImageUrl.trim(),
      'featured_banner_price_text': data.featuredBannerPriceText.trim(),
      'whatsapp': data.whatsapp.trim(),
      'phone': data.phone.trim(),
      'email': data.email.trim(),
      'hero_badge': data.heroBadge.trim(),
      'instagram': data.instagram.trim(),
      'website': data.website.trim(),
      'address': data.address.trim(),
      'theme': data.theme.trim(),
      'status': data.status.trim(),
      'marketplace_links': marketplaceLinksToJson(data),
      'gallery_items': galleryItemsToJson(data),
      'catalog_link': '',
      'references_link': data.referencesLink.trim(),
      'vcard_link': '',
      'shelf_image_url': shelfImageUrl,
      'is_published': true,
      'is_store': data.isStore,
      'kategori': data.kategori,
      'working_hours': data.workingHours.trim(),
      'province_code': data.provinceCode.trim(),
      'province_name': data.provinceName.trim(),
      'district_code': data.districtCode.trim(),
      'district_name': data.districtName.trim(),
      'google_business_link': data.googleBusinessLink.trim(),
      'logo_url': data.logoUrl,
      'latitude': data.latitude,
      'longitude': data.longitude,
      'location_accuracy_meters': data.locationAccuracyMeters,
      'location_consent_at': data.locationConsentAt?.toIso8601String(),
      'location_source': data.locationSource,
      // products artık ayrı products tablosunda tutuluyor (Aşama 5)
      'product_storage_version': 2,
      'product_categories': productCategoriesToJson(data),
      'offerings': offeringsToJson(data),
      'faq_items': faqItemsToJson(data),
      'privacy_notice_acknowledged': data.privacyNoticeAcknowledged,
      'privacy_notice_version': data.privacyNoticeVersion.trim(),
      'privacy_notice_hash': data.privacyNoticeHash.trim(),
      'privacy_notice_acknowledged_at':
          data.privacyNoticeAcknowledgedAt?.toIso8601String(),
      'terms_accepted': data.termsAccepted,
      'terms_version': data.termsVersion.trim(),
      'terms_hash': data.termsHash.trim(),
      'terms_accepted_at': data.termsAcceptedAt?.toIso8601String(),
      'explicit_consent_given': data.publicationConsentAccepted,
      'publication_consent_version': data.publicationConsentVersion.trim(),
      'publication_consent_hash': data.publicationConsentHash.trim(),
      'publication_consent_accepted_at':
          data.publicationConsentAcceptedAt?.toIso8601String(),
      'consent_accepted_at':
          data.privacyNoticeAcknowledgedAt?.toIso8601String(),
    };
  }

  List<Map<String, dynamic>> productsToJson(StoreData data) {
    return data.products.asMap().entries.map((entry) {
      final index = entry.key;
      final p = entry.value;
      final slug = _resolveProductSlug(p, index);
      final item = <String, dynamic>{
        'id': p.id.trim(),
        'name': p.name.trim(),
        'price': p.price.trim(),
        'description': p.description.trim(),
        'imagePath': p.primaryImageUrl,
        'imageUrls': p.displayImageUrls,
        'categoryId': p.categoryId.trim(),
        'category': p.category.trim(),
        'stockStatus': p.stockStatus.trim(),
        'isVisible': p.isVisible,
        'slug': slug,
      };

      void putOptional(String key, String? value) {
        final trimmed = value?.trim();
        if (trimmed != null && trimmed.isNotEmpty) {
          item[key] = trimmed;
        }
      }

      putOptional('source', p.source);
      putOptional('sourceMediaId', p.sourceMediaId);
      putOptional('sourcePermalink', p.sourcePermalink);
      putOptional('importedAt', p.importedAt);
      putOptional('badgeTag', p.badgeTag);
      putOptional('fulfillmentLocation', p.fulfillmentLocation);
      if (p.oldPriceAmount != null) {
        item['oldPriceAmount'] = p.oldPriceAmount;
      }

      return item;
    }).toList();
  }

  List<Map<String, dynamic>> productCategoriesToJson(StoreData data) {
    return data.productCategories
        .asMap()
        .entries
        .map((entry) {
          final category = entry.value;
          return {
            'id': category.id.trim(),
            'name': category.name.trim(),
            'sortOrder': entry.key,
          };
        })
        .where((item) {
          return (item['id'] as String).isNotEmpty &&
              (item['name'] as String).isNotEmpty;
        })
        .toList();
  }

  String _resolveProductSlug(Product product, int index) {
    final explicitSlug = product.slug?.trim();
    if (explicitSlug != null && explicitSlug.isNotEmpty) {
      return generateSlug(explicitSlug);
    }

    final nameSlug = generateSlug(
      product.name.trim().isNotEmpty ? product.name.trim() : 'urun',
    );
    final idSlug = generateSlug(product.id.trim());

    if (idSlug.isNotEmpty && idSlug != 'magazaniz') {
      return '$nameSlug-$idSlug';
    }

    return '$nameSlug-${index + 1}';
  }

  List<Map<String, dynamic>> offeringsToJson(StoreData data) {
    return data.offerings
        .where((o) => o.title.trim().isNotEmpty)
        .take(6)
        .map(
          (o) => {
            'id': o.id.trim(),
            'title': o.title.trim(),
            'description': o.description.trim(),
            'price': o.price.trim(),
            'durationMinutes': o.durationMinutes,
            'isBookable': o.isBookable,
          },
        )
        .toList();
  }

  List<Map<String, String>> faqItemsToJson(StoreData data) {
    return data.faqItems
        .where(
          (item) =>
              item.question.trim().isNotEmpty && item.answer.trim().isNotEmpty,
        )
        .take(20)
        .map(
          (item) => {
            'id':
                item.id.trim().isEmpty
                    ? DateTime.now().microsecondsSinceEpoch.toString()
                    : item.id.trim(),
            'question': item.question.trim(),
            'answer': item.answer.trim(),
          },
        )
        .toList();
  }

  List<Map<String, String>> aboutValuesToJson(StoreData data) {
    return data.aboutValues
        .where((item) => item.title.trim().isNotEmpty)
        .take(3)
        .map(
          (item) => {
            'id':
                item.id.trim().isEmpty
                    ? DateTime.now().microsecondsSinceEpoch.toString()
                    : item.id.trim(),
            'title': item.title.trim(),
            'description': item.description.trim(),
          },
        )
        .toList();
  }

  List<Map<String, String>> galleryItemsToJson(StoreData data) {
    return data.displayGalleryItems
        .where((item) => item.imageUrl.trim().isNotEmpty)
        .take(12)
        .map(
          (item) => {
            'id': item.id.trim(),
            'imageUrl': item.imageUrl.trim(),
            'title': item.title.trim(),
            'description': item.description.trim(),
          },
        )
        .toList();
  }

  List<Map<String, dynamic>> marketplaceLinksToJson(StoreData data) {
    return data.marketplaceLinks
        .where(
          (link) =>
              link.platform.trim().isNotEmpty && link.url.trim().isNotEmpty,
        )
        .map(
          (link) => {
            'platform': link.platform.trim(),
            'url': link.url.trim(),
            'subtitle': link.subtitle.trim(),
          },
        )
        .toList();
  }
}

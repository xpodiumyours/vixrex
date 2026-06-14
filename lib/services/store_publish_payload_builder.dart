import 'package:vitrinx/models/store_data.dart';

class StorePublishPayloadBuilder {
  const StorePublishPayloadBuilder();

  String generateSlug(String name) {
    var slug = name.trim().toLowerCase();
    if (slug.isEmpty) return 'magazaniz';

    const replacements = {
      'ç': 'c',
      'ğ': 'g',
      'ı': 'i',
      'ö': 'o',
      'ş': 's',
      'ü': 'u',
    };

    replacements.forEach((source, target) {
      slug = slug.replaceAll(source, target);
    });

    slug = slug.replaceAll(RegExp(r'[^a-z0-9\s-]'), '');
    slug = slug.replaceAll(RegExp(r'\s+'), '-');
    slug = slug.replaceAll(RegExp(r'-+'), '-');
    slug = slug.replaceAll(RegExp(r'^-|-$'), '');

    return slug.isEmpty ? 'magazaniz' : slug;
  }

  Map<String, dynamic> toStoreInsertMap(
    StoreData data,
    String slug,
    String editToken,
  ) {
    return {'slug': slug, 'edit_token': editToken, ...toStoreUpdateMap(data)};
  }

  Map<String, dynamic> toStoreUpdateMap(StoreData data) {
    final shelfImageUrl = data.coverImageUrl.trim();

    return <String, dynamic>{
      'name': data.name.trim(),
      'business_type': data.businessType.trim(),
      'description': data.description.trim(),
      'corporate_bio': data.corporateBio.trim(),
      'whatsapp': data.whatsapp.trim(),
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
      'logo_url': data.logoUrl,
      'latitude': data.latitude,
      'longitude': data.longitude,
      'location_accuracy_meters': data.locationAccuracyMeters,
      'location_consent_at': data.locationConsentAt?.toIso8601String(),
      'location_source': data.locationSource,
      'products': productsToJson(data),
    };
  }

  List<Map<String, dynamic>> productsToJson(StoreData data) {
    return data.products
        .map(
          (p) => {
            'id': p.id.trim(),
            'name': p.name.trim(),
            'price': p.price.trim(),
            'description': p.description.trim(),
            'imagePath': p.imagePath?.trim(),
            'category': p.category.trim(),
            'stockStatus': p.stockStatus.trim(),
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

  List<Map<String, String>> marketplaceLinksToJson(StoreData data) {
    return data.marketplaceLinks
        .where(
          (link) =>
              link.platform.trim().isNotEmpty && link.url.trim().isNotEmpty,
        )
        .map(
          (link) => {'platform': link.platform.trim(), 'url': link.url.trim()},
        )
        .toList();
  }
}

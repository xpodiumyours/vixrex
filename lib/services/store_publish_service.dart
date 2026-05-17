import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitrinx/models/store_data.dart';

class StorePublishService {
  const StorePublishService();

  Future<String> publishStore(StoreData data) async {
    final slug = _generateSlug(data.name);
    final payload = _toStoreMap(data, slug);

    try {
      await Supabase.instance.client.from('stores').insert(payload);
      return '/v/$slug';
    } on PostgrestException catch (error) {
      if (_isDuplicateSlugError(error)) {
        debugPrint(
          'Store slug already exists, returning existing public link.',
        );
        return '/v/$slug';
      }

      throw Exception('Vitrin yayınlanamadı: ${error.message}');
    } catch (error) {
      throw Exception('Vitrin yayınlanamadı: $error');
    }
  }

  Map<String, dynamic> _toStoreMap(StoreData data, String slug) {
    return {
      'slug': slug,
      'name': data.name.trim(),
      'business_type': data.businessType.trim(),
      'description': data.description.trim(),
      'whatsapp': data.whatsapp.trim(),
      'instagram': data.instagram.trim(),
      'website': data.website.trim(),
      'address': data.address.trim(),
      'theme': data.theme.trim(),
      'status': data.status.trim(),
      'marketplace_links': _marketplaceLinksToJson(data),
      'catalog_link': '',
      'references_link': data.referencesLink.trim(),
      'vcard_link': '',
      'shelf_image_url': data.shelfImageUrl.trim(),
      'is_published': true,
    };
  }

  List<Map<String, String>> _marketplaceLinksToJson(StoreData data) {
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

  bool _isDuplicateSlugError(PostgrestException error) {
    final searchableText =
        [
          error.message,
          error.code,
          error.details?.toString(),
          error.hint,
          error.toString(),
        ].whereType<String>().join(' ').toLowerCase();

    return searchableText.contains('stores_slug_key') ||
        searchableText.contains('duplicate key') ||
        searchableText.contains('23505') ||
        searchableText.contains('409');
  }

  String _generateSlug(String name) {
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
}

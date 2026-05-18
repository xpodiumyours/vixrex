import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitrinx/models/store_data.dart';

class StorePublishService {
  const StorePublishService();

  Future<StorePublishResult> publishStore(
    StoreData data, {
    required String editToken,
  }) async {
    final slug = _generateSlug(data.name);
    final client = Supabase.instance.client;

    try {
      final existingStore =
          await client
              .from('stores')
              .select('slug')
              .eq('slug', slug)
              .maybeSingle();

      if (existingStore == null) {
        await client
            .from('stores')
            .insert(_toStoreInsertMap(data, slug, editToken));
        return StorePublishResult(publicPath: '/v/$slug', wasUpdated: false);
      }

      await _updateStoreWithToken(client, data, slug, editToken);
      return StorePublishResult(publicPath: '/v/$slug', wasUpdated: true);
    } on PostgrestException catch (error) {
      if (_isDuplicateSlugError(error)) {
        debugPrint(
          'Store slug already exists after select, trying token update.',
        );
        await _updateStoreWithToken(client, data, slug, editToken);
        return StorePublishResult(publicPath: '/v/$slug', wasUpdated: true);
      }

      throw StorePublishException(_messageForPostgrestError(error));
    } on StorePublishException {
      rethrow;
    } catch (error) {
      throw StorePublishException('Vitrin yayınlanamadı: $error');
    }
  }

  Future<void> _updateStoreWithToken(
    SupabaseClient client,
    StoreData data,
    String slug,
    String editToken,
  ) async {
    try {
      await client.rpc(
        'update_store_with_token',
        params: {
          'p_slug': slug,
          'p_edit_token': editToken,
          'p_store': _toStoreUpdateMap(data),
        },
      );
    } on PostgrestException catch (error) {
      throw StorePublishException(_messageForPostgrestError(error));
    }
  }

  Map<String, dynamic> _toStoreInsertMap(
    StoreData data,
    String slug,
    String editToken,
  ) {
    return {
      'slug': slug,
      'edit_token': editToken,
      ..._toStoreUpdateMap(data),
      'shelf_image_url': data.shelfImageUrl.trim(),
    };
  }

  Map<String, dynamic> _toStoreUpdateMap(StoreData data) {
    final payload = <String, dynamic>{
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
      'marketplace_links': _marketplaceLinksToJson(data),
      'catalog_link': '',
      'references_link': data.referencesLink.trim(),
      'vcard_link': '',
      'is_published': true,
    };

    final shelfImageUrl = data.shelfImageUrl.trim();
    if (shelfImageUrl.isNotEmpty) {
      payload['shelf_image_url'] = shelfImageUrl;
    }

    return payload;
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

  String _messageForPostgrestError(PostgrestException error) {
    final searchableText =
        [
          error.message,
          error.code,
          error.details?.toString(),
          error.hint,
          error.toString(),
        ].whereType<String>().join(' ').toLowerCase();

    if (searchableText.contains('edit_token_mismatch') ||
        searchableText.contains('edit token mismatch')) {
      return 'Bu vitrin başka bir cihazdan oluşturulmuş olabilir.';
    }

    if (searchableText.contains('update_store_with_token') ||
        searchableText.contains('could not find the function')) {
      return 'Güncelleme altyapısı Supabase tarafında henüz kurulmamış.';
    }

    if (searchableText.contains('row-level security') ||
        searchableText.contains('permission denied') ||
        searchableText.contains('violates row-level security')) {
      return 'Vitrin güncelleme izni Supabase tarafında eksik görünüyor.';
    }

    return 'Vitrin yayınlanamadı: ${error.message}';
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

class StorePublishResult {
  final String publicPath;
  final bool wasUpdated;

  const StorePublishResult({
    required this.publicPath,
    required this.wasUpdated,
  });
}

class StorePublishException implements Exception {
  final String message;

  const StorePublishException(this.message);

  @override
  String toString() => message;
}

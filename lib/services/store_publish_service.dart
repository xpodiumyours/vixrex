import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/utils/whatsapp_link_helper.dart';

class StorePublishValidator {
  const StorePublishValidator();

  static const _standardPlatforms = {
    'trendyol',
    'hepsiburada',
    'n11',
    'amazon',
    'çiçeksepeti',
    'ciceksepeti',
    'shopier',
    'google işletme',
    'google isletme',
    'instagram',
    'whatsapp',
    'diğer',
    'diger',
  };

  // Legacy validate method for compatibility/tests
  String? validate(StoreData data) {
    if (data.isStore) {
      return validateStore(data);
    } else {
      return validateVitrin(data);
    }
  }

  String? _validateLinksAndOfferings(StoreData data) {
    for (final link in data.marketplaceLinks) {
      final trimmedUrl = link.url.trim();
      final platformLower = link.platform.trim().toLowerCase();
      final isCustom =
          platformLower.isNotEmpty &&
          !_standardPlatforms.contains(platformLower);

      if (isCustom && trimmedUrl.isEmpty) {
        return 'Geçersiz web adresi formatı. Lütfen geçerli bir web sitesi veya sosyal medya linki girin.';
      }

      if (trimmedUrl.isNotEmpty) {
        final urlLower = trimmedUrl.toLowerCase();
        if (urlLower.startsWith('javascript:') ||
            urlLower.startsWith('data:') ||
            urlLower.startsWith('file:') ||
            urlLower.startsWith('tel:') ||
            urlLower.startsWith('mailto:')) {
          return 'Geçersiz web adresi formatı. Lütfen geçerli bir web sitesi veya sosyal medya linki girin.';
        }
        final uri = Uri.tryParse(trimmedUrl);
        if (uri == null || !trimmedUrl.contains('.')) {
          return 'Geçersiz web adresi formatı. Lütfen geçerli bir web sitesi veya sosyal medya linki girin.';
        }
      }
    }

    if (data.offerings.length > 6) {
      return 'En fazla 6 adet randevu hizmeti ekleyebilirsiniz.';
    }
    for (final offering in data.offerings) {
      if (offering.title.trim().isEmpty) {
        return 'Randevu hizmeti başlığı boş olamaz.';
      }
      if (offering.title.trim().length > 60) {
        return 'Hizmet başlığı en fazla 60 karakter olabilir.';
      }
      if (offering.description.trim().length > 120) {
        return 'Hizmet açıklaması en fazla 120 karakter olabilir.';
      }
      if (offering.price.trim().length > 30) {
        return 'Hizmet fiyatı en fazla 30 karakter olabilir.';
      }
    }
    return null;
  }

  String? validateVitrin(StoreData data) {
    final missing = <String>[];

    if (data.name.trim().isEmpty) {
      missing.add('işletme adı');
    }
    if (data.whatsapp.trim().isEmpty) {
      missing.add('WhatsApp numarası');
    }
    if (data.address.trim().isEmpty) {
      missing.add('konum / adres');
    }

    if (data.provinceName.trim().isEmpty || data.provinceCode.trim().isEmpty) {
      missing.add('il');
    }
    if (data.districtName.trim().isEmpty || data.districtCode.trim().isEmpty) {
      missing.add('ilçe');
    }
    if (missing.isNotEmpty) {
      return 'Lütfen şu zorunlu alanları doldurun: ${missing.join(', ')}.';
    }
    if (!WhatsAppLinkHelper.isValidTurkeyMobile(data.whatsapp)) {
      return WhatsAppLinkHelper.invalidNumberMessage;
    }

    final extraValidation = _validateLinksAndOfferings(data);
    if (extraValidation != null) {
      return extraValidation;
    }

    final legalValidation = _validateLegalAcceptance(data);
    if (legalValidation != null) {
      return legalValidation;
    }

    return null;
  }

  String? validateStore(StoreData data) {
    final missingItems = <String>[];

    if (data.name.trim().isEmpty) {
      missingItems.add('mağaza adı');
    }
    if (data.whatsapp.trim().isEmpty) {
      missingItems.add('telefon / WhatsApp numarası');
    }
    if (data.description.trim().isEmpty) {
      missingItems.add('kısa açıklama');
    }
    if (data.address.trim().isEmpty) {
      missingItems.add('adres bilgisi');
    }
    if (data.kategori.trim().isEmpty) {
      missingItems.add('işletme kategorisi');
    }

    if (data.provinceName.trim().isEmpty || data.provinceCode.trim().isEmpty) {
      missingItems.add('il');
    }
    if (data.districtName.trim().isEmpty || data.districtCode.trim().isEmpty) {
      missingItems.add('ilçe');
    }
    if (missingItems.isNotEmpty) {
      return 'Mağaza yayınlanmadan önce şu alanları tamamlayın: ${missingItems.join(', ')}.';
    }
    if (!WhatsAppLinkHelper.isValidTurkeyMobile(data.whatsapp)) {
      return WhatsAppLinkHelper.invalidNumberMessage;
    }

    // Validate products if present
    for (final product in data.products) {
      if (product.name.trim().isEmpty) {
        return 'Eklenen tüm ürünlerin adı zorunludur.';
      }
      if (product.category.trim().isEmpty) {
        return 'Eklenen tüm ürünlerin kategorisi zorunludur.';
      }
      if (product.displayImageUrls.length > 4) {
        return 'Bir ürüne en fazla 4 görsel eklenebilir.';
      }
    }

    final extraValidation = _validateLinksAndOfferings(data);
    if (extraValidation != null) {
      return extraValidation;
    }

    final legalValidation = _validateLegalAcceptance(data);
    if (legalValidation != null) {
      return legalValidation;
    }

    return null;
  }

  String? _validateLegalAcceptance(StoreData data) {
    if (!data.privacyNoticeAcknowledged ||
        data.privacyNoticeVersion.trim().isEmpty ||
        data.privacyNoticeHash.trim().isEmpty) {
      return 'Yayınlamak için Aydınlatma Metni hakkında bilgilendirildiğinizi onaylamalısınız.';
    }
    if (!data.termsAccepted ||
        data.termsVersion.trim().isEmpty ||
        data.termsHash.trim().isEmpty) {
      return 'Yayınlamak için Kullanım Şartları’nı kabul etmelisiniz.';
    }
    if (!data.publicationConsentAccepted ||
        data.publicationConsentVersion.trim().isEmpty ||
        data.publicationConsentHash.trim().isEmpty) {
      return 'Vitrininizi yayınlamak için açık rıza vermelisiniz.';
    }
    return null;
  }
}

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
    final shelfImageUrl =
        data.shelfImageUrl.trim().isNotEmpty
            ? data.shelfImageUrl.trim()
            : data.coverImageUrl.trim();

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
      'products': productsToJson(data),
      'product_categories': productCategoriesToJson(data),
      'offerings': offeringsToJson(data),
      'privacy_notice_acknowledged': data.privacyNoticeAcknowledged,
      'privacy_notice_version': data.privacyNoticeVersion.trim(),
      'privacy_notice_hash': data.privacyNoticeHash.trim(),
      'privacy_notice_acknowledged_at': data.privacyNoticeAcknowledgedAt?.toIso8601String(),
      'terms_accepted': data.termsAccepted,
      'terms_version': data.termsVersion.trim(),
      'terms_hash': data.termsHash.trim(),
      'terms_accepted_at': data.termsAcceptedAt?.toIso8601String(),
      'explicit_consent_given': data.publicationConsentAccepted,
      'publication_consent_version': data.publicationConsentVersion.trim(),
      'publication_consent_hash': data.publicationConsentHash.trim(),
      'publication_consent_accepted_at': data.publicationConsentAcceptedAt?.toIso8601String(),
      'consent_accepted_at': data.privacyNoticeAcknowledgedAt?.toIso8601String(),
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

class StorePublishService {
  final StorePublishPayloadBuilder payloadBuilder;
  final StorePublishValidator validator;
  final SupabaseClient? supabaseClient;

  const StorePublishService({
    this.payloadBuilder = const StorePublishPayloadBuilder(),
    this.validator = const StorePublishValidator(),
    this.supabaseClient,
  });

  Future<StorePublishResult> publishStore(
    StoreData data, {
    required String editToken,
  }) async {
    final validationMessage = validator.validate(data);
    if (validationMessage != null) {
      throw StorePublishException(validationMessage);
    }

    final initialSlug =
        data.slug.trim().isNotEmpty
            ? data.slug.trim()
            : payloadBuilder.generateSlug(data.name);
    late final SupabaseClient client;
    var slug = initialSlug;

    try {
      client = supabaseClient ?? Supabase.instance.client;

      final existingStore =
          await client
              .from('stores')
              .select('slug, edit_token')
              .eq('slug', slug)
              .maybeSingle();

      // editToken boşsa ve store varsa → direkt update (RPC yerine)
      // Çünkü update_store_with_token RPC'si boş editToken'i reject eder
      if (editToken.trim().isEmpty && existingStore != null) {
        final payload = payloadBuilder.toStoreUpdateMap(data);
        await client.from('stores').update(payload).eq('slug', slug);
        return StorePublishResult(
          publicPath: '/v/$slug',
          slug: slug,
          wasUpdated: true,
          editToken: editToken,
        );
      }

      if (editToken.trim().isNotEmpty) {
        try {
          final existingByToken =
              await client
                  .from('stores')
                  .select('slug')
                  .eq('edit_token', editToken)
                  .maybeSingle();

          if (existingByToken != null) {
            final dbSlug = (existingByToken['slug'] as String?)?.trim() ?? '';
            if (dbSlug.isNotEmpty) {
              slug = dbSlug;
            }
            await _updateStoreWithToken(client, data, slug, editToken);
            return StorePublishResult(
              publicPath: '/v/$slug',
              slug: slug,
              wasUpdated: true,
              editToken: editToken,
            );
          }
        } on PostgrestException catch (error) {
          debugPrint('Store token lookup skipped: ${error.message}');
        }
      }

      if (existingStore == null) {
        final payload = payloadBuilder.toStoreInsertMap(data, slug, editToken);
        if (client.auth.currentUser != null) {
          payload['user_id'] = client.auth.currentUser!.id;
        }
        await client.from('stores').insert(payload);
        return StorePublishResult(
          publicPath: '/v/$slug',
          slug: slug,
          wasUpdated: false,
          editToken: editToken,
        );
      }

      await _updateStoreWithToken(client, data, slug, editToken);
      return StorePublishResult(
        publicPath: '/v/$slug',
        slug: slug,
        wasUpdated: true,
        editToken: editToken,
      );
    } on PostgrestException catch (error) {
      if (_isDuplicateSlugError(error)) {
        debugPrint(
          'Store slug already exists after select, trying token update.',
        );
        await _updateStoreWithToken(client, data, slug, editToken);
        return StorePublishResult(
          publicPath: '/v/$slug',
          slug: slug,
          wasUpdated: true,
          editToken: editToken,
        );
      }

      throw StorePublishException(
        _messageForPostgrestError(error, data.isStore),
      );
    } on StorePublishException {
      rethrow;
    } catch (error) {
      throw StorePublishException(
        _messageForUnexpectedError(error, data.isStore),
      );
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
          'p_store': payloadBuilder.toStoreUpdateMap(data),
        },
      );
    } on PostgrestException catch (error) {
      throw StorePublishException(
        _messageForPostgrestError(error, data.isStore),
      );
    }
  }

  Future<void> withdrawPublicationConsent({
    required String slug,
    required String editToken,
  }) async {
    if (slug.trim().isEmpty || editToken.trim().isEmpty) {
      throw const StorePublishException(
        'Yayındaki vitrin bilgileri eksik olduğu için rıza geri çekilemedi.',
      );
    }

    try {
      final client = supabaseClient ?? Supabase.instance.client;
      await client.rpc(
        'withdraw_store_publication_consent',
        params: {'p_slug': slug.trim(), 'p_edit_token': editToken.trim()},
      );
    } on PostgrestException catch (error) {
      throw StorePublishException(_messageForPostgrestError(error, false));
    } catch (_) {
      throw const StorePublishException(
        'Yayınlama rızası geri çekilemedi. Lütfen tekrar deneyin.',
      );
    }
  }

  String _messageForPostgrestError(PostgrestException error, bool isStore) {
    final searchableText =
        [
          error.message,
          error.code,
          error.details?.toString(),
          error.hint,
          error.toString(),
        ].whereType<String>().join(' ').toLowerCase();

    if (searchableText.contains('edit_token_mismatch') ||
        searchableText.contains('edit token mismatch') ||
        searchableText.contains('invalid_edit_token')) {
      return isStore
          ? 'Bu mağaza başka bir cihazdan oluşturulmuş olabilir. Lütfen oturumu kapatıp tekrar giriş yapın.'
          : 'Bu vitrin başka bir cihazdan oluşturulmuş olabilir. Lütfen oturumu kapatıp tekrar giriş yapın.';
    }

    if (searchableText.contains('privacy_notice_required') ||
        searchableText.contains('privacy_notice_version_invalid')) {
      return 'Güncel Aydınlatma Metni hakkında bilgilendirildiğinizi onaylamalısınız.';
    }
    if (searchableText.contains('terms_acceptance_required') ||
        searchableText.contains('terms_version_invalid')) {
      return 'Güncel Kullanım Şartları’nı kabul etmelisiniz.';
    }
    if (searchableText.contains('publication_consent_required') ||
        searchableText.contains('publication_consent_version_invalid')) {
      return 'Vitrininizi yayınlamak için güncel açık rıza beyanını onaylamalısınız.';
    }

    if (searchableText.contains('update_store_with_token') ||
        searchableText.contains('could not find the function')) {
      return 'Güncelleme altyapısı Supabase tarafında henüz kurulmamış.';
    }

    if (searchableText.contains('row-level security') ||
        searchableText.contains('permission denied') ||
        searchableText.contains('violates row-level security')) {
      return isStore
          ? 'Mağaza güncelleme izni Supabase tarafında eksik görünüyor.'
          : 'Vitrin güncelleme izni Supabase tarafında eksik görünüyor.';
    }

    return isStore
        ? 'Mağaza yayınlanamadı: ${error.message}'
        : 'Vitrin yayınlanamadı: ${error.message}';
  }

  String _messageForUnexpectedError(Object error, bool isStore) {
    final searchableText = error.toString().toLowerCase();

    if (searchableText.contains('supabase') &&
        (searchableText.contains('initialize') ||
            searchableText.contains('not initialized') ||
            searchableText.contains('has not been initialized') ||
            searchableText.contains('instance'))) {
      return 'Supabase bağlantı bilgileri eksik. Uygulamayı SUPABASE_URL ve SUPABASE_PUBLISHABLE_KEY değerleriyle başlatın.';
    }

    return isStore
        ? 'Mağaza yayınlanamadı: $error'
        : 'Vitrin yayınlanamadı: $error';
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
}

class StorePublishResult {
  final String publicPath;
  final String slug;
  final bool wasUpdated;
  final String editToken;

  const StorePublishResult({
    required this.publicPath,
    required this.slug,
    required this.wasUpdated,
    required this.editToken,
  });
}

class StorePublishException implements Exception {
  final String message;

  const StorePublishException(this.message);

  @override
  String toString() => message;
}

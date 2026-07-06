export 'package:vixrex/services/store_publish_validator.dart';
export 'package:vixrex/services/store_publish_payload_builder.dart';
export 'package:vixrex/services/store_publish_legal_validator.dart';
export 'package:vixrex/services/store_publish_links_validator.dart';
export 'package:vixrex/services/store_publish_slug_generator.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/store_publish_validator.dart';
import 'package:vixrex/services/store_publish_payload_builder.dart';

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
        } on PostgrestException catch (_) {}
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

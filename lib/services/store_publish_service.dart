import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/services/store_publish_payload_builder.dart';
import 'package:vitrinx/services/store_publish_validator.dart';

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

    final slug = payloadBuilder.generateSlug(data.name);
    late final SupabaseClient client;

    try {
      client = supabaseClient ?? Supabase.instance.client;
      final existingStore =
          await client
              .from('stores')
              .select('slug')
              .eq('slug', slug)
              .maybeSingle();

      if (existingStore == null) {
        final payload = payloadBuilder.toStoreInsertMap(data, slug, editToken);
        if (client.auth.currentUser != null) {
          payload['user_id'] = client.auth.currentUser!.id;
        }
        await client.from('stores').insert(payload);
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

      throw StorePublishException(_messageForPostgrestError(error, data.isStore));
    } on StorePublishException {
      rethrow;
    } catch (error) {
      throw StorePublishException(_messageForUnexpectedError(error, data.isStore));
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
      throw StorePublishException(_messageForPostgrestError(error, data.isStore));
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
        searchableText.contains('edit token mismatch')) {
      return isStore
          ? 'Bu mağaza başka bir cihazdan oluşturulmuş olabilir.'
          : 'Bu vitrin başka bir cihazdan oluşturulmuş olabilir.';
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

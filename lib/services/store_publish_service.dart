export 'package:vixrex/services/store_publish_validator.dart';
export 'package:vixrex/services/store_publish_payload_builder.dart';
export 'package:vixrex/services/store_publish_legal_validator.dart';
export 'package:vixrex/services/store_publish_links_validator.dart';
export 'package:vixrex/services/store_publish_slug_generator.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/store_publish_validator.dart';
import 'package:vixrex/services/store_publish_payload_builder.dart';
import 'package:vixrex/core/supabase_error_mapper.dart';

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
        SupabaseErrorMapper.map(error).message,
      );
    } on StorePublishException {
      rethrow;
    } catch (error) {
      throw StorePublishException(
        SupabaseErrorMapper.map(error).message,
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
        SupabaseErrorMapper.map(error).message,
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
      throw StorePublishException(SupabaseErrorMapper.map(error).message);
    } catch (error) {
      throw StorePublishException(
        SupabaseErrorMapper.map(error).message,
      );
    }
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

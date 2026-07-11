import 'package:flutter/foundation.dart';
export 'package:vixrex/services/store_publish_validator.dart';
export 'package:vixrex/services/store_publish_payload_builder.dart';
export 'package:vixrex/services/store_publish_legal_validator.dart';
export 'package:vixrex/services/store_publish_links_validator.dart';
export 'package:vixrex/services/store_publish_slug_generator.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/store_publish_validator.dart';
import 'package:vixrex/services/store_publish_payload_builder.dart';
import 'package:vixrex/core/result.dart';
import 'package:vixrex/core/supabase_error_mapper.dart';
import 'package:vixrex/utils/failure.dart';

class StorePublishService {
  final StorePublishPayloadBuilder payloadBuilder;
  final StorePublishValidator validator;
  final SupabaseClient? supabaseClient;

  const StorePublishService({
    this.payloadBuilder = const StorePublishPayloadBuilder(),
    this.validator = const StorePublishValidator(),
    this.supabaseClient,
  });

  Future<Result<StorePublishResult>> publishStore(
    StoreData data, {
    required String editToken,
  }) async {
    final validationMessage = validator.validate(data);
    if (validationMessage != null) {
      return Result.failure(Failure(validationMessage));
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
        return Result.success(StorePublishResult(
          publicPath: '/v/$slug',
          slug: slug,
          wasUpdated: true,
          editToken: editToken,
        ));
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
            final updateResult = await _updateStoreWithToken(client, data, slug, editToken);
            if (updateResult.isFailure) return Result.failure(updateResult.failure!);
            return Result.success(StorePublishResult(
              publicPath: '/v/$slug',
              slug: slug,
              wasUpdated: true,
              editToken: editToken,
            ));
          }
        } on PostgrestException catch (e) {
          if (kDebugMode) debugPrint('Store update check error: $e');
        }
      }

      if (existingStore == null) {
        final payload = payloadBuilder.toStoreInsertMap(data, slug, editToken);
        if (client.auth.currentUser != null) {
          payload['user_id'] = client.auth.currentUser!.id;
        }
        await client.from('stores').insert(payload);
        return Result.success(StorePublishResult(
          publicPath: '/v/$slug',
          slug: slug,
          wasUpdated: false,
          editToken: editToken,
        ));
      }

      final updateResult = await _updateStoreWithToken(client, data, slug, editToken);
      if (updateResult.isFailure) return Result.failure(updateResult.failure!);
      return Result.success(StorePublishResult(
        publicPath: '/v/$slug',
        slug: slug,
        wasUpdated: true,
        editToken: editToken,
      ));
    } on PostgrestException catch (error) {
      if (_isDuplicateSlugError(error)) {
        final updateResult = await _updateStoreWithToken(client, data, slug, editToken);
        if (updateResult.isFailure) return Result.failure(updateResult.failure!);
        return Result.success(StorePublishResult(
          publicPath: '/v/$slug',
          slug: slug,
          wasUpdated: true,
          editToken: editToken,
        ));
      }

      return Result.failure(SupabaseErrorMapper.map(error));
    } catch (error) {
      return Result.failure(SupabaseErrorMapper.map(error));
    }
  }

  /// Ürünler Supabase'e anında kaydedilir (publish gerektirmez).
  /// RLS'i aşmak için doğrudan UPDATE yerine `update_store_with_token` RPC kullanılır.
  Future<Result<void>> updateProductsOnly(
    StoreData data, {
    required String editToken,
  }) async {
    try {
      final client = supabaseClient ?? Supabase.instance.client;
      final slug = data.slug.trim().isNotEmpty
          ? data.slug.trim()
          : payloadBuilder.generateSlug(data.name);

      if (slug.isEmpty) {
        return Result.failure(Failure('Vitrin slug\'ı bulunamadı.'));
      }

      // edit token ile store'u bul
      final existingByToken = await client
          .from('stores')
          .select('slug')
          .eq('edit_token', editToken)
          .maybeSingle();

      if (existingByToken == null) {
        return Result.failure(Failure(
          'Bu cihazda yayınlanmamış bir vitrin bulunamadı.',
        ));
      }

      final dbSlug = (existingByToken['slug'] as String?)?.trim() ?? slug;

      await client.rpc(
        'update_store_with_token',
        params: {
          'p_slug': dbSlug,
          'p_edit_token': editToken,
          'p_store': {
            'products': payloadBuilder.productsToJson(data),
            'product_categories':
                payloadBuilder.productCategoriesToJson(data),
          },
        },
      );

      return const Result.success(null);
    } catch (e, s) {
      return Result.failure(SupabaseErrorMapper.map(e, s));
    }
  }

  /// Yayın sonrası tek alan yaması (ör. Instagram kullanıcı adı).
  Future<Result<void>> updateStorePatch({
    required String slug,
    required String editToken,
    required Map<String, dynamic> patch,
  }) async {
    final trimmedSlug = slug.trim();
    final trimmedToken = editToken.trim();
    if (trimmedSlug.isEmpty || trimmedToken.isEmpty || patch.isEmpty) {
      return Result.failure(Failure('Vitrin bilgileri eksik.'));
    }

    try {
      final client = supabaseClient ?? Supabase.instance.client;
      await client.rpc(
        'update_store_with_token',
        params: {
          'p_slug': trimmedSlug,
          'p_edit_token': trimmedToken,
          'p_store': patch,
        },
      );
      return const Result.success(null);
    } catch (e, s) {
      return Result.failure(SupabaseErrorMapper.map(e, s));
    }
  }

  Future<Result<void>> _updateStoreWithToken(
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
      return const Result.success(null);
    } catch (e, s) {
      return Result.failure(SupabaseErrorMapper.map(e, s));
    }
  }

  Future<Result<void>> withdrawPublicationConsent({
    required String slug,
    required String editToken,
  }) async {
    if (slug.trim().isEmpty || editToken.trim().isEmpty) {
      return Result.failure(
        Failure('Yayındaki vitrin bilgileri eksik olduğu için rıza geri çekilemedi.'),
      );
    }

    try {
      final client = supabaseClient ?? Supabase.instance.client;
      await client.rpc(
        'withdraw_store_publication_consent',
        params: {'p_slug': slug.trim(), 'p_edit_token': editToken.trim()},
      );
      return const Result.success(null);
    } catch (e, s) {
      return Result.failure(SupabaseErrorMapper.map(e, s));
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

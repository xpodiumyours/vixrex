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

      if (editToken.trim().isEmpty && client.auth.currentUser == null) {
        return Result.failure(Failure('Yayın için edit token gerekli.'));
      }

      // edit_token yazma yetkisi için kullanılır; hiçbir zaman REST ile
      // aranmaz. Slug güvenli bir public/owner alanıdır.
      final existingBySlug =
          await client
              .from('stores')
              .select('slug')
              .eq('slug', slug)
              .maybeSingle();

      if (existingBySlug != null) {
        final dbSlug = (existingBySlug['slug'] as String?)?.trim() ?? '';
        if (dbSlug.isNotEmpty) {
          slug = dbSlug;
        }
        final updateResult = await _updateStoreWithToken(
          client,
          data,
          slug,
          editToken,
        );
        if (updateResult.isSuccess) {
          return Result.success(
            StorePublishResult(
              publicPath: '/v/$slug',
              slug: slug,
              wasUpdated: true,
              editToken: editToken,
            ),
          );
        }
        if (!_isUnauthorizedUpdate(updateResult.failure)) {
          return Result.failure(updateResult.failure!);
        }
        // Slug başka sahibe ait: yeni benzersiz adresle oluştur.
        slug = _allocateUniqueSlug(initialSlug);
      }

      // 2. Yeni vitrin oluştur (RPC)
      try {
        await client.rpc(
          'create_store_with_token',
          params: {
            'p_slug': slug,
            'p_edit_token': editToken,
            'p_store': payloadBuilder.toStoreInsertMap(data, slug, editToken),
          },
        );
        return Result.success(
          StorePublishResult(
            publicPath: '/v/$slug',
            slug: slug,
            wasUpdated: false,
            editToken: editToken,
          ),
        );
      } on PostgrestException catch (error) {
        // Slug çakışıyorsa → yetkiliyse güncelle, değilse yeni slug ile oluştur
        if (_isDuplicateSlugError(error)) {
          final updateResult = await _updateStoreWithToken(
            client,
            data,
            slug,
            editToken,
          );
          if (updateResult.isSuccess) {
            return Result.success(
              StorePublishResult(
                publicPath: '/v/$slug',
                slug: slug,
                wasUpdated: true,
                editToken: editToken,
              ),
            );
          }
          if (!_isUnauthorizedUpdate(updateResult.failure)) {
            return Result.failure(updateResult.failure!);
          }
          slug = _allocateUniqueSlug(initialSlug);
          await client.rpc(
            'create_store_with_token',
            params: {
              'p_slug': slug,
              'p_edit_token': editToken,
              'p_store': payloadBuilder.toStoreInsertMap(data, slug, editToken),
            },
          );
          return Result.success(
            StorePublishResult(
              publicPath: '/v/$slug',
              slug: slug,
              wasUpdated: false,
              editToken: editToken,
            ),
          );
        }
        return Result.failure(SupabaseErrorMapper.map(error));
      }
    } on PostgrestException catch (error) {
      if (_isDuplicateSlugError(error)) {
        final updateResult = await _updateStoreWithToken(
          client,
          data,
          slug,
          editToken,
        );
        if (updateResult.isSuccess) {
          return Result.success(
            StorePublishResult(
              publicPath: '/v/$slug',
              slug: slug,
              wasUpdated: true,
              editToken: editToken,
            ),
          );
        }
        if (!_isUnauthorizedUpdate(updateResult.failure)) {
          return Result.failure(updateResult.failure!);
        }
        slug = _allocateUniqueSlug(initialSlug);
        await client.rpc(
          'create_store_with_token',
          params: {
            'p_slug': slug,
            'p_edit_token': editToken,
            'p_store': payloadBuilder.toStoreInsertMap(data, slug, editToken),
          },
        );
        return Result.success(
          StorePublishResult(
            publicPath: '/v/$slug',
            slug: slug,
            wasUpdated: false,
            editToken: editToken,
          ),
        );
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
      final slug =
          data.slug.trim().isNotEmpty
              ? data.slug.trim()
              : payloadBuilder.generateSlug(data.name);

      if (slug.isEmpty) {
        return Result.failure(Failure('Vitrin slug\'ı bulunamadı.'));
      }

      await client.rpc(
        'update_store_with_token',
        params: {
          'p_slug': slug,
          'p_edit_token': editToken,
          'p_store': {
            'products': payloadBuilder.productsToJson(data),
            'product_categories': payloadBuilder.productCategoriesToJson(data),
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
        Failure(
          'Yayındaki vitrin bilgileri eksik olduğu için rıza geri çekilemedi.',
        ),
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

  /// Token doğrulamasıyla vitrini ve ona bağlı verileri kalıcı olarak siler.
  Future<Result<void>> deleteStore({
    required String slug,
    String? editToken,
  }) async {
    if (slug.trim().isEmpty) {
      return Result.failure(Failure('Silinecek vitrin bilgileri eksik.'));
    }

    try {
      final client = supabaseClient ?? Supabase.instance.client;
      final normalizedToken = editToken?.trim();
      await client.rpc(
        'delete_store_with_token',
        params: {
          'p_slug': slug.trim(),
          'p_edit_token':
              normalizedToken == null || normalizedToken.isEmpty
                  ? ''
                  : normalizedToken,
        },
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

  bool _isUnauthorizedUpdate(Failure? failure) {
    if (failure == null) return false;
    final text = failure.message.toLowerCase();
    return text.contains('başka bir cihazdan') ||
        text.contains('store_update_not_allowed') ||
        text.contains('edit_token_mismatch') ||
        text.contains('erişim reddedildi');
  }

  String _allocateUniqueSlug(String baseSlug) {
    final cleaned = baseSlug.trim().isEmpty ? 'magazaniz' : baseSlug.trim();
    final stamp = DateTime.now().millisecondsSinceEpoch.toString();
    final suffix = stamp.length > 6 ? stamp.substring(stamp.length - 6) : stamp;
    return '$cleaned-$suffix';
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

export 'package:vixrex/services/store_publish_validator.dart';
export 'package:vixrex/services/store_publish_payload_builder.dart';
export 'package:vixrex/services/store_publish_legal_validator.dart';
export 'package:vixrex/services/store_publish_links_validator.dart';
export 'package:vixrex/services/store_publish_slug_generator.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/core/result.dart';
import 'package:vixrex/core/supabase_error_mapper.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/repositories/supabase_product_repository.dart';
import 'package:vixrex/services/product_catalog_sync_service.dart';
import 'package:vixrex/services/product_category_sync_service.dart';
import 'package:vixrex/services/product_image_cleanup_service.dart';
import 'package:vixrex/services/product_service.dart';
import 'package:vixrex/services/store_publish_payload_builder.dart';
import 'package:vixrex/services/store_publish_validator.dart';
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

  /// Verilen slug bulutta YAYINDA duruyor mu?
  ///
  /// Üç cevap verir, ikisi değil:
  ///   true  — kayıt bulutta var
  ///   false — bulut kesin olarak "yok" dedi
  ///   null  — BİLİNMİYOR (bağlantı yok, istemci yok, hata)
  ///
  /// NEDEN ÜÇ CEVAP: karşılama ekranı "vitrinin var" derken tarayıcının
  /// hafızasına bakıyordu. Bulutta silinmiş bir vitrin uygulamada
  /// sonsuza kadar görünüyordu (2026-08-07, bulgu 17). Ama yalnız
  /// true/false dönseydik, internet yokken de "yok" der ve esnafın
  /// yerel kaydını silerdik. Bilinmeyen hâli ayrı olmalı: şüphede
  /// hiçbir şey silinmez.
  Future<bool?> yayindaMi(String slug) async {
    final temiz = slug.trim();
    if (temiz.isEmpty) return false;

    final client = supabaseClient ?? Supabase.instance.client;
    try {
      final response =
          await client
              .from('stores')
              .select('slug')
              .eq('slug', temiz)
              .eq('is_published', true)
              .maybeSingle();
      return response != null;
    } catch (_) {
      return null;
    }
  }

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

      // Ürünlü mağazada public yayın son adım olmalıdır. İlk yayında
      // save_store_draft_with_token her koşulda is_published=false tutar;
      // Product CORE o görünmeyen satıra yazılır. Katalog tamamen
      // senkronlanmadan aşağıdaki public publish adımlarına geçilmez.
      if (data.products.isNotEmpty) {
        final catalogStage = await _stageCatalogBeforePublish(
          client: client,
          data: data,
          preferredSlug: slug,
          editToken: editToken,
        );
        if (catalogStage.isFailure || catalogStage.data == null) {
          return Result.failure(
            catalogStage.failure ??
                Failure('Ürün kataloğu yayın öncesi hazırlanamadı.'),
          );
        }
        slug = catalogStage.data!.slug;
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

        // İLK YAYINDAN SONRA BÖLÜMLER AYRICA YAZILIR.
        //
        // SORUN (2026-08-08 tespiti): Manuel panelde Hakkımızda ve SSS
        // doldurulup yayınlanıyor ama vitrinde görünmüyordu. Zincir şurada
        // kopuyordu:
        //   Flutter modeli          → alanlar var
        //   Panel formu             → düzenleme ekranı var
        //   Yayın yükü              → about_title, faq_items gönderiliyor
        //   create_store_with_token → BU SÜTUNLARI YAZMIYOR   ← kopma
        //   update_store_with_token → yazıyor
        //   Vitrin çizimi           → about_title boşsa bölümü hiç çizmiyor
        //
        // Yani ilk yayında girilen veri sessizce kayboluyordu; sonradan
        // panelden kaydedince görünüyordu.
        //
        // NEDEN VERİTABANI DEĞİL BURASI DÜZELTİLDİ: eksik sekiz sütunu
        // create fonksiyonuna eklemek 170 satırlık bir fonksiyonu elle
        // yeniden yazmayı gerektiriyordu ve iki denemede de yapıştırma
        // hatasıyla düştü. Güncelleme fonksiyonu zaten doğru çalışıyor;
        // onu bir kez daha çağırmak hem kısa hem risksiz.
        //
        // Başarısız olursa yayın YİNE DE geçerlidir: vitrin yayında,
        // yalnız Hakkımızda/SSS bölümleri eksik kalır. Esnafı yayından
        // etmemek için hata yutulur.
        await _updateStoreWithToken(client, data, slug, editToken);

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

  Future<Result<_CatalogStageResult>> _stageCatalogBeforePublish({
    required SupabaseClient client,
    required StoreData data,
    required String preferredSlug,
    required String editToken,
  }) async {
    var slug = preferredSlug.trim();
    if (slug.isEmpty) {
      slug = payloadBuilder.generateSlug(data.name);
    }

    try {
      var storeId =
          _isUuid(data.id?.trim() ?? '') ? data.id!.trim() : null;
      storeId ??= await _storeIdForEditToken(client, slug, editToken);

      if (storeId == null) {
        try {
          await _saveCatalogDraft(client, data, slug, editToken);
        } on PostgrestException catch (error) {
          if (!_isDraftSlugConflict(error)) rethrow;
          slug = _allocateUniqueSlug(slug);
          await _saveCatalogDraft(client, data, slug, editToken);
        }

        storeId = await _storeIdForEditToken(client, slug, editToken);
        if (storeId == null) {
          return Result.failure(
            Failure('Ürün kataloğu için mağaza kimliği doğrulanamadı.'),
          );
        }
      }

      data.id = storeId;
      data.slug = slug;

      var products = List<Product>.of(data.products);
      var categories = List<ProductCategory>.of(data.productCategories);

      if (categories.isNotEmpty) {
        final categoryService = ProductCategorySyncService(client: client);
        final categoryResult = await categoryService.sync(
          storeId: storeId,
          editToken: editToken,
          categories: categories,
          products: products,
        );
        categories = categoryResult.categories;
        products = categoryResult.products;
      }

      final productService = ProductService(
        repository: SupabaseProductRepository(client: client),
        imageCleanupService: ProductImageCleanupService(client: client),
      );
      final catalogService = ProductCatalogSyncService(
        productService: productService,
      );
      final catalogResult = await catalogService.syncCatalog(
        storeId: storeId,
        editToken: editToken,
        products: products,
      );
      if (catalogResult.isFailure || catalogResult.data == null) {
        return Result.failure(
          catalogResult.failure ?? Failure('Ürün kataloğu kaydedilemedi.'),
        );
      }

      data.productCategories = categories;
      data.products = catalogResult.data!;
      return Result.success(_CatalogStageResult(slug: slug, storeId: storeId));
    } on PostgrestException catch (error) {
      return Result.failure(SupabaseErrorMapper.map(error));
    } catch (error) {
      return Result.failure(SupabaseErrorMapper.map(error));
    }
  }

  Future<void> _saveCatalogDraft(
    SupabaseClient client,
    StoreData data,
    String slug,
    String editToken,
  ) async {
    await client.rpc(
      'save_store_draft_with_token',
      params: {
        'p_slug': slug,
        'p_edit_token': editToken.trim(),
        'p_store': payloadBuilder.toStoreUpdateMap(data),
      },
    );
  }

  Future<String?> _storeIdForEditToken(
    SupabaseClient client,
    String slug,
    String editToken,
  ) async {
    final value = await client.rpc(
      'get_store_id_for_edit_token',
      params: {
        'p_slug': slug.trim(),
        'p_edit_token': editToken.trim(),
      },
    );
    final id = value?.toString().trim() ?? '';
    return _isUuid(id) ? id : null;
  }

  bool _isDraftSlugConflict(PostgrestException error) {
    final text = [
      error.message,
      error.code,
      error.details?.toString(),
      error.hint,
      error.toString(),
    ].whereType<String>().join(' ').toLowerCase();
    return text.contains('store_already_published') ||
        text.contains('edit_token_mismatch_or_published') ||
        text.contains('duplicate key') ||
        text.contains('23505');
  }

  bool _isUuid(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value.trim());
  }

  /// Yayın öncesi taslak kaydeder (Next.js taslak önizlemesi için).
  /// Satır zaten yayındaysa RPC `STORE_ALREADY_PUBLISHED` ile reddeder —
  /// canlı vitrin taslak yazmayla asla ezilemez.
  Future<Result<StoreDraftResult>> saveDraft(
    StoreData data, {
    required String editToken,
  }) async {
    final trimmedToken = editToken.trim();
    if (trimmedToken.isEmpty) {
      return Result.failure(Failure('Önizleme için edit token gerekli.'));
    }

    final slug =
        data.slug.trim().isNotEmpty
            ? data.slug.trim()
            : payloadBuilder.generateSlug(data.name);
    if (slug.isEmpty) {
      return Result.failure(Failure('Önizleme için işletme adı gerekli.'));
    }

    try {
      final client = supabaseClient ?? Supabase.instance.client;
      await client.rpc(
        'save_store_draft_with_token',
        params: {
          'p_slug': slug,
          'p_edit_token': trimmedToken,
          'p_store': payloadBuilder.toStoreUpdateMap(data),
        },
      );
      return Result.success(
        StoreDraftResult(slug: slug, editToken: trimmedToken),
      );
    } on PostgrestException catch (error) {
      if (_isAlreadyPublished(error)) {
        return Result.failure(
          Failure('Bu vitrin zaten yayında; taslak önizleme kullanılamaz.'),
        );
      }
      return Result.failure(SupabaseErrorMapper.map(error));
    } catch (error) {
      return Result.failure(SupabaseErrorMapper.map(error));
    }
  }

  bool _isAlreadyPublished(PostgrestException error) {
    final searchableText =
        [
          error.message,
          error.code,
          error.details?.toString(),
          error.hint,
        ].whereType<String>().join(' ').toLowerCase();
    return searchableText.contains('store_already_published');
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

class _CatalogStageResult {
  const _CatalogStageResult({required this.slug, required this.storeId});

  final String slug;
  final String storeId;
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

class StoreDraftResult {
  final String slug;
  final String editToken;

  const StoreDraftResult({required this.slug, required this.editToken});
}

class StorePublishException implements Exception {
  final String message;

  const StorePublishException(this.message);

  @override
  String toString() => message;
}

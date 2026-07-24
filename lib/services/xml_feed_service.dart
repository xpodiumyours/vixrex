import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/models/store_product.dart';
import 'package:vixrex/services/bulk_product_upload_service.dart';

/// XML feed'lerinden ürün çekme ve senkronize etme servisi.
class XmlFeedService {
  final SupabaseClient _client;
  final BulkProductUploadService _uploadService;

  XmlFeedService({
    SupabaseClient? client,
    BulkProductUploadService? uploadService,
  })  : _client = client ?? Supabase.instance.client,
        _uploadService = uploadService ?? const BulkProductUploadService();

  /// Mağazanın tüm XML feed'lerini getirir.
  Future<List<XmlFeed>> getFeeds(String storeId) async {
    final response = await _client
        .from('xml_feeds')
        .select()
        .eq('store_id', storeId)
        .order('created_at');

    return (response as List).map((row) => XmlFeed.fromMap(row)).toList();
  }

  /// Yeni XML feed ekler.
  Future<XmlFeed> addFeed({
    required String storeId,
    required String feedName,
    required String feedUrl,
    String feedFormat = 'generic',
  }) async {
    final response = await _client.from('xml_feeds').insert({
      'store_id': storeId,
      'feed_name': feedName,
      'feed_url': feedUrl,
      'feed_format': feedFormat,
    }).select().single();

    return XmlFeed.fromMap(response);
  }

  /// XML feed'i günceller.
  Future<void> updateFeed({
    required String feedId,
    String? feedName,
    String? feedUrl,
    String? feedFormat,
    bool? isActive,
  }) async {
    final updates = <String, dynamic>{};
    if (feedName != null) updates['feed_name'] = feedName;
    if (feedUrl != null) updates['feed_url'] = feedUrl;
    if (feedFormat != null) updates['feed_format'] = feedFormat;
    if (isActive != null) updates['is_active'] = isActive;

    if (updates.isNotEmpty) {
      await _client.from('xml_feeds').update(updates).eq('id', feedId);
    }
  }

  /// XML feed'i siler.
  Future<void> deleteFeed(String feedId) async {
    await _client.from('xml_feeds').delete().eq('id', feedId);
  }

  /// XML feed'ini indirir ve parse eder.
  Future<XmlFeedParseResult> fetchAndParse(XmlFeed feed) async {
    try {
      // HTTP ile XML'i indir
      final response = await _client.functions.invoke(
        'fetch-xml-feed',
        body: {'url': feed.feedUrl},
      );

      if (response.status != 200) {
        return XmlFeedParseResult.error('XML indirilemedi: ${response.status}');
      }

      final data = response.data as Map<String, dynamic>;
      final xmlBytes = base64Decode(data['content'] as String);
      final fileName = '${feed.feedName}.xml';

      // XML'i parse et
      final parseResult = _uploadService.parse(xmlBytes, fileName: fileName);

      if (!parseResult.isSuccess) {
        return XmlFeedParseResult.error(parseResult.errorMessage!);
      }

      return XmlFeedParseResult.success(
        products: parseResult.products,
        errorCount: parseResult.errorCount,
      );
    } catch (e) {
      return XmlFeedParseResult.error('XML işlenirken hata: $e');
    }
  }

  /// XML feed'inden ürünleri mağazaya senkronize eder (upsert).
  Future<XmlSyncResult> syncFeed({
    required String storeId,
    required String editToken,
    required XmlFeed feed,
    required List<Product> products,
  }) async {
    try {
      // Ürünleri JSON'a çevir
      final productsJson = products.map((p) {
        return {
          'name': p.name,
          'slug': p.slug ?? '',
          'description': p.description,
          'price_text': p.price,
          'price_amount': double.tryParse(p.price),
          'image_urls': p.imageUrls,
          'category_name': p.category,
          'external_product_id': p.slug ?? p.id,
          'stock_quantity': null,
          'stock_status': p.stockStatus,
        };
      }).toList();

      // Chunk'lar halinde upsert (1000'erli)
      var totalInserted = 0;
      var totalUpdated = 0;
      var totalSkipped = 0;
      final allErrors = <Map<String, dynamic>>[];

      const chunkSize = 1000;
      for (var i = 0; i < productsJson.length; i += chunkSize) {
        final chunk = productsJson.sublist(
          i,
          (i + chunkSize).clamp(0, productsJson.length),
        );

        final result = await _client.rpc('upsert_products_from_xml', params: {
          'p_store_id': storeId,
          'p_edit_token': editToken,
          'p_products': chunk,
        });

        final data = result as Map<String, dynamic>;
        totalInserted += (data['inserted'] as int?) ?? 0;
        totalUpdated += (data['updated'] as int?) ?? 0;
        totalSkipped += (data['skipped'] as int?) ?? 0;

        final errors = data['errors'] as List?;
        if (errors != null) {
          allErrors.addAll(errors.cast<Map<String, dynamic>>());
        }
      }

      // Feed durumunu güncelle
      await _client.from('xml_feeds').update({
        'last_synced_at': DateTime.now().toIso8601String(),
        'last_sync_status': 'success',
        'last_sync_message': '$totalInserted yeni, $totalUpdated güncellendi, $totalSkipped atlandı',
        'total_products_synced': totalInserted + totalUpdated,
        'product_count': products.length,
      }).eq('id', feed.id);

      return XmlSyncResult(
        inserted: totalInserted,
        updated: totalUpdated,
        skipped: totalSkipped,
        errors: allErrors,
      );
    } catch (e) {
      // Hata durumunu güncelle
      await _client.from('xml_feeds').update({
        'last_sync_status': 'error',
        'last_sync_message': 'Senkronizasyon hatası: $e',
      }).eq('id', feed.id);

      return XmlSyncResult.error('Senkronizasyon hatası: $e');
    }
  }
}

/// XML feed modeli.
class XmlFeed {
  final String id;
  final String storeId;
  final String feedName;
  final String feedUrl;
  final String feedFormat;
  final bool isActive;
  final DateTime? lastSyncedAt;
  final String lastSyncStatus;
  final String? lastSyncMessage;
  final int totalProductsSynced;
  final int productCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const XmlFeed({
    required this.id,
    required this.storeId,
    required this.feedName,
    required this.feedUrl,
    required this.feedFormat,
    required this.isActive,
    this.lastSyncedAt,
    required this.lastSyncStatus,
    this.lastSyncMessage,
    required this.totalProductsSynced,
    required this.productCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory XmlFeed.fromMap(Map<String, dynamic> map) => XmlFeed(
        id: map['id'] as String,
        storeId: map['store_id'] as String,
        feedName: map['feed_name'] as String,
        feedUrl: map['feed_url'] as String,
        feedFormat: map['feed_format'] as String? ?? 'generic',
        isActive: map['is_active'] as bool? ?? true,
        lastSyncedAt: map['last_synced_at'] != null
            ? DateTime.parse(map['last_synced_at'] as String)
            : null,
        lastSyncStatus: map['last_sync_status'] as String? ?? 'pending',
        lastSyncMessage: map['last_sync_message'] as String?,
        totalProductsSynced: map['total_products_synced'] as int? ?? 0,
        productCount: map['product_count'] as int? ?? 0,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );
}

/// XML parse sonucu.
class XmlFeedParseResult {
  final bool isSuccess;
  final String? errorMessage;
  final List<Product> products;
  final int errorCount;

  const XmlFeedParseResult._({
    required this.isSuccess,
    this.errorMessage,
    this.products = const [],
    this.errorCount = 0,
  });

  factory XmlFeedParseResult.success({
    required List<Product> products,
    required int errorCount,
  }) =>
      XmlFeedParseResult._(
        isSuccess: true,
        products: products,
        errorCount: errorCount,
      );

  factory XmlFeedParseResult.error(String message) =>
      XmlFeedParseResult._(isSuccess: false, errorMessage: message);
}

/// XML senkronizasyon sonucu.
class XmlSyncResult {
  final bool isSuccess;
  final String? errorMessage;
  final int inserted;
  final int updated;
  final int skipped;
  final List<Map<String, dynamic>> errors;

  const XmlSyncResult._({
    required this.isSuccess,
    this.errorMessage,
    this.inserted = 0,
    this.updated = 0,
    this.skipped = 0,
    this.errors = const [],
  });

  factory XmlSyncResult({
    required int inserted,
    required int updated,
    required int skipped,
    required List<Map<String, dynamic>> errors,
  }) =>
      XmlSyncResult._(
        isSuccess: true,
        inserted: inserted,
        updated: updated,
        skipped: skipped,
        errors: errors,
      );

  factory XmlSyncResult.error(String message) =>
      XmlSyncResult._(isSuccess: false, errorMessage: message);
}

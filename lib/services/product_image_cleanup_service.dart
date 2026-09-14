import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductImageSnapshot {
  const ProductImageSnapshot({required this.storeId, required this.imageUrls});

  final String storeId;
  final List<String> imageUrls;
}

class ProductImageCleanupService {
  const ProductImageCleanupService({SupabaseClient? client}) : _client = client;

  static const String _bucketName = 'shelf-images';
  static const String _publicObjectMarker =
      '/storage/v1/object/public/shelf-images/';
  static const String _configuredSupabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
  );

  final SupabaseClient? _client;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  @visibleForTesting
  String? managedProductStoragePath(
    String imageUrl,
    String storeSlug, {
    String? supabaseUrl,
  }) {
    final expectedText = (supabaseUrl ?? _configuredSupabaseUrl).trim();
    final cleanSlug = _safeSlug(storeSlug);
    if (expectedText.isEmpty || cleanSlug.isEmpty) return null;

    try {
      final uri = Uri.parse(imageUrl);
      final expected = Uri.parse(expectedText);
      if (uri.origin != expected.origin) return null;
      final decodedPath = Uri.decodeComponent(uri.path);
      final markerIndex = decodedPath.indexOf(_publicObjectMarker);
      if (markerIndex < 0) return null;
      final objectPath = decodedPath.substring(
        markerIndex + _publicObjectMarker.length,
      );
      if (!objectPath.startsWith('$cleanSlug/products/')) return null;
      if (objectPath.contains('\\') ||
          objectPath.split('/').any((part) => part == '..')) {
        return null;
      }
      return objectPath;
    } catch (_) {
      return null;
    }
  }

  @visibleForTesting
  List<String> unreferencedManagedPaths({
    required List<String> candidateUrls,
    required List<String> referencedUrls,
    required String storeSlug,
    String? supabaseUrl,
  }) {
    final candidates = <String>{};
    for (final url in candidateUrls) {
      final path = managedProductStoragePath(
        url,
        storeSlug,
        supabaseUrl: supabaseUrl,
      );
      if (path != null) candidates.add(path);
    }

    final referenced = <String>{};
    for (final url in referencedUrls) {
      final path = managedProductStoragePath(
        url,
        storeSlug,
        supabaseUrl: supabaseUrl,
      );
      if (path != null) referenced.add(path);
    }
    return candidates.where((path) => !referenced.contains(path)).toList();
  }

  Future<ProductImageSnapshot?> snapshot(String productId) async {
    try {
      final row = await _supabase
          .from('products')
          .select('store_id,image_urls')
          .eq('id', productId)
          .maybeSingle();
      if (row == null) return null;
      final storeId = row['store_id']?.toString().trim() ?? '';
      if (storeId.isEmpty) return null;
      return ProductImageSnapshot(
        storeId: storeId,
        imageUrls: _stringList(row['image_urls']),
      );
    } catch (error) {
      if (kDebugMode) debugPrint('ProductImageCleanup snapshot: $error');
      return null;
    }
  }

  Future<int> cleanupUnreferenced({
    required String storeId,
    required List<String> candidateUrls,
  }) async {
    if (storeId.trim().isEmpty || candidateUrls.isEmpty) return 0;
    try {
      final store = await _supabase
          .from('stores')
          .select('slug')
          .eq('id', storeId)
          .maybeSingle();
      final storeSlug = store?['slug']?.toString().trim() ?? '';
      if (storeSlug.isEmpty) return 0;

      final rows = await _supabase
          .from('products')
          .select('image_urls')
          .eq('store_id', storeId);
      final referencedUrls = <String>[];
      for (final raw in rows as List) {
        if (raw is Map) referencedUrls.addAll(_stringList(raw['image_urls']));
      }

      final removable = unreferencedManagedPaths(
        candidateUrls: candidateUrls,
        referencedUrls: referencedUrls,
        storeSlug: storeSlug,
      );
      if (removable.isEmpty) return 0;

      await _supabase.storage.from(_bucketName).remove(removable);
      return removable.length;
    } catch (error) {
      if (kDebugMode) debugPrint('ProductImageCleanup cleanup: $error');
      return 0;
    }
  }

  String _safeSlug(String value) {
    return value.trim().replaceAll(RegExp(r'[^a-zA-Z0-9-]'), '');
  }

  List<String> _stringList(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();
  }
}

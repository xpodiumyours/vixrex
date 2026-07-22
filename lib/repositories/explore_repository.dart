import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/local_storage_keys.dart';
import 'package:vixrex/services/store_safe_select.dart';
import 'package:vixrex/utils/app_error_guard.dart';

class ExploreRepository {
  final SupabaseClient? _supabaseClient;
  final SharedPreferences _sharedPreferences;

  ExploreRepository({
    SupabaseClient? supabaseClient,
    required SharedPreferences sharedPreferences,
  }) : _supabaseClient = supabaseClient,
       _sharedPreferences = sharedPreferences;

  SupabaseClient get _client => _supabaseClient ?? Supabase.instance.client;

  Future<List<StoreData>> fetchPublishedStores() async {
    return AppErrorGuard.run<List<StoreData>>(
      label: 'ExploreRepository.fetchPublishedStores',
      fallback: const [],
      onError: (error, stack) => throw error,
      action: () async {
        final response = await _client
            .from('stores')
            .select(StoreSafeSelect.columns)
            .eq('is_published', true);
        final List<dynamic> rawList = response as List<dynamic>;
        final stores = rawList.map((json) => StoreData.fromJson(json)).toList();

        final storeIds = stores
            .map((s) => s.id?.trim() ?? '')
            .where((id) => id.isNotEmpty)
            .toList();

        if (storeIds.isNotEmpty) {
          final productsResponse = await _client
              .from('products')
              .select(
                'id, store_id, name, slug, description, price_text, price_amount, currency, stock_status, image_urls, is_visible, is_active, sort_order',
              )
              .filter('store_id', 'in', storeIds)
              .eq('is_active', true)
              .eq('is_visible', true)
              .order('sort_order');

          final List<dynamic> rawProducts = productsResponse as List<dynamic>;
          final Map<String, List<Product>> productMap = {};
          for (final item in rawProducts) {
            if (item is Map) {
              final map = Map<String, dynamic>.from(item);
              final storeId = (map['store_id'] ?? '').toString().trim();
              if (storeId.isNotEmpty) {
                final product = Product.fromJson(map);
                productMap.putIfAbsent(storeId, () => []).add(product);
              }
            }
          }
          for (final store in stores) {
            final id = store.id?.trim() ?? '';
            if (id.isNotEmpty && productMap.containsKey(id)) {
              store.products = productMap[id]!;
            }
          }
        }

        return stores;
      },
    );
  }

  Future<List<String>> loadFavoriteStoreNames() async {
    return AppErrorGuard.run<List<String>>(
      label: 'ExploreRepository.loadFavoriteStoreNames',
      fallback: const [],
      action: () async {
        return _sharedPreferences.getStringList('favorite_stores') ?? const [];
      },
    );
  }

  Future<void> saveFavoriteStoreNames(List<String> names) async {
    return AppErrorGuard.run<void>(
      label: 'ExploreRepository.saveFavoriteStoreNames',
      fallback: null,
      action: () async {
        await _sharedPreferences.setStringList('favorite_stores', names);
      },
    );
  }

  Future<String?> loadLastPublishedSlug() async {
    return AppErrorGuard.run<String?>(
      label: 'ExploreRepository.loadLastPublishedSlug',
      fallback: null,
      action: () async {
        return _sharedPreferences.getString(LocalStorageKeys.lastPublishedSlug);
      },
    );
  }
}

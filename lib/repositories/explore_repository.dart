import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/local_storage_keys.dart';
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
            .select()
            .eq('is_published', true);
        final List<dynamic> data = response as List<dynamic>;
        return data.map((json) => StoreData.fromJson(json)).toList();
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

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/services/local_storage_keys.dart';

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
    final response = await _client
        .from('stores')
        .select()
        .eq('is_published', true);
    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) => StoreData.fromJson(json)).toList();
  }

  Future<List<String>> loadFavoriteStoreNames() async {
    return _sharedPreferences.getStringList('favorite_stores') ?? [];
  }

  Future<void> saveFavoriteStoreNames(List<String> names) async {
    await _sharedPreferences.setStringList('favorite_stores', names);
  }

  Future<String?> loadLastPublishedSlug() async {
    return _sharedPreferences.getString(LocalStorageKeys.lastPublishedSlug);
  }
}

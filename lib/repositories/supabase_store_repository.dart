import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/repositories/store_repository.dart';
import 'package:vixrex/services/store_safe_select.dart';

/// Supabase ile StoreRepository implementasyonu.
class SupabaseStoreRepository implements StoreRepository {
  final SupabaseClient _client;

  SupabaseStoreRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  @override
  Future<StoreData?> getStoreForCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final response =
        await _client
            .from('stores')
            .select(StoreSafeSelect.columns)
            .eq('user_id', user.id)
            .maybeSingle();
    if (response == null) return null;
    return StoreData.fromJson(response);
  }

  @override
  Future<StoreData?> getStoreBySlug(String slug) async {
    if (slug.trim().isEmpty) return null;
    final response =
        await _client
            .from('stores')
            .select(StoreSafeSelect.columns)
            .eq('slug', slug.trim())
            .maybeSingle();
    if (response == null) return null;
    return StoreData.fromJson(response);
  }

  @override
  Future<void> insertStore(Map<String, dynamic> payload) async {
    final slug = (payload['slug'] ?? '').toString().trim();
    final editToken = (payload['edit_token'] ?? '').toString().trim();
    await _client.rpc(
      'create_store_with_token',
      params: {'p_slug': slug, 'p_edit_token': editToken, 'p_store': payload},
    );
  }

  @override
  Future<void> updateStoreWithToken({
    required String slug,
    required String editToken,
    required Map<String, dynamic> storeData,
  }) async {
    await _client.rpc(
      'update_store_with_token',
      params: {
        'p_slug': slug.trim(),
        'p_edit_token': editToken.trim(),
        'p_store': storeData,
      },
    );
  }

  @override
  Future<void> withdrawPublicationConsent({
    required String slug,
    required String editToken,
  }) async {
    await _client.rpc(
      'withdraw_store_publication_consent',
      params: {'p_slug': slug.trim(), 'p_edit_token': editToken.trim()},
    );
  }

  @override
  Future<List<StoreData>> fetchPublishedStores() async {
    final response = await _client
        .from('stores')
        .select(StoreSafeSelect.columns)
        .eq('is_published', true);
    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) => StoreData.fromJson(json)).toList();
  }
}

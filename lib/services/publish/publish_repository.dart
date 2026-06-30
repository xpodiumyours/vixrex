import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/services/store_publish_service.dart';

class PublishRepository {
  const PublishRepository();

  Future<String?> findStoreByToken(
    SupabaseClient client,
    String editToken,
  ) async {
    final existingByToken = await client
        .from('stores')
        .select('slug')
        .eq('edit_token', editToken)
        .maybeSingle();

    if (existingByToken == null) {
      return null;
    }

    return (existingByToken['slug'] as String?)?.trim() ?? '';
  }

  Future<bool> findStoreBySlug(SupabaseClient client, String slug) async {
    final existingStore = await client
        .from('stores')
        .select('slug')
        .eq('slug', slug)
        .maybeSingle();

    return existingStore != null;
  }

  Future<void> insertStore(
    SupabaseClient client,
    Map<String, dynamic> payload,
  ) async {
    await client.from('stores').insert(payload);
  }

  Future<void> updateStoreWithToken(
    SupabaseClient client,
    StoreData data,
    String slug,
    String editToken,
    StorePublishPayloadBuilder payloadBuilder,
  ) async {
    await client.rpc(
      'update_store_with_token',
      params: {
        'p_slug': slug,
        'p_edit_token': editToken,
        'p_store': payloadBuilder.toStoreUpdateMap(data),
      },
    );
  }

  Future<void> withdrawConsent(
    SupabaseClient client,
    String slug,
    String editToken,
  ) async {
    await client.rpc(
      'withdraw_store_publication_consent',
      params: {'p_slug': slug.trim(), 'p_edit_token': editToken.trim()},
    );
  }
}

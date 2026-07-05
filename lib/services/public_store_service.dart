import 'package:supabase_flutter/supabase_flutter.dart';

/// Herkese açık vitrin görüntüleme için Supabase okuma işlemlerini merkezileştirir.
class PublicStoreService {
  final SupabaseClient? _client;

  const PublicStoreService({SupabaseClient? client}) : _client = client;

  SupabaseClient get _resolveClient => _client ?? Supabase.instance.client;

  /// Slug ile yayınlanmış bir store'un tüm alanlarını getirir.
  Future<Map<String, dynamic>?> fetchPublishedStoreBySlug(String slug) async {
    return await _resolveClient
        .from('stores')
        .select(
          'slug,name,business_type,description,corporate_bio,whatsapp,instagram,website,address,latitude,longitude,location_accuracy_meters,location_consent_at,location_source,theme,status,marketplace_links,references_link,shelf_image_url,gallery_items,is_published,is_store,products,offerings,kategori,working_hours,booking_settings(is_enabled,capacity,working_hours,lunch_break)',
        )
        .eq('slug', slug)
        .eq('is_published', true)
        .maybeSingle();
  }

  /// Slug ile yayınlanmış bir store'un ürün bilgilerini getirir.
  Future<Map<String, dynamic>?> fetchPublishedStoreProducts(String slug) async {
    return await _resolveClient
        .from('stores')
        .select('slug,name,whatsapp,shelf_image_url,logo_url,products,is_published')
        .eq('slug', slug)
        .eq('is_published', true)
        .maybeSingle();
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/core/result.dart';
import 'package:vixrex/core/supabase_error_mapper.dart';

/// Herkese açık vitrin görüntüleme için Supabase okuma işlemlerini merkezileştirir.
class PublicStoreService {
  final SupabaseClient? _client;

  const PublicStoreService({SupabaseClient? client}) : _client = client;

  SupabaseClient get _resolveClient => _client ?? Supabase.instance.client;

  /// Slug ile yayınlanmış bir store'un tüm alanlarını getirir.
  Future<Result<Map<String, dynamic>?>> fetchPublishedStoreBySlug(
    String slug,
  ) async {
    try {
      final res =
          await _resolveClient
              .from('stores')
              .select(
                'id,slug,name,business_type,description,corporate_bio,whatsapp,instagram,website,address,latitude,longitude,location_accuracy_meters,location_consent_at,location_source,theme,status,marketplace_links,references_link,shelf_image_url,logo_url,google_business_link,gallery_items,is_published,is_store,products,product_storage_version,offerings,kategori,working_hours,booking_settings(is_enabled,capacity,working_hours,lunch_break)',
              )
              .eq('slug', slug)
              .eq('is_published', true)
              .maybeSingle();
      return Result.success(res);
    } catch (e, s) {
      return Result.failure(SupabaseErrorMapper.map(e, s));
    }
  }

  /// Slug ile yayınlanmış bir store'un ürün bilgilerini getirir.
  Future<Result<Map<String, dynamic>?>> fetchPublishedStoreProducts(
    String slug,
  ) async {
    try {
      final res =
          await _resolveClient
              .from('stores')
              .select(
                'id,slug,name,whatsapp,shelf_image_url,logo_url,products,product_storage_version,is_published',
              )
              .eq('slug', slug)
              .eq('is_published', true)
              .maybeSingle();
      return Result.success(res);
    } catch (e, s) {
      return Result.failure(SupabaseErrorMapper.map(e, s));
    }
  }
}

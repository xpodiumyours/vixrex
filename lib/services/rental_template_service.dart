import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/models/rental_trial_result.dart';

/// Kiralık vitrin denemesi yalnızca sunucudaki atomik RPC ile başlatılır.
/// İstemci ücretli hak veya abonelik durumu yazamaz.
class RentalTemplateService {
  final SupabaseClient _client;

  RentalTemplateService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  Future<RentalTrialResult> startTrialForStore(String storeId) async {
    final normalizedStoreId = storeId.trim();
    if (normalizedStoreId.isEmpty) {
      throw const FormatException('Kiralık vitrin kimliği bulunamadı.');
    }

    final session = _client.auth.currentSession;
    if (session == null) {
      throw StateError(
        '14 günlük denemeyi başlatmak için önce giriş yapmalısınız.',
      );
    }

    final template = await _client
        .from('rental_templates')
        .select('id')
        .eq('store_id', normalizedStoreId)
        .eq('is_active', true)
        .maybeSingle();

    if (template == null || template['id'] == null) {
      throw StateError('Bu kiralık vitrin şu anda kullanıma açık değil.');
    }

    final result = await _client.rpc(
      'start_rental_trial',
      params: {'p_template_id': template['id']},
    );

    if (result is! List || result.isEmpty || result.first is! Map) {
      throw const FormatException('Kiralık vitrin oluşturma yanıtı geçersiz.');
    }

    return RentalTrialResult.fromJson(
      Map<String, dynamic>.from(result.first as Map),
    );
  }
}

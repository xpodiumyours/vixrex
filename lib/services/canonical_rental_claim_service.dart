import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/repositories/vitrin_sahiplik_repository.dart';

/// Kanonik kiralama — PR6-C25.
///
/// Tek RPC zinciri: klon + sahiplik + çalışma taslağı + akış durumu
/// ya hep birlikte ya hiç. Flutter ve Next.js aynı yolu çağırır.
/// Flutter dış tarayıcıyı açmadan önce kendi oturumuyla tamamlar,
/// sonra kısa ömürlü oturumla Next.js çalışma alanını açar.
class CanonicalRentalClaimService {
  const CanonicalRentalClaimService({SupabaseClient? client})
    : _client = client;
  final SupabaseClient? _client;

  VitrinSahiplikRepository get _depo =>
      VitrinSahiplikRepository(client: _client);
  SupabaseClient? get _supabase => _depo.istemci;

  Future<Map<String, dynamic>?> claim(
    String demoSlug, {
    String akisTuru = 'kiralama',
  }) async {
    final c = _supabase;
    if (c == null) return null;
    try {
      final res = await _depo.rentDemoForAccount(c, demoSlug);
      if (res is! Map || res['ok'] != true) return null;
      final slug = (res['slug'] ?? '').toString();
      if (slug.isEmpty) return Map<String, dynamic>.from(res);
      // Çalışma taslağı hazırla — kanonik zincir (akış/konuşma best-effort Dart'ta).
      try {
        await c.rpc(
          'get_or_create_working_draft',
          params: {'p_slug': slug, 'p_edit_token': res['edit_token']},
        );
      } catch (_) {}
      return Map<String, dynamic>.from(res);
    } catch (_) {
      return null;
    }
  }
}

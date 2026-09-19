import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/models/owner_bootstrap_state.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/repositories/auth_repository.dart';

/// Supabase Auth ile AuthRepository implementasyonu.
class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client;

  SupabaseAuthRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  @override
  User? get currentUser {
    try {
      return _client.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  @override
  bool get hasActiveSession => currentUser != null;

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Future<void> deleteAccount() async {
    final user = currentUser;
    if (user == null) {
      throw StateError('Hesap silmek için aktif oturum bulunamadı.');
    }
    await _client.rpc('delete_user_account');
    await signOut();
  }

  @override
  Future<StoreData?> getStoreForCurrentUser() async {
    final user = currentUser;
    if (user == null) return null;
    // 2026-08-26: doğrudan `.eq('user_id', ...)` filtresi canlıda 42501 ile
    // düşüyordu — V-09 o kolonun SELECT'ini authenticated'ten revoke etti,
    // PostgreSQL WHERE'de geçen kolon için de yetki arar. Sahiplik sorgusu
    // artık SECURITY DEFINER olan bootstrap_owner_state üzerinden.
    final response = await _client.rpc('bootstrap_owner_state');
    if (response is! Map) return null;
    return OwnerBootstrapState.fromJson(
      Map<String, dynamic>.from(response),
    ).tercihEdilenVeri;
  }
}

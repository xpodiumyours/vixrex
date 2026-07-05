import 'package:supabase_flutter/supabase_flutter.dart';
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
  Future<AuthResponse> signUp(String email, String password) async {
    return await _client.auth.signUp(email: email, password: password);
  }

  @override
  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

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
    final response = await _client
        .from('stores')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();
    if (response == null) return null;
    return StoreData.fromJson(response);
  }
}

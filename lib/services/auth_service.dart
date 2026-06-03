import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitrinx/models/store_data.dart';

class AuthService {
  const AuthService();

  /// Returns the currently authenticated user session.
  User? get currentUser => Supabase.instance.client.auth.currentUser;

  /// Returns whether a user session is active.
  bool get hasActiveSession => currentUser != null;

  /// Sign up with email and password.
  Future<AuthResponse> signUp(String email, String password) async {
    return await Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
    );
  }

  /// Sign in with email and password.
  Future<AuthResponse> signIn(String email, String password) async {
    return await Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign out.
  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
  }

  /// Fetches the store details for the currently logged-in user.
  Future<StoreData?> getStoreForCurrentUser() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final response = await Supabase.instance.client
          .from('stores')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (response != null) {
        return StoreData.fromJson(response);
      }
    } catch (e) {
      // Ignore or log error
    }
    return null;
  }

  /// Links an anonymously created store (identifiable by edit token) to the current user.
  Future<bool> linkAnonymousStore(String editToken) async {
    try {
      final result = await Supabase.instance.client.rpc(
        'link_store_to_user',
        params: {'p_edit_token': editToken},
      );
      return result as bool? ?? false;
    } catch (e) {
      return false;
    }
  }
}


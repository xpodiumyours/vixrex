import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/store_local_storage_service.dart';

/// DebugPrint için foundation.dart import'u
import 'package:flutter/foundation.dart' show debugPrint;

class AuthService {
  const AuthService();

  static bool isDeleteConfirmationValid(String value) {
    return value.trim() == 'SİL';
  }

  /// Returns the currently authenticated user session.
  User? get currentUser {
    try {
      return Supabase.instance.client.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

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
    await const StoreLocalStorageService().clearStoreData();
    await const StoreLocalStorageService().clearVitrinData();
  }

  /// Deletes the currently authenticated user's account and all their data.
  Future<void> deleteAccount() async {
    final user = currentUser;
    if (user == null) {
      throw StateError('Hesap silmek için aktif oturum bulunamadı.');
    }

    // Call the database RPC to delete the user account
    await Supabase.instance.client.rpc('delete_user_account');
    // Sign out to clear local session
    await signOut();
  }

  /// Fetches the store details for the currently logged-in user.
  Future<StoreData?> getStoreForCurrentUser() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final response =
          await Supabase.instance.client
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

  /// Fetches the edit token for the currently logged-in user's store.
  Future<String?> getEditTokenForCurrentUser() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final response =
          await Supabase.instance.client
              .from('stores')
              .select('edit_token')
              .eq('user_id', user.id)
              .maybeSingle();

      if (response != null && response['edit_token'] != null) {
        return response['edit_token'] as String;
      }
    } catch (e) {
      debugPrint('getEditTokenForCurrentUser error: $e');
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

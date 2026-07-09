import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/core/result.dart';
import 'package:vixrex/core/supabase_error_mapper.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/store_local_storage_service.dart';
import 'package:vixrex/utils/failure.dart';

class AuthService {
  const AuthService();

  static bool isDeleteConfirmationValid(String value) {
    return value.trim() == 'SİL';
  }

  /// Returns the currently authenticated user session.
  User? get currentUser {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null && session.isExpired) {
        // Oturum süresi dolmuşsa yenilemeyi dene (asenkron olmadığı için burada sadece null döner,
        // ancak bir sonraki asenkron işlemde Supabase SDK otomatik yenileyecektir)
        return null;
      }
      return session?.user;
    } catch (_) {
      return null;
    }
  }

  /// Returns whether a user session is active.
  bool get hasActiveSession => currentUser != null;

  /// Sign up with email and password.
  Future<Result<AuthResponse>> signUp(String email, String password) async {
    try {
      final res = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );
      return Result.success(res);
    } catch (e, s) {
      return Result.failure(SupabaseErrorMapper.map(e, s));
    }
  }

  /// Sign in with email and password.
  Future<Result<AuthResponse>> signIn(String email, String password) async {
    try {
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return Result.success(res);
    } catch (e, s) {
      return Result.failure(SupabaseErrorMapper.map(e, s));
    }
  }

  /// Sign out.
  Future<Result<void>> signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      // Sadece auth verilerini temizle, vitrin verilerini koru
      await const StoreLocalStorageService().clearAuthData();
      return const Result.success(null);
    } catch (e, s) {
      return Result.failure(SupabaseErrorMapper.map(e, s));
    }
  }

  /// Deletes the currently authenticated user's account and all their data.
  Future<Result<void>> deleteAccount() async {
    final user = currentUser;
    if (user == null) {
      return Result.failure(
        Failure('Hesap silmek için aktif oturum bulunamadı.'),
      );
    }

    try {
      await Supabase.instance.client.rpc('delete_user_account');
      await signOut();
      return const Result.success(null);
    } catch (e, s) {
      return Result.failure(SupabaseErrorMapper.map(e, s));
    }
  }

  /// Fetches the store details for the currently logged-in user.
  Future<Result<StoreData?>> getStoreForCurrentUser() async {
    final user = currentUser;
    if (user == null) return const Result.success(null);

    try {
      final response =
          await Supabase.instance.client
              .from('stores')
              .select()
              .eq('user_id', user.id)
              .maybeSingle();

      if (response != null) {
        return Result.success(StoreData.fromJson(response));
      }
      return const Result.success(null);
    } catch (e, s) {
      return Result.failure(SupabaseErrorMapper.map(e, s));
    }
  }

  /// Fetches the edit token for the currently logged-in user's store.
  Future<Result<String?>> getEditTokenForCurrentUser() async {
    final user = currentUser;
    if (user == null) return const Result.success(null);

    try {
      final response =
          await Supabase.instance.client
              .from('stores')
              .select('edit_token')
              .eq('user_id', user.id)
              .maybeSingle();

      if (response != null && response['edit_token'] != null) {
        return Result.success(response['edit_token'] as String);
      }
      return const Result.success(null);
    } catch (e, s) {
      return Result.failure(SupabaseErrorMapper.map(e, s));
    }
  }

  /// Links an anonymously created store (identifiable by edit token) to the current user.
  Future<Result<bool>> linkAnonymousStore(String editToken) async {
    try {
      final result = await Supabase.instance.client.rpc(
        'link_store_to_user',
        params: {'p_edit_token': editToken},
      );
      return Result.success(result as bool? ?? false);
    } catch (e, s) {
      return Result.failure(SupabaseErrorMapper.map(e, s));
    }
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/config/legal_config.dart';
import 'package:vixrex/core/result.dart';
import 'package:vixrex/core/supabase_error_mapper.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/push_notification_service.dart';
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
      final userId = res.user?.id;
      if (userId != null) {
        await PushNotificationService.instance.loginUser(userId);
      }
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
      final userId = res.user?.id;
      if (userId != null) {
        await PushNotificationService.instance.loginUser(userId);
      }
      return Result.success(res);
    } catch (e, s) {
      return Result.failure(SupabaseErrorMapper.map(e, s));
    }
  }

  /// Sign out.
  Future<Result<void>> signOut() async {
    try {
      await PushNotificationService.instance.logoutUser();
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

  /// Sends a password-reset email via Supabase Auth.
  Future<Result<void>> resetPassword(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) {
      return Result.failure(Failure('E-posta adresi zorunludur'));
    }

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        trimmed,
        redirectTo: LegalConfig.publicSiteUrl,
      );
      return const Result.success(null);
    } catch (e, s) {
      return Result.failure(SupabaseErrorMapper.map(e, s));
    }
  }

  /// Exports the signed-in user's portable data as JSON-ready map (KVKK erişim).
  /// Sensitive secrets (edit_token, Instagram tokens) are stripped.
  Future<Result<Map<String, dynamic>>> exportMyData() async {
    final user = currentUser;
    if (user == null) {
      return Result.failure(
        Failure('Veri dışa aktarmak için giriş yapmalısınız.'),
      );
    }

    try {
      final client = Supabase.instance.client;
      final storesRaw = await client
          .from('stores')
          .select()
          .eq('user_id', user.id);

      final stores = (storesRaw as List)
          .map((row) => _sanitizeStoreExport(Map<String, dynamic>.from(row as Map)))
          .toList();

      final slugs = stores
          .map((s) => s['slug']?.toString().trim() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();

      List<dynamic> appointments = [];
      List<dynamic> bookingSettings = [];
      List<dynamic> articles = [];

      if (slugs.isNotEmpty) {
        appointments = await client
            .from('appointments')
            .select()
            .inFilter('store_slug', slugs);
        bookingSettings = await client
            .from('booking_settings')
            .select()
            .inFilter('store_slug', slugs);
        articles = await client
            .from('store_articles')
            .select()
            .inFilter('store_slug', slugs);
      }

      return Result.success({
        'exported_at': DateTime.now().toUtc().toIso8601String(),
        'app': LegalConfig.appName,
        'user': {
          'id': user.id,
          'email': user.email,
        },
        'stores': stores,
        'appointments': appointments,
        'booking_settings': bookingSettings,
        'store_articles': articles,
      });
    } catch (e, s) {
      return Result.failure(SupabaseErrorMapper.map(e, s));
    }
  }

  static Map<String, dynamic> _sanitizeStoreExport(Map<String, dynamic> row) {
    final copy = Map<String, dynamic>.from(row);
    copy.remove('edit_token');
    copy.remove('instagram_access_token');
    copy.remove('instagram_token');
    return copy;
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

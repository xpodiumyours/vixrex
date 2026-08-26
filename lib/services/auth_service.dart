import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/config/legal_config.dart';
import 'package:vixrex/core/result.dart';
import 'package:vixrex/core/supabase_error_mapper.dart';
import 'package:vixrex/models/owner_bootstrap_state.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/owner_bootstrap_service.dart';
import 'package:vixrex/services/push_notification_service.dart';
import 'package:vixrex/services/secure_token_storage.dart';
import 'package:vixrex/services/store_local_storage_service.dart';
import 'package:vixrex/services/store_safe_select.dart';
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

  /// Sign in with Google using native ID token authentication.
  /// Anonim hesabı Google'a bağlar. AYNI hesap kalır, veri taşınmaz.
  ///
  /// NEDEN VAR (docs/kok-neden-arastirmasi.md — kimlik kökü):
  /// Uygulama açılışta anonim oturum kuruyor; vitrin ilk andan sahipli
  /// oluyor. Ama anonim hesap CİHAZA bağlıdır — esnaf telefonunu
  /// değiştirse ya da tarayıcı verisini silse vitrinine bir daha
  /// erişemez. Bu adım o riski kapatır.
  ///
  /// signInWithGoogle'dan farkı: o YENİ bir hesaba geçirir ve anonim
  /// hesapta duran vitrin sahipsiz kalır. Bu ise mevcut hesabın üstüne
  /// Google kimliğini ekler — `user_id` değişmez, vitrin sahibini korur.
  Future<Result<void>> hesabiGoogleaBagla() async {
    try {
      final auth = Supabase.instance.client.auth;
      final kullanici = auth.currentUser;

      if (kullanici == null) {
        return Result.failure(Failure('Önce oturum kurulmalı.'));
      }
      if (!kullanici.isAnonymous) {
        // Zaten kalıcı hesabı var; yapacak bir şey yok.
        return Result.success(null);
      }

      const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
      const iosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

      final googleSignIn =
          kIsWeb
              ? GoogleSignIn(clientId: webClientId)
              : GoogleSignIn(
                clientId: iosClientId.isNotEmpty ? iosClientId : null,
                serverClientId: webClientId.isNotEmpty ? webClientId : null,
              );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return Result.failure(Failure('Google ile bağlama iptal edildi.'));
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        return Result.failure(Failure('Google kimliği alınamadı.'));
      }

      await auth.linkIdentityWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: googleAuth.accessToken,
      );

      final userId = auth.currentUser?.id;
      if (userId != null) {
        await PushNotificationService.instance.loginUser(userId);
      }

      // Kimlik bağlandı: kullanıcı artık kalıcı hesap. Cihazdaki vitrin bu
      // ana kadar sahipsizdi (anonim oturum bilerek sahiplenemez, bkz.
      // claim_store_for_user) — sahiplenmenin doğru anı tam burası.
      await claimDeviceStore();
      return Result.success(null);
    } catch (e, s) {
      return Result.failure(SupabaseErrorMapper.map(e, s));
    }
  }

  Future<Result<AuthResponse>> signInWithGoogle() async {
    try {
      const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
      const iosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

      if (kIsWeb) {
        try {
          final googleSignIn = GoogleSignIn(clientId: webClientId);
          final googleUser = await googleSignIn.signIn();
          if (googleUser == null) {
            return Result.failure(Failure('Google ile giriş iptal edildi.'));
          }
          final googleAuth = await googleUser.authentication;
          final idToken = googleAuth.idToken;
          if (idToken != null) {
            final res = await Supabase.instance.client.auth.signInWithIdToken(
              provider: OAuthProvider.google,
              idToken: idToken,
              accessToken: googleAuth.accessToken,
            );
            final userId = res.user?.id;
            if (userId != null) {
              await PushNotificationService.instance.loginUser(userId);
            }
            return Result.success(res);
          }
        } catch (_) {
          // Web fallback: Harici OAuth yönlendirmesi
        }
        await Supabase.instance.client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: kIsWeb ? Uri.base.origin : null,
        );
        return Result.failure(Failure('Google ile giriş yönlendiriliyor...'));
      }

      final googleSignIn = GoogleSignIn(
        clientId: iosClientId.isNotEmpty ? iosClientId : null,
        serverClientId: webClientId.isNotEmpty ? webClientId : null,
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return Result.failure(Failure('Google ile giriş iptal edildi.'));
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        return Result.failure(Failure('Google token alınamadı.'));
      }

      final res = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: googleAuth.accessToken,
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
      // V-14 (attack-vectors.md, 2026-08-18): eskiden köke (publicSiteUrl)
      // yönlendiriyordu — orada işleyen bir sayfa yoktu, link ölü uçtu.
      // Artık şifre belirleme formunu gösteren gerçek sayfaya gidiyor
      // (public_web/src/app/sifre-sifirla/page.tsx).
      await Supabase.instance.client.auth.resetPasswordForEmail(
        trimmed,
        redirectTo: '${LegalConfig.publicSiteUrl}/sifre-sifirla',
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
          .select(StoreSafeSelect.columns)
          .eq('user_id', user.id);

      final stores =
          (storesRaw as List)
              .map(
                (row) =>
                    _sanitizeStoreExport(Map<String, dynamic>.from(row as Map)),
              )
              .toList();

      final slugs =
          stores
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
        'user': {'id': user.id, 'email': user.email},
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

  /// Giriş yapmış kullanıcının sunucudaki tam sahip durumu: vitrin verisi,
  /// kendi edit token'ı ve varsa web'de bırakılmış çalışma taslağı.
  ///
  /// 2026-08-26: burada eskiden `from('stores').eq('user_id', ...)` vardı.
  /// V-09 (20260818050000) `stores.user_id`'nin SELECT'ini authenticated'ten
  /// revoke etti; PostgreSQL WHERE'de geçen kolon için de SELECT yetkisi
  /// arar — sorgunun TAMAMI 42501 ile düşüyordu, yani bu çağrı canlıda hiç
  /// çalışmıyordu (ölçüldü: user_id dolu satır sayısı 0). 20260820210000
  /// aynı hatayı Keşfet ve StorePublishedInfoLookupService için düzeltmişti,
  /// bu çağrı atlanmış. Artık `bootstrap_owner_state` RPC'si kullanılıyor —
  /// SECURITY DEFINER, user_id'yi asla client'a döndürmez.
  Future<Result<OwnerBootstrapState>> getOwnerState() async {
    return const OwnerBootstrapService().getir();
  }

  /// Geriye dönük ince kabuk — çağıranlar kademeli olarak [getOwnerState]'e
  /// geçiyor. Yalnız vitrin verisini döner, token ve taslağı düşürür.
  Future<Result<StoreData?>> getStoreForCurrentUser() async {
    final result = await getOwnerState();
    return result.when(
      success: (state) => Result<StoreData?>.success(state.tercihEdilenVeri),
      failure: (failure) => Result<StoreData?>.failure(failure),
    );
  }

  /// Cihazda duran edit token'ı bulup vitrini hesaba bağlar. Cihazda hiç
  /// token yoksa (bağlanacak vitrin yok) `null` döner.
  ///
  /// Yayın akışı `last_published_edit_token`'ı yazar ve vitrin/store
  /// anahtarlarına da aynalar; üçü de aday olarak denenir.
  Future<StoreClaimResult?> claimDeviceStore() async {
    final adaylar = <String>[
      await SecureTokenStorage.loadLastPublishedEditToken() ?? '',
      await SecureTokenStorage.loadVitrinEditToken() ?? '',
      await SecureTokenStorage.loadStoreEditToken() ?? '',
    ];
    final token = adaylar
        .map((t) => t.trim())
        .firstWhere((t) => t.isNotEmpty, orElse: () => '');
    if (token.isEmpty) return null;

    final sonuc = await claimStore(token);
    return sonuc.when(success: (value) => value, failure: (_) => null);
  }

  /// Cihazda duran edit token'la sahipsiz bir vitrini kalıcı hesaba bağlar.
  ///
  /// Tek-vitrin kuralı, anonim oturum yasağı ve token süresini kalıcıya
  /// çekme işi sunucudaki `claim_store_for_user` sözleşmesinde — istemci
  /// yalnız sonucu yorumlar.
  Future<Result<StoreClaimResult>> claimStore(String editToken) async {
    try {
      final result = await Supabase.instance.client.rpc(
        'claim_store_for_user',
        params: {'p_edit_token': editToken},
      );
      if (result is! Map) {
        return const Result.success(
          StoreClaimResult.basarisiz('INVALID_RESPONSE'),
        );
      }
      return Result.success(
        StoreClaimResult.fromJson(Map<String, dynamic>.from(result)),
      );
    } catch (e, s) {
      return Result.failure(SupabaseErrorMapper.map(e, s));
    }
  }
}

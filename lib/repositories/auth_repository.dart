import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitrinx/models/store_data.dart';

/// Kimlik doğrulama ve kullanıcı yönetimi için repository arayüzü.
///
/// UI katmanı ve business logic bu arayüze bağımlı olmalı,
/// concrete implementasyon değiştirilebilir olmalı.
abstract class AuthRepository {
  /// Mevcut oturumdaki kullanıcıyı döndürür.
  User? get currentUser;

  /// Aktif oturum olup olmadığını kontrol eder.
  bool get hasActiveSession;

  /// Email ve şifre ile kayıt olur.
  Future<AuthResponse> signUp(String email, String password);

  /// Email ve şifre ile giriş yapar.
  Future<AuthResponse> signIn(String email, String password);

  /// Çıkış yapar.
  Future<void> signOut();

  /// Mevcut kullanıcının hesabını ve tüm verilerini siler.
  Future<void> deleteAccount();

  /// Giriş yapmış kullanıcının vitrin verisini getirir.
  Future<StoreData?> getStoreForCurrentUser();
}

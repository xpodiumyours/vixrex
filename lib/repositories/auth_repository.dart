import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/models/store_data.dart';

/// Kimlik doğrulama ve kullanıcı yönetimi için repository arayüzü.
///
/// UI katmanı ve business logic bu arayüze bağımlı olmalı,
/// concrete implementasyon değiştirilebilir olmalı.
abstract class AuthRepository {
  /// Mevcut oturumdaki kullanıcıyı döndürür.
  User? get currentUser;

  /// Aktif oturum olup olmadığını kontrol eder.
  bool get hasActiveSession;

  /// Çıkış yapar.
  Future<void> signOut();

  /// Mevcut kullanıcının hesabını ve tüm verilerini siler.
  Future<void> deleteAccount();

  /// Giriş yapmış kullanıcının vitrin verisini getirir.
  Future<StoreData?> getStoreForCurrentUser();
}

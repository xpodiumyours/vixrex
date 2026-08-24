import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage for sensitive tokens (edit_token, etc.)
///
/// Uses flutter_secure_storage which provides encrypted storage:
/// - iOS: Keychain
/// - Android: Keystore/EncryptedSharedPreferences
/// - Web: Encrypted localStorage (via Web Crypto API)
class SecureTokenStorage {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const _storeEditTokenKey = 'vixrex_store_edit_token';
  static const _vitrinEditTokenKey = 'vixrex_vitrin_edit_token';
  static const _lastPublishedEditTokenKey = 'vixrex_last_published_edit_token';

  /// Save store edit token securely
  static Future<void> saveStoreEditToken(String token) async {
    await _storage.write(key: _storeEditTokenKey, value: token);
    if (kDebugMode) debugPrint('[SecureTokenStorage] storeEditToken saved');
  }

  /// Load store edit token securely
  static Future<String?> loadStoreEditToken() async {
    final value = await _storage.read(key: _storeEditTokenKey);
    if (kDebugMode && value != null)
      debugPrint('[SecureTokenStorage] storeEditToken loaded');
    return value;
  }

  /// Save vitrin edit token securely
  static Future<void> saveVitrinEditToken(String token) async {
    await _storage.write(key: _vitrinEditTokenKey, value: token);
    if (kDebugMode) debugPrint('[SecureTokenStorage] vitrinEditToken saved');
  }

  /// Load vitrin edit token securely
  static Future<String?> loadVitrinEditToken() async {
    final value = await _storage.read(key: _vitrinEditTokenKey);
    if (kDebugMode && value != null)
      debugPrint('[SecureTokenStorage] vitrinEditToken loaded');
    return value;
  }

  /// Save last published edit token securely
  static Future<void> saveLastPublishedEditToken(String token) async {
    await _storage.write(key: _lastPublishedEditTokenKey, value: token);
    if (kDebugMode)
      debugPrint('[SecureTokenStorage] lastPublishedEditToken saved');
  }

  /// Load last published edit token securely
  static Future<String?> loadLastPublishedEditToken() async {
    final value = await _storage.read(key: _lastPublishedEditTokenKey);
    if (kDebugMode && value != null)
      debugPrint('[SecureTokenStorage] lastPublishedEditToken loaded');
    return value;
  }

  /// Delete all sensitive tokens
  static Future<void> clearAll() async {
    await _storage.delete(key: _storeEditTokenKey);
    await _storage.delete(key: _vitrinEditTokenKey);
    await _storage.delete(key: _lastPublishedEditTokenKey);
    if (kDebugMode) debugPrint('[SecureTokenStorage] all tokens cleared');
  }

  /// Delete auth-related tokens only (keep vitrin data)
  static Future<void> clearAuthTokens() async {
    await _storage.delete(key: _storeEditTokenKey);
    await _storage.delete(key: _vitrinEditTokenKey);
    if (kDebugMode) debugPrint('[SecureTokenStorage] auth tokens cleared');
  }
}

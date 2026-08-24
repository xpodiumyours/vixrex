import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure key-value storage using flutter_secure_storage.
///
/// Provides encrypted storage for sensitive data:
/// - iOS: Keychain
/// - Android: Keystore/EncryptedSharedPreferences
/// - Web: Encrypted localStorage (via Web Crypto API)
/// - Linux/macOS/Windows: libsecret/Keychain/DPAPI
class SecureKVStorage {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // Sensitive key prefixes
  static const _prefix = 'vixrex_secure_';

  /// Save a string value securely
  static Future<void> setString(String key, String value) async {
    await _storage.write(key: '$_prefix$key', value: value);
    if (kDebugMode) debugPrint('[SecureKVStorage] set: $key');
  }

  /// Load a string value securely
  static Future<String?> getString(String key) async {
    final value = await _storage.read(key: '$_prefix$key');
    if (kDebugMode && value != null) debugPrint('[SecureKVStorage] get: $key');
    return value;
  }

  /// Save a bool value securely
  static Future<void> setBool(String key, bool value) async {
    await _storage.write(key: '$_prefix$key', value: value.toString());
    if (kDebugMode) debugPrint('[SecureKVStorage] setBool: $key = $value');
  }

  /// Load a bool value securely
  static Future<bool?> getBool(String key) async {
    final value = await _storage.read(key: '$_prefix$key');
    if (kDebugMode && value != null)
      debugPrint('[SecureKVStorage] getBool: $key');
    return value == 'true';
  }

  /// Save a string list securely
  static Future<void> setStringList(String key, List<String> values) async {
    await _storage.write(key: '$_prefix$key', value: values.join('\u{001F}'));
    if (kDebugMode)
      debugPrint('[SecureKVStorage] setStringList: $key (${values.length})');
  }

  /// Load a string list securely
  static Future<List<String>> getStringList(String key) async {
    final value = await _storage.read(key: '$_prefix$key');
    if (value == null || value.isEmpty) return [];
    return value.split('\u{001F}');
  }

  /// Delete a key securely
  static Future<void> delete(String key) async {
    await _storage.delete(key: '$_prefix$key');
    if (kDebugMode) debugPrint('[SecureKVStorage] delete: $key');
  }

  /// Delete all keys with our prefix
  static Future<void> clearAll() async {
    // flutter_secure_storage doesn't support prefix deletion directly
    // We track known keys and delete them individually
    const knownKeys = [
      'store_edit_token',
      'vitrin_edit_token',
      'last_published_edit_token',
      'booking_tokens',
      'vitrin_view_session_key',
    ];
    for (final key in knownKeys) {
      await _storage.delete(key: '$_prefix$key');
    }
    if (kDebugMode) debugPrint('[SecureKVStorage] cleared all known keys');
  }

  /// Clear auth-related keys only (keep non-auth sensitive data)
  static Future<void> clearAuthKeys() async {
    const authKeys = [
      'store_edit_token',
      'vitrin_edit_token',
      'last_published_edit_token',
      'booking_tokens',
    ];
    for (final key in authKeys) {
      await _storage.delete(key: '$_prefix$key');
    }
    if (kDebugMode) debugPrint('[SecureKVStorage] cleared auth keys');
  }
}

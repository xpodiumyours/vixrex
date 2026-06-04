import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/services/local_storage_keys.dart';

/// Mağaza ve vitrin verilerinin yerel depolamaya yazılması/okunmasını
/// merkezi olarak yöneten servis.
///
/// Bu servis, SharedPreferences işlemlerinin ekran sınıflarında
/// tekrar yazılmasını önler ve test edilebilirliği artırır.
class StoreLocalStorageService {
  const StoreLocalStorageService();

  // ── Mağaza (Store) ────────────────────────────────────────────────────

  /// Mağaza verisini yerel depoya kaydeder.
  Future<void> saveStoreData(StoreData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      LocalStorageKeys.storeData,
      jsonEncode(data.toJson()),
    );
  }

  /// Kayıtlı mağaza verisini okur. Yoksa `null` döner.
  Future<StoreData?> loadStoreData() async {
    final prefs = await SharedPreferences.getInstance();
    return _readStoreData(prefs.getString(LocalStorageKeys.storeData));
  }

  /// Mağaza edit token'ını kaydeder.
  Future<void> saveStoreEditToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(LocalStorageKeys.storeEditToken, token);
  }

  /// Kayıtlı mağaza edit token'ını okur. Yoksa `null` döner.
  Future<String?> loadStoreEditToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(LocalStorageKeys.storeEditToken);
  }

  /// Kayıtlı mağaza verisini ve token'ını siler.
  Future<void> clearStoreData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(LocalStorageKeys.storeData);
    await prefs.remove(LocalStorageKeys.storeEditToken);
  }

  // ── Vitrin ────────────────────────────────────────────────────────────

  /// Vitrin verisini yerel depoya kaydeder.
  Future<void> saveVitrinData(StoreData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      LocalStorageKeys.vitrinData,
      jsonEncode(data.toJson()),
    );
  }

  /// Kayıtlı vitrin verisini okur. Yoksa `null` döner.
  Future<StoreData?> loadVitrinData() async {
    final prefs = await SharedPreferences.getInstance();
    return _readStoreData(prefs.getString(LocalStorageKeys.vitrinData));
  }

  /// Vitrin edit token'ını kaydeder.
  Future<void> saveVitrinEditToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(LocalStorageKeys.vitrinEditToken, token);
  }

  /// Kayıtlı vitrin edit token'ını okur. Yoksa `null` döner.
  Future<String?> loadVitrinEditToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(LocalStorageKeys.vitrinEditToken);
  }

  /// Kayıtlı vitrin verisini ve token'ını siler.
  Future<void> clearVitrinData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(LocalStorageKeys.vitrinData);
    await prefs.remove(LocalStorageKeys.vitrinEditToken);
  }

  // ── Legacy Destek ─────────────────────────────────────────────────────

  /// Eski `vitrin_data` anahtarında `isStore == true` bulunan veriyi
  /// okur (geriye dönük uyumluluk). Sadece okuma amaçlıdır.
  Future<StoreData?> loadLegacyStoreInVitrinData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(LocalStorageKeys.vitrinData);
    final data = _readStoreData(raw);
    if (data != null && data.isStore) {
      return data;
    }
    return null;
  }

  /// Eski `vitrin_data` anahtarını siler (migration sonrası temizlik için).
  Future<void> clearLegacyVitrinData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(LocalStorageKeys.vitrinData);
  }

  // ── Private ───────────────────────────────────────────────────────────

  StoreData? _readStoreData(String? rawJson) {
    if (rawJson == null || rawJson.trim().isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is Map<String, dynamic>) {
        return StoreData.fromJson(decoded);
      }
      if (decoded is Map) {
        return StoreData.fromJson(Map<String, dynamic>.from(decoded));
      }
    } on FormatException catch (e) {
      debugPrint('StoreLocalStorageService: JSON parse error: $e');
    }
    return null;
  }
}

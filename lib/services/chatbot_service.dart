import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitrinx/config/chatbot_config.dart';
import 'package:vitrinx/models/chat_message.dart';
import 'package:vitrinx/services/xrex_profile_snapshot.dart';

/// Xrex chatbot servis katmanı.
/// Kural tabanlı, tamamen offline çalışır.
class ChatbotService {
  static const String _greetedKey = 'xrex_greeted';
  static const String _sharedMilestoneKey = 'xrex_vitrin_shared';
  static const String _dismissedRecommendationKey =
      'xrex_dismissed_recommendation';

  /// Kullanıcının mesajını analiz edip yanıt döner.
  ChatMessage respond(
    String input, [
    XrexProfileSnapshot? snapshot,
    bool hasShared = false,
  ]) {
    final normalized = _normalize(input);

    // Intent eşleştirme
    for (final intent in ChatbotConfig.intents) {
      for (final keyword in intent.keywords) {
        if (normalized.contains(_normalize(keyword))) {
          return ChatbotConfig.responseFor(intent.payload, snapshot, hasShared);
        }
      }
    }

    // Eşleşme bulunamadı
    return ChatbotConfig.responseFor('default', snapshot, hasShared);
  }

  /// Quick Reply payload'ına göre yanıt döner.
  ChatMessage respondToPayload(
    String payload, [
    XrexProfileSnapshot? snapshot,
    bool hasShared = false,
  ]) {
    return ChatbotConfig.responseFor(payload, snapshot, hasShared);
  }

  /// Vitrin snapshot'ına göre kişiselleştirilmiş karşılama mesajı döner.
  ChatMessage respondWithSnapshot(
    XrexProfileSnapshot snapshot, {
    required bool hasShared,
  }) {
    return ChatbotConfig.snapshotWelcome(snapshot, hasShared: hasShared);
  }

  /// Kullanıcı daha önce karşılandı mı?
  Future<bool> wasGreeted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_greetedKey) ?? false;
  }

  /// Karşılama tamamlandı olarak işaretle.
  Future<void> markGreeted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_greetedKey, true);
  }

  Future<bool> hasSharedVitrin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_sharedMilestoneKey) ?? false;
  }

  Future<void> markVitrinShared() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sharedMilestoneKey, true);
  }

  Future<String?> loadDismissedRecommendationId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_dismissedRecommendationKey);
  }

  Future<void> dismissRecommendation(String recommendationId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dismissedRecommendationKey, recommendationId);
  }

  /// Türkçe karakter normalizasyonu + küçük harf.
  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll('İ', 'i')
        .replaceAll('Ğ', 'g')
        .replaceAll('Ü', 'u')
        .replaceAll('Ş', 's')
        .replaceAll('Ö', 'o')
        .replaceAll('Ç', 'c');
  }

  static const String _historyKey = 'xrex_chat_history';

  /// Sohbet geçmişini kaydeder.
  Future<void> saveHistory(List<ChatMessage> history) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = history.map((m) => m.toJson()).toList();
      await prefs.setString(_historyKey, jsonEncode(jsonList));
    } catch (_) {}
  }

  /// Sohbet geçmişini yükler.
  Future<List<ChatMessage>> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_historyKey);
      if (jsonStr == null || jsonStr.isEmpty) return [];
      final decoded = jsonDecode(jsonStr) as List<dynamic>;
      return decoded
          .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Geçmişi temizler.
  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
    } catch (_) {}
  }
}

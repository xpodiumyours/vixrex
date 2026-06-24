import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitrinx/config/chatbot_config.dart';
import 'package:vitrinx/models/chat_message.dart';
import 'package:vitrinx/services/xrex_profile_snapshot.dart';

/// Xrex chatbot servis katmanı.
/// Kural tabanlı, tamamen offline çalışır.
class ChatbotService {
  static const String _greetedKey = 'xrex_greeted';

  /// Kullanıcının mesajını analiz edip yanıt döner.
  ChatMessage respond(String input) {
    final normalized = _normalize(input);

    // Intent eşleştirme
    for (final intent in ChatbotConfig.intents) {
      for (final keyword in intent.keywords) {
        if (normalized.contains(_normalize(keyword))) {
          return ChatbotConfig.responseFor(intent.payload);
        }
      }
    }

    // Eşleşme bulunamadı
    return ChatbotConfig.responseFor('default');
  }

  /// Quick Reply payload'ına göre yanıt döner.
  ChatMessage respondToPayload(String payload) {
    return ChatbotConfig.responseFor(payload);
  }

  /// Vitrin snapshot'ına göre kişiselleştirilmiş karşılama mesajı döner.
  /// [İyileştirme #2] Önceliklendirilmiş eksik alan sıralaması ile.
  ChatMessage respondWithSnapshot(XrexProfileSnapshot snapshot) {
    return ChatbotConfig.snapshotWelcome(snapshot);
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
}

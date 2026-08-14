import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vixrex/config/chatbot_config.dart';
import 'package:vixrex/models/chat_message.dart';
import 'package:vixrex/services/vixrex_profile_snapshot.dart';

/// VixRex chatbot servis katmanı.
/// Kural tabanlı, tamamen offline çalışır.
class ChatbotService {
  static const String _greetedKey = 'vixrex_greeted';
  static const String _sharedMilestoneKey = 'vixrex_vitrin_shared';
  static const String _dismissedRecommendationKey =
      'vixrex_dismissed_recommendation';

  /// Kullanıcının mesajını analiz edip yanıt döner.
  ChatMessage respond(
    String input, [
    VixRexProfileSnapshot? snapshot,
    bool hasShared = false,
  ]) {
    final normalized = _normalize(input);

    // Intent eşleştirme
    for (final intent in ChatbotConfig.intents) {
      for (final keyword in intent.keywords) {
        if (normalized.contains(_normalize(keyword))) {
          return ChatbotConfig.responseFor(
            intent.payload,
            snapshot: snapshot,
            hasShared: hasShared,
          );
        }
      }
    }

    // Eşleşme bulunamadı
    return ChatbotConfig.responseFor(
      'default',
      snapshot: snapshot,
      hasShared: hasShared,
    );
  }

  /// Quick Reply payload'ına göre yanıt döner.
  ChatMessage respondToPayload(
    String payload, [
    VixRexProfileSnapshot? snapshot,
    bool hasShared = false,
  ]) {
    return ChatbotConfig.responseFor(
      payload,
      snapshot: snapshot,
      hasShared: hasShared,
    );
  }

  /// Vitrin snapshot'ına göre kişiselleştirilmiş karşılama mesajı döner.
  ChatMessage respondWithSnapshot(
    VixRexProfileSnapshot snapshot, {
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

  // ── Tek anahtar deseni (Tek Asistan planı, Faz C) ───────────────────────
  //
  // Eskiden üç anahtar vardı (scope'suz, v2 scope'lu, ayrıca loadHistory
  // her çağrıda eskiden yeniye kopyalıyordu — göç değil, sürekli kontrol).
  // Artık tek desen: vixrex_sohbet_v3_<scope>. Yayın yoksa scope "local".
  // Eski anahtarlardan bu desene taşıma SohbetGecmisiGocu'nun işi; bu
  // servis eski anahtar adlarını bilmez.
  static const String _v3Prefix = 'vixrex_sohbet_v3_';
  static const String localScope = 'local';

  String _historyKeyFor(String? scope) {
    final rawScope = scope?.trim() ?? '';
    if (rawScope.isEmpty) return '$_v3Prefix$localScope';

    final uri = Uri.tryParse(rawScope);
    final normalizedScope =
        uri != null && uri.pathSegments.isNotEmpty
            ? uri.pathSegments.last.toLowerCase()
            : rawScope.toLowerCase();
    final encodedScope = base64Url
        .encode(utf8.encode(normalizedScope))
        .replaceAll('=', '');
    return '$_v3Prefix$encodedScope';
  }

  List<ChatMessage> _decodeHistory(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return [];
    final decoded = jsonDecode(jsonStr) as List<dynamic>;
    return decoded
        .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  List<ChatMessage> reconcileGuidanceHistory({
    required List<ChatMessage> history,
    required ChatMessage currentGuidance,
    required String handoffMarker,
  }) {
    final reconciled = <ChatMessage>[];
    var handoffKept = false;

    for (final message in history) {
      final stateKey = message.snapshotStateKey?.trim() ?? '';
      if (stateKey == handoffMarker) {
        if (!handoffKept) {
          reconciled.add(message);
          handoffKept = true;
        }
        continue;
      }

      // Faz C: tahmine (state key doluluğu, payload ismi, eski CTA
      // etiketleri) değil, veriye bakılır. ChatbotConfig'in gerçekten
      // "şu an sıradaki adım" mesajı ürettiği üç yer (setupInviteMessage,
      // snapshotWelcome, nextStepTip) `uretilmis: true` yazıyor; geri kalan
      // her şey (sabit içerik yanıtları, kullanıcı mesajları) korunur.
      if (message.isBot && message.uretilmis) continue;

      reconciled.add(message);
    }

    reconciled.add(currentGuidance);
    return reconciled;
  }

  /// Sohbet geçmişini kaydeder.
  Future<void> saveHistory(List<ChatMessage> history, {String? scope}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = history.map((m) => m.toJson()).toList();
      await prefs.setString(_historyKeyFor(scope), jsonEncode(jsonList));
    } catch (e) {
      if (kDebugMode) debugPrint('saveHistory error: $e');
    }
  }

  /// Sohbet geçmişini yükler. Göç bilmez — bkz. [SohbetGecmisiGocu].
  Future<List<ChatMessage>> loadHistory({String? scope}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return _decodeHistory(prefs.getString(_historyKeyFor(scope)));
    } catch (_) {
      return [];
    }
  }

  /// Geçmişi temizler.
  Future<void> clearHistory({String? scope}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKeyFor(scope));
    } catch (e) {
      if (kDebugMode) debugPrint('clearHistory error: $e');
    }
  }

  /// Vitrin yayınlanınca yerel (henüz yayınlanmamış) geçmişi yeni scope'a
  /// bir kez taşır — Tek Asistan planı, Faz C, madde 1.
  ///
  /// Hedefte zaten geçmiş varsa dokunmaz (iki kez taşınmaz, üzerine yazmaz).
  /// Yerelde geçmiş yoksa sessizce çıkar.
  Future<void> migrateLocalToPublishedScope(String scope) async {
    final trimmedScope = scope.trim();
    if (trimmedScope.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final localKey = _historyKeyFor(null);
      final targetKey = _historyKeyFor(trimmedScope);
      if (targetKey == localKey) return;

      final localRaw = prefs.getString(localKey);
      if (localRaw == null || localRaw.isEmpty) return;

      final targetRaw = prefs.getString(targetKey);
      if (targetRaw != null && targetRaw.isNotEmpty) return;

      await prefs.setString(targetKey, localRaw);
      await prefs.remove(localKey);
    } catch (e) {
      if (kDebugMode) debugPrint('migrateLocalToPublishedScope error: $e');
    }
  }
}

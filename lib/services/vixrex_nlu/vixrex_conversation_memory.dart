import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Bekleyen slot – netleştirme için hafıza.
/// Supabase `assistant_conversations.pending_slot jsonb` kanonik,
/// SharedPrefs yerel önbellek (çevrimdışı). VixrexConversationRepository deseni korunur.
class VixrexPendingSlot {
  final String anahtar; // vitrin alan anahtarı, örn. "whatsapp"
  final String etiket; // Türkçe etiket, bildirim için
  final String tip; // metin/telefon/url/sayi/secim/acikKapali...
  final DateTime sorulduAt;
  final int deneme; // kaç kez soruldu (spam koruması)

  const VixrexPendingSlot({
    required this.anahtar,
    required this.etiket,
    required this.tip,
    required this.sorulduAt,
    this.deneme = 1,
  });

  Map<String, dynamic> toJson() => {
        'anahtar': anahtar,
        'etiket': etiket,
        'tip': tip,
        'sorulduAt': sorulduAt.toIso8601String(),
        'deneme': deneme,
      };

  factory VixrexPendingSlot.fromJson(Map<String, dynamic> json) {
    return VixrexPendingSlot(
      anahtar: json['anahtar'] as String,
      etiket: json['etiket'] as String? ?? json['anahtar'] as String,
      tip: json['tip'] as String? ?? 'metin',
      sorulduAt: DateTime.tryParse(json['sorulduAt'] as String? ?? '') ?? DateTime.now(),
      deneme: (json['deneme'] as num?)?.toInt() ?? 1,
    );
  }
}

/// Port – testte mock’lanır, prod’da Supabase + SharedPrefs.
abstract class VixrexConversationMemoryPort {
  Future<VixrexPendingSlot?> loadPendingSlot({String? scope});
  Future<void> savePendingSlot(VixrexPendingSlot slot, {String? scope});
  Future<void> clearPendingSlot({String? scope});
}

/// SharedPrefs + (ileride) Supabase. Faz 1’de SharedPrefs yeterli,
/// Supabase `pending_slot` kolonu eklenince buraya RPC eklenir – arayüz değişmez.
class VixrexConversationMemory implements VixrexConversationMemoryPort {
  const VixrexConversationMemory();

  static const _prefix = 'vixrex_pending_slot_v1_';
  static const _localScope = 'local';

  String _keyFor(String? scope) {
    final s = scope?.trim().isEmpty == true ? _localScope : scope!.trim();
    // Scope’u normalize et – ChatbotService._historyKeyFor ile aynı mantık ama sade.
    final norm = s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return '$_prefix$norm';
  }

  @override
  Future<VixrexPendingSlot?> loadPendingSlot({String? scope}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(scope));
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return VixrexPendingSlot.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> savePendingSlot(VixrexPendingSlot slot, {String? scope}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFor(scope), jsonEncode(slot.toJson()));
  }

  @override
  Future<void> clearPendingSlot({String? scope}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFor(scope));
  }
}

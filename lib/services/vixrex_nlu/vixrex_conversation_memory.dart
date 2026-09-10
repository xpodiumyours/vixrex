import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:vixrex/repositories/vixrex_conversation_repository.dart';

/// Bekleyen slot – netleştirme için hafıza.
/// Supabase `assistant_conversations.pending_slot jsonb` kanonik,
/// SharedPrefs yalnız çevrimdışı/oturumsuz önbellektir.
class VixrexPendingSlot {
  final String anahtar; // vitrin alan anahtarı, örn. "whatsapp"
  final String etiket; // Türkçe etiket, bildirim için
  final String tip; // metin/telefon/url/sayi/secim/acikKapali...
  final DateTime sorulduAt;
  final int deneme; // kaç kez soruldu (spam koruması)
  final String? eylem; // örn. "kaldir" — sonraki kısa cevabın bağlamı

  const VixrexPendingSlot({
    required this.anahtar,
    required this.etiket,
    required this.tip,
    required this.sorulduAt,
    this.deneme = 1,
    this.eylem,
  });

  Map<String, dynamic> toJson() => {
    'anahtar': anahtar,
    'etiket': etiket,
    'tip': tip,
    'sorulduAt': sorulduAt.toIso8601String(),
    'deneme': deneme,
    if (eylem != null) 'eylem': eylem,
  };

  factory VixrexPendingSlot.fromJson(Map<String, dynamic> json) {
    return VixrexPendingSlot(
      anahtar: json['anahtar'] as String,
      etiket: json['etiket'] as String? ?? json['anahtar'] as String,
      tip: json['tip'] as String? ?? 'metin',
      sorulduAt:
          DateTime.tryParse(json['sorulduAt'] as String? ?? '') ??
          DateTime.now(),
      deneme: (json['deneme'] as num?)?.toInt() ?? 1,
      eylem: json['eylem'] as String?,
    );
  }
}

/// Port – testte mock’lanır, prod’da Supabase + SharedPrefs.
abstract class VixrexConversationMemoryPort {
  Future<VixrexPendingSlot?> loadPendingSlot({String? scope});
  Future<void> savePendingSlot(VixrexPendingSlot slot, {String? scope});
  Future<void> clearPendingSlot({String? scope});
}

/// Kalıcı hesapta Supabase kanoniktir. SharedPrefs aynı slotun yerel
/// önbelleğidir ve ağ/Supabase erişilemezse konuşmanın cihazda devam etmesini
/// sağlar. Böylece Next.js ve Flutter aynı pending slotu okuyabilir.
class VixrexConversationMemory implements VixrexConversationMemoryPort {
  const VixrexConversationMemory({
    VixrexConversationRepository conversationRepository =
        const VixrexConversationRepository(),
  }) : _conversationRepository = conversationRepository;

  final VixrexConversationRepository _conversationRepository;

  static const _prefix = 'vixrex_pending_slot_v1_';
  static const _localScope = 'local';

  String _keyFor(String? scope) {
    final s =
        (scope == null || scope.trim().isEmpty) ? _localScope : scope.trim();
    final norm = s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return '$_prefix$norm';
  }

  Future<VixrexPendingSlot?> _loadLocal(String? scope) async {
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

  Future<void> _saveLocal(VixrexPendingSlot slot, String? scope) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFor(scope), jsonEncode(slot.toJson()));
  }

  Future<void> _clearLocal(String? scope) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFor(scope));
  }

  @override
  Future<VixrexPendingSlot?> loadPendingSlot({String? scope}) async {
    if (_conversationRepository.canSync) {
      try {
        final remote = await _conversationRepository.loadPendingSlot();
        if (remote == null) {
          // Kalıcı hesapta uzak kaynak kanonik: uzakta slot yoksa eski cihaz
          // önbelleği yeni bir konuşma adımı gibi tekrar canlanmamalı.
          await _clearLocal(scope);
          return null;
        }
        final slot = VixrexPendingSlot.fromJson(remote);
        await _saveLocal(slot, scope);
        return slot;
      } catch (_) {
        // Ağ/Supabase hatasında yalnızca yerel önbelleğe geri düş.
      }
    }
    return _loadLocal(scope);
  }

  @override
  Future<void> savePendingSlot(VixrexPendingSlot slot, {String? scope}) async {
    await _saveLocal(slot, scope);
    if (!_conversationRepository.canSync) return;
    try {
      await _conversationRepository.savePendingSlot(slot.toJson());
    } catch (_) {
      // Yerel önbellek korundu; bağlantı gelince sonraki işlemde kanonik kaynak
      // yeniden okunur.
    }
  }

  @override
  Future<void> clearPendingSlot({String? scope}) async {
    await _clearLocal(scope);
    if (!_conversationRepository.canSync) return;
    try {
      await _conversationRepository.savePendingSlot(null);
    } catch (_) {
      // Çevrimdışı temizleme cihazda uygulanır. Uzak durum yeniden erişildiğinde
      // kanonik değer tekrar okunur; sessizce yeni alan uydurulmaz.
    }
  }
}

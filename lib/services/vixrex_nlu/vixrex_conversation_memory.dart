import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:vixrex/repositories/vixrex_conversation_repository.dart';

/// Bekleyen slot – netleştirme için hafıza.
///
/// 5.4 canonical envelope v1. Eski anahtarlar (`anahtar`, `etiket`, `tip`,
/// `sorulduAt`, `deneme`) geçiş süresince JSON'da da tutulur; mevcut canlı
/// DB constraint ve eski istemciler kırılmaz. Canonical alanlar field*/kind
/// isimleridir.
class VixrexPendingSlot {
  static const int currentSchemaVersion = 1;
  static const String storefrontDomain = 'storefront';
  static const String missingValueKind = 'missing_value';
  static const String confirmCandidateKind = 'confirm_candidate';
  static const String specialFlowKind = 'special_flow';

  final int schemaVersion;
  final String domain;
  final String kind;
  final String anahtar;
  final String etiket;
  final String tip;
  final DateTime sorulduAt;
  final int deneme;
  final Object? proposedValue;
  final String? commandId;

  const VixrexPendingSlot({
    this.schemaVersion = currentSchemaVersion,
    this.domain = storefrontDomain,
    this.kind = missingValueKind,
    required this.anahtar,
    required this.etiket,
    required this.tip,
    required this.sorulduAt,
    this.deneme = 1,
    this.proposedValue,
    this.commandId,
  });

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'domain': domain,
    'kind': kind,
    'fieldKey': anahtar,
    'fieldType': tip,
    'fieldLabel': etiket,
    if (proposedValue != null) 'proposedValue': proposedValue,
    if (commandId != null) 'commandId': commandId,
    'attempt': deneme,
    'createdAt': sorulduAt.toIso8601String(),

    // Geçiş uyumu: mevcut DB constraint ve eski istemciler.
    'anahtar': anahtar,
    'etiket': etiket,
    'tip': tip,
    'sorulduAt': sorulduAt.toIso8601String(),
    'deneme': deneme,
  };

  factory VixrexPendingSlot.fromJson(Map<String, dynamic> json) {
    final schemaVersion =
        (json['schemaVersion'] as num?)?.toInt() ?? currentSchemaVersion;
    final domain = json['domain']?.toString() ?? storefrontDomain;
    final kind = json['kind']?.toString() ?? missingValueKind;
    final anahtar = (json['fieldKey'] ?? json['anahtar'])?.toString().trim();

    if (schemaVersion != currentSchemaVersion ||
        domain != storefrontDomain ||
        !const {
          missingValueKind,
          confirmCandidateKind,
          specialFlowKind,
        }.contains(kind) ||
        anahtar == null ||
        anahtar.isEmpty) {
      throw const FormatException('INVALID_PENDING_SLOT');
    }

    final etiket =
        (json['fieldLabel'] ?? json['etiket'])?.toString() ?? anahtar;
    final tip = (json['fieldType'] ?? json['tip'])?.toString() ?? 'metin';
    final createdAtRaw =
        (json['createdAt'] ?? json['sorulduAt'])?.toString() ?? '';
    final deneme =
        ((json['attempt'] ?? json['deneme']) as num?)?.toInt() ?? 1;
    final commandId = json['commandId']?.toString().trim();

    return VixrexPendingSlot(
      schemaVersion: schemaVersion,
      domain: domain,
      kind: kind,
      anahtar: anahtar,
      etiket: etiket,
      tip: tip,
      sorulduAt: DateTime.tryParse(createdAtRaw) ?? DateTime.now(),
      deneme: deneme < 1 ? 1 : deneme,
      proposedValue: json['proposedValue'],
      commandId:
          commandId == null || commandId.isEmpty ? null : commandId,
    );
  }
}

abstract class VixrexConversationMemoryPort {
  Future<VixrexPendingSlot?> loadPendingSlot({String? scope});
  Future<void> savePendingSlot(VixrexPendingSlot slot, {String? scope});
  Future<void> clearPendingSlot({String? scope});
}

/// Supabase canonical + SharedPrefs cache/offline devam katmanı.
///
/// Kalıcı/non-anonymous hesapta remote hakikattir. Offline set/clear işlemi
/// dirty marker ile tutulur; bağlantı geldiğinde remote okunmadan önce bu
/// işlem tekrar uygulanır. Böylece eski remote pending local değişikliği
/// geri diriltemez.
class VixrexConversationMemory implements VixrexConversationMemoryPort {
  const VixrexConversationMemory({VixrexConversationRepository? repository})
    : _repository = repository ?? const VixrexConversationRepository();

  final VixrexConversationRepository _repository;

  static const _prefix = 'vixrex_pending_slot_v1_';
  static const _dirtyPrefix = 'vixrex_pending_slot_dirty_v1_';
  static const _localScope = 'local';
  static const _dirtySet = 'set';
  static const _dirtyClear = 'clear';

  String _normalizedScope(String? scope) {
    final raw =
        (scope == null || scope.trim().isEmpty) ? _localScope : scope.trim();
    return raw.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  }

  String _keyFor(String? scope) => '$_prefix${_normalizedScope(scope)}';
  String _dirtyKeyFor(String? scope) =>
      '$_dirtyPrefix${_normalizedScope(scope)}';

  VixrexPendingSlot? _decodeLocal(SharedPreferences prefs, String? scope) {
    final raw = prefs.getString(_keyFor(scope));
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return VixrexPendingSlot.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  Future<void> _cacheSlot(
    SharedPreferences prefs,
    VixrexPendingSlot slot,
    String? scope,
  ) async {
    await prefs.setString(_keyFor(scope), jsonEncode(slot.toJson()));
  }

  Future<void> _clearCache(SharedPreferences prefs, String? scope) async {
    await prefs.remove(_keyFor(scope));
  }

  @override
  Future<VixrexPendingSlot?> loadPendingSlot({String? scope}) async {
    final prefs = await SharedPreferences.getInstance();
    final local = _decodeLocal(prefs, scope);

    if (!_repository.canSync) return local;

    final dirtyKey = _dirtyKeyFor(scope);
    final dirty = prefs.getString(dirtyKey);

    if (dirty == _dirtyClear) {
      try {
        await _repository.savePendingSlot(null);
        await prefs.remove(dirtyKey);
        await _clearCache(prefs, scope);
      } catch (_) {
        // Remote clear gerçekleşmeden eski remote state'i geri yükleme.
      }
      return null;
    }

    if (dirty == _dirtySet) {
      if (local == null) {
        await prefs.remove(dirtyKey);
      } else {
        try {
          await _repository.savePendingSlot(local.toJson());
          await prefs.remove(dirtyKey);
        } catch (_) {
          return local;
        }
        return local;
      }
    }

    try {
      final remote = await _repository.loadPendingSlot();
      if (remote == null) {
        await _clearCache(prefs, scope);
        return null;
      }
      final slot = VixrexPendingSlot.fromJson(remote);
      await _cacheSlot(prefs, slot, scope);
      return slot;
    } catch (_) {
      return local;
    }
  }

  @override
  Future<void> savePendingSlot(VixrexPendingSlot slot, {String? scope}) async {
    final prefs = await SharedPreferences.getInstance();
    await _cacheSlot(prefs, slot, scope);
    final dirtyKey = _dirtyKeyFor(scope);

    if (!_repository.canSync) {
      await prefs.setString(dirtyKey, _dirtySet);
      return;
    }

    try {
      await _repository.savePendingSlot(slot.toJson());
      await prefs.remove(dirtyKey);
    } catch (_) {
      await prefs.setString(dirtyKey, _dirtySet);
    }
  }

  @override
  Future<void> clearPendingSlot({String? scope}) async {
    final prefs = await SharedPreferences.getInstance();
    await _clearCache(prefs, scope);
    final dirtyKey = _dirtyKeyFor(scope);

    if (!_repository.canSync) {
      await prefs.setString(dirtyKey, _dirtyClear);
      return;
    }

    try {
      await _repository.savePendingSlot(null);
      await prefs.remove(dirtyKey);
    } catch (_) {
      await prefs.setString(dirtyKey, _dirtyClear);
    }
  }
}

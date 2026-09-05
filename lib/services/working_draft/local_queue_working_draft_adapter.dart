import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vixrex/core/result.dart';
import 'package:vixrex/services/working_draft/working_draft_port.dart';
import 'package:vixrex/services/working_draft/supabase_working_draft_adapter.dart';
import 'package:vixrex/utils/failure.dart';

/// Yerel önbellek + kuyruk adaptörü — çevrimdışı önbellek ve kuyruk.
///
/// Taslak verisi Supabase'in önbelleği. Normal yamalar legacy kimliğiyle,
/// Akıllı Motor yamaları ise expectedVersion + actionId + commandId ile
/// kuyruklanır. Reconnect'te aynı logical action aynı kimlikle tekrar edilir;
/// 5.5 idempotency receipt duplicate mutation'ı engeller.
class LocalQueueWorkingDraftAdapter implements WorkingDraftPort {
  LocalQueueWorkingDraftAdapter({
    SupabaseWorkingDraftAdapter? remote,
    SharedPreferences? prefs,
  })  : _remote = remote ?? const SupabaseWorkingDraftAdapter(),
        _prefs = prefs;

  final SupabaseWorkingDraftAdapter _remote;
  final SharedPreferences? _prefs;

  static const _kKuyruk = 'wd_kuyruk_v1';
  static const _kOnbellek = 'wd_onbellek_v1';
  static const _assistantKind = 'smart_engine';

  SharedPreferences? _cachedPrefs;

  Future<SharedPreferences> _prefsAsync() async {
    if (_prefs != null) return _prefs!;
    return _cachedPrefs ??= await SharedPreferences.getInstance();
  }

  @override
  Future<Result<WorkingDraftSnapshot>> yukle({required String sessionToken}) async {
    final remote = await _remote.yukle(sessionToken: sessionToken);
    if (remote.isSuccess) {
      final p = await _prefsAsync();
      await p.setString(_kOnbellek, jsonEncode(remote.data!.draftData));
      return remote;
    }
    // Çevrimdışı: önbellekten dön.
    try {
      final p = await _prefsAsync();
      final raw = p.getString(_kOnbellek);
      if (raw == null) return remote;
      final data = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      return Result.success(WorkingDraftSnapshot(
        slug: '',
        draftData: data,
        draftVersion: 1,
        baseLiveVersion: 1,
      ));
    } catch (_) {
      return remote;
    }
  }

  @override
  Future<Result<WorkingDraftPatchResult>> yamaUygula({
    required String sessionToken,
    required String anahtar,
    required dynamic deger,
    int? beklenenSurum,
    String? clientId,
  }) async {
    final res = await _remote.yamaUygula(
      sessionToken: sessionToken,
      anahtar: anahtar,
      deger: deger,
      beklenenSurum: beklenenSurum,
      clientId: clientId,
    );
    if (res.isSuccess) {
      await _legacyKuyruktanSil(anahtar);
      return res;
    }
    if (_agYok(res.failure)) {
      await _legacyKuyrugaEkle(anahtar, deger, beklenenSurum, clientId);
      return Result.success(const WorkingDraftPatchResult.queuedOffline());
    }
    return res;
  }

  @override
  Future<Result<WorkingDraftAssistantPatchResult>> akilliMotorYamasiUygula({
    String? sessionToken,
    required String anahtar,
    required dynamic deger,
    required int beklenenSurum,
    required String actionId,
    required String commandId,
    String? clientId,
  }) async {
    final res = await _remote.akilliMotorYamasiUygula(
      sessionToken: sessionToken,
      anahtar: anahtar,
      deger: deger,
      beklenenSurum: beklenenSurum,
      actionId: actionId,
      commandId: commandId,
      clientId: clientId,
    );

    if (res.isSuccess) {
      await _assistantKuyruktanSil(actionId);
      return res;
    }

    if (_agYok(res.failure)) {
      await _assistantKuyrugaEkle(
        anahtar: anahtar,
        deger: deger,
        beklenenSurum: beklenenSurum,
        actionId: actionId,
        commandId: commandId,
        clientId: clientId,
      );
      return Result.success(
        WorkingDraftAssistantPatchResult.queuedOffline(
          actionId: actionId,
          commandId: commandId,
          fieldKey: anahtar,
          normalizedValue: deger,
        ),
      );
    }

    return res;
  }

  bool _agYok(Failure? f) {
    if (f == null) return false;
    final m = f.message.toUpperCase();
    return m.contains('NO_CLIENT') ||
        m.contains('NETWORK') ||
        m.contains('SOCKET') ||
        m.contains('İNTERNET') ||
        m.contains('INTERNET') ||
        m.contains('BAĞLANTI');
  }

  Future<void> _legacyKuyrugaEkle(
    String k,
    dynamic v,
    int? vs,
    String? cid,
  ) async {
    final p = await _prefsAsync();
    final list = List<String>.from(p.getStringList(_kKuyruk) ?? const []);
    list.add(jsonEncode({
      'k': k,
      'v': v,
      'vs': vs,
      'cid': cid,
      'ts': DateTime.now().toIso8601String(),
    }));
    await p.setStringList(_kKuyruk, list);
  }

  Future<void> _assistantKuyrugaEkle({
    required String anahtar,
    required dynamic deger,
    required int beklenenSurum,
    required String actionId,
    required String commandId,
    String? clientId,
  }) async {
    final p = await _prefsAsync();
    final list = List<String>.from(p.getStringList(_kKuyruk) ?? const []);

    // Aynı logical action response kaybı nedeniyle tekrar queue edilirse ikinci
    // queue item üretme. Payload farklıysa server idempotency reuse ile reddeder;
    // queue da kimliği değiştirmez.
    final alreadyQueued = list.any((raw) {
      try {
        final m = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        return m['kind'] == _assistantKind && m['aid'] == actionId;
      } catch (_) {
        return false;
      }
    });
    if (alreadyQueued) return;

    list.add(jsonEncode({
      'kind': _assistantKind,
      'k': anahtar,
      'v': deger,
      'vs': beklenenSurum,
      'cid': clientId,
      'aid': actionId,
      'cmd': commandId,
      'ts': DateTime.now().toIso8601String(),
    }));
    await p.setStringList(_kKuyruk, list);
  }

  Future<void> _legacyKuyruktanSil(String k) async {
    final p = await _prefsAsync();
    final list = List<String>.from(p.getStringList(_kKuyruk) ?? const []);
    list.removeWhere((e) {
      try {
        final m = Map<String, dynamic>.from(jsonDecode(e) as Map);
        return m['kind'] != _assistantKind && m['k'] == k;
      } catch (_) {
        return false;
      }
    });
    await p.setStringList(_kKuyruk, list);
  }

  Future<void> _assistantKuyruktanSil(String actionId) async {
    final p = await _prefsAsync();
    final list = List<String>.from(p.getStringList(_kKuyruk) ?? const []);
    list.removeWhere((e) {
      try {
        final m = Map<String, dynamic>.from(jsonDecode(e) as Map);
        return m['kind'] == _assistantKind && m['aid'] == actionId;
      } catch (_) {
        return false;
      }
    });
    await p.setStringList(_kKuyruk, list);
  }

  /// Kuyruktaki yamaları sırayla gönder — bağlantı gelince çağrılır.
  /// Assistant action aynı actionId/commandId ile replay edilir; yeni kimlik
  /// üretilmez. Gerçek hata/conflict sonrası zincir durur.
  Future<void> kuyruguBosalt({required String sessionToken}) async {
    final p = await _prefsAsync();
    final list = List<String>.from(p.getStringList(_kKuyruk) ?? const []);
    for (final raw in List<String>.from(list)) {
      Map<String, dynamic> m;
      try {
        m = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      } catch (_) {
        continue;
      }

      if (m['kind'] == _assistantKind) {
        final r = await _remote.akilliMotorYamasiUygula(
          sessionToken: sessionToken.trim().isEmpty ? null : sessionToken,
          anahtar: m['k'] as String,
          deger: m['v'],
          beklenenSurum: (m['vs'] as num).toInt(),
          actionId: m['aid'] as String,
          commandId: m['cmd'] as String,
          clientId: m['cid'] as String?,
        );
        if (r.isSuccess && r.data?.succeeded == true) {
          list.remove(raw);
          await p.setStringList(_kKuyruk, List<String>.from(list));
          continue;
        }
        if (!_agYok(r.failure)) break;
        continue;
      }

      final r = await _remote.yamaUygula(
        sessionToken: sessionToken,
        anahtar: m['k'] as String,
        deger: m['v'],
        beklenenSurum: m['vs'] as int?,
        clientId: m['cid'] as String?,
      );
      if (r.isSuccess && r.data?.succeeded == true) {
        list.remove(raw);
        await p.setStringList(_kKuyruk, List<String>.from(list));
      } else if (!_agYok(r.failure)) {
        break;
      }
    }
  }

  @override
  Future<Result<WorkingDraftPublishResult>> yayinla({required String sessionToken}) =>
      _remote.yayinla(sessionToken: sessionToken);

  @override
  Stream<int> degisimSinyali({required String slug}) => _remote.degisimSinyali(slug: slug);
}

import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vixrex/core/result.dart';
import 'package:vixrex/services/working_draft/working_draft_port.dart';
import 'package:vixrex/services/working_draft/supabase_working_draft_adapter.dart';
import 'package:vixrex/utils/failure.dart';

/// Yerel önbellek + kuyruk adaptörü — çevrimdışı önbellek ve kuyruk.
///
/// Taslak verisi Supabase'in önbelleği; yamalar `expected_version` + `clientId`
/// ile kuyruklanır. Bağlantı gelince sırayla gönderilir. Farklı alanlar
/// otomatik birleşir, aynı alan çakışması kullanıcıya gösterilir (C23).
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
      await _kuyruktanSil(anahtar);
      return res;
    }
    // Ağ yoksa kuyruğa al, sonra aynı logical patch'i yeniden dene.
    if (_agYok(res.failure)) {
      await _kuyrugaEkle(anahtar, deger, beklenenSurum, clientId);
      // Queue'a güvenli yazılmış olması authoritative persistence değildir.
      // Sahte draftVersion:-1 yerine açık queuedOffline sonucu döner.
      return Result.success(const WorkingDraftPatchResult.queuedOffline());
    }
    return res;
  }

  bool _agYok(Failure? f) {
    if (f == null) return false;
    final m = f.message.toUpperCase();
    return m.contains('NO_CLIENT') || m.contains('NETWORK') || m.contains('SOCKET');
  }

  Future<void> _kuyrugaEkle(String k, dynamic v, int? vs, String? cid) async {
    final p = await _prefsAsync();
    final list = List<String>.from(p.getStringList(_kKuyruk) ?? const []);
    list.add(jsonEncode({'k': k, 'v': v, 'vs': vs, 'cid': cid, 'ts': DateTime.now().toIso8601String()}));
    await p.setStringList(_kKuyruk, list);
  }

  Future<void> _kuyruktanSil(String k) async {
    final p = await _prefsAsync();
    final list = List<String>.from(p.getStringList(_kKuyruk) ?? const []);
    list.removeWhere((e) {
      try {
        return (jsonDecode(e) as Map)['k'] == k;
      } catch (_) {
        return false;
      }
    });
    await p.setStringList(_kKuyruk, list);
  }

  /// Kuyruktaki yamaları sırayla gönder — bağlantı gelince çağrılır.
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
        break; // Gerçek hata — dur, kullanıcı çözecek (C23).
      }
    }
  }

  @override
  Future<Result<WorkingDraftPublishResult>> yayinla({required String sessionToken}) =>
      _remote.yayinla(sessionToken: sessionToken);

  @override
  Stream<int> degisimSinyali({required String slug}) => _remote.degisimSinyali(slug: slug);
}

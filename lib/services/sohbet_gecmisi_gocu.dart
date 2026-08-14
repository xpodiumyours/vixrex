import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sohbet geçmişi göçü — eski anahtar desenlerinden tek v3 desenine.
///
/// NEDEN VAR (Tek Asistan planı, Faz C)
/// `ChatbotService` üç ayrı anahtar tutuyordu: `vixrex_chat_history` (eski,
/// scope'suz), `vixrex_chat_history_v2_<base64(slug)>` (scope'lu) ve
/// `loadHistory` eskiden yeniye HER ÇAĞRIDA kopyalıyordu — göç değil,
/// sürekli kontrol. Artık tek desen var: `vixrex_sohbet_v3_<scope>`
/// (yayın yoksa scope `local`). Göç burada, uygulama açılışında bir kez.
///
/// `ChatbotService.loadHistory` artık bu eski anahtarları hiç bilmez.
abstract final class SohbetGecmisiGocu {
  static const String _bayrakAnahtari = 'vixrex_gecmis_goc_v3';
  static const String _eskiScopesuzAnahtar = 'vixrex_chat_history';
  static const String _eskiScopluOnEk = 'vixrex_chat_history_v2_';
  static const String _yeniOnEk = 'vixrex_sohbet_v3_';
  static const String _yerelScope = 'local';

  /// Uygulama açılışında bir kez çağrılır. İkinci çağrıda bayrak sayesinde
  /// hemen çıkar — pahalı bir işlem değil ama tekrar çalışmaz.
  static Future<void> calistir() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_bayrakAnahtari) ?? false) return;

      // v1: scope'suz eski geçmiş → "local" scope'a taşınır. Kullanıcı
      // henüz yayınlamamışken biriken sohbet burada duruyordu.
      final eskiScopesuz = prefs.getString(_eskiScopesuzAnahtar);
      if (eskiScopesuz != null && eskiScopesuz.isNotEmpty) {
        await _tasiSessizce(
          prefs,
          hedefAnahtar: '$_yeniOnEk$_yerelScope',
          deger: eskiScopesuz,
        );
        await prefs.remove(_eskiScopesuzAnahtar);
      }

      // v2: scope'lu eski geçmişler → aynı scope'ta (aynı kodlama) v3.
      final eskiScopluAnahtarlar =
          prefs.getKeys().where((k) => k.startsWith(_eskiScopluOnEk)).toList();
      for (final eskiAnahtar in eskiScopluAnahtarlar) {
        final deger = prefs.getString(eskiAnahtar);
        if (deger != null && deger.isNotEmpty) {
          final kodluScope = eskiAnahtar.substring(_eskiScopluOnEk.length);
          await _tasiSessizce(
            prefs,
            hedefAnahtar: '$_yeniOnEk$kodluScope',
            deger: deger,
          );
        }
        await prefs.remove(eskiAnahtar);
      }

      await prefs.setBool(_bayrakAnahtari, true);
    } catch (e) {
      // Göç başarısız olsa bile uygulama açılmaya devam eder — bu adım bir
      // kapı değil, bir temizlik. Sohbet geçmişi eski anahtarda kalır,
      // bir sonraki açılışta tekrar denenir (bayrak basılmadı).
      if (kDebugMode) debugPrint('SohbetGecmisiGocu.calistir error: $e');
    }
  }

  /// Hedefte zaten veri varsa üzerine yazmaz — iki eski kaynak aynı hedefe
  /// düşerse (olağan değil ama olursa) ilk gelen kazanır, veri kaybolmaz.
  static Future<void> _tasiSessizce(
    SharedPreferences prefs, {
    required String hedefAnahtar,
    required String deger,
  }) async {
    final mevcut = prefs.getString(hedefAnahtar);
    if (mevcut != null && mevcut.isNotEmpty) return;
    await prefs.setString(hedefAnahtar, deger);
  }
}

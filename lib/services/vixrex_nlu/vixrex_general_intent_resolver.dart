import 'package:vixrex/config/vixrex_mesajlar.g.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_normalizer.dart';

/// Flutter'ın genel rehber niyet çözümü.
/// Next.js `resolveVixrexGeneralIntent` ile aynı deterministik kural:
/// - eşleşme kelime başından başlamalı,
/// - Türkçe ekler için son sınır katı değil,
/// - en uzun/en özgül anahtar kelime kazanır,
/// - eşit uzunlukta katalog sırası korunur.
class VixrexGeneralIntentResolver {
  const VixrexGeneralIntentResolver();

  bool _kelimeBaslangicindaVarMi(String input, String keyword) {
    var from = 0;
    while (from <= input.length - keyword.length) {
      final idx = input.indexOf(keyword, from);
      if (idx < 0) return false;
      final baslangicUygun =
          idx == 0 || !RegExp(r'[a-z0-9]').hasMatch(input[idx - 1]);
      if (baslangicUygun) return true;
      from = idx + 1;
    }
    return false;
  }

  String? resolve(String input) {
    final normalized = VixrexNormalizer.normalize(input);
    if (normalized.trim().isEmpty) return null;

    String? bestPayload;
    var bestLength = -1;

    for (final intent in vixRexIntentSemasi) {
      for (final keyword in intent.anahtarKelimeler) {
        final normalizedKeyword = VixrexNormalizer.normalize(keyword).trim();
        if (normalizedKeyword.isEmpty) continue;
        if (!_kelimeBaslangicindaVarMi(normalized, normalizedKeyword)) continue;
        if (normalizedKeyword.length > bestLength) {
          bestLength = normalizedKeyword.length;
          bestPayload = intent.payload;
        }
      }
    }

    return bestPayload;
  }
}

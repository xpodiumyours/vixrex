import 'package:vixrex/config/vixrex_niyet_sozlugu.g.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_normalizer.dart';

/// 46 alan sözlüğü üzerinden eş-anlam + sözlük örneği ile alan bulur.
/// Deterministik, AI yok, Next.js ile aynı algoritma olmalı.
class VixrexIntentResolver {
  const VixrexIntentResolver();

  /// Türkçe ekler için son sınırı katı değildir; fakat eşleşme sıradan bir
  /// kelimenin ortasından başlayamaz. Uzun/bağlamlı örnekler kısa alias'lardan
  /// önce değerlendirilir.
  bool _niyetBaslangicindaEslesir(String normInput, String normIfade) {
    var from = 0;
    while (from <= normInput.length - normIfade.length) {
      final idx = normInput.indexOf(normIfade, from);
      if (idx < 0) return false;
      if (idx == 0 || !RegExp(r'[a-z0-9]').hasMatch(normInput[idx - 1])) {
        return true;
      }
      from = idx + 1;
    }
    return false;
  }

  /// `{deger}` içeren sözlük örneğinin değerden önceki sabit bölümü gerçek
  /// niyet kanıtıdır. Değeri sabit örnekler genelleştirilmez; değer taşımayan
  /// aç/kapat komutları doğrudan kanıt olarak kullanılır.
  List<String> _ornekNiyetIfadeleri(VixrexNiyetAlan alan) {
    final ifadeler = <String>[];
    for (final ornek in alan.ornekIfadeler) {
      final marker = ornek.indexOf('{deger}');
      String? sabit;
      if (marker >= 0) {
        sabit = ornek
            .substring(0, marker)
            .replaceFirst(RegExp(r'[\s:,-]+$'), '')
            .trim();
      } else if (alan.tip == 'acikKapali') {
        sabit = ornek.trim();
      }
      if (sabit != null && sabit.isNotEmpty) ifadeler.add(sabit);
    }
    return ifadeler;
  }

  List<({VixrexNiyetAlan alan, String ifade, int len})> _adaylariOlustur() {
    final candidates = <({VixrexNiyetAlan alan, String ifade, int len})>[];
    for (final alan in vixrexNiyetSozlugu) {
      final seen = <String>{};
      final ifadeler = <String>[
        ...alan.esAnlamlar,
        ..._ornekNiyetIfadeleri(alan),
      ];
      for (final ifade in ifadeler) {
        final normIfade = VixrexNormalizer.normalize(ifade).trim();
        if (normIfade.isEmpty || seen.contains(normIfade)) continue;
        seen.add(normIfade);
        candidates.add((alan: alan, ifade: normIfade, len: normIfade.length));
      }
    }
    candidates.sort((a, b) => b.len.compareTo(a.len));
    return candidates;
  }

  VixrexNiyetAlan? resolve(String input) {
    final normInput = VixrexNormalizer.normalize(input);
    if (normInput.trim().isEmpty) return null;
    for (final c in _adaylariOlustur()) {
      if (_niyetBaslangicindaEslesir(normInput, c.ifade)) return c.alan;
    }
    return null;
  }

  List<VixrexNiyetAlan> resolveAll(String input) {
    final normInput = VixrexNormalizer.normalize(input);
    final found = <VixrexNiyetAlan>[];
    final seen = <String>{};
    for (final c in _adaylariOlustur()) {
      if (seen.contains(c.alan.anahtar)) continue;
      if (_niyetBaslangicindaEslesir(normInput, c.ifade)) {
        found.add(c.alan);
        seen.add(c.alan.anahtar);
      }
    }
    return found;
  }
}

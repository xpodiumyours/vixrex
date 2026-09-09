import 'package:vixrex/config/vixrex_niyet_sozlugu.g.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_normalizer.dart';

/// 46 alan sözlüğü üzerinden eş-anlam ile alan bulur.
/// Kural: en uzun eş-anlam önce + gerçek kelime başlangıcı.
/// Deterministik, AI yok, Next.js ile aynı algoritma olmalı.
class VixrexIntentResolver {
  const VixrexIntentResolver();

  /// Türkçe ekler için SON sınırı katı değildir ("instagram" →
  /// "instagramımı" eşleşebilir); fakat başlangıç gerçek kelime başlangıcı
  /// olmalıdır. Böylece kısa "il" eş-anlamı "ailece" içinden çıkmaz.
  bool _niyetBaslangicindaEslesir(String normInput, String normEa) {
    var from = 0;
    while (from <= normInput.length - normEa.length) {
      final idx = normInput.indexOf(normEa, from);
      if (idx < 0) return false;
      if (idx == 0 || !RegExp(r'[a-z0-9]').hasMatch(normInput[idx - 1])) {
        return true;
      }
      from = idx + 1;
    }
    return false;
  }

  /// Tüm sözlüğe göre en iyi eşleşen alanı döner, yoksa null.
  /// `input` serbest cümle, Türkçe normalize ile eşleştirilir.
  VixrexNiyetAlan? resolve(String input) {
    final normInput = VixrexNormalizer.normalize(input);
    if (normInput.trim().isEmpty) return null;

    final candidates = <({VixrexNiyetAlan alan, String esAnlam, int len})>[];
    for (final alan in vixrexNiyetSozlugu) {
      for (final ea in alan.esAnlamlar) {
        final normEa = VixrexNormalizer.normalize(ea);
        if (normEa.trim().isEmpty) continue;
        candidates.add((alan: alan, esAnlam: normEa, len: normEa.length));
      }
    }
    candidates.sort((a, b) => b.len.compareTo(a.len));

    for (final c in candidates) {
      if (_niyetBaslangicindaEslesir(normInput, c.esAnlam)) return c.alan;
    }
    return null;
  }

  /// Aynı cümlede birden fazla alan geçiyorsa hepsini uzunluk önceliğiyle döner.
  List<VixrexNiyetAlan> resolveAll(String input) {
    final normInput = VixrexNormalizer.normalize(input);
    final found = <VixrexNiyetAlan>[];
    final seen = <String>{};
    final candidates = <({VixrexNiyetAlan alan, String esAnlam, int len})>[];
    for (final alan in vixrexNiyetSozlugu) {
      for (final ea in alan.esAnlamlar) {
        final normEa = VixrexNormalizer.normalize(ea);
        if (normEa.trim().isEmpty) continue;
        candidates.add((
          alan: alan,
          esAnlam: normEa,
          len: normEa.length,
        ));
      }
    }
    candidates.sort((a, b) => b.len.compareTo(a.len));
    for (final c in candidates) {
      if (seen.contains(c.alan.anahtar)) continue;
      if (_niyetBaslangicindaEslesir(normInput, c.esAnlam)) {
        found.add(c.alan);
        seen.add(c.alan.anahtar);
      }
    }
    return found;
  }
}

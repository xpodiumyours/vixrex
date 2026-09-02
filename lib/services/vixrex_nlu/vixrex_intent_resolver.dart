import 'package:vixrex/config/vixrex_niyet_sozlugu.g.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_normalizer.dart';

/// 46 alan sözlüğü üzerinden `esAnlamlar` contains ile alan bulur.
/// Kural: en uzun eş-anlam önce (örn. "işletme adı" > "ad" çakışmasını çözer).
/// Deterministik, AI yok, Next.js ile aynı algoritma olmalı.
class VixrexIntentResolver {
  const VixrexIntentResolver();

  /// Tüm sözlüğe göre en iyi eşleşen alanı döner, yoksa null.
  /// `input` serbest cümle, Türkçe normalize ile eşleştirilir.
  VixrexNiyetAlan? resolve(String input) {
    final normInput = VixrexNormalizer.normalize(input);
    if (normInput.trim().isEmpty) return null;

    // Tüm eş-anlamları (alan, eşAnlam) olarak düzleştir ve uzunluğa göre sırala.
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
      if (normInput.contains(c.esAnlam)) return c.alan;
    }
    return null;
  }

  /// Aynı cümlede birden fazla alan geçiyorsa hepsini uzunluk önceliğiyle döner.
  /// Faz 3 çok-alanlı destek için; Faz 1 tek alan için `resolve` yeterli.
  List<VixrexNiyetAlan> resolveAll(String input) {
    final normInput = VixrexNormalizer.normalize(input);
    final found = <VixrexNiyetAlan>[];
    final seen = <String>{};
    final candidates = <({VixrexNiyetAlan alan, String esAnlam, int len})>[];
    for (final alan in vixrexNiyetSozlugu) {
      for (final ea in alan.esAnlamlar) {
        candidates.add((
          alan: alan,
          esAnlam: VixrexNormalizer.normalize(ea),
          len: VixrexNormalizer.normalize(ea).length
        ));
      }
    }
    candidates.sort((a, b) => b.len.compareTo(a.len));
    for (final c in candidates) {
      if (seen.contains(c.alan.anahtar)) continue;
      if (normInput.contains(c.esAnlam)) {
        found.add(c.alan);
        seen.add(c.alan.anahtar);
      }
    }
    return found;
  }
}

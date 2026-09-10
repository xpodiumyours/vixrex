import 'package:vixrex/config/vixrex_niyet_sozlugu.g.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_normalizer.dart';

class _NiyetEslesmesi {
  final int start;
  final int end;

  const _NiyetEslesmesi(this.start, this.end);
}

/// 46 alan sözlüğü üzerinden eş-anlam + sözlük örneği ile alan bulur.
/// Deterministik, AI yok, Next.js ile aynı algoritma olmalı.
class VixrexIntentResolver {
  const VixrexIntentResolver();

  static const String _araIsimEki =
      r'(?:m|im|um|in|un|min|mun|imin|umun|nin|nun|imiz|umuz|iniz|unuz|imizin|umuzun|inizin|unuzun|larin|lerin)?';

  bool _ortusuyorMu(
    _NiyetEslesmesi aday,
    List<_NiyetEslesmesi> doluAraliklar,
  ) {
    return doluAraliklar.any(
      (dolu) => aday.start < dolu.end && aday.end > dolu.start,
    );
  }

  _NiyetEslesmesi? _tamIfadeEslesmesiBul(
    String normInput,
    String normIfade,
    List<_NiyetEslesmesi> doluAraliklar,
  ) {
    var from = 0;
    while (from <= normInput.length - normIfade.length) {
      final idx = normInput.indexOf(normIfade, from);
      if (idx < 0) return null;
      final startOk =
          idx == 0 || !RegExp(r'[a-z0-9]').hasMatch(normInput[idx - 1]);
      final aday = _NiyetEslesmesi(idx, idx + normIfade.length);
      if (startOk && !_ortusuyorMu(aday, doluAraliklar)) return aday;
      from = idx + 1;
    }
    return null;
  }

  /// Türkçede çok kelimeli isim öbekleri doğal konuşmada ek alır:
  /// "dükkan adı" -> "dükkanın adı", "ürün başlığı" ->
  /// "ürünlerin başlığı". Yalnız ara token >=4 karakterse kontrollü ek
  /// toleransı açılır; `il`, `tel`, `ig` gibi kısa/riskli alias'lar genişlemez.
  _NiyetEslesmesi? _ekliCokKelimeEslesmesiBul(
    String normInput,
    String normIfade,
    List<_NiyetEslesmesi> doluAraliklar,
  ) {
    final tokens = normIfade
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (tokens.length < 2) return null;

    final body = tokens.asMap().entries.map((entry) {
      final i = entry.key;
      final token = entry.value;
      final kok = RegExp.escape(token);
      if (i < tokens.length - 1 &&
          RegExp(r'^[a-z0-9]+$').hasMatch(token) &&
          token.length >= 4) {
        return '$kok$_araIsimEki';
      }
      return kok;
    }).join(r'\s+');

    final re = RegExp('(^|[^a-z0-9])($body)');
    for (final m in re.allMatches(normInput)) {
      final prefix = m.group(1) ?? '';
      final matched = m.group(2);
      if (matched == null) continue;
      final start = m.start + prefix.length;
      final aday = _NiyetEslesmesi(start, start + matched.length);
      if (!_ortusuyorMu(aday, doluAraliklar)) return aday;
    }
    return null;
  }

  /// Önce mevcut düz eşleşme, yalnız o yoksa kontrollü Türkçe iyelik/genitif
  /// varyasyonu denenir. Böylece eski eşleşme önceliği korunur.
  _NiyetEslesmesi? _niyetEslesmesiBul(
    String normInput,
    String normIfade, [
    List<_NiyetEslesmesi> doluAraliklar = const [],
  ]) {
    return _tamIfadeEslesmesiBul(
          normInput,
          normIfade,
          doluAraliklar,
        ) ??
        _ekliCokKelimeEslesmesiBul(
          normInput,
          normIfade,
          doluAraliklar,
        );
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
        sabit =
            ornek
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
      if (_niyetEslesmesiBul(normInput, c.ifade) != null) return c.alan;
    }
    return null;
  }

  List<VixrexNiyetAlan> resolveAll(String input) {
    final normInput = VixrexNormalizer.normalize(input);
    final found = <VixrexNiyetAlan>[];
    final seen = <String>{};
    final doluAraliklar = <_NiyetEslesmesi>[];

    for (final c in _adaylariOlustur()) {
      if (seen.contains(c.alan.anahtar)) continue;
      final eslesme = _niyetEslesmesiBul(normInput, c.ifade, doluAraliklar);
      if (eslesme == null) continue;

      found.add(c.alan);
      seen.add(c.alan.anahtar);
      doluAraliklar.add(eslesme);
    }
    return found;
  }
}

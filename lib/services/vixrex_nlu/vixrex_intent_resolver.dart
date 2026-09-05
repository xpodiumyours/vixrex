import 'package:vixrex/config/vixrex_matcher_contract.g.dart';
import 'package:vixrex/config/vixrex_niyet_sozlugu.g.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_normalizer.dart';

class VixrexIntentMatch {
  final VixrexNiyetAlan alan;
  final String matchedAlias;
  final String matchClass;
  final int startToken;
  final int endToken;

  const VixrexIntentMatch({
    required this.alan,
    required this.matchedAlias,
    required this.matchClass,
    required this.startToken,
    required this.endToken,
  });
}

class _Candidate extends VixrexIntentMatch {
  final int aliasLength;
  final int tokenCount;

  const _Candidate({
    required super.alan,
    required super.matchedAlias,
    required super.matchClass,
    required super.startToken,
    required super.endToken,
    required this.aliasLength,
    required this.tokenCount,
  });
}

/// 46 alan sözlüğü üzerinden token/phrase sınırında deterministik alan bulur.
/// Serbest substring yasaktır; Flutter ve Next.js aynı ortak matcher kontratını kullanır.
class VixrexIntentResolver {
  const VixrexIntentResolver();

  static final List<String> _safeSuffixes = [...vixrexMatcherSafeSuffixes]
    ..sort((a, b) => b.length.compareTo(a.length));

  static List<String> _tokenize(String text) {
    final normalized = VixrexNormalizer.normalize(text);
    return RegExp(
      r'[a-z0-9]+',
    ).allMatches(normalized).map((m) => m.group(0)!).toList(growable: false);
  }

  static int _classRank(String matchClass) {
    switch (matchClass) {
      case 'exact_phrase':
        return 3;
      case 'exact_token':
        return 2;
      case 'inflected_safe':
        return 1;
      default:
        return 0;
    }
  }

  static bool _isSafeInflection(String inputToken, String aliasToken) {
    if (!inputToken.startsWith(aliasToken) ||
        inputToken.length <= aliasToken.length) {
      return false;
    }
    final suffix = inputToken.substring(aliasToken.length);
    return _safeSuffixes.contains(suffix);
  }

  static List<_Candidate> _collectFormMatches(
    List<String> inputTokens,
    VixrexNiyetAlan alan,
    String form, {
    required bool allowInflected,
  }) {
    final aliasTokens = _tokenize(form);
    if (aliasTokens.isEmpty || aliasTokens.length > inputTokens.length) {
      return const <_Candidate>[];
    }

    final normalizedAliasLength = aliasTokens.join().length;
    final out = <_Candidate>[];

    for (
      var start = 0;
      start <= inputTokens.length - aliasTokens.length;
      start += 1
    ) {
      var prefixMatches = true;
      for (var offset = 0; offset < aliasTokens.length - 1; offset += 1) {
        if (inputTokens[start + offset] != aliasTokens[offset]) {
          prefixMatches = false;
          break;
        }
      }
      if (!prefixMatches) continue;

      final end = start + aliasTokens.length - 1;
      final inputLast = inputTokens[end];
      final aliasLast = aliasTokens.last;

      if (inputLast == aliasLast) {
        out.add(
          _Candidate(
            alan: alan,
            matchedAlias: form,
            matchClass: aliasTokens.length > 1 ? 'exact_phrase' : 'exact_token',
            startToken: start,
            endToken: end,
            aliasLength: normalizedAliasLength,
            tokenCount: aliasTokens.length,
          ),
        );
        continue;
      }

      if (allowInflected &&
          normalizedAliasLength >= vixrexMatcherMinInflectedAliasLength &&
          _isSafeInflection(inputLast, aliasLast)) {
        out.add(
          _Candidate(
            alan: alan,
            matchedAlias: form,
            matchClass: 'inflected_safe',
            startToken: start,
            endToken: end,
            aliasLength: normalizedAliasLength,
            tokenCount: aliasTokens.length,
          ),
        );
      }
    }

    return out;
  }

  static bool _sameScore(_Candidate a, _Candidate b) {
    return _classRank(a.matchClass) == _classRank(b.matchClass) &&
        a.tokenCount == b.tokenCount &&
        a.aliasLength == b.aliasLength;
  }

  static bool _overlaps(_Candidate a, _Candidate b) {
    return a.startToken <= b.endToken && b.startToken <= a.endToken;
  }

  static List<VixrexIntentMatch> _selectSafeMatches(
    List<_Candidate> candidates,
  ) {
    final sorted = [...candidates]..sort((a, b) {
      final rank = _classRank(b.matchClass) - _classRank(a.matchClass);
      if (rank != 0) return rank;
      final tokens = b.tokenCount - a.tokenCount;
      if (tokens != 0) return tokens;
      final length = b.aliasLength - a.aliasLength;
      if (length != 0) return length;
      final start = a.startToken - b.startToken;
      if (start != 0) return start;
      return a.alan.anahtar.compareTo(b.alan.anahtar);
    });

    final accepted = <_Candidate>[];
    for (final candidate in sorted) {
      final ambiguous = sorted.any(
        (other) =>
            !identical(other, candidate) &&
            other.alan.anahtar != candidate.alan.anahtar &&
            other.startToken == candidate.startToken &&
            other.endToken == candidate.endToken &&
            _sameScore(other, candidate),
      );
      if (ambiguous) continue;
      if (accepted.any((other) => _overlaps(other, candidate))) continue;
      accepted.add(candidate);
    }

    accepted.sort((a, b) {
      final start = a.startToken - b.startToken;
      if (start != 0) return start;
      return a.endToken - b.endToken;
    });

    return accepted
        .map(
          (candidate) => VixrexIntentMatch(
            alan: candidate.alan,
            matchedAlias: candidate.matchedAlias,
            matchClass: candidate.matchClass,
            startToken: candidate.startToken,
            endToken: candidate.endToken,
          ),
        )
        .toList(growable: false);
  }

  List<VixrexIntentMatch> resolveMatches(String input) {
    final inputTokens = _tokenize(input);
    if (inputTokens.isEmpty) return const <VixrexIntentMatch>[];

    final candidates = <_Candidate>[];
    for (final alan in vixrexNiyetSozlugu) {
      for (final alias in alan.esAnlamlar) {
        candidates.addAll(
          _collectFormMatches(inputTokens, alan, alias, allowInflected: true),
        );
      }

      final exactForms =
          vixrexMatcherExactFormsByField[alan.anahtar] ?? const <String>[];
      for (final exactForm in exactForms) {
        candidates.addAll(
          _collectFormMatches(
            inputTokens,
            alan,
            exactForm,
            allowInflected: false,
          ),
        );
      }
    }

    return _selectSafeMatches(candidates);
  }

  /// Tüm sözlüğe göre ilk güvenli eşleşen alanı döner, yoksa null.
  VixrexNiyetAlan? resolve(String input) =>
      resolveMatches(input).firstOrNull?.alan;

  /// Aynı cümledeki bağımsız güvenli alanları token sırasıyla döner.
  List<VixrexNiyetAlan> resolveAll(String input) {
    final seen = <String>{};
    final fields = <VixrexNiyetAlan>[];
    for (final match in resolveMatches(input)) {
      if (!seen.add(match.alan.anahtar)) continue;
      fields.add(match.alan);
    }
    return fields;
  }
}

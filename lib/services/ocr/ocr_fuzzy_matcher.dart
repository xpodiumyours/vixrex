/// Fuzzy ürün eşleştirme motoru.
///
/// Levenshtein ve Jaro-Winkler algoritmaları ile ML Kit hatalarını düzeltir.
/// "YAKA KISA KOLU REÇME ARA" → "YAKASI KISA KOL REÇME ARA BIYELI" eşleştirmesi.
class OcrFuzzyMatcher {
  const OcrFuzzyMatcher();

  // ─── LEVENSHTEIN MESAFESİ ──────────────────────────────────────

  /// İki string arasındaki Levenshtein mesafesi.
  /// 0 = birebir aynı, artan değer = daha farklı.
  int levenshteinDistance(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final matrix = List.generate(
      a.length + 1,
      (i) => List.generate(b.length + 1, (j) => 0),
    );

    for (int i = 0; i <= a.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= b.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[a.length][b.length];
  }

  /// Levenshtein benzerlik oranı (0.0 - 1.0).
  double levenshteinSimilarity(String a, String b) {
    if (a.isEmpty && b.isEmpty) return 1.0;
    final maxLen = a.length > b.length ? a.length : b.length;
    final distance = levenshteinDistance(a.toLowerCase(), b.toLowerCase());
    return 1.0 - (distance / maxLen);
  }

  // ─── JARO-WINKLER ──────────────────────────────────────────────

  /// Jaro benzerliği.
  double jaroSimilarity(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0.0;
    if (a == b) return 1.0;

    final shorter = a.length < b.length ? a : b;
    final longer = a.length < b.length ? b : a;

    final matchWindow = (longer.length ~/ 2) - 1;
    if (matchWindow < 0) return 0.0;

    final shorterMatches = List.filled(shorter.length, false);
    final longerMatches = List.filled(longer.length, false);

    int matches = 0;
    int transpositions = 0;

    // Eşleşmeleri bul
    for (int i = 0; i < shorter.length; i++) {
      final start = (i - matchWindow).clamp(0, longer.length);
      final end = (i + matchWindow + 1).clamp(0, longer.length);

      for (int j = start; j < end; j++) {
        if (longerMatches[j] || shorter[i] != longer[j]) continue;
        shorterMatches[i] = true;
        longerMatches[j] = true;
        matches++;
        break;
      }
    }

    if (matches == 0) return 0.0;

    // Transpozisyonları say
    int k = 0;
    for (int i = 0; i < shorter.length; i++) {
      if (!shorterMatches[i]) continue;
      while (!longerMatches[k]) {
        k++;
      }
      if (shorter[i] != longer[k]) transpositions++;
      k++;
    }

    return (matches / shorter.length +
            matches / longer.length +
            (matches - transpositions ~/ 2) / matches) /
        3.0;
  }

  /// Jaro-Winkler benzerliği (prefix bonus'u ile).
  double jaroWinklerSimilarity(
    String a,
    String b, {
    double boostThreshold = 0.7,
  }) {
    final jaro = jaroSimilarity(a, b);
    if (jaro < boostThreshold) return jaro;

    // Prefix uzunluğunu hesapla (maks 4 karakter)
    int prefix = 0;
    for (int i = 0; i < a.length && i < b.length && i < 4; i++) {
      if (a[i] == b[i]) {
        prefix++;
      } else {
        break;
      }
    }

    return jaro + prefix * 0.1 * (1 - jaro);
  }

  // ─── TOKEN SET RATIO ────────────────────────────────────────────

  /// Token set ratio: Kelimeleri sırala, kesişimi hesapla.
  double tokenSetRatio(String a, String b) {
    final tokensA = a.toLowerCase().split(RegExp(r'\s+')).toSet();
    final tokensB = b.toLowerCase().split(RegExp(r'\s+')).toSet();

    if (tokensA.isEmpty || tokensB.isEmpty) return 0.0;

    final intersection = tokensA.intersection(tokensB);
    final union = tokensA.union(tokensB);

    return intersection.length / union.length;
  }

  // ─── ANA EŞLEŞTİRME METOTU ─────────────────────────────────────

  /// OCR metnini veritabanı ürünleriyle eşleştir.
  /// En iyi eşleşmeyi ve confidence skorunu döner.
  FuzzyMatchResult findBestMatch(
    String ocrText,
    List<String> databaseProducts, {
    double threshold = 0.4,
  }) {
    if (ocrText.isEmpty || databaseProducts.isEmpty) {
      return FuzzyMatchResult.empty();
    }

    final normalizedOcr = _normalize(ocrText);
    double bestScore = 0;
    int bestIndex = -1;

    for (int i = 0; i < databaseProducts.length; i++) {
      final normalizedDb = _normalize(databaseProducts[i]);

      // Birden fazla metrik kullan, en yüksek olanı al
      final levenshteinScore = levenshteinSimilarity(
        normalizedOcr,
        normalizedDb,
      );
      final jaroWinklerScore = jaroWinklerSimilarity(
        normalizedOcr,
        normalizedDb,
      );
      final tokenScore = tokenSetRatio(normalizedOcr, normalizedDb);

      // Ağırlıklı ortalama
      final combinedScore =
          levenshteinScore * 0.3 + jaroWinklerScore * 0.4 + tokenScore * 0.3;

      if (combinedScore > bestScore) {
        bestScore = combinedScore;
        bestIndex = i;
      }
    }

    if (bestIndex == -1 || bestScore < threshold) {
      return FuzzyMatchResult.empty();
    }

    return FuzzyMatchResult(
      matchedText: databaseProducts[bestIndex],
      score: bestScore,
      levenshteinScore: levenshteinSimilarity(
        normalizedOcr,
        _normalize(databaseProducts[bestIndex]),
      ),
      jaroWinklerScore: jaroWinklerSimilarity(
        normalizedOcr,
        _normalize(databaseProducts[bestIndex]),
      ),
      tokenScore: tokenSetRatio(
        normalizedOcr,
        _normalize(databaseProducts[bestIndex]),
      ),
    );
  }

  /// Normalizasyon: Türkçe karakterleri standartlaştır, boşlukları temizle.
  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ı', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

/// Fuzzy eşleşme sonucu.
class FuzzyMatchResult {
  final String matchedText;
  final double score;
  final double levenshteinScore;
  final double jaroWinklerScore;
  final double tokenScore;

  const FuzzyMatchResult({
    required this.matchedText,
    required this.score,
    required this.levenshteinScore,
    required this.jaroWinklerScore,
    required this.tokenScore,
  });

  factory FuzzyMatchResult.empty() => const FuzzyMatchResult(
    matchedText: '',
    score: 0,
    levenshteinScore: 0,
    jaroWinklerScore: 0,
    tokenScore: 0,
  );

  bool get isEmpty => matchedText.isEmpty;
  bool get isNotEmpty => matchedText.isNotEmpty;
}

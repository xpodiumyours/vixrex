import 'dart:math';

/// Harici paket bağımlılığı olmadan fuzzy string eşleşmesi sağlayan yardımcı sınıf.
class FuzzyMatchUtils {
  /// İki metin arasındaki Levenshtein mesafesini hesaplar.
  static int levenshtein(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> prev = List<int>.generate(s2.length + 1, (i) => i);
    List<int> curr = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      curr[0] = i + 1;
      for (int j = 0; j < s2.length; j++) {
        int cost = (s1[i] == s2[j]) ? 0 : 1;
        curr[j + 1] = min(
          curr[j] + 1, // Insertion
          min(
            prev[j + 1] + 1, // Deletion
            prev[j] + cost, // Substitution
          ),
        );
      }
      prev = List<int>.from(curr);
    }
    return prev[s2.length];
  }

  /// Levenshtein mesafesine dayalı benzerlik oranı (0.0 - 1.0)
  static double similarityRatio(String s1, String s2) {
    int maxLen = max(s1.length, s2.length);
    if (maxLen == 0) return 1.0;
    int dist = levenshtein(s1, s2);
    return 1.0 - (dist / maxLen);
  }

  /// Jaro-Winkler benzerlik oranını hesaplar (0.0 - 1.0).
  static double jaroWinkler(String s1, String s2) {
    s1 = s1.trim().toLowerCase();
    s2 = s2.trim().toLowerCase();

    if (s1 == s2) return 1.0;

    int len1 = s1.length;
    int len2 = s2.length;

    if (len1 == 0 || len2 == 0) return 0.0;

    int matchDistance = (max(len1, len2) ~/ 2) - 1;
    if (matchDistance < 0) matchDistance = 0;

    List<bool> hashS1 = List<bool>.filled(len1, false);
    List<bool> hashS2 = List<bool>.filled(len2, false);

    int matches = 0;
    int transpositions = 0;

    for (int i = 0; i < len1; i++) {
      int start = max(0, i - matchDistance);
      int end = min(len2 - 1, i + matchDistance);

      for (int j = start; j <= end; j++) {
        if (!hashS2[j] && s1[i] == s2[j]) {
          hashS1[i] = true;
          hashS2[j] = true;
          matches++;
          break;
        }
      }
    }

    if (matches == 0) return 0.0;

    int k = 0;
    for (int i = 0; i < len1; i++) {
      if (hashS1[i]) {
        while (!hashS2[k]) {
          k++;
        }
        if (s1[i] != s2[k]) {
          transpositions++;
        }
        k++;
      }
    }

    double jaro = ((matches / len1) + (matches / len2) + ((matches - transpositions / 2) / matches)) / 3.0;

    // Winkler prefix scale
    double p = 0.1;
    int prefixLen = 0;
    for (int i = 0; i < min(4, min(len1, len2)); i++) {
      if (s1[i] == s2[i]) {
        prefixLen++;
      } else {
        break;
      }
    }

    return jaro + (prefixLen * p * (1.0 - jaro));
  }

  /// Token Set Ratio (FuzzyWuzzy benzeri token seti tabanlı oran).
  /// Metinlerin kelime kümeleri arasındaki kesişim ve farkları inceleyerek benzerlik skoru üretir (0.0 - 1.0).
  static double tokenSetRatio(String s1, String s2) {
    s1 = s1.trim().toLowerCase();
    s2 = s2.trim().toLowerCase();

    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final tokens1 = s1.split(RegExp(r'\s+')).toSet();
    final tokens2 = s2.split(RegExp(r'\s+')).toSet();

    final intersection = tokens1.intersection(tokens2);
    final diff1to2 = tokens1.difference(tokens2);
    final diff2to1 = tokens2.difference(tokens1);

    final sortedIntersection = intersection.join(' ');
    final sortedDiff1 = (Set<String>.from(intersection)..addAll(diff1to2)).join(' ');
    final sortedDiff2 = (Set<String>.from(intersection)..addAll(diff2to1)).join(' ');

    double r1 = similarityRatio(sortedIntersection, sortedDiff1);
    double r2 = similarityRatio(sortedIntersection, sortedDiff2);
    double r3 = similarityRatio(sortedDiff1, sortedDiff2);

    return max(r1, max(r2, r3));
  }
}

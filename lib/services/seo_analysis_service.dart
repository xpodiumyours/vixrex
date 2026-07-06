class SeoAnalysisResult {
  final int score;
  final List<String> recommendations;

  const SeoAnalysisResult({
    required this.score,
    required this.recommendations,
  });
}

class SeoAnalysisService {
  const SeoAnalysisService();

  SeoAnalysisResult analyze({
    required String title,
    required String summary,
    required String content,
    required String topic,
    required String city,
    required bool hasCover,
  }) {
    int score = 0;
    final recs = <String>[];

    final cleanTitle = title.trim();
    final cleanSummary = summary.trim();
    final cleanContent = content.trim();
    final cleanTopic = topic.trim().toLowerCase();
    final cleanCity = city.trim().toLowerCase();

    // 1. Title length checks (Max 20 pts)
    if (cleanTitle.isEmpty) {
      recs.add("• Başlık ekleyin (Tavsiye: 30-60 karakter)");
    } else if (cleanTitle.length < 30) {
      score += 10;
      recs.add(
        "• Başlık çok kısa (${cleanTitle.length} karakter). Arama motorları için en az 30 karakter yapın.",
      );
    } else if (cleanTitle.length > 60) {
      score += 10;
      recs.add(
        "• Başlık çok uzun (${cleanTitle.length} karakter). 60 karakteri aşmamalıdır.",
      );
    } else {
      score += 20;
    }

    // 2. Summary length checks (Max 20 pts)
    if (cleanSummary.isEmpty) {
      recs.add("• Kısa özet yazın (Tavsiye: 80-160 karakter)");
    } else if (cleanSummary.length < 80) {
      score += 10;
      recs.add(
        "• Özet çok kısa (${cleanSummary.length} karakter). En az 80 karakter yapın.",
      );
    } else if (cleanSummary.length > 160) {
      score += 10;
      recs.add(
        "• Özet çok uzun (${cleanSummary.length} karakter). 160 karakteri aşmamalıdır.",
      );
    } else {
      score += 20;
    }

    // 3. Word count checks (Max 20 pts)
    final words = cleanContent.isEmpty ? 0 : cleanContent.split(RegExp(r'\s+')).length;
    if (words == 0) {
      recs.add("• İçerik metni yazın (En az 300 kelime)");
    } else if (words < 150) {
      score += 5;
      recs.add(
        "• İçerik çok yetersiz ($words kelime). En az 300 kelime olmalı.",
      );
    } else if (words < 300) {
      score += 12;
      recs.add(
        "• İçerik geliştirilebilir ($words kelime). En az 300 kelime önerilir.",
      );
    } else {
      score += 20;
    }

    // 4. Cover Image check (Max 15 pts)
    if (hasCover) {
      score += 15;
    } else {
      recs.add("• Yazıya bir kapak fotoğrafı ekleyin.");
    }

    // 5. SEO Topic check (Max 15 pts)
    if (cleanTopic.isNotEmpty) {
      if (cleanTitle.toLowerCase().contains(cleanTopic) ||
          cleanContent.toLowerCase().contains(cleanTopic)) {
        score += 10;
      } else {
        recs.add(
          "• Hedef kelimeyi ('$cleanTopic') başlıkta veya yazının içinde geçirin.",
        );
      }
    } else {
      recs.add(
        "• Arama motorlarında öne çıkmak için hedef anahtar kelime belirleyin.",
      );
    }

    // 6. Target City check (Max 10 pts)
    if (cleanCity.isNotEmpty) {
      if (cleanTitle.toLowerCase().contains(cleanCity) ||
          cleanContent.toLowerCase().contains(cleanCity)) {
        score += 10;
      } else {
        recs.add(
          "• Yerel aramalarda çıkmak için hedef şehri ('$cleanCity') başlık veya içerikte kullanın.",
        );
      }
    }

    return SeoAnalysisResult(score: score, recommendations: recs);
  }
}

import 'package:flutter/material.dart';
import 'package:vixrex/theme/app_colors.dart';

class BlogSeoPanel extends StatelessWidget {
  final int seoScore;
  final List<String> seoRecommendations;

  const BlogSeoPanel({
    super.key,
    required this.seoScore,
    required this.seoRecommendations,
  });

  @override
  Widget build(BuildContext context) {
    Color scoreColor = Colors.orange;
    if (seoScore >= 80) {
      scoreColor = Colors.green;
    } else if (seoScore >= 40) {
      scoreColor = Colors.amber.shade700;
    }

    return Container(
      padding: const EdgeInsets.all(AppColors.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppColors.radius20),
        border: Border.all(color: AppColors.cardBorderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.analytics_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Canlı SEO Analizi',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppColors.spacing12,
                  vertical: AppColors.spacing8,
                ),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppColors.radius20),
                  border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Skor: $seoScore / 100',
                  style: TextStyle(
                    color: scoreColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppColors.spacing12),
          if (seoRecommendations.isEmpty)
            const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
                SizedBox(width: 6),
                Text(
                  'Harika! Yazınız mükemmel şekilde optimize edildi.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          else ...[
            const Text(
              'Geliştirme Tavsiyeleri:',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.softText,
              ),
            ),
            const SizedBox(height: AppColors.spacing8),
            ...seoRecommendations.take(3).map(
                  (rec) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text(
                      rec,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.mutedText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            if (seoRecommendations.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Text(
                  've ${seoRecommendations.length - 3} tavsiye daha var...',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.mutedText,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

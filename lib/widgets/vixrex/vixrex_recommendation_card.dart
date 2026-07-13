import 'package:flutter/material.dart';
import 'package:vixrex/models/chat_message.dart';
import 'package:vixrex/services/vixrex_guidance_service.dart';
import 'package:vixrex/theme/app_colors.dart';

class VixRexRecommendationCard extends StatelessWidget {
  final VixRexRecommendation recommendation;
  final bool isRecommendationDismissed;
  final ValueChanged<String> onDismissRecommendation;
  final ValueChanged<VixRexAction> onAction;

  const VixRexRecommendationCard({
    super.key,
    required this.recommendation,
    required this.isRecommendationDismissed,
    required this.onDismissRecommendation,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    if (isRecommendationDismissed) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: AppColors.mutedText,
              size: 20,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Bu öneri kapatıldı. Durumun değiştiğinde Vixrex yeni adımı gösterecek.',
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 12,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sıradaki adım',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recommendation.title,
                      style: const TextStyle(
                        color: AppColors.darkText,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => onDismissRecommendation(recommendation.id),
                tooltip: 'Öneriyi kapat',
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.mutedText,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            recommendation.description,
            style: const TextStyle(
              color: AppColors.mutedText,
              fontSize: 12,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => onAction(recommendation.action),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text(recommendation.buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}

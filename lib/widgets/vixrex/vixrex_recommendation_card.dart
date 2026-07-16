import 'package:flutter/material.dart';
import 'package:vixrex/models/chat_message.dart';
import 'package:vixrex/services/vixrex_guidance_service.dart';
import 'package:vixrex/theme/app_colors.dart';

/// Sıradaki adımı ince, tek-CTA'lı bir kart olarak gösterir.
/// Motor: [VixRexGuidanceService] — aksiyon mevcut [VixRexAction] handler'larına gider.
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: AppColors.mutedText,
              size: 15,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Bu öneri kapatıldı. Durumun değiştiğinde Vixrex yeni adımı gösterecek.',
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 11,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            'SIRADAKİ ADIM',
            style: TextStyle(
              color: AppColors.mutedText,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withAlpha(90)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recommendation.title,
                      style: const TextStyle(
                        color: AppColors.darkText,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      recommendation.description,
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 28,
                      child: ElevatedButton(
                        onPressed: () => onAction(recommendation.action),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: const Color(0xFF00181A),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 11),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                        child: Text(
                          recommendation.buttonLabel,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => onDismissRecommendation(recommendation.id),
                tooltip: 'Öneriyi kapat',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.mutedText,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

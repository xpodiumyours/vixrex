import 'package:flutter/material.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/theme/app_text_styles.dart';

/// Formun üstündeki tamamlanma ölçeri.
class VitrinCompletionMeter extends StatelessWidget {
  const VitrinCompletionMeter({
    super.key,
    required this.percent,
    this.missingRequiredLabels = const [],
  });

  final int percent;
  final List<String> missingRequiredLabels;

  String get _hint {
    if (missingRequiredLabels.isEmpty) {
      return 'Yayına çıkmak için gereken tüm alanlar dolu.';
    }
    if (missingRequiredLabels.length == 1) {
      return 'Yayına çıkmak için ${missingRequiredLabels.first} alanı kaldı.';
    }
    final last = missingRequiredLabels.last;
    final rest = missingRequiredLabels
        .sublist(0, missingRequiredLabels.length - 1)
        .join(', ');
    return 'Yayına çıkmak için $rest ve $last alanları kaldı.';
  }

  @override
  Widget build(BuildContext context) {
    final clamped = percent.clamp(0, 100);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppColors.spacing24,
        AppColors.spacing20,
        AppColors.spacing24,
        AppColors.spacing16,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.blueSurface)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Expanded(
                child: Text('Vitrinim', style: AppTextStyles.sectionTitle),
              ),
              Text(
                '%$clamped hazır',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppColors.spacing12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: clamped / 100,
              minHeight: 6,
              backgroundColor: AppColors.surfaceSoft,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppColors.spacing12),
          Text(_hint, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

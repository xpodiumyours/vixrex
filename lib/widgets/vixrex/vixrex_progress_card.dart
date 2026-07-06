import 'package:flutter/material.dart';
import 'package:vixrex/services/vixrex_profile_snapshot.dart';
import 'package:vixrex/theme/app_colors.dart';

class VixRexProgressCard extends StatelessWidget {
  final VixRexProfileSnapshot? snapshot;
  final VixRexJourneyPhase phase;
  final bool hasShared;

  const VixRexProgressCard({
    super.key,
    required this.snapshot,
    required this.phase,
    required this.hasShared,
  });

  @override
  Widget build(BuildContext context) {
    final completedRequiredSteps = snapshot?.completedRequiredStepCount ?? 0;
    final isPublished = snapshot?.isPublished ?? false;
    final completedSteps = completedRequiredSteps +
        (isPublished ? 1 : 0) +
        (isPublished && hasShared ? 1 : 0);
    const totalSteps = VixRexProfileSnapshot.requiredStepCount + 2;
    final progress = completedSteps / totalSteps;
    final phaseLabel = switch (phase) {
      VixRexJourneyPhase.setup => 'Kurulum',
      VixRexJourneyPhase.publish => 'Yayınlama',
      VixRexJourneyPhase.share => 'Duyurma',
      VixRexJourneyPhase.improve => 'Geliştirme',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.route_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Aşama: $phaseLabel',
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$completedSteps/$totalSteps',
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: AppColors.surfaceSoft,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

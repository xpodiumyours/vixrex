import 'package:flutter/material.dart';
import 'package:vitrinx/models/chat_message.dart';
import 'package:vitrinx/services/xrex_guidance_service.dart';
import 'package:vitrinx/services/xrex_profile_snapshot.dart';
import 'package:vitrinx/theme/app_colors.dart';

const double _xrexHeroMinSize = 150;
const double _xrexHeroMaxSize = 200;

class XrexScreen extends StatelessWidget {
  final XrexProfileSnapshot? snapshot;
  final bool hasShared;
  final String? dismissedRecommendationId;
  final ValueChanged<XrexAction> onAction;
  final ValueChanged<String> onDismissRecommendation;

  const XrexScreen({
    super.key,
    required this.snapshot,
    required this.hasShared,
    required this.dismissedRecommendationId,
    required this.onAction,
    required this.onDismissRecommendation,
  });

  @override
  Widget build(BuildContext context) {
    final recommendation = XrexGuidanceService.recommendationFor(
      snapshot: snapshot,
      hasShared: hasShared,
    );
    final isRecommendationDismissed =
        dismissedRecommendationId == recommendation.id;
    final screenSize = MediaQuery.sizeOf(context);
    final heightBasedSize = screenSize.height * 0.24;
    final widthBasedSize = screenSize.width * 0.56;
    final availableSize =
        heightBasedSize < widthBasedSize ? heightBasedSize : widthBasedSize;
    final mascotSize = availableSize
        .clamp(_xrexHeroMinSize, _xrexHeroMaxSize)
        .toDouble();

    return Scaffold(
      backgroundColor: AppColors.bgEditor,
      appBar: AppBar(
        title: const Text(
          'X-rex Yapay Zekâ',
          style: TextStyle(
            color: AppColors.darkText,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.bgEditor,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Siber Ejderha Avatar / İkon Alanı
              Container(
                width: mascotSize,
                height: mascotSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(30),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/xrex_mascot.png',
                    width: mascotSize,
                    height: mascotSize,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'X-rex',
                style: TextStyle(
                  color: AppColors.darkText,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'VitrinX Yapay Zekâ Asistanı',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Vitrininizi, mağaza kartlarınızı ve ürün sunumlarınızı optimize etmek için buradayım.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 36),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildProgressCard(recommendation.phase),
                    const SizedBox(height: 12),
                    if (isRecommendationDismissed)
                      _buildDismissedCard()
                    else
                      _buildRecommendationCard(recommendation),
                    const SizedBox(height: 24),
                    const Text(
                      'Yakında',
                      style: TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildSuggestionCard(
                      icon: Icons.analytics_outlined,
                      title: 'Vitrin kaliteni analiz et',
                      subtitle: 'Eksik alanları ve puanını optimize et.',
                    ),
                    const SizedBox(height: 12),
                    _buildSuggestionCard(
                      icon: Icons.edit_note_outlined,
                      title: 'Mağaza açıklamanı iyileştir',
                      subtitle:
                          'Yapay zekâ ile dikkat çekici bir açıklama yaz.',
                    ),
                    const SizedBox(height: 12),
                    _buildSuggestionCard(
                      icon: Icons.style_outlined,
                      title: 'Ürün kartı önerileri hazırla',
                      subtitle:
                          'Ürünlerinin sunumunu ve fiyatlarını değerlendir.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard(XrexJourneyPhase phase) {
    final completedRequiredSteps = snapshot?.completedRequiredStepCount ?? 0;
    final isPublished = snapshot?.isPublished ?? false;
    final completedSteps = completedRequiredSteps +
        (isPublished ? 1 : 0) +
        (isPublished && hasShared ? 1 : 0);
    const totalSteps = XrexProfileSnapshot.requiredStepCount + 2;
    final progress = completedSteps / totalSteps;
    final phaseLabel = switch (phase) {
      XrexJourneyPhase.setup => 'Kurulum',
      XrexJourneyPhase.publish => 'Yayınlama',
      XrexJourneyPhase.share => 'Duyurma',
      XrexJourneyPhase.improve => 'Geliştirme',
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

  Widget _buildRecommendationCard(XrexRecommendation recommendation) {
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

  Widget _buildDismissedCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_outline, color: AppColors.mutedText, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Bu öneri kapatıldı. Durumun değiştiğinde X-rex yeni adımı gösterecek.',
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

  Widget _buildSuggestionCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              'Yakında',
              style: TextStyle(
                color: AppColors.mutedText,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:vitrinx/models/chat_message.dart';
import 'package:vitrinx/services/xrex_guidance_service.dart';
import 'package:vitrinx/services/xrex_promotion_service.dart';
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
  final ValueChanged<String> onCopyPromotionText;
  final ValueChanged<String> onSharePromotionText;

  const XrexScreen({
    super.key,
    required this.snapshot,
    required this.hasShared,
    required this.dismissedRecommendationId,
    required this.onAction,
    required this.onDismissRecommendation,
    required this.onCopyPromotionText,
    required this.onSharePromotionText,
  });

  @override
  Widget build(BuildContext context) {
    final recommendation = XrexGuidanceService.recommendationFor(
      snapshot: snapshot,
      hasShared: hasShared,
    );
    final qualityReport = XrexGuidanceService.qualityReportFor(
      snapshot: snapshot,
      hasShared: hasShared,
    );
    final nextQualityStep = qualityReport.nextImprovement;
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
          'X-rex Rehber',
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
                'VitrinX Rehberi',
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
                  'Vitrinini kurman, yayınlaman ve müşterilerine duyurman için sıradaki doğru adımı gösteririm.',
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
                      'Vitrin araçları',
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
                      subtitle: nextQualityStep == null
                          ? 'Puanın 100/100 • Tüm kalite adımları tamamlandı.'
                          : 'Puanın ${qualityReport.score}/100 • Öncelik: ${nextQualityStep.label}',
                      onTap: () => _showQualityReport(context, qualityReport),
                    ),
                    const SizedBox(height: 12),
                    _buildSuggestionCard(
                      icon: Icons.auto_fix_high_outlined,
                      title: 'Kategoriye özel hazır görseller',
                      subtitle: snapshot?.autoFillCompleted == true
                          ? 'Hazır görselleri zaten kullandın. İstersen değiştirebilirsin.'
                          : 'İşletme kategorine özel telifsiz görsellerle vitrinini doldur.',
                      onTap: () => onAction(XrexAction.scrollToCategory),
                    ),
                    const SizedBox(height: 12),
                    _buildSuggestionCard(
                      icon: Icons.edit_note_outlined,
                      title: 'Mağaza açıklamanı iyileştir',
                      subtitle: snapshot?.descriptionCompleted == true
                          ? 'Açıklaman hazır. İstersen güncelleyebilirsin.'
                          : 'İşletmeni anlatan kısa bir açıklama ekle.',
                      onTap: () => onAction(XrexAction.scrollToDesc),
                    ),
                    const SizedBox(height: 12),
                    _buildSuggestionCard(
                      icon: Icons.style_outlined,
                      title: 'Ürün kartı önerileri hazırla',
                      subtitle: snapshot?.catalogCompleted == true
                          ? 'Ürün ve hizmetlerini gözden geçir.'
                          : 'İlk ürününü veya hizmetini ekle.',
                      onTap: () => onAction(XrexAction.scrollToProducts),
                    ),
                    const SizedBox(height: 12),
                    _buildSuggestionCard(
                      icon: Icons.campaign_outlined,
                      title: 'Tanıtım paketi hazırla',
                      subtitle: snapshot?.isPublished == true
                          ? 'Düzenlenebilir paylaşım metinleri oluştur.'
                          : 'Tanıtım metni için önce vitrinini yayınla.',
                      onTap: () {
                        if (snapshot?.isPublished == true) {
                          _showPromotionPackage(context);
                        } else {
                          onAction(XrexAction.openVitrim);
                        }
                      },
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
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
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
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.mutedText,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showQualityReport(
    BuildContext context,
    XrexQualityReport report,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final next = report.nextImprovement;
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.82,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Vitrin kalite özeti',
                          style: TextStyle(
                            color: AppColors.darkText,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Text(
                        '${report.score}/100',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    next == null
                        ? 'Tüm kalite adımları tamamlandı.'
                        : 'Öncelikli eksik: ${next.label}',
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      itemCount: report.items.length,
                      separatorBuilder: (_, __) =>
                          const Divider(color: AppColors.border, height: 1),
                      itemBuilder: (context, index) {
                        final item = report.items[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            item.completed
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: item.completed
                                ? AppColors.primary
                                : AppColors.mutedText,
                          ),
                          title: Text(
                            item.label,
                            style: const TextStyle(
                              color: AppColors.darkText,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          trailing: Text(
                            '${item.completed ? item.points : 0}/${item.points}',
                            style: TextStyle(
                              color: item.completed
                                  ? AppColors.primary
                                  : AppColors.mutedText,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          onTap: item.completed
                              ? null
                              : () {
                                  Navigator.pop(sheetContext);
                                  onAction(item.action);
                                },
                        );
                      },
                    ),
                  ),
                  if (next != null) ...[
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        onAction(next.action);
                      },
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: Text('${next.label} alanını aç'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showPromotionPackage(BuildContext context) async {
    final drafts = XrexPromotionService.draftsFor(snapshot);
    var selectedIndex = 1;
    final controller = TextEditingController(text: drafts[selectedIndex].text);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  20 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'X-rex tanıtım paketi',
                        style: TextStyle(
                          color: AppColors.darkText,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Bir ton seç, metni düzenle ve hazır olduğunda paylaş.',
                        style: TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(drafts.length, (index) {
                          final draft = drafts[index];
                          return ChoiceChip(
                            label: Text(draft.label),
                            selected: selectedIndex == index,
                            onSelected: (_) {
                              setSheetState(() {
                                selectedIndex = index;
                                controller.text = draft.text;
                              });
                            },
                          );
                        }),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: controller,
                        minLines: 5,
                        maxLines: 8,
                        maxLength: 600,
                        style: const TextStyle(color: AppColors.darkText),
                        decoration: const InputDecoration(
                          labelText: 'Tanıtım metni',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          final text = controller.text.trim();
                          if (text.isEmpty) return;
                          Navigator.pop(sheetContext);
                          onCopyPromotionText(text);
                        },
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: const Text('Metni kopyala'),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: () {
                          final text = controller.text.trim();
                          if (text.isEmpty) return;
                          Navigator.pop(sheetContext);
                          onSharePromotionText(text);
                        },
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: const Text('WhatsApp\'ta paylaş'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    controller.dispose();
  }
}

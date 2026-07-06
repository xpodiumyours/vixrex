import 'package:flutter/material.dart';
import 'package:vixrex/models/chat_message.dart';
import 'package:vixrex/services/vixrex_guidance_service.dart';
import 'package:vixrex/services/vixrex_promotion_service.dart';
import 'package:vixrex/services/vixrex_profile_snapshot.dart';
import 'package:vixrex/theme/app_colors.dart';

import 'package:vixrex/widgets/vixrex/vixrex_hero.dart';
import 'package:vixrex/widgets/vixrex/vixrex_progress_card.dart';
import 'package:vixrex/widgets/vixrex/vixrex_recommendation_card.dart';

const double _vixrexHeroMinSize = 150;
const double _vixrexHeroMaxSize = 200;

class VixRexScreen extends StatelessWidget {
  final VixRexProfileSnapshot? snapshot;
  final bool hasShared;
  final String? dismissedRecommendationId;
  final ValueChanged<VixRexAction> onAction;
  final ValueChanged<String> onDismissRecommendation;
  final ValueChanged<String> onCopyPromotionText;
  final ValueChanged<String> onSharePromotionText;

  const VixRexScreen({
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
    final recommendation = VixRexGuidanceService.recommendationFor(
      snapshot: snapshot,
      hasShared: hasShared,
    );
    final qualityReport = VixRexGuidanceService.qualityReportFor(
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
        .clamp(_vixrexHeroMinSize, _vixrexHeroMaxSize)
        .toDouble();

    return Scaffold(
      backgroundColor: AppColors.bgEditor,
      appBar: AppBar(
        title: const Text(
          'VixRex Rehber',
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
              VixRexHero(mascotSize: mascotSize),
              const SizedBox(height: 36),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    VixRexProgressCard(
                      snapshot: snapshot,
                      phase: recommendation.phase,
                      hasShared: hasShared,
                    ),
                    const SizedBox(height: 12),
                    VixRexRecommendationCard(
                      recommendation: recommendation,
                      isRecommendationDismissed: isRecommendationDismissed,
                      onDismissRecommendation: onDismissRecommendation,
                      onAction: onAction,
                    ),
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
                      onTap: () => onAction(VixRexAction.scrollToCategory),
                    ),
                    const SizedBox(height: 12),
                    _buildSuggestionCard(
                      icon: Icons.edit_note_outlined,
                      title: 'Mağaza açıklamanı iyileştir',
                      subtitle: snapshot?.descriptionCompleted == true
                          ? 'Açıklaman hazır. İstersen güncelleyebilirsin.'
                          : 'İşletmeni anlatan kısa bir açıklama ekle.',
                      onTap: () => onAction(VixRexAction.scrollToDesc),
                    ),
                    const SizedBox(height: 12),
                    _buildSuggestionCard(
                      icon: Icons.style_outlined,
                      title: 'Ürün kartı önerileri hazırla',
                      subtitle: snapshot?.catalogCompleted == true
                          ? 'Ürün ve hizmetlerini gözden geçir.'
                          : 'İlk ürününü veya hizmetini ekle.',
                      onTap: () => onAction(VixRexAction.scrollToProducts),
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
                          onAction(VixRexAction.openVitrim);
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
    VixRexQualityReport report,
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
    final drafts = VixRexPromotionService.draftsFor(snapshot);
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
                        'VixRex tanıtım paketi',
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

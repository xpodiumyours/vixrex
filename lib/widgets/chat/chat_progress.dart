import 'package:flutter/material.dart';
import 'package:vixrex/services/vixrex_profile_snapshot.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/theme/app_text_styles.dart';

/// İlerleme kartı ve skor çubuğu — TEK YERDE.
///
/// NEDEN VAR (Faz A): `VixRexProgressCard` 11/10px, `VixRexScoreBar` 10px
/// metinle çiziliyordu; ikisi de aynı işi (ilerlemeyi göstermek) yapıyordu.
/// Metin `AppTextStyles.labelSmall` (12) oldu, çubuk yüksekliği 6px'te eşitlendi.
///
/// Skor renkleri palete bağlandı: yeşil `success`, sarı `warning`,
/// kırmızı `error`. Palet dışı `#22C55E` silindi.
class ChatProgressCard extends StatelessWidget {
  const ChatProgressCard({
    super.key,
    required this.snapshot,
    required this.phase,
    required this.hasShared,
  });

  final VixRexProfileSnapshot? snapshot;
  final VixRexJourneyPhase phase;
  final bool hasShared;

  @override
  Widget build(BuildContext context) {
    final completedRequiredSteps = snapshot?.completedRequiredStepCount ?? 0;
    final isPublished = snapshot?.isPublished ?? false;
    final completedSteps =
        completedRequiredSteps +
        (isPublished ? 1 : 0) +
        (isPublished && hasShared ? 1 : 0);
    // Toplam adım sayısı ŞEMADAN gelir; elle sabit tutulmaz.
    // +2 → yayınlama ve paylaşma (alan değil, akış aşaması).
    final totalSteps = (snapshot?.totalRequiredStepCount ?? 5) + 2;
    final phaseLabel = switch (phase) {
      VixRexJourneyPhase.setup => 'Kurulum',
      VixRexJourneyPhase.publish => 'Yayınlama',
      VixRexJourneyPhase.share => 'Duyurma',
      VixRexJourneyPhase.improve => 'Geliştirme',
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppColors.spacing12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppColors.radius12),
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
                size: 16,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Aşama: $phaseLabel',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.darkText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$completedSteps/$totalSteps',
                style: AppTextStyles.labelSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ChatProgressBar(value: completedSteps / totalSteps),
        ],
      ),
    );
  }
}

/// Ortak çubuk. Kart ve skor aynı çubuğu çizer.
class ChatProgressBar extends StatelessWidget {
  const ChatProgressBar({
    super.key,
    required this.value,
    this.color = AppColors.primary,
  });

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: 6,
        backgroundColor: AppColors.surfaceSoft,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

/// Vitrin skoru — bot balonunun altında.
class ChatScoreBar extends StatefulWidget {
  const ChatScoreBar({
    super.key,
    required this.score,
    this.label = 'Vitrin skoru',
  });

  /// 0–100.
  final int score;
  final String label;

  @override
  State<ChatScoreBar> createState() => _ChatScoreBarState();
}

class _ChatScoreBarState extends State<ChatScoreBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final Animation<double> _fill = Tween<double>(
    begin: 0,
    end: (widget.score / 100).clamp(0, 1),
  ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// Eşikler değişmedi; renkler palete bağlandı.
  Color get _color {
    if (widget.score >= 80) return AppColors.success;
    if (widget.score >= 50) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.label, style: AppTextStyles.labelSmall),
            AnimatedBuilder(
              animation: _fill,
              builder:
                  (_, _) => Text(
                    '%${(widget.score * _fill.value).round()}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: _color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppColors.spacing4),
        AnimatedBuilder(
          animation: _fill,
          builder: (_, _) => ChatProgressBar(value: _fill.value, color: _color),
        ),
      ],
    );
  }
}

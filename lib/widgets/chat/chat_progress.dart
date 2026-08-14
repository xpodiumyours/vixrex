import 'package:flutter/material.dart';
import 'package:vixrex/theme/app_colors.dart';

/// Sohbet yüzeylerinin paylaştığı etiketli ilerleme çubuğu.
///
/// Faz A (Tek Asistan planı): `VixRexProgressCard` (aşama ilerlemesi) ve
/// `VixRexScoreBar` (vitrin skoru) aynı satır+çubuk deseni iki ayrı yerde
/// çiziyordu. Her ikisinin de kendi metni, rengi ve (skor için) animasyonu
/// kalır — ortaklaşan yalnız düzen: üstte etiket/değer satırı, altta çubuk.
class ChatProgress extends StatelessWidget {
  const ChatProgress({
    super.key,
    required this.leading,
    required this.trailing,
    required this.progress,
    this.color = AppColors.primary,
    this.trackColor = AppColors.surfaceSoft,
    this.minHeight = 6,
  });

  /// Sol taraf — genellikle bir [Text] ya da ikon+metin satırı.
  final Widget leading;

  /// Sağ taraf — genellikle değeri gösteren [Text].
  final Widget trailing;

  /// 0.0–1.0 arası doluluk.
  final double progress;

  final Color color;
  final Color trackColor;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Expanded(child: leading), trailing],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: minHeight,
            backgroundColor: trackColor,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

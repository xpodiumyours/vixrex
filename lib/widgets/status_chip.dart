import 'package:flutter/material.dart';
import 'package:vixrex/theme/app_text_styles.dart';
import 'package:vixrex/widgets/common/app_tone.dart';

/// Vitrin durum çipi — koyu tema karşılığı.
///
/// ESKİ HALİ Material paletiyle çalışıyordu (`Colors.green.shade100`,
/// `orange.shade100`, `blue.shade100`, `red.shade100`): koyu lacivert
/// arayüzde açık pastel adalar. Artık zemin palet renginin %14'ü,
/// kenarlık %40'ı, metin tam renk.
///
/// Çağrı biçimi korundu — `StatusChip(status: 'Açık')` çalışmaya devam eder,
/// mevcut kullanım yerlerinde değişiklik gerekmez.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.status,
    this.tone,
    this.dense = false,
  });

  final String status;

  /// Verilmezse [status] metninden çıkarılır (geriye uyumluluk).
  final AppTone? tone;

  /// Kart içi sıkışık kullanım — 12px yerine 10px yatay boşluk.
  final bool dense;

  static AppTone toneFor(String status) => switch (status) {
    'Açık' => AppTone.success,
    'Bugün kampanya var' => AppTone.info,
    'Yeni ürünler geldi' => AppTone.info,
    'Stok sınırlı' => AppTone.danger,
    'Kapalı' => AppTone.neutral,
    _ => AppTone.info,
  };

  static IconData? _iconFor(String status) => switch (status) {
    'Açık' => null, // nokta gösterilir, ikon değil
    'Bugün kampanya var' => Icons.local_offer_rounded,
    'Yeni ürünler geldi' => Icons.new_releases_rounded,
    'Stok sınırlı' => Icons.warning_amber_rounded,
    'Kapalı' => null,
    _ => Icons.campaign_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final effectiveTone = tone ?? toneFor(status);
    final icon = _iconFor(status);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 10 : 12, vertical: 5),
      decoration: BoxDecoration(
        color: effectiveTone.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: effectiveTone.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(icon, size: 12, color: effectiveTone.color)
          else
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: effectiveTone.color,
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 6),
          Text(
            status,
            style: AppTextStyles.labelSmall.copyWith(
              color: effectiveTone.color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

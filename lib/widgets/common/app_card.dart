import 'package:flutter/material.dart';
import 'package:vixrex/theme/app_colors.dart';

/// Ortak kart bileşeni — tüm ekranlarda aynı zemin, yuvarlaklık ve kenarlık.
///
/// Ekranlarda tekrar eden şu desenin yerine geçer:
/// ```dart
/// Container(
///   decoration: BoxDecoration(
///     color: AppColors.surface,
///     borderRadius: BorderRadius.circular(16),
///     border: Border.all(color: AppColors.border),
///   ),
/// )
/// ```
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.color = AppColors.surface,
    required this.child,
  });

  /// Dokunulabilir kart yapmak için verilir (InkWell dalga efektiyle).
  final VoidCallback? onTap;

  /// Kart iç boşluğu. Varsayılan 16 (raporun baskın kullanımı).
  final EdgeInsetsGeometry padding;

  /// Kart zemini. Varsayılan [AppColors.surface].
  final Color color;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: child,
        ),
      ),
    );
  }
}

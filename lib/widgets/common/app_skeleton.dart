import 'package:flutter/material.dart';
import 'package:vixrex/theme/app_colors.dart';

/// Yükleme iskeleti — nefes alan tek blok.
///
/// Her ekranda ortada dönen `CircularProgressIndicator` var; kullanıcı ne
/// geleceğini görmüyor. İskelet, gelecek düzenin şeklini önden gösterir ve
/// algılanan bekleme süresini kısaltır.
///
/// ```dart
/// AppSkeleton(width: 120, height: 10)
/// AppSkeleton.card()            // Keşfet grid kartı
/// AppSkeleton.listRow()         // ayar / bildirim satırı
/// ```
class AppSkeleton extends StatefulWidget {
  const AppSkeleton({
    super.key,
    this.width,
    this.height = 12,
    this.radius = 999,
  });

  final double? width;
  final double height;
  final double radius;

  /// Keşfet grid kartının iskeleti — kapak alanı + iki satır + çip.
  static Widget card() => const _SkeletonCard();

  /// Liste satırı iskeleti — kart yüksekliğinde tek blok.
  static Widget listRow() =>
      const AppSkeleton(height: 64, radius: AppColors.radius16);

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        // #182E5B ile #112448 arası: iki palet yüzeyi arasında nefes.
        final color = Color.lerp(
          AppColors.blueSurface,
          AppColors.surfaceSoft,
          _controller.value,
        );
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        );
      },
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppColors.radius16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            child: AppSkeleton(
              height: double.infinity,
              radius: AppColors.radius16,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppColors.spacing12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppSkeleton(width: 130, height: 10),
                const SizedBox(height: AppColors.spacing8),
                const AppSkeleton(width: 80, height: 8),
                const SizedBox(height: AppColors.spacing12),
                const AppSkeleton(width: 64, height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Panel içi ince kaydırma şeridi — web + Flutter aynı düzen kuralı.
///
/// 2026-09-03 (Çalışma masası düzeni): web'deki sahip paneli sohbetinin
/// kaydırma şeridi ince ve koyu yüzeye uyumlu yapıldı
/// (`.vixrex-panel-kaydirici`, globals.css). Uygulama içi asistan sohbetleri
/// (onboarding + companion) aynı görünümü kullanır — aynı uygulama, aynı
/// şerit. Varsayılan kalın şerit yerine 6px, yuvarlak uçlu, yüzeyle uyumlu
/// bir şerit çizer.
class VixrexThinScrollbar extends StatelessWidget {
  const VixrexThinScrollbar({
    super.key,
    required this.controller,
    required this.child,
  });

  /// Kaydırılan listenin kullandığı controller — `Scrollbar`'ın okuyabilmesi
  /// için aynı controller verilir.
  final ScrollController controller;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ScrollbarTheme(
      data: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(
          Colors.white.withValues(alpha: 0.22),
        ),
        thumbVisibility: const WidgetStatePropertyAll(true),
        radius: const Radius.circular(8),
        thickness: const WidgetStatePropertyAll(6),
        trackColor: const WidgetStatePropertyAll(Colors.transparent),
        trackBorderColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      child: Scrollbar(controller: controller, child: child),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:vixrex/theme/app_colors.dart';

/// Durum tonu — bant, çip, rozet ve ilerleme göstergelerinin paylaştığı
/// tek ölçek.
///
/// Kural: metin ve ikon tam renk, zemin %14 (hata %12), kenarlık %40.
/// Bir bileşen kendi durum rengini hesaplamaz, buradan alır.
enum AppTone { info, success, warning, danger, neutral }

extension AppToneColors on AppTone {
  Color get color => switch (this) {
    AppTone.info => AppColors.secondary,
    AppTone.success => AppColors.success,
    AppTone.warning => AppColors.warning,
    AppTone.danger => AppColors.error,
    AppTone.neutral => AppColors.mutedText,
  };

  Color get surface => switch (this) {
    AppTone.info => AppColors.infoSoft,
    AppTone.success => AppColors.successSoft,
    AppTone.warning => AppColors.warningSoft,
    AppTone.danger => AppColors.errorSoft,
    AppTone.neutral => AppColors.neutralSoft,
  };

  Color get borderColor => switch (this) {
    AppTone.info => AppColors.infoBorder,
    AppTone.success => AppColors.successBorder,
    AppTone.warning => AppColors.warningBorder,
    AppTone.danger => AppColors.errorBorder,
    AppTone.neutral => AppColors.neutralBorder,
  };

  IconData get icon => switch (this) {
    AppTone.info => Icons.info_outline_rounded,
    AppTone.success => Icons.check_circle_outline_rounded,
    AppTone.warning => Icons.warning_amber_rounded,
    AppTone.danger => Icons.error_outline_rounded,
    AppTone.neutral => Icons.remove_circle_outline_rounded,
  };
}

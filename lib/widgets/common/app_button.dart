import 'package:flutter/material.dart';
import 'package:vixrex/theme/app_colors.dart';

/// Uygulamanın tek buton bileşeni — dört ağırlık, tek yükseklik sözleşmesi.
///
/// Ekranlarda tekrar eden `FilledButton` / `OutlinedButton` / `TextButton` +
/// elle yazılmış `styleFrom` desenlerinin yerine geçer. Stilin tamamı
/// [AppTheme] alt temalarından gelir; bu bileşen yalnız hangi ağırlığın
/// kullanılacağını ve yükleme/ikon durumunu yönetir.
///
/// ```dart
/// AppButton.primary(label: 'Vitrini yayınla', onPressed: _publish)
/// AppButton.secondary(label: 'Taslağı kaydet', onPressed: _save)
/// AppButton.ghost(label: 'Vazgeç', onPressed: _cancel)
/// AppButton.danger(label: 'Vitrini sil', onPressed: _delete)
/// ```
enum AppButtonVariant { primary, secondary, ghost, danger }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.expanded = true,
    this.compact = false,
  });

  const AppButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expanded = true,
    this.compact = false,
  }) : variant = AppButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expanded = true,
    this.compact = false,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expanded = false,
    this.compact = false,
  }) : variant = AppButtonVariant.ghost;

  const AppButton.danger({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expanded = true,
    this.compact = false,
  }) : variant = AppButtonVariant.danger;

  final String label;

  /// null ise buton pasif çizilir (tema `disabled*` renklerini uygular).
  final VoidCallback? onPressed;

  final AppButtonVariant variant;
  final IconData? icon;

  /// Yükleme sırasında etiket yerine halka çizer ve dokunmayı kapatır.
  /// Buton genişliği değişmez — düzen zıplamaz.
  final bool loading;

  /// Satırın tamamını kaplar. Formlarda true, satır içi aksiyonlarda false.
  final bool expanded;

  /// 44px yükseklik (satır içi kullanım). Varsayılan 48/46px.
  final bool compact;

  bool get _enabled => onPressed != null && !loading;

  @override
  Widget build(BuildContext context) {
    final child = _buildChild();
    final Widget button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
        onPressed: _enabled ? onPressed : null,
        style: _sizeStyle(),
        child: child,
      ),
      AppButtonVariant.secondary => OutlinedButton(
        onPressed: _enabled ? onPressed : null,
        style: _sizeStyle(),
        child: child,
      ),
      AppButtonVariant.ghost => TextButton(
        onPressed: _enabled ? onPressed : null,
        style: _sizeStyle(),
        child: child,
      ),
      AppButtonVariant.danger => OutlinedButton(
        onPressed: _enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          backgroundColor: AppColors.errorSoft,
          side: BorderSide(color: AppColors.errorBorder),
          minimumSize: Size.fromHeight(compact ? 44 : 46),
        ),
        child: child,
      ),
    };

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }

  ButtonStyle? _sizeStyle() {
    if (!compact) return null;
    return ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(0, 44)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }

  Widget _buildChild() {
    if (loading) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (icon == null) return Text(label);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: AppColors.spacing8),
        Text(label),
      ],
    );
  }
}

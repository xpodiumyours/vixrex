import 'package:flutter/material.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/theme/app_text_styles.dart';

/// Sohbet yazma alanı — TEK YERDE.
///
/// NEDEN VAR (Faz A): iki yüzeyde iki ayrı yazma alanı vardı.
/// - onboarding `_buildComposer`: `inputBg` zemin, 88×48 buton, `onPrimary` metin
/// - companion satır içi: `surface` zemin, 72×48 buton, `#041016` metin
/// Doğru değerler kurulum tarafından alındı: `inputBg`, 48px yükseklik,
/// `AppColors.onPrimary`. `#041016` palet dışıydı, silindi.
class ChatComposer extends StatelessWidget {
  const ChatComposer({
    super.key,
    required this.controller,
    required this.onSubmit,
    this.focusNode,
    this.hintText = 'Vixrex’e sor…',
    this.sendLabel = 'Gönder',
    this.enabled = true,
    this.autofocus = false,
    this.padding = EdgeInsets.zero,
  });

  final TextEditingController controller;

  /// Hem klavye "gönder" tuşu hem düğme buraya düşer.
  final ValueChanged<String> onSubmit;

  final FocusNode? focusNode;
  final String hintText;
  final String sendLabel;

  /// Bot yazarken false — çift gönderimi engeller.
  final bool enabled;

  final bool autofocus;
  final EdgeInsetsGeometry padding;

  static const double _height = 48;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppColors.radius12),
      borderSide: const BorderSide(color: AppColors.border),
    );

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              autofocus: autofocus,
              style: AppTextStyles.body.copyWith(color: AppColors.darkText),
              textInputAction: TextInputAction.send,
              onSubmitted: enabled ? onSubmit : null,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: AppTextStyles.body.copyWith(
                  color: AppColors.mutedText,
                ),
                filled: true,
                fillColor: AppColors.inputBg,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                border: border,
                enabledBorder: border,
                focusedBorder: border.copyWith(
                  borderSide: const BorderSide(
                    color: AppColors.focusedBorder,
                    width: 1.4,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppColors.spacing8),
          SizedBox(
            height: _height,
            child: FilledButton(
              onPressed: enabled ? () => onSubmit(controller.text) : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                disabledBackgroundColor: AppColors.disabled,
                minimumSize: const Size(88, _height),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppColors.spacing16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppColors.radius12),
                ),
              ),
              child: Text(
                sendLabel,
                style: AppTextStyles.labelBold.copyWith(
                  color: AppColors.onPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

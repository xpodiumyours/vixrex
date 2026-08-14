import 'package:flutter/material.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/theme/app_text_styles.dart';

/// Sohbet yüzeylerinin paylaştığı metin alanı + gönder düğmesi.
///
/// Faz A (Tek Asistan planı): onboarding kendi composer'ında `inputBg` +
/// `onPrimary` kullanıyordu, companion sohbeti `surface` zemin + `#041016`
/// metin rengiyle ayrı bir kopya çiziyordu. Doğru değerler onboarding'e
/// aitti (`inputBg`, `onPrimary`, 48px buton) — companion'ın kendi
/// sapması gitti. Gönder düğmesi artık `filledButtonTheme`'den geliyor,
/// kendi stilini tanımlamıyor.
class ChatComposer extends StatelessWidget {
  const ChatComposer({
    super.key,
    required this.controller,
    required this.onSend,
    this.focusNode,
    this.hintText,
    this.enabled = true,
    this.sendLabel = 'Gönder',
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final FocusNode? focusNode;
  final String? hintText;
  final bool enabled;
  final String sendLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            style: AppTextStyles.body.copyWith(color: AppColors.darkText),
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => onSend(),
            decoration: InputDecoration(
              hintText: hintText,
              filled: true,
              fillColor: AppColors.inputBg,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: AppColors.spacing12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppColors.radius12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppColors.radius12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppColors.spacing8),
        FilledButton(
          onPressed: enabled ? onSend : null,
          child: Text(sendLabel),
        ),
      ],
    );
  }
}

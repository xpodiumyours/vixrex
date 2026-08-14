import 'package:flutter/material.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/theme/app_text_styles.dart';
import 'package:vixrex/widgets/common/app_tone.dart';

/// Vitrin formunun katlanabilir bölüm kabuğu.
class FormAccordionSection extends StatelessWidget {
  const FormAccordionSection({
    super.key,
    required this.index,
    required this.title,
    required this.filledCount,
    required this.totalCount,
    required this.isOpen,
    required this.onToggle,
    required this.child,
    this.isRequired = false,
    this.anchorKey,
  });

  final int index;
  final String title;
  final int filledCount;
  final int totalCount;
  final bool isOpen;
  final VoidCallback onToggle;
  final Widget child;
  final bool isRequired;
  final Key? anchorKey;

  bool get _isComplete => filledCount >= totalCount && totalCount > 0;

  AppTone get _tone {
    if (_isComplete) return AppTone.success;
    if (isRequired) return AppTone.info;
    return AppTone.neutral;
  }

  String get _meta {
    final base = '$filledCount / $totalCount alan dolu';
    if (_isComplete || !isRequired) return base;
    return '$base · zorunlu';
  }

  @override
  Widget build(BuildContext context) {
    final tone = _tone;

    return KeyedSubtree(
      key: anchorKey,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.blueSurface)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppColors.spacing24,
                  vertical: AppColors.spacing16,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: tone.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: tone.borderColor),
                      ),
                      child:
                          _isComplete
                              ? Icon(
                                Icons.check_rounded,
                                size: 14,
                                color: tone.color,
                              )
                              : Text(
                                '${index + 1}',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: tone.color,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                    ),
                    const SizedBox(width: AppColors.spacing12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: AppTextStyles.subTitle),
                          const SizedBox(height: 2),
                          Text(_meta, style: AppTextStyles.labelSmall),
                        ],
                      ),
                    ),
                    Icon(
                      isOpen
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: AppColors.mutedText,
                    ),
                  ],
                ),
              ),
            ),
            if (isOpen)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppColors.spacing24,
                  0,
                  AppColors.spacing24,
                  AppColors.spacing20,
                ),
                child: child,
              ),
          ],
        ),
      ),
    );
  }
}

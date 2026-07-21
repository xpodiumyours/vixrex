import 'package:flutter/material.dart';
import 'package:vixrex/models/chat_message.dart';
import 'package:vixrex/theme/app_colors.dart';

/// İlk sohbet paneli gibi: ortada küçük hap(lar), tam genişlik şerit yok.
class VixRexQuickReplies extends StatelessWidget {
  final List<QuickReply> replies;
  final ValueChanged<QuickReply> onTap;

  const VixRexQuickReplies({
    super.key,
    required this.replies,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (replies.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
      child: Column(
        children: [
          const Text(
            'Devam',
            style: TextStyle(
              color: AppColors.mutedText,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < replies.length; i++)
                _Pill(
                  reply: replies[i],
                  primary: i == 0,
                  onTap: () => onTap(replies[i]),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final QuickReply reply;
  final bool primary;
  final VoidCallback onTap;

  const _Pill({
    required this.reply,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: reply.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: primary ? AppColors.ctaGradient : null,
              color: primary ? null : const Color(0xFF0E1B2E),
              border:
                  primary
                      ? null
                      : Border.all(
                        color: const Color(0xFF38A0E4).withAlpha(120),
                        width: 1.2,
                      ),
              boxShadow:
                  primary
                      ? [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(70),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                      : null,
            ),
            child: Center(
              child: Text(
                reply.label,
                style: TextStyle(
                  color: primary ? Colors.white : AppColors.mutedText,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

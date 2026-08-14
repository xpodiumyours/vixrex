import 'package:flutter/material.dart';
import 'package:vixrex/models/chat_message.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/widgets/chat/chat_pill.dart';

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
                ChatPill(
                  label: replies[i].label,
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

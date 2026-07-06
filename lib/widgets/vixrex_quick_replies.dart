import 'package:flutter/material.dart';
import 'package:vixrex/models/chat_message.dart';
import 'package:vixrex/theme/app_colors.dart';

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
    return Container(
      color: AppColors.bgEditor,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          itemCount: replies.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (context, index) {
            final r = replies[index];
            return Semantics(
              button: true,
              label: r.label,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(r),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 44),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    gradient: AppColors.ctaGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    r.label,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

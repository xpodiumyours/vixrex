import 'package:flutter/material.dart';
import 'package:vixrex/models/chat_message.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/widgets/vixrex_score_bar.dart';

class VixRexBotMessage extends StatelessWidget {
  final ChatMessage msg;
  final bool showCursor;
  final bool cursorVisible;

  const VixRexBotMessage({
    super.key,
    required this.msg,
    required this.showCursor,
    required this.cursorVisible,
  });

  @override
  Widget build(BuildContext context) {
    final lines = msg.text.split('\n');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(20),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text(
              'X',
              style: TextStyle(
                color: AppColors.primaryDark,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.bgEditor,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...lines.map((line) {
                  if (line.isEmpty) return const SizedBox(height: 4);
                  final isCursor = showCursor && lines.last == line;
                  return RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: line,
                          style: const TextStyle(
                            color: AppColors.darkText,
                            fontSize: 12.5,
                            height: 1.5,
                            fontFamily: 'monospace',
                          ),
                        ),
                        if (isCursor && cursorVisible)
                          const TextSpan(
                            text: ' ▌',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  );
                }),
                if (msg.snapshotScore != null) ...[
                  const SizedBox(height: 10),
                  VixRexScoreBar(score: msg.snapshotScore!),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class VixRexUserMessage extends StatelessWidget {
  final ChatMessage msg;

  const VixRexUserMessage({super.key, required this.msg});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: AppColors.ctaGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Text(
              msg.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class VixRexTypingIndicator extends StatelessWidget {
  const VixRexTypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                'X',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.bgEditor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              'Analiz ediliyor...',
              style: TextStyle(
                color: AppColors.mutedText,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

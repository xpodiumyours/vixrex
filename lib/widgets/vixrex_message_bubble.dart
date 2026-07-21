import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vixrex/models/chat_message.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/widgets/vixrex_score_bar.dart';

final _urlPattern = RegExp(r'https?://[^\s]+', caseSensitive: false);

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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...lines.map((line) {
                  if (line.isEmpty) return const SizedBox(height: 4);
                  final trimmed = line.trim();
                  final onlyUrl = _urlPattern.stringMatch(trimmed);
                  if (onlyUrl != null &&
                      onlyUrl.replaceAll(RegExp(r'[.,)>]+$'), '') ==
                          trimmed.replaceAll(RegExp(r'[.,)>]+$'), '')) {
                    final url = onlyUrl.replaceAll(RegExp(r'[.,)>]+$'), '');
                    return Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 2),
                      child: _LinkChip(url: url),
                    );
                  }
                  final isCursor = showCursor && lines.last == line;
                  final inlineUrl = _urlPattern.firstMatch(line);
                  if (inlineUrl != null) {
                    final url =
                        inlineUrl.group(0)!.replaceAll(RegExp(r'[.,)>]+$'), '');
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (inlineUrl.start > 0)
                            Text(
                              line.substring(0, inlineUrl.start),
                              style: const TextStyle(
                                color: AppColors.darkText,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          GestureDetector(
                            onTap: () => _openUrl(url),
                            child: Text(
                              url,
                              style: const TextStyle(
                                color: Color(0xFF7DD3FC),
                                fontSize: 13,
                                height: 1.5,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                                decorationColor: Color(0xFF7DD3FC),
                              ),
                            ),
                          ),
                          if (inlineUrl.end < line.length)
                            Text(
                              line.substring(inlineUrl.end),
                              style: const TextStyle(
                                color: AppColors.darkText,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          if (isCursor && cursorVisible)
                            const Text(
                              ' ▌',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      isCursor && cursorVisible ? '$line ▌' : line,
                      style: TextStyle(
                        color: AppColors.darkText,
                        fontSize: 13,
                        height: 1.5,
                        fontWeight:
                            isCursor && cursorVisible
                                ? FontWeight.w500
                                : FontWeight.w400,
                      ),
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

class _LinkChip extends StatelessWidget {
  final String url;
  const _LinkChip({required this.url});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Material(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: () => _openUrl(url),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  url.replaceFirst(RegExp(r'^https?://'), ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF7DD3FC),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: url));
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Link kopyalandı.')),
            );
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.darkText,
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            minimumSize: const Size(0, 36),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Kopyala', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}

Future<void> _openUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {}
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

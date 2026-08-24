import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vixrex/services/safe_url_launcher.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/theme/app_text_styles.dart';
import 'package:vixrex/widgets/vixrex_avatar.dart';

/// Sohbet balonları — TEK YERDE.
///
/// NEDEN VAR (Faz A): iki balon iki ayrı tipografiye sahipti — bot 14.5,
/// kullanıcı 12.5. İkisi `AppTextStyles.body` (14) oldu.
///
/// Kullanıcı balonundan `ctaGradient` kaldırıldı: birincil gradyan
/// yayınlama aksiyonuna ait. Kullanıcı balonu `surfaceSoft` + `border`;
/// bot balonundan köşe yönüyle ayrılır, renkle değil.
final _urlPattern = RegExp(r'https?://[^\s]+', caseSensitive: false);
final _trailingPunctuation = RegExp(r'[.,)>]+$');

const _linkColor = Color(0xFF7DD3FC);

class ChatBubble extends StatelessWidget {
  const ChatBubble._({
    required this.text,
    required this.fromBot,
    this.showCursor = false,
    this.cursorVisible = false,
    this.footer,
  });

  /// Bot balonu: avatar + sol alt köşesi kırık kutu.
  const ChatBubble.bot({
    Key? key,
    required String text,
    bool showCursor = false,
    bool cursorVisible = false,
    Widget? footer,
  }) : this._(
         text: text,
         fromBot: true,
         showCursor: showCursor,
         cursorVisible: cursorVisible,
         footer: footer,
       );

  /// Kullanıcı balonu: sağa yaslı, sağ alt köşesi kırık kutu.
  const ChatBubble.user({Key? key, required String text})
    : this._(text: text, fromBot: false);

  final String text;
  final bool fromBot;
  final bool showCursor;
  final bool cursorVisible;

  /// Balonun altına giren ek içerik (skor çubuğu, onay kartı).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: fromBot ? AppColors.surfaceSoft : AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(AppColors.radius16),
          topRight: const Radius.circular(AppColors.radius16),
          bottomLeft: Radius.circular(fromBot ? 4 : AppColors.radius16),
          bottomRight: Radius.circular(fromBot ? AppColors.radius16 : 4),
        ),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._lines(),
          if (footer != null) ...[
            const SizedBox(height: AppColors.spacing8),
            footer!,
          ],
        ],
      ),
    );

    if (!fromBot) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [Flexible(child: box)],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const VixrexAvatar(boyut: 28),
        const SizedBox(width: AppColors.spacing8),
        Expanded(child: box),
      ],
    );
  }

  List<Widget> _lines() {
    final lines = text.split('\n');
    return [
      for (final line in lines)
        if (line.isEmpty)
          const SizedBox(height: 4)
        else
          _ChatLine(
            line: line,
            isCursorLine: showCursor && line == lines.last,
            cursorVisible: cursorVisible,
          ),
    ];
  }
}

class _ChatLine extends StatelessWidget {
  const _ChatLine({
    required this.line,
    required this.isCursorLine,
    required this.cursorVisible,
  });

  final String line;
  final bool isCursorLine;
  final bool cursorVisible;

  bool get _cursorOn => isCursorLine && cursorVisible;

  @override
  Widget build(BuildContext context) {
    final trimmed = line.trim();
    final match = _urlPattern.firstMatch(line);

    if (match != null) {
      final url = match.group(0)!.replaceAll(_trailingPunctuation, '');
      final onlyUrl = url == trimmed.replaceAll(_trailingPunctuation, '');
      if (onlyUrl) {
        return Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 2),
          child: ChatLinkChip(url: url),
        );
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (match.start > 0)
              Text(line.substring(0, match.start), style: AppTextStyles.body),
            GestureDetector(
              onTap: () => openChatUrl(url),
              child: Text(
                url,
                style: AppTextStyles.body.copyWith(
                  color: _linkColor,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                  decorationColor: _linkColor,
                ),
              ),
            ),
            if (match.end < line.length)
              Text(line.substring(match.end), style: AppTextStyles.body),
            if (_cursorOn)
              Text(
                ' ▌',
                style: AppTextStyles.body.copyWith(color: AppColors.primary),
              ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        _cursorOn ? '$line ▌' : line,
        style: AppTextStyles.body.copyWith(
          fontWeight: _cursorOn ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}

/// Tek başına duran link satırı: aç + kopyala.
class ChatLinkChip extends StatelessWidget {
  const ChatLinkChip({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Material(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppColors.radius12),
            child: InkWell(
              onTap: () => openChatUrl(url),
              borderRadius: BorderRadius.circular(AppColors.radius12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppColors.radius12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  url.replaceFirst(RegExp(r'^https?://'), ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: _linkColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppColors.spacing8),
        OutlinedButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: url));
            if (!context.mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Link kopyalandı.')));
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.darkText,
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(
              horizontal: AppColors.spacing12,
              vertical: 10,
            ),
            minimumSize: const Size(0, 36),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppColors.radius12),
            ),
          ),
          child: Text('Kopyala', style: AppTextStyles.labelSmall),
        ),
      ],
    );
  }
}

Future<void> openChatUrl(String url) async {
  await safeLaunchUrl(url);
}

/// "Yazıyor" göstergesi — TEK YERDE.
///
/// İki gösterge vardı: `VixRexTypingIndicator` (harf `X` çizen çember,
/// "Analiz ediliyor…") ve companion'ın düz metni ("Vixrex yazıyor…").
/// Biri kaldı; çember `VixrexAvatar`'a döndü, metin tek cümle.
class ChatTypingIndicator extends StatelessWidget {
  const ChatTypingIndicator({super.key, this.label = 'Vixrex yazıyor…'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          const VixrexAvatar(boyut: 28),
          const SizedBox(width: AppColors.spacing8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppColors.radius12),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

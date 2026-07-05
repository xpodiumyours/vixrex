import 'package:flutter/material.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/widgets/editor/article_summary_row.dart';

class VisibilityHubCard extends StatelessWidget {
  final bool hasPublished;
  final bool hasWebLink;
  final bool hasLocation;
  final bool hasGoogleReview;
  final bool hasProfileDescription;
  final bool hasPublishedArticle;
  final bool isLoadingArticles;
  final List<Map<String, dynamic>> publishedArticles;
  final VoidCallback onShowGoogleReviewQr;
  final VoidCallback onCreateArticle;
  final ValueChanged<Map<String, dynamic>> onOpenArticle;

  const VisibilityHubCard({
    super.key,
    required this.hasPublished,
    required this.hasWebLink,
    required this.hasLocation,
    required this.hasGoogleReview,
    required this.hasProfileDescription,
    required this.hasPublishedArticle,
    required this.isLoadingArticles,
    required this.publishedArticles,
    required this.onShowGoogleReviewQr,
    required this.onCreateArticle,
    required this.onOpenArticle,
  });

  @override
  Widget build(BuildContext context) {
    final completedCount =
        [
          hasPublished,
          hasWebLink,
          hasLocation,
          hasGoogleReview,
          hasProfileDescription,
          hasPublishedArticle,
        ].where((value) => value).length;

    final hasCoreInfo =
        hasPublished && hasWebLink && hasLocation && hasProfileDescription;
    final isReady = hasCoreInfo && hasGoogleReview;
    final statusLabel =
        isReady
            ? 'Hazır'
            : hasCoreInfo
            ? 'Geliştirilebilir'
            : 'Eksik bilgi var';
    final statusColor =
        isReady
            ? const Color(0xFF047857)
            : hasCoreInfo
            ? const Color(0xFFB45309)
            : const Color(0xFFDC2626);
    final statusBg = statusColor.withValues(alpha: 0.12);
    final helperText =
        isReady
            ? 'Temel bilgiler tamam. Güncel içerik ekledikçe görünürlük güçlenir.'
            : hasCoreInfo
            ? 'Temel bilgiler hazır. Google yorum linki ve içerik eklemek vitrini güçlendirir.'
            : 'Google için önce yayın linki, adres/konum ve kısa açıklamayı tamamla.';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorderDark),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.travel_explore_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Google Görünürlük',
                  style: TextStyle(
                    color: AppColors.darkText,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.18),
                  ),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Vitrin bilgilerinden otomatik hazırlanır. Sıralama garantisi vermez; doğru bilgi, erişilebilir sayfa ve güncel içerik görünürlüğü destekler.',
            style: TextStyle(
              color: AppColors.mutedText.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.inputBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorderDark),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$completedCount/6 kontrol tamamlandı. $helperText',
                    style: const TextStyle(
                      color: AppColors.darkText,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 520;
              final tileWidth =
                  isNarrow
                      ? constraints.maxWidth
                      : (constraints.maxWidth - 16) / 3;

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _VisibilityCheckTile(
                    width: tileWidth,
                    icon: Icons.public_rounded,
                    title: 'Vitrin yayında',
                    isComplete: hasPublished,
                  ),
                  _VisibilityCheckTile(
                    width: tileWidth,
                    icon: Icons.link_rounded,
                    title: 'Web linki hazır',
                    isComplete: hasWebLink,
                  ),
                  _VisibilityCheckTile(
                    width: tileWidth,
                    icon: Icons.place_rounded,
                    title: 'Adres veya konum',
                    isComplete: hasLocation,
                  ),
                  _VisibilityCheckTile(
                    width: tileWidth,
                    icon: Icons.rate_review_rounded,
                    title: 'Google yorum linki',
                    isComplete: hasGoogleReview,
                  ),
                  _VisibilityCheckTile(
                    width: tileWidth,
                    icon: Icons.notes_rounded,
                    title: 'Kısa açıklama',
                    isComplete: hasProfileDescription,
                  ),
                  _VisibilityCheckTile(
                    width: tileWidth,
                    icon: Icons.article_rounded,
                    title: 'Yayında içerik',
                    isComplete: hasPublishedArticle,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (hasGoogleReview)
                OutlinedButton.icon(
                  onPressed: onShowGoogleReviewQr,
                  icon: const Icon(Icons.qr_code_2_rounded, size: 16),
                  label: const Text(
                    'Yorum QR kodu',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )
              else
                const _VisibilityHintChip(
                  icon: Icons.rate_review_rounded,
                  text: 'Google yorum linki ekle',
                ),
              TextButton.icon(
                onPressed: onCreateArticle,
                icon: const Icon(
                  Icons.add_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                label: const Text(
                  'Yeni Yazı',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          if (isLoadingArticles) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(
              minHeight: 2,
              color: AppColors.primary,
              backgroundColor: Color(0xFFE5E7EB),
            ),
          ] else if (publishedArticles.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'İçerik ve Duyurular',
              style: TextStyle(
                color: AppColors.darkText,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            ...publishedArticles.take(2).map(
              (article) => ArticleSummaryRow(
                article: article,
                onTap: () => onOpenArticle(article),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VisibilityCheckTile extends StatelessWidget {
  final double width;
  final IconData icon;
  final String title;
  final bool isComplete;

  const _VisibilityCheckTile({
    required this.width,
    required this.icon,
    required this.title,
    required this.isComplete,
  });

  @override
  Widget build(BuildContext context) {
    final color = isComplete ? AppColors.success : AppColors.mutedText;

    return SizedBox(
      width: width,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color:
              isComplete
                  ? AppColors.success.withAlpha(30)
                  : AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isComplete
                    ? AppColors.success.withAlpha(80)
                    : AppColors.cardBorderDark,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isComplete ? AppColors.success : AppColors.darkText,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Icon(
              isComplete
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: color,
              size: 15,
            ),
          ],
        ),
      ),
    );
  }
}

class _VisibilityHintChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _VisibilityHintChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.darkText,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

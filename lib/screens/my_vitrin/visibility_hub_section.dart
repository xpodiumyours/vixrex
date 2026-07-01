import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:vitrinx/theme/app_colors.dart';

class VisibilityHubSection extends StatelessWidget {
  final String? publicLink;
  final bool hasPublished;
  final String addressText;
  final bool hasLatLon;
  final String googleBusinessLink;
  final String descriptionText;
  final bool isLoadingArticles;
  final List<Map<String, dynamic>> articles;
  final VoidCallback onShowGoogleReviewQrSheet;
  final VoidCallback onOpenBlogEditor;
  final void Function(Map<String, dynamic>) onOpenBlogEditorWithArticle;

  const VisibilityHubSection({
    super.key,
    required this.publicLink,
    required this.hasPublished,
    required this.addressText,
    required this.hasLatLon,
    required this.googleBusinessLink,
    required this.descriptionText,
    required this.isLoadingArticles,
    required this.articles,
    required this.onShowGoogleReviewQrSheet,
    required this.onOpenBlogEditor,
    required this.onOpenBlogEditorWithArticle,
  });

  static const Color _primaryColor = AppColors.primary;
  static const Color _darkText = AppColors.darkText;
  static const Color _mutedText = AppColors.mutedText;
  static const Color _cardBorder = AppColors.border;

  @override
  Widget build(BuildContext context) {
    final hasWebLink = publicLink != null && publicLink!.isNotEmpty;
    final hasLocation = addressText.isNotEmpty || hasLatLon;
    final hasGoogleReview = googleBusinessLink.isNotEmpty;
    final hasProfileDescription = descriptionText.isNotEmpty;
    final publishedArticles =
        articles
            .where((a) => a['status']?.toString() == 'published')
            .toList();
    final hasPublishedArticle = publishedArticles.isNotEmpty;

    final completedCount =
        [
          hasPublished,
          hasWebLink,
          hasLocation,
          hasGoogleReview,
          hasProfileDescription,
          hasPublishedArticle,
        ].where((v) => v).length;

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
        border: Border.all(color: _cardBorder),
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
                color: _primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Google Görünürlük',
                  style: TextStyle(
                    color: _darkText,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: statusColor.withValues(alpha: 0.18)),
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
              color: _mutedText.withValues(alpha: 0.8),
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
              border: Border.all(color: _cardBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: _primaryColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$completedCount/6 kontrol tamamlandı. $helperText',
                    style: const TextStyle(
                      color: _darkText,
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
                  _checkTile(tileWidth, Icons.public_rounded, 'Vitrin yayında', hasPublished),
                  _checkTile(tileWidth, Icons.link_rounded, 'Web linki hazır', hasWebLink),
                  _checkTile(tileWidth, Icons.place_rounded, 'Adres veya konum', hasLocation),
                  _checkTile(tileWidth, Icons.rate_review_rounded, 'Google yorum linki', hasGoogleReview),
                  _checkTile(tileWidth, Icons.notes_rounded, 'Kısa açıklama', hasProfileDescription),
                  _checkTile(tileWidth, Icons.article_rounded, 'Yayında içerik', hasPublishedArticle),
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
                  onPressed: onShowGoogleReviewQrSheet,
                  icon: const Icon(Icons.qr_code_2_rounded, size: 16),
                  label: const Text(
                    'Yorum QR kodu',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primaryColor,
                    side: const BorderSide(color: _primaryColor),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )
              else
                _hintChip(Icons.rate_review_rounded, 'Google yorum linki ekle'),
              TextButton.icon(
                onPressed: onOpenBlogEditor,
                icon: const Icon(Icons.add_rounded, size: 16, color: _primaryColor),
                label: const Text(
                  'Yeni Yazı',
                  style: TextStyle(
                    color: _primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
              color: _primaryColor,
              backgroundColor: Color(0xFFE5E7EB),
            ),
          ] else if (publishedArticles.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'İçerik ve Duyurular',
              style: TextStyle(
                color: _darkText,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            ...publishedArticles.take(2).map(_articleRow),
          ],
        ],
      ),
    );
  }

  Widget _checkTile(double width, IconData icon, String title, bool isComplete) {
    final color = isComplete ? AppColors.success : _mutedText;
    return SizedBox(
      width: width,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isComplete ? AppColors.success.withAlpha(30) : AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isComplete ? AppColors.success.withAlpha(80) : _cardBorder,
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
                  color: isComplete ? AppColors.success : _darkText,
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

  Widget _hintChip(IconData icon, String text) {
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

  Widget _articleRow(Map<String, dynamic> article) {
    final title = article['title']?.toString().trim() ?? '';
    final seoScore = article['seo_score'] ?? 0;
    return InkWell(
      onTap: () => onOpenBlogEditorWithArticle(article),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _primaryColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.article_rounded, color: _primaryColor, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title.isEmpty ? 'Yayınlanan yazı' : title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _darkText,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'SEO $seoScore',
              style: const TextStyle(
                color: _mutedText,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Static helper to show Google review QR sheet from the parent state.
  static void showGoogleReviewQrSheet(BuildContext context, String link) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Google Yorum QR Kodu',
              style: TextStyle(
                color: AppColors.darkText,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Google politikaları gereği yorum karşılığında ödül veya hediye teklif edilmesi yasaktır. Lütfen QR kodunu müşterilerinizden tarafsız ve organik geri bildirimler almak üzere kullanın.',
                      style: TextStyle(
                        color: AppColors.darkTextAlt,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: 220,
              height: 220,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: QrImageView(
                data: link,
                version: QrVersions.auto,
                errorCorrectionLevel: QrErrorCorrectLevel.M,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              link,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.mutedText,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

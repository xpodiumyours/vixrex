import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitrinx/services/revalidation_service.dart';
import 'package:vitrinx/theme/app_colors.dart';

/// Yönetici moderasyon ekranı.
///
/// Supabase `user_metadata.is_admin == true` olan kullanıcılar için
/// `store_articles` tablosundaki `review` statüsündeki yazıları listeler
/// ve yayınlama / reddetme işlemi yapar.
class BlogModerationScreen extends StatefulWidget {
  const BlogModerationScreen({super.key});

  @override
  State<BlogModerationScreen> createState() => _BlogModerationScreenState();
}

class _BlogModerationScreenState extends State<BlogModerationScreen> {
  static const Color _primaryColor = AppColors.primary;
  static const Color _bgColor = AppColors.bgEditor;
  static const Color _darkText = AppColors.darkText;
  static const Color _mutedText = AppColors.mutedText;

  List<Map<String, dynamic>> _pendingArticles = [];
  bool _isLoading = true;
  String? _error;

  // Track in-progress moderation actions to prevent double taps
  final Set<String> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _fetchPending();
  }

  Future<void> _fetchPending() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final client = Supabase.instance.client;
      final data = await client
          .from('store_articles')
          .select('id, store_slug, title, summary, status, created_at, seo_score, article_type, target_city')
          .eq('status', 'review')
          .order('created_at', ascending: true);

      setState(() {
        _pendingArticles = List<Map<String, dynamic>>.from(data as List);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Yazılar yüklenemedi: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _moderate(
    Map<String, dynamic> article,
    String newStatus,
  ) async {
    final id = article['id']?.toString() ?? '';
    if (id.isEmpty || _processingIds.contains(id)) return;

    setState(() => _processingIds.add(id));
    try {
      final client = Supabase.instance.client;
      await client
          .from('store_articles')
          .update({'status': newStatus})
          .eq('id', id);

      // Trigger ISR revalidation so public page updates immediately
      if (newStatus == 'published') {
        final storeSlug = article['store_slug']?.toString() ?? '';
        const RevalidationService().revalidateStore(storeSlug);
      }

      if (!mounted) return;
      setState(() => _pendingArticles.removeWhere((a) => a['id']?.toString() == id));

      _showSnackBar(
        newStatus == 'published' ? '✓ Yazı yayınlandı' : '✗ Yazı reddedildi',
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Hata: $e');
    } finally {
      if (mounted) setState(() => _processingIds.remove(id));
    }
  }

  void _showSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Blog Moderasyonu',
          style: TextStyle(
            color: _darkText,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Yenile',
            onPressed: _fetchPending,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _primaryColor));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: _darkText)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchPending,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    if (_pendingArticles.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline_rounded, size: 64, color: Color(0xFF10B981)),
            SizedBox(height: 16),
            Text(
              'İncelenecek yazı yok',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _darkText,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Yeni yazı geldiğinde burada görünür.',
              style: TextStyle(color: _mutedText),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _primaryColor,
      onRefresh: _fetchPending,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingArticles.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final article = _pendingArticles[index];
          return _ArticleReviewCard(
            article: article,
            isProcessing: _processingIds.contains(article['id']?.toString()),
            onApprove: () => _moderate(article, 'published'),
            onReject: () => _moderate(article, 'rejected'),
          );
        },
      ),
    );
  }
}

class _ArticleReviewCard extends StatelessWidget {
  static const Color _cardBorder = AppColors.cardBorderDark;
  static const Color _darkText = AppColors.darkText;
  static const Color _mutedText = AppColors.mutedText;

  final Map<String, dynamic> article;
  final bool isProcessing;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ArticleReviewCard({
    required this.article,
    required this.isProcessing,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final title = article['title']?.toString() ?? 'Başlıksız';
    final summary = article['summary']?.toString() ?? '';
    final storeSlug = article['store_slug']?.toString() ?? '';
    final seoScore = article['seo_score'] as int? ?? 0;
    final articleType = article['article_type']?.toString() ?? 'standard';
    final targetCity = article['target_city']?.toString() ?? '';
    final createdAt = article['created_at']?.toString().split('T').first ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _darkText,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _SeoScoreBadge(score: seoScore),
            ],
          ),
          if (summary.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              summary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: _mutedText, height: 1.4),
            ),
          ],
          const SizedBox(height: 10),
          // Meta chips
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _MetaChip(label: storeSlug, icon: Icons.storefront_rounded),
              _MetaChip(label: articleType, icon: Icons.article_rounded),
              if (targetCity.isNotEmpty)
                _MetaChip(label: targetCity, icon: Icons.location_city_rounded),
              _MetaChip(label: createdAt, icon: Icons.calendar_today_rounded),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          // Action buttons
          if (isProcessing)
            const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Reddet'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Yayınla'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _SeoScoreBadge extends StatelessWidget {
  final int score;

  const _SeoScoreBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score >= 70
        ? const Color(0xFF10B981)
        : score >= 40
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Text(
        'SEO $score',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _MetaChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.cardBorderDark),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.mutedText),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.mutedText),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:vixrex/config/app_router.dart';
import 'package:vixrex/services/article_service.dart';
import 'package:vixrex/theme/app_colors.dart';

/// Mevcut blog yazılarını listeler, tıklayınca düzenlemeye açar.
///
/// Önceden "Blog Yazılarım" kartındaki "Aç" butonu her zaman YENİ bir
/// yazı ekranı açıyordu — mevcut yazılar hiç listelenmiyor, hiç
/// düzenlenemiyordu. Bu ekran o eksiği kapatır: `article_service.dart`
/// içindeki `fetchArticles`/`updateArticle` zaten hazırdı, yalnız bir
/// liste arayüzü eksikti.
class BlogPostListScreen extends StatefulWidget {
  final String storeSlug;

  const BlogPostListScreen({super.key, required this.storeSlug});

  @override
  State<BlogPostListScreen> createState() => _BlogPostListScreenState();
}

class _BlogPostListScreenState extends State<BlogPostListScreen> {
  final _articleService = const ArticleService();
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _articles = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final result = await _articleService.fetchArticles(widget.storeSlug);
    if (!mounted) return;
    if (result.isSuccess) {
      setState(() {
        _articles = result.data ?? const [];
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = 'Yazılar yüklenemedi. Tekrar deneyin.';
        _isLoading = false;
      });
    }
  }

  Future<void> _openNewPost() async {
    await AppRouter.navigateToBlogEditor(context, slug: widget.storeSlug);
    if (mounted) _load();
  }

  Future<void> _openExistingPost(Map<String, dynamic> article) async {
    await AppRouter.navigateToBlogEditor(
      context,
      slug: widget.storeSlug,
      article: article,
    );
    if (mounted) _load();
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'published':
        return 'Yayında';
      case 'review':
        return 'İncelemede';
      case 'draft':
      default:
        return 'Taslak';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgEditor,
      appBar: AppBar(
        backgroundColor: AppColors.bgEditor,
        title: const Text('Blog Yazılarım'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewPost,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Yeni Yazı'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: AppColors.mutedText)),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Tekrar dene')),
          ],
        ),
      );
    }
    if (_articles.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Henüz blog yazısı yok. "Yeni Yazı" ile ilkini ekleyebilirsin.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.mutedText),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount: _articles.length,
      itemBuilder: (context, index) {
        final article = _articles[index];
        final title = (article['title'] as String?)?.trim();
        final status = article['status'] as String?;
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          color: AppColors.surfaceSoft,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
          child: ListTile(
            leading: const Icon(
              Icons.article_outlined,
              color: AppColors.primary,
            ),
            title: Text(
              (title == null || title.isEmpty) ? '(Başlıksız yazı)' : title,
              style: const TextStyle(
                color: AppColors.darkText,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              _statusLabel(status),
              style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _openExistingPost(article),
          ),
        );
      },
    );
  }
}

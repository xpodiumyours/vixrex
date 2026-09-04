import 'package:flutter/material.dart';
import 'package:vixrex/config/app_router.dart';
import 'package:vixrex/services/article_service.dart';
import 'package:vixrex/theme/app_colors.dart';

/// Mevcut blog yazılarını listeler, tıklayınca düzenlemeye açar.
///
/// Katman 3'te aynı ekran içine Vixrex merkezi kütüphanesinden güvenli
/// taslak çekme eylemi eklenir. Ayrı blog yönetim ekranı/backend kurulmaz.
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

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _openVixrexLibrary() async {
    final result = await _articleService.fetchVixrexLibrary(limit: 20);
    if (!mounted) return;
    if (!result.isSuccess) {
      _showMessage('Vixrex kütüphanesi yüklenemedi. Tekrar deneyin.');
      return;
    }

    final library = result.data ?? const <Map<String, dynamic>>[];
    if (library.isEmpty) {
      _showMessage('Şu anda yayında Vixrex yazısı bulunmuyor.');
      return;
    }

    String? importingId;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return SafeArea(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(sheetContext).size.height * 0.82,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.bgEditor,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppColors.radius20),
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Vixrex Kütüphanesi',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                    color: AppColors.darkText,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Yayındaki bir rehberi vitrininize taslak olarak alın.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.mutedText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed:
                                importingId == null
                                    ? () => Navigator.of(sheetContext).pop()
                                    : null,
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: library.length,
                        separatorBuilder:
                            (_, __) => const SizedBox(height: AppColors.spacing12),
                        itemBuilder: (context, index) {
                          final article = library[index];
                          final id = (article['id'] as String?)?.trim() ?? '';
                          final title =
                              (article['title'] as String?)?.trim() ??
                              'Başlıksız yazı';
                          final summary =
                              (article['summary'] as String?)?.trim() ?? '';
                          final minutes = article['reading_minutes'];
                          final topic =
                              (article['primary_topic'] as String?)?.trim() ?? '';
                          final isImporting = importingId == id;

                          Future<void> importWithMode(String mode) async {
                            if (id.isEmpty || importingId != null) return;
                            setSheetState(() => importingId = id);

                            final importResult = await _articleService
                                .importVixrexBlogArticle(
                                  storeSlug: widget.storeSlug,
                                  sourceArticleId: id,
                                  mode: mode,
                                );
                            if (!mounted) return;

                            if (!importResult.isSuccess) {
                              if (Navigator.of(sheetContext).canPop()) {
                                setSheetState(() => importingId = null);
                              }
                              _showMessage(
                                'Yazı vitrininize eklenemedi. Tekrar deneyin.',
                              );
                              return;
                            }

                            final importedSlug =
                                (importResult.data?['article_slug'] as String?)
                                    ?.trim();
                            final refreshed = await _articleService.fetchArticles(
                              widget.storeSlug,
                            );
                            if (!mounted) return;

                            Map<String, dynamic>? importedArticle;
                            if (refreshed.isSuccess && importedSlug != null) {
                              for (final item in refreshed.data ?? const []) {
                                if (item['slug'] == importedSlug) {
                                  importedArticle = item;
                                  break;
                                }
                              }
                            }

                            if (Navigator.of(sheetContext).canPop()) {
                              Navigator.of(sheetContext).pop();
                            }

                            if (importedArticle != null) {
                              await AppRouter.navigateToBlogEditor(
                                context,
                                slug: widget.storeSlug,
                                article: importedArticle,
                              );
                            } else {
                              _showMessage(
                                'Taslak eklendi. Yazı listesi yenileniyor.',
                              );
                            }
                            if (mounted) await _load();
                          }

                          return Card(
                            margin: EdgeInsets.zero,
                            color: AppColors.surfaceSoft,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppColors.radius16,
                              ),
                              side: const BorderSide(color: AppColors.border),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(AppColors.spacing16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      color: AppColors.darkText,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (summary.isNotEmpty) ...[
                                    const SizedBox(height: AppColors.spacing8),
                                    Text(
                                      summary,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.mutedText,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                  if (minutes != null || topic.isNotEmpty) ...[
                                    const SizedBox(height: AppColors.spacing8),
                                    Text(
                                      [
                                        if (minutes != null) '$minutes dk',
                                        if (topic.isNotEmpty) topic,
                                      ].join(' · '),
                                      style: const TextStyle(
                                        color: AppColors.mutedText,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: AppColors.spacing12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed:
                                              importingId == null
                                                  ? () => importWithMode(
                                                    'linked_excerpt',
                                                  )
                                                  : null,
                                          child: Text(
                                            isImporting
                                                ? 'Ekleniyor…'
                                                : 'Kısa sürüm',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: AppColors.spacing8),
                                      Expanded(
                                        child: FilledButton(
                                          onPressed:
                                              importingId == null
                                                  ? () => importWithMode(
                                                    'adaptable_draft',
                                                  )
                                                  : null,
                                          child: Text(
                                            isImporting
                                                ? 'Ekleniyor…'
                                                : 'Uyarlanabilir taslak',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
        actions: [
          TextButton.icon(
            onPressed: _openVixrexLibrary,
            icon: const Icon(Icons.auto_stories_outlined, size: 18),
            label: const Text('Vixrex Kütüphanesi'),
          ),
          const SizedBox(width: AppColors.spacing8),
        ],
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
            'Henüz blog yazısı yok. "Yeni Yazı" veya "Vixrex Kütüphanesi" ile ilkini ekleyebilirsin.',
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
            borderRadius: BorderRadius.circular(AppColors.radius16),
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

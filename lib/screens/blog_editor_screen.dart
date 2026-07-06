import 'package:flutter/material.dart';
import 'package:vixrex/config/turkey_cities_config.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/controllers/blog_editor_controller.dart';
import 'package:vixrex/widgets/editor/blog_seo_panel.dart';
import 'package:vixrex/widgets/editor/blog_cover_picker.dart';
import 'package:vixrex/services/seo_service.dart';

class BlogEditorScreen extends StatefulWidget {
  final String storeSlug;
  final Map<String, dynamic>? initialArticle;

  const BlogEditorScreen({
    super.key,
    required this.storeSlug,
    this.initialArticle,
  });

  @override
  State<BlogEditorScreen> createState() => _BlogEditorScreenState();
}

class _BlogEditorScreenState extends State<BlogEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final BlogEditorController _controller;

  @override
  void initState() {
    super.initState();
    _controller = BlogEditorController(
      storeSlug: widget.storeSlug,
      initialArticle: widget.initialArticle,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _handleSave(String targetStatus) async {
    final success = await _controller.saveArticle(
      targetStatus,
      formKey: _formKey,
      onError: _showSnackBar,
    );

    if (success) {
      _showSnackBar(
        targetStatus == 'published'
            ? 'Yazı yayına gönderildi! (Güvenilir yazar değilseniz önce moderatör incelemesine alınır)'
            : 'Yazı taslak olarak kaydedildi.',
      );

      final slug = _controller.initialArticle != null
          ? (_controller.initialArticle!['slug'] as String?)?.trim() ?? ''
          : 'yazi-${DateTime.now().millisecondsSinceEpoch}';

      const SeoService().revalidateAll(
        storeSlug: widget.storeSlug,
        articleSlug: slug,
      );

      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = AppColors.primary;
    const Color bgColor = AppColors.bgEditor;
    const Color cardBorder = AppColors.cardBorderDark;
    const Color inputBg = AppColors.inputBg;
    const Color darkText = AppColors.darkText;

    final isEdit = widget.initialArticle != null;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: Text(
              isEdit ? 'Yazıyı Düzenle' : 'Yeni Blog Yazısı',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: darkText,
                fontSize: 18,
              ),
            ),
            centerTitle: false,
            actions: [
              if (_controller.isSaving)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppColors.spacing16),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: primaryColor,
                      ),
                    ),
                  ),
                )
              else ...[
                TextButton(
                  onPressed: () => _handleSave('draft'),
                  child: const Text(
                    'Taslak Kaydet',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: AppColors.spacing8),
                  child: ElevatedButton(
                    onPressed: () => _handleSave('published'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppColors.radius12),
                      ),
                    ),
                    child: const Text(
                      'Yayınla',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ],
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppColors.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Real-time SEO score panel
                  BlogSeoPanel(
                    seoScore: _controller.seoScore,
                    seoRecommendations: _controller.seoRecommendations,
                  ),
                  const SizedBox(height: AppColors.spacing16),

                  // Title, Summary & Content Inputs card
                  Container(
                    padding: const EdgeInsets.all(AppColors.spacing16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppColors.radius20),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Makale İçeriği',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: AppColors.spacing16),

                        // Cover image picker
                        BlogCoverPicker(
                          coverBytes: _controller.coverBytes,
                          coverImageUrl: _controller.coverImageUrl,
                          isUploading: _controller.isUploadingCover,
                          onTap: () => _controller.pickCoverPhoto(_showSnackBar),
                        ),
                        const SizedBox(height: AppColors.spacing16),

                        // Title
                        TextFormField(
                          controller: _controller.titleController,
                          maxLength: 80,
                          decoration: const InputDecoration(
                            labelText: 'Yazı Başlığı *',
                            hintText: 'Örn: 2026 Erkek Saç Kesim Trendleri',
                            filled: true,
                            fillColor: inputBg,
                            border: OutlineInputBorder(borderSide: BorderSide.none),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Başlık zorunludur'
                              : null,
                        ),
                        const SizedBox(height: AppColors.spacing12),

                        // Summary
                        TextFormField(
                          controller: _controller.summaryController,
                          maxLines: 2,
                          maxLength: 200,
                          decoration: const InputDecoration(
                            labelText: 'Yazı Özeti (Meta Açıklaması) *',
                            hintText:
                                'Arama sonuçlarında başlığın altında çıkacak kısa özet...',
                            filled: true,
                            fillColor: inputBg,
                            border: OutlineInputBorder(borderSide: BorderSide.none),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Özet zorunludur'
                              : null,
                        ),
                        const SizedBox(height: AppColors.spacing12),

                        // Content
                        TextFormField(
                          controller: _controller.contentController,
                          maxLines: 12,
                          keyboardType: TextInputType.multiline,
                          decoration: const InputDecoration(
                            labelText: 'Makale Metni (İçerik) *',
                            hintText:
                                'Makalenizi buraya yazın. Arama motorları en az 300 kelimelik zengin içerikleri ödüllendirir...',
                            filled: true,
                            fillColor: inputBg,
                            border: OutlineInputBorder(borderSide: BorderSide.none),
                            alignLabelWithHint: true,
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'İçerik zorunludur'
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppColors.spacing16),

                  // Target SEO Configuration card
                  Container(
                    padding: const EdgeInsets.all(AppColors.spacing16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppColors.radius20),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SEO & Hedefleme Parametreleri',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: AppColors.spacing16),

                        // Article Type dropdown
                        DropdownButtonFormField<String>(
                          value: _controller.articleType,
                          decoration: const InputDecoration(
                            labelText: 'Yazı Türü',
                            filled: true,
                            fillColor: inputBg,
                            border: OutlineInputBorder(borderSide: BorderSide.none),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'standard',
                              child: Text('Standart Rehber / Blog'),
                            ),
                            DropdownMenuItem(
                              value: 'news',
                              child: Text('Duyuru / Haber'),
                            ),
                            DropdownMenuItem(
                              value: 'promotion',
                              child: Text('Kampanya / Promosyon'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              _controller.setArticleType(val);
                            }
                          },
                        ),
                        const SizedBox(height: AppColors.spacing12),

                        // Target Topic
                        TextFormField(
                          controller: _controller.topicController,
                          decoration: const InputDecoration(
                            labelText: 'Hedef Anahtar Kelime / Konu',
                            hintText: 'Örn: cilt bakımı',
                            filled: true,
                            fillColor: inputBg,
                            border: OutlineInputBorder(borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: AppColors.spacing12),

                        // Target City dropdown / autocomplete
                        DropdownButtonFormField<String>(
                          value: _controller.cityController.text.isEmpty
                              ? null
                              : turkeyProvinces.any(
                                  (p) => p.name == _controller.cityController.text,
                                )
                                  ? _controller.cityController.text
                                  : null,
                          decoration: const InputDecoration(
                            labelText: 'Hedef Şehir (Yerel SEO)',
                            filled: true,
                            fillColor: inputBg,
                            border: OutlineInputBorder(borderSide: BorderSide.none),
                          ),
                          hint: const Text('Şehir Seçiniz'),
                          items: turkeyProvinces.map((Province p) {
                            return DropdownMenuItem<String>(
                              value: p.name,
                              child: Text(p.name),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              _controller.setCity(val);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppColors.spacing40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

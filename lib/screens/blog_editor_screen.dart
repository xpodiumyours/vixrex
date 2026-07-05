import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:vitrinx/config/turkey_cities_config.dart';
import 'package:vitrinx/services/article_service.dart';
import 'package:vitrinx/services/store_shelf_upload_service.dart';
import 'package:vitrinx/services/store_publish_service.dart';
import 'package:vitrinx/services/seo_service.dart';
import 'package:vitrinx/theme/app_colors.dart';

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

  // Controllers
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _contentController = TextEditingController();
  final _topicController = TextEditingController();
  final _cityController = TextEditingController();

  // State
  String _articleType = 'standard';
  String? _coverImageUrl;
  Uint8List? _coverBytes;
  String _coverExtension = 'jpg';
  String _coverContentType = 'image/jpeg';

  bool _isSaving = false;
  bool _isUploadingCover = false;

  // SEO Scores
  int _seoScore = 0;
  List<String> _seoRecommendations = [];

  @override
  void initState() {
    super.initState();

    // Load initial values if editing
    if (widget.initialArticle != null) {
      final art = widget.initialArticle!;
      _titleController.text = art['title'] ?? '';
      _summaryController.text = art['summary'] ?? '';
      _contentController.text = art['content'] ?? '';
      _topicController.text = art['target_topic'] ?? '';
      _cityController.text = art['target_city'] ?? '';
      _articleType = art['article_type'] ?? 'standard';
      _coverImageUrl = art['cover_image_url'];
    }

    // Add listeners for real-time SEO scoring
    _titleController.addListener(_updateSeoAnalysis);
    _summaryController.addListener(_updateSeoAnalysis);
    _contentController.addListener(_updateSeoAnalysis);
    _topicController.addListener(_updateSeoAnalysis);
    _cityController.addListener(_updateSeoAnalysis);

    _updateSeoAnalysis();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _contentController.dispose();
    _topicController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  // Real-time SEO Analyzer
  void _updateSeoAnalysis() {
    int score = 0;
    final recs = <String>[];

    final title = _titleController.text.trim();
    final summary = _summaryController.text.trim();
    final content = _contentController.text.trim();
    final topic = _topicController.text.trim().toLowerCase();
    final city = _cityController.text.trim().toLowerCase();

    // 1. Title length checks (Max 20 pts)
    if (title.isEmpty) {
      recs.add("• Başlık ekleyin (Tavsiye: 30-60 karakter)");
    } else if (title.length < 30) {
      score += 10;
      recs.add(
        "• Başlık çok kısa (${title.length} karakter). Arama motorları için en az 30 karakter yapın.",
      );
    } else if (title.length > 60) {
      score += 10;
      recs.add(
        "• Başlık çok uzun (${title.length} karakter). 60 karakteri aşmamalıdır.",
      );
    } else {
      score += 20;
    }

    // 2. Summary length checks (Max 20 pts)
    if (summary.isEmpty) {
      recs.add("• Kısa özet yazın (Tavsiye: 80-160 karakter)");
    } else if (summary.length < 80) {
      score += 10;
      recs.add(
        "• Özet çok kısa (${summary.length} karakter). En az 80 karakter yapın.",
      );
    } else if (summary.length > 160) {
      score += 10;
      recs.add(
        "• Özet çok uzun (${summary.length} karakter). 160 karakteri aşmamalıdır.",
      );
    } else {
      score += 20;
    }

    // 3. Word count checks (Max 20 pts)
    final words = content.isEmpty ? 0 : content.split(RegExp(r'\s+')).length;
    if (words == 0) {
      recs.add("• İçerik metni yazın (En az 300 kelime)");
    } else if (words < 150) {
      score += 5;
      recs.add(
        "• İçerik çok yetersiz ($words kelime). En az 300 kelime olmalı.",
      );
    } else if (words < 300) {
      score += 12;
      recs.add(
        "• İçerik geliştirilebilir ($words kelime). En az 300 kelime önerilir.",
      );
    } else {
      score += 20;
    }

    // 4. Cover Image check (Max 15 pts)
    if (_coverImageUrl != null || _coverBytes != null) {
      score += 15;
    } else {
      recs.add("• Yazıya bir kapak fotoğrafı ekleyin.");
    }

    // 5. SEO Topic check (Max 15 pts)
    if (topic.isNotEmpty) {
      if (title.toLowerCase().contains(topic) ||
          content.toLowerCase().contains(topic)) {
        score += 10;
      } else {
        recs.add(
          "• Hedef kelimeyi ('$topic') başlıkta veya yazının içinde geçirin.",
        );
      }
    } else {
      recs.add(
        "• Arama motorlarında öne çıkmak için hedef anahtar kelime belirleyin.",
      );
    }

    // 6. Target City check (Max 10 pts)
    if (city.isNotEmpty) {
      if (title.toLowerCase().contains(city) ||
          content.toLowerCase().contains(city)) {
        score += 10;
      } else {
        recs.add(
          "• Yerel aramalarda çıkmak için hedef şehri ('$city') başlık veya içerikte kullanın.",
        );
      }
    }

    setState(() {
      _seoScore = score;
      _seoRecommendations = recs;
    });
  }

  // Cover Image upload helper
  Future<void> _pickCoverPhoto() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.bytes == null) return;

      setState(() {
        _coverBytes = file.bytes;
        _coverExtension = file.extension ?? 'jpg';
        _coverContentType =
            _coverExtension == 'png' ? 'image/png' : 'image/jpeg';
      });

      _updateSeoAnalysis();
    } catch (e) {
      _showSnackBar('Görsel seçilirken hata oluştu.');
    }
  }

  // Save / Publish
  Future<void> _saveArticle(String targetStatus) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final title = _titleController.text.trim();
      final slug = const StorePublishPayloadBuilder().generateSlug(title);
      final cleanSlug = slug.replaceAll(RegExp(r'[^a-z0-9-]'), '');

      var finalCoverUrl = _coverImageUrl;

      // 1. Upload cover if local bytes present
      if (_coverBytes != null) {
        setState(() => _isUploadingCover = true);
        try {
          finalCoverUrl = await const StoreShelfUploadService().uploadShelfImage(
            _coverBytes!,
            '${widget.storeSlug}/blog/${DateTime.now().millisecondsSinceEpoch}',
            fileExtension: _coverExtension,
            contentType: _coverContentType,
          );
        } catch (e) {
          throw Exception('Kapak fotoğrafı sunucuya yüklenemedi: $e');
        } finally {
          setState(() => _isUploadingCover = false);
        }
      }

      // 2. Slug üretimi: güncelleme sırasında mevcut slug korunur
      String finalSlug;
      if (widget.initialArticle != null) {
        // Düzenleme: slug değiştirme (URL kırılmasını önle)
        finalSlug =
            (widget.initialArticle!['slug'] as String?)?.trim() ?? cleanSlug;
      } else {
        // Yeni yazı: slug boşsa timestamp suffix ekle
        finalSlug =
            cleanSlug.isNotEmpty
                ? cleanSlug
                : 'yazi-${DateTime.now().millisecondsSinceEpoch}';
      }

      // 3. Prepare database save payload
      final payload = {
        'store_slug': widget.storeSlug,
        'title': title,
        'summary': _summaryController.text.trim(),
        'content': _contentController.text.trim(),
        'cover_image_url': finalCoverUrl,
        'article_type': _articleType,
        'target_topic': _topicController.text.trim(),
        'target_city': _cityController.text.trim(),
        'seo_score': _seoScore,
        'seo_errors': _seoRecommendations,
        'slug': finalSlug,
        'status':
            targetStatus, // 'draft' or 'published' (trigger shifts to 'review' if not trusted)
      };

      if (widget.initialArticle == null) {
        // Create new article
        await const ArticleService().createArticle(payload);
        _showSnackBar(
          targetStatus == 'published'
              ? 'Yazı yayına gönderildi! (Güvenilir yazar değilseniz önce moderatör incelemesine alınır)'
              : 'Yazı taslak olarak kaydedildi.',
        );
      } else {
        // Update existing (slug'ı payload'dan çıkar — URL değişmesin)
        final updatePayload = Map<String, dynamic>.from(payload)
          ..remove('slug');
        await const ArticleService().updateArticle(
          id: widget.initialArticle!['id'],
          payload: updatePayload,
        );
        _showSnackBar('Değişiklikler başarıyla kaydedildi.');
      }

      // Next.js ISR önbelleğini arka planda temizle
      const SeoService().revalidateAll(
        storeSlug: widget.storeSlug,
        articleSlug: finalSlug,
      );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint("Save article error: $e");
      _showSnackBar('Kaydetme hatası: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
    const Color primaryColor = AppColors.primary;
    const Color bgColor = AppColors.bgEditor;
    const Color cardBorder = AppColors.cardBorderDark;
    const Color inputBg = AppColors.inputBg;
    const Color darkText = AppColors.darkText;

    final isEdit = widget.initialArticle != null;

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
          if (_isSaving)
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
              onPressed: () => _saveArticle('draft'),
              child: const Text(
                'Taslak Kaydet',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: AppColors.spacing8),
              child: ElevatedButton(
                onPressed: () => _saveArticle('published'),
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
              _buildSeoAnalysisCard(),
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
                    _buildCoverPickerWidget(),
                    const SizedBox(height: AppColors.spacing16),

                    // Title
                    TextFormField(
                      controller: _titleController,
                      maxLength: 80,
                      decoration: const InputDecoration(
                        labelText: 'Yazı Başlığı *',
                        hintText: 'Örn: 2026 Erkek Saç Kesim Trendleri',
                        filled: true,
                        fillColor: inputBg,
                        border: OutlineInputBorder(borderSide: BorderSide.none),
                      ),
                      validator:
                          (v) =>
                              v == null || v.trim().isEmpty
                                  ? 'Başlık zorunludur'
                                  : null,
                    ),
                    const SizedBox(height: AppColors.spacing12),

                    // Summary
                    TextFormField(
                      controller: _summaryController,
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
                      validator:
                          (v) =>
                              v == null || v.trim().isEmpty
                                  ? 'Özet zorunludur'
                                  : null,
                    ),
                    const SizedBox(height: AppColors.spacing12),

                    // Content
                    TextFormField(
                      controller: _contentController,
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
                      validator:
                          (v) =>
                              v == null || v.trim().isEmpty
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
                      initialValue: _articleType,
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
                          setState(() => _articleType = val);
                          _updateSeoAnalysis();
                        }
                      },
                    ),
                    const SizedBox(height: AppColors.spacing12),

                    // Target Topic
                    TextFormField(
                      controller: _topicController,
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
                      initialValue:
                          _cityController.text.isEmpty
                              ? null
                              : turkeyProvinces.any(
                                (p) => p.name == _cityController.text,
                              )
                              ? _cityController.text
                              : null,
                      decoration: const InputDecoration(
                        labelText: 'Hedef Şehir (Yerel SEO)',
                        filled: true,
                        fillColor: inputBg,
                        border: OutlineInputBorder(borderSide: BorderSide.none),
                      ),
                      hint: const Text('Şehir Seçiniz'),
                      items:
                          turkeyProvinces.map((Province p) {
                            return DropdownMenuItem<String>(
                              value: p.name,
                              child: Text(p.name),
                            );
                          }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _cityController.text = val);
                          _updateSeoAnalysis();
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
  }

  Widget _buildCoverPickerWidget() {
    final hasCover =
        _coverBytes != null ||
        (_coverImageUrl != null && _coverImageUrl!.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kapak Fotoğrafı',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11,
            color: AppColors.softText,
          ),
        ),
        const SizedBox(height: AppColors.spacing8),
        InkWell(
          onTap: _pickCoverPhoto,
          borderRadius: BorderRadius.circular(AppColors.radius12),
          child: AspectRatio(
            aspectRatio: 16 / 7,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.inputBg,
                borderRadius: BorderRadius.circular(AppColors.radius12),
                border: Border.all(color: AppColors.cardBorderDark),
              ),
              clipBehavior: Clip.antiAlias,
              child:
                  _isUploadingCover
                      ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                      : hasCover
                      ? Stack(
                        fit: StackFit.expand,
                        children: [
                          _coverBytes != null
                              ? Image.memory(_coverBytes!, fit: BoxFit.cover)
                              : Image.network(
                                _coverImageUrl!,
                                fit: BoxFit.cover,
                              ),
                          Container(color: Colors.black38),
                          const Center(
                            child: Icon(
                              Icons.photo_library_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ],
                      )
                      : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_rounded,
                            color: AppColors.mutedText,
                            size: 28,
                          ),
                          SizedBox(height: AppColors.spacing8),
                          Text(
                            'Fotoğraf Seç',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.mutedText,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeoAnalysisCard() {
    Color scoreColor = Colors.orange;
    if (_seoScore >= 80) {
      scoreColor = Colors.green;
    } else if (_seoScore >= 40) {
      scoreColor = Colors.amber.shade700;
    }

    return Container(
      padding: const EdgeInsets.all(AppColors.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppColors.radius20),
        border: Border.all(color: AppColors.cardBorderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.analytics_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Canlı SEO Analizi',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppColors.spacing12,
                  vertical: AppColors.spacing8,
                ),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppColors.radius20),
                  border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Skor: $_seoScore / 100',
                  style: TextStyle(
                    color: scoreColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppColors.spacing12),
          if (_seoRecommendations.isEmpty)
            const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
                SizedBox(width: 6),
                Text(
                  'Harika! Yazınız mükemmel şekilde optimize edildi.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          else ...[
            const Text(
              'Geliştirme Tavsiyeleri:',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.softText,
              ),
            ),
            const SizedBox(height: AppColors.spacing8),
            ..._seoRecommendations
                .take(3)
                .map(
                  (rec) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text(
                      rec,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.mutedText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            if (_seoRecommendations.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Text(
                  've ${_seoRecommendations.length - 3} tavsiye daha var...',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.mutedText,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

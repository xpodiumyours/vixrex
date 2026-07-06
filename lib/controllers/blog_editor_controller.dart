import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:vixrex/services/article_service.dart';
import 'package:vixrex/services/seo_analysis_service.dart';
import 'package:vixrex/services/store_publish_service.dart';
import 'package:vixrex/services/store_shelf_upload_service.dart';

class BlogEditorController extends ChangeNotifier {
  final String storeSlug;
  final Map<String, dynamic>? initialArticle;
  final SeoAnalysisService seoService;

  // Controllers / Inputs
  final titleController = TextEditingController();
  final summaryController = TextEditingController();
  final contentController = TextEditingController();
  final topicController = TextEditingController();
  final cityController = TextEditingController();
  String articleType = 'standard';

  // State variables
  String? coverImageUrl;
  Uint8List? coverBytes;
  String coverExtension = 'jpg';
  String coverContentType = 'image/jpeg';

  bool isSaving = false;
  bool isUploadingCover = false;

  // SEO Analysis state
  int seoScore = 0;
  List<String> seoRecommendations = [];

  BlogEditorController({
    required this.storeSlug,
    this.initialArticle,
    this.seoService = const SeoAnalysisService(),
  }) {
    _initialize();
  }

  void _initialize() {
    if (initialArticle != null) {
      final art = initialArticle!;
      titleController.text = art['title'] ?? '';
      summaryController.text = art['summary'] ?? '';
      contentController.text = art['content'] ?? '';
      topicController.text = art['target_topic'] ?? '';
      cityController.text = art['target_city'] ?? '';
      articleType = art['article_type'] ?? 'standard';
      coverImageUrl = art['cover_image_url'];
    }

    titleController.addListener(updateSeoAnalysis);
    summaryController.addListener(updateSeoAnalysis);
    contentController.addListener(updateSeoAnalysis);
    topicController.addListener(updateSeoAnalysis);
    cityController.addListener(updateSeoAnalysis);

    updateSeoAnalysis();
  }

  void setArticleType(String type) {
    articleType = type;
    updateSeoAnalysis();
  }

  void setCity(String city) {
    cityController.text = city;
    updateSeoAnalysis();
  }

  void updateSeoAnalysis() {
    final hasCover = coverBytes != null || (coverImageUrl != null && coverImageUrl!.isNotEmpty);
    final result = seoService.analyze(
      title: titleController.text,
      summary: summaryController.text,
      content: contentController.text,
      topic: topicController.text,
      city: cityController.text,
      hasCover: hasCover,
    );

    seoScore = result.score;
    seoRecommendations = result.recommendations;
    notifyListeners();
  }

  Future<bool> pickCoverPhoto(void Function(String) onError) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return false;

      final file = result.files.first;
      if (file.bytes == null) return false;

      coverBytes = file.bytes;
      coverExtension = file.extension ?? 'jpg';
      coverContentType = coverExtension == 'png' ? 'image/png' : 'image/jpeg';
      
      updateSeoAnalysis();
      return true;
    } catch (_) {
      onError('Görsel seçilirken hata oluştu.');
      return false;
    }
  }

  Future<bool> saveArticle(
    String targetStatus, {
    required GlobalKey<FormState> formKey,
    required void Function(String) onError,
  }) async {
    if (!formKey.currentState!.validate()) return false;

    isSaving = true;
    notifyListeners();

    try {
      final title = titleController.text.trim();
      final slug = const StorePublishPayloadBuilder().generateSlug(title);
      final cleanSlug = slug.replaceAll(RegExp(r'[^a-z0-9-]'), '');

      var finalCoverUrl = coverImageUrl;

      if (coverBytes != null) {
        isUploadingCover = true;
        notifyListeners();
        try {
          finalCoverUrl = await const StoreShelfUploadService().uploadShelfImage(
            coverBytes!,
            '$storeSlug/blog/${DateTime.now().millisecondsSinceEpoch}',
            fileExtension: coverExtension,
            contentType: coverContentType,
          );
        } catch (e) {
          throw Exception('Kapak fotoğrafı sunucuya yüklenemedi: $e');
        } finally {
          isUploadingCover = false;
          notifyListeners();
        }
      }

      String finalSlug;
      if (initialArticle != null) {
        finalSlug = (initialArticle!['slug'] as String?)?.trim() ?? cleanSlug;
      } else {
        finalSlug = cleanSlug;
      }

      final payload = {
        'store_slug': storeSlug,
        'title': title,
        'summary': summaryController.text.trim(),
        'content': contentController.text.trim(),
        'cover_image_url': finalCoverUrl,
        'article_type': articleType,
        'target_topic': topicController.text.trim(),
        'target_city': cityController.text.trim(),
        'seo_score': seoScore,
        'seo_errors': seoRecommendations,
        'status': targetStatus,
        'slug': finalSlug,
      };

      if (initialArticle != null) {
        final artId = initialArticle!['id'] as String;
        final updatePayload = Map<String, dynamic>.from(payload)..remove('slug');
        await const ArticleService().updateArticle(id: artId, payload: updatePayload);
      } else {
        await const ArticleService().createArticle(payload);
      }

      isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      isSaving = false;
      notifyListeners();
      onError(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    summaryController.dispose();
    contentController.dispose();
    topicController.dispose();
    cityController.dispose();
    super.dispose();
  }
}

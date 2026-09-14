import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vixrex/config/app_router.dart';
import 'package:vixrex/config/instagram_sync_config.dart';
import 'package:vixrex/controllers/ocr_controller.dart';
import 'package:vixrex/controllers/store_editor_controller.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/screens/my_vitrin/my_vitrin_state.dart';
import 'package:vixrex/screens/ocr_scanner_screen.dart';
import 'package:vixrex/services/ocr/ocr_service.dart';
import 'package:vixrex/services/store_publish_payload_builder.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/widgets/editor/about_editor_sheet.dart';
import 'package:vixrex/widgets/editor/about_entry_card.dart';
import 'package:vixrex/widgets/editor/blog_entry_card.dart';
import 'package:vixrex/widgets/editor/common_form_fields.dart';
import 'package:vixrex/widgets/editor/faq_editor_sheet.dart';
import 'package:vixrex/widgets/editor/faq_entry_card.dart';
import 'package:vixrex/widgets/editor/featured_campaign_entry_card.dart';
import 'package:vixrex/widgets/editor/featured_campaign_sheet.dart';
import 'package:vixrex/widgets/editor/form_marketplace_links.dart';
import 'package:vixrex/widgets/editor/section_visibility_card.dart';
import 'package:vixrex/widgets/editor/sections/spaced_column.dart';
import 'package:vixrex/widgets/instagram_sync_section.dart';
import 'package:vixrex/widgets/product/product_management_entry_card.dart';
import 'package:vixrex/widgets/product/product_management_sheet.dart';
import 'package:vixrex/config/vitrin_alan_bilgisi.dart';

/// İçerik ve SEO bölümü — Instagram senkron, hakkımızda, ürünler, kampanya,
/// SSS, blog, vitrin durumu, Google yorum linki, pazaryeri linkleri ve
/// bölüm görünürlüğü.
///
/// Faz 0 kalanı (Tek Asistan planı): vitrin_form_section.dart'ın altı bölüm
/// gövdesinden biri — en kalabalık bölüm, çünkü orijinalde de öyleydi.
class IcerikSeoBolumu extends StatelessWidget {
  const IcerikSeoBolumu({
    super.key,
    required this.controller,
    required this.state,
    required this.hasPublished,
    required this.instagramController,
    required this.referencesController,
    required this.categorySectionTitleController,
    required this.productSectionTitleController,
    required this.blogKickerController,
    required this.blogTitleController,
    required this.faqKickerController,
    required this.faqTitleController,
    required this.faqDescriptionController,
    required this.googleBusinessController,
  });

  final StoreEditorController controller;
  final MyVitrinState state;
  final bool hasPublished;
  final TextEditingController instagramController;
  final TextEditingController referencesController;
  final TextEditingController categorySectionTitleController;
  final TextEditingController productSectionTitleController;
  final TextEditingController blogKickerController;
  final TextEditingController blogTitleController;
  final TextEditingController faqKickerController;
  final TextEditingController faqTitleController;
  final TextEditingController faqDescriptionController;
  final TextEditingController googleBusinessController;

  static const _platformOptions = [
    'Trendyol',
    'Hepsiburada',
    'N11',
    'Amazon',
    'Çiçeksepeti',
    'Shopier',
    'Google İşletme',
    'Diğer',
    'Özel...',
  ];

  @override
  Widget build(BuildContext context) {
    return SpacedColumn(
      children: [
        if (hasPublished && InstagramSyncConfig.enabled)
          InstagramSyncSection(
            storeSlug: controller.publishedInfo!.slug,
            editToken: controller.publishedInfo!.editToken,
            defaultCategory: controller.selectedKategori,
            onProductImported: controller.updateProductImported,
            onMessage: (msg) => state.showSnackBar(context, msg),
            onConnectedUsername: _applyConnectedInstagram,
          ),
        AboutEntryCard(
          hasContent: controller.hasAboutSection,
          onTap: () => _showAboutSheet(context),
        ),
        EditorTextField(
          label: vitrinAlanEtiketi('referansLinki'),
          controller: referencesController,
          hint: 'https://...',
          icon: Icons.link_rounded,
          keyboardType: TextInputType.url,
          onChanged: (v) => controller.updateReferencesLink(v),
        ),
        _buildCatalogSectionTitles(),
        KeyedSubtree(
          key: state.productsKey,
          child: ProductManagementEntryCard(
            productCount: controller.data.products.length,
            onTap: () => _showProductSheet(context),
          ),
        ),
        FeaturedCampaignEntryCard(
          hasCampaign: controller.hasFeaturedCampaign,
          onTap: () => _showFeaturedCampaignSheet(context),
        ),
        FaqEntryCard(
          faqCount: controller.data.faqItems.length,
          onTap: () => _showFaqSheet(context),
        ),
        _buildBlogSectionTitles(),
        BlogEntryCard(
          canOpen:
              (controller.publishedInfo?.slug.trim().isNotEmpty ?? false) ||
              controller.data.slug.trim().isNotEmpty,
          onTap: () => _openBlogEditor(context),
        ),
        EditorDropdownField(
          label: 'Vitrin Durumu',
          value: controller.selectedStatus,
          items: const [
            'Açık',
            'Bugün kampanya var',
            'Yeni ürünler geldi',
            'Stok sınırlı',
            'Kapalı',
          ],
          icon: Icons.info_outline_rounded,
          onChanged: (val) => controller.selectStatus(val ?? 'Açık'),
        ),
        EditorTextField(
          label: 'Google Yorum Bağlantısı',
          controller: googleBusinessController,
          hint: 'https://search.google.com/local/writereview?placeid=...',
          icon: Icons.rate_review_rounded,
          keyboardType: TextInputType.url,
          errorText: controller.googleLinkError,
          onChanged: (value) {
            controller.updateGoogleBusinessLink(value);
            controller.clearValidationErrors();
          },
        ),
        _buildRatingToggle(),
        FormMarketplaceLinks(
          controller: controller,
          platformOptions: _platformOptions,
        ),
        SectionVisibilityCard(
          visibility: controller.data.sectionVisibility,
          onChanged: controller.updateSectionVisibility,
        ),
      ],
    );
  }

  Widget _buildCatalogSectionTitles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EditorTextField(
          label: vitrinAlanEtiketi('kategoriBolumBaslik'),
          controller: categorySectionTitleController,
          hint: 'Örn: Servis Alanlarımız',
          icon: Icons.category_outlined,
          maxLength: 60,
          onChanged: (v) => controller.updateCategorySectionTitle(v),
        ),
        const SizedBox(height: 12),
        EditorTextField(
          label: vitrinAlanEtiketi('urunBolumBaslik'),
          controller: productSectionTitleController,
          hint: 'Örn: Servis Fiyat Listesi',
          icon: Icons.inventory_2_outlined,
          maxLength: 60,
          onChanged: (v) => controller.updateProductSectionTitle(v),
        ),
      ],
    );
  }

  Widget _buildBlogSectionTitles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EditorTextField(
          label: vitrinAlanEtiketi('blogUstBaslik'),
          controller: blogKickerController,
          hint: 'Örn: Teknik rehber',
          icon: Icons.label_outline_rounded,
          maxLength: 40,
          onChanged: (v) => controller.updateBlogSectionKicker(v),
        ),
        const SizedBox(height: 12),
        EditorTextField(
          label: vitrinAlanEtiketi('blogBaslik'),
          controller: blogTitleController,
          hint: 'Örn: Mağazadan Haberler',
          icon: Icons.article_outlined,
          maxLength: 90,
          onChanged: (v) => controller.updateBlogSectionTitle(v),
        ),
      ],
    );
  }

  // ListTile türevleri mürekkep efektini en yakın Material üzerine çizer.
  // Bu, arka planı olan bir Container'ın içinde duruyor; araya Material
  // konmazsa Flutter "efektler görünmez olacak" diye assertion fırlatıyor.
  Widget _buildRatingToggle() {
    return Material(
      type: MaterialType.transparency,
      child: SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: const Text(
          'Vitrinde puan bandı göster',
          style: TextStyle(
            color: AppColors.darkText,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: const Text(
          'Gerçek puanın yoksa kapalı kalsın; örnek puan görünmesin.',
          style: TextStyle(color: AppColors.mutedText, fontSize: 11),
        ),
        value: controller.data.showStorefrontRating,
        activeThumbColor: AppColors.primary,
        onChanged: (value) {
          controller.updateShowStorefrontRating(value);
          controller.saveLocally();
        },
      ),
    );
  }

  Future<void> _applyConnectedInstagram(String username) async {
    final cleaned = username.trim().replaceFirst('@', '');
    if (cleaned.isEmpty) return;
    final handle = '@$cleaned';
    instagramController.text = handle;
    final result = await controller.applyConnectedInstagramUsername(cleaned);
    if (result.isFailure) {
      // Yerel alan yine dolu; yayın/yeniden kaydet ile düzelir.
      if (kDebugMode) {
        debugPrint('_applyConnectedInstagram: ${result.failure?.message}');
      }
    }
  }

  void _showProductSheet(BuildContext ctx) {
    final slug =
        controller.data.slug.trim().isNotEmpty
            ? controller.data.slug.trim()
            : StorePublishPayloadBuilder().generateSlug(controller.data.name);
    showModalBottomSheet(
      context: ctx,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (_) => ProductManagementSheet(
            products: controller.data.products,
            categories: controller.data.productCategories,
            storeSlug: slug,
            storeId: controller.data.id?.trim() ?? '',
            editToken: controller.publishedInfo?.editToken.trim() ?? '',
            showMessage: (msg) => state.showSnackBar(ctx, msg),
            onCatalogChanged: (products, categories) async {
              final publishedToken =
                  controller.publishedInfo?.editToken.trim() ?? '';
              if (publishedToken.isEmpty) {
                // Yayın öncesi eski akışı koru: ürünler taslakta kaybolmaz.
                // İlk public yayında StorePublishService aynı veriyi önce
                // görünmeyen draft store'a Product CORE olarak stage eder.
                controller.data.products = List<Product>.of(products);
                controller.data.productCategories =
                    List<ProductCategory>.of(categories);
                await controller.saveLocally();
                controller.notifyStoreDataChanged();
                return true;
              }

              final sync = await controller.syncCatalogToRemote(
                products: products,
                categories: categories,
              );
              if (sync.isFailure && ctx.mounted) {
                state.showSnackBar(
                  ctx,
                  sync.failure?.message ??
                      'Ürünler kaydedilemedi, lütfen tekrar deneyin.',
                );
              }
              return sync.isSuccess;
            },
            onProductDelete: (product) async {
              final publishedToken =
                  controller.publishedInfo?.editToken.trim() ?? '';
              if (publishedToken.isEmpty) {
                controller.data.products.removeWhere(
                  (item) => item.id == product.id,
                );
                await controller.saveLocally();
                controller.notifyStoreDataChanged();
                return true;
              }

              final result = await controller.removeProductById(product.id);
              if (result.isFailure && ctx.mounted) {
                state.showSnackBar(
                  ctx,
                  result.failure?.message ?? 'Ürün silinemedi.',
                );
                return false;
              }
              return result.isSuccess;
            },
            onOcrTap: () {
              // Alt paneli kapat, sonra root navigator'dan OCR ekranını aç
              Navigator.of(ctx).pop();
              // Root navigator'u kullanarak navigasyon yap
              Navigator.of(ctx, rootNavigator: true).push(
                MaterialPageRoute(
                  builder:
                      (_) => OcrScannerScreen(
                        ocrController: OcrController(
                          ocrService: const OcrService(),
                          editorController: controller,
                        ),
                      ),
                ),
              );
            },
          ),
    );
  }

  Future<void> _showFeaturedCampaignSheet(BuildContext ctx) async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: ctx,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => FeaturedCampaignSheet(storeData: controller.data),
    );
    if (result == null) return;
    controller.updateFeaturedCampaign(
      label: result['label'] ?? '',
      title: result['title'] ?? '',
      body: (result['body'] as String?) ?? '',
      description: result['description'] ?? '',
      priceText: result['priceText'] ?? '',
      imageUrl: result['imageUrl'] ?? '',
    );
    await controller.saveLocally();
    if (ctx.mounted) {
      state.showSnackBar(ctx, 'Kampanya bilgileri kaydedildi.');
    }
  }

  Future<void> _showAboutSheet(BuildContext ctx) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: ctx,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AboutEditorSheet(storeData: controller.data),
    );
    if (result == null) return;
    final values = (result['values'] as List<StoreAboutValue>?) ?? const [];
    controller.updateAboutSection(
      kicker: (result['kicker'] as String?) ?? '',
      title: (result['title'] as String?) ?? '',
      body: (result['body'] as String?) ?? '',
      imageUrl: (result['imageUrl'] as String?) ?? '',
      imageCaption: (result['imageCaption'] as String?) ?? '',
      values: values,
    );
    await controller.saveLocally();
    if (ctx.mounted) {
      state.showSnackBar(ctx, 'Hakkımızda kaydedildi.');
    }
  }

  Future<void> _showFaqSheet(BuildContext ctx) async {
    final result = await showModalBottomSheet<List<StoreFaqItem>>(
      context: ctx,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (_) => FaqEditorSheet(
            items: controller.data.faqItems,
            kickerController: faqKickerController,
            titleController: faqTitleController,
            descriptionController: faqDescriptionController,
            onKickerChanged: (v) => controller.updateFaqSectionKicker(v),
            onTitleChanged: (v) => controller.updateFaqSectionTitle(v),
            onDescriptionChanged:
                (v) => controller.updateFaqSectionDescription(v),
          ),
    );
    if (result == null) return;
    controller.updateFaqItems(result);
    await controller.saveLocally();
    if (ctx.mounted) {
      state.showSnackBar(ctx, 'SSS kaydedildi.');
    }
  }

  Future<void> _openBlogEditor(BuildContext ctx) async {
    final slug =
        (controller.publishedInfo?.slug.trim().isNotEmpty ?? false)
            ? controller.publishedInfo!.slug.trim()
            : controller.data.slug.trim();
    if (slug.isEmpty) {
      state.showSnackBar(ctx, 'Blog için önce vitrini yayınlayın.');
      return;
    }
    await AppRouter.navigateToBlogPostList(ctx, slug: slug);
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart' as img_picker;
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vixrex/config/app_router.dart';
import 'package:vixrex/config/business_category_config.dart';
import 'package:vixrex/config/instagram_sync_config.dart';
import 'package:vixrex/config/public_site_config.dart';
import 'package:vixrex/controllers/ocr_controller.dart';
import 'package:vixrex/controllers/store_editor_controller.dart';
import 'package:vixrex/models/chat_message.dart';
import 'package:vixrex/models/editor_gallery_item.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/screens/ocr_scanner_screen.dart';
import 'package:vixrex/screens/my_vitrin/my_vitrin_state.dart';
import 'package:vixrex/services/category_image_service.dart';
import 'package:vixrex/services/ocr/ocr_service.dart';
import 'package:vixrex/services/store_publish_payload_builder.dart';
import 'package:vixrex/services/store_publish_service.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/utils/gallery_image_file_validator.dart';
import 'package:vixrex/widgets/auto_fill/category_gallery_sheet.dart';
import 'package:vixrex/widgets/editor/common_form_fields.dart';
import 'package:vixrex/widgets/editor/gallery_editor_section.dart';
import 'package:vixrex/widgets/editor/legal_consent_section.dart';
import 'package:vixrex/widgets/editor/public_link_card.dart';
import 'package:vixrex/widgets/google_business_guide_card.dart';
import 'package:vixrex/widgets/editor/blog_entry_card.dart';
import 'package:vixrex/widgets/editor/about_entry_card.dart';
import 'package:vixrex/widgets/editor/about_editor_sheet.dart';
import 'package:vixrex/widgets/editor/faq_entry_card.dart';
import 'package:vixrex/widgets/editor/faq_editor_sheet.dart';
import 'package:vixrex/widgets/editor/featured_campaign_entry_card.dart';
import 'package:vixrex/widgets/editor/featured_campaign_sheet.dart';
import 'package:vixrex/widgets/editor/form_media_picker.dart';
import 'package:vixrex/widgets/editor/working_hours_editor.dart';
import 'package:vixrex/widgets/instagram_sync_section.dart';
import 'package:vixrex/widgets/product/product_management_entry_card.dart';
import 'package:vixrex/widgets/product/product_management_sheet.dart';
import 'package:vixrex/widgets/editor/form_location_info.dart';
import 'package:vixrex/widgets/editor/form_marketplace_links.dart';
import 'package:vixrex/widgets/editor/section_visibility_card.dart';

class VitrinFormSection extends StatelessWidget {
  final StoreEditorController controller;
  final MyVitrinState state;
  final Map<String, TextEditingController> textControllers;
  final VoidCallback? onPublished;
  final VoidCallback? onOpenExplore;

  const VitrinFormSection({
    super.key,
    required this.controller,
    required this.state,
    required this.textControllers,
    this.onPublished,
    this.onOpenExplore,
  });

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

  TextEditingController get _name => textControllers['name']!;
  TextEditingController get _whatsapp => textControllers['whatsapp']!;
  TextEditingController get _phone => textControllers['phone']!;
  TextEditingController get _email => textControllers['email']!;
  TextEditingController get _heroBadge => textControllers['heroBadge']!;
  TextEditingController get _galleryKicker => textControllers['galleryKicker']!;
  TextEditingController get _galleryTitle => textControllers['galleryTitle']!;
  TextEditingController get _galleryActionLabel =>
      textControllers['galleryActionLabel']!;
  TextEditingController get _galleryActionHref =>
      textControllers['galleryActionHref']!;
  TextEditingController get _workingHours => textControllers['workingHours']!;
  TextEditingController get _address => textControllers['address']!;
  TextEditingController get _heroLocationText =>
      textControllers['heroLocationText']!;
  TextEditingController get _mapLabel => textControllers['mapLabel']!;
  TextEditingController get _desc => textControllers['description']!;
  TextEditingController get _insta => textControllers['instagram']!;
  TextEditingController get _google => textControllers['googleBusiness']!;
  TextEditingController get _categorySectionTitle =>
      textControllers['categorySectionTitle']!;
  TextEditingController get _productSectionTitle =>
      textControllers['productSectionTitle']!;
  TextEditingController get _blogKicker => textControllers['blogKicker']!;
  TextEditingController get _blogTitle => textControllers['blogTitle']!;
  TextEditingController get _faqKicker => textControllers['faqKicker']!;
  TextEditingController get _faqTitle => textControllers['faqTitle']!;
  TextEditingController get _faqDescription =>
      textControllers['faqDescription']!;

  /// EditorGalleryItem → GalleryItem dönüşümü (GalleryEditorSection uyumluluğu)
  List<GalleryItem> get _galleryItemsForEditor =>
      controller.galleryItems
          .map(
            (e) => GalleryItem(
              id: e.id,
              bytes: e.bytes,
              imageUrl: e.imageUrl ?? '',
              extension: e.extension ?? 'jpg',
              contentType: e.contentType ?? 'image/jpeg',
              title: e.title ?? '',
              isRemoved: e.isRemoved,
            ),
          )
          .toList();

  /// GalleryItem → EditorGalleryItem dönüşümü (controller uyumluluğu)
  List<EditorGalleryItem> _toEditorItems(List<GalleryItem> items) =>
      items
          .where((e) => e.bytes != null)
          .map(
            (e) => EditorGalleryItem(
              id: e.id,
              bytes: e.bytes,
              extension: e.extension,
              contentType: e.contentType,
              title: e.title.trim().isEmpty ? null : e.title.trim(),
            ),
          )
          .toList();

  /// Kategori galerisi bottom sheet'ini açar
  Future<void> _showCategoryGallery(
    BuildContext ctx, {
    required SheetImageSource source,
  }) async {
    final kategori = controller.selectedKategori.trim();
    final preferredKey =
        kategori.isNotEmpty ? mapKategoriToKey(kategori) : null;

    await CategoryGallerySheet.show(
      context: ctx,
      preferredCategoryKey: preferredKey,
      source: source,
      onImageAction: (url, action, categoryKey) {
        switch (action) {
          case ImageAction.setAsCover:
            controller.setCoverUrl(url);
            if (categoryKey != null && categoryKey.trim().isNotEmpty) {
              final label = BusinessCategoryConfig.labelForKey(categoryKey);
              if (label != null) {
                controller.selectCategory(label);
              }
            }
            controller.saveLocally();
            break;
          case ImageAction.addToGallery:
            controller.addGalleryUrl(url);
            break;
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPublished = controller.publishedInfo?.isComplete == true;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        _buildHeader(hasPublished),
        const SizedBox(height: 8),
        _buildSubHeader(hasPublished),
        const SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(isDesktop ? 24 : 18),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ÜST ALAN (Tam Ekran / Boydan Boya): Kapak Fotoğrafı & Vitrin Galerisi
              Align(
                alignment: Alignment.center,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: _buildMediaSection(context),
                ),
              ),
              const SizedBox(height: 24),

              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SOL SÜTUN
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildNameField(),
                          const SizedBox(height: 14),
                          _buildWhatsappField(),
                          const SizedBox(height: 14),
                          _buildPhoneField(),
                          const SizedBox(height: 14),
                          _buildEmailField(),
                          const SizedBox(height: 14),
                          _buildLocationSection(),
                          const SizedBox(height: 14),
                          _buildDescriptionField(),
                          const SizedBox(height: 14),
                          _buildHeroBadgeField(),
                          const SizedBox(height: 14),
                          _buildInstagramField(),
                          const SizedBox(height: 14),
                          _buildWorkingHoursField(),
                          const SizedBox(height: 14),
                          AboutEntryCard(
                            hasContent: controller.hasAboutSection,
                            onTap: () => _showAboutSheet(context),
                          ),
                          const SizedBox(height: 14),
                          _buildDirectionsToggle(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 32),
                    // SAĞ SÜTUN
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Vitrin paylaşım linki (isimden öngörülen / yayın sonrası canlı)
                          _buildPublicLinkCard(context, hasPublished),
                          const SizedBox(height: 14),

                          // Instagram Sync Section (if active)
                          if (hasPublished && InstagramSyncConfig.enabled) ...[
                            InstagramSyncSection(
                              storeSlug: controller.publishedInfo!.slug,
                              editToken: controller.publishedInfo!.editToken,
                              defaultCategory: controller.selectedKategori,
                              onProductImported:
                                  controller.updateProductImported,
                              onMessage:
                                  (msg) => state.showSnackBar(context, msg),
                              onConnectedUsername:
                                  (username) =>
                                      _applyConnectedInstagram(username),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Randevu / çalışma saatleri — sadece booking paketi kategorilerinde
                          if (BusinessCategoryConfig.supportsBookingPackage(
                            controller.selectedKategori,
                          )) ...[
                            KeyedSubtree(
                              key: state.productsKey,
                              child: WorkingHoursEditor(
                                bookingIsEnabled: controller.bookingIsEnabled,
                                bookingCapacity: controller.bookingCapacity,
                                bookingWorkingHours:
                                    controller.bookingWorkingHours,
                                bookingLunchBreak: controller.bookingLunchBreak,
                                offerings: controller.offerings,
                                selectedKategori: controller.selectedKategori,
                                onBookingEnabledChanged:
                                    controller.setBookingIsEnabled,
                                onBookingCapacityChanged:
                                    controller.setBookingCapacity,
                                onStateChanged: controller.refreshBookingEditor,
                                showSnackBar:
                                    (msg) => state.showSnackBar(context, msg),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // 2. Ürünlerimi Yönet (Ürün Ekle Kısmı)
                          _buildCatalogSectionTitles(),
                          const SizedBox(height: 14),
                          ProductManagementEntryCard(
                            productCount: controller.data.products.length,
                            onTap: () => _showProductSheet(context),
                          ),
                          const SizedBox(height: 14),
                          FeaturedCampaignEntryCard(
                            hasCampaign: controller.hasFeaturedCampaign,
                            onTap: () => _showFeaturedCampaignSheet(context),
                          ),
                          const SizedBox(height: 14),
                          FaqEntryCard(
                            faqCount: controller.data.faqItems.length,
                            onTap: () => _showFaqSheet(context),
                          ),
                          const SizedBox(height: 14),
                          _buildBlogSectionTitles(),
                          const SizedBox(height: 14),
                          BlogEntryCard(
                            canOpen:
                                (controller.publishedInfo?.slug
                                        .trim()
                                        .isNotEmpty ??
                                    false) ||
                                controller.data.slug.trim().isNotEmpty,
                            onTap: () => _openBlogEditor(context),
                          ),
                          const SizedBox(height: 14),

                          // 4. Vitrin Durumu
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
                            onChanged:
                                (val) => controller.selectStatus(val ?? 'Açık'),
                          ),
                          const SizedBox(height: 14),

                          // 5. Google Yorum Bağlantısı
                          EditorTextField(
                            label: 'Google Yorum Bağlantısı',
                            controller: _google,
                            hint:
                                'https://search.google.com/local/writereview?placeid=...',
                            icon: Icons.rate_review_rounded,
                            keyboardType: TextInputType.url,
                            errorText: controller.googleLinkError,
                            onChanged: (v) {
                              controller.updateGoogleBusinessLink(v);
                              controller.clearValidationErrors();
                            },
                          ),
                          const SizedBox(height: 10),
                          _buildRatingToggle(),
                          const SizedBox(height: 14),

                          // 6. Bağlantılı Platformlar (Trendyol vb.)
                          FormMarketplaceLinks(
                            controller: controller,
                            platformOptions: _platformOptions,
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              else
                // MOBİL LAYOUT (Tek Sütun)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // İşletme Adı (Zorunlu)
                    _buildNameField(),
                    const SizedBox(height: 14),

                    // WhatsApp Numarası (Zorunlu)
                    _buildWhatsappField(),
                    const SizedBox(height: 14),

                    _buildPhoneField(),
                    const SizedBox(height: 14),

                    _buildEmailField(),
                    const SizedBox(height: 14),

                    // Konum Bilgileri (İl, İlçe, Açık Adres, GPS) (Zorunlu)
                    _buildLocationSection(),
                    const SizedBox(height: 10),
                    _buildDirectionsToggle(),
                    const SizedBox(height: 14),

                    // Kısa Açıklama
                    _buildDescriptionField(),
                    const SizedBox(height: 14),

                    _buildHeroBadgeField(),
                    const SizedBox(height: 14),

                    // Instagram
                    _buildInstagramField(),
                    const SizedBox(height: 14),

                    _buildWorkingHoursField(),
                    const SizedBox(height: 14),

                    AboutEntryCard(
                      hasContent: controller.hasAboutSection,
                      onTap: () => _showAboutSheet(context),
                    ),
                    const SizedBox(height: 14),

                    // Vitrin paylaşım linki (isimden öngörülen / yayın sonrası canlı)
                    _buildPublicLinkCard(context, hasPublished),
                    const SizedBox(height: 14),

                    // Instagram Sync Section (if active)
                    if (hasPublished && InstagramSyncConfig.enabled) ...[
                      InstagramSyncSection(
                        storeSlug: controller.publishedInfo!.slug,
                        editToken: controller.publishedInfo!.editToken,
                        defaultCategory: controller.selectedKategori,
                        onProductImported: controller.updateProductImported,
                        onMessage: (msg) => state.showSnackBar(context, msg),
                        onConnectedUsername:
                            (username) => _applyConnectedInstagram(username),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Randevu / çalışma saatleri — sadece booking paketi kategorilerinde
                    if (BusinessCategoryConfig.supportsBookingPackage(
                      controller.selectedKategori,
                    )) ...[
                      KeyedSubtree(
                        key: state.productsKey,
                        child: WorkingHoursEditor(
                          bookingIsEnabled: controller.bookingIsEnabled,
                          bookingCapacity: controller.bookingCapacity,
                          bookingWorkingHours: controller.bookingWorkingHours,
                          bookingLunchBreak: controller.bookingLunchBreak,
                          offerings: controller.offerings,
                          selectedKategori: controller.selectedKategori,
                          onBookingEnabledChanged:
                              controller.setBookingIsEnabled,
                          onBookingCapacityChanged:
                              controller.setBookingCapacity,
                          onStateChanged: controller.refreshBookingEditor,
                          showSnackBar:
                              (msg) => state.showSnackBar(context, msg),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Ürünlerimi Yönet (Ürün Ekle)
                    _buildCatalogSectionTitles(),
                    const SizedBox(height: 14),
                    ProductManagementEntryCard(
                      productCount: controller.data.products.length,
                      onTap: () => _showProductSheet(context),
                    ),
                    const SizedBox(height: 14),
                    FeaturedCampaignEntryCard(
                      hasCampaign: controller.hasFeaturedCampaign,
                      onTap: () => _showFeaturedCampaignSheet(context),
                    ),
                    const SizedBox(height: 14),
                    FaqEntryCard(
                      faqCount: controller.data.faqItems.length,
                      onTap: () => _showFaqSheet(context),
                    ),
                    const SizedBox(height: 14),
                    _buildBlogSectionTitles(),
                    const SizedBox(height: 14),
                    BlogEntryCard(
                      canOpen:
                          (controller.publishedInfo?.slug.trim().isNotEmpty ??
                              false) ||
                          controller.data.slug.trim().isNotEmpty,
                      onTap: () => _openBlogEditor(context),
                    ),
                    const SizedBox(height: 14),

                    // Vitrin Durumu
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
                      onChanged:
                          (val) => controller.selectStatus(val ?? 'Açık'),
                    ),
                    const SizedBox(height: 14),

                    // Google Yorum Bağlantısı
                    EditorTextField(
                      label: 'Google Yorum Bağlantısı',
                      controller: _google,
                      hint:
                          'https://search.google.com/local/writereview?placeid=...',
                      icon: Icons.rate_review_rounded,
                      keyboardType: TextInputType.url,
                      errorText: controller.googleLinkError,
                      onChanged: (v) {
                        controller.updateGoogleBusinessLink(v);
                        controller.clearValidationErrors();
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildRatingToggle(),
                    const SizedBox(height: 14),

                    // Bağlantılı Platformlar (Trendyol vb.)
                    FormMarketplaceLinks(
                      controller: controller,
                      platformOptions: _platformOptions,
                    ),
                  ],
                ),

              const SizedBox(height: 24),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 24),

              // GELİŞMİŞ AYARLAR — bölüm görünürlüğü (sahip kararı)
              SectionVisibilityCard(
                visibility: controller.data.sectionVisibility,
                onChanged: controller.updateSectionVisibility,
              ),
              const SizedBox(height: 24),

              // ALT ALAN (Her iki görünümde de tam genişlik)
              _buildLegalAndPublishSection(context, hasPublished),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMediaSection(BuildContext context) {
    return FormMediaPicker(
      controller: controller,
      state: state,
      galleryItems: _galleryItemsForEditor,
      galleryKickerController: _galleryKicker,
      galleryTitleController: _galleryTitle,
      galleryActionLabelController: _galleryActionLabel,
      galleryActionHrefController: _galleryActionHref,
      onPickCover: () => _pickCover(context),
      onPickCoverFromCamera: () => _pickCoverFromCamera(context),
      onAutoFillCover:
          () => _showCategoryGallery(
            context,
            source: SheetImageSource.coverPicker,
          ),
      onPickGallery: () => _pickGallery(context),
      onGalleryTitleChanged: (index, title) {
        controller.updateGalleryItemTitle(index, title);
        controller.saveLocally();
      },
      onGalleryActionLabelChanged: controller.updateGalleryActionLabel,
      onGalleryActionHrefChanged: controller.updateGalleryActionHref,
    );
  }

  Widget _buildHeader(bool hasPublished) {
    return Row(
      children: [
        Expanded(
          child: Text(
            hasPublished ? 'Vixrex Düzenle' : 'Vixrex Oluştur',
            style: const TextStyle(
              color: AppColors.darkText,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
        ),
        const SizedBox(width: 10),
        _buildVixRexBadge(),
      ],
    );
  }

  Widget _buildVixRexBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.storefront_rounded, color: AppColors.onPrimary, size: 13),
          SizedBox(width: 4),
          Text(
            'Vixrex ile',
            style: TextStyle(
              color: AppColors.onPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubHeader(bool hasPublished) {
    return Text(
      hasPublished
          ? 'Düzenledikten sonra kaydet, linkin ve QR kodun güncellenir.'
          : 'Ad, WhatsApp ve konumunu gir — vitrin hazır. Diğer detayları sonra ekleyebilirsin.',
      style: const TextStyle(
        color: AppColors.mutedText,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
    );
  }

  Widget _buildNameField() {
    return KeyedSubtree(
      key: state.nameKey,
      child: EditorTextField(
        label: 'İşletme / Vixrex Adı',
        controller: _name,
        focusNode: state.nameFocusNode,
        hint: 'Örn: Aymira Butik',
        icon: Icons.storefront_rounded,
        requiredField: true,
        errorText: controller.nameError,
        onChanged: (v) {
          controller.updateName(v);
          controller.clearValidationErrors();
        },
      ),
    );
  }

  Widget _buildWhatsappField() {
    return KeyedSubtree(
      key: state.whatsappKey,
      child: EditorTextField(
        label: 'WhatsApp Numarası',
        controller: _whatsapp,
        focusNode: state.whatsappFocusNode,
        hint: '05xx xxx xx xx',
        icon: Icons.chat_bubble_rounded,
        keyboardType: TextInputType.phone,
        requiredField: true,
        errorText: controller.whatsappError,
        onChanged: (v) {
          controller.updateWhatsapp(v);
          controller.clearValidationErrors();
        },
      ),
    );
  }

  Widget _buildDescriptionField() {
    return KeyedSubtree(
      key: state.descriptionKey,
      child: EditorTextField(
        label: 'Kısa Açıklama',
        controller: _desc,
        focusNode: state.descriptionFocusNode,
        hint: 'Bugün vitrinde ne var? Kısa bir tanıtım yaz.',
        icon: Icons.notes_rounded,
        maxLines: 3,
        onChanged: (v) {
          controller.setDescription(v);
          controller.clearValidationErrors();
        },
      ),
    );
  }

  Widget _buildInstagramField() {
    return EditorTextField(
      label: 'Instagram',
      controller: _insta,
      hint: '@kullanici_adi veya profil linki',
      icon: Icons.camera_alt_rounded,
      keyboardType: TextInputType.url,
      onChanged: (v) => controller.updateInstagram(v),
    );
  }

  Widget _buildPhoneField() {
    return EditorTextField(
      label: 'Telefon',
      controller: _phone,
      hint: '05xx xxx xx xx (isteğe bağlı)',
      icon: Icons.phone_rounded,
      keyboardType: TextInputType.phone,
      onChanged: (v) => controller.updatePhone(v),
    );
  }

  Widget _buildEmailField() {
    return EditorTextField(
      label: 'E-posta',
      controller: _email,
      hint: 'ornek@isletme.com',
      icon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      onChanged: (v) => controller.updateEmail(v),
    );
  }

  Widget _buildHeroBadgeField() {
    return EditorTextField(
      label: 'Kapak Rozeti',
      controller: _heroBadge,
      hint: 'Örn: Atölye / Mağaza',
      icon: Icons.sell_outlined,
      onChanged: (v) => controller.updateHeroBadge(v),
    );
  }

  Widget _buildWorkingHoursField() {
    return EditorTextField(
      label: 'Çalışma Saatleri',
      controller: _workingHours,
      hint: 'Örn: Pzt — Cmt 09:00 - 20:00',
      icon: Icons.schedule_rounded,
      onChanged: (v) => controller.updateWorkingHoursText(v),
    );
  }

  Widget _buildCatalogSectionTitles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EditorTextField(
          label: 'Kategori Bölümü Başlığı',
          controller: _categorySectionTitle,
          hint: 'Örn: Servis Alanlarımız',
          icon: Icons.category_outlined,
          maxLength: 60,
          onChanged: (v) => controller.updateCategorySectionTitle(v),
        ),
        const SizedBox(height: 12),
        EditorTextField(
          label: 'Ürün Bölümü Başlığı',
          controller: _productSectionTitle,
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
          label: 'Blog Üst Başlık',
          controller: _blogKicker,
          hint: 'Örn: Teknik rehber',
          icon: Icons.label_outline_rounded,
          maxLength: 40,
          onChanged: (v) => controller.updateBlogSectionKicker(v),
        ),
        const SizedBox(height: 12),
        EditorTextField(
          label: 'Blog Bölüm Başlığı',
          controller: _blogTitle,
          hint: 'Örn: Mağazadan Haberler',
          icon: Icons.article_outlined,
          maxLength: 90,
          onChanged: (v) => controller.updateBlogSectionTitle(v),
        ),
      ],
    );
  }

  // ListTile türevleri mürekkep efektini en yakın Material üzerine çizer.
  // Bu iki anahtar, arka planı olan bir Container'ın (_cardDecoration) içinde
  // duruyor; araya Material konmazsa Flutter "efektler görünmez olacak" diye
  // assertion fırlatıyor ve test ortamında ekranın kalanı hiç çizilmiyor.
  // Şeffaf Material efekti kendi üstüne çizdirir, görünümü değiştirmez.
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

  Widget _buildDirectionsToggle() {
    return Material(
      type: MaterialType.transparency,
      child: SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: const Text(
          'Yol tarifi butonu göster',
          style: TextStyle(
            color: AppColors.darkText,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: const Text(
          'Adres veya GPS varsa vitrinde yol tarifi linki çıkar.',
          style: TextStyle(color: AppColors.mutedText, fontSize: 11),
        ),
        value: controller.data.showDirectionsLink,
        activeThumbColor: AppColors.primary,
        onChanged: (value) {
          controller.updateShowDirectionsLink(value);
          controller.saveLocally();
        },
      ),
    );
  }

  Widget _buildPublicLinkCard(BuildContext context, bool hasPublished) {
    const builder = StorePublishPayloadBuilder();
    final publishedLink = controller.publishedInfo?.publicLink.trim() ?? '';
    final previewLink = builder.previewVitrinLink(controller.data.name);
    final displayLink =
        hasPublished && publishedLink.isNotEmpty
            ? publishedLink
            : (previewLink.isEmpty ? null : previewLink);

    return PublicLinkCard(
      displayLink: displayLink,
      isLive: hasPublished && publishedLink.isNotEmpty,
      onCopyLink:
          () => _copyDisplayLink(context, displayLink, isLive: hasPublished),
      onPreview: () => _openInAppPreview(context),
      onShareLink: hasPublished ? () => _shareLink(context) : null,
      onShowQr: hasPublished ? () => _showQrSheet(context) : null,
      onOpenLiveLink: hasPublished ? () => _openLink(context) : null,
      onScrollToPublish:
          hasPublished
              ? null
              : () => state.scrollToVixRexAction(VixRexAction.scrollToLegal),
    );
  }

  /// Yayındaki vitrinin QR kodunu gösterir.
  ///
  /// Esnaf bunu tezgâha yapıştırıyor; kiralama vaadinde de "özel paylaşım
  /// linki ve QR kod" diye geçiyor. Eski PublishActionsSection'da vardı,
  /// PublicLinkCard'a geçişte düşmüştü.
  ///
  /// Görsel, vitrin sayfasının kullandığı aynı hizmetten geliyor — iki
  /// yerde iki farklı QR üretmemek için.
  void _showQrSheet(BuildContext ctx) {
    final raw = controller.publishedInfo?.publicLink.trim() ?? '';
    if (raw.isEmpty) {
      state.showSnackBar(ctx, 'Önce vitrini yayına al.');
      return;
    }
    final link = PublicSiteConfig.repairPublicLink(raw);
    final qrUrl =
        'https://api.qrserver.com/v1/create-qr-code/?size=320x320&data='
        '${Uri.encodeComponent(link)}';

    showModalBottomSheet<void>(
      context: ctx,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (sheetContext) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Vitrin QR Kodun',
                    style: TextStyle(
                      color: AppColors.darkText,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Yazdırıp tezgâhına koyabilirsin. Müşteri okuttuğunda '
                    'doğrudan vitrinine gelir.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(12),
                      child: Image.network(
                        qrUrl,
                        width: 220,
                        height: 220,
                        errorBuilder:
                            (_, __, ___) => const SizedBox(
                              width: 220,
                              height: 220,
                              child: Center(
                                child: Text(
                                  'QR kodu getirilemedi.\nİnternet bağlantını '
                                  'kontrol et.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.mutedText,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SelectableText(
                    link,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.softText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _copyDisplayLink(ctx, link, isLive: true);
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Linki Kopyala'),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // Taslak/yayın ayrımı controller.openOwnerPreview() arkasında saklanır
  // (implementation_plan.md §5.1) — bu ekran hangi durumda olduğunu bilmez.
  Future<void> _openInAppPreview(BuildContext ctx) async {
    try {
      final owner = await controller.openOwnerPreview();
      if (!ctx.mounted) return;
      await AppRouter.openPublicUrl(
        ctx,
        owner.url,
        failureMessage: 'Önizleme açılamadı.',
      );
    } catch (e) {
      if (!ctx.mounted) return;
      state.showSnackBar(ctx, 'Önizleme hazırlanamadı: $e');
    }
  }

  Future<void> _copyDisplayLink(
    BuildContext ctx,
    String? link, {
    required bool isLive,
  }) async {
    final raw = link?.trim() ?? '';
    if (raw.isEmpty) {
      state.showSnackBar(ctx, 'Önce işletme adını yazın.');
      return;
    }
    final repaired = isLive ? PublicSiteConfig.repairPublicLink(raw) : raw;
    await Clipboard.setData(ClipboardData(text: repaired));
    if (!ctx.mounted) return;
    state.showSnackBar(
      ctx,
      isLive
          ? 'Vitrin linki kopyalandı.'
          : 'Öngörülen vitrin linki kopyalandı. Yayına alınca tarayıcıda açılır.',
    );
  }

  Future<void> _applyConnectedInstagram(String username) async {
    final cleaned = username.trim().replaceFirst('@', '');
    if (cleaned.isEmpty) return;
    final handle = '@$cleaned';
    _insta.text = handle;
    final result = await controller.applyConnectedInstagramUsername(cleaned);
    if (result.isFailure) {
      // Yerel alan yine dolu; yayın/yeniden kaydet ile düzelir.
      if (kDebugMode) {
        debugPrint('_applyConnectedInstagram: ${result.failure?.message}');
      }
    }
  }

  Widget _buildLocationSection() {
    return FormLocationInfo(
      controller: controller,
      state: state,
      addressController: _address,
      heroLocationTextController: _heroLocationText,
      mapLabelController: _mapLabel,
    );
  }

  Widget _buildLegalAndPublishSection(BuildContext context, bool hasPublished) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KeyedSubtree(
          key: state.legalKey,
          child: LegalConsentSection(
            canAccept: !controller.isLoadingLegalDocuments,
            isLoading: controller.isLoadingLegalDocuments,
            errorText: controller.legalDocumentsError,
            privacyNoticeAcknowledged: controller.privacyNoticeAcknowledged,
            termsAccepted: controller.termsAccepted,
            publicationConsentAccepted: controller.publicationConsentAccepted,
            onPrivacyChanged: controller.setPrivacyNoticeAcknowledged,
            onTermsChanged: controller.setTermsAccepted,
            onPublicationChanged: controller.setPublicationConsentAccepted,
            onReloadDocuments: controller.reloadLegalDocuments,
            onOpenLegalPage: (type) => AppRouter.navigateToLegal(context, type),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 54,
          child: ElevatedButton.icon(
            onPressed:
                controller.isPublishing || !controller.isLegalPublishReady
                    ? null
                    : () => state.handlePublish(context, onPublished),
            icon:
                controller.isPublishing
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.onPrimary,
                      ),
                    )
                    : Icon(
                      hasPublished
                          ? Icons.cloud_upload_rounded
                          : Icons.rocket_launch_rounded,
                      size: 19,
                    ),
            label: Text(
              controller.isPublishing
                  ? 'Yayına alınıyor...'
                  : hasPublished
                  ? 'Değişiklikleri Kaydet & Yayına Al'
                  : 'Vitrinimi Yayına Al',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          hasPublished
              ? 'Mevcut linkin korunur, Keşfet görünümün güncellenir.'
              : 'Linkin oluşur, Keşfet\'te görünürsün.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.mutedText,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (hasPublished) ...[
          const SizedBox(height: 16),
          GoogleBusinessGuideCard(
            publishedLink: controller.publishedInfo?.publicLink ?? '',
          ),
        ],
      ],
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: AppColors.cardBorderDark),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.25),
        blurRadius: 24,
        offset: const Offset(0, 12),
      ),
    ],
  );

  Future<void> _pickCover(BuildContext ctx) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    if (!ctx.mounted) return;
    final file = result.files.single;
    final v = GalleryImageFileValidator.validate(
      bytes: file.bytes,
      reportedSize: file.size,
    );
    if (!v.isValid || file.bytes == null) {
      state.showSnackBar(
        ctx,
        'Fotoğraf eklenemedi. JPG, PNG veya WEBP, en fazla 15 MB.',
      );
      return;
    }
    controller.setCoverBytes(
      file.bytes!,
      file.name,
      v.fileInfo?.extension ?? 'jpg',
      v.fileInfo?.contentType ?? 'image/jpeg',
    );
  }

  Future<void> _pickCoverFromCamera(BuildContext ctx) async {
    try {
      final picker = img_picker.ImagePicker();
      final pickedFile = await picker.pickImage(
        source: img_picker.ImageSource.camera,
      );
      if (pickedFile == null) return;
      final bytes = await pickedFile.readAsBytes();
      final size = bytes.length;
      final v = GalleryImageFileValidator.validate(
        bytes: bytes,
        reportedSize: size,
      );
      if (!ctx.mounted) return;
      if (!v.isValid) {
        state.showSnackBar(
          ctx,
          'Fotoğraf eklenemedi. JPG, PNG veya WEBP, en fazla 15 MB.',
        );
        return;
      }
      controller.setCoverBytes(
        bytes,
        pickedFile.name,
        v.fileInfo?.extension ?? 'jpg',
        v.fileInfo?.contentType ?? 'image/jpeg',
      );
    } catch (_) {
      if (ctx.mounted) {
        state.showSnackBar(
          ctx,
          'Kameraya erişilemedi. Kamera izinlerini kontrol edin veya dosya yüklemeyi kullanın.',
        );
      }
    }
  }

  Future<void> _pickGallery(BuildContext ctx) async {
    final remaining =
        controller.maxGalleryPhotos - controller.galleryItems.length;
    if (remaining <= 0) {
      state.showSnackBar(
        ctx,
        'En fazla ${controller.maxGalleryPhotos} galeri fotoğrafı eklenebilir.',
      );
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    if (!ctx.mounted) return;
    var rejected = 0;
    final newItems = <GalleryItem>[];
    for (final file in result.files.take(remaining)) {
      final v = GalleryImageFileValidator.validate(
        bytes: file.bytes,
        reportedSize: file.size,
      );
      if (!v.isValid || file.bytes == null) {
        rejected++;
        continue;
      }
      newItems.add(
        GalleryItem(
          id: '${DateTime.now().microsecondsSinceEpoch}_${newItems.length}',
          bytes: file.bytes,
          imageUrl: '',
          extension: v.fileInfo?.extension ?? 'jpg',
          contentType: v.fileInfo?.contentType ?? 'image/jpeg',
        ),
      );
    }
    final editorItems = [
      ...controller.galleryItems,
      ..._toEditorItems(newItems),
    ];
    controller.setGalleryItems(editorItems);
    if (rejected > 0) state.showSnackBar(ctx, '$rejected fotoğraf eklenemedi.');
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
            },
            onProductDelete: (product) async {
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
            kickerController: _faqKicker,
            titleController: _faqTitle,
            descriptionController: _faqDescription,
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
    await AppRouter.navigateToBlogEditor(ctx, slug: slug);
  }

  Future<void> _openLink(BuildContext ctx) async {
    final raw = controller.publishedInfo?.publicLink.trim();
    if (raw == null || raw.isEmpty) {
      state.showSnackBar(
        ctx,
        'Vitrininizi yayına aldığınızda size özel web linkiniz oluşacak.',
      );
      return;
    }
    final link = PublicSiteConfig.repairPublicLink(raw);
    final uri = Uri.tryParse(link);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      state.showSnackBar(ctx, 'Vitrin linki açılamadı.');
      return;
    }
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && ctx.mounted) state.showSnackBar(ctx, 'Tarayıcı açılamadı.');
    } catch (_) {
      if (ctx.mounted) state.showSnackBar(ctx, 'Tarayıcı açılamadı.');
    }
  }

  Future<void> _shareLink(BuildContext ctx) async {
    final raw = controller.publishedInfo?.publicLink.trim();
    if (raw == null || raw.isEmpty) {
      state.showSnackBar(
        ctx,
        'Vitrininizi yayına aldığınızda size özel web linkiniz oluşacak.',
      );
      return;
    }
    final link = PublicSiteConfig.repairPublicLink(raw);
    try {
      final r = await SharePlus.instance.share(
        ShareParams(
          text: 'Vixrex web linkim:\n$link',
          title: 'Vixrex Web Linki',
        ),
      );
      if (r.status != ShareResultStatus.unavailable) return;
    } catch (e) {
      if (kDebugMode) debugPrint('_shareLink error: $e');
    }
    await Clipboard.setData(ClipboardData(text: link));
    if (ctx.mounted) {
      state.showSnackBar(ctx, 'Paylaşım açılamadı, link kopyalandı.');
    }
  }
}

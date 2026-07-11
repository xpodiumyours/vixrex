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
import 'package:vixrex/screens/ocr_scanner_screen.dart';
import 'package:vixrex/screens/my_vitrin/my_vitrin_state.dart';
import 'package:vixrex/services/category_image_service.dart';
import 'package:vixrex/services/ocr/ocr_service.dart';
import 'package:vixrex/services/store_publish_service.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/models/editor_gallery_item.dart';
import 'package:vixrex/utils/gallery_image_file_validator.dart';
import 'package:vixrex/widgets/auto_fill/category_gallery_sheet.dart';
import 'package:vixrex/widgets/editor/common_form_fields.dart';
import 'package:vixrex/widgets/editor/gallery_editor_section.dart';
import 'package:vixrex/widgets/editor/legal_consent_section.dart';
import 'package:vixrex/widgets/editor/public_link_card.dart';
import 'package:vixrex/widgets/editor/store_theme_picker.dart';
import 'package:vixrex/widgets/editor/working_hours_editor.dart';
import 'package:vixrex/widgets/instagram_sync_section.dart';
import 'package:vixrex/widgets/product/product_management_entry_card.dart';
import 'package:vixrex/widgets/product/product_management_sheet.dart';

import 'package:vixrex/widgets/editor/form_media_picker.dart';
import 'package:vixrex/widgets/editor/form_location_info.dart';
import 'package:vixrex/widgets/editor/form_marketplace_links.dart';

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
    'Trendyol', 'Hepsiburada', 'N11', 'Amazon', 'Çiçeksepeti',
    'Shopier', 'Google İşletme', 'Diğer', 'Özel...',
  ];

  TextEditingController get _name => textControllers['name']!;
  TextEditingController get _whatsapp => textControllers['whatsapp']!;
  TextEditingController get _address => textControllers['address']!;
  TextEditingController get _desc => textControllers['description']!;
  TextEditingController get _insta => textControllers['instagram']!;
  TextEditingController get _web => textControllers['website']!;
  TextEditingController get _google => textControllers['googleBusiness']!;

  /// EditorGalleryItem → GalleryItem dönüşümü (GalleryEditorSection uyumluluğu)
  List<GalleryItem> get _galleryItemsForEditor =>
      controller.galleryItems.map((e) => GalleryItem(
        id: e.id,
        bytes: e.bytes,
        imageUrl: e.imageUrl ?? '',
        extension: e.extension ?? 'jpg',
        contentType: e.contentType ?? 'image/jpeg',
        isRemoved: e.isRemoved,
      )).toList();

  /// GalleryItem → EditorGalleryItem dönüşümü (controller uyumluluğu)
  List<EditorGalleryItem> _toEditorItems(List<GalleryItem> items) =>
      items.where((e) => e.bytes != null).map((e) => EditorGalleryItem.fromBytes(
        e.bytes!,
        id: e.id,
        extension: e.extension,
        contentType: e.contentType,
      )).toList();

  /// Kategori galerisi bottom sheet'ini açar
  Future<void> _showCategoryGallery(BuildContext ctx, {required SheetImageSource source}) async {
    final kategori = controller.selectedKategori.trim();
    if (kategori.isEmpty) {
      state.showSnackBar(ctx, 'Önce bir kategori seçmelisiniz.');
      return;
    }
    final preferredKey = mapKategoriToKey(kategori);

    await CategoryGallerySheet.show(
      context: ctx,
      preferredCategoryKey: preferredKey,
      source: source,
      onImageAction: (url, action) {
        switch (action) {
          case ImageAction.setAsCover:
            controller.setCoverUrl(url);
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
                      _buildLocationSection(),
                      const SizedBox(height: 14),
                      _buildDescriptionField(),
                      const SizedBox(height: 14),
                      _buildInstagramField(),
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
                      // 1. Website (En Üstte)
                      PublicLinkCard(
                        controller: _web,
                        publicLink: controller.publishedInfo?.publicLink,
                        onOpenLink: () => _openLink(context),
                        onCopyLink: () => _copyLink(context),
                        onShareLink: () => _shareLink(context),
                      ),
                      const SizedBox(height: 14),

                      // Instagram Sync Section (if active)
                      if (hasPublished && InstagramSyncConfig.enabled) ...[
                        InstagramSyncSection(
                          storeSlug: controller.publishedInfo!.slug,
                          editToken: controller.publishedInfo!.editToken,
                          defaultCategory: controller.selectedKategori,
                          onProductImported: controller.updateProductImported,
                          onMessage: (msg) => state.showSnackBar(context, msg),
                          onConnectedUsername: (username) =>
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
                            bookingWorkingHours: controller.bookingWorkingHours,
                            bookingLunchBreak: controller.bookingLunchBreak,
                            offerings: controller.offerings,
                            selectedKategori: controller.selectedKategori,
                            onBookingEnabledChanged: controller.setBookingIsEnabled,
                            onBookingCapacityChanged: controller.setBookingCapacity,
                            onStateChanged: controller.refreshBookingEditor,
                            showSnackBar: (msg) => state.showSnackBar(context, msg),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // 2. Ürünlerimi Yönet (Ürün Ekle Kısmı)
                      ProductManagementEntryCard(
                        productCount: controller.data.products.length,
                        onTap: () => _showProductSheet(context),
                      ),
                      const SizedBox(height: 14),

                      // 3. Kategori
                      KeyedSubtree(
                        key: state.categoryKey,
                        child: EditorDropdownField(
                          label: 'Kategori',
                          value: controller.selectedKategori,
                          items: BusinessCategoryConfig.categories.map((c) => c.label).toList(),
                          icon: Icons.category_rounded,
                          onChanged: (val) => controller.selectCategory(val ?? 'Diğer'),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // StoreThemePicker (Tema Seçimi)
                      StoreThemePicker(
                        selectedTheme: controller.data.theme,
                        onThemeChanged: (val) => controller.data.theme = val,
                      ),
                      const SizedBox(height: 14),

                      // 4. Vitrin Durumu
                      EditorDropdownField(
                        label: 'Vitrin Durumu',
                        value: controller.selectedStatus,
                        items: const ['Açık', 'Bugün kampanya var', 'Yeni ürünler geldi', 'Stok sınırlı', 'Kapalı'],
                        icon: Icons.info_outline_rounded,
                        onChanged: (val) => controller.selectStatus(val ?? 'Açık'),
                      ),
                      const SizedBox(height: 14),

                      // 5. Google Yorum Bağlantısı
                      EditorTextField(
                        label: 'Google Yorum Bağlantısı',
                        controller: _google,
                        hint: 'https://search.google.com/local/writereview?placeid=...',
                        icon: Icons.rate_review_rounded,
                        keyboardType: TextInputType.url,
                        errorText: controller.googleLinkError,
                        onChanged: (v) {
                          controller.updateGoogleBusinessLink(v);
                          controller.clearValidationErrors();
                        },
                      ),
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

                // Konum Bilgileri (İl, İlçe, Açık Adres, GPS) (Zorunlu)
                _buildLocationSection(),
                const SizedBox(height: 14),

                // Kısa Açıklama
                _buildDescriptionField(),
                const SizedBox(height: 14),

                // Instagram
                _buildInstagramField(),
                const SizedBox(height: 14),

                // Website (Website Linki)
                PublicLinkCard(
                  controller: _web,
                  publicLink: controller.publishedInfo?.publicLink,
                  onOpenLink: () => _openLink(context),
                  onCopyLink: () => _copyLink(context),
                  onShareLink: () => _shareLink(context),
                ),
                const SizedBox(height: 14),

                // Instagram Sync Section (if active)
                if (hasPublished && InstagramSyncConfig.enabled) ...[
                  InstagramSyncSection(
                    storeSlug: controller.publishedInfo!.slug,
                    editToken: controller.publishedInfo!.editToken,
                    defaultCategory: controller.selectedKategori,
                    onProductImported: controller.updateProductImported,
                    onMessage: (msg) => state.showSnackBar(context, msg),
                    onConnectedUsername: (username) =>
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
                      bookingWorkingHours: controller.bookingWorkingHours,
                      bookingLunchBreak: controller.bookingLunchBreak,
                      offerings: controller.offerings,
                      selectedKategori: controller.selectedKategori,
                      onBookingEnabledChanged: controller.setBookingIsEnabled,
                      onBookingCapacityChanged: controller.setBookingCapacity,
                      onStateChanged: controller.refreshBookingEditor,
                      showSnackBar: (msg) => state.showSnackBar(context, msg),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Ürünlerimi Yönet (Ürün Ekle)
                ProductManagementEntryCard(
                  productCount: controller.data.products.length,
                  onTap: () => _showProductSheet(context),
                ),
                const SizedBox(height: 14),

                // Kategori
                KeyedSubtree(
                  key: state.categoryKey,
                  child: EditorDropdownField(
                    label: 'Kategori',
                    value: controller.selectedKategori,
                    items: BusinessCategoryConfig.categories.map((c) => c.label).toList(),
                    icon: Icons.category_rounded,
                    onChanged: (val) => controller.selectCategory(val ?? 'Diğer'),
                  ),
                ),
                const SizedBox(height: 14),

                // StoreThemePicker (Tema Seçimi)
                StoreThemePicker(
                  selectedTheme: controller.data.theme,
                  onThemeChanged: (val) => controller.data.theme = val,
                ),
                const SizedBox(height: 14),

                // Vitrin Durumu
                EditorDropdownField(
                  label: 'Vitrin Durumu',
                  value: controller.selectedStatus,
                  items: const ['Açık', 'Bugün kampanya var', 'Yeni ürünler geldi', 'Stok sınırlı', 'Kapalı'],
                  icon: Icons.info_outline_rounded,
                  onChanged: (val) => controller.selectStatus(val ?? 'Açık'),
                ),
                const SizedBox(height: 14),

                // Google Yorum Bağlantısı
                EditorTextField(
                  label: 'Google Yorum Bağlantısı',
                  controller: _google,
                  hint: 'https://search.google.com/local/writereview?placeid=...',
                  icon: Icons.rate_review_rounded,
                  keyboardType: TextInputType.url,
                  errorText: controller.googleLinkError,
                  onChanged: (v) {
                    controller.updateGoogleBusinessLink(v);
                    controller.clearValidationErrors();
                  },
                ),
                const SizedBox(height: 14),

                // Bağlantılı Platformlar (Trendyol vb.)
                FormMarketplaceLinks(
                  controller: controller,
                  platformOptions: _platformOptions,
                ),
              ],
            ),

          const SizedBox(height: 24),
          const Divider(color: Color(0xFF25415F), height: 1),
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
      onPickCover: () => _pickCover(context),
      onPickCoverFromCamera: () => _pickCoverFromCamera(context),
      onAutoFillCover: () => _showCategoryGallery(context, source: SheetImageSource.coverPicker),
      onPickGallery: () => _pickGallery(context),
    );
  }

  Widget _buildHeader(bool hasPublished) {
    return Row(
      children: [
        Expanded(
          child: Text(
            hasPublished ? 'VixRex Düzenle' : 'VixRex Oluştur',
            style: const TextStyle(
              color: Colors.white,
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
        color: const Color(0xFF00F0FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.storefront_rounded, color: Colors.black, size: 13),
          SizedBox(width: 4),
          Text(
            'VixRex ile',
            style: TextStyle(
              color: Colors.black,
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
        color: Color(0xFFA1A1AA),
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
        label: 'İşletme / VixRex Adı',
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
            onPressed: controller.isPublishing || !controller.isLegalPublishReady
                ? null
                : () => state.handlePublish(context, onPublished),
            icon: controller.isPublishing
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                  )
                : Icon(
                    hasPublished ? Icons.cloud_upload_rounded : Icons.rocket_launch_rounded,
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
              backgroundColor: const Color(0xFF00F0FF),
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            color: Color(0xFFA1A1AA),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
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
      type: FileType.image, withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    if (!ctx.mounted) return;
    final file = result.files.single;
    final v = GalleryImageFileValidator.validate(
      bytes: file.bytes, reportedSize: file.size,
    );
    if (!v.isValid || file.bytes == null) {
      state.showSnackBar(ctx, 'Fotoğraf eklenemedi. JPG, PNG veya WEBP, en fazla 15 MB.');
      return;
    }
    controller.setCoverBytes(
      file.bytes!, file.name,
      v.fileInfo?.extension ?? 'jpg',
      v.fileInfo?.contentType ?? 'image/jpeg',
    );
  }

  Future<void> _pickCoverFromCamera(BuildContext ctx) async {
    try {
      final picker = img_picker.ImagePicker();
      final pickedFile = await picker.pickImage(source: img_picker.ImageSource.camera);
      if (pickedFile == null) return;
      final bytes = await pickedFile.readAsBytes();
      final size = bytes.length;
      final v = GalleryImageFileValidator.validate(
        bytes: bytes, reportedSize: size,
      );
      if (!ctx.mounted) return;
      if (!v.isValid) {
        state.showSnackBar(ctx, 'Fotoğraf eklenemedi. JPG, PNG veya WEBP, en fazla 15 MB.');
        return;
      }
      controller.setCoverBytes(
        bytes, pickedFile.name,
        v.fileInfo?.extension ?? 'jpg',
        v.fileInfo?.contentType ?? 'image/jpeg',
      );
    } catch (_) {
      if (ctx.mounted) {
        state.showSnackBar(ctx, 'Kameraya erişilemedi. Kamera izinlerini kontrol edin veya dosya yüklemeyi kullanın.');
      }
    }
  }

  Future<void> _pickGallery(BuildContext ctx) async {
    final remaining = controller.maxGalleryPhotos - controller.galleryItems.length;
    if (remaining <= 0) {
      state.showSnackBar(ctx, 'En fazla ${controller.maxGalleryPhotos} galeri fotoğrafı eklenebilir.');
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true, type: FileType.image, withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    if (!ctx.mounted) return;
    var rejected = 0;
    final newItems = <GalleryItem>[];
    for (final file in result.files.take(remaining)) {
      final v = GalleryImageFileValidator.validate(bytes: file.bytes, reportedSize: file.size);
      if (!v.isValid || file.bytes == null) { rejected++; continue; }
      newItems.add(GalleryItem(
        id: '${DateTime.now().microsecondsSinceEpoch}_${newItems.length}',
        bytes: file.bytes, imageUrl: '',
        extension: v.fileInfo?.extension ?? 'jpg',
        contentType: v.fileInfo?.contentType ?? 'image/jpeg',
      ));
    }
    final editorItems = [...controller.galleryItems, ..._toEditorItems(newItems)];
    controller.setGalleryItems(editorItems);
    if (rejected > 0) state.showSnackBar(ctx, '$rejected fotoğraf eklenemedi.');
  }

  void _showProductSheet(BuildContext ctx) {
    final slug = controller.data.slug.trim().isNotEmpty
        ? controller.data.slug.trim()
        : StorePublishPayloadBuilder().generateSlug(controller.data.name);
    showModalBottomSheet(
      context: ctx, backgroundColor: AppColors.surface, isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ProductManagementSheet(
        products: controller.data.products,
        categories: controller.data.productCategories,
        storeSlug: slug,
        showMessage: (msg) => state.showSnackBar(ctx, msg),
        onCatalogChanged: (products, categories) async {
          controller.data.products = products;
          controller.data.productCategories = categories;
          await controller.saveLocally();
          final sync = await controller.syncProductsToSupabase(
            data: controller.data,
            publishService: controller.publishService,
            editToken: controller.publishedInfo?.editToken,
          );
          if (sync.isFailure && ctx.mounted) {
            state.showSnackBar(
              ctx,
              sync.failure?.message ??
                  'Ürünler kaydedilemedi, lütfen tekrar deneyin.',
            );
          }
        },
        onOcrTap: () {
          // Alt paneli kapat, sonra root navigator'dan OCR ekranını aç
          Navigator.of(ctx).pop();
          // Root navigator'u kullanarak navigasyon yap
          Navigator.of(ctx, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (_) => OcrScannerScreen(
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

  Future<void> _openLink(BuildContext ctx) async {
    final raw = controller.publishedInfo?.publicLink.trim();
    if (raw == null || raw.isEmpty) {
      state.showSnackBar(ctx, 'Vitrininizi yayına aldığınızda size özel web linkiniz oluşacak.');
      return;
    }
    final link = PublicSiteConfig.repairPublicLink(raw);
    final uri = Uri.tryParse(link);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      state.showSnackBar(ctx, 'Vitrin linki açılamadı.'); return;
    }
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && ctx.mounted) state.showSnackBar(ctx, 'Tarayıcı açılamadı.');
    } catch (_) {
      if (ctx.mounted) state.showSnackBar(ctx, 'Tarayıcı açılamadı.');
    }
  }

  Future<void> _copyLink(BuildContext ctx) async {
    final raw = controller.publishedInfo?.publicLink;
    if (raw == null || raw.trim().isEmpty) return;
    final link = PublicSiteConfig.repairPublicLink(raw);
    await Clipboard.setData(ClipboardData(text: link));
    if (ctx.mounted) state.showSnackBar(ctx, 'Vitrin linki kopyalandı.');
  }

  Future<void> _shareLink(BuildContext ctx) async {
    final raw = controller.publishedInfo?.publicLink.trim();
    if (raw == null || raw.isEmpty) {
      state.showSnackBar(ctx, 'Vitrininizi yayına aldığınızda size özel web linkiniz oluşacak.');
      return;
    }
    final link = PublicSiteConfig.repairPublicLink(raw);
    try {
      final r = await SharePlus.instance.share(
        ShareParams(text: 'VixRex web linkim:\n$link', title: 'VixRex Web Linki'),
      );
      if (r.status != ShareResultStatus.unavailable) return;
    } catch (e) {
      if (kDebugMode) debugPrint('_shareLink error: $e');
    }
    await Clipboard.setData(ClipboardData(text: link));
    if (ctx.mounted) state.showSnackBar(ctx, 'Paylaşım açılamadı, link kopyalandı.');
  }
}

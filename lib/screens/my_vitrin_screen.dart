import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vixrex/config/app_router.dart';
import 'package:vixrex/config/business_category_config.dart';
import 'package:vixrex/controllers/store_editor_controller.dart';
import 'package:vixrex/models/chat_message.dart';
import 'package:vixrex/screens/my_vitrin/my_vitrin_state.dart';
import 'package:vixrex/screens/my_vitrin/sections/vitrin_form_section.dart';
import 'package:vixrex/screens/my_vitrin/sections/vitrin_publish_section.dart';
import 'package:vixrex/screens/my_vitrin/sections/vitrin_danger_section.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/services/store_local_storage_service.dart';
// NOTE: PublishedSummaryCard is exported from publish_actions_section.dart
import 'package:vixrex/widgets/editor/publish_actions_section.dart';
import 'package:vixrex/widgets/editor/qr_code_bottom_sheet.dart';
import 'package:vixrex/widgets/editor/visibility_hub_card.dart';
import 'package:vixrex/widgets/auto_fill/category_gallery_sheet.dart';

class MyVitrinScreen extends StatefulWidget {
  final String? initialName;
  final VoidCallback? onPublished;
  final VoidCallback? onOpenExplore;

  const MyVitrinScreen({
    super.key,
    this.initialName,
    this.onPublished,
    this.onOpenExplore,
  });

  @override
  State<MyVitrinScreen> createState() => MyVitrinScreenState();
}

class MyVitrinScreenState extends State<MyVitrinScreen> {
  late final StoreEditorController _controller;
  late final MyVitrinState _state;

  StoreEditorController get controller => _controller;

  final _nameController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _instagramController = TextEditingController();
  final _websiteController = TextEditingController();
  final _googleBusinessLinkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = StoreEditorController();
    _state = MyVitrinState(controller: _controller);
    _initialize();
  }

  Future<void> _initialize() async {
    await _controller.initialize(widget.initialName);
    _syncControllers();
    final pendingCategoryKey = await const StoreLocalStorageService().loadPendingCategoryKey();
    if (pendingCategoryKey != null) {
      final label = BusinessCategoryConfig.labelForKey(pendingCategoryKey);
      if (label != null) {
        _controller.selectCategory(label);
      }
      await const StoreLocalStorageService().clearPendingCategoryKey();
    }
  }

  void _syncControllers() {
    _nameController.text = _controller.data.name;
    _whatsappController.text = _controller.data.whatsapp;
    _addressController.text = _controller.data.address;
    _descriptionController.text = _controller.data.description;
    _instagramController.text = _controller.data.instagram;
    _websiteController.text =
        _controller.publishedInfo?.publicLink ?? _controller.data.website;
    _googleBusinessLinkController.text =
        _controller.data.googleBusinessLink;
  }

  /// VixRex aksiyonuna göre ilgili forma otomatik kaydırır ve odaklanır.
  /// [home_shell_screen.dart] tarafindan GlobalKey uzerinden çağrılır.
  void scrollToVixRexAction(VixRexAction action) {
    _state.scrollToVixRexAction(action);
  }

  /// VixRex asistanindan kapak sablonu secim bottom sheet'ini acar.
  /// [home_shell_screen.dart] tarafindan GlobalKey uzerinden çağrılır.
  void openCoverTemplatePicker() {
    CategoryGallerySheet.show(
      context: context,
      source: SheetImageSource.coverPicker,
      onImageAction: (coverUrl, action) {
        _controller.setCoverUrl(coverUrl);
        _controller.saveLocally();
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _whatsappController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _instagramController.dispose();
    _websiteController.dispose();
    _googleBusinessLinkController.dispose();
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _state,
      builder: (context, child) {
        if (_controller.isLoading) {
          return const Scaffold(
            backgroundColor: AppColors.bgEditor,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final hasPublished = _controller.publishedInfo?.isComplete == true;

        return Scaffold(
          backgroundColor: AppColors.bgEditor,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 720;
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 32 : 16,
                    vertical: isDesktop ? 28 : 18,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          VitrinFormSection(
                            controller: _controller,
                            state: _state,
                            textControllers: {
                              'name': _nameController,
                              'whatsapp': _whatsappController,
                              'address': _addressController,
                              'description': _descriptionController,
                              'instagram': _instagramController,
                              'website': _websiteController,
                              'googleBusiness': _googleBusinessLinkController,
                            },
                            onPublished: widget.onPublished,
                            onOpenExplore: widget.onOpenExplore,
                          ),
                          if (hasPublished)
                            VitrinPublishSection(
                              publishedSummary: _buildPublishedSummary(),
                              actionButtons: _buildActionButtons(),
                              visibilityHubCard: _buildVisibilityHubCard(),
                            ),
                          if (hasPublished)
                            VitrinDangerSection(state: _state),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildPublishedSummary() {
    return PublishedSummaryCard(
      info: _controller.publishedInfo!,
      coverUrl: _controller.coverUrl?.trim() ?? '',
      onOpenExplore: widget.onOpenExplore,
    );
  }

  Widget _buildActionButtons() {
    return PublishActionsSection(
      bookingIsEnabled: _controller.bookingIsEnabled,
      onOpenBookingManagement: () => AppRouter.navigateToBookingManagement(
        context,
        slug: _controller.publishedInfo!.slug,
      ),
      onOpenPublicVitrin: () => AppRouter.navigateToPublicVitrin(
        context,
        _controller.publishedInfo!.slug,
      ),
      onCopyLink: () async {
        final link = _controller.publishedInfo?.publicLink;
        if (link == null || link.trim().isEmpty) return;
        await Clipboard.setData(ClipboardData(text: link));
        if (mounted) _state.showSnackBar(context, 'Vitrin linki kopyalandı.');
      },
      onShowQrSheet: () {
        final link = _controller.publishedInfo?.publicLink;
        if (link == null || link.trim().isEmpty) return;
        QrCodeBottomSheet.show(
          context: context,
          title: 'QR Kod',
          link: link,
        );
      },
    );
  }

  Widget _buildVisibilityHubCard() {
    final publicLink = (_controller.publishedInfo?.publicLink.trim().isNotEmpty == true)
        ? _controller.publishedInfo!.publicLink.trim()
        : _websiteController.text.trim();
    final publishedArticles = _controller.articles
        .where((a) => a['status']?.toString() == 'published')
        .toList();

    return VisibilityHubCard(
      hasPublished: _controller.publishedInfo?.isComplete == true,
      hasWebLink: publicLink.isNotEmpty,
      hasLocation: _addressController.text.trim().isNotEmpty ||
          (_controller.latitude != null && _controller.longitude != null),
      hasGoogleReview: _googleBusinessLinkController.text.trim().isNotEmpty,
      hasProfileDescription: _descriptionController.text.trim().isNotEmpty,
      hasPublishedArticle: publishedArticles.isNotEmpty,
      isLoadingArticles: _controller.isLoadingArticles,
      publishedArticles: publishedArticles,
      onShowGoogleReviewQr: () => _showGoogleReviewQrSheet(),
      onCreateArticle: () => _openBlogEditor(),
      onOpenArticle: (article) => _openBlogEditor(article: article),
    );
  }

  void _showGoogleReviewQrSheet() {
    final link = _googleBusinessLinkController.text.trim();
    if (link.isEmpty) {
      _state.showSnackBar(context,
        'Lütfen önce Google Yorum Bağlantısı girin ve vitrininizi kaydedin.');
      return;
    }
    QrCodeBottomSheet.show(
      context: context,
      title: 'Google Yorum QR Kodu',
      link: link,
      warningText: 'Google politikaları gereği yorum karşılığında ödül veya hediye teklif edilmesi yasaktır. Lütfen QR kodunu müşterilerinizden tarafsız ve organik geri bildirimler almak üzere kullanın.',
    );
  }

  Future<void> _openBlogEditor({Map<String, dynamic>? article}) async {
    final slug = _controller.publishedInfo?.slug ?? _controller.data.slug;
    if (slug.trim().isEmpty) {
      _state.showSnackBar(context, 'Önce vitrini yayına almanız gerekir.');
      return;
    }
    final result = await AppRouter.navigateToBlogEditor(
      context, slug: slug, article: article,
    );
    if (result == true) await _controller.fetchArticles();
  }
}

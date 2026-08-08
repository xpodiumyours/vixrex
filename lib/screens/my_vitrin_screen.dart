import 'package:flutter/material.dart';
import 'package:vixrex/config/business_category_config.dart';
import 'package:vixrex/controllers/store_editor_controller.dart';
import 'package:vixrex/models/chat_message.dart';
import 'package:vixrex/screens/my_vitrin/my_vitrin_state.dart';
import 'package:vixrex/screens/my_vitrin/sections/vitrin_form_section.dart';
import 'package:vixrex/screens/my_vitrin/sections/vitrin_danger_section.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/services/store_local_storage_service.dart';
import 'package:vixrex/widgets/auto_fill/category_gallery_sheet.dart';

class MyVitrinScreen extends StatefulWidget {
  final String? initialName;
  final StoreEditorController? editorController;
  final Future<void>? editorInitialization;
  final VoidCallback? onPublished;
  final VoidCallback? onOpenExplore;

  const MyVitrinScreen({
    super.key,
    this.initialName,
    this.editorController,
    this.editorInitialization,
    this.onPublished,
    this.onOpenExplore,
  });

  @override
  State<MyVitrinScreen> createState() => MyVitrinScreenState();
}

class MyVitrinScreenState extends State<MyVitrinScreen> {
  late final StoreEditorController _controller;
  late final MyVitrinState _state;
  late final bool _ownsController;

  StoreEditorController get controller => _controller;

  final _nameController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _heroBadgeController = TextEditingController();
  final _corporateBioController = TextEditingController();
  final _galleryKickerController = TextEditingController();
  final _galleryTitleController = TextEditingController();
  final _galleryActionLabelController = TextEditingController();
  final _galleryActionHrefController = TextEditingController();
  final _workingHoursController = TextEditingController();
  final _addressController = TextEditingController();
  final _heroLocationTextController = TextEditingController();
  final _mapLabelController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _instagramController = TextEditingController();
  final _websiteController = TextEditingController();
  final _googleBusinessLinkController = TextEditingController();
  final _categorySectionTitleController = TextEditingController();
  final _productSectionTitleController = TextEditingController();
  final _blogKickerController = TextEditingController();
  final _blogTitleController = TextEditingController();
  final _faqKickerController = TextEditingController();
  final _faqTitleController = TextEditingController();
  final _faqDescriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ownsController = widget.editorController == null;
    _controller = widget.editorController ?? StoreEditorController();
    _state = MyVitrinState(controller: _controller);
    _controller.addListener(_syncControllers);
    _initialize();
  }

  Future<void> _initialize() async {
    final sharedInitialization = widget.editorInitialization;
    if (sharedInitialization != null) {
      await sharedInitialization;
    } else if (_ownsController) {
      await _controller.initialize(widget.initialName);
    }
    if (!mounted) return;
    _syncControllers();
    final pendingCategoryKey =
        await const StoreLocalStorageService().loadPendingCategoryKey();
    if (!mounted) return;
    if (pendingCategoryKey != null) {
      final label = BusinessCategoryConfig.labelForKey(pendingCategoryKey);
      if (label != null) {
        _controller.selectCategory(label);
      }
      await const StoreLocalStorageService().clearPendingCategoryKey();
    }
  }

  void _syncControllers() {
    _syncText(_nameController, _controller.data.name);
    _syncText(_whatsappController, _controller.data.whatsapp);
    _syncText(_phoneController, _controller.data.phone);
    _syncText(_emailController, _controller.data.email);
    _syncText(_heroBadgeController, _controller.data.heroBadge);
    _syncText(_corporateBioController, _controller.data.corporateBio);
    _syncText(_galleryKickerController, _controller.data.gallerySectionKicker);
    _syncText(_galleryTitleController, _controller.data.gallerySectionTitle);
    _syncText(
      _galleryActionLabelController,
      _controller.data.galleryActionLabel,
    );
    _syncText(_galleryActionHrefController, _controller.data.galleryActionHref);
    _syncText(_workingHoursController, _controller.data.workingHours);
    _syncText(_addressController, _controller.data.address);
    _syncText(
      _heroLocationTextController,
      _controller.data.heroLocationText,
    );
    _syncText(_mapLabelController, _controller.data.mapLabel);
    _syncText(_descriptionController, _controller.data.description);
    _syncText(_instagramController, _controller.data.instagram);
    _syncText(
      _websiteController,
      _controller.publishedInfo?.publicLink ?? _controller.data.website,
    );
    _syncText(
      _googleBusinessLinkController,
      _controller.data.googleBusinessLink,
    );
    _syncText(
      _categorySectionTitleController,
      _controller.data.categorySectionTitle,
    );
    _syncText(
      _productSectionTitleController,
      _controller.data.productSectionTitle,
    );
    _syncText(_blogKickerController, _controller.data.blogSectionKicker);
    _syncText(_blogTitleController, _controller.data.blogSectionTitle);
    _syncText(_faqKickerController, _controller.data.faqSectionKicker);
    _syncText(_faqTitleController, _controller.data.faqSectionTitle);
    _syncText(
      _faqDescriptionController,
      _controller.data.faqSectionDescription,
    );
  }

  void _syncText(TextEditingController controller, String value) {
    if (controller.text == value) return;
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
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
      onImageAction: (coverUrl, action, categoryKey) {
        _controller.setCoverUrl(coverUrl);
        if (categoryKey != null && categoryKey.trim().isNotEmpty) {
          final label = BusinessCategoryConfig.labelForKey(categoryKey);
          if (label != null) {
            _controller.selectCategory(label);
          }
        }
        _controller.saveLocally();
      },
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_syncControllers);
    _nameController.dispose();
    _whatsappController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _heroBadgeController.dispose();
    _corporateBioController.dispose();
    _galleryKickerController.dispose();
    _galleryTitleController.dispose();
    _galleryActionLabelController.dispose();
    _galleryActionHrefController.dispose();
    _workingHoursController.dispose();
    _addressController.dispose();
    _heroLocationTextController.dispose();
    _mapLabelController.dispose();
    _descriptionController.dispose();
    _instagramController.dispose();
    _websiteController.dispose();
    _googleBusinessLinkController.dispose();
    _categorySectionTitleController.dispose();
    _productSectionTitleController.dispose();
    _blogKickerController.dispose();
    _blogTitleController.dispose();
    _faqKickerController.dispose();
    _faqTitleController.dispose();
    _faqDescriptionController.dispose();
    _state.dispose();
    if (_ownsController) _controller.dispose();
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

        return Scaffold(
          backgroundColor: AppColors.bgEditor,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 900;
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 32 : 16,
                    vertical: isDesktop ? 28 : 18,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          VitrinFormSection(
                            controller: _controller,
                            state: _state,
                            textControllers: {
                              'name': _nameController,
                              'whatsapp': _whatsappController,
                              'phone': _phoneController,
                              'email': _emailController,
                              'heroBadge': _heroBadgeController,
                              'corporateBio': _corporateBioController,
                              'galleryKicker': _galleryKickerController,
                              'galleryTitle': _galleryTitleController,
                              'galleryActionLabel':
                                  _galleryActionLabelController,
                              'galleryActionHref':
                                  _galleryActionHrefController,
                              'workingHours': _workingHoursController,
                              'address': _addressController,
                              'heroLocationText': _heroLocationTextController,
                              'mapLabel': _mapLabelController,
                              'description': _descriptionController,
                              'instagram': _instagramController,
                              'website': _websiteController,
                              'googleBusiness': _googleBusinessLinkController,
                              'categorySectionTitle':
                                  _categorySectionTitleController,
                              'productSectionTitle':
                                  _productSectionTitleController,
                              'blogKicker': _blogKickerController,
                              'blogTitle': _blogTitleController,
                              'faqKicker': _faqKickerController,
                              'faqTitle': _faqTitleController,
                              'faqDescription': _faqDescriptionController,
                            },
                            onPublished: widget.onPublished,
                            onOpenExplore: widget.onOpenExplore,
                          ),
                          // Yayın özeti / Google hub / Aç-Kopyala-QR yok.
                          // Form + yalnızca Vitrini Sil.
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
}

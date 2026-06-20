import 'dart:async';

import 'dart:math';

import 'package:flutter/material.dart';

import 'package:qr_flutter/qr_flutter.dart';

import 'package:vitrinx/config/legal_config.dart';
import 'package:vitrinx/theme/vitrin_theme_preset.dart';

import 'package:vitrinx/widgets/vitrin_view.dart';
import 'package:vitrinx/widgets/google_business_guide_card.dart';
import 'package:vitrinx/screens/preview_screen.dart';
import 'package:vitrinx/screens/store_editor/store_editor_controller.dart';
import 'package:vitrinx/screens/store_editor/widgets/store_info_section.dart';
import 'package:vitrinx/screens/store_editor/widgets/store_products_section.dart';
import 'package:vitrinx/screens/store_editor/widgets/store_gallery_section.dart';
import 'package:vitrinx/screens/landing_screen.dart';
import 'package:vitrinx/services/auth_service.dart';
import 'package:vitrinx/services/store_local_storage_service.dart';
import 'package:vitrinx/widgets/unsaved_changes_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitrinx/services/local_storage_keys.dart';
import 'package:vitrinx/screens/store_editor/widgets/store_score_section.dart';

class StoreEditorScreen extends StatefulWidget {
  final String? initialStoreName;

  const StoreEditorScreen({super.key, this.initialStoreName});

  @override
  State<StoreEditorScreen> createState() => _StoreEditorScreenState();
}

class _StoreEditorScreenState extends State<StoreEditorScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TabController _mobileTabController;
  late final StoreEditorController _controller;
  bool _isDeletingAccount = false;
  bool _allowPop = false;
  bool _isExitDialogOpen = false;

  final Map<StoreScoreTarget, GlobalKey> _scoreTargetKeys = {
    StoreScoreTarget.storeName: GlobalKey(),
    StoreScoreTarget.whatsapp: GlobalKey(),
    StoreScoreTarget.description: GlobalKey(),
    StoreScoreTarget.social: GlobalKey(),
    StoreScoreTarget.address: GlobalKey(),
    StoreScoreTarget.marketplace: GlobalKey(),
    StoreScoreTarget.about: GlobalKey(),
    StoreScoreTarget.gallery: GlobalKey(),
  };

  // Premium light editor palette
  static const Color primaryColor = Color(0xFFFF4D00);
  static const Color secondaryColor = Color(0xFFB200FF);
  static const Color bgColor = Color(0xFFF6F8FC);
  static const Color cardBorder = Color.fromRGBO(15, 23, 42, 0.10);
  static const Color darkText = Color(0xFF111827);
  static const Color mutedText = Color(0xFF64748B);
  static const Color softText = Color(0xFF334155);
  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, secondaryColor],
  );

  @override
  void initState() {
    super.initState();
    _controller = StoreEditorController(
      initialStoreName: widget.initialStoreName,
    );
    _mobileTabController = TabController(length: 2, vsync: this);
    _controller.addListener(_onControllerChanged);
    _controller.loadSavedData(context);
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _mobileTabController.dispose();
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _focusMobileEditTab() async {
    if (_mobileTabController.index != 0) {
      _mobileTabController.animateTo(0);
      await Future<void>.delayed(const Duration(milliseconds: 280));
    }
  }

  Future<void> _goToScoreTarget(StoreScoreTarget target) async {
    if (!mounted) return;

    final isMobile = MediaQuery.of(context).size.width <= 900;
    if (isMobile) {
      await _focusMobileEditTab();
    }

    BuildContext? targetContext;
    for (var attempt = 0; attempt < 5; attempt++) {
      targetContext = _scoreTargetKeys[target]?.currentContext;
      if (targetContext != null) break;
      await Future<void>.delayed(const Duration(milliseconds: 90));
    }

    if (!mounted || targetContext == null || !targetContext.mounted) return;

    _controller.triggerHighlightScoreTarget(target);
    final token = _controller.scoreTargetHighlightToken;
    Future<void>.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted || token != _controller.scoreTargetHighlightToken) return;
      _controller.clearHighlightScoreTarget();
    });

    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  Future<void> _showVitrinScoreSheet() async {
    await showStoreScoreSheet(
      context: context,
      controller: _controller,
      onTaskTap: _goToScoreTarget,
    );
  }

  Widget _buildVitrinScoreBadge() {
    return StoreScoreBadge(
      controller: _controller,
      onTap: _showVitrinScoreSheet,
    );
  }

  Widget _buildTodayViewBadge({bool compact = false}) {
    final text =
        _controller.isTodayViewCountLoading ? 'YÃ¼kleniyor...' : ' Ziyaret';

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.trending_up_rounded,
              color: primaryColor,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            if (!_controller.isTodayViewCountLoading) ...[
              const SizedBox(width: 4),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _controller.refreshTodayViewCount(force: true),
                  borderRadius: BorderRadius.circular(999),
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(
                      Icons.refresh_rounded,
                      color: Colors.white38,
                      size: 11,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  BoxDecoration _premiumCardDecoration({double radius = 24}) {
    return BoxDecoration(
      color: const Color.fromRGBO(255, 255, 255, 0.94),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: cardBorder, width: 1),
      boxShadow: const [
        BoxShadow(
          color: Color.fromRGBO(0, 0, 0, 0.08),
          blurRadius: 24,
          offset: Offset(0, 12),
        ),
      ],
    );
  }

  BoxDecoration _studioFrameDecoration() {
    return BoxDecoration(
      color: const Color.fromRGBO(255, 255, 255, 0.92),
      borderRadius: BorderRadius.circular(32),
      border: Border.all(color: cardBorder),
      boxShadow: const [
        BoxShadow(
          color: Color.fromRGBO(0, 0, 0, 0.22),
          blurRadius: 34,
          offset: Offset(0, 18),
        ),
      ],
    );
  }

  Widget _buildEditorBackdrop({required Widget child}) {
    return Stack(
      children: [
        const Positioned.fill(
          child: CustomPaint(painter: _EditorGridPainter()),
        ),
        child,
      ],
    );
  }

  Widget _gradientUnderline({double width = 58}) {
    return Container(
      width: width,
      height: 4,
      decoration: BoxDecoration(
        gradient: ctaGradient,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }

  Widget _buildStudioTopBar() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Color.fromRGBO(255, 255, 255, 0.035),
        border: Border(bottom: BorderSide(color: cardBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: ctaGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: secondaryColor.withValues(alpha: 0.24),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'VX',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Magaza Studio',
                  style: TextStyle(
                    color: darkText,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Magaza icin canli editor',
                  style: TextStyle(
                    color: mutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _buildLegalMenuButton(),
        ],
      ),
    );
  }

  Widget _buildLegalMenuButton() {
    return PopupMenuButton<String>(
      tooltip: 'Hukuki bilgiler',
      color: Colors.white,
      onSelected: (routePath) => Navigator.pushNamed(context, routePath),
      itemBuilder:
          (context) => const [
            PopupMenuItem(
              value: LegalConfig.privacyPath,
              child: Text('KVKK ve Gizlilik Politikası'),
            ),
            PopupMenuItem(
              value: LegalConfig.termsPath,
              child: Text('Kullanım Şartları'),
            ),
            PopupMenuItem(
              value: LegalConfig.dataDeletionPath,
              child: Text('Veri Silme'),
            ),
          ],
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cardBorder),
        ),
        child: const Icon(Icons.policy_rounded, color: softText, size: 18),
      ),
    );
  }

  Widget _buildGradientButton({
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    Widget? child,
    bool expand = false,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      horizontal: 28,
      vertical: 12,
    ),
  }) {
    final content =
        child ??
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );

    final button = Opacity(
      opacity: onPressed == null ? 0.62 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: ctaGradient,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: secondaryColor.withValues(alpha: 0.22),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(40),
            child: Padding(padding: padding, child: content),
          ),
        ),
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }

  void _showDeleteVitrinConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.redAccent,
                size: 24,
              ),
              SizedBox(width: 10),
              Text(
                'Mağazayı Sil',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: darkText,
                ),
              ),
            ],
          ),
          content: const Text(
            'Bu işlem geri alınamaz. Mağazanız tamamen silinecektir. Devam etmek istiyor musunuz?',
            style: TextStyle(color: softText, fontSize: 14, height: 1.5),
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Vazgeç',
                style: TextStyle(fontWeight: FontWeight.bold, color: mutedText),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteVitrin();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Sil',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount() async {
    if (_isDeletingAccount) return;
    setState(() => _isDeletingAccount = true);

    try {
      await const AuthService().deleteAccount();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(LocalStorageKeys.vitrinEditToken);
      await prefs.remove(LocalStorageKeys.vitrinData);
      await prefs.remove(LocalStorageKeys.storeEditToken);
      await prefs.remove(LocalStorageKeys.storeData);
      await const StoreLocalStorageService().clearPublishedVitrinInfo();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hesabınız ve mağaza kayıtlarınız başarıyla silindi.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF10B981),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LandingScreen()),
        (route) => false,
      );
    } catch (e) {
      debugPrint('[Editor] Hesap silme hatası: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hesap silinirken bir hata oluştu: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isDeletingAccount = false);
      }
    }
  }

  Future<void> _showDeleteAccountConfirmation() async {
    final confirmationController = TextEditingController();

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              final canDelete = AuthService.isDeleteConfirmationValid(
                confirmationController.text,
              );

              return AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.redAccent,
                      size: 24,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Hesabımı Sil',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: darkText,
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bu işlem geri alınamaz. Hesabınız ve mağaza/vitrin kayıtlarınız kalıcı olarak silinir.',
                      style: TextStyle(
                        color: softText,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Onaylamak için SİL yazın.',
                      style: TextStyle(
                        color: darkText,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      key: const ValueKey(
                        'store-delete-account-confirmation-input',
                      ),
                      controller: confirmationController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.characters,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: InputDecoration(
                        hintText: 'SİL',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                actionsPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text(
                      'Vazgeç',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: mutedText,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    key: const ValueKey('store-delete-account-confirm-button'),
                    onPressed:
                        canDelete
                            ? () {
                              Navigator.pop(dialogContext);
                              _deleteAccount();
                            }
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.redAccent.withValues(
                        alpha: 0.28,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Hesabı Sil',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      confirmationController.dispose();
    }
  }

  // Replacing state handlers with controller methods
  Future<void> _saveData() => _controller.saveData(context);
  Future<void> _publishStore() => _controller.publishStore(context);
  Future<void> _copyPublishedLink(String msg) =>
      _controller.copyPublishedLink(context, msg);
  Future<void> _deleteVitrin() => _controller.deleteVitrin(context);

  Future<void> _requestExit() async {
    if (_allowPop || !mounted) return;

    if (!_controller.hasUnsavedChanges) {
      _exitEditor();
      return;
    }
    if (_isExitDialogOpen) return;

    _isExitDialogOpen = true;
    final shouldExit = await showUnsavedChangesDialog(context);
    _isExitDialogOpen = false;
    if (shouldExit && mounted) {
      _exitEditor();
    }
  }

  void _exitEditor() {
    if (!mounted) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    final isWide = MediaQuery.of(context).size.width > 900;

    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _requestExit();
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
        backgroundColor: const Color.fromRGBO(255, 255, 255, 0.94),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: darkText,
        shape: const Border(bottom: BorderSide(color: cardBorder)),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: darkText,
          ),
          onPressed: _requestExit,
        ),
        title:
            isWide
                ? Row(
                  children: [
                    const Text(
                      'Mağaza Düzenle',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: darkText,
                        fontSize: 18,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'VITRINX',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: primaryColor.withValues(alpha: 0.62),
                        fontSize: 12,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                )
                : const Text(
                  'Mağaza Düzenle',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: darkText,
                    fontSize: 17,
                  ),
                ),
        actions:
            isWide
                ? [
                  _buildTodayViewBadge(),
                  _buildVitrinScoreBadge(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: _buildGradientButton(
                      label: 'Kaydet',
                      onPressed: _saveData,
                      icon: Icons.cloud_done_outlined,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 12.0,
                    ),
                    child: _buildGradientButton(
                      label: 'Önizle & Paylaş',
                      icon: Icons.visibility_rounded,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => PreviewScreen(
                                  storeData: _controller.data,
                                  previewGalleryItems:
                                      _controller.galleryPreviewItems(),
                                ),
                          ),
                        );
                      },
                      child: const Text(
                        'Önizle & Paylaş',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ]
                : [
                  _buildTodayViewBadge(compact: true),
                  _buildVitrinScoreBadge(),
                ],
      ),
      bottomNavigationBar: !isWide ? _buildMobileBottomActions() : null,
        body: _buildEditorBackdrop(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 900;

            if (!isWide) {
              return DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        color: Color.fromRGBO(22, 22, 36, 0.88),
                        border: Border(bottom: BorderSide(color: cardBorder)),
                      ),
                      child: TabBar(
                        controller: _mobileTabController,
                        labelColor: primaryColor,
                        unselectedLabelColor: mutedText,
                        indicatorColor: primaryColor,
                        tabs: const [
                          Tab(text: 'Düzenle'),
                          Tab(text: 'Yayınla'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _mobileTabController,
                        children: [
                          SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 800,
                                ),
                                child: _buildForm(),
                              ),
                            ),
                          ),
                          SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 800,
                                ),
                                child: _buildPublishPanel(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  width: min(constraints.maxWidth - 48, 1360),
                  height: max(0, constraints.maxHeight - 48),
                  clipBehavior: Clip.antiAlias,
                  decoration: _studioFrameDecoration(),
                  child: Column(
                    children: [
                      _buildStudioTopBar(),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(
                                  34,
                                  30,
                                  28,
                                  34,
                                ),
                                child: Center(
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      maxWidth: 780,
                                    ),
                                    child: _buildForm(
                                      showDesktopPublishCard: true,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const VerticalDivider(width: 1, color: cardBorder),
                            Expanded(
                              flex: 4,
                              child: LayoutBuilder(
                                builder: (context, previewConstraints) {
                                  return Center(
                                    child: _buildLivePreviewMockup(
                                      previewConstraints,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        ),
      ),
    );
  }

  Widget _buildForm({bool showDesktopPublishCard = false}) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showDesktopPublishCard) ...[
            _buildPublishPanel(compact: true, includeBottomSpacing: false),
          ],
          SizedBox(height: showDesktopPublishCard ? 24 : 0),
          StoreGallerySection(
            controller: _controller,
            scoreTargetKeys: _scoreTargetKeys,
          ),
          const SizedBox(height: 24),
          StoreInfoSection(
            controller: _controller,
            scoreTargetKeys: _scoreTargetKeys,
          ),
          const SizedBox(height: 24),
          StoreProductsSection(controller: _controller),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFFEE2E2), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.gpp_maybe_rounded,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tehlikeli Alan / Danger Zone',
                            style: TextStyle(
                              color: Color(0xFF991B1B),
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Geri alınamayacak silme işlemlerini buradan gerçekleştirebilirsiniz.',
                            style: TextStyle(
                              color: Color(0xFFB91C1C),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildDangerZoneTile(
                  title: 'Mağazayı Sil',
                  subtitle:
                      'Mevcut mağazanızı ve tüm yerel verilerinizi kalıcı olarak kaldırır.',
                  isLoading: _controller.isDeleting,
                  onTap:
                      _controller.isDeleting
                          ? null
                          : _showDeleteVitrinConfirmation,
                  icon: Icons.delete_outline_rounded,
                ),
                if (const AuthService().currentUser != null) ...[
                  const SizedBox(height: 12),
                  _buildDangerZoneTile(
                    title: 'Hesabımı Kalıcı Olarak Sil',
                    subtitle:
                        'Kullanıcı hesabınızı ve bağlı mağaza/vitrin kayıtlarınızı kalıcı olarak siler.',
                    isLoading: _isDeletingAccount,
                    onTap:
                        _isDeletingAccount
                            ? null
                            : _showDeleteAccountConfirmation,
                    icon: Icons.person_remove_outlined,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZoneTile({
    required String title,
    required String subtitle,
    required bool isLoading,
    required VoidCallback? onTap,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFEE2E2)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(153, 27, 27, 0.02),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      isLoading
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.redAccent,
                            ),
                          )
                          : Icon(icon, color: Colors.redAccent, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFFFCA5A5),
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPublishPanel({
    bool compact = false,
    bool includeBottomSpacing = true,
  }) {
    final checklist = _controller.publishChecklist();
    final panelChildren =
        compact
            ? <Widget>[
              _buildPublishCard(
                children: [
                  _buildPublishIntro(),
                  const SizedBox(height: 18),
                  _buildPublishSectionTitle('Yayın öncesi kontrol'),
                  const SizedBox(height: 10),
                  ...checklist.map((item) => _buildPublishChecklistRow(item)),
                  const SizedBox(height: 10),
                  _buildPublishSectionTitle('Bu link nerede kullanılabilir?'),
                  const SizedBox(height: 10),
                  _buildPublishUsageList(),
                  const SizedBox(height: 16),
                  _buildPublishActionArea(),
                ],
              ),
            ]
            : <Widget>[
              _buildPublishCard(children: [_buildPublishIntro()]),
              const SizedBox(height: 16),
              _buildPublishCard(
                children: [
                  _buildPublishSectionTitle('Yayın öncesi kontrol'),
                  const SizedBox(height: 10),
                  ...checklist.map((item) => _buildPublishChecklistRow(item)),
                ],
              ),
              const SizedBox(height: 16),
              _buildPublishCard(
                children: [
                  _buildPublishSectionTitle('Bu link nerede kullanılabilir?'),
                  const SizedBox(height: 10),
                  _buildPublishUsageList(),
                  const SizedBox(height: 16),
                  _buildPublishActionArea(),
                ],
              ),
            ];

    if (includeBottomSpacing) {
      panelChildren.add(const SizedBox(height: 100));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: panelChildren,
    );
  }

  String _buildPublicLinkWithSource(String link, String source) {
    try {
      final uri = Uri.parse(link);
      final query = Map<String, String>.from(uri.queryParameters);
      query['src'] = source;
      return uri.replace(queryParameters: query).toString();
    } catch (_) {
      final separator = link.contains('?') ? '&' : '?';
      return '$link${separator}src=$source';
    }
  }

  Widget _buildPublishIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mağazanızı yayınlayın',
          style: TextStyle(
            color: darkText,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        _gradientUnderline(width: 64),
        const SizedBox(height: 8),
        Text(
          'Mağaza linkiniz hazır olduğunda müşteriler bu adrese girerek canlı mağazanızı görebilecek.',
          style: TextStyle(
            color: softText.withValues(alpha: 0.8),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildPublishUsageList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPublishBulletRow('WhatsApp mesajı'),
        _buildPublishBulletRow('Instagram bio'),
        _buildPublishBulletRow('Google İşletme profili'),
        _buildPublishBulletRow('QR kart / mağaza içi afiş'),
      ],
    );
  }

  Widget _buildPublishActionArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_controller.publishedLink != null) ...[
          _buildPublishedLinkBlock(_controller.publishedLink!),
          const SizedBox(height: 12),
        ],
        if (_controller.publishError != null) ...[
          _buildPublishErrorBlock(_controller.publishError!),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _controller.isPublishing ? null : _publishStore,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 13),
              minimumSize: const Size(44, 46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            child:
                _controller.isPublishing
                    ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _controller.isUploadingGallery
                              ? 'Galeri yükleniyor...'
                              : 'Hazırlanıyor...',
                        ),
                      ],
                    )
                    : Text(
                      _controller.publishedLink == null
                          ? 'Mağaza linkini oluştur'
                          : 'Mağazayı güncelle',
                    ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Galeri fotograflari Supabase Storage yuklenir ve public magazada gorunur.',
          style: TextStyle(
            color: mutedText,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildPublishedLinkBlock(String link) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(45, 212, 191, 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color.fromRGBO(45, 212, 191, 0.26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Hazirlanan magaza linki',
                  style: TextStyle(
                    color: const Color(0xFF5EEAD4),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _copyPublishedLink('Mağaza linki kopyalandı.'),
                tooltip: 'Linki kopyala',
                icon: Icon(
                  Icons.copy_rounded,
                  color: Colors.teal.shade800,
                  size: 17,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(255, 255, 255, 0.08),
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(32, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  side: const BorderSide(
                    color: Color.fromRGBO(45, 212, 191, 0.22),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            link,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: darkText,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          _buildPublishedQrBlock(link),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed:
                  () => _copyPublishedLink('Paylaşım için link kopyalandı.'),
              icon: const Icon(Icons.share_outlined, size: 16),
              label: const Text('Paylaş'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF5EEAD4),
                side: const BorderSide(
                  color: Color.fromRGBO(45, 212, 191, 0.32),
                ),
                padding: const EdgeInsets.symmetric(vertical: 11),
                minimumSize: const Size(44, 42),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          GoogleBusinessGuideCard(publishedLink: link),
        ],
      ),
    );
  }

  Widget _buildPublishedQrBlock(String link) {
    final qrLink = _buildPublicLinkWithSource(link, 'qr');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(31, 28, 44, 0.86),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: QrImageView(
              data: qrLink,
              version: QrVersions.auto,
              backgroundColor: Colors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.M,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'QR ile paylaş',
                  style: TextStyle(
                    color: darkText,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Musteriler bu kodu okutarak magazaniza ulasabilir.',
                  style: TextStyle(
                    color: softText.withValues(alpha: 0.86),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Mağaza içine, paket üzerine veya sosyal medya görseline ekleyebilirsiniz.',
                  style: TextStyle(
                    color: mutedText,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublishErrorBlock(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 77, 0, 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color.fromRGBO(255, 77, 0, 0.28)),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: const Color(0xFFFFB085),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      ),
    );
  }

  Widget _buildPublishCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _premiumCardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildPublishSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: darkText,
        fontSize: 15,
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
    );
  }

  Widget _buildPublishChecklistRow(StorePublishChecklistItem item) {
    final color = item.isReady ? const Color(0xFF2DD4BF) : mutedText;

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            item.isReady
                ? Icons.check_circle_rounded
                : Icons.info_outline_rounded,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.isReady ? item.readyText : item.missingText,
              style: TextStyle(
                color: softText.withValues(alpha: 0.88),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublishBulletRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: softText.withValues(alpha: 0.72),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: softText.withValues(alpha: 0.88),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivePreviewMockup(BoxConstraints constraints) {
    final isMobilePreview = constraints.maxWidth < 520;

    if (isMobilePreview) {
      return _buildMobileLivePreview();
    }

    return _buildDesktopLivePreview(constraints);
  }

  Widget _buildPremium3DDeviceFrame({
    required Widget child,
    required double width,
    required double height,
    required bool isDarkTheme,
    bool isMobilePreview = false,
  }) {
    final statusColor =
        isDarkTheme
            ? Colors.white.withValues(alpha: 0.75)
            : Colors.black.withValues(alpha: 0.75);
    final indicatorColor =
        isDarkTheme
            ? Colors.white.withValues(alpha: 0.32)
            : Colors.black.withValues(alpha: 0.28);
    final frameRadius = isMobilePreview ? 46.0 : 52.0;
    final framePadding = isMobilePreview ? 2.2 : 3.0;
    final shellRadius = frameRadius - 3;
    final screenRadius = frameRadius - 5;
    final statusBarHeight = isMobilePreview ? 38.0 : 44.0;
    final bottomInset = isMobilePreview ? 16.0 : 20.0;
    final statusHorizontalPadding = isMobilePreview ? 20.0 : 22.0;
    final islandWidth = isMobilePreview ? 92.0 : 110.0;
    final islandHeight = isMobilePreview ? 23.0 : 26.0;
    final homeIndicatorWidth = isMobilePreview ? 92.0 : 120.0;
    // Titanium frame gradient (silver/matte like iPhone 15 Pro)
    const titaniumGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF9EA5AD), // top-left highlight
        Color(0xFF6B7480), // mid
        Color(0xFF4A5260), // shadow
        Color(0xFF7E8898), // bottom-right partial light
      ],
      stops: [0.0, 0.35, 0.65, 1.0],
    );

    return Stack(
      children: [
        // Outer titanium body with gradient border
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            gradient: titaniumGradient,
            borderRadius: BorderRadius.circular(frameRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.62),
                blurRadius: isMobilePreview ? 42 : 52,
                offset: Offset(0, isMobilePreview ? 22 : 28),
              ),
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.18),
                blurRadius: isMobilePreview ? 38 : 48,
                offset: const Offset(-12, 8),
              ),
              BoxShadow(
                color: secondaryColor.withValues(alpha: 0.22),
                blurRadius: isMobilePreview ? 48 : 60,
                offset: Offset(14, isMobilePreview ? 22 : 28),
              ),
              BoxShadow(
                color: const Color.fromRGBO(255, 255, 255, 0.94),
                blurRadius: 12,
                offset: const Offset(-2, -2),
              ),
            ],
          ),
          padding: EdgeInsets.all(framePadding),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0F),
              borderRadius: BorderRadius.circular(shellRadius),
              border: Border.all(
                color: const Color(0xFF1A1A22),
                width: isMobilePreview ? 1.1 : 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(screenRadius),
              child: Stack(
                children: [
                  // Screen background (black behind VitrinView)
                  const Positioned.fill(
                    child: ColoredBox(color: Color(0xFF000000)),
                  ),
                  // Main phone screen content
                  Positioned.fill(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: statusBarHeight,
                        bottom: bottomInset,
                      ),
                      child: child,
                    ),
                  ),

                  // Gentle inner screen depth so the mockup feels less flat.
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(screenRadius),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(
                                alpha: isMobilePreview ? 0.12 : 0.08,
                              ),
                              Colors.transparent,
                              Colors.black.withValues(
                                alpha: isMobilePreview ? 0.10 : 0.08,
                              ),
                            ],
                            stops: const [0.0, 0.18, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Glossy edge-glow reflection (left)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(screenRadius),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0.06),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.08),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Status Bar background blur
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: statusBarHeight,
                    child: Container(
                      color:
                          isDarkTheme
                              ? const Color(0xCC000000)
                              : Colors.white.withValues(alpha: 0.82),
                    ),
                  ),

                  // Status Bar content
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: statusBarHeight,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: statusHorizontalPadding,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '9:41',
                            style: TextStyle(
                              color: statusColor,
                              fontSize: isMobilePreview ? 12 : 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.signal_cellular_4_bar_rounded,
                                size: 12,
                                color: statusColor,
                              ),
                              const SizedBox(width: 3),
                              Icon(
                                Icons.wifi_rounded,
                                size: 14,
                                color: statusColor,
                              ),
                              const SizedBox(width: 4),
                              // Battery icon
                              SizedBox(
                                width: 24,
                                height: 12,
                                child: Stack(
                                  alignment: Alignment.centerLeft,
                                  children: [
                                    Container(
                                      width: 21,
                                      height: 11,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: statusColor,
                                          width: 1,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          2.5,
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(1.5),
                                      child: Container(
                                        width: 14,
                                        decoration: BoxDecoration(
                                          color: statusColor,
                                          borderRadius: BorderRadius.circular(
                                            1,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      child: Container(
                                        width: 2,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          color: statusColor,
                                          borderRadius: const BorderRadius.only(
                                            topRight: Radius.circular(1),
                                            bottomRight: Radius.circular(1),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Dynamic Island (pill-shaped, modern)
                  Positioned(
                    top: isMobilePreview ? 8 : 10,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: islandWidth,
                        height: islandHeight,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(islandHeight / 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.45),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Front camera dot
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1C1C28),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF2C2C3E),
                                  width: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Home Indicator (swipe bar)
                  Positioned(
                    bottom: 5,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: homeIndicatorWidth,
                        height: 4,
                        decoration: BoxDecoration(
                          color: indicatorColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Physical side buttons — Volume Up
        Positioned(
          left: 0,
          top: height * 0.22,
          child: Container(
            width: 4,
            height: height * 0.07,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF8A929C), Color(0xFF5A6270)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(3),
                bottomLeft: Radius.circular(3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 4,
                  offset: const Offset(-2, 0),
                ),
              ],
            ),
          ),
        ),

        // Physical side buttons — Volume Down
        Positioned(
          left: 0,
          top: height * 0.315,
          child: Container(
            width: 4,
            height: height * 0.07,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF8A929C), Color(0xFF5A6270)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(3),
                bottomLeft: Radius.circular(3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 4,
                  offset: const Offset(-2, 0),
                ),
              ],
            ),
          ),
        ),

        // Physical side buttons — Power/Lock
        Positioned(
          right: 0,
          top: height * 0.265,
          child: Container(
            width: 4,
            height: height * 0.10,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF8A929C), Color(0xFF5A6270)],
              ),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(3),
                bottomRight: Radius.circular(3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 4,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLivePreview() {
    final preset = vitrinThemePresetFor(_controller.data.theme);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      child: Column(
        children: [
          _buildLivePreviewBadge(),
          const SizedBox(height: 16),
          Expanded(
            child: LayoutBuilder(
              builder: (context, phoneConstraints) {
                final maxPhoneWidth = min(
                  phoneConstraints.maxWidth * 0.92,
                  342.0,
                );
                final maxPhoneHeight = phoneConstraints.maxHeight;
                const targetRatio = 2.14;
                var phoneHeight = min(
                  maxPhoneHeight,
                  maxPhoneWidth * targetRatio,
                );
                var phoneWidth = phoneHeight / targetRatio;

                if (phoneWidth < 286.0 &&
                    maxPhoneWidth >= 286.0 &&
                    maxPhoneHeight >= 286.0 * targetRatio) {
                  phoneWidth = 286.0;
                  phoneHeight = phoneWidth * targetRatio;
                }

                phoneWidth = phoneWidth.clamp(260.0, maxPhoneWidth).toDouble();
                phoneHeight = min(maxPhoneHeight, phoneWidth * targetRatio);

                return Center(
                  child: _buildPremium3DDeviceFrame(
                    width: phoneWidth,
                    height: phoneHeight,
                    isDarkTheme: preset.isDark,
                    isMobilePreview: true,
                    child: VitrinView(
                      key: ValueKey(
                        'mobile_preview_${_controller.data.name}_${_controller.data.marketplaceLinks.length}_${_controller.data.description}_${_controller.data.theme}_${_controller.galleryPreviewKey()}',
                      ),
                      storeData: _controller.data,
                      isEmbedded: true,
                      compactEmbeddedHeader: true,
                      previewGalleryItems: _controller.galleryPreviewItems(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivePreviewBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.visibility_rounded, size: 14, color: primaryColor),
          SizedBox(width: 7),
          Text(
            'CANLI ÖNİZLEME',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
              color: softText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLivePreview(BoxConstraints constraints) {
    final preset = vitrinThemePresetFor(_controller.data.theme);

    return Stack(
      children: [
        // Lighter 3D background with radial depth effects
        Positioned.fill(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E2235), // lighter navy-slate
                  Color(0xFF252842), // mid blue-slate
                  Color(0xFF1A1D30), // slightly deeper
                ],
              ),
              border: Border.all(color: Color.fromRGBO(255, 255, 255, 0.10)),
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.52),
                  blurRadius: 34,
                  offset: Offset(0, 18),
                ),
              ],
            ),
          ),
        ),
        // Radial top-left glow (accent light)
        Positioned(
          top: 24,
          left: 24,
          child: IgnorePointer(
            child: Container(
              width: 260,
              height: 260,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x22FF4D00), Colors.transparent],
                ),
              ),
            ),
          ),
        ),
        // Radial bottom-right glow (secondary light)
        Positioned(
          bottom: 24,
          right: 24,
          child: IgnorePointer(
            child: Container(
              width: 220,
              height: 220,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x1AB200FF), Colors.transparent],
                ),
              ),
            ),
          ),
        ),
        // Main content column
        Positioned.fill(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                _buildLivePreviewBadge(),
                const SizedBox(height: 12),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, phoneConstraints) {
                      // Modern 9:19.5 aspect ratio (iPhone 15 Pro-like)
                      final availableH = phoneConstraints.maxHeight;
                      final availableW = phoneConstraints.maxWidth;
                      // Fit phone to fill available space, respecting ratio
                      double phoneHeight = availableH * 0.96;
                      double phoneWidth = phoneHeight / 2.17;
                      if (phoneWidth > availableW * 0.88) {
                        phoneWidth = availableW * 0.88;
                        phoneHeight = phoneWidth * 2.17;
                      }
                      phoneWidth = max(260.0, min(phoneWidth, 390.0));
                      phoneHeight = max(520.0, min(phoneHeight, availableH));

                      return Center(
                        child: _buildPremium3DDeviceFrame(
                          width: phoneWidth,
                          height: phoneHeight,
                          isDarkTheme: preset.isDark,
                          child: VitrinView(
                            key: ValueKey(
                              'preview_${_controller.data.name}_${_controller.data.marketplaceLinks.length}_${_controller.data.description}_${_controller.data.theme}_${_controller.galleryPreviewKey()}',
                            ),
                            storeData: _controller.data,
                            isEmbedded: true,
                            previewGalleryItems:
                                _controller.galleryPreviewItems(),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.94),
        border: const Border(top: BorderSide(color: cardBorder)),
        boxShadow: [
          BoxShadow(
            color: secondaryColor.withValues(alpha: 0.10),
            blurRadius: 22,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: _buildGradientButton(
                label: 'Kaydet',
                onPressed: _saveData,
                icon: Icons.cloud_done_outlined,
                expand: true,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGradientButton(
                label: 'Mağazayı Aç',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => PreviewScreen(
                            storeData: _controller.data,
                            previewGalleryItems:
                                _controller.galleryPreviewItems(),
                          ),
                    ),
                  );
                },
                icon: Icons.share_outlined,
                expand: true,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorGridPainter extends CustomPainter {
  const _EditorGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = const Color.fromRGBO(15, 23, 42, 0.055)
          ..strokeWidth = 0.5;

    for (double x = 0; x <= size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y <= size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

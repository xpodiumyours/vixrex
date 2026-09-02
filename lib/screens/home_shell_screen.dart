import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vixrex/config/app_router.dart';
import 'package:vixrex/config/business_category_config.dart';
import 'package:vixrex/config/public_site_config.dart';
import 'package:vixrex/models/chat_message.dart';
import 'package:vixrex/services/auth_service.dart';
import 'package:vixrex/services/chatbot_service.dart';
import 'package:vixrex/screens/blog_moderation_screen.dart';
import 'package:vixrex/screens/explore_screen.dart';
import 'package:vixrex/screens/my_vitrin_screen.dart';
import 'package:vixrex/screens/ocr_scanner_screen.dart';
import 'package:vixrex/screens/vixrex_screen.dart';
import 'package:vixrex/screens/profile_screen.dart';
import 'package:vixrex/controllers/ocr_controller.dart';
import 'package:vixrex/controllers/store_editor_controller.dart';
import 'package:vixrex/services/ocr/ocr_service.dart';
import 'package:vixrex/services/store_local_storage_service.dart';
import 'package:vixrex/services/vixrex_assistant_nlu_types.dart';
import 'package:vixrex/services/vixrex_session_controller.dart';
import 'package:vixrex/services/vixrex_profile_snapshot.dart';
import 'package:vixrex/services/vixrex_promotion_service.dart';
import 'package:vixrex/widgets/chatbot_badge.dart';
import 'package:vixrex/widgets/editor/qr_code_bottom_sheet.dart';
import 'package:vixrex/widgets/shell/shell_sidebar.dart';
import 'package:vixrex/widgets/shell/shell_status_bar.dart';
import 'package:vixrex/widgets/xml_upload_dialog.dart';
import 'package:vixrex/theme/app_colors.dart';

class HomeShellScreen extends StatefulWidget {
  final int initialIndex;
  final String? initialVitrinName;

  /// Asistan/kurulumdan gelen tek aksiyon — mevcut VixRex handler'larına düşer.
  final VixRexAction? initialVixRexAction;

  const HomeShellScreen({
    super.key,
    this.initialIndex = 0,
    this.initialVitrinName,
    this.initialVixRexAction,
  });

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  late int _selectedIndex;
  final _myVitrinKey = GlobalKey<MyVitrinScreenState>();
  final _exploreKey = GlobalKey<ExploreScreenState>();
  final _globalSearchController = TextEditingController();
  late final StoreEditorController _editorController;
  late final Future<void> _editorInitialization;

  // Chat History
  final List<ChatMessage> _vixrexChatMessages = [];

  // ── Vixrex Snapshot ─────────────────────────────────────────────────────────
  VixRexProfileSnapshot? _vixrexSnapshot;
  PublishedVitrinInfo? _publishedInfo;
  bool _vixrexHasShared = false;
  String? _dismissedVixRexRecommendationId;
  final _snapshotLoader = const VixRexSnapshotLoader();

  /// Mevcut kullanıcının yönetici olup olmadığını kontrol eder.
  bool get _isAdmin {
    try {
      final meta = const AuthService().currentUser?.userMetadata;
      return meta?['is_admin'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Ekran genişliğine göre masaüstü modu
  bool _isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width > 900;
  }

  @override
  void initState() {
    super.initState();
    // Doğrudan sekme indeksi: 0=Vitrinim, 1=Keşfet, 2=Vixrex, 3=Profil, 4=Moderasyon
    _selectedIndex = widget.initialIndex < 0 ? 0 : widget.initialIndex;
    // Vixrex Asistan'ın TEK oturumu — landing'de açılmış bir sohbet varsa
    // (bkz. VixRexSessionController) aynı controller burada da kullanılır,
    // kaldığı yerden devam eder. Bu ekran controller'ı SAHİPLENMEZ, o yüzden
    // dispose() burada çağrılmaz — uygulama boyunca yaşar.
    _editorController = VixRexSessionController.controller;
    _editorController.addListener(_onEditorChanged);
    _editorInitialization = VixRexSessionController.ensureInitialized(
      widget.initialVitrinName,
    );
    _loadVixRexSnapshot();
    final pending = widget.initialVixRexAction;
    if (pending != null && pending != VixRexAction.none) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future<void>.delayed(const Duration(milliseconds: 350), () {
          if (!mounted) return;
          _handleVixRexAction(pending);
        });
      });
    }
  }

  void _onEditorChanged() {
    _loadVixRexSnapshot();
    _kontrolEtPendingDraft();
  }

  /// Vixrex Asistan tarayıcıda taslak güncellediğinde Flutter'da bildirir.
  void _kontrolEtPendingDraft() {
    if (!_editorController.hasPendingExternalDraft) return;
    final etiket = _editorController.lastExternalDraftEtiket;
    _editorController.clearPendingExternalDraft();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          etiket != null
              ? 'Asistan "$etiket" alanını güncelledi.'
              : 'Asistan vitrinde bir güncelleme yaptı.',
        ),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(label: 'Tamam', onPressed: () {}),
      ),
    );
  }

  @override
  void dispose() {
    _globalSearchController.dispose();
    _editorController.removeListener(_onEditorChanged);
    // _editorController.dispose() ÇAĞRILMAZ: bu, VixRexSessionController'ın
    // paylaşılan tek örneği — bu ekran onu sahiplenmiyor, uygulama boyunca
    // yaşamaya devam eder (landing ve diğer HomeShell açılışları da kullanır).
    super.dispose();
  }

  // ── Snapshot Yükleme ──────────────────────────────────────────────────────

  Future<void> _loadVixRexSnapshot() async {
    final snapshot = await _snapshotLoader.load();
    final storage = const StoreLocalStorageService();
    final publishedInfo = await storage.loadPublishedVitrinInfo();

    // Geçmiş sohbeti yerel depolamadan yükle
    final chatbotService = ChatbotService();
    final history = await chatbotService.loadHistory();
    final hasShared = await chatbotService.hasSharedVitrin();
    final dismissedRecommendationId =
        await chatbotService.loadDismissedRecommendationId();

    if (mounted) {
      setState(() {
        _vixrexSnapshot = snapshot;
        _publishedInfo = publishedInfo;
        _vixrexHasShared = hasShared;
        _dismissedVixRexRecommendationId = dismissedRecommendationId;
        _vixrexChatMessages.clear();
        _vixrexChatMessages.addAll(history);
      });
    }
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void _openExplore() {
    setState(() => _selectedIndex = 1); // Discover
    _exploreKey.currentState?.reloadStores();
  }

  void _applyGlobalSearch(String query) {
    setState(() => _selectedIndex = 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _exploreKey.currentState?.applyExternalSearch(query);
    });
  }

  /// [İyileştirme #3] Vitrin yayınlandığında snapshot otomatik yenilenir.
  void _handleVitrinPublished() {
    _exploreKey.currentState?.reloadStores();
    _loadVixRexSnapshot();
  }

  // ── Vixrex Action Callbacks ─────────────────────────────────────────────────

  void _vixrexNavigateToVitrim() {
    setState(() => _selectedIndex = 0); // Store
  }

  void _vixrexCopyLink() {
    final raw = _publishedInfo?.publicLink;
    if (raw != null && raw.isNotEmpty) {
      final link = PublicSiteConfig.repairPublicLink(raw);
      Clipboard.setData(ClipboardData(text: link));
      _markVixRexShared();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link panoya kopyalandı!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _vixrexShareWhatsapp() async {
    final raw = _publishedInfo?.publicLink;
    if (raw == null || raw.isEmpty) return;
    final link = PublicSiteConfig.repairPublicLink(raw);

    final snapshot = _vixrexSnapshot;
    final message =
        snapshot == null
            ? 'Merhaba! Dijital vitrinimi incelemek için bağlantıyı kullanabilirsiniz: $link'
            : VixRexPromotionService.draftsFor(snapshot)[1].text;
    await _vixrexSharePromotionText(message);
  }

  Future<void> _vixrexSharePromotionText(String message) async {
    final normalizedMessage = message.trim();
    if (normalizedMessage.isEmpty) return;

    await _markVixRexShared();
    final whatsappUrl = Uri.parse(
      'https://api.whatsapp.com/send?text=${Uri.encodeComponent(normalizedMessage)}',
    );

    try {
      final launched = await launchUrl(
        whatsappUrl,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        Clipboard.setData(ClipboardData(text: normalizedMessage));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WhatsApp açılamadı, metin panoya kopyalandı!'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        Clipboard.setData(ClipboardData(text: normalizedMessage));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hata oluştu, metin panoya kopyalandı!'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _vixrexShowQr() {
    final raw = _publishedInfo?.publicLink;
    if (raw == null || raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'QR kodunu göstermek için önce vitrininizi yayınlamalısınız!',
          ),
        ),
      );
      return;
    }
    _markVixRexShared();
    QrCodeBottomSheet.show(
      context: context,
      title: 'Vitrin QR Kodunuz',
      link: PublicSiteConfig.repairPublicLink(raw),
    );
  }

  void _vixrexScrollToAction(VixRexAction action) {
    setState(() => _selectedIndex = 0); // Store
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _myVitrinKey.currentState?.scrollToVixRexAction(action);
    });
  }

  void _vixrexOpenCoverTemplatePicker() {
    setState(() => _selectedIndex = 0); // Store
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _myVitrinKey.currentState?.openCoverTemplatePicker();
    });
  }

  void _openOcrScanner({String scanMode = 'receipt'}) {
    final editorController = _myVitrinKey.currentState?.controller;
    if (editorController == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vitrin henüz yüklenmedi. Lütfen bekleyin.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final ocrController = OcrController(
      ocrService: const OcrService(),
      editorController: editorController,
    );
    ocrController.scanMode = scanMode;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OcrScannerScreen(ocrController: ocrController),
      ),
    );
  }

  void _openXmlUpload() {
    final editorController = _myVitrinKey.currentState?.controller;
    if (editorController == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vitrin henüz yüklenmedi. Lütfen bekleyin.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final storeId = editorController.data.id?.trim() ?? '';
    final editToken = editorController.publishedInfo?.editToken.trim() ?? '';

    if (storeId.isEmpty || editToken.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Önce vitrininizi yayınlayın.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // XML yükleme dialogunu aç
    XmlUploadDialog.show(
      context: context,
      storeId: storeId,
      editToken: editToken,
      onUploaded: () {
        if (mounted) setState(() {});
      },
    );
  }

  Future<void> _markVixRexShared() async {
    await ChatbotService().markVitrinShared();
    if (!mounted) return;
    setState(() => _vixrexHasShared = true);
  }

  Future<void> _dismissVixRexRecommendation(String recommendationId) async {
    await ChatbotService().dismissRecommendation(recommendationId);
    if (!mounted) return;
    setState(() => _dismissedVixRexRecommendationId = recommendationId);
  }

  // Faz 1 – 46 alan borusu: genel alan güncelleme (yeni)
  void _handleVixRexUpdateField(String anahtar, Object? deger) {
    final editorController = _myVitrinKey.currentState?.controller;
    if (editorController == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vitrin henüz yüklenmedi. Lütfen bekleyin.'), duration: Duration(seconds: 2)),
      );
      return;
    }
    // Yasal alanlar bu borudan yasak – mevcut legal akışa yönlendirme gerekmez (sözlükte yok).
    // Özel akış: il/ilce listeden seçilmeli – burada serbest metinle yazmayı denemeyip yönlendir.
    if (anahtar == 'il' || anahtar == 'ilce') {
      _vixrexScrollToAction(VixRexAction.scrollToAddress);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İl/İlçe listeden seçilmeli – adres bölümüne yönlendirildin.'), duration: Duration(seconds: 2)),
      );
      return;
    }
    try {
      // deger String/num/bool olabilir – VixrexExecutor ile aynı mantık.
      if (deger is bool) {
        editorController.updateField(anahtar, deger);
      } else if (deger is num) {
        editorController.updateField(anahtar, deger);
      } else {
        editorController.updateField(anahtar, deger?.toString() ?? '');
      }
      // Özel: kategori string label’ı selectCategory ile senkron et (businessType + booking paketi)
      if (anahtar == 'kategori' && deger is String) {
        try {
          editorController.selectCategory(deger);
        } catch (_) {}
      }
      editorController.saveLocally();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kaydedildi: $anahtar'), duration: const Duration(seconds: 2)),
      );
    } catch (e) {
      // writeField desteklemiyor → özel akış (görsel yükle vb.)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bu alan için panelden devam et: $e'), duration: const Duration(seconds: 2)),
      );
    }
  }

  /// Faz 8.1 — sohbette onaylanan alanı GERÇEK `StoreEditorController`
  /// üzerinden kaydeder. Anlama katmanı mock; yazma yolu değişmedi
  /// (ikinci yazma yolu açılmadı).
  void _handleVixRexSaveField(VixRexNluField field, String value) {
    final editorController = _myVitrinKey.currentState?.controller;
    if (editorController == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vitrin henüz yüklenmedi. Lütfen bekleyin.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    switch (field) {
      case VixRexNluField.storeName:
        editorController.setName(value);
        break;
      case VixRexNluField.whatsapp:
        editorController.updateWhatsapp(value);
        break;
      case VixRexNluField.address:
        editorController.updateAddress(editorController.data, value);
        break;
      case VixRexNluField.description:
        editorController.setDescription(value);
        break;
      case VixRexNluField.category:
        final normalized = value.toLowerCase().trim();
        final category = BusinessCategoryConfig.categories.where(
          (item) =>
              item.id.toLowerCase() == normalized ||
              item.label.toLowerCase() == normalized,
        );
        if (category.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bu kategori Vixrex listesinde bulunamadı.'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        editorController.selectCategory(category.first.id);
        break;
    }
  }

  /// Yayınlanmamış kurulum: Vixrex sekmesindeki gömülü onboarding (route yok).
  bool get _needsSetupOnboarding {
    final snapshot = _vixrexSnapshot;
    return snapshot == null || !snapshot.isPublished;
  }

  void _openSetupOnboarding() {
    setState(() => _selectedIndex = 2);
  }

  Future<void> _onVixRexSetupComplete() async {
    await _loadVixRexSnapshot();
    if (!mounted) return;
    _exploreKey.currentState?.reloadStores();
    setState(() => _selectedIndex = 2);
  }

  void _handleVixRexAction(VixRexAction action) {
    switch (action) {
      case VixRexAction.openVitrim:
        // Yayın yoksa Vixrex sekmesi (kurulum); yayında Vitrinim.
        if (_needsSetupOnboarding) {
          _openSetupOnboarding();
        } else {
          _vixrexNavigateToVitrim();
        }
        break;
      case VixRexAction.copyLink:
        _vixrexCopyLink();
        break;
      case VixRexAction.shareWhatsapp:
        _vixrexShareWhatsapp();
        break;
      case VixRexAction.showQr:
        _vixrexShowQr();
        break;
      case VixRexAction.openExplore:
        _openExplore();
        break;
      case VixRexAction.scrollToName:
      case VixRexAction.scrollToWhatsapp:
      case VixRexAction.scrollToAddress:
      case VixRexAction.scrollToLegal:
        // Kurulumda Vixrex sekmesi; yayında form scroll.
        if (_needsSetupOnboarding) {
          _openSetupOnboarding();
        } else {
          _vixrexScrollToAction(action);
        }
        break;
      case VixRexAction.scrollToCover:
      case VixRexAction.scrollToGallery:
      case VixRexAction.scrollToDesc:
      case VixRexAction.scrollToProducts:
      case VixRexAction.scrollToCategory:
        _vixrexScrollToAction(action);
        break;
      case VixRexAction.openCoverTemplatePicker:
        _vixrexOpenCoverTemplatePicker();
        break;
      case VixRexAction.openOcrScanner:
        _openOcrScanner(scanMode: 'receipt');
        break;
      case VixRexAction.openOcrScannerShelf:
        _openOcrScanner(scanMode: 'shelf_label');
        break;
      case VixRexAction.openXmlUpload:
        _openXmlUpload();
        break;
      case VixRexAction.openAuth:
        AppRouter.navigateToAuth(context);
        break;
      case VixRexAction.none:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _isAdmin;
    final isDesktop = _isDesktop(context);

    final pages = [
      MyVitrinScreen(
        key: _myVitrinKey,
        initialName: widget.initialVitrinName,
        editorController: _editorController,
        editorInitialization: _editorInitialization,
        onPublished: _handleVitrinPublished,
        onOpenExplore: _openExplore,
      ),
      ExploreScreen(key: _exploreKey),
      VixRexScreen(
        snapshot: _vixrexSnapshot,
        editorController: _editorController,
        editorInitialization: _editorInitialization,
        hasShared: _vixrexHasShared,
        dismissedRecommendationId: _dismissedVixRexRecommendationId,
        onAction: _handleVixRexAction,
        onSaveField: _handleVixRexSaveField,
        onUpdateField: _handleVixRexUpdateField,
        onDismissRecommendation: _dismissVixRexRecommendation,
        onSetupComplete: _onVixRexSetupComplete,
      ),
      ProfileScreen(
        publicLink: _publishedInfo?.publicLink,
        storeName: _vixrexSnapshot?.storeName,
        onShowQr: _vixrexShowQr,
        onCopyLink: _vixrexCopyLink,
      ),
      if (isAdmin) const BlogModerationScreen(),
    ];

    // Güvenlik: index sayfa sayısını aşmasın
    final safeIndex = _selectedIndex.clamp(0, pages.length - 1);

    // Masaüstü için sidebar menü öğeleri
    final sidebarItems = [
      ShellSidebarItem(
        icon: Icons.storefront_outlined,
        selectedIcon: Icons.storefront_rounded,
        label: 'Vitrinim',
      ),
      ShellSidebarItem(
        icon: Icons.travel_explore_outlined,
        selectedIcon: Icons.travel_explore_rounded,
        label: 'Keşfet',
      ),
      ShellSidebarItem(
        icon: Icons.assistant_outlined,
        selectedIcon: Icons.assistant_rounded,
        label: 'Vixrex',
      ),
      ShellSidebarItem(
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
        label: 'Profil',
      ),
      if (isAdmin)
        ShellSidebarItem(
          icon: Icons.admin_panel_settings_outlined,
          selectedIcon: Icons.admin_panel_settings_rounded,
          label: 'Moderasyon',
        ),
    ];

    // Mobil için alt navigasyon barı
    final destinations = [
      const NavigationDestination(
        icon: Icon(Icons.storefront_outlined),
        selectedIcon: Icon(Icons.storefront_rounded),
        label: 'Vitrinim',
      ),
      const NavigationDestination(
        icon: Icon(Icons.travel_explore_outlined),
        selectedIcon: Icon(Icons.travel_explore_rounded),
        label: 'Keşfet',
      ),
      const NavigationDestination(
        icon: Icon(Icons.assistant_outlined),
        selectedIcon: Icon(Icons.assistant_rounded),
        label: 'Vixrex',
      ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline_rounded),
        selectedIcon: Icon(Icons.person_rounded),
        label: 'Profil',
      ),
      if (isAdmin)
        const NavigationDestination(
          icon: Icon(Icons.admin_panel_settings_outlined),
          selectedIcon: Icon(Icons.admin_panel_settings_rounded),
          label: 'Moderasyon',
        ),
    ];

    // Masaüstü sidebar
    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppColors.bgEditor,
        body: Row(
          children: [
            ShellSidebar(
              items: sidebarItems,
              selectedIndex: _selectedIndex,
              onSelected: (index) {
                setState(() => _selectedIndex = index);
                if (index == 1) _exploreKey.currentState?.reloadStores();
                if (index == 2) _loadVixRexSnapshot();
              },
              searchController: _globalSearchController,
              onSearchSubmitted: _applyGlobalSearch,
              onSearchChanged: (value) {
                if (_selectedIndex == 1) {
                  _exploreKey.currentState?.applyExternalSearch(value);
                }
              },
            ),
            // Ana içerik
            Expanded(
              child: Column(
                children: [
                  ShellStatusBar(
                    isPublished: _vixrexSnapshot?.isPublished ?? false,
                    publicLink:
                        _publishedInfo?.publicLink == null
                            ? null
                            : PublicSiteConfig.repairPublicLink(
                              _publishedInfo!.publicLink,
                            ).replaceFirst(RegExp(r'^https?://'), ''),
                    onCopyLink: _vixrexCopyLink,
                    onShowQr: _vixrexShowQr,
                    onOpenVitrin:
                        () => _handleVixRexAction(VixRexAction.openVitrim),
                    onPublish: _openSetupOnboarding,
                  ),
                  Expanded(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IndexedStack(index: safeIndex, children: pages),
                        // Vitrinim ekraninda alt butonlari kapatmasin.
                        if (_selectedIndex != 0 && _selectedIndex != 2)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: SafeArea(
                              minimum: const EdgeInsets.only(
                                right: 16,
                                bottom: 16,
                              ),
                              child: ChatbotBadge(
                                snapshot: _vixrexSnapshot,
                                hasShared: _vixrexHasShared,
                                // Tek kapı: overlay FAQ yok → mevcut VixRex sekmesi.
                                onOpen:
                                    () => setState(() => _selectedIndex = 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Mobil layout (mevcut yapı)
    return Scaffold(
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          IndexedStack(index: safeIndex, children: pages),
          // Vitrinim ekraninda alt butonlari kapatmasin.
          if (_selectedIndex != 0 && _selectedIndex != 2)
            Positioned(
              right: 0,
              bottom: 0,
              child: SafeArea(
                minimum: const EdgeInsets.only(right: 16, bottom: 16),
                child: ChatbotBadge(
                  snapshot: _vixrexSnapshot,
                  hasShared: _vixrexHasShared,
                  // Tek kapı: overlay FAQ yok → mevcut VixRex sekmesi.
                  onOpen: () => setState(() => _selectedIndex = 2),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 0.8)),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() => _selectedIndex = index);
            if (index == 1) _exploreKey.currentState?.reloadStores();
            if (index == 2) _loadVixRexSnapshot();
          },
          destinations: destinations,
        ),
      ),
    );
  }
}

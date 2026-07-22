import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';
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
import 'package:vixrex/services/vixrex_profile_snapshot.dart';
import 'package:vixrex/services/vixrex_promotion_service.dart';
import 'package:vixrex/widgets/chatbot_badge.dart';
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
    _editorController = StoreEditorController();
    _editorInitialization = _editorController.initialize(
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

  @override
  void dispose() {
    _globalSearchController.dispose();
    _editorController.dispose();
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
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    final link = PublicSiteConfig.repairPublicLink(raw);

    _markVixRexShared();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Vitrin QR Kodunuz',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Müşterileriniz bu QR kodu okutarak vitrininize hızlıca ulaşabilir.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.mutedText),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        Colors
                            .white, // Keep QR white background for scan reliability
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: QrImageView(
                      data: link,
                      version: QrVersions.auto,
                      size: 200,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: link));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vitrin linki kopyalandı!')),
                    );
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Linki Kopyala'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
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
      _SidebarItem(
        icon: Icons.storefront_outlined,
        selectedIcon: Icons.storefront_rounded,
        label: 'Vitrinim',
      ),
      _SidebarItem(
        icon: Icons.travel_explore_outlined,
        selectedIcon: Icons.travel_explore_rounded,
        label: 'Keşfet',
      ),
      _SidebarItem(
        icon: Icons.assistant_outlined,
        selectedIcon: Icons.assistant_rounded,
        label: 'Vixrex',
      ),
      _SidebarItem(
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
        label: 'Profil',
      ),
      if (isAdmin)
        _SidebarItem(
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
            // Sidebar
            Container(
              width: 220,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  right: BorderSide(color: AppColors.border, width: 0.8),
                ),
              ),
              child: Column(
                children: [
                  // Logo alanı
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.storefront_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Vixrex',
                          style: TextStyle(
                            color: AppColors.darkText,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                    child: TextField(
                      controller: _globalSearchController,
                      style: const TextStyle(
                        color: AppColors.darkText,
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Vitrin veya ürün ara...',
                        hintStyle: const TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 12,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          size: 18,
                          color: AppColors.mutedText,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        filled: true,
                        fillColor: AppColors.inputBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: _applyGlobalSearch,
                      onChanged: (value) {
                        if (_selectedIndex == 1) {
                          _exploreKey.currentState?.applyExternalSearch(value);
                        }
                      },
                    ),
                  ),
                  // Menü öğeleri
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      itemCount: sidebarItems.length,
                      itemBuilder: (context, index) {
                        final item = sidebarItems[index];
                        final isSelected = _selectedIndex == index;
                        return _buildSidebarItem(
                          item: item,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() => _selectedIndex = index);
                            if (index == 2) _loadVixRexSnapshot();
                          },
                        );
                      },
                    ),
                  ),
                  // Alt bilgi
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: const Text(
                      'v1.0.0',
                      style: TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Ana içerik
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  IndexedStack(index: safeIndex, children: pages),
                  // Vixrex robot rozeti
                  if (_selectedIndex != 2)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: SafeArea(
                        minimum: const EdgeInsets.only(right: 16, bottom: 16),
                        child: ChatbotBadge(
                          // Tek kapı: overlay FAQ yok → mevcut VixRex sekmesi.
                          onOpen: () => setState(() => _selectedIndex = 2),
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

    // Mobil layout (mevcut yapı)
    return Scaffold(
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          IndexedStack(index: safeIndex, children: pages),
          // Vixrex: Sağ alt köşede yüzen robot rozeti (sadece Vixrex tabında değilken gösterilir)
          if (_selectedIndex != 2)
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
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: AppColors.bgEditor,
          indicatorColor: AppColors.primary.withAlpha(40),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              );
            }
            return const TextStyle(color: AppColors.mutedText, fontSize: 11);
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: AppColors.primary);
            }
            return const IconThemeData(color: AppColors.mutedText);
          }),
        ),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.border, width: 0.8),
            ),
          ),
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
              if (index == 2) _loadVixRexSnapshot();
            },
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: destinations,
            height: 65,
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarItem({
    required _SidebarItem item,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color:
            isSelected ? AppColors.primary.withAlpha(15) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  isSelected ? item.selectedIcon : item.icon,
                  color: isSelected ? AppColors.primary : AppColors.mutedText,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color:
                          isSelected ? AppColors.darkText : AppColors.mutedText,
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _SidebarItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

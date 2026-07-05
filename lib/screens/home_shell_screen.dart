import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:vitrinx/models/chat_message.dart';
import 'package:vitrinx/services/chatbot_service.dart';
import 'package:vitrinx/screens/blog_moderation_screen.dart';
import 'package:vitrinx/screens/explore_screen.dart';
import 'package:vitrinx/screens/my_vitrin_screen.dart';
import 'package:vitrinx/screens/xrex_screen.dart';
import 'package:vitrinx/screens/profile_screen.dart';
import 'package:vitrinx/services/store_local_storage_service.dart';
import 'package:vitrinx/services/xrex_profile_snapshot.dart';
import 'package:vitrinx/services/xrex_promotion_service.dart';
import 'package:vitrinx/widgets/chatbot_overlay.dart';
import 'package:vitrinx/theme/app_colors.dart';

class HomeShellScreen extends StatefulWidget {
  final int initialIndex;
  final String? initialVitrinName;

  const HomeShellScreen({
    super.key,
    this.initialIndex = 1,
    this.initialVitrinName,
  });

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  late int _selectedIndex;
  int _exploreRefreshKey = 0;
  final _myVitrinKey = GlobalKey<MyVitrinScreenState>();

  // Chat History
  final List<ChatMessage> _xrexChatMessages = [];

  // ── Xrex Snapshot ─────────────────────────────────────────────────────────
  XrexProfileSnapshot? _xrexSnapshot;
  PublishedVitrinInfo? _publishedInfo;
  bool _xrexHasShared = false;
  String? _dismissedXrexRecommendationId;
  final _snapshotLoader = const XrexSnapshotLoader();

  /// Mevcut kullanıcının yönetici olup olmadığını kontrol eder.
  bool get _isAdmin {
    try {
      final meta = Supabase.instance.client.auth.currentUser?.userMetadata;
      return meta?['is_admin'] == true;
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    // Safely map initialIndex:
    // Old 0 (Explore) -> New 1 (Discover)
    // Old 1 (MyVitrin) -> New 0 (Store)
    // Old 2 (Moderation) -> New 4 (Moderation)
    if (widget.initialIndex == 0) {
      _selectedIndex = 1;
    } else if (widget.initialIndex == 1) {
      _selectedIndex = 0;
    } else if (widget.initialIndex == 2 && _isAdmin) {
      _selectedIndex = 4;
    } else {
      _selectedIndex = 0; // Default to Store
    }
    _loadXrexSnapshot();
  }

  // ── Snapshot Yükleme ──────────────────────────────────────────────────────

  Future<void> _loadXrexSnapshot() async {
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
        _xrexSnapshot = snapshot;
        _publishedInfo = publishedInfo;
        _xrexHasShared = hasShared;
        _dismissedXrexRecommendationId = dismissedRecommendationId;
        _xrexChatMessages.clear();
        _xrexChatMessages.addAll(history);
      });
    }
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void _openExplore() {
    setState(() {
      _selectedIndex = 1; // Discover
      _exploreRefreshKey++;
    });
  }

  /// [İyileştirme #3] Vitrin yayınlandığında snapshot otomatik yenilenir.
  void _handleVitrinPublished() {
    setState(() => _exploreRefreshKey++);
    _loadXrexSnapshot(); // ← Snapshot anında güncellenir
  }

  // ── Xrex Action Callbacks ─────────────────────────────────────────────────

  void _xrexNavigateToVitrim() {
    setState(() => _selectedIndex = 0); // Store
  }

  void _xrexCopyLink() {
    final link = _publishedInfo?.publicLink;
    if (link != null && link.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: link));
      _markXrexShared();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link panoya kopyalandı!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _xrexShareWhatsapp() async {
    final link = _publishedInfo?.publicLink;
    if (link == null || link.isEmpty) return;

    final snapshot = _xrexSnapshot;
    final message = snapshot == null
        ? 'Merhaba! Dijital vitrinimi incelemek için bağlantıyı kullanabilirsiniz: $link'
        : XrexPromotionService.draftsFor(snapshot)[1].text;
    await _xrexSharePromotionText(message);
  }

  void _xrexCopyPromotionText(String text) {
    if (text.trim().isEmpty) return;
    Clipboard.setData(ClipboardData(text: text.trim()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tanıtım metni panoya kopyalandı!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _xrexSharePromotionText(String message) async {
    final normalizedMessage = message.trim();
    if (normalizedMessage.isEmpty) return;

    await _markXrexShared();
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

  void _xrexShowQr() {
    final link = _publishedInfo?.publicLink;
    if (link == null || link.isEmpty) {
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

    _markXrexShared();

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
                        Colors.white, // Keep QR white background for scan reliability
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

  void _xrexScrollToAction(XrexAction action) {
    setState(() => _selectedIndex = 0); // Store
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _myVitrinKey.currentState?.scrollToXrexAction(action);
    });
  }

  void _xrexOpenCoverTemplatePicker() {
    setState(() => _selectedIndex = 0); // Store
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _myVitrinKey.currentState?.openCoverTemplatePicker();
    });
  }

  Future<void> _markXrexShared() async {
    await ChatbotService().markVitrinShared();
    if (!mounted) return;
    setState(() => _xrexHasShared = true);
  }

  Future<void> _dismissXrexRecommendation(String recommendationId) async {
    await ChatbotService().dismissRecommendation(recommendationId);
    if (!mounted) return;
    setState(() => _dismissedXrexRecommendationId = recommendationId);
  }

  void _handleXrexAction(XrexAction action) {
    switch (action) {
      case XrexAction.openVitrim:
        _xrexNavigateToVitrim();
        break;
      case XrexAction.copyLink:
        _xrexCopyLink();
        break;
      case XrexAction.shareWhatsapp:
        _xrexShareWhatsapp();
        break;
      case XrexAction.showQr:
        _xrexShowQr();
        break;
      case XrexAction.openExplore:
        _openExplore();
        break;
      case XrexAction.scrollToCover:
      case XrexAction.scrollToGallery:
      case XrexAction.scrollToName:
      case XrexAction.scrollToWhatsapp:
      case XrexAction.scrollToAddress:
      case XrexAction.scrollToLegal:
      case XrexAction.scrollToDesc:
      case XrexAction.scrollToProducts:
      case XrexAction.scrollToCategory:
      case XrexAction.openAutoFillDialog:
      case XrexAction.applyCategoryTemplate:
        _xrexScrollToAction(action);
        break;
      case XrexAction.openCoverTemplatePicker:
        _xrexOpenCoverTemplatePicker();
        break;
      case XrexAction.none:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _isAdmin;

    final pages = [
      MyVitrinScreen(
        key: _myVitrinKey,
        initialName: widget.initialVitrinName,
        onPublished: _handleVitrinPublished,
        onOpenExplore: _openExplore,
      ),
      ExploreScreen(key: ValueKey(_exploreRefreshKey)),
      XrexScreen(
        snapshot: _xrexSnapshot,
        hasShared: _xrexHasShared,
        dismissedRecommendationId: _dismissedXrexRecommendationId,
        onAction: _handleXrexAction,
        onDismissRecommendation: _dismissXrexRecommendation,
        onCopyPromotionText: _xrexCopyPromotionText,
        onSharePromotionText: _xrexSharePromotionText,
      ),
      const ProfileScreen(),
      if (isAdmin) const BlogModerationScreen(),
    ];

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
        label: 'X-rex',
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

    return Scaffold(
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          IndexedStack(index: _selectedIndex, children: pages),
          // Xrex: Sağ alt köşede yüzen robot rozeti (sadece X-rex tabında değilken gösterilir)
          if (_selectedIndex != 2)
            Positioned(
              right: 0,
              bottom: 0,
              child: SafeArea(
                minimum: const EdgeInsets.only(right: 16, bottom: 16),
                child: ChatbotBadge(
                  snapshot: _xrexSnapshot,
                  chatHistory: _xrexChatMessages,
                  onNavigateToVitrim: _xrexNavigateToVitrim,
                  onNavigateToExplore: _openExplore,
                  onCopyLink: _xrexCopyLink,
                  onShowQr: _xrexShowQr,
                  onShareWhatsapp: _xrexShareWhatsapp,
                  onScrollToAction: _xrexScrollToAction,
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
              if (index == 2) _loadXrexSnapshot();
            },
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: destinations,
            height: 65,
          ),
        ),
      ),
    );
  }
}

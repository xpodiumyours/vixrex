import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:vixrex/models/chat_message.dart';
import 'package:vixrex/services/auth_service.dart';
import 'package:vixrex/services/chatbot_service.dart';
import 'package:vixrex/screens/blog_moderation_screen.dart';
import 'package:vixrex/screens/explore_screen.dart';
import 'package:vixrex/screens/my_vitrin_screen.dart';
import 'package:vixrex/screens/vixrex_screen.dart';
import 'package:vixrex/screens/profile_screen.dart';
import 'package:vixrex/services/store_local_storage_service.dart';
import 'package:vixrex/services/vixrex_profile_snapshot.dart';
import 'package:vixrex/services/vixrex_promotion_service.dart';
import 'package:vixrex/widgets/chatbot_badge.dart';
import 'package:vixrex/theme/app_colors.dart';

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
  final List<ChatMessage> _vixrexChatMessages = [];

  // ── VixRex Snapshot ─────────────────────────────────────────────────────────
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
    // Safely map initialIndex:
    // Old 0 (Explore) -> New 1 (Discover)
    // Old 1 (MyVitrin) -> New 0 (Store)
    // Old 2 (Moderation) -> New 4 (Moderasyon)
    if (widget.initialIndex == 0) {
      _selectedIndex = 1;
    } else if (widget.initialIndex == 1) {
      _selectedIndex = 0;
    } else if (widget.initialIndex == 2 && _isAdmin) {
      _selectedIndex = 4;
    } else {
      _selectedIndex = 0; // Default to Store
    }
    _loadVixRexSnapshot();
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
    setState(() {
      _selectedIndex = 1; // Discover
      _exploreRefreshKey++;
    });
  }

  /// [İyileştirme #3] Vitrin yayınlandığında snapshot otomatik yenilenir.
  void _handleVitrinPublished() {
    setState(() => _exploreRefreshKey++);
    _loadVixRexSnapshot(); // ← Snapshot anında güncellenir
  }

  // ── VixRex Action Callbacks ─────────────────────────────────────────────────

  void _vixrexNavigateToVitrim() {
    setState(() => _selectedIndex = 0); // Store
  }

  void _vixrexCopyLink() {
    final link = _publishedInfo?.publicLink;
    if (link != null && link.isNotEmpty) {
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
    final link = _publishedInfo?.publicLink;
    if (link == null || link.isEmpty) return;

    final snapshot = _vixrexSnapshot;
    final message = snapshot == null
        ? 'Merhaba! Dijital vitrinimi incelemek için bağlantıyı kullanabilirsiniz: $link'
        : VixRexPromotionService.draftsFor(snapshot)[1].text;
    await _vixrexSharePromotionText(message);
  }

  void _vixrexCopyPromotionText(String text) {
    if (text.trim().isEmpty) return;
    Clipboard.setData(ClipboardData(text: text.trim()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tanıtım metni panoya kopyalandı!'),
        duration: Duration(seconds: 2),
      ),
    );
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

  void _handleVixRexAction(VixRexAction action) {
    switch (action) {
      case VixRexAction.openVitrim:
        _vixrexNavigateToVitrim();
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
      case VixRexAction.scrollToCover:
      case VixRexAction.scrollToGallery:
      case VixRexAction.scrollToName:
      case VixRexAction.scrollToWhatsapp:
      case VixRexAction.scrollToAddress:
      case VixRexAction.scrollToLegal:
      case VixRexAction.scrollToDesc:
      case VixRexAction.scrollToProducts:
      case VixRexAction.scrollToCategory:
        _vixrexScrollToAction(action);
        break;
      case VixRexAction.openCoverTemplatePicker:
        _vixrexOpenCoverTemplatePicker();
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
        onPublished: _handleVitrinPublished,
        onOpenExplore: _openExplore,
      ),
      ExploreScreen(key: ValueKey(_exploreRefreshKey)),
      VixRexScreen(
        snapshot: _vixrexSnapshot,
        hasShared: _vixrexHasShared,
        dismissedRecommendationId: _dismissedVixRexRecommendationId,
        onAction: _handleVixRexAction,
        onDismissRecommendation: _dismissVixRexRecommendation,
        onCopyPromotionText: _vixrexCopyPromotionText,
        onSharePromotionText: _vixrexSharePromotionText,
      ),
      const ProfileScreen(),
      if (isAdmin) const BlogModerationScreen(),
    ];

    // Masaüstü için sidebar menü öğeleri
    final sidebarItems = [
      _SidebarItem(icon: Icons.storefront_outlined, selectedIcon: Icons.storefront_rounded, label: 'Vitrinim'),
      _SidebarItem(icon: Icons.travel_explore_outlined, selectedIcon: Icons.travel_explore_rounded, label: 'Keşfet'),
      _SidebarItem(icon: Icons.assistant_outlined, selectedIcon: Icons.assistant_rounded, label: 'VixRex'),
      _SidebarItem(icon: Icons.person_outline_rounded, selectedIcon: Icons.person_rounded, label: 'Profil'),
      if (isAdmin) _SidebarItem(icon: Icons.admin_panel_settings_outlined, selectedIcon: Icons.admin_panel_settings_rounded, label: 'Moderasyon'),
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
        label: 'VixRex',
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
                          'VixRex',
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
                  // Menü öğeleri
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
                  IndexedStack(index: _selectedIndex, children: pages),
                  // VixRex robot rozeti
                  if (_selectedIndex != 2)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: SafeArea(
                        minimum: const EdgeInsets.only(right: 16, bottom: 16),
                        child: ChatbotBadge(
                          snapshot: _vixrexSnapshot,
                          chatHistory: _vixrexChatMessages,
                          onNavigateToVitrim: _vixrexNavigateToVitrim,
                          onNavigateToExplore: _openExplore,
                          onCopyLink: _vixrexCopyLink,
                          onShowQr: _vixrexShowQr,
                          onShareWhatsapp: _vixrexShareWhatsapp,
                          onScrollToAction: _vixrexScrollToAction,
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
          IndexedStack(index: _selectedIndex, children: pages),
          // VixRex: Sağ alt köşede yüzen robot rozeti (sadece VixRex tabında değilken gösterilir)
          if (_selectedIndex != 2)
            Positioned(
              right: 0,
              bottom: 0,
              child: SafeArea(
                minimum: const EdgeInsets.only(right: 16, bottom: 16),
                child: ChatbotBadge(
                  snapshot: _vixrexSnapshot,
                  chatHistory: _vixrexChatMessages,
                  onNavigateToVitrim: _vixrexNavigateToVitrim,
                  onNavigateToExplore: _openExplore,
                  onCopyLink: _vixrexCopyLink,
                  onShowQr: _vixrexShowQr,
                  onShareWhatsapp: _vixrexShareWhatsapp,
                  onScrollToAction: _vixrexScrollToAction,
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
        color: isSelected ? AppColors.primary.withAlpha(15) : Colors.transparent,
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
                      color: isSelected ? AppColors.darkText : AppColors.mutedText,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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

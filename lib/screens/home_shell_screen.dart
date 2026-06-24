import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:vitrinx/models/chat_message.dart';
import 'package:vitrinx/screens/blog_moderation_screen.dart';
import 'package:vitrinx/screens/explore_screen.dart';
import 'package:vitrinx/screens/my_vitrin_screen.dart';
import 'package:vitrinx/services/store_local_storage_service.dart';
import 'package:vitrinx/services/xrex_profile_snapshot.dart';
import 'package:vitrinx/widgets/chatbot_overlay.dart';

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

  // ── Xrex Snapshot ─────────────────────────────────────────────────────────
  XrexProfileSnapshot? _xrexSnapshot;
  PublishedVitrinInfo? _publishedInfo;
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
    _selectedIndex = widget.initialIndex.clamp(0, _isAdmin ? 2 : 1);
    _loadXrexSnapshot();
  }

  // ── Snapshot Yükleme ──────────────────────────────────────────────────────

  Future<void> _loadXrexSnapshot() async {
    final snapshot = await _snapshotLoader.load();
    final storage = const StoreLocalStorageService();
    final publishedInfo = await storage.loadPublishedVitrinInfo();
    if (mounted) {
      setState(() {
        _xrexSnapshot = snapshot;
        _publishedInfo = publishedInfo;
      });
    }
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void _openExplore() {
    setState(() {
      _selectedIndex = 0;
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
    setState(() => _selectedIndex = 1);
  }

  void _xrexCopyLink() {
    final link = _publishedInfo?.publicLink;
    if (link != null && link.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: link));
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

    final storeName = _xrexSnapshot?.nameCompleted == true ? 'vitrinimi' : 'dijital vitrinimi';
    final message = 'Merhaba! Tasarladığım $storeName incelemek için linke tıklayabilirsiniz: $link';
    final whatsappUrl = Uri.parse('https://api.whatsapp.com/send?text=${Uri.encodeComponent(message)}');

    try {
      final launched = await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        Clipboard.setData(ClipboardData(text: link));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WhatsApp açılamadı, link panoya kopyalandı!'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        Clipboard.setData(ClipboardData(text: link));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hata oluştu, link panoya kopyalandı!'),
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
          content: Text('QR kodunu göstermek için önce vitrininizi yayınlamalısınız!'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
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
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Vitrin QR Kodunuz',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Müşterileriniz bu QR kodu okutarak vitrininize hızlıca ulaşabilir.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
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
                    foregroundColor: const Color(0xFF4F46E5),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
    setState(() => _selectedIndex = 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _myVitrinKey.currentState?.scrollToXrexAction(action);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _isAdmin;

    final pages = [
      ExploreScreen(key: ValueKey(_exploreRefreshKey)),
      MyVitrinScreen(
        key: _myVitrinKey,
        initialName: widget.initialVitrinName,
        onPublished: _handleVitrinPublished,
        onOpenExplore: _openExplore,
      ),
      if (isAdmin) const BlogModerationScreen(),
    ];

    final destinations = [
      const NavigationDestination(
        icon: Icon(Icons.travel_explore_outlined),
        selectedIcon: Icon(Icons.travel_explore_rounded),
        label: 'Keşfet',
      ),
      const NavigationDestination(
        icon: Icon(Icons.storefront_outlined),
        selectedIcon: Icon(Icons.storefront_rounded),
        label: 'Vitrinim',
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
          // Xrex: Sol kenarda yüzen robot rozeti — snapshot + callback'lerle
          Positioned(
            left: 4,
            top: 0,
            bottom: 0,
            child: Center(
              child: ChatbotBadge(
                snapshot: _xrexSnapshot,
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: destinations,
      ),
    );
  }
}

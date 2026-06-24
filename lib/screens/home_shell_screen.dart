import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  void _xrexShareWhatsapp() {
    final link = _publishedInfo?.publicLink;
    if (link == null || link.isEmpty) return;
    // url_launcher bağımlılığı olmadığından linki kopyalayıp bildirim göster
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Paylaşmak için link kopyalandı: $link'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _xrexShowQr() {
    // QR gösterimi için MyVitrinScreen'deki mevcut QR bottom sheet
    // v1: Vitrinim sekmesine yönlendir (QR orada mevcut)
    setState(() => _selectedIndex = 1);
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _isAdmin;

    final pages = [
      ExploreScreen(key: ValueKey(_exploreRefreshKey)),
      MyVitrinScreen(
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

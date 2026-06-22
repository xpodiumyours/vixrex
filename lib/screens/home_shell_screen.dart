import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitrinx/screens/blog_moderation_screen.dart';
import 'package:vitrinx/screens/explore_screen.dart';
import 'package:vitrinx/screens/my_vitrin_screen.dart';

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
  }

  void _openExplore() {
    setState(() {
      _selectedIndex = 0;
      _exploreRefreshKey++;
    });
  }

  void _handleVitrinPublished() {
    setState(() => _exploreRefreshKey++);
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
      body: IndexedStack(index: _selectedIndex, children: pages),
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

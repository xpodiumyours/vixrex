import 'package:flutter/material.dart';
import 'package:vitrinx/screens/explore_screen.dart';
import 'package:vitrinx/screens/my_vitrin_screen.dart';

class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  int _selectedIndex = 1;
  int _exploreRefreshKey = 0;

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
    final pages = [
      ExploreScreen(key: ValueKey(_exploreRefreshKey)),
      MyVitrinScreen(
        onPublished: _handleVitrinPublished,
        onOpenExplore: _openExplore,
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
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.travel_explore_outlined),
            selectedIcon: Icon(Icons.travel_explore_rounded),
            label: 'Keşfet',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront_rounded),
            label: 'Vitrinim',
          ),
        ],
      ),
    );
  }
}

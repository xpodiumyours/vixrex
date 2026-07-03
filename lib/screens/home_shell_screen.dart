import 'package:flutter/material.dart';
import 'package:vitrinx/config/chatbot_config.dart';
import 'package:vitrinx/controllers/global_controller.dart';
import 'package:vitrinx/presentation/screens/landing_screen.dart';
import 'package:vitrinx/presentation/screens/my_vitrin/my_vitrin_screen.dart';
import 'package:vitrinx/presentation/screens/explore_screen.dart';
import 'package:vitrinx/presentation/screens/profile_screen.dart';
import 'package:vitrinx/presentation/screens/appointment_tracker_screen.dart';
import 'package:vitrinx/presentation/screens/xrex_screen.dart';
import 'package:vitrinx/theme/app_colors.dart';
import 'package:vitrinx/widgets/chatbot_overlay.dart';
import 'package:get/get.dart';

class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    LandingScreen(),
    MyVitrinScreen(),
    ExploreScreen(),
    AppointmentTrackerScreen(),
    ProfileScreen(),
  ];

  void _handleXrexAction(XrexAction action) {
    switch (action.type) {
      case XrexActionType.navigate:
        final tabIndex = action.payload['tabIndex'] as int?;
        if (tabIndex != null) {
          setState(() => _currentIndex = tabIndex);
        }
        break;
      case XrexActionType.openChat:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const XrexScreen()),
        );
        break;
      case XrexActionType.scrollToCategory:
        setState(() => _currentIndex = 1);
        Future.delayed(const Duration(milliseconds: 300), () {
          final state = context.findAncestorStateOfType<_HomeShellScreenState>();
          if (state != null) {
            // MyVitrinScreen will handle the scroll via notification
          }
        });
        break;
      case XrexActionType.openAutoFillDialog:
        setState(() => _currentIndex = 1);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<GlobalController>(
      builder: (globalCtrl) {
        return Scaffold(
          body: _screens[_currentIndex],
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              border: Border(
                top: BorderSide(color: AppColors.cardBorderDark),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(
                      icon: Icons.home_rounded,
                      label: 'Ana Sayfa',
                      isActive: _currentIndex == 0,
                      onTap: () => setState(() => _currentIndex = 0),
                    ),
                    _NavItem(
                      icon: Icons.storefront_rounded,
                      label: 'Vitrinim',
                      isActive: _currentIndex == 1,
                      onTap: () => setState(() => _currentIndex = 1),
                    ),
                    _NavItem(
                      icon: Icons.explore_rounded,
                      label: 'Keşfet',
                      isActive: _currentIndex == 2,
                      onTap: () => setState(() => _currentIndex = 2),
                    ),
                    _NavItem(
                      icon: Icons.calendar_today_rounded,
                      label: 'Randevular',
                      isActive: _currentIndex == 3,
                      onTap: () => setState(() => _currentIndex = 3),
                    ),
                    _NavItem(
                      icon: Icons.person_rounded,
                      label: 'Profil',
                      isActive: _currentIndex == 4,
                      onTap: () => setState(() => _currentIndex = 4),
                    ),
                  ],
                ),
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.small(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const XrexScreen()),
              );
            },
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.black),
          ),
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.primary : AppColors.mutedText,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.primary : AppColors.mutedText,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

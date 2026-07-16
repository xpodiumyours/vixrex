import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/models/landing_demo_profile.dart';
import 'package:vixrex/screens/vixrex_onboarding_chat_screen.dart';
import 'package:vixrex/widgets/landing/phone_mockup.dart';

class LandingHeroMockup extends StatelessWidget {
  final AnimationController animController;
  final int activeProfileIndex;
  final List<HeroDemoProfile> heroDemoProfiles;
  final VoidCallback onNavigateToPreview;
  final bool isMockupChatOpen;
  final VoidCallback onCloseMockupChat;

  const LandingHeroMockup({
    super.key,
    required this.animController,
    required this.activeProfileIndex,
    required this.heroDemoProfiles,
    required this.onNavigateToPreview,
    required this.isMockupChatOpen,
    required this.onCloseMockupChat,
  });

  static const Color brandBlue = AppColors.primary;

  @override
  Widget build(BuildContext context) {
    final activeProfile = heroDemoProfiles[activeProfileIndex];
    final activeIndex = activeProfileIndex;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 360;
        return Column(
          children: [
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 520),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final slide = Tween<Offset>(
                        begin: const Offset(0.06, 0),
                        end: Offset.zero,
                      ).animate(animation);
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(position: slide, child: child),
                      );
                    },
                    child: SizedBox(
                      width: 320,
                      height: 640,
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: onNavigateToPreview,
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: PhoneMockup(
                                key: ValueKey(activeProfile.name),
                                profile: activeProfile,
                                onPreviewTap: onNavigateToPreview,
                              ),
                            ),
                          ),
                          if (isMockupChatOpen)
                            Positioned.fill(
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(36),
                                  child: VixRexOnboardingChatScreen(
                                    compact: true,
                                    onClose: onCloseMockupChat,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (!isMockupChatOpen)
                    Positioned(
                      right: isNarrow ? -14 : -40,
                      top:
                          100 +
                          math.sin((animController.value + 0.3) * math.pi * 2) *
                              10,
                      child: _buildFloatingBadge(
                        activeProfile.badgeIcon,
                        activeProfile.accentColor,
                        activeProfile.badgeText,
                      ),
                    ),
                  if (!isMockupChatOpen)
                    Positioned(
                      left: isNarrow ? -12 : -30,
                      bottom:
                          120 +
                          math.sin((animController.value + 0.6) * math.pi * 2) *
                              10,
                      child: _buildFloatingBadge(
                        activeProfile.secondaryBadgeIcon,
                        activeProfile.secondaryBadgeColor,
                        activeProfile.secondaryBadgeText,
                      ),
                    ),
                ],
              ),
            ),
            if (!isMockupChatOpen) ...[
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(heroDemoProfiles.length, (index) {
                  final isActive = index == activeIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive ? brandBlue : AppColors.border,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  );
                }),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildFloatingBadge(IconData icon, Color color, String text) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.28),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 15),
              ),
              const SizedBox(width: 8),
              Text(
                text,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: AppColors.darkText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitrinx/theme/app_colors.dart';
import 'package:vitrinx/models/landing_demo_profile.dart';
import 'package:vitrinx/services/auth_service.dart';
import 'package:vitrinx/config/app_router.dart';
import 'package:vitrinx/widgets/landing/phone_mockup.dart';

class LandingHeroSection extends StatelessWidget {
  final AnimationController animController;
  final int activeProfileIndex;
  final bool hasSavedVitrin;
  final bool isCheckingSavedVitrin;
  final TextEditingController storeNameController;
  final List<HeroDemoProfile> heroDemoProfiles;
  final VoidCallback onNavigateToExploreApp;
  final VoidCallback onNavigateToSavedVitrin;
  final VoidCallback onNavigateToPreview;
  final VoidCallback onNavigateToEditor;
  final VoidCallback onStateChanged;

  const LandingHeroSection({
    super.key,
    required this.animController,
    required this.activeProfileIndex,
    required this.hasSavedVitrin,
    required this.isCheckingSavedVitrin,
    required this.storeNameController,
    required this.heroDemoProfiles,
    required this.onNavigateToExploreApp,
    required this.onNavigateToSavedVitrin,
    required this.onNavigateToPreview,
    required this.onNavigateToEditor,
    required this.onStateChanged,
  });

  static const Color brandBlue = AppColors.primary;
  static const Color mint = AppColors.landingMint;
  static const Color blueAccent = AppColors.landingBlueAccent;
  static const Color pinkAccent = AppColors.landingPinkAccent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.bgEditor, AppColors.bgLight],
        ),
      ),
      child: Stack(
        children: [
          // Ambient Mesh Glows
          Positioned.fill(
            child: AnimatedBuilder(
              animation: animController,
              builder: (context, child) {
                final sinVal = math.sin(animController.value * math.pi * 2);
                final cosVal = math.cos(animController.value * math.pi * 2);
                return Stack(
                  children: [
                    Positioned(
                      top: 100 + sinVal * 30,
                      left: -100 + cosVal * 40,
                      child: _buildMeshGlow(
                        brandBlue.withValues(alpha: 0.3),
                        300,
                      ),
                    ),
                    Positioned(
                      bottom: 50 + cosVal * 30,
                      right: -50 + sinVal * 40,
                      child: _buildMeshGlow(
                        blueAccent.withValues(alpha: 0.25),
                        400,
                      ),
                    ),
                    Positioned(
                      top: 200 - sinVal * 20,
                      right: 150 + cosVal * 20,
                      child: _buildMeshGlow(
                        pinkAccent.withValues(alpha: 0.2),
                        250,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 900;
                return Column(
                  children: [
                    _buildTopNavBar(context, isDesktop),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: 24,
                            right: 24,
                            top: isDesktop ? 40 : 20,
                            bottom: isDesktop ? 100 : 50,
                          ),
                          child:
                              isDesktop
                                  ? Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        flex: 5,
                                        child: _buildHeroContent(
                                          context: context,
                                          isDesktop: true,
                                        ),
                                      ),
                                      const SizedBox(width: 40),
                                      Expanded(
                                        flex: 5,
                                        child: _buildHeroMockup(),
                                      ),
                                    ],
                                  )
                                  : Column(
                                    children: [
                                      _buildHeroContent(
                                        context: context,
                                        isDesktop: false,
                                      ),
                                      const SizedBox(
                                        height: AppColors.spacing40,
                                      ),
                                      _buildHeroMockup(),
                                    ],
                                  ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopNavBar(BuildContext context, bool isDesktop) {
    final isUserLoggedIn = _isUserLoggedIn();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? AppColors.spacing40 : AppColors.spacing20,
        vertical: AppColors.spacing16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: brandBlue.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: brandBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'VitrinX',
                style: TextStyle(
                  color: AppColors.darkText,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          Row(
            children: [
              if (isDesktop)
                ElevatedButton.icon(
                  onPressed: onNavigateToExploreApp,
                  icon: const Icon(Icons.explore_rounded, size: 16),
                  label: const Text(
                    'Vitrinleri Keşfet',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceSoft,
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.45),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                )
              else
                IconButton(
                  onPressed: onNavigateToExploreApp,
                  icon: const Icon(Icons.explore_rounded, size: 18),
                  color: AppColors.darkText,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surfaceSoft,
                    padding: const EdgeInsets.all(10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
              const SizedBox(width: 10),
              if (isUserLoggedIn) ...[
                if (isDesktop)
                  TextButton.icon(
                    onPressed: () async {
                      await const AuthService().signOut();
                      onStateChanged();
                    },
                    icon: const Icon(
                      Icons.logout_rounded,
                      size: 16,
                      color: AppColors.darkText,
                    ),
                    label: const Text(
                      'Çıkış Yap',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: AppColors.darkText,
                      ),
                    ),
                  )
                else
                  IconButton(
                    onPressed: () async {
                      await const AuthService().signOut();
                      onStateChanged();
                    },
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    color: AppColors.darkText,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surfaceSoft,
                      padding: const EdgeInsets.all(10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
              ] else ...[
                if (isDesktop)
                  ElevatedButton.icon(
                    onPressed: () {
                      AppRouter.navigateToAuth(context).then((_) {
                        onStateChanged();
                      });
                    },
                    icon: const Icon(Icons.login_rounded, size: 16),
                    label: const Text(
                      'Giriş Yap',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  )
                else
                  IconButton(
                    onPressed: () {
                      AppRouter.navigateToAuth(context).then((_) {
                        onStateChanged();
                      });
                    },
                    icon: const Icon(Icons.login_rounded, size: 18),
                    color: Colors.white,
                    style: IconButton.styleFrom(
                      backgroundColor: brandBlue,
                      padding: const EdgeInsets.all(10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroContent({
    required BuildContext context,
    required bool isDesktop,
  }) {
    return Column(
      crossAxisAlignment:
          isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        // Title block
        Column(
          crossAxisAlignment:
              isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            const Text(
              'İşletmeniz için',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: AppColors.darkText,
                height: 1.1,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Paylaşılabilir Dijital Vitrin',
              textAlign: isDesktop ? TextAlign.left : TextAlign.center,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: brandBlue,
                height: 1.15,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Müşterilerinizin aradığı her şeyi tek bir linkte sunun. WhatsApp iletişimi, konum tarifi, sosyal ağlar, fotoğraflar ve ürünler tek ekranda.',
          textAlign: isDesktop ? TextAlign.left : TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.darkTextAlt,
            height: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 32),
        // Interactive Setup Form
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.16),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Vitrin linkinizi belirleyin',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              'vitrinx.com/',
                              style: TextStyle(
                                color: AppColors.mutedText,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: storeNameController,
                              style: const TextStyle(
                                color: AppColors.darkText,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'butiginiz',
                                hintStyle: TextStyle(
                                  color: AppColors.mutedText,
                                  fontWeight: FontWeight.normal,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (hasSavedVitrin && !isCheckingSavedVitrin) ...[
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: onNavigateToSavedVitrin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mint,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit_document, size: 18),
                        SizedBox(width: 10),
                        Text(
                          'Kayıtlı Vitrinimi Düzenle',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: onNavigateToExploreApp,
                    child: const Text(
                      'Farklı vitrinleri inceleyin',
                      style: TextStyle(
                        color: brandBlue,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: onNavigateToEditor,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Vitrin Oluştur',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _buildSecondaryActions(isDesktop: isDesktop),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryActions({required bool isDesktop}) {
    final canOpenSavedVitrin = hasSavedVitrin && !isCheckingSavedVitrin;

    final buttons = <Widget>[
      if (canOpenSavedVitrin)
        ElevatedButton.icon(
          onPressed: onNavigateToSavedVitrin,
          icon: const Icon(Icons.edit_rounded, size: 18),
          label: const Text(
            'VitrinX Düzenle',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: brandBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      OutlinedButton.icon(
        onPressed: onNavigateToExploreApp,
        icon: const Icon(
          Icons.explore_rounded,
          size: 18,
          color: AppColors.darkText,
        ),
        label: const Text(
          'Vitrinleri Keşfet',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            color: AppColors.darkText,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.darkTextAlt, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    ];

    return isDesktop
        ? Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.start,
            children: buttons,
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children:
                buttons.expand((b) => [b, const SizedBox(height: 12)]).toList()
                  ..removeLast(),
          );
  }

  Widget _buildHeroMockup() {
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
                    child: GestureDetector(
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
                  ),
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

  Widget _buildMeshGlow(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }

  bool _isUserLoggedIn() {
    try {
      return Supabase.instance.client.auth.currentUser != null;
    } catch (_) {
      return false;
    }
  }
}

import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitrinx/config/legal_config.dart';
import 'package:vitrinx/screens/preview_screen.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/services/local_storage_keys.dart';
import 'package:vitrinx/services/auth_service.dart';
import 'package:vitrinx/theme/app_colors.dart';
import 'package:vitrinx/widgets/chatbot_overlay.dart';
import 'package:vitrinx/config/app_router.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  int _activeProfileIndex = 0;
  bool _hasSavedVitrin = false;
  bool _isCheckingSavedVitrin = true;
  final TextEditingController _storeNameController = TextEditingController();

  // Modern Color Palette
  static const Color brandOrange = AppColors.brandOrange;
  static const Color darkAccent = AppColors.darkTextAlt;
  static const Color lightBg = AppColors.bgLight;
  static const Color mint = AppColors.success;
  static const Color blueAccent = AppColors.secondary;
  static const Color pinkAccent = AppColors.pinkAccent;

  static const List<_HeroDemoProfile> _heroDemoProfiles = [
    _HeroDemoProfile(
      name: 'Aymira Giyim',
      category: 'KadÄ±n giyim / butik',
      status: 'AÃ§Ä±k',
      description: 'Yeni sezon reyonlarÄ± ve maÄŸaza fotoÄŸraflarÄ± tek vitrinde.',
      icon: Icons.checkroom_rounded,
      accentColor: Color(0xFFFF5A1F),
      badgeIcon: Icons.photo_library_rounded,
      badgeText: 'Galeri',
      secondaryBadgeIcon: Icons.qr_code_2_rounded,
      secondaryBadgeText: 'QR kod',
      actions: [
        _HeroDemoAction(Icons.chat_bubble_rounded, Color(0xFF25D366)),
        _HeroDemoAction(Icons.camera_alt_rounded, Color(0xFFE1306C)),
      ],
      links: [
        _HeroDemoLink(
          'Vitrin galerisi',
          'Raf ve reyon fotoÄŸraflarÄ±',
          Icons.photo_library_rounded,
          Color(0xFFFF5A1F),
        ),
        _HeroDemoLink(
          'Trendyol',
          'MaÄŸazayÄ± ziyaret edin',
          Icons.shopping_bag_rounded,
          Color(0xFFF27A1A),
        ),
      ],
      coverImageUrl:
          'https://images.unsplash.com/photo-1441984904996-e0b6ba687e04?auto=format&fit=crop&w=400&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1567401893414-76b7b1e5a7a5?auto=format&fit=crop&w=300&q=80',
        'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?auto=format&fit=crop&w=300&q=80',
        'https://images.unsplash.com/photo-1445205170230-053b83016050?auto=format&fit=crop&w=300&q=80',
      ],
    ),
    _HeroDemoProfile(
      name: 'Lezzet DuraÄŸÄ±',
      category: 'Kafe / restoran',
      status: 'AÃ§Ä±k',
      description: 'MenÃ¼, konum ve WhatsApp sipariÅŸ bilgileri tek ekranda.',
      icon: Icons.restaurant_menu_rounded,
      accentColor: Color(0xFFEA580C),
      badgeIcon: Icons.menu_book_rounded,
      badgeText: 'MenÃ¼',
      secondaryBadgeIcon: Icons.directions_rounded,
      secondaryBadgeText: 'Yol tarifi',
      actions: [
        _HeroDemoAction(Icons.chat_bubble_rounded, Color(0xFF25D366)),
        _HeroDemoAction(Icons.location_on_rounded, Color(0xFFEF4444)),
      ],
      links: [
        _HeroDemoLink(
          'GÃ¼nÃ¼n menÃ¼sÃ¼',
          'SÄ±cak yemek ve tatlÄ±lar',
          Icons.local_dining_rounded,
          Color(0xFFEA580C),
        ),
        _HeroDemoLink(
          'Paket servis',
          'WhatsApp ile sipariÅŸ',
          Icons.delivery_dining_rounded,
          Color(0xFF10B981),
        ),
      ],
      coverImageUrl:
          'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&w=400&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=300&q=80',
        'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=300&q=80',
        'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?auto=format&fit=crop&w=300&q=80',
      ],
    ),
    _HeroDemoProfile(
      name: 'Nova KuafÃ¶r',
      category: 'KuafÃ¶r / gÃ¼zellik',
      status: 'AÃ§Ä±k',
      description: 'Randevu, hizmetler ve sosyal medya baÄŸlantÄ±larÄ± hazÄ±r.',
      icon: Icons.content_cut_rounded,
      accentColor: Color(0xFFDB2777),
      badgeIcon: Icons.calendar_month_rounded,
      badgeText: 'Randevu',
      secondaryBadgeIcon: Icons.camera_alt_rounded,
      secondaryBadgeText: 'Instagram',
      actions: [
        _HeroDemoAction(Icons.chat_bubble_rounded, Color(0xFF25D366)),
        _HeroDemoAction(Icons.camera_alt_rounded, Color(0xFFE1306C)),
      ],
      links: [
        _HeroDemoLink(
          'Hizmetler',
          'Kesim, boya ve bakÄ±m',
          Icons.spa_rounded,
          Color(0xFFDB2777),
        ),
        _HeroDemoLink(
          'Randevu al',
          'WhatsApp ile hÄ±zlÄ± iletiÅŸim',
          Icons.event_available_rounded,
          Color(0xFF10B981),
        ),
      ],
      coverImageUrl:
          'https://images.unsplash.com/photo-1560066984-138dadb4c035?auto=format&fit=crop&w=400&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?auto=format&fit=crop&w=300&q=80',
        'https://images.unsplash.com/photo-1595476108010-b4d1f102b1b1?auto=format&fit=crop&w=300&q=80',
        'https://images.unsplash.com/photo-1634449571010-02389ed0f9b0?auto=format&fit=crop&w=300&q=80',
      ],
    ),
    _HeroDemoProfile(
      name: 'TeknoFix',
      category: 'Telefon teknik servis',
      status: 'AÃ§Ä±k',
      description: 'Servis talebi, adres ve gÃ¼venilir iletiÅŸim tek vitrinde.',
      icon: Icons.build_circle_rounded,
      accentColor: Color(0xFF2563EB),
      badgeIcon: Icons.chat_bubble_rounded,
      badgeText: 'WhatsApp',
      secondaryBadgeIcon: Icons.location_on_rounded,
      secondaryBadgeText: 'Konum',
      actions: [
        _HeroDemoAction(Icons.chat_bubble_rounded, Color(0xFF25D366)),
        _HeroDemoAction(Icons.phone_android_rounded, Color(0xFF2563EB)),
      ],
      links: [
        _HeroDemoLink(
          'Servis kaydÄ±',
          'Ekran, batarya ve bakÄ±m',
          Icons.construction_rounded,
          Color(0xFF2563EB),
        ),
        _HeroDemoLink(
          'Google yorumlarÄ±',
          'MÃ¼ÅŸteri gÃ¼veni',
          Icons.verified_rounded,
          Color(0xFF6366F1),
        ),
      ],
      coverImageUrl:
          'https://images.unsplash.com/photo-1512499617640-c74ae3a79d37?auto=format&fit=crop&w=400&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1601784551446-20c9e07cdbdb?auto=format&fit=crop&w=300&q=80',
        'https://images.unsplash.com/photo-1545259741-2ea3ebf61fa3?auto=format&fit=crop&w=300&q=80',
        'https://images.unsplash.com/photo-1585771724684-38269d6639fd?auto=format&fit=crop&w=300&q=80',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
    _animController.addListener(() {
      final newIndex = math.min(
        (_animController.value * _heroDemoProfiles.length).floor(),
        _heroDemoProfiles.length - 1,
      );
      if (newIndex != _activeProfileIndex) {
        setState(() => _activeProfileIndex = newIndex);
      }
    });
    _loadSavedVitrinState();
  }

  @override
  void dispose() {
    _animController.dispose();
    _storeNameController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedVitrinState() async {
    try {
      final authService = const AuthService();
      User? currentUser;
      try {
        currentUser = authService.currentUser;
      } catch (_) {
        // Supabase not initialized (e.g. in tests)
      }
      final prefs = await SharedPreferences.getInstance();

      if (currentUser != null) {
        final store = await authService.getStoreForCurrentUser();
        if (store != null) {
          if (!mounted) return;
          if (store.isStore) {
            // isStore: true olan hesaplar iÃ§in Store editor ekranÄ±
            // planlanmaktadÄ±r (StoreSetupScreen kaldÄ±rÄ±ldÄ±). Åimdilik
            // token ve veri Ã¶nbelleÄŸe alÄ±nÄ±p LandingScreen'de bÄ±rakÄ±lÄ±r.
            await prefs.setString(
              LocalStorageKeys.storeData,
              jsonEncode(store.toJson()),
            );

            if (!mounted) return;
            final dbStore =
                await Supabase.instance.client
                    .from('stores')
                    .select('edit_token')
                    .eq('user_id', currentUser.id)
                    .maybeSingle();

            if (!mounted) return;
            if (dbStore != null && dbStore['edit_token'] != null) {
              await prefs.setString(
                LocalStorageKeys.storeEditToken,
                dbStore['edit_token'] as String,
              );
            }

            if (!mounted) return;
            setState(() {
              _hasSavedVitrin = false;
              _isCheckingSavedVitrin = false;
            });
            return;
          } else {
            await prefs.setString(
              LocalStorageKeys.vitrinData,
              jsonEncode(store.toJson()),
            );

            if (!mounted) return;
            final dbStore =
                await Supabase.instance.client
                    .from('stores')
                    .select('edit_token')
                    .eq('user_id', currentUser.id)
                    .maybeSingle();

            if (!mounted) return;
            if (dbStore != null && dbStore['edit_token'] != null) {
              await prefs.setString(
                LocalStorageKeys.vitrinEditToken,
                dbStore['edit_token'] as String,
              );
            }

            if (!mounted) return;
            AppRouter.navigateToHomeShell(context, initialIndex: 1);
            return;
          }
        }
      }

      final savedVitrinJson = prefs.getString(LocalStorageKeys.vitrinData);
      var hasSavedVitrin = false;

      final savedVitrin = _readSavedStoreData(savedVitrinJson);
      if (savedVitrin != null && !savedVitrin.isStore) {
        hasSavedVitrin = _hasMeaningfulSavedVitrin(savedVitrin);
      }

      if (!mounted) return;
      setState(() {
        _hasSavedVitrin = hasSavedVitrin;
        _isCheckingSavedVitrin = false;
      });
    } catch (error) {
      debugPrint('Saved vitrin state load error: $error');
      if (!mounted) return;
      setState(() {
        _hasSavedVitrin = false;
        _isCheckingSavedVitrin = false;
      });
    }
  }

  StoreData? _readSavedStoreData(String? rawJson) {
    if (rawJson == null || rawJson.trim().isEmpty) return null;

    final decoded = jsonDecode(rawJson);
    if (decoded is Map<String, dynamic>) {
      return StoreData.fromJson(decoded);
    }
    if (decoded is Map) {
      return StoreData.fromJson(Map<String, dynamic>.from(decoded));
    }
    return null;
  }

  bool get _isUserLoggedIn {
    try {
      return const AuthService().currentUser != null;
    } catch (_) {
      return false;
    }
  }

  bool _hasMeaningfulSavedVitrin(StoreData data) {
    final hasTextContent = [
      data.name,
      data.description,
      data.whatsapp,
      data.instagram,
      data.website,
      data.address,
      data.corporateBio,
      data.referencesLink,
      data.shelfImageUrl,
    ].any((value) => value.trim().isNotEmpty);

    final hasGallery = data.displayGalleryItems.isNotEmpty;
    final hasMarketplace = data.marketplaceLinks.any(
      (link) => link.url.trim().isNotEmpty,
    );

    return hasTextContent || hasGallery || hasMarketplace;
  }

  Future<void> _navigateToEditor() async {
    final name = _storeNameController.text;
    AppRouter.navigateToHomeShell(
      context,
      initialIndex: 1,
      initialVitrinName: name,
    );
  }

  Future<void> _navigateToExploreApp() async {
    AppRouter.navigateToHomeShell(context, initialIndex: 0);
  }

  Future<void> _navigateToSavedVitrin() async {
    if (!_hasSavedVitrin || _isCheckingSavedVitrin) return;
    AppRouter.navigateToHomeShell(context, initialIndex: 1);
  }

  void _navigateToPreview() {
    final activeProfile = _heroDemoProfiles[_activeProfileIndex];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => PreviewScreen(
              storeData: activeProfile.toStoreData(),
              isDemo: true,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: brandOrange,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                _buildHeroSection(context),
                _buildValueBandSection(context),
                _buildFeaturesSection(context),
                _buildComparisonSection(context),
                _buildTrustBandSection(context),
                _buildStepsSection(context),
                _buildBottomCTA(context),
                _buildFooter(),
              ],
            ),
          ),
          // Xrex: SaÄŸ alt kÃ¶ÅŸede yÃ¼zen robot rozeti
          const Positioned(
            right: 16,
            bottom: 16,
            child: ChatbotBadge(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
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
              animation: _animController,
              builder: (context, child) {
                final sinVal = math.sin(_animController.value * math.pi * 2);
                final cosVal = math.cos(_animController.value * math.pi * 2);
                return Stack(
                  children: [
                    Positioned(
                      top: 100 + sinVal * 30,
                      left: -100 + cosVal * 40,
                      child: _buildMeshGlow(
                        brandOrange.withValues(alpha: 0.3),
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
                                      _buildHeroContent(isDesktop: false),
                                      const SizedBox(height: 40),
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
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 40 : 20,
        vertical: 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: brandOrange.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: brandOrange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'VitrinX',
                style: TextStyle(
                  color: darkAccent,
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
                  onPressed: () {
                    _navigateToExploreApp();
                  },
                  icon: const Icon(Icons.explore_rounded, size: 16),
                  label: const Text(
                    'Vitrinleri KeÅŸfet',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkAccent,
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
                    _navigateToExploreApp();
                  },
                  icon: const Icon(Icons.explore_rounded, size: 18),
                  color: darkAccent,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.8),
                    padding: const EdgeInsets.all(10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
              const SizedBox(width: 10),
              if (_isUserLoggedIn) ...[
                if (isDesktop)
                  TextButton.icon(
                    onPressed: () async {
                      await const AuthService().signOut();
                      if (mounted) {
                        setState(() {});
                        _loadSavedVitrinState();
                      }
                    },
                    icon: const Icon(
                      Icons.logout_rounded,
                      size: 16,
                      color: darkAccent,
                    ),
                    label: const Text(
                      'Ã‡Ä±kÄ±ÅŸ Yap',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: darkAccent,
                      ),
                    ),
                  )
                else
                  IconButton(
                    onPressed: () async {
                      await const AuthService().signOut();
                      if (mounted) {
                        setState(() {});
                        _loadSavedVitrinState();
                      }
                    },
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    color: darkAccent,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.8),
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
                        if (mounted) {
                          setState(() {});
                          _loadSavedVitrinState();
                        }
                      });
                    },
                    icon: const Icon(Icons.login_rounded, size: 16),
                    label: const Text(
                      'GiriÅŸ Yap',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandOrange,
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
                        if (mounted) {
                          setState(() {});
                          _loadSavedVitrinState();
                        }
                      });
                    },
                    icon: const Icon(Icons.login_rounded, size: 18),
                    color: Colors.white,
                    style: IconButton.styleFrom(
                      backgroundColor: brandOrange,
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

  Widget _buildMeshGlow(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildHeroContent({required bool isDesktop}) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween<double>(begin: 0, end: 1),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment:
            isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: brandOrange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: brandOrange.withValues(alpha: 0.3)),
            ),
            child: const Text(
              'Ä°ÅLETMENÄ°Z Ä°Ã‡Ä°N DÄ°JÄ°TAL VÄ°TRÄ°N',
              style: TextStyle(
                color: brandOrange,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Ä°ÅŸletmenizin dijital vitrini dakikalar iÃ§inde hazÄ±r',
            textAlign: isDesktop ? TextAlign.left : TextAlign.center,
            style: TextStyle(
              color: darkAccent,
              fontSize: isDesktop ? 62 : 38,
              fontWeight: FontWeight.w900,
              height: 1.1,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Ä°ÅŸletme bilgilerinizi, fotoÄŸraflarÄ±nÄ±zÄ±, Ã¼rÃ¼n ve hizmetlerinizi, adresinizi ve WhatsApp iletiÅŸiminizi tek vitrinde toplayÄ±n. Linkinizi ve QR kodunuzu mÃ¼ÅŸterilerinizle kolayca paylaÅŸÄ±n.',
            textAlign: isDesktop ? TextAlign.left : TextAlign.center,
            style: const TextStyle(
              color: AppColors.mutedText,
              fontSize: 17,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 24),
          _buildSocialProofRow(isDesktop: isDesktop),
          const SizedBox(height: 24),
          _buildClaimBar(isDesktop: isDesktop),
          const SizedBox(height: 32),
          _buildHeroTrustChips(isDesktop: isDesktop),
          const SizedBox(height: 24),
          _buildSecondaryActions(isDesktop: isDesktop),
        ],
      ),
    );
  }

  Widget _buildHeroTrustChips({required bool isDesktop}) {
    final items = [
      'Kredi kartÄ± gerekmez',
      'Teknik bilgi gerekmez',
      'Komisyon yok',
      'Link ve QR hazÄ±r',
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: isDesktop ? WrapAlignment.start : WrapAlignment.center,
      children:
          items.map((text) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded, size: 16, color: mint),
                  const SizedBox(width: 7),
                  Text(
                    text,
                    style: const TextStyle(
                      color: AppColors.darkTextAlt,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildSecondaryActions({required bool isDesktop}) {
    final canOpenSavedVitrin = _hasSavedVitrin && !_isCheckingSavedVitrin;

    final buttons = <Widget>[
      if (canOpenSavedVitrin)
        ElevatedButton.icon(
          onPressed: _navigateToSavedVitrin,
          icon: const Icon(Icons.edit_rounded, size: 18),
          label: const Text(
            'VitrinX DÃ¼zenle',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: brandOrange,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      OutlinedButton.icon(
        onPressed: () {
          _navigateToExploreApp();
        },
        icon: const Icon(Icons.explore_rounded, size: 18, color: darkAccent),
        label: const Text(
          'Vitrinleri KeÅŸfet',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            color: darkAccent,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: darkAccent, width: 1.5),
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

  Widget _buildClaimBar({required bool isDesktop}) {
    final inputWidget = Expanded(
      flex: isDesktop ? 6 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Row(
          children: [
            const Text(
              'vitrinx.app/',
              style: TextStyle(
                color: AppColors.mutedText,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: TextField(
                controller: _storeNameController,
                style: const TextStyle(
                  color: darkAccent,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
                decoration: const InputDecoration(
                  hintText: 'isletmeniz',
                  hintStyle: TextStyle(
                    color: AppColors.mutedText,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final buttonWidget = AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: brandOrange.withValues(
                  alpha:
                      0.24 +
                      0.16 * math.sin(_animController.value * math.pi * 2),
                ),
                blurRadius:
                    16 + 8 * math.sin(_animController.value * math.pi * 2),
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _navigateToEditor,
            style: ElevatedButton.styleFrom(
              backgroundColor: brandOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'VitrinX OluÅŸtur',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
        );
      },
    );

    if (isDesktop) {
      return SizedBox(
        height: 64,
        child: Row(
          children: [inputWidget, const SizedBox(width: 12), buttonWidget],
        ),
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 56, child: Row(children: [inputWidget])),
          const SizedBox(height: 12),
          SizedBox(height: 56, child: buttonWidget),
        ],
      );
    }
  }

  Widget _buildSocialProofRow({required bool isDesktop}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment:
            isDesktop ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1EB),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: const Color(0xFFFFD8C7)),
            ),
            child: const Icon(
              Icons.qr_code_2_rounded,
              color: brandOrange,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  isDesktop
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
              children: [
                const Text(
                  'Tek linkte hazÄ±r dijital vitrin',
                  style: TextStyle(
                    color: darkAccent,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'QR kod ve WhatsApp iletiÅŸimi paylaÅŸmaya hazÄ±r olsun.',
                  style: TextStyle(
                    color: AppColors.mutedText,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroMockup() {
    final isNarrow = MediaQuery.sizeOf(context).width < 520;
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final floatOffset = math.sin(_animController.value * math.pi * 2) * 8;
        final activeIndex = math.min(
          (_animController.value * _heroDemoProfiles.length).floor(),
          _heroDemoProfiles.length - 1,
        );
        final activeProfile = _heroDemoProfiles[activeIndex];
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform(
              transform:
                  Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(-0.1)
                    ..rotateX(0.05)
                    ..translateByDouble(0.0, floatOffset, 0.0, 0.0),
              alignment: Alignment.center,
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
                      onTap: _navigateToPreview,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: _PhoneMockup(
                          key: ValueKey(activeProfile.name),
                          profile: activeProfile,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: isNarrow ? -14 : -40,
                    top:
                        100 +
                        math.sin((_animController.value + 0.3) * math.pi * 2) *
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
                        math.sin((_animController.value + 0.6) * math.pi * 2) *
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
              children: List.generate(_heroDemoProfiles.length, (index) {
                final isActive = index == activeIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive ? brandOrange : AppColors.border,
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
            color: Colors.white.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.92),
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
                  color: darkAccent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValueBandSection(BuildContext context) {
    return Container(
      width: double.infinity,
      color: lightBg,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 820;
              final copy = Column(
                crossAxisAlignment:
                    isDesktop
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.center,
                children: [
                  Text(
                    'MÃ¼ÅŸterileriniz ihtiyaÃ§ duyduÄŸu her bilgiye tek linkten ulaÅŸsÄ±n',
                    textAlign: isDesktop ? TextAlign.left : TextAlign.center,
                    style: const TextStyle(
                      color: darkAccent,
                      fontSize: 30,
                      height: 1.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Vitrin linkinizi WhatsApp, sosyal medya, Google Ä°ÅŸletme, kartvizit, paket veya iÅŸletme iÃ§i QR kod Ã¼zerinden paylaÅŸÄ±n.',
                    textAlign: isDesktop ? TextAlign.left : TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 16,
                      height: 1.55,
                    ),
                  ),
                ],
              );
              final chips = Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: isDesktop ? WrapAlignment.end : WrapAlignment.center,
                children:
                    const [
                      'WhatsApp',
                      'Sosyal medya',
                      'Google Ä°ÅŸletme',
                      'QR kod',
                      'Vitrin linki',
                    ].map((text) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          text,
                          style: const TextStyle(
                            color: AppColors.darkTextAlt,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      );
                    }).toList(),
              );

              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 5, child: copy),
                    const SizedBox(width: 48),
                    Expanded(flex: 4, child: chips),
                  ],
                );
              }

              return Column(
                children: [copy, const SizedBox(height: 24), chips],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesSection(BuildContext context) {
    return Container(
      width: double.infinity,
      color: lightBg,
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 72),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              const Text(
                'Dijital vitrininizi kolayca hazÄ±rlayÄ±n',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: darkAccent,
                  letterSpacing: 0,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                'MÃ¼ÅŸterilerinizin ihtiyaÃ§ duyduÄŸu bilgileri tek vitrinde toplayÄ±n, panelden yÃ¶netin ve istediÄŸiniz yerde paylaÅŸÄ±n.',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black54,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 1040;
                  final isTablet = constraints.maxWidth > 680;
                  final cardWidth =
                      isDesktop
                          ? (constraints.maxWidth - 54) / 4
                          : isTablet
                          ? (constraints.maxWidth - 18) / 2
                          : constraints.maxWidth;
                  return Wrap(
                    spacing: 18,
                    runSpacing: 18,
                    alignment: WrapAlignment.center,
                    children:
                        [
                          _LandingValueCard(
                            icon: Icons.bolt_rounded,
                            color: brandOrange,
                            title: 'Dakikalar iÃ§inde yayÄ±na alÄ±n',
                            desc:
                                'Temel bilgilerinizi ekleyin ve vitrininizi oluÅŸturun.',
                            isHorizontal: !isTablet,
                            enableHover: isDesktop,
                          ),
                          _LandingValueCard(
                            icon: Icons.contact_phone_rounded,
                            color: mint,
                            title: 'MÃ¼ÅŸteriler size doÄŸrudan ulaÅŸsÄ±n',
                            desc:
                                'WhatsApp, adres ve yol tarifi seÃ§eneklerini tek yerde sunun.',
                            isHorizontal: !isTablet,
                            enableHover: isDesktop,
                          ),
                          _LandingValueCard(
                            icon: Icons.share_rounded,
                            color: pinkAccent,
                            title: 'Her kanalda aynÄ± vitrini paylaÅŸÄ±n',
                            desc:
                                'Linkinizi sosyal medyada, QR kodunuzu iÅŸletmenizde kullanÄ±n.',
                            isHorizontal: !isTablet,
                            enableHover: isDesktop,
                          ),
                          _LandingValueCard(
                            icon: Icons.edit_note_rounded,
                            color: blueAccent,
                            title: 'Bilgilerinizi panelden gÃ¼ncelleyin',
                            desc:
                                'FotoÄŸraf, Ã¼rÃ¼n, hizmet ve iletiÅŸim bilgilerinizi istediÄŸiniz zaman dÃ¼zenleyin.',
                            isHorizontal: !isTablet,
                            enableHover: isDesktop,
                          ),
                        ].map((widget) => SizedBox(width: cardWidth, child: widget)).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonSection(BuildContext context) {
    const separateSetupItems = [
      (Icons.language_rounded, 'Domain ve hosting'),
      (Icons.tune_rounded, 'Teknik ayarlar'),
      (Icons.chat_bubble_outline_rounded, 'WhatsApp baÄŸlantÄ±sÄ±'),
      (Icons.qr_code_2_rounded, 'QR ve paylaÅŸÄ±m sÃ¼reci'),
      (Icons.support_agent_rounded, 'Ä°Ã§erik gÃ¼ncelleme desteÄŸi'),
    ];
    const vitrinxSetupItems = [
      (Icons.storefront_rounded, 'Ä°ÅŸletme bilgileri ve fotoÄŸraflar'),
      (Icons.inventory_2_rounded, 'ÃœrÃ¼nler ve hizmetler'),
      (Icons.hub_rounded, 'WhatsApp, adres, link ve QR'),
      (Icons.edit_note_rounded, 'Panelden kolay gÃ¼ncelleme'),
      (Icons.forum_rounded, 'MÃ¼ÅŸteriyle doÄŸrudan iletiÅŸim'),
    ];

    return Container(
      width: double.infinity,
      color: AppColors.bgEditor,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              const Text(
                'Dijital vitrininiz iÃ§in gerekenler tek yerde',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: darkAccent,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'AraÃ§larÄ± ve kurulumlarÄ± ayrÄ± ayrÄ± yÃ¶netmek yerine iÅŸletme bilgilerinizi VitrinXâ€™e ekleyin ve paylaÅŸmaya baÅŸlayÄ±n.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.mutedText,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 820;
                  final separatePanel = _buildSetupPanel(
                    label: 'AyrÄ± ayrÄ± kurulum',
                    items: separateSetupItems,
                    footer: 'Birden fazla araÃ§ ve iÅŸlem',
                    highlighted: false,
                  );
                  final vitrinxPanel = _buildSetupPanel(
                    label: 'VitrinX ile',
                    items: vitrinxSetupItems,
                    footer: 'Tek panel, tek link, doÄŸrudan iletiÅŸim',
                    highlighted: true,
                  );
                  final direction = Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFDCE7EA)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(15, 23, 42, 0.08),
                          blurRadius: 16,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      isDesktop
                          ? Icons.arrow_forward_rounded
                          : Icons.arrow_downward_rounded,
                      color: brandOrange,
                    ),
                  );

                  if (isDesktop) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: separatePanel),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: direction,
                        ),
                        Expanded(child: vitrinxPanel),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      separatePanel,
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        child: direction,
                      ),
                      vitrinxPanel,
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSetupPanel({
    required String label,
    required List<(IconData, String)> items,
    required String footer,
    required bool highlighted,
  }) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: highlighted ? null : Colors.white,
        gradient:
            highlighted
                ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.darkText, Color(0xFF0B6670)],
                )
                : null,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color:
              highlighted
                  ? const Color.fromRGBO(16, 216, 216, 0.32)
                  : const Color(0xFFDCE7EA),
        ),
        boxShadow: [
          BoxShadow(
            color:
                highlighted
                    ? const Color.fromRGBO(11, 102, 112, 0.2)
                    : const Color.fromRGBO(15, 23, 42, 0.06),
            blurRadius: highlighted ? 34 : 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: highlighted ? brandOrange : AppColors.mutedText,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 22),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color:
                          highlighted
                              ? Colors.white.withValues(alpha: 0.1)
                              : AppColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      highlighted ? Icons.check_rounded : item.$1,
                      size: 19,
                      color:
                          highlighted
                              ? const Color(0xFF65E7E7)
                              : AppColors.mutedText,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.$2,
                      style: TextStyle(
                        color:
                            highlighted
                                ? Colors.white
                                : AppColors.darkTextAlt,
                        fontSize: 14,
                        height: 1.35,
                        fontWeight:
                            highlighted ? FontWeight.w800 : FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
            decoration: BoxDecoration(
              color:
                  highlighted
                      ? Colors.white.withValues(alpha: 0.1)
                      : AppColors.bgLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    highlighted
                        ? Colors.white.withValues(alpha: 0.12)
                        : AppColors.border,
              ),
            ),
            child: Text(
              footer,
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                    highlighted
                        ? const Color(0xFFBFF7F7)
                        : AppColors.mutedText,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustBandSection(BuildContext context) {
    const items = [
      (Icons.credit_card_off_rounded, 'Kredi kartÄ± gerekmez'),
      (Icons.percent_rounded, 'SatÄ±ÅŸtan komisyon alÄ±nmaz'),
      (Icons.code_off_rounded, 'Kodsuz kurulum'),
      (Icons.qr_code_2_rounded, 'Link ve QR kod hazÄ±rdÄ±r'),
      (Icons.chat_bubble_rounded, 'WhatsApp ile doÄŸrudan iletiÅŸim'),
    ];

    return Container(
      width: double.infinity,
      color: AppColors.bgLight,
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              const Text(
                'BaÅŸlarken sÃ¼rpriz yok',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: darkAccent,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 28),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children:
                    items
                        .map(
                          (item) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: AppColors.border,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(item.$1, color: brandOrange, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  item.$2,
                                  style: const TextStyle(
                                    color: AppColors.darkText,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepsSection(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.bgLight,
      padding: const EdgeInsets.symmetric(vertical: 76, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              const Text(
                'ÃœÃ§ adÄ±mda vitrininiz hazÄ±r',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: darkAccent,
                  letterSpacing: 0,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 56),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 800;
                  final steps = [
                    _buildStepTimeline(
                      1,
                      'Bilgilerinizi ekleyin',
                      'Ä°ÅŸletme adÄ±, aÃ§Ä±klama, WhatsApp ve adres bilgilerinizi girin.',
                    ),
                    _buildStepTimeline(
                      2,
                      'Vitrininizi hazÄ±rlayÄ±n',
                      'FotoÄŸraflarÄ±nÄ±zÄ±, Ã¼rÃ¼nlerinizi ve hizmetlerinizi ekleyin.',
                    ),
                    _buildStepTimeline(
                      3,
                      'MÃ¼ÅŸterilerinizle paylaÅŸÄ±n',
                      'Vitrin linkinizi veya QR kodunuzu paylaÅŸÄ±n.',
                    ),
                  ];

                  if (isDesktop) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: steps.map((e) => Expanded(child: e)).toList(),
                    );
                  }
                  return Column(
                    children:
                        steps.map((e) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 28),
                            child: e,
                          );
                        }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepTimeline(int step, String title, String description) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: brandOrange.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: brandOrange.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '$step',
            style: const TextStyle(
              color: brandOrange,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: darkAccent,
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.mutedText,
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomCTA(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 88, horizontal: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.bgEditor, AppColors.primaryDark],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              const Text(
                'Ä°ÅŸletmenizi tek linkte mÃ¼ÅŸterilerinizle buluÅŸturun',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.bgLight,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'VitrinXâ€™inizi oluÅŸturun; linkinizi, QR kodunuzu ve WhatsApp iletiÅŸiminizi paylaÅŸmaya baÅŸlayÄ±n.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.border,
                  fontSize: 18,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: _navigateToEditor,
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 24,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 10,
                ),
                child: const Text(
                  'VitrinX OluÅŸtur',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      color: AppColors.bgEditor,
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Text(
            'VITRINX',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 8,
              color: brandOrange.withValues(alpha: 0.8),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Ä°ÅŸletmenizin paylaÅŸÄ±labilir dijital vitrini',
            style: TextStyle(
              color: AppColors.mutedText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFooterLegalLink(
                label: 'KVKK ve Gizlilik PolitikasÄ±',
                routePath: LegalConfig.privacyPath,
              ),
              _buildFooterLegalLink(
                label: 'KullanÄ±m ÅartlarÄ±',
                routePath: LegalConfig.termsPath,
              ),
              _buildFooterLegalLink(
                label: 'Veri Silme',
                routePath: LegalConfig.dataDeletionPath,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLegalLink({
    required String label,
    required String routePath,
  }) {
    return TextButton(
      onPressed: () => Navigator.pushNamed(context, routePath),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.mutedText,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _HeroDemoAction {
  final IconData icon;
  final Color color;

  const _HeroDemoAction(this.icon, this.color);
}

class _HeroDemoLink {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _HeroDemoLink(this.title, this.subtitle, this.icon, this.color);
}

class _HeroDemoProfile {
  final String name;
  final String category;
  final String status;
  final String description;
  final IconData icon;
  final Color accentColor;
  final IconData badgeIcon;
  final String badgeText;
  final IconData secondaryBadgeIcon;
  final String secondaryBadgeText;
  final List<_HeroDemoAction> actions;
  final List<_HeroDemoLink> links;
  final String coverImageUrl;
  final List<String> galleryImages;

  const _HeroDemoProfile({
    required this.name,
    required this.category,
    required this.status,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.badgeIcon,
    required this.badgeText,
    required this.secondaryBadgeIcon,
    required this.secondaryBadgeText,
    required this.actions,
    required this.links,
    required this.coverImageUrl,
    required this.galleryImages,
  });

  Color get secondaryBadgeColor {
    if (links.isEmpty) return accentColor;
    return links.last.color;
  }

  StoreData toStoreData() {
    final galleryItems = [
      StoreGalleryItem(id: 'cover', imageUrl: coverImageUrl),
      ...galleryImages.asMap().entries.map(
        (e) => StoreGalleryItem(id: 'gallery-${e.key}', imageUrl: e.value),
      ),
    ];

    List<StoreOffering> parsedOfferings = [];
    String mappedKategori = 'DiÄŸer';
    double? lat;
    double? lng;
    String phone = '05551234567';
    String web = '';
    String addr = 'AtatÃ¼rk Cad. No:24, ÅiÅŸli, Ä°stanbul';

    if (name.contains('Aymira')) {
      mappedKategori = 'Giyim & Butik';
      lat = 41.0606;
      lng = 28.9878;
      web = 'aymiragiyim.com';
      parsedOfferings = [
        StoreOffering(
          id: '1',
          title: 'Elbise SeÃ§enekleri',
          description: 'Yeni sezon Ã¶zel tasarÄ±m elbiseler',
          price: 'MaÄŸazada sorunuz',
        ),
        StoreOffering(
          id: '2',
          title: 'Triko & HÄ±rka',
          description: 'FarklÄ± renk ve beden alternatifleriyle',
          price: 'MaÄŸazada sorunuz',
        ),
        StoreOffering(
          id: '3',
          title: 'Yeni Sezon Ceket',
          description: 'ÅÄ±k ve modern gÃ¼nlÃ¼k ceketler',
          price: 'MaÄŸazada sorunuz',
        ),
      ];
    } else if (name.contains('Lezzet')) {
      mappedKategori = 'Kafe / Lokanta';
      lat = 41.0422;
      lng = 29.0084;
      web = 'lezzetduragi.com';
      parsedOfferings = [
        StoreOffering(
          id: '1',
          title: 'GÃ¼nÃ¼n MenÃ¼sÃ¼',
          description: 'Ana yemek + Ã§orba + iÃ§ecek menÃ¼sÃ¼',
          price: '120 TL',
        ),
        StoreOffering(
          id: '2',
          title: 'Ev YapÄ±mÄ± MantÄ±',
          description: 'YoÄŸurtlu ve tereyaÄŸlÄ± soslu el yapÄ±mÄ± mantÄ±',
          price: '95 TL',
        ),
      ];
    } else if (name.contains('Nova')) {
      mappedKategori = 'KuafÃ¶r';
      lat = 41.0370;
      lng = 28.9850;
      web = 'novakuafor.com';
      parsedOfferings = [
        StoreOffering(
          id: '1',
          title: 'SaÃ§ Kesimi & TasarÄ±m',
          description: 'YÄ±kama ve fÃ¶n dahil komple saÃ§ tasarÄ±mÄ±',
          price: '180 TL',
        ),
        StoreOffering(
          id: '2',
          title: 'SaÃ§ Boyama & Keratin',
          description: 'SaÃ§ yapÄ±sÄ±na Ã¶zel organik keratin bakÄ±mÄ±',
          price: '450 TL',
        ),
      ];
    } else if (name.contains('TeknoFix')) {
      mappedKategori = 'Teknik Servis';
      lat = 41.0150;
      lng = 28.9740;
      web = 'teknofix.com';
      parsedOfferings = [
        StoreOffering(
          id: '1',
          title: 'Telefon Ekran DeÄŸiÅŸimi',
          description: '30 dakikada hÄ±zlÄ± ekran deÄŸiÅŸimi ve garanti',
          price: 'MaÄŸazada sorunuz',
        ),
        StoreOffering(
          id: '2',
          title: 'Batarya DeÄŸiÅŸimi',
          description: 'YÃ¼ksek kapasiteli batarya yenilemesi',
          price: 'MaÄŸazada sorunuz',
        ),
      ];
    }

    return StoreData(
      name: name,
      businessType: category,
      description: description,
      status: status,
      theme: 'Premium',
      isEsnafMode: true,
      whatsapp: phone,
      website: web,
      address: addr,
      latitude: lat,
      longitude: lng,
      kategori: mappedKategori,
      galleryItems: galleryItems,
      offerings: parsedOfferings,
      marketplaceLinks:
          links
              .asMap()
              .entries
              .map(
                (e) => MarketplaceLink(
                  id: '${e.key}',
                  platform: e.value.title,
                  url:
                      e.value.title == 'Trendyol'
                          ? 'trendyol.com/magaza/demo'
                          : 'google.com',
                  subtitle: e.value.subtitle,
                ),
              )
              .toList(),
    );
  }
}

class _PhoneMockup extends StatelessWidget {
  final _HeroDemoProfile profile;

  const _PhoneMockup({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: 640,
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white24, width: 8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
          BoxShadow(
            color: AppColors.brandOrange.withValues(alpha: 0.2),
            blurRadius: 80,
            offset: const Offset(-20, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            children: [
              SizedBox(
                height: 124,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: profile.accentColor.withValues(alpha: 0.16),
                        image: DecorationImage(
                          image: NetworkImage(profile.coverImageUrl),
                          fit: BoxFit.cover,
                          onError: (exception, stackTrace) {
                            // Suppress errors during tests or network issues
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      top: 76,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.bgLight,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            profile.icon,
                            size: 24,
                            color: profile.accentColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        profile.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.darkText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        profile.status.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  children: [
                    Text(
                      profile.category.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: profile.accentColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      profile.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:
                      profile.actions
                          .map(
                            (action) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: _buildMockIconButton(
                                action.icon,
                                action.color,
                              ),
                            ),
                          )
                          .toList(),
                ),
              ),
              const SizedBox(height: 12),
              for (final link in profile.links.take(2))
                _buildMockLinkItem(
                  link.title,
                  link.subtitle,
                  link.color,
                  link.icon,
                ),
              _buildMockGalleryRow(profile),
              const SizedBox(height: 12),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Vitrin hazÄ±r',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: AppColors.darkText,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${profile.links.length} baÄŸlantÄ±',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: profile.accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.qr_code_2_rounded,
                        size: 24,
                        color: profile.accentColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Bu vitrin VitrinX ile oluÅŸturuldu',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black45,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMockGalleryRow(_HeroDemoProfile profile) {
    final allImages = [profile.coverImageUrl, ...profile.galleryImages];
    final displayImages = allImages.take(3).toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 20, right: 20),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: profile.accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.photo_library_rounded,
                  color: profile.accentColor,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Vitrin galerisi',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: AppColors.darkText,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: profile.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${allImages.length} foto\u011fraf',
                  style: TextStyle(
                    color: profile.accentColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children:
                displayImages.asMap().entries.map((e) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: e.key == 0 ? 0 : 5),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              color: profile.accentColor.withValues(
                                alpha: 0.12,
                              ),
                              image: DecorationImage(
                                image: NetworkImage(e.value),
                                fit: BoxFit.cover,
                                onError: (exception, stackTrace) {
                                  // Suppress errors during tests or network issues
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMockIconButton(IconData icon, Color color) {
    return Container(
      width: 44,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }

  Widget _buildMockLinkItem(
    String title,
    String subtitle,
    Color color,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 20, right: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.black54, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LandingValueCard extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String desc;
  final bool isHorizontal;
  final bool enableHover;

  const _LandingValueCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.desc,
    required this.isHorizontal,
    required this.enableHover,
  });

  @override
  State<_LandingValueCard> createState() => _LandingValueCardState();
}

class _LandingValueCardState extends State<_LandingValueCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isLifted = widget.enableHover && _isHovered;
    final icon = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: widget.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(widget.icon, color: widget.color, size: 24),
    );
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.title,
          style: const TextStyle(
            fontSize: 17,
            height: 1.2,
            fontWeight: FontWeight.w900,
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.desc,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.mutedText,
            height: 1.45,
          ),
        ),
      ],
    );

    return MouseRegion(
      onEnter:
          widget.enableHover ? (_) => setState(() => _isHovered = true) : null,
      onExit:
          widget.enableHover ? (_) => setState(() => _isHovered = false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, isLifted ? -4 : 0, 0),
        constraints: BoxConstraints(minHeight: widget.isHorizontal ? 0 : 188),
        padding:
            widget.isHorizontal
                ? const EdgeInsets.symmetric(horizontal: 18, vertical: 17)
                : const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: isLifted ? 0.13 : 0.04),
              blurRadius: isLifted ? 26 : 12,
              offset: Offset(0, isLifted ? 12 : 6),
            ),
          ],
        ),
        child:
            widget.isHorizontal
                ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    icon,
                    const SizedBox(width: 15),
                    Expanded(child: content),
                  ],
                )
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [icon, const SizedBox(height: 18), content],
                ),
      ),
    );
  }
}

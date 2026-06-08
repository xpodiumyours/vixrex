import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitrinx/screens/store_editor_screen.dart';
import 'package:vitrinx/screens/vitrin_editor_screen.dart';
import 'package:vitrinx/screens/preview_screen.dart';
import 'package:vitrinx/screens/explore_screen.dart';
import 'package:vitrinx/screens/store_setup_screen.dart';
import 'package:vitrinx/screens/auth_screen.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/services/local_storage_keys.dart';
import 'package:vitrinx/services/auth_service.dart';
import 'package:vitrinx/core/theme/vitrin_theme.dart';

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
  bool _hasSavedStore = false;
  bool _isCheckingSavedVitrin = true;
  final TextEditingController _storeNameController = TextEditingController();

  // Modern Color Palette
  static const Color brandOrange = Color(0xFFFF5A1F);
  static const Color darkAccent = Color(0xFF0F172A);
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color mint = Color(0xFF10B981);
  static const Color blueAccent = Color(0xFF2563EB);
  static const Color pinkAccent = Color(0xFFFB7185);

  static const List<_HeroDemoProfile> _heroDemoProfiles = [
    _HeroDemoProfile(
      name: 'Aymira Giyim',
      category: 'Kadın giyim / butik',
      status: 'Açık',
      description: 'Yeni sezon reyonları ve mağaza fotoğrafları tek vitrinde.',
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
          'Raf ve reyon fotoğrafları',
          Icons.photo_library_rounded,
          Color(0xFFFF5A1F),
        ),
        _HeroDemoLink(
          'Trendyol',
          'Mağazayı ziyaret edin',
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
      name: 'Lezzet Durağı',
      category: 'Kafe / restoran',
      status: 'Açık',
      description: 'Menü, konum ve WhatsApp sipariş bilgileri tek ekranda.',
      icon: Icons.restaurant_menu_rounded,
      accentColor: Color(0xFFEA580C),
      badgeIcon: Icons.menu_book_rounded,
      badgeText: 'Menü',
      secondaryBadgeIcon: Icons.directions_rounded,
      secondaryBadgeText: 'Yol tarifi',
      actions: [
        _HeroDemoAction(Icons.chat_bubble_rounded, Color(0xFF25D366)),
        _HeroDemoAction(Icons.location_on_rounded, Color(0xFFEF4444)),
      ],
      links: [
        _HeroDemoLink(
          'Günün menüsü',
          'Sıcak yemek ve tatlılar',
          Icons.local_dining_rounded,
          Color(0xFFEA580C),
        ),
        _HeroDemoLink(
          'Paket servis',
          'WhatsApp ile sipariş',
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
      name: 'Nova Kuaför',
      category: 'Kuaför / güzellik',
      status: 'Açık',
      description: 'Randevu, hizmetler ve sosyal medya bağlantıları hazır.',
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
          'Kesim, boya ve bakım',
          Icons.spa_rounded,
          Color(0xFFDB2777),
        ),
        _HeroDemoLink(
          'Randevu al',
          'WhatsApp ile hızlı iletişim',
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
      status: 'Açık',
      description: 'Servis talebi, adres ve güvenilir iletişim tek vitrinde.',
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
          'Servis kaydı',
          'Ekran, batarya ve bakım',
          Icons.construction_rounded,
          Color(0xFF2563EB),
        ),
        _HeroDemoLink(
          'Google yorumları',
          'Müşteri güveni',
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
            await prefs.setString(LocalStorageKeys.storeData, jsonEncode(store.toJson()));
            
            if (!mounted) return;
            final dbStore = await Supabase.instance.client
                .from('stores')
                .select('edit_token')
                .eq('user_id', currentUser.id)
                .maybeSingle();
            
            if (!mounted) return;
            if (dbStore != null && dbStore['edit_token'] != null) {
              await prefs.setString(LocalStorageKeys.storeEditToken, dbStore['edit_token'] as String);
            }

            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const StoreEditorScreen()),
            );
            return;
          } else {
            await prefs.setString(LocalStorageKeys.vitrinData, jsonEncode(store.toJson()));
            
            if (!mounted) return;
            final dbStore = await Supabase.instance.client
                .from('stores')
                .select('edit_token')
                .eq('user_id', currentUser.id)
                .maybeSingle();
            
            if (!mounted) return;
            if (dbStore != null && dbStore['edit_token'] != null) {
              await prefs.setString(LocalStorageKeys.vitrinEditToken, dbStore['edit_token'] as String);
            }

            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const VitrinEditorScreen()),
            );
            return;
          }
        }
      }

      final savedVitrinJson = prefs.getString(LocalStorageKeys.vitrinData);
      final savedStoreJson = prefs.getString(LocalStorageKeys.storeData);
      final legacyJson = prefs.getString(LocalStorageKeys.vitrinData);
      var hasSavedVitrin = false;
      var hasSavedStore = false;

      final savedVitrin = _readSavedStoreData(savedVitrinJson);
      if (savedVitrin != null && !savedVitrin.isStore) {
        hasSavedVitrin = _hasMeaningfulSavedVitrin(savedVitrin);
      }

      final savedStore = _readSavedStoreData(savedStoreJson);
      if (savedStore != null && savedStore.isStore) {
        hasSavedStore = _hasMeaningfulSavedVitrin(savedStore);
      }

      final legacyData = _readSavedStoreData(legacyJson);
      if (legacyData != null && legacyData.isStore) {
        hasSavedStore = _hasMeaningfulSavedVitrin(legacyData);
      }

      if (!mounted) return;
      setState(() {
        _hasSavedVitrin = hasSavedVitrin;
        _hasSavedStore = hasSavedStore;
        _isCheckingSavedVitrin = false;
      });
    } catch (error) {
      debugPrint('Saved vitrin state load error: $error');
      if (!mounted) return;
      setState(() {
        _hasSavedVitrin = false;
        _hasSavedStore = false;
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
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VitrinEditorScreen(initialStoreName: name)),
    );
    if (mounted) {
      _loadSavedVitrinState();
    }
  }

  Future<void> _navigateToSavedVitrin() async {
    if (!_hasSavedVitrin || _isCheckingSavedVitrin) return;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VitrinEditorScreen()),
    );
    if (mounted) {
      _loadSavedVitrinState();
    }
  }

  Future<void> _navigateToSavedStore() async {
    if (!_hasSavedStore || _isCheckingSavedVitrin) return;

    final prefs = await SharedPreferences.getInstance();
    final savedStoreJson = prefs.getString(LocalStorageKeys.storeData);
    if (savedStoreJson == null || savedStoreJson.trim().isEmpty) {
      final legacyJson = prefs.getString(LocalStorageKeys.vitrinData);
      final legacyData = _readSavedStoreData(legacyJson);
      if (legacyData != null && legacyData.isStore) {
        await prefs.setString(LocalStorageKeys.storeData, legacyJson!);
        final legacyToken = prefs.getString(LocalStorageKeys.vitrinEditToken);
        if (legacyToken != null) {
          await prefs.setString(LocalStorageKeys.storeEditToken, legacyToken);
          await prefs.remove(LocalStorageKeys.vitrinEditToken);
        }
        await prefs.remove(LocalStorageKeys.vitrinData);
      }
    }

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StoreEditorScreen()),
    );
    if (mounted) {
      _loadSavedVitrinState();
    }
  }

  void _navigateToPreview() {
    final activeProfile = _heroDemoProfiles[_activeProfileIndex];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PreviewScreen(storeData: activeProfile.toStoreData()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: brandOrange,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroSection(context),
            _buildValueBandSection(context),
            _buildFeaturesSection(context),
            _buildStepsSection(context),
            _buildBottomCTA(context),
            _buildFooter(),
          ],
        ),
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
          colors: [Color(0xFFFFFBF7), Color(0xFFF6F8FF)],
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
              VitrinButton(
                text: isDesktop ? 'Vitrinleri Keşfet' : 'Keşfet',
                icon: Icons.explore_rounded,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ExploreScreen()),
                  );
                },
              ),
              const SizedBox(width: 10),
              if (_isUserLoggedIn) ...[
                VitrinButton(
                  text: isDesktop ? 'Çıkış Yap' : 'Çıkış',
                  icon: Icons.logout_rounded,
                  isSecondary: true,
                  onPressed: () async {
                    await const AuthService().signOut();
                    if (mounted) {
                      setState(() {});
                      _loadSavedVitrinState();
                    }
                  },
                ),
              ] else ...[
                VitrinButton(
                  text: 'Giriş Yap',
                  icon: Icons.login_rounded,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AuthScreen()),
                    ).then((_) {
                      if (mounted) {
                        setState(() {});
                        _loadSavedVitrinState();
                      }
                    });
                  },
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
              'ESNAF İÇİN DİJİTAL VİTRİN',
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
            'Mağazanızın tek linkte hazır vitrini',
            textAlign: isDesktop ? TextAlign.left : TextAlign.center,
            style: TextStyle(
              color: darkAccent,
              fontSize: isDesktop ? 64 : 42,
              fontWeight: FontWeight.w900,
              height: 1.1,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Fotoğraflarınızı, iletişim bilgilerinizi, pazaryeri linklerinizi ve QR kodunuzu müşterilerinizle tek sayfada paylaşın.',
            textAlign: isDesktop ? TextAlign.left : TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 18,
              height: 1.6,
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
      'Kredi kartı gerekmez',
      'Dakikalar içinde hazırlanır',
      'Mobil uyumlu paylaşım',
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
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded, size: 16, color: mint),
                  const SizedBox(width: 7),
                  Text(
                    text,
                    style: const TextStyle(
                      color: Color(0xFF334155),
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
    final canOpenSavedStore = _hasSavedStore && !_isCheckingSavedVitrin;
    final savedVitrinLabel =
        _isCheckingSavedVitrin
            ? 'Kontrol ediliyor'
            : _hasSavedVitrin
            ? 'Vitrinimi Düzenle'
            : 'Kayıtlı vitrin yok';
    final savedStoreLabel =
        _isCheckingSavedVitrin
            ? 'Kontrol ediliyor'
            : _hasSavedStore
            ? 'Mağazamı Düzenle'
            : 'Kayıtlı mağaza yok';

    final buttons = [
      VitrinButton(
        text: savedVitrinLabel,
        icon: canOpenSavedVitrin ? Icons.edit_rounded : Icons.lock_outline_rounded,
        onPressed: canOpenSavedVitrin ? () => _navigateToSavedVitrin() : null,
      ),
      const SizedBox(width: 12, height: 12),
      VitrinButton(
        text: savedStoreLabel,
        icon: canOpenSavedStore ? Icons.storefront_rounded : Icons.lock_outline_rounded,
        isSecondary: true,
        onPressed: canOpenSavedStore ? () => _navigateToSavedStore() : null,
      ),
      const SizedBox(width: 12, height: 12),
      VitrinButton(
        text: 'Vitrinleri Keşfet',
        icon: Icons.explore_rounded,
        isSecondary: true,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ExploreScreen()),
          );
        },
      ),
    ];

    return isDesktop
        ? Row(mainAxisAlignment: MainAxisAlignment.start, children: buttons)
        : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: buttons,
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
          border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
        ),
        child: Row(
          children: [
            const Text(
              'vitrinx.app/',
              style: TextStyle(
                color: Color(0xFF64748B),
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
                  hintText: 'magazaniz',
                  hintStyle: TextStyle(
                    color: Color(0xFF94A3B8),
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
          child: VitrinButton(
            text: 'Ücretsiz Oluştur',
            icon: Icons.arrow_forward_rounded,
            onPressed: _navigateToEditor,
          ),
        );
      },
    );

    final storeSetupButton = VitrinButton(
      text: 'Mağaza Aç →',
      icon: Icons.add_business_rounded,
      isSecondary: true,
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StoreSetupScreen()),
        );
      },
    );

    if (isDesktop) {
      return SizedBox(
        height: 64,
        child: Row(
          children: [
            inputWidget,
            const SizedBox(width: 12),
            buttonWidget,
            const SizedBox(width: 10),
            storeSetupButton,
          ],
        ),
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 56, child: Row(children: [inputWidget])),
          const SizedBox(height: 12),
          SizedBox(height: 56, child: buttonWidget),
          const SizedBox(height: 10),
          SizedBox(height: 52, child: storeSetupButton),
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
          SizedBox(
            width: 100,
            height: 36,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  child: _buildSocialProofAvatar(
                    icon: Icons.checkroom_rounded,
                    color: brandOrange,
                  ),
                ),
                Positioned(
                  left: 20,
                  child: _buildSocialProofAvatar(
                    icon: Icons.restaurant_menu_rounded,
                    color: const Color(0xFFEA580C),
                  ),
                ),
                Positioned(
                  left: 40,
                  child: _buildSocialProofAvatar(
                    icon: Icons.content_cut_rounded,
                    color: const Color(0xFFDB2777),
                  ),
                ),
                Positioned(
                  left: 60,
                  child: _buildSocialProofAvatar(
                    icon: Icons.build_circle_rounded,
                    color: blueAccent,
                  ),
                ),
              ],
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFBBF24),
                      size: 16,
                    ),
                    Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFBBF24),
                      size: 16,
                    ),
                    Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFBBF24),
                      size: 16,
                    ),
                    Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFBBF24),
                      size: 16,
                    ),
                    Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFBBF24),
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      '4.9/5',
                      style: TextStyle(
                        color: darkAccent,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  '1.200\'den fazla esnaf ve butik VitrinX kullanıyor',
                  style: TextStyle(
                    color: Color(0xFF64748B),
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

  Widget _buildSocialProofAvatar({
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 14),
        ),
      ),
    );
  }

  Widget _buildHeroMockup() {
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
                    ..translate(0.0, floatOffset, 0.0),
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
                    right: -40,
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
                    left: -30,
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
                    color: isActive ? brandOrange : const Color(0xFFCBD5E1),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.5,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 12),
              Text(
                text,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: Color(0xFFF8FAFC),
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
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 20),
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
                    'Müşteri sizi nereden bulursa bulsun, tek linkten ulaşır.',
                    textAlign: isDesktop ? TextAlign.left : TextAlign.center,
                    style: const TextStyle(
                      color: darkAccent,
                      fontSize: 28,
                      height: 1.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'WhatsApp, Instagram, Google İşletme, paket üstü QR veya sosyal medya bio alanı için tek paylaşılabilir vitrin.',
                    textAlign: isDesktop ? TextAlign.left : TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
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
                      'WhatsApp mesajı',
                      'Instagram bio',
                      'Google İşletme',
                      'Paket üstü QR',
                    ].map((text) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          text,
                          style: const TextStyle(
                            color: Color(0xFF334155),
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
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              const Text(
                'Bir link, tüm mağaza kanallarınız',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: darkAccent,
                  letterSpacing: 0,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                'Müşteri iletişim, konum, fotoğraf ve pazaryeri bilgilerine tek vitrinden ulaşır.',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black54,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 64),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 700;
                  return Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    alignment: WrapAlignment.center,
                    children:
                        [
                              _HoverFeatureCard(
                                icon: Icons.link_rounded,
                                color: blueAccent,
                                title: 'Mağazanızı tek linkte toplayın',
                                desc:
                                    'İletişim, konum, sosyal medya ve pazaryeri bağlantıları tek yerde görünür.',
                              ),
                              _HoverFeatureCard(
                                icon: Icons.photo_library_rounded,
                                color: brandOrange,
                                title: 'Fotoğraflarla vitrininizi gösterin',
                                desc:
                                    'Raf, ürün, reyon veya mağaza fotoğraflarınızı müşteriye hızlıca sunun.',
                              ),
                              _HoverFeatureCard(
                                icon: Icons.chat_bubble_rounded,
                                color: mint,
                                title:
                                    'WhatsApp ve konumla hızlı ulaşım sağlayın',
                                desc:
                                    'Müşteri sizi aramakla uğraşmadan mesaj atabilir veya yol tarifi alabilir.',
                              ),
                              _HoverFeatureCard(
                                icon: Icons.qr_code_2_rounded,
                                color: pinkAccent,
                                title: 'QR kodla her yerde paylaşın',
                                desc:
                                    'Mağaza içi afiş, paket, kartvizit ve sosyal medya için hazır paylaşım.',
                              ),
                            ]
                            .map(
                              (widget) => SizedBox(
                                width:
                                    isDesktop
                                        ? (constraints.maxWidth - 24) / 2
                                        : constraints.maxWidth,
                                child: widget,
                              ),
                            )
                            .toList(),
                  );
                },
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
      color: Color(0xFFF8FAFC),
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              const Text(
                'Dakikalar içinde yayına hazır',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: darkAccent,
                  letterSpacing: 0,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 80),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 800;
                  final steps = [
                    _buildStepTimeline(
                      1,
                      'Bilgilerini ekle',
                      'Mağaza adı, açıklama, WhatsApp, adres ve linklerini gir.',
                    ),
                    _buildStepTimeline(
                      2,
                      'Fotoğraflarını yükle',
                      'Mağazanı ve ürünlerini gösteren görsellerle vitrini güçlendir.',
                    ),
                    _buildStepTimeline(
                      3,
                      'Vitrin linkini paylaş',
                      'QR kodu veya linki müşterilerinle paylaş.',
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
                            padding: const EdgeInsets.only(bottom: 40),
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
              color: Color(0xFF64748B),
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
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), brandOrange],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              const Text(
                'Bugün mağazanız için paylaşılabilir bir vitrin oluşturun.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFF8FAFC),
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Linkinizi müşterilerinize gönderin, QR kodunuzu mağazada kullanın, tüm kanallarınızı tek yerde toplayın.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFE2E8F0),
                  fontSize: 18,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              VitrinButton(
                text: 'Vitrinimi oluştur',
                onPressed: _navigateToEditor,
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
      color: Color(0xFFF8FAFC),
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
            'Dijital Dünyadaki Yeni Eviniz',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
    return StoreData(
      name: name,
      businessType: category,
      description: description,
      status: status,
      theme: 'Premium',
      isEsnafMode: true,
      galleryItems: galleryItems,
      marketplaceLinks:
          links
              .asMap()
              .entries
              .map(
                (e) => MarketplaceLink(
                  id: '${e.key}',
                  platform: e.value.title,
                  url: '',
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
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white24, width: 8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
          BoxShadow(
            color: const Color(0xFFFF5A1F).withValues(alpha: 0.2),
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
                          image: NetworkImage(
                            profile.coverImageUrl,
                          ),
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
                            color: Color(0xFFF8FAFC),
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
                          color: Color(0xFF0F172A),
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
                        color: Color(0xFF475569),
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
                  color: Color(0xFFF8FAFC),
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
                          'Vitrin hazır',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${profile.links.length} bağlantı',
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
                'Bu vitrin VitrinX ile oluşturuldu',
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
        color: const Color(0xFFF8FAFC),
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
                    color: Color(0xFF0F172A),
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
                                image: NetworkImage(
                                  e.value,
                                ),
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
        color: const Color(0xFFF8FAFC),
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

class _HoverFeatureCard extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String desc;

  const _HoverFeatureCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.desc,
  });

  @override
  State<_HoverFeatureCard> createState() => _HoverFeatureCardState();
}

class _HoverFeatureCardState extends State<_HoverFeatureCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _isHovered ? -8 : 0, 0),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: VitrinTheme.cardBgColor,
          borderRadius: BorderRadius.circular(VitrinTheme.cardRadius),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: _isHovered ? 0.15 : 0.05),
              blurRadius: _isHovered ? 30 : 10,
              offset: Offset(0, _isHovered ? 15 : 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(VitrinTheme.smallRadius),
              ),
              child: Icon(widget.icon, color: widget.color, size: 28),
            ),
            const SizedBox(height: 20),
            Text(
              widget.title,
              style: VitrinTheme.subHeadingStyle,
            ),
            const SizedBox(height: 12),
            Text(
              widget.desc,
              style: VitrinTheme.bodyStyle,
            ),
          ],
        ),
      ),
    );
  }
}

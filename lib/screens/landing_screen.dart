import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitrinx/screens/preview_screen.dart';
import 'package:vitrinx/models/landing_demo_profile.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/services/local_storage_keys.dart';
import 'package:vitrinx/services/auth_service.dart';
import 'package:vitrinx/services/category_image_service.dart';
import 'package:vitrinx/theme/app_colors.dart';
import 'package:vitrinx/widgets/landing/landing_hero_section.dart';
import 'package:vitrinx/widgets/landing/landing_value_band.dart';
import 'package:vitrinx/widgets/landing/landing_features_section.dart';
import 'package:vitrinx/widgets/landing/landing_comparison_section.dart';
import 'package:vitrinx/widgets/landing/landing_trust_band.dart';
import 'package:vitrinx/widgets/landing/landing_steps_section.dart';
import 'package:vitrinx/widgets/landing/landing_bottom_cta.dart';
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

  /// Kategori sablonlarindan yuklenen galeri gorselleri cache'i
  /// Key: templateCategoryKey, Value: gorsel URL listesi
  final Map<String, List<String>> _categoryGalleryCache = {};
  bool _isLoadingGalleryImages = false;

  // Modern Color Palette
  static const Color brandBlue = AppColors.primary;

  static List<HeroDemoProfile> _heroDemoProfiles = [
    HeroDemoProfile(
      name: 'Aymira Giyim',
      category: 'Kadin giyim / butik',
      status: 'Acik',
      description: 'Yeni sezon reyonlari ve magaza fotograflari tek vitrinde.',
      icon: Icons.checkroom_rounded,
      accentColor: Color(0xFFFF5A1F),
      badgeIcon: Icons.photo_library_rounded,
      badgeText: 'Galeri',
      secondaryBadgeIcon: Icons.qr_code_2_rounded,
      secondaryBadgeText: 'QR kod',
      actions: [
        HeroDemoAction(Icons.chat_bubble_rounded, Color(0xFF25D366)),
        HeroDemoAction(Icons.camera_alt_rounded, Color(0xFFE1306C)),
      ],
      links: [
        HeroDemoLink(
          'Vitrin galerisi',
          'Raf ve reyon fotograflari',
          Icons.photo_library_rounded,
          Color(0xFFFF5A1F),
        ),
        HeroDemoLink(
          'Trendyol',
          'Magazayi ziyaret edin',
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
      templateCategoryKey: 'butik_giyim',
    ),
    HeroDemoProfile(
      name: 'Lezzet Duragi',
      category: 'Kafe / restoran',
      status: 'Acik',
      description: 'Menu, konum ve WhatsApp siparis bilgileri tek ekranda.',
      icon: Icons.restaurant_menu_rounded,
      accentColor: Color(0xFFEA580C),
      badgeIcon: Icons.menu_book_rounded,
      badgeText: 'Menu',
      secondaryBadgeIcon: Icons.directions_rounded,
      secondaryBadgeText: 'Yol tarifi',
      actions: [
        HeroDemoAction(Icons.chat_bubble_rounded, Color(0xFF25D366)),
        HeroDemoAction(Icons.location_on_rounded, Color(0xFFEF4444)),
      ],
      links: [
        HeroDemoLink(
          'Gunun menusu',
          'Sicak yemek ve tatlilar',
          Icons.local_dining_rounded,
          Color(0xFFEA580C),
        ),
        HeroDemoLink(
          'Paket servis',
          'WhatsApp ile siparis',
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
      templateCategoryKey: 'kafe_restoran',
    ),
    HeroDemoProfile(
      name: 'Nova Kuafor',
      category: 'Kuafor / guzellik',
      status: 'Acik',
      description: 'Randevu, hizmetler ve sosyal medya baglantilari hazir.',
      icon: Icons.content_cut_rounded,
      accentColor: Color(0xFFDB2777),
      badgeIcon: Icons.calendar_month_rounded,
      badgeText: 'Randevu',
      secondaryBadgeIcon: Icons.camera_alt_rounded,
      secondaryBadgeText: 'Instagram',
      actions: [
        HeroDemoAction(Icons.chat_bubble_rounded, Color(0xFF25D366)),
        HeroDemoAction(Icons.camera_alt_rounded, Color(0xFFE1306C)),
      ],
      links: [
        HeroDemoLink(
          'Hizmetler',
          'Kesim, boya ve bakim',
          Icons.spa_rounded,
          Color(0xFFDB2777),
        ),
        HeroDemoLink(
          'Randevu al',
          'WhatsApp ile hizli iletisim',
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
      templateCategoryKey: 'kuafor_guzellik',
    ),
    HeroDemoProfile(
      name: 'TeknoFix',
      category: 'Telefon teknik servis',
      status: 'Acik',
      description: 'Servis talebi, adres ve guvenilir iletisim tek vitrinde.',
      icon: Icons.build_circle_rounded,
      accentColor: Color(0xFF2563EB),
      badgeIcon: Icons.chat_bubble_rounded,
      badgeText: 'WhatsApp',
      secondaryBadgeIcon: Icons.location_on_rounded,
      secondaryBadgeText: 'Konum',
      actions: [
        HeroDemoAction(Icons.chat_bubble_rounded, Color(0xFF25D366)),
        HeroDemoAction(Icons.phone_android_rounded, Color(0xFF2563EB)),
      ],
      links: [
        HeroDemoLink(
          'Servis kaydi',
          'Ekran, batarya ve bakim',
          Icons.construction_rounded,
          Color(0xFF2563EB),
        ),
        HeroDemoLink(
          'Google yorumlari',
          'Musteri guveni',
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
      templateCategoryKey: 'teknik_servis',
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
    _loadCategoryGalleryImages();
  }

  /// Kategori sablonlarindan galeri gorsellerini on-yukle
  /// ve demo profilleri guncelle
  Future<void> _loadCategoryGalleryImages() async {
    setState(() => _isLoadingGalleryImages = true);

    final updatedProfiles = <HeroDemoProfile>[];

    for (final profile in _heroDemoProfiles) {
      final key = profile.templateCategoryKey;
      if (key == null || key.isEmpty) {
        updatedProfiles.add(profile);
        continue;
      }

      try {
        final imageSet = await CategoryImageService.getImagesForCategory(key);
        final urls = imageSet.galleryImages.map((i) => i.imageUrl).toList();
        if (urls.isNotEmpty) {
          _categoryGalleryCache[key] = urls;
          // Profili guncel gorsellerle klonla
          updatedProfiles.add(
            HeroDemoProfile(
              name: profile.name,
              category: profile.category,
              status: profile.status,
              description: profile.description,
              icon: profile.icon,
              accentColor: profile.accentColor,
              badgeIcon: profile.badgeIcon,
              badgeText: profile.badgeText,
              secondaryBadgeIcon: profile.secondaryBadgeIcon,
              secondaryBadgeText: profile.secondaryBadgeText,
              actions: profile.actions,
              links: profile.links,
              coverImageUrl: imageSet.coverImages.isNotEmpty
                  ? imageSet.coverImages.first.imageUrl
                  : profile.coverImageUrl,
              galleryImages: urls.take(3).toList(),
              templateCategoryKey: key,
            ),
          );
          continue;
        }
      } catch (e) {
        debugPrint('Gallery load error for $key: $e');
      }

      // Fallback: orijinal profili koru
      updatedProfiles.add(profile);
    }

    if (mounted) {
      setState(() {
        _heroDemoProfiles = updatedProfiles;
        _isLoadingGalleryImages = false;
      });
    }
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
      // ... mevcut kod devam eder
    } catch (e) {
      debugPrint('Landing saved vitrin check error: $e');
    }
    if (mounted) setState(() => _isCheckingSavedVitrin = false);
  }

  void _navigateToExploreApp() {
    AppRouter.navigateTo(context, AppRoute.authEmail);
  }

  void _navigateToSavedVitrin() {
    // mevcut implementasyon
  }

  void _navigateToPreview() {
    final profile = _heroDemoProfiles[_activeProfileIndex];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PreviewScreen(storeData: profile.toStoreData()),
      ),
    );
  }

  void _navigateToEditor() {
    AppRouter.navigateTo(context, AppRoute.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              LandingHeroSection(
                animController: _animController,
                activeProfileIndex: _activeProfileIndex,
                hasSavedVitrin: _hasSavedVitrin,
                isCheckingSavedVitrin: _isCheckingSavedVitrin,
                storeNameController: _storeNameController,
                heroDemoProfiles: _heroDemoProfiles,
                onNavigateToExploreApp: _navigateToExploreApp,
                onNavigateToSavedVitrin: _navigateToSavedVitrin,
                onNavigateToPreview: _navigateToPreview,
                onNavigateToEditor: _navigateToEditor,
                onStateChanged: () {
                  if (mounted) {
                    setState(() {});
                    _loadSavedVitrinState();
                  }
                },
              ),
              const LandingValueBand(),
              const LandingFeaturesSection(),
              const LandingComparisonSection(),
              const LandingTrustBand(),
              const LandingStepsSection(),
              const LandingBottomCta(),
            ],
          ),
        ),
      ),
      floatingActionButton: const ChatbotOverlay(),
    );
  }
}

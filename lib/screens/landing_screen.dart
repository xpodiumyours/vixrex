import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vitrinx/screens/preview_screen.dart';
import 'package:vitrinx/models/landing_demo_profile.dart';
import 'package:vitrinx/services/category_image_service.dart';
import 'package:vitrinx/theme/app_colors.dart';
import 'package:vitrinx/widgets/landing/landing_hero_section.dart';
import 'package:vitrinx/widgets/landing/landing_value_band.dart';
import 'package:vitrinx/widgets/landing/landing_features_section.dart';
import 'package:vitrinx/widgets/landing/landing_comparison_section.dart';
import 'package:vitrinx/widgets/landing/landing_trust_band.dart';
import 'package:vitrinx/widgets/landing/landing_steps_section.dart';
import 'package:vitrinx/widgets/landing/landing_bottom_cta.dart';
import 'package:vitrinx/widgets/landing/landing_template_catalog.dart';
import 'package:vitrinx/widgets/chatbot_overlay.dart';
import 'package:vitrinx/config/app_router.dart';
import 'package:vitrinx/services/store_local_storage_service.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  int _activeProfileIndex = 0;
  final bool _hasSavedVitrin = false;
  bool _isCheckingSavedVitrin = true;
  final TextEditingController _storeNameController = TextEditingController();

  /// Kategori sablonlarindan yuklenen galeri gorselleri cache'i
  final Map<String, List<String>> _categoryGalleryCache = {};
  // ignore: unused_field
  bool _isLoadingGalleryImages = false;


  static List<HeroDemoProfile> _heroDemoProfiles = [
    HeroDemoProfile(
      name: 'Aymira Giyim',
      category: 'KADIN GİYİM / BUTİK',
      status: 'AÇIK',
      description: 'Yeni sezon reyonları ve mağaza fotoğrafları tek vitrinde.',
      icon: Icons.checkroom_rounded,
      accentColor: const Color(0xFFFF5A1F),
      badgeIcon: Icons.photo_library_rounded,
      badgeText: 'Galeri',
      secondaryBadgeIcon: Icons.qr_code_2_rounded,
      secondaryBadgeText: 'QR kod',
      actions: [
        const HeroDemoAction(Icons.chat_bubble_rounded, Color(0xFF25D366)),
        const HeroDemoAction(Icons.camera_alt_rounded, Color(0xFFE1306C)),
      ],
      links: [
        const HeroDemoLink('Vitrin galerisi', 'Raf ve reyon fotoğrafları', Icons.photo_library_rounded, Color(0xFFFF5A1F)),
        const HeroDemoLink('Trendyol', 'Mağazayı ziyaret edin', Icons.shopping_bag_rounded, Color(0xFFF27A1A)),
      ],
      coverImageUrl: 'https://images.unsplash.com/photo-1441984904996-e0b6ba687e04?auto=format&fit=crop&w=400&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1567401893414-76b7b1e5a7a5?auto=format&fit=crop&w=300&q=80',
        'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?auto=format&fit=crop&w=300&q=80',
        'https://images.unsplash.com/photo-1445205170230-053b83016050?auto=format&fit=crop&w=300&q=80',
        'https://images.unsplash.com/photo-1483985988355-763728e1935b?auto=format&fit=crop&w=300&q=80',
      ],
      templateCategoryKey: 'butik_giyim',
    ),
    HeroDemoProfile(
      name: 'Lezzet Durağı',
      category: 'KAFE / RESTORAN',
      status: 'AÇIK',
      description: 'Menü, konum ve WhatsApp sipariş bilgileri tek ekranda.',
      icon: Icons.restaurant_menu_rounded,
      accentColor: const Color(0xFFEA580C),
      badgeIcon: Icons.menu_book_rounded,
      badgeText: 'Menü',
      secondaryBadgeIcon: Icons.directions_rounded,
      secondaryBadgeText: 'Yol tarifi',
      actions: [
        const HeroDemoAction(Icons.chat_bubble_rounded, Color(0xFF25D366)),
        const HeroDemoAction(Icons.location_on_rounded, Color(0xFFEF4444)),
      ],
      links: [
        const HeroDemoLink('Günün menüsü', 'Sıcak yemek ve tatlılar', Icons.local_dining_rounded, Color(0xFFEA580C)),
        const HeroDemoLink('Paket servis', 'WhatsApp ile sipariş', Icons.delivery_dining_rounded, Color(0xFF10B981)),
      ],
      coverImageUrl: 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&w=400&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=300&q=80',
        'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=300&q=80',
        'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?auto=format&fit=crop&w=300&q=80',
        'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=300&q=80',
      ],
      templateCategoryKey: 'kafe_restoran',
    ),
    HeroDemoProfile(
      name: 'Nova Kuaför',
      category: 'KUAFÖR / GÜZELLİK',
      status: 'AÇIK',
      description: 'Randevu, hizmetler ve sosyal medya bağlantıları hazır.',
      icon: Icons.content_cut_rounded,
      accentColor: const Color(0xFFDB2777),
      badgeIcon: Icons.calendar_month_rounded,
      badgeText: 'Randevu',
      secondaryBadgeIcon: Icons.camera_alt_rounded,
      secondaryBadgeText: 'Instagram',
      actions: [
        const HeroDemoAction(Icons.chat_bubble_rounded, Color(0xFF25D366)),
        const HeroDemoAction(Icons.camera_alt_rounded, Color(0xFFE1306C)),
      ],
      links: [
        const HeroDemoLink('Hizmetler', 'Kesim, boya ve bakım', Icons.spa_rounded, Color(0xFFDB2777)),
        const HeroDemoLink('Randevu al', 'WhatsApp ile hızlı iletişim', Icons.event_available_rounded, Color(0xFF10B981)),
      ],
      coverImageUrl: 'https://images.unsplash.com/photo-1560066984-138dadb4c035?auto=format&fit=crop&w=400&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?auto=format&fit=crop&w=300&q=80',
        'https://images.unsplash.com/photo-1595476108010-b4d1f102b1b1?auto=format&fit=crop&w=300&q=80',
        'https://images.unsplash.com/photo-1634449571010-02389ed0f9b0?auto=format&fit=crop&w=300&q=80',
        'https://images.unsplash.com/photo-1595476108010-b4d1f102b1b1?auto=format&fit=crop&w=300&q=80',
      ],
      templateCategoryKey: 'kuafor_guzellik',
    ),
    HeroDemoProfile(
      name: 'TeknoFix',
      category: 'TELEFON TEKNİK SERVİS',
      status: 'AÇIK',
      description: 'Servis talebi, adres ve güvenilir iletişim tek vitrinde.',
      icon: Icons.build_circle_rounded,
      accentColor: const Color(0xFF2563EB),
      badgeIcon: Icons.chat_bubble_rounded,
      badgeText: 'WhatsApp',
      secondaryBadgeIcon: Icons.location_on_rounded,
      secondaryBadgeText: 'Konum',
      actions: [
        const HeroDemoAction(Icons.chat_bubble_rounded, Color(0xFF25D366)),
        const HeroDemoAction(Icons.phone_android_rounded, Color(0xFF2563EB)),
      ],
      links: [
        const HeroDemoLink('Servis kaydı', 'Ekran, batarya ve bakım', Icons.construction_rounded, Color(0xFF2563EB)),
        const HeroDemoLink('Google yorumları', 'Müşteri güveni', Icons.verified_rounded, Color(0xFF6366F1)),
      ],
      coverImageUrl: 'https://images.unsplash.com/photo-1512499617640-c74ae3a79d37?auto=format&fit=crop&w=400&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1601784551446-20c9e07cdbdb?auto=format&fit=crop&w=300&q=80',
        'https://images.unsplash.com/photo-1545259741-2ea3ebf61fa3?auto=format&fit=crop&w=300&q=80',
        'https://images.unsplash.com/photo-1585771724684-38269d6639fd?auto=format&fit=crop&w=300&q=80',
        'https://images.unsplash.com/photo-1545259741-2ea3ebf61fa3?auto=format&fit=crop&w=300&q=80',
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
    if (mounted) setState(() => _isCheckingSavedVitrin = false);
  }

  void _navigateToExploreApp([String? categoryKey]) async {
    if (categoryKey != null) {
      const storage = StoreLocalStorageService();
      await storage.savePendingCategoryKey(categoryKey);
    }
    AppRouter.navigateToAuth(context);
  }

  void _navigateToSavedVitrin() {}

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
    AppRouter.navigateToHomeShell(context);
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
              // YENI: 12 kategorili hazir sablon katalogu
              LandingTemplateCatalog(
                onNavigateToAuth: (key) => _navigateToExploreApp(key),
              ),
              LandingBottomCta(onNavigateToEditor: _navigateToEditor),
            ],
          ),
        ),
      ),
      floatingActionButton: ChatbotBadge(),
    );
  }
}

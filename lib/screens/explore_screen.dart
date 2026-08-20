import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vixrex/config/app_router.dart';
import 'package:vixrex/controllers/explore_controller.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/repositories/explore_repository.dart';
import 'package:vixrex/services/store_publish_service.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/theme/app_text_styles.dart';
import 'package:vixrex/utils/whatsapp_link_helper.dart';
import 'package:vixrex/widgets/common/app_banner.dart';
import 'package:vixrex/widgets/common/app_empty_state.dart';
import 'package:vixrex/widgets/common/app_screen_scaffold.dart';
import 'package:vixrex/widgets/common/app_skeleton.dart';
import 'package:vixrex/widgets/common/app_tone.dart';
import 'package:vixrex/widgets/explore_store_card_motion.dart';
import 'package:vixrex/widgets/vitrin_store_card.dart';

class ExploreScreen extends StatefulWidget {
  final ExploreRepository? repository;

  /// Onboarding'in "Hazır Vitrin Seç" akışından açıldı mı — yalnız kiralık
  /// şablonlar gösterilir, başlık/altyazı değişir, altta "Uygun olan yok"
  /// çıkışı eklenir. `false` ise bu ekran her zamanki Keşfet sekmesidir.
  final bool onlyRentalTemplates;

  /// [onlyRentalTemplates] iken: kullanıcı hiçbir hazır şablonu beğenmedi,
  /// sıfırdan oluşturma yoluna dönmek istiyor. `onlyRentalTemplates` false
  /// iken kullanılmaz.
  final VoidCallback? onNoneMatch;

  const ExploreScreen({
    super.key,
    this.repository,
    this.onlyRentalTemplates = false,
    this.onNoneMatch,
  });

  @override
  State<ExploreScreen> createState() => ExploreScreenState();
}

class ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final ExploreController _controller;
  bool _isControllerInitialized = false;

  // KALDIRILDI: ekrana özel renk sabitleri (primaryColor, bgColor, cardBorder,
  // inputBg, darkText, mutedText, softText). Bu ekran paletin ikinci bir
  // kopyasını tutuyordu; artık doğrudan AppColors kullanılıyor.

  // Template group labels for the top-level filter
  static const List<String> _templateGroupLabels = [
    'Tümü',
    'Perakende',
    'Hizmet',
    'Gıda',
    'Diğer',
  ];

  @override
  void initState() {
    super.initState();
    _initController();
    _searchController.addListener(() {
      if (_isControllerInitialized) {
        _controller.setSearchQuery(_searchController.text);
      }
    });
  }

  Future<void> _initController() async {
    final repository =
        widget.repository ??
        ExploreRepository(
          sharedPreferences: await SharedPreferences.getInstance(),
        );
    _controller = ExploreController(
      repository: repository,
      onlyRentalTemplates: widget.onlyRentalTemplates,
    );
    await _controller.initialize();
    if (mounted) {
      setState(() {
        _isControllerInitialized = true;
      });
    }
  }

  /// Shell sidebar / global arama — Keşfet sekmesine query uygular.
  void applyExternalSearch(String query) {
    _searchController.text = query;
    _searchController.selection = TextSelection.collapsed(offset: query.length);
    if (_isControllerInitialized) {
      _controller.setSearchQuery(query);
    }
  }

  Future<void> reloadStores() async {
    if (!_isControllerInitialized) return;
    await _controller.reloadStores();
  }

  @override
  void dispose() {
    if (_isControllerInitialized) {
      _controller.dispose();
    }
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openWhatsApp(String whatsappNumber, String message) async {
    final url = WhatsAppLinkHelper.buildCustomUrl(
      number: whatsappNumber,
      message: message,
    );
    if (url == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Geçerli bir WhatsApp numarası bulunamadı.'),
        ),
      );
      return;
    }
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp uygulaması açılamadı!')),
      );
    }
  }

  void _showWhatsAppBottomSheet(StoreData store) {
    // backgroundColor / shape verilmiyor — bottomSheetTheme'den geliyor.
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final storeName =
            store.name.trim().isEmpty
                ? 'vitrininiz'
                : '${store.name.trim()} vitrininiz';
        final options = <({String label, String message})>[
          (
            label: 'Ürün ve fiyat bilgisi',
            message:
                'Merhaba, $storeName hakkında ürün ve fiyat bilgisi almak istiyorum.',
          ),
          (
            label: 'Sipariş vermek istiyorum',
            message: 'Merhaba, $storeName üzerinden sipariş vermek istiyorum.',
          ),
          (
            label: 'Adres ve çalışma saatleri',
            message:
                'Merhaba, $storeName için adres ve çalışma saatlerini öğrenmek istiyorum.',
          ),
        ];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppColors.spacing24,
              AppColors.spacing8,
              AppColors.spacing24,
              AppColors.spacing24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        // WhatsApp marka rengi — üçüncü taraf, palet dışı
                        // kalması bilinçli.
                        color: const Color(0xFF25D366).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chat_bubble_rounded,
                        color: Color(0xFF25D366),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppColors.spacing12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(store.name, style: AppTextStyles.subTitle),
                          const SizedBox(height: 2),
                          const Text(
                            'Hazır mesaj seçin:',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppColors.spacing20),
                ...options.map((option) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _openWhatsApp(store.whatsapp, option.message);
                      },
                      // side / shape / textStyle verilmiyor —
                      // outlinedButtonTheme'den geliyor.
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppColors.spacing16,
                          vertical: AppColors.spacing16,
                        ),
                        alignment: Alignment.centerLeft,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              option.label,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppColors.spacing12),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12,
                            color: AppColors.mutedText,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.onlyRentalTemplates ? 'Hazır Vitrin Seç' : "Vixrex'leri Keşfet";

    if (!_isControllerInitialized) {
      return AppScreenScaffold(
        title: title,
        padding: EdgeInsets.zero,
        body: _buildSkeletonGrid(),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final stores = _controller.filteredStores;

        // AppBar başlığı ve zemin AppScreenScaffold'dan; ekran kendi
        // TextStyle'ını yazmıyor.
        return AppScreenScaffold(
          title: title,
          padding: EdgeInsets.zero,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppColors.spacing24,
                  0,
                  AppColors.spacing24,
                  AppColors.spacing12,
                ),
                child: Text(
                  widget.onlyRentalTemplates
                      ? 'Beğendiğini kirala, kendi vitrinin olsun'
                      : 'Yayındaki tüm Vixrex vitrinlerini inceleyin',
                  style: AppTextStyles.caption,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppColors.spacing24,
                  0,
                  AppColors.spacing24,
                  AppColors.spacing12,
                ),
                child: TextField(
                  controller: _searchController,
                  // fillColor / border / hintStyle verilmiyor —
                  // inputDecorationTheme'den geliyor.
                  decoration: InputDecoration(
                    hintText: 'Vitrin, ürün veya il/ilçe ara',
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    suffixIcon:
                        _searchController.text.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                _controller.setSearchQuery('');
                              },
                            )
                            : null,
                  ),
                ),
              ),
              _buildTemplateGroupFilterBar(),
              _buildFilterBar(),
              if (_controller.loadErrorMessage != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppColors.spacing24,
                    AppColors.spacing12,
                    AppColors.spacing24,
                    0,
                  ),
                  child: AppBanner(
                    tone: AppTone.danger,
                    title: 'Vitrinler yüklenemedi',
                    message: _controller.loadErrorMessage,
                    actionLabel: 'Tekrar dene',
                    onAction: () => _controller.reloadStores(),
                  ),
                ),
              Expanded(
                child:
                    _controller.isLoading
                        ? _buildSkeletonGrid()
                        : stores.isEmpty
                        ? _buildEmptyState()
                        : _buildStoreGrid(stores),
              ),
              if (widget.onlyRentalTemplates && widget.onNoneMatch != null)
                _buildNoneMatchBar(),
            ],
          ),
        );
      },
    );
  }

  /// "Hazır Vitrin Seç" modunda çıkış yolu — hiçbir şablon uymadıysa sıfırdan
  /// oluşturma sohbetine geri döner (bkz. vixrex_onboarding_controller.dart
  /// chooseScratch).
  Widget _buildNoneMatchBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppColors.spacing24,
          AppColors.spacing8,
          AppColors.spacing24,
          AppColors.spacing12,
        ),
        child: OutlinedButton(
          onPressed: widget.onNoneMatch,
          child: const Text('Uygun olan yok, sıfırdan oluştur'),
        ),
      ),
    );
  }

  /// Şablon grubu filtre çubuğu — 4 ana grup
  Widget _buildTemplateGroupFilterBar() {
    return SizedBox(
      height: 52,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppColors.spacing20,
          vertical: AppColors.spacing4,
        ),
        children:
            _templateGroupLabels.map((group) {
              final isSelected = _controller.selectedTemplateGroup == group;
              return Padding(
                padding: const EdgeInsets.only(right: AppColors.spacing8),
                child: ChoiceChip(
                  selected: isSelected,
                  label: Text(group),
                  onSelected: (val) {
                    if (val) _controller.setTemplateGroup(group);
                  },
                ),
              );
            }).toList(),
      ),
    );
  }

  /// Kategori filtre çubuğu — templateGroup'a göre filtrelenmiş kategoriler
  Widget _buildFilterBar() {
    return SizedBox(
      height: 52,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppColors.spacing20,
          vertical: AppColors.spacing4,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: AppColors.spacing8),
            child: FilterChip(
              selected: _controller.onlyFavorites,
              onSelected: _controller.setOnlyFavorites,
              avatar: Icon(
                _controller.onlyFavorites
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                size: 14,
                color:
                    _controller.onlyFavorites
                        ? AppColors.onPrimary
                        : AppColors.error,
              ),
              label: const Text('Favorilerim'),
            ),
          ),
          ..._controller.filteredCategories.map((category) {
            final categoryLabel = category.label;
            final isSelected = _controller.selectedCategory == categoryLabel;
            return Padding(
              padding: const EdgeInsets.only(right: AppColors.spacing8),
              child: ChoiceChip(
                selected: isSelected,
                label: Text(categoryLabel),
                onSelected: (val) {
                  if (val) _controller.setCategory(categoryLabel);
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Grid sütun ve kart yüksekliği kuralı değişmedi.
  ({int columns, double cardHeight}) _gridMetrics(double width) {
    final columns =
        width >= 1000
            ? 4
            : width >= 700
            ? 3
            : 2;
    final cardHeight =
        columns == 2
            ? 280.0
            : columns == 3
            ? 305.0
            : 320.0;
    return (columns: columns, cardHeight: cardHeight);
  }

  Widget _buildStoreGrid(List<StoreData> stores) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = _gridMetrics(constraints.maxWidth);
        return GridView.builder(
          padding: const EdgeInsets.all(AppColors.spacing12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: metrics.columns,
            crossAxisSpacing: AppColors.spacing12,
            mainAxisSpacing: AppColors.spacing12,
            mainAxisExtent: metrics.cardHeight,
          ),
          itemCount: stores.length,
          itemBuilder: (context, index) {
            final store = stores[index];
            return ExploreStoreCardMotion(
              index: index,
              child: VitrinStoreCard(
                store: store,
                isExample: _controller.showingExampleStores,
                isFavorited: _controller.isFavorite(store),
                isOwnStore: _controller.isOwnStore(store),
                // Premium bilgisi yalnız KENDİ vitrininde taşınır — başkasının
                // vitrinine asla sızmaz (PR #6).
                premiumStatus:
                    _controller.isOwnStore(store)
                        ? _controller.ownStorePremium
                        : null,
                onTap: () {
                  final slug =
                      store.slug.isNotEmpty
                          ? store.slug
                          : const StorePublishPayloadBuilder().generateSlug(
                            store.name,
                          );
                  AppRouter.navigateToPublicVitrin(context, slug);
                },
                onFavoritePressed:
                    () => _controller.toggleFavorite(store.name),
                onWhatsAppPressed: () => _showWhatsAppBottomSheet(store),
                onRentPressed:
                    store.isRentalTemplate
                        ? () => AppRouter.navigateToRentDemo(
                          context,
                          store.slug.isNotEmpty
                              ? store.slug
                              : const StorePublishPayloadBuilder().generateSlug(
                                store.name,
                              ),
                        )
                        : null,
              ),
            );
          },
        );
      },
    );
  }

  /// Yükleme — ortada dönen halka yerine gelecek düzenin iskeleti.
  Widget _buildSkeletonGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = _gridMetrics(constraints.maxWidth);
        return GridView.builder(
          padding: const EdgeInsets.all(AppColors.spacing12),
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: metrics.columns,
            crossAxisSpacing: AppColors.spacing12,
            mainAxisSpacing: AppColors.spacing12,
            mainAxisExtent: metrics.cardHeight,
          ),
          itemCount: metrics.columns * 2,
          itemBuilder: (context, index) => AppSkeleton.card(),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final hasError = _controller.loadErrorMessage != null;
    if (hasError) {
      return AppEmptyState(
        icon: Icons.wifi_off_rounded,
        title: 'Vitrinler şu an yüklenemedi',
        message: 'Bağlantınızı kontrol edip tekrar deneyin.',
        actionLabel: 'Tekrar dene',
        onAction: () => _controller.reloadStores(),
      );
    }
    if (_controller.onlyFavorites) {
      return AppEmptyState(
        icon: Icons.favorite_border_rounded,
        title: 'Favorilere ekli vitrin yok',
        message: 'Beğendiğiniz vitrinleri kalp simgesiyle kaydedin.',
        actionLabel: 'Tüm vitrinleri gör',
        onAction: () => _controller.setOnlyFavorites(false),
      );
    }
    return AppEmptyState(
      icon: Icons.storefront_rounded,
      title: 'Aramanızla eşleşen vitrin yok',
      message: 'Farklı bir kelime deneyin veya filtreleri temizleyin.',
      actionLabel: 'Filtreleri temizle',
      onAction: () {
        _searchController.clear();
        _controller.setSearchQuery('');
        _controller.setCategory('Tümü');
      },
    );
  }
}

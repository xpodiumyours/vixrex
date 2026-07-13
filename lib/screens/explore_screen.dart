import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vixrex/config/business_category_config.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/store_publish_service.dart';
import 'package:vixrex/utils/whatsapp_link_helper.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/repositories/explore_repository.dart';
import 'package:vixrex/controllers/explore_controller.dart';
import 'package:vixrex/widgets/vitrin_store_card.dart';
import 'package:vixrex/config/app_router.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => ExploreScreenState();
}

class ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final ExploreController _controller;
  bool _isControllerInitialized = false;

  // Theme Colors from AppColors
  static const Color primaryColor = AppColors.primary;
  static const Color bgColor = AppColors.bgEditor;
  static const Color cardBorder = AppColors.border;
  static const Color inputBg = AppColors.inputBg;
  static const Color darkText = AppColors.darkText;
  static const Color mutedText = AppColors.mutedText;
  static const Color softText = AppColors.softText;

  final List<String> _categories = [
    'Tümü',
    ...BusinessCategoryConfig.categories.map((c) => c.label),
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
    final prefs = await SharedPreferences.getInstance();
    final repository = ExploreRepository(sharedPreferences: prefs);
    _controller = ExploreController(repository: repository);
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
          behavior: SnackBarBehavior.floating,
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
        const SnackBar(
          content: Text('WhatsApp uygulaması açılamadı!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showWhatsAppBottomSheet(StoreData store) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chat_bubble_rounded,
                      color: Color(0xFF25D366),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: darkText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Hazır mesaj seçin:',
                          style: TextStyle(fontSize: 12, color: mutedText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...options.map((option) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _openWhatsApp(store.whatsapp, option.message);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      side: const BorderSide(color: cardBorder, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.centerLeft,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            option.label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: softText,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: mutedText,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isControllerInitialized) {
      return const Scaffold(
        backgroundColor: bgColor,
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final stores = _controller.filteredStores;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            title: const Text(
              "Vixrex'leri Keşfet",
              style: TextStyle(
                color: darkText,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
            backgroundColor: bgColor,
            elevation: 0,
            iconTheme: const IconThemeData(color: darkText),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _controller.reloadStores,
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header / Subtitle
                Container(
                  color: bgColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: const Text(
                    'Yayındaki Vixrex profillerini keşfet',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: mutedText,
                    ),
                  ),
                ),
                // Search Input
                Container(
                  color: bgColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Vitrin, ürün veya kategori ara...',
                      hintStyle: TextStyle(
                        color: mutedText.withValues(alpha: 0.6),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: mutedText,
                        size: 20,
                      ),
                      suffixIcon:
                          _searchController.text.isNotEmpty
                              ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  _controller.setSearchQuery('');
                                },
                              )
                              : null,
                      filled: true,
                      fillColor: inputBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: darkText,
                    ),
                  ),
                ),
                // Filter Categories Bar
                Container(
                  height: 52,
                  color: bgColor,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    children: [
                      // Favorites Filter Chip
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          selected: _controller.onlyFavorites,
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _controller.onlyFavorites
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: 14,
                                color:
                                    _controller.onlyFavorites
                                        ? Colors.white
                                        : Colors.redAccent,
                              ),
                              const SizedBox(width: 4),
                              const Text('Favorilerim'),
                            ],
                          ),
                          labelStyle: TextStyle(
                            color:
                                _controller.onlyFavorites
                                    ? Colors.white
                                    : darkText,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          selectedColor: primaryColor,
                          checkmarkColor: Colors.white,
                          backgroundColor: bgColor,
                          onSelected: (val) {
                            _controller.setOnlyFavorites(val);
                          },
                        ),
                      ),
                      ..._categories.map((category) {
                        final isSelected =
                            _controller.selectedCategory == category;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            selected: isSelected,
                            label: Text(category),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : darkText,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            selectedColor: primaryColor,
                            backgroundColor: bgColor,
                            onSelected: (val) {
                              if (val) {
                                _controller.setCategory(category);
                              }
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                // Divider
                Container(height: 1, color: cardBorder),
                if (_controller.loadErrorMessage != null)
                  _buildLoadWarning(_controller.loadErrorMessage!),
                // Grid List
                Expanded(
                  child:
                      _controller.isLoading
                          ? const Center(
                            child: CircularProgressIndicator(
                              color: primaryColor,
                            ),
                          )
                          : stores.isEmpty
                          ? _buildEmptyState()
                          : LayoutBuilder(
                            builder: (context, constraints) {
                              final width = constraints.maxWidth;
                              // Masaüstü için daha kompakt grid
                              final columnCount =
                                  width >= 1000
                                      ? 4
                                      : width >= 700
                                      ? 3
                                      : 2;
                              final cardHeight =
                                  columnCount == 2
                                      ? 220.0
                                      : columnCount == 3
                                      ? 240.0
                                      : 260.0;

                              return GridView.builder(
                                padding: const EdgeInsets.all(12),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: columnCount,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                      mainAxisExtent: cardHeight,
                                    ),
                                itemCount: stores.length,
                                itemBuilder: (context, index) {
                                  final store = stores[index];
                                  return VitrinStoreCard(
                                    store: store,
                                    isExample:
                                        _controller.showingExampleStores,
                                    isFavorited: _controller.isFavorite(
                                      store,
                                    ),
                                    isOwnStore: _controller.isOwnStore(
                                      store,
                                    ),
                                    onTap: () {
                                      final slug =
                                          store.slug.isNotEmpty
                                              ? store.slug
                                              : const StorePublishPayloadBuilder()
                                                  .generateSlug(store.name);
                                      AppRouter.navigateToPublicVitrin(
                                        context,
                                        slug,
                                      );
                                    },
                                    onFavoritePressed:
                                        () => _controller.toggleFavorite(
                                          store.name,
                                        ),
                                    onWhatsAppPressed:
                                        () =>
                                            _showWhatsAppBottomSheet(store),
                                  );
                                },
                              );
                            },
                          ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadWarning(String message) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE8D9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor, width: 1.4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 22,
            color: primaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF9A3412),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _controller.reloadStores(),
            child: const Text(
              'Tekrar dene',
              style: TextStyle(
                color: Color(0xFF9A3412),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasError = _controller.loadErrorMessage != null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasError
                  ? Icons.wifi_off_rounded
                  : Icons.storefront_rounded,
              size: 48,
              color: mutedText,
            ),
            const SizedBox(height: 12),
            Text(
              hasError
                  ? 'Vitrinler şu an yüklenemedi.'
                  : _controller.onlyFavorites
                      ? 'Favorilere ekli vitrin bulunamadı.'
                      : 'Aramanızla eşleşen vitrin bulunamadı.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: mutedText,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (hasError) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _controller.reloadStores(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Tekrar dene'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/screens/public_vitrin_screen.dart';
import 'package:vitrinx/services/local_storage_keys.dart';
import 'package:vitrinx/services/store_publish_payload_builder.dart';
import 'package:vitrinx/utils/whatsapp_link_helper.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<StoreData> _allStores = [];
  bool _isLoading = true;
  String? _loadErrorMessage;
  String _selectedCategory = 'Tümü';
  bool _onlyFavorites = false;
  bool _showingExampleStores = false;
  List<String> _favoritedStoreNames = [];

  // Theme Colors
  static const Color primaryColor = Color(0xFFFF4D00);
  static const Color bgColor = Color(0xFFF6F8FC);
  static const Color cardBorder = Color.fromRGBO(15, 23, 42, 0.10);
  static const Color inputBg = Color(0xFFF1F5F9);
  static const Color darkText = Color(0xFF111827);
  static const Color mutedText = Color(0xFF64748B);
  static const Color softText = Color(0xFF334155);

  final List<String> _categories = const [
    'Tümü',
    'Giyim & Butik',
    'Gıda & Fırın',
    'Kozmetik',
    'Dekorasyon',
    'Elektronik',
    'Kırtasiye',
    'Diğer',
  ];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _loadStores();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favoritedStoreNames = prefs.getStringList('favorite_stores') ?? [];
    });
  }

  Future<void> _toggleFavorite(String storeName) async {
    final prefs = await SharedPreferences.getInstance();
    final updated = List<String>.from(_favoritedStoreNames);
    if (updated.contains(storeName)) {
      updated.remove(storeName);
    } else {
      updated.add(storeName);
    }
    await prefs.setStringList('favorite_stores', updated);
    setState(() {
      _favoritedStoreNames = updated;
    });
  }

  String? _localPublishedSlug;

  Future<void> _loadStores() async {
    setState(() {
      _isLoading = true;
      _loadErrorMessage = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      _localPublishedSlug = prefs.getString(LocalStorageKeys.lastPublishedSlug);

      final client = Supabase.instance.client;
      debugPrint('[Explore] Supabase stores sorgusu başlıyor...');
      final response = await client
          .from('stores')
          .select()
          .eq('is_published', true);

      final List<dynamic> data = response as List<dynamic>;
      debugPrint(
        '[Explore] Supabase stores sorgusu başarılı. Kayıt sayısı: ${data.length}',
      );
      setState(() {
        final List<StoreData> loadedStores =
            data.map((json) => StoreData.fromJson(json)).toList();
        if (_localPublishedSlug != null && _localPublishedSlug!.isNotEmpty) {
          final int index = loadedStores.indexWhere(
            (store) => store.slug == _localPublishedSlug,
          );
          if (index != -1) {
            final ownStore = loadedStores.removeAt(index);
            loadedStores.insert(0, ownStore);
          }
        }
        _allStores = loadedStores;
        _showingExampleStores = false;
        _isLoading = false;
      });
    } on PostgrestException catch (e) {
      debugPrint('[Explore] Supabase PostgrestException:');
      debugPrint('  code   : ${e.code}');
      debugPrint('  message: ${e.message}');
      debugPrint('  details: ${e.details}');
      debugPrint('  hint   : ${e.hint}');
      setState(() {
        _allStores = _getMockStores();
        _showingExampleStores = true;
        _loadErrorMessage =
            'Canlı vitrinler yüklenemedi. Aşağıdaki kartlar tıklanamayan örneklerdir.';
        _isLoading = false;
      });
    } catch (e) {
      // Handle Supabase not initialized or connection error (e.g. in tests)
      debugPrint('[Explore] VitrinX listesi yüklenemedi: $e');
      setState(() {
        _allStores = _getMockStores();
        _showingExampleStores = true;
        _loadErrorMessage =
            'Canlı vitrinler yüklenemedi. Aşağıdaki kartlar tıklanamayan örneklerdir.';
        _isLoading = false;
      });
    }
  }

  List<StoreData> _getMockStores() {
    return [
      StoreData(
        name: 'Aymira Giyim',
        description:
            'Sezonun en trend kadın kıyafetleri ve tasarım kombinleri.',
        kategori: 'Giyim & Butik',
        businessType: 'Giyim & Butik',
        whatsapp: '0555 123 45 67',
        address: 'Bahariye Cad. No:12, Kadıköy, İstanbul',
        slug: 'aymira-giyim',
        shelfImageUrl:
            'https://images.unsplash.com/photo-1567401893414-76b7b1e5a7a5?auto=format&fit=crop&w=500&q=80',
        isStore: true,
      ),
      StoreData(
        name: 'Lezzet Durağı',
        description:
            'Taze kahveler, kruvasanlar ve el yapımı ekşi mayalı ekmekler.',
        kategori: 'Gıda & Fırın',
        businessType: 'Gıda & Fırın',
        whatsapp: '0555 234 56 78',
        address: 'Şair Nedim Cad. No:45, Beşiktaş, İstanbul',
        slug: 'lezzet-duragi',
        shelfImageUrl:
            'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=500&q=80',
        isStore: true,
      ),
      StoreData(
        name: 'Elit Aksesuar',
        description: 'Özel tasarım takılar ve şık gümüş aksesuarlar vitrini.',
        kategori: 'Dekorasyon',
        businessType: 'Dekorasyon',
        whatsapp: '0555 345 67 89',
        address: 'Moda Cad. No:89, Kadıköy, İstanbul',
        slug: 'elit-aksesuar',
        shelfImageUrl:
            'https://images.unsplash.com/photo-1441984904996-e0b6ba687e04?auto=format&fit=crop&w=500&q=80',
        isStore: false,
      ),
    ];
  }

  List<StoreData> get _filteredStores {
    final query = _searchController.text.toLowerCase().trim();
    return _allStores.where((store) {
      // 1. Category filter
      if (_selectedCategory != 'Tümü' && store.kategori != _selectedCategory) {
        return false;
      }
      // 2. Favorites filter
      if (_onlyFavorites && !_favoritedStoreNames.contains(store.name)) {
        return false;
      }
      // 3. Search query filter
      if (query.isNotEmpty) {
        final matchName = store.name.toLowerCase().contains(query);
        final matchDesc = store.description.toLowerCase().contains(query);
        final matchCat = store.kategori.toLowerCase().contains(query);
        return matchName || matchDesc || matchCat;
      }
      return true;
    }).toList();
  }

  Future<void> _openWhatsApp(String whatsappNumber, String message) async {
    final normalizedNumber = WhatsAppLinkHelper.normalizeTurkeyMobile(
      whatsappNumber,
    );
    if (normalizedNumber == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Geçerli bir WhatsApp numarası bulunamadı.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final encodedMessage = Uri.encodeComponent(message);
    final url = 'https://wa.me/$normalizedNumber?text=$encodedMessage';
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
            store.name.trim().isEmpty ? 'vitrininiz' : '${store.name.trim()} vitrininiz';
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
    final stores = _filteredStores;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          "VitrinX'leri Keşfet",
          style: TextStyle(
            color: darkText,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: darkText),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadStores,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header / Subtitle
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: const Text(
                'Yayındaki VitrinX profillerini keşfet',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: mutedText,
                ),
              ),
            ),
            // Search Input
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                            onPressed: () => _searchController.clear(),
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
              color: Colors.white,
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
                      selected: _onlyFavorites,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _onlyFavorites
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 14,
                            color:
                                _onlyFavorites
                                    ? Colors.white
                                    : Colors.redAccent,
                          ),
                          const SizedBox(width: 4),
                          const Text('Favorilerim'),
                        ],
                      ),
                      labelStyle: TextStyle(
                        color: _onlyFavorites ? Colors.white : darkText,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      selectedColor: primaryColor,
                      checkmarkColor: Colors.white,
                      backgroundColor: bgColor,
                      onSelected: (val) {
                        setState(() => _onlyFavorites = val);
                      },
                    ),
                  ),
                  ..._categories.map((category) {
                    final isSelected = _selectedCategory == category;
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
                            setState(() => _selectedCategory = category);
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
            if (_loadErrorMessage != null) _buildLoadWarning(),
            // Grid List
            Expanded(
              child:
                  _isLoading
                      ? const Center(
                        child: CircularProgressIndicator(color: primaryColor),
                      )
                      : stores.isEmpty
                      ? _buildEmptyState()
                      : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.72,
                            ),
                        itemCount: stores.length,
                        itemBuilder: (context, index) {
                          return _buildStoreCard(
                            stores[index],
                            isExample: _showingExampleStores,
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadWarning() {
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
          const Icon(Icons.warning_amber_rounded, size: 22, color: primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _loadErrorMessage!,
              style: const TextStyle(
                color: Color(0xFF9A3412),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.storefront_rounded, size: 48, color: mutedText),
          const SizedBox(height: 12),
          Text(
            _onlyFavorites
                ? 'Favorilere ekli vitrin bulunamadı.'
                : 'Aramanızla eşleşen vitrin bulunamadı.',
            style: const TextStyle(
              fontSize: 14,
              color: mutedText,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreCard(StoreData store, {required bool isExample}) {
    final isFavorited = _favoritedStoreNames.contains(store.name);
    final hasImage = store.shelfImageUrl.isNotEmpty;
    final isOwnStore =
        _localPublishedSlug != null &&
        _localPublishedSlug!.isNotEmpty &&
        store.slug == _localPublishedSlug;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side:
            isOwnStore
                ? const BorderSide(color: Color(0xFFFF4D00), width: 2.5)
                : const BorderSide(color: cardBorder, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      child: InkWell(
        onTap:
            isExample
                ? null
                : () {
                  final slug =
                      store.slug.isNotEmpty
                          ? store.slug
                          : const StorePublishPayloadBuilder().generateSlug(
                            store.name,
                          );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PublicVitrinScreen(slug: slug),
                    ),
                  );
                },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Shelf image or placeholder
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasImage)
                    Image.network(
                      store.shelfImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) =>
                              _buildImagePlaceholder(),
                    )
                  else
                    _buildImagePlaceholder(),
                  // Kategori ve Tip badge on image
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'VitrinX${store.kategori.isNotEmpty ? " • ${store.kategori}" : ""}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (isExample)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: primaryColor),
                        ),
                        child: const Text(
                          'Örnek',
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  if (isOwnStore)
                    Positioned(
                      bottom: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4D00),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: Colors.white,
                              size: 12,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Senin vitrinin',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Favorite button
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          isFavorited
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 18,
                          color: isFavorited ? Colors.redAccent : mutedText,
                        ),
                        onPressed: () => _toggleFavorite(store.name),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info content
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: darkText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      store.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: mutedText,
                        height: 1.3,
                      ),
                    ),
                    const Spacer(),
                    // Action Buttons (WhatsApp)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            store.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: softText,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.chat_bubble_rounded,
                              color: Color(0xFF25D366),
                              size: 18,
                            ),
                            onPressed: () => _showWhatsAppBottomSheet(store),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFEBE3), Color(0xFFFFF2EC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.storefront_outlined, color: primaryColor, size: 32),
      ),
    );
  }
}

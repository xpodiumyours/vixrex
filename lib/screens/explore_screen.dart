import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/screens/public_vitrin_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _storyPulseController;
  final TextEditingController _searchController = TextEditingController();
  
  String _selectedCategory = 'Tümü';
  String _selectedNeighborhood = 'Tüm İstanbul';
  bool _onlyFavorites = false;
  List<String> _favoritedStoreNames = [];
  
  // Custom layout column counts
  static const double _gridSpacing = 12.0;

  // Modern Color Palette
  static const Color brandOrange = Color(0xFFFF5A1F);
  static const Color darkAccent = Color(0xFF0F172A);
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color softText = Color(0xFF334155);
  static const Color mutedText = Color(0xFF64748B);
  
  static const List<String> _categories = [
    'Tümü',
    'Giyim & Butik',
    'Kafe & Gıda',
    'Kuaför & Güzellik',
    'Teknoloji & Servis',
    'Diğer'
  ];

  static const List<String> _neighborhoods = [
    'Tüm İstanbul',
    'Kadıköy',
    'Beşiktaş',
    'Şişli',
    'Üsküdar'
  ];

  late final List<StoreData> _mockStores;
  late final List<ExplorePost> _allPosts;

  @override
  void initState() {
    super.initState();
    _storyPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _initializeMockData();
    _loadFavorites();
  }

  @override
  void dispose() {
    _storyPulseController.dispose();
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

  void _initializeMockData() {
    // We construct 7 rich local businesses
    _mockStores = [
      StoreData(
        name: 'Aymira Giyim',
        businessType: 'Giyim & Butik',
        description: 'Sezonun en trend kadın kıyafetleri ve tasarım kombinleri.',
        whatsapp: '0555 123 45 67',
        instagram: '@aymiragiyim',
        website: 'aymiragiyim.com',
        address: 'Bahariye Cad. No:12, Kadıköy, İstanbul',
        theme: 'Sade',
        status: 'Açık',
        isEsnafMode: true,
        corporateBio: 'Aymira Giyim, Kadıköy Bahariye\'de 10 yılı aşkın süredir butik giyim hizmeti vermektedir. Günlük kombinler, spor şıklık ve abiye modellerimizle raflarımızı her hafta yeniliyoruz.',
        galleryItems: [
          StoreGalleryItem(
            id: 'aymira_1',
            imageUrl: 'https://images.unsplash.com/photo-1567401893414-76b7b1e5a7a5?auto=format&fit=crop&w=500&q=80',
            title: 'Yazlık Keten Elbise Serisi',
            description: 'Nefes alan keten dokulu, farklı pastel renk seçenekleriyle raflarda.',
          ),
          StoreGalleryItem(
            id: 'aymira_2',
            imageUrl: 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?auto=format&fit=crop&w=500&q=80',
            title: 'Özel Tasarım Kruvaze Ceket Kombini',
            description: 'Hem ofis hem günlük şıklığa uygun yeni sezon kruvaze ceketler.',
          ),
          StoreGalleryItem(
            id: 'aymira_3',
            imageUrl: 'https://images.unsplash.com/photo-1445205170230-053b83016050?auto=format&fit=crop&w=500&q=80',
            title: 'Aksesuar ve Çanta Standı',
            description: 'Tarzınızı tamamlayacak deri çantalar ve özel tasarım kolyeler.',
          ),
        ],
      ),
      StoreData(
        name: 'Lezzet Durağı',
        businessType: 'Kafe & Gıda',
        description: 'Taze kahveler, kruvasanlar ve el yapımı ekşi mayalı ekmekler.',
        whatsapp: '0555 234 56 78',
        instagram: '@lezzetduragi_cafe',
        website: 'lezzetduragi.cafe',
        address: 'Şair Nedim Cad. No:45, Beşiktaş, İstanbul',
        theme: 'Güneş',
        status: 'Bugün kampanya var',
        isEsnafMode: true,
        corporateBio: 'Fırınımızdan çıkan taze sıcak kruvasan kokusuyla Beşiktaş sokaklarını şenlendiriyoruz. Nitelikli kahve çekirdeklerimiz ve ev yapımı tatlılarımızla sizleri bekliyoruz.',
        galleryItems: [
          StoreGalleryItem(
            id: 'lezzet_1',
            imageUrl: 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=500&q=80',
            title: 'Taze Çilekli ve Çikolatalı Kruvasan',
            description: 'Her sabah saat 08:00\'de sıcak ve taze olarak servis edilir.',
          ),
          StoreGalleryItem(
            id: 'lezzet_2',
            imageUrl: 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=500&q=80',
            title: 'Barista Özel Filtre Kahve Çeşitleri',
            description: 'Etiyopya ve Kolombiya çekirdeklerinden taze demlenmiş V60 kahveler.',
          ),
        ],
      ),
      StoreData(
        name: 'Nova Kuaför',
        businessType: 'Kuaför & Güzellik',
        description: 'Saç tasarımı, renklendirme ve profesyonel cilt bakımı.',
        whatsapp: '0555 345 67 89',
        instagram: '@novakuafor_sisli',
        address: 'Halaskargazi Cad. No:110, Şişli, İstanbul',
        theme: 'Zarif',
        status: 'Yeni ürünler geldi',
        isEsnafMode: true,
        corporateBio: 'Nova Kuaför, Şişli\'de modern saç tasarımları, profesyonel boyama teknikleri ve dünya markası saç bakım kürleri ile hizmet vermektedir.',
        galleryItems: [
          StoreGalleryItem(
            id: 'nova_1',
            imageUrl: 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?auto=format&fit=crop&w=500&q=80',
            title: 'Doğal Işıltılı Ombre Uygulaması',
            description: 'Saçı yıpratmadan yapılan özel renk geçişli ombre tasarımlarımız.',
          ),
          StoreGalleryItem(
            id: 'nova_2',
            imageUrl: 'https://images.unsplash.com/photo-1595476108010-b4d1f102b1b1?auto=format&fit=crop&w=500&q=80',
            title: 'Profesyonel Saç Botoksu & Bakım',
            description: 'Kuru ve yıpranmış saçlar için amino asit ve keratin yüklemeli canlandırma kürü.',
          ),
        ],
      ),
      StoreData(
        name: 'TeknoFix',
        businessType: 'Teknoloji & Servis',
        description: 'Telefon teknik servis, kılıf standı ve aksesuar çeşitleri.',
        whatsapp: '0555 456 78 90',
        instagram: '@teknofix_uskudar',
        address: 'Hakimiyeti Milliye Cad. No:82, Üsküdar, İstanbul',
        theme: 'Premium',
        status: 'Açık',
        isEsnafMode: true,
        corporateBio: 'TeknoFix Üsküdar şubemizde, hızlı ekran ve batarya değişim hizmetleri sunuyoruz. Tüm onarımlarımız 6 ay garantilidir. Ayrıca en trend kılıflar burada!',
        galleryItems: [
          StoreGalleryItem(
            id: 'tekno_1',
            imageUrl: 'https://images.unsplash.com/photo-1601784551446-20c9e07cdbdb?auto=format&fit=crop&w=500&q=80',
            title: 'Premium Lansman Kılıf Standı',
            description: 'Darbe emici kadife iç astarlı kılıflar, tüm renk seçenekleriyle.',
          ),
          StoreGalleryItem(
            id: 'tekno_2',
            imageUrl: 'https://images.unsplash.com/photo-1545259741-2ea3ebf61fa3?auto=format&fit=crop&w=500&q=80',
            title: 'Teknik Servis - Hızlı Ekran Değişimi',
            description: 'Orijinal kalitede yedek parçalarla 30 dakikada cihazınız teslim edilir.',
          ),
        ],
      ),
      StoreData(
        name: 'Kitap Ağacı',
        businessType: 'Diğer',
        description: 'İkinci el kitaplar, nadide baskılar ve sessiz okuma alanı.',
        whatsapp: '0555 567 89 01',
        instagram: '@kitapagaci_sahaf',
        address: 'Moda Cad. No:88, Kadıköy, İstanbul',
        theme: 'Doğal',
        status: 'Stok sınırlı',
        isEsnafMode: true,
        corporateBio: 'Eski kitapların kokusunu, tarihin izlerini Moda\'daki samimi sahaf dükkanımızda yaşatıyoruz. Kahvenizi alıp saatlerce kitaplar arasında kaybolabilirsiniz.',
        galleryItems: [
          StoreGalleryItem(
            id: 'kitap_1',
            imageUrl: 'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?auto=format&fit=crop&w=500&q=80',
            title: 'Nadir Eserler ve Eski Baskılar',
            description: 'Ciltli klasikler, ilk baskılar ve imzalı eserlerin yer aldığı özel rafımız.',
          ),
          StoreGalleryItem(
            id: 'kitap_2',
            imageUrl: 'https://images.unsplash.com/photo-1507842217343-583bb7270b66?auto=format&fit=crop&w=500&q=80',
            title: 'Sessiz Okuma ve Kahve Köşesi',
            description: 'Sadece kitap okumak, dinlenmek ve çalışmak isteyen misafirlerimize özel alan.',
          ),
        ],
      ),
      StoreData(
        name: 'Yeşil Manav',
        businessType: 'Kafe & Gıda',
        description: 'Mevsimlik taze sebzeler, ithal tropikal meyveler ve organik gıdalar.',
        whatsapp: '0555 678 90 12',
        instagram: '@yesilmanav_besiktas',
        address: 'Ihlamurdere Cad. No:92, Beşiktaş, İstanbul',
        theme: 'Doğal',
        status: 'Yeni ürünler geldi',
        isEsnafMode: true,
        corporateBio: 'Yeşil Manav olarak yerel üreticilerden aldığımız taze sebzeleri ve en kaliteli tropikal meyveleri günlük olarak Beşiktaş halkına ulaştırıyoruz.',
        galleryItems: [
          StoreGalleryItem(
            id: 'manav_1',
            imageUrl: 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=500&q=80',
            title: 'Günlük Taze Tropikal Meyve Standı',
            description: 'Avokado, mango, ananas ve taze yaban mersinleri tezgahlarımızda.',
          ),
        ],
      ),
      StoreData(
        name: 'Glamour Kozmetik',
        businessType: 'Kozmetik',
        description: 'Dünya markası parfümler, makyaj ürünleri ve cilt bakım setleri.',
        whatsapp: '0555 789 01 23',
        instagram: '@glamour_kozmetik',
        address: 'Rumeli Cad. No:30, Şişli, İstanbul',
        theme: 'Zarif',
        status: 'Açık',
        isEsnafMode: true,
        corporateBio: 'Glamour Kozmetik, Nişantaşı sınırında, orijinal ithal parfümler ve profesyonel cilt bakımı markalarıyla 15 yıldır kalitenin adresi.',
        galleryItems: [
          StoreGalleryItem(
            id: 'glamour_1',
            imageUrl: 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?auto=format&fit=crop&w=500&q=80',
            title: 'Niche Parfüm ve Esans Köşesi',
            description: 'Koleksiyonluk özel niche parfümler ve kalıcılığı yüksek ten esansları.',
          ),
        ],
      ),
    ];

    // Compile posts from all store gallery items
    _allPosts = [];
    for (final store in _mockStores) {
      final neighborhood = _getStoreNeighborhood(store.address);
      for (final item in store.galleryItems) {
        _allPosts.add(
          ExplorePost(
            id: item.id,
            store: store,
            imageUrl: item.imageUrl,
            title: item.title,
            description: item.description,
            neighborhood: neighborhood,
            category: store.businessType,
          ),
        );
      }
    }
  }

  String _getStoreNeighborhood(String address) {
    for (final n in _neighborhoods) {
      if (address.toLowerCase().contains(n.toLowerCase())) {
        return n;
      }
    }
    return 'Kadıköy'; // Default fallback
  }

  List<ExplorePost> _getFilteredPosts() {
    final query = _searchController.text.toLowerCase().trim();
    
    return _allPosts.where((post) {
      // 1. Category Filter
      if (_selectedCategory != 'Tümü' && post.category != _selectedCategory) {
        return false;
      }
      
      // 2. Neighborhood Filter
      if (_selectedNeighborhood != 'Tüm İstanbul' && post.neighborhood != _selectedNeighborhood) {
        return false;
      }

      // 3. Favorites Filter
      if (_onlyFavorites && !_favoritedStoreNames.contains(post.store.name)) {
        return false;
      }

      // 4. Smart Search Query
      if (query.isNotEmpty) {
        final matchesName = post.store.name.toLowerCase().contains(query);
        final matchesTitle = post.title.toLowerCase().contains(query);
        final matchesDesc = post.description.toLowerCase().contains(query);
        final matchesCat = post.category.toLowerCase().contains(query);
        final matchesNei = post.neighborhood.toLowerCase().contains(query);
        return matchesName || matchesTitle || matchesDesc || matchesCat || matchesNei;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredPosts = _getFilteredPosts();

    return Scaffold(
      backgroundColor: lightBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildSearchAndFilters(),
            _buildStoriesBar(),
            Expanded(
              child: filteredPosts.isEmpty
                  ? _buildEmptyState()
                  : _buildMasonryFeed(filteredPosts),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: brandOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.explore_rounded,
                  color: brandOrange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'VitrinX Keşfet',
                    style: TextStyle(
                      color: darkAccent,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'Çevrendeki esnafların canlı reyonları',
                    style: TextStyle(
                      color: mutedText,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Back button to Landing page
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: darkAccent),
            style: IconButton.styleFrom(
              backgroundColor: lightBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Column(
        children: [
          // Search & Neighborhood Selector Row
          Row(
            children: [
              // Search Input
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: lightBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() {}),
                    style: const TextStyle(
                      color: darkAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search_rounded, color: mutedText, size: 20),
                      hintText: 'Ürün, mağaza veya reyon ara...',
                      hintStyle: const TextStyle(
                        color: mutedText,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18, color: mutedText),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Neighborhood Filter Button
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedNeighborhood,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: brandOrange),
                    style: const TextStyle(
                      color: darkAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedNeighborhood = newValue;
                        });
                      }
                    },
                    items: _neighborhoods.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Category Chips & Favorite Toggle Row
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Favorites Filter Switch Chip
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _onlyFavorites ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 16,
                          color: _onlyFavorites ? Colors.white : Colors.red,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Favorilerim (${_favoritedStoreNames.length})',
                          style: TextStyle(
                            color: _onlyFavorites ? Colors.white : darkAccent,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    selected: _onlyFavorites,
                    onSelected: (val) {
                      setState(() {
                        _onlyFavorites = val;
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor: brandOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: _onlyFavorites ? brandOrange : const Color(0xFFE2E8F0),
                      ),
                    ),
                    showCheckmark: false,
                  ),
                ),
                ..._categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(
                        cat,
                        style: TextStyle(
                          color: isSelected ? Colors.white : softText,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedCategory = cat;
                          });
                        }
                      },
                      backgroundColor: lightBg,
                      selectedColor: darkAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? darkAccent : Colors.transparent,
                        ),
                      ),
                      showCheckmark: false,
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildStoriesBar() {
    // Filter stories by category, favorites, and search query for a better UX
    final query = _searchController.text.toLowerCase().trim();
    final storiesStores = _mockStores.where((s) {
      if (s.status.isEmpty) return false;
      if (_selectedCategory != 'Tümü' && s.businessType != _selectedCategory) {
        return false;
      }
      if (_onlyFavorites && !_favoritedStoreNames.contains(s.name)) {
        return false;
      }
      if (query.isNotEmpty) {
        final matchesName = s.name.toLowerCase().contains(query);
        final matchesCat = s.businessType.toLowerCase().contains(query);
        return matchesName || matchesCat;
      }
      return true;
    }).toList();

    if (storiesStores.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 104,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1.5),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: storiesStores.length,
        itemBuilder: (context, index) {
          final store = storiesStores[index];
          final isFavorited = _favoritedStoreNames.contains(store.name);
          
          return GestureDetector(
            onTap: () => _showStoryModal(store),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              child: Column(
                children: [
                  // Animating story ring
                  AnimatedBuilder(
                    animation: _storyPulseController,
                    builder: (context, child) {
                      final scale = 1.0 + 0.04 * _storyPulseController.value;
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: isFavorited
                                  ? [Colors.redAccent, Colors.orangeAccent]
                                  : [brandOrange, const Color(0xFFFF8C3B), const Color(0xFF25D366)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: CircleAvatar(
                              radius: 26,
                              backgroundColor: brandOrange.withValues(alpha: 0.1),
                              child: Text(
                                store.name.substring(0, 1),
                                style: const TextStyle(
                                  color: brandOrange,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 68,
                    child: Text(
                      store.name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: darkAccent,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showStoryModal(StoreData store) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 100),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Story Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: brandOrange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: brandOrange.withValues(alpha: 0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.flash_on_rounded, color: brandOrange, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'GÜNLÜK DUYURU',
                              style: TextStyle(
                                color: brandOrange,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Store Avatar
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        child: Text(
                          store.name.substring(0, 1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Store Name
                      Text(
                        store.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        store.businessType,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // The Story Message (Announcements)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: Text(
                          '"${store.status}"',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w700,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PublicVitrinScreen(
                                      slug: store.name.toLowerCase().replaceAll(' ', '-'),
                                      mockStoreData: store,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.store_rounded),
                              label: const Text('Vitrini Gör'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: darkAccent,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                textStyle: const TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _openWhatsApp(store.whatsapp, store.name, 'Günlük Duyurunuz'),
                              icon: const Icon(Icons.chat_bubble_rounded),
                              label: const Text('WhatsApp'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                textStyle: const TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Close button
                Positioned(
                  right: 12,
                  top: 12,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white60),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: const Icon(
                Icons.search_off_rounded,
                color: brandOrange,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sonuç Bulunamadı',
              style: TextStyle(
                color: darkAccent,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _onlyFavorites 
                  ? 'Favorilerinizde bu filtrelere uygun dükkan bulunmuyor.' 
                  : 'Farklı bir arama kelimesi yazabilir veya filtreleri temizleyebilirsiniz.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: mutedText,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            if (_searchController.text.isNotEmpty || _selectedCategory != 'Tümü' || _selectedNeighborhood != 'Tüm İstanbul' || _onlyFavorites)
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _selectedCategory = 'Tümü';
                    _selectedNeighborhood = 'Tüm İstanbul';
                    _onlyFavorites = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text('Filtreleri Temizle', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMasonryFeed(List<ExplorePost> posts) {
    // Distribute posts sequentially between two lists to mimic masonry layout
    final List<ExplorePost> leftColumn = [];
    final List<ExplorePost> rightColumn = [];
    
    for (int i = 0; i < posts.length; i++) {
      if (i % 2 == 0) {
        leftColumn.add(posts[i]);
      } else {
        rightColumn.add(posts[i]);
      }
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(_gridSpacing),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: leftColumn.map((post) => _buildFeedCard(post)).toList(),
            ),
          ),
          const SizedBox(width: _gridSpacing),
          Expanded(
            child: Column(
              children: rightColumn.map((post) => _buildFeedCard(post)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedCard(ExplorePost post) {
    final isFavorited = _favoritedStoreNames.contains(post.store.name);
    
    return Container(
      margin: const EdgeInsets.only(bottom: _gridSpacing),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Image.network(
                  post.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 150,
                      color: const Color(0xFFF1F5F9),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: mutedText,
                        size: 32,
                      ),
                    );
                  },
                ),
              ),
              // Favorite Button Overlay
              Positioned(
                top: 8,
                right: 8,
                child: ClipOval(
                  child: Container(
                    color: Colors.white.withValues(alpha: 0.9),
                    child: IconButton(
                      icon: Icon(
                        isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isFavorited ? Colors.red : mutedText,
                        size: 18,
                      ),
                      onPressed: () => _toggleFavorite(post.store.name),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
              // Category Overlay Badge
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    post.category,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Card Details
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Store Info Header
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PublicVitrinScreen(
                          slug: post.store.name.toLowerCase().replaceAll(' ', '-'),
                          mockStoreData: post.store,
                        ),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: brandOrange.withValues(alpha: 0.1),
                        child: Text(
                          post.store.name.substring(0, 1),
                          style: const TextStyle(color: brandOrange, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          post.store.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: darkAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Post Title
                Text(
                  post.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: darkAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                if (post.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    post.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: mutedText,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                // Neighborhood & Actions row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Location
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: brandOrange, size: 12),
                        const SizedBox(width: 2),
                        Text(
                          post.neighborhood,
                          style: const TextStyle(
                            color: softText,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    // Action Buttons (WhatsApp templates, Directions, Share)
                    Row(
                      children: [
                        // Directions Button
                        IconButton(
                          icon: const Icon(Icons.directions_rounded, color: Colors.blueAccent, size: 16),
                          onPressed: () => _openMaps(post.store.address),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                          tooltip: 'Yol Tarifi',
                        ),
                        // Share Button
                        IconButton(
                          icon: const Icon(Icons.share_rounded, color: darkAccent, size: 16),
                          onPressed: () => _copyStoreLink(post.store.name),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                          tooltip: 'Bağlantıyı Kopyala',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // WhatsApp Button
                SizedBox(
                  width: double.infinity,
                  height: 34,
                  child: OutlinedButton.icon(
                    onPressed: () => _showWhatsAppTemplates(post),
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Color(0xFF25D366)),
                    label: const Text(
                      'Ürünü Sor',
                      style: TextStyle(
                        color: Color(0xFF25D366),
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF25D366)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showWhatsAppTemplates(ExplorePost post) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Fotoğraftaki Ürünü Sor',
                    style: TextStyle(
                      color: darkAccent,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Text(
                '${post.store.name} mağazasına göndermek istediğiniz mesaj şablonunu seçin:',
                style: const TextStyle(
                  color: mutedText,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              
              // Preset 1: Fiyat Sor
              _buildTemplateItem(
                icon: Icons.label_rounded,
                color: brandOrange,
                title: 'Fiyat Bilgisi Al',
                subtitle: 'Fiyatı ne kadar?',
                message: 'Merhaba! ${post.store.name} vitrininizdeki "${post.title}" reyon görselindeki ürünlerin fiyatları hakkında bilgi alabilir miyim?',
                post: post,
              ),
              const SizedBox(height: 12),
              
              // Preset 2: Stok Sor
              _buildTemplateItem(
                icon: Icons.inventory_2_rounded,
                color: Colors.blue,
                title: 'Stok Durumu Sor',
                subtitle: 'Şu an ellerinde var mı?',
                message: 'Merhaba! ${post.store.name} vitrininizdeki "${post.title}" reyon görselindeki ürünler şu an stokta mevcut mu?',
                post: post,
              ),
              const SizedBox(height: 12),
              
              // Preset 3: Detay/Renk Sor
              _buildTemplateItem(
                icon: Icons.palette_rounded,
                color: Colors.purple,
                title: 'Detay & Seçenekleri Sor',
                subtitle: 'Farklı renk veya bedenleri var mı?',
                message: 'Merhaba! ${post.store.name} vitrininizdeki "${post.title}" ürünü için farklı renk, beden veya çeşit seçenekleri var mı?',
                post: post,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTemplateItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String message,
    required ExplorePost post,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        _openWhatsApp(post.store.whatsapp, post.store.name, message);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: lightBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: darkAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: mutedText,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: mutedText),
          ],
        ),
      ),
    );
  }

  Future<void> _openWhatsApp(String numberValue, String storeName, String text) async {
    var number = numberValue.replaceAll(RegExp(r'[^0-9]'), '');
    if (number.startsWith('0') && number.length == 11) {
      number = '90${number.substring(1)}';
    } else if (number.startsWith('5') && number.length == 10) {
      number = '90$number';
    }

    final encodedMessage = Uri.encodeComponent(text);
    final url = 'https://wa.me/$number?text=$encodedMessage';
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

  Future<void> _openMaps(String address) async {
    final url = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': address.trim(),
    }).toString();
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harita uygulaması açılamadı!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _copyStoreLink(String storeName) async {
    final slug = storeName.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '-');
    final link = 'https://vitrinx.app/v/$slug';
    await Clipboard.setData(ClipboardData(text: link));
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Text('"$storeName" vitrin bağlantısı kopyalandı!'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: brandOrange,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class ExplorePost {
  final String id;
  final StoreData store;
  final String imageUrl;
  final String title;
  final String description;
  final String neighborhood;
  final String category;

  ExplorePost({
    required this.id,
    required this.store,
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.neighborhood,
    required this.category,
  });
}

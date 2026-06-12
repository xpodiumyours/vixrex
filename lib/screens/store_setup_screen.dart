import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vitrinx/config/legal_config.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/screens/explore_screen.dart';
import 'package:vitrinx/screens/landing_screen.dart';
import 'package:vitrinx/services/local_storage_keys.dart';
import 'package:vitrinx/services/location_service.dart';
import 'package:vitrinx/services/store_publish_payload_builder.dart';
import 'package:vitrinx/services/store_shelf_upload_service.dart';
import 'package:vitrinx/utils/token_generator.dart';

// ─── Kategori Modeli ────────────────────────────────────────────────────────
class _Category {
  final String label;
  final String emoji;
  final Color accent;
  const _Category(this.label, this.emoji, this.accent);
}

// ─── Setup Galeri Modeli ──────────────────────────────────────────────────
class _SetupGalleryItem {
  final String id;
  final Uint8List? bytes;
  final String imageUrl;
  final String extension;
  final String contentType;
  final String title;
  final String description;

  _SetupGalleryItem({
    required this.id,
    this.bytes,
    this.imageUrl = '',
    this.extension = 'jpg',
    this.contentType = 'image/jpeg',
    this.title = '',
    this.description = '',
  });
}

// ─── Ana Widget ─────────────────────────────────────────────────────────────
class StoreSetupScreen extends StatefulWidget {
  const StoreSetupScreen({super.key});

  @override
  State<StoreSetupScreen> createState() => _StoreSetupScreenState();
}

class _StoreSetupScreenState extends State<StoreSetupScreen>
    with TickerProviderStateMixin {
  // ── Renkler (premium SaaS stili) ──────────────────────────────────────────
  static const Color primaryColor = Color(0xFFFF4D00);
  static const Color secondaryColor = Color(0xFFB200FF);
  static const Color bgColor = Color(0xFFF8FAFC);
  static const Color cardBorder = Color.fromRGBO(15, 23, 42, 0.08);
  static const Color inputBg = Color(0xFFF1F5F9);
  static const Color darkText = Color(0xFF0F172A);
  static const Color mutedText = Color(0xFF64748B);
  static const Color softText = Color(0xFF334155);
  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, secondaryColor],
  );

  // ── Adım ve Durum ─────────────────────────────────────────────────────────
  int _step =
      0; // 0 = kategori seç, 1 = mağaza bilgileri, 2 = ürünler, 3 = fotoğraflar, 4 = özet & yayınla
  bool _isPublishing = false;
  bool _isDeleting = false;
  String? _publishedLink;
  String? _existingStoreToken;

  // Controllers
  late final PageController _pageController;
  late final AnimationController _progressController;

  _Category? _selectedCategory;
  String? _selectedBusinessType; // İşletme türü

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _waCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _workingHoursCtrl = TextEditingController();

  String? _nameError;
  String? _waError;

  // Konum & KVKK
  double? _latitude;
  double? _longitude;
  double? _locationAccuracyMeters;
  DateTime? _locationConsentAt;
  String? _locationSource;
  bool _kvkkConsent = false;
  bool _isLocating = false;
  String? _locationStatusMessage;
  double? _pendingMapsLatitude;
  double? _pendingMapsLongitude;
  double? _pendingMapsAccuracyMeters;

  // Ürünler
  final List<Product> _products = [];
  final Map<String, Uint8List> _productImageBytes = {};
  final Map<String, String> _productImageExtensions = {};
  final Map<String, String> _productImageContentTypes = {};

  // Fotoğraflar
  Uint8List? _logoBytes;
  String? _logoExtension;
  String? _logoContentType;
  String? _logoUrl;

  Uint8List? _coverBytes;
  String? _coverExtension;
  String? _coverContentType;
  String? _coverUrl;

  final List<_SetupGalleryItem> _setupGalleryItems = [];

  // Kategoriler ve Alt İşletme Türleri
  static const List<_Category> _categories = [
    _Category('Giyim & Butik', '🛍', Color(0xFFFF5A1F)),
    _Category('Gıda & Fırın', '🍞', Color(0xFFE67E22)),
    _Category('Kozmetik', '💄', Color(0xFFE91E8C)),
    _Category('Dekorasyon', '🪴', Color(0xFF27AE60)),
    _Category('Elektronik', '📱', Color(0xFF2563EB)),
    _Category('Kırtasiye', '📚', Color(0xFF7C3AED)),
    _Category('Diğer', '🏪', Color(0xFF64748B)),
  ];

  final Map<String, List<String>> _businessTypesByCategory = const {
    'Giyim & Butik': [
      'Kadın Giyim Butiği',
      'Erkek Giyim Butiği',
      'Ayakkabı & Çanta',
      'Aksesuar & Takı',
      'Diğer Butik',
    ],
    'Gıda & Fırın': [
      'Fırın / Unlu Mamüller',
      'Kafe / Pastane',
      'Restoran / Yemek',
      'Şarküteri / Bakkal',
      'Diğer Gıda',
    ],
    'Kozmetik': [
      'Güzellik & Kuaför',
      'Kozmetik Mağazası',
      'Kişisel Bakım',
      'Diğer Kozmetik',
    ],
    'Dekorasyon': [
      'Ev Dekorasyonu & Mobilya',
      'Çiçekçi & Peyzaj',
      'Züccaciye',
      'Diğer Dekorasyon',
    ],
    'Elektronik': [
      'Teknoloji Mağazası',
      'Telefon & Aksesuar',
      'Teknik Servis',
      'Diğer Elektronik',
    ],
    'Kırtasiye': [
      'Kitabevi & Kırtasiye',
      'Hobi & Oyuncak',
      'Ofis Malzemeleri',
      'Diğer Kırtasiye',
    ],
    'Diğer': [
      'Yerel Esnaf',
      'Hizmet İşletmesi',
      'Atölye / Üretim',
      'Diğer İşletme',
    ],
  };

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _progressController.animateTo(0.20);
    });
    _loadExistingStoreToken();
  }

  Future<void> _loadExistingStoreToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(LocalStorageKeys.storeEditToken);
      final savedStore =
          _readSavedStoreData(prefs.getString(LocalStorageKeys.storeData)) ??
          _readSavedStoreData(prefs.getString(LocalStorageKeys.vitrinData));
      if (mounted) {
        setState(() {
          _existingStoreToken = token;
          if (savedStore != null && savedStore.isStore) {
            _applySavedStoreData(savedStore);
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading store edit token: $e');
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

  void _applySavedStoreData(StoreData data) {
    _Category? savedCategory;
    for (final category in _categories) {
      if (category.label == data.kategori) {
        savedCategory = category;
        break;
      }
    }
    _selectedCategory = savedCategory;
    _selectedBusinessType = data.businessType;
    _nameCtrl.text = data.name;
    _descCtrl.text = data.description;
    _waCtrl.text = data.whatsapp;
    _addressCtrl.text = data.address;
    _workingHoursCtrl.text = data.workingHours;
    _latitude = data.latitude;
    _longitude = data.longitude;
    _locationAccuracyMeters = data.locationAccuracyMeters;
    _locationConsentAt = data.locationConsentAt;
    _locationSource = data.locationSource;
    _kvkkConsent = data.latitude != null && data.longitude != null;

    // Load products
    _products.clear();
    _products.addAll(data.products);

    // Load logo/cover
    _logoUrl = data.logoUrl;

    // Load gallery items
    _setupGalleryItems.clear();
    for (final item in data.galleryItems) {
      if (item.id == 'cover') {
        _coverUrl = item.imageUrl;
      } else {
        _setupGalleryItems.add(
          _SetupGalleryItem(
            id: item.id,
            imageUrl: item.imageUrl,
            title: item.title,
            description: item.description,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _waCtrl.dispose();
    _addressCtrl.dispose();
    _workingHoursCtrl.dispose();
    super.dispose();
  }

  // ── Navigasyon ────────────────────────────────────────────────────────────
  void _goNext() {
    if (_step == 0) {
      if (_selectedCategory == null) {
        _showError('Lütfen bir kategori seçin.');
        return;
      }
      if (_selectedBusinessType == null) {
        _showError('Lütfen bir işletme türü seçin.');
        return;
      }
      _toStep(1);
    } else if (_step == 1) {
      if (!_validateStep2()) return;
      _toStep(2);
    } else if (_step == 2) {
      if (_products.isEmpty) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ürün eklemek mağazanızı güçlendirir!'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
      }
      _toStep(3);
    } else if (_step == 3) {
      _toStep(4);
    }
  }

  void _goBack() {
    if (_step > 0) _toStep(_step - 1);
  }

  void _toStep(int step) {
    setState(() => _step = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
    _progressController.animateTo(
      (step + 1) / 5,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  bool _validateStep2() {
    bool ok = true;
    setState(() {
      _nameError = null;
      _waError = null;
      if (_nameCtrl.text.trim().isEmpty) {
        _nameError = 'Mağaza adı zorunludur';
        ok = false;
      }
      if (_waCtrl.text.trim().isEmpty) {
        _waError = 'WhatsApp numarası zorunludur';
        ok = false;
      }
    });
    return ok;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocating = true;
      _pendingMapsLatitude = null;
      _pendingMapsLongitude = null;
      _pendingMapsAccuracyMeters = null;
      _locationStatusMessage =
          'Konum aranıyor... 30 metre altı doğruluk bekleniyor.';
    });

    final result = await const LocationService().getCurrentLocation();
    if (!mounted) return;

    if (!result.isSuccess) {
      final approximatePosition = result.approximatePosition;
      setState(() {
        _locationStatusMessage = result.errorMessage;
        _pendingMapsLatitude = approximatePosition?.latitude;
        _pendingMapsLongitude = approximatePosition?.longitude;
        _pendingMapsAccuracyMeters = approximatePosition?.accuracy;
        _isLocating = false;
      });
      return;
    }

    final position = result.position!;
    setState(() {
      _latitude = position.latitude;
      _longitude = position.longitude;
      _locationAccuracyMeters = position.accuracy;
      _locationConsentAt = DateTime.now();
      _locationSource = 'setup_screen_gps_high_accuracy';
      _locationStatusMessage = LocationService.buildAccuracyMessage(
        position.accuracy,
      );
      _pendingMapsLatitude = null;
      _pendingMapsLongitude = null;
      _pendingMapsAccuracyMeters = null;
      _isLocating = false;
    });
  }

  // ── YAYINLA ───────────────────────────────────────────────────────────────
  Future<void> _openPendingLocationInMaps() async {
    final latitude = _pendingMapsLatitude;
    final longitude = _pendingMapsLongitude;
    if (latitude == null || longitude == null) return;

    final uri = LocationService.buildGoogleMapsSearchUri(latitude, longitude);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _confirmPendingLocation() {
    final latitude = _pendingMapsLatitude;
    final longitude = _pendingMapsLongitude;
    if (latitude == null || longitude == null) return;

    setState(() {
      _latitude = latitude;
      _longitude = longitude;
      _locationAccuracyMeters = _pendingMapsAccuracyMeters;
      _locationConsentAt = DateTime.now();
      _locationSource = 'setup_screen_gps_user_confirmed_approximate';
      _locationStatusMessage =
          'Yaklasik konum kullanici onayi ile kaydedildi. Google Maps uzerinden kontrol edildi.';
      _pendingMapsLatitude = null;
      _pendingMapsLongitude = null;
      _pendingMapsAccuracyMeters = null;
      if (_addressCtrl.text.trim().isEmpty) {
        _addressCtrl.text = 'Koordinatlarla isaretlenen konum';
      }
    });
  }

  Future<void> _publish() async {
    if (_isPublishing) return;
    setState(() => _isPublishing = true);

    try {
      final name = _nameCtrl.text.trim();
      final builder = const StorePublishPayloadBuilder();
      final slug = builder.generateSlug(name);
      final editToken = _existingStoreToken ?? _generateToken();
      final client = Supabase.instance.client;

      // ── Resimleri Yükleme ─────────────────────────────────────────────────
      String? logoUrl = _logoUrl;
      if (_logoBytes != null) {
        logoUrl = await const StoreShelfUploadService().uploadShelfImage(
          _logoBytes!,
          '$slug/logo',
          fileExtension: _logoExtension ?? 'jpg',
          contentType: _logoContentType ?? 'image/jpeg',
        );
      }

      String? coverUrl = _coverUrl;
      if (_coverBytes != null) {
        coverUrl = await const StoreShelfUploadService().uploadShelfImage(
          _coverBytes!,
          '$slug/cover',
          fileExtension: _coverExtension ?? 'jpg',
          contentType: _coverContentType ?? 'image/jpeg',
        );
      }

      // Ürün fotoğraflarını yükleyelim
      for (final prod in _products) {
        final prodBytes = _productImageBytes[prod.id];
        if (prodBytes != null) {
          final pUrl = await const StoreShelfUploadService().uploadShelfImage(
            prodBytes,
            '$slug/products/${prod.id}',
            fileExtension: _productImageExtensions[prod.id] ?? 'jpg',
            contentType: _productImageContentTypes[prod.id] ?? 'image/jpeg',
          );
          prod.imagePath = pUrl;
        }
      }

      // Galeri fotoğraflarını yükleyelim
      final List<StoreGalleryItem> finalGalleryItems = [];
      if (coverUrl != null && coverUrl.isNotEmpty) {
        finalGalleryItems.add(
          StoreGalleryItem(
            id: 'cover',
            imageUrl: coverUrl,
            title: 'Kapak Fotoğrafı',
            description: 'Giriş / kapak resmi',
          ),
        );
      }

      for (final item in _setupGalleryItems) {
        if (item.bytes != null) {
          final gUrl = await const StoreShelfUploadService().uploadGalleryImage(
            item.bytes!,
            slug,
            fileExtension: item.extension,
            contentType: item.contentType,
          );
          finalGalleryItems.add(
            StoreGalleryItem(
              id: item.id,
              imageUrl: gUrl,
              title: item.title,
              description: item.description,
            ),
          );
        } else if (item.imageUrl.isNotEmpty) {
          finalGalleryItems.add(
            StoreGalleryItem(
              id: item.id,
              imageUrl: item.imageUrl,
              title: item.title,
              description: item.description,
            ),
          );
        }
      }

      // ── Token + StoreData ─────────────────────────────────────────────────
      final storeData = StoreData(
        name: name,
        description: _descCtrl.text.trim(),
        whatsapp: _waCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        workingHours: _workingHoursCtrl.text.trim(),
        isStore: true,
        logoUrl: logoUrl,
        kategori: _selectedCategory!.label,
        businessType: _selectedBusinessType ?? _selectedCategory!.label,
        status: 'Açık',
        latitude: _latitude,
        longitude: _longitude,
        locationAccuracyMeters: _locationAccuracyMeters,
        locationConsentAt: _locationConsentAt,
        locationSource: _locationSource,
        products: _products,
        galleryItems: finalGalleryItems,
      );

      final payload = builder.toStoreInsertMap(storeData, slug, editToken);
      if (client.auth.currentUser != null) {
        payload['user_id'] = client.auth.currentUser!.id;
      }

      // ── Supabase insert / update ──────────────────────────────────────────
      final hasExistingStoreToken =
          _existingStoreToken != null && _existingStoreToken!.isNotEmpty;
      if (hasExistingStoreToken) {
        final existingByToken =
            await client
                .from('stores')
                .select('edit_token')
                .eq('edit_token', editToken)
                .maybeSingle();

        if (existingByToken == null) {
          await client.from('stores').insert(payload);
        } else {
          await client
              .from('stores')
              .update(payload)
              .eq('edit_token', editToken);
        }
      } else {
        await client.from('stores').insert(payload);
      }

      // ── Yerel Kayıt ──────────────────────────────────────────────────────
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(LocalStorageKeys.storeEditToken, editToken);
      await prefs.setString(
        LocalStorageKeys.storeData,
        jsonEncode(storeData.toJson()),
      );

      // Eski vitrin_data verisinde isStore true ise temizle
      final legacyData = _readSavedStoreData(
        prefs.getString(LocalStorageKeys.vitrinData),
      );
      if (legacyData != null && legacyData.isStore) {
        await prefs.remove(LocalStorageKeys.vitrinData);
      }

      setState(() {
        _publishedLink = 'https://vitrinx.app/v/$slug';
        _isPublishing = false;
      });
    } catch (e) {
      _showError('Yayınlanırken hata oluştu: $e');
      setState(() => _isPublishing = false);
    }
  }

  /// Edit token üretir. [TokenGenerator] delegasyonu.
  String _generateToken() => TokenGenerator.generate();

  Future<void> _deleteStore() async {
    if (_isDeleting) return;
    setState(() => _isDeleting = true);

    try {
      final token = _existingStoreToken;
      if (token != null && token.isNotEmpty) {
        await Supabase.instance.client
            .from('stores')
            .delete()
            .eq('edit_token', token);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(LocalStorageKeys.storeEditToken);
      await prefs.remove(LocalStorageKeys.storeData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mağazanız başarıyla silindi.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LandingScreen()),
        (route) => false,
      );
    } catch (e) {
      _showError('Silme hatası: $e');
      setState(() => _isDeleting = false);
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Mağazayı Sil',
            style: TextStyle(fontWeight: FontWeight.bold, color: darkText),
          ),
          content: const Text(
            'Mağazanız tamamen silinecektir. Devam etmek istiyor musunuz?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Vazgeç',
                style: TextStyle(color: mutedText, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _deleteStore();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Sil',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildStepHeader(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(), // Kategori
                _buildStep2(), // Bilgiler
                _buildStep3(), // Ürünler
                _buildStep4(), // Görseller
                _buildStep5(), // Özet & Yayınla
              ],
            ),
          ),
          if (_publishedLink == null) _buildBottomNav(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final titles = [
      'Kategori Seç',
      'Mağaza Bilgileri',
      'Ürün Kataloğu',
      'Görseller',
      'Özet & Yayınla',
    ];
    return AppBar(
      title: Text(
        titles[_step],
        style: const TextStyle(
          color: darkText,
          fontWeight: FontWeight.w900,
          fontSize: 18,
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: const IconThemeData(color: darkText),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: cardBorder),
      ),
    );
  }

  Widget _buildStepHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      child: Column(
        children: [
          Row(
            children: List.generate(5, (i) {
              final done = i < _step;
              final active = i == _step;
              return Expanded(
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      width: active ? 32 : 24,
                      height: active ? 32 : 24,
                      decoration: BoxDecoration(
                        color:
                            done || active
                                ? primaryColor
                                : const Color(0xFFE2E8F0),
                        shape: BoxShape.circle,
                        boxShadow:
                            active
                                ? [
                                  BoxShadow(
                                    color: primaryColor.withValues(alpha: 0.35),
                                    blurRadius: 12,
                                  ),
                                ]
                                : null,
                      ),
                      child: Center(
                        child:
                            done
                                ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 14,
                                )
                                : Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    color: active ? Colors.white : mutedText,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                      ),
                    ),
                    if (i < 4)
                      Expanded(
                        child: Container(
                          height: 3,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color:
                                done ? primaryColor : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Adım ${_step + 1}/5',
                style: const TextStyle(
                  color: primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                'Premium Mağaza Kurulumu',
                style: TextStyle(
                  color: mutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── ADIM WIDGETS ──────────────────────────────────────────────────────────
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'İşletme kategoriniz nedir?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: darkText,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Müşteriler sizi daha kolay bulsun diye doğru kategoriyi seçin.',
            style: TextStyle(fontSize: 14, color: mutedText, height: 1.5),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
            ),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final selected = _selectedCategory?.label == cat.label;
              return _CategoryCard(
                category: cat,
                selected: selected,
                onTap: () {
                  setState(() {
                    _selectedCategory = cat;
                    _selectedBusinessType = null;
                  });
                },
              );
            },
          ),
          const SizedBox(height: 28),
          if (_selectedCategory != null) ...[
            const Text(
              'İşletme Türü Seçin',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: darkText,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'İşletmenizin sunduğu spesifik hizmet veya ürün odağını belirtin.',
              style: TextStyle(fontSize: 13, color: mutedText),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cardBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedBusinessType,
                  hint: const Text(
                    'İşletme Türü Seçin',
                    style: TextStyle(
                      fontSize: 14,
                      color: mutedText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  isExpanded: true,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: mutedText,
                  ),
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  items:
                      _businessTypesByCategory[_selectedCategory!.label]!
                          .map(
                            (type) => DropdownMenuItem<String>(
                              value: type,
                              child: Text(
                                type,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: darkText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedBusinessType = val;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 60),
          ],
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mağaza Bilgileri',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: darkText,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Müşterilerinizin size ulaşabilmesi için detayları doldurun.',
            style: TextStyle(fontSize: 14, color: mutedText, height: 1.5),
          ),
          const SizedBox(height: 24),
          _buildInputField(
            label: 'Mağaza Adı',
            controller: _nameCtrl,
            hint: 'Örn: Aymira Giyim',
            icon: Icons.storefront_rounded,
            required: true,
            errorText: _nameError,
            onChanged: (_) {
              if (_nameError != null) setState(() => _nameError = null);
            },
          ),
          const SizedBox(height: 16),
          _buildInputField(
            label: 'Kısa Açıklama',
            controller: _descCtrl,
            hint: 'Mağazanız hakkında 1-2 cümle...',
            icon: Icons.description_outlined,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          _buildInputField(
            label: 'WhatsApp Numarası',
            controller: _waCtrl,
            hint: 'Örn: 0555 123 45 67',
            icon: Icons.phone_android_rounded,
            keyboardType: TextInputType.phone,
            required: true,
            errorText: _waError,
            onChanged: (_) {
              if (_waError != null) setState(() => _waError = null);
            },
          ),
          const SizedBox(height: 16),
          _buildInputField(
            label: 'Çalışma Saatleri',
            controller: _workingHoursCtrl,
            hint: 'Örn: Pzt-Cmt: 09:00 - 20:00, Pazar: Kapalı',
            icon: Icons.access_time_rounded,
          ),
          const SizedBox(height: 16),
          _buildInputField(
            label: 'Açık Adres',
            controller: _addressCtrl,
            hint: 'Örn: Kadıköy, İstanbul',
            icon: Icons.location_on_outlined,
            maxLines: 2,
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 8),
              child:
                  _isLocating
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                primaryColor,
                              ),
                            ),
                          ),
                        ),
                      )
                      : IconButton(
                        icon: const Icon(Icons.my_location_rounded, size: 20),
                        color: primaryColor,
                        disabledColor: mutedText.withValues(alpha: 0.4),
                        onPressed:
                            _kvkkConsent && !_isLocating
                                ? _getCurrentLocation
                                : null,
                        tooltip: 'Konumumu Kullan',
                      ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _kvkkConsent,
                  activeColor: primaryColor,
                  onChanged: (val) {
                    setState(() {
                      _kvkkConsent = val ?? false;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _kvkkConsent = !_kvkkConsent;
                    });
                  },
                  child: const Text(
                    'Konum verilerimin KVKK kapsamında işlenmesine açık rıza veriyorum.',
                    style: TextStyle(
                      fontSize: 12,
                      color: softText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed:
                  () => Navigator.pushNamed(context, LegalConfig.privacyPath),
              style: TextButton.styleFrom(
                foregroundColor: primaryColor,
                padding: const EdgeInsets.only(left: 32, top: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'KVKK ve gizlilik metnini görüntüle',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          if (_locationStatusMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _locationStatusMessage!,
              style: TextStyle(
                fontSize: 12,
                color:
                    _latitude != null
                        ? Colors.green.shade700
                        : _pendingMapsLatitude != null
                        ? Colors.orange.shade800
                        : Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_pendingMapsLatitude != null && _pendingMapsLongitude != null)
              Wrap(
                spacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: _openPendingLocationInMaps,
                    icon: const Icon(Icons.map_outlined, size: 16),
                    label: const Text("Google Maps'te Kontrol Et"),
                    style: TextButton.styleFrom(foregroundColor: primaryColor),
                  ),
                  TextButton.icon(
                    onPressed: _confirmPendingLocation,
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Bu Konumu Kullan'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ürün Kataloğu',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: darkText,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Mağazanızda satılan ürünleri ekleyin.',
                    style: TextStyle(fontSize: 13, color: mutedText),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showProductFormDialog(),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text(
                  'Ürün Ekle',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_products.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cardBorder),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      color: primaryColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Henüz Ürün Eklenmedi',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Ürün eklemek mağazanızı güçlendirir! Müşterileriniz ürünlerinizi inceleyebilir.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: mutedText,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _products.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final product = _products[index];
                final imageBytes = _productImageBytes[product.id];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child:
                            imageBytes != null
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.memory(
                                    imageBytes,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                : (product.imagePath != null &&
                                        product.imagePath!.isNotEmpty
                                    ? ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        product.imagePath!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                    : const Icon(
                                      Icons.image_outlined,
                                      color: mutedText,
                                      size: 24,
                                    )),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: darkText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    product.category,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: softText,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        product.stockStatus == 'Mevcut'
                                            ? const Color(0xFFECFDF5)
                                            : (product.stockStatus ==
                                                    'Son birkaç adet'
                                                ? const Color(0xFFFFFBEB)
                                                : const Color(0xFFFEF2F2)),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    product.stockStatus,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          product.stockStatus == 'Mevcut'
                                              ? const Color(0xFF059669)
                                              : (product.stockStatus ==
                                                      'Son birkaç adet'
                                                  ? const Color(0xFFD97706)
                                                  : const Color(0xFFDC2626)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              product.price.isEmpty
                                  ? 'Mağazaya Sorunuz'
                                  : product.price,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: softText,
                          size: 20,
                        ),
                        onPressed:
                            () => _showProductFormDialog(product: product),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _products.removeAt(index);
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _showProductFormDialog({Product? product}) {
    final isEdit = product != null;
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final priceCtrl = TextEditingController(text: product?.price ?? '');
    final descCtrl = TextEditingController(text: product?.description ?? '');

    String selectedCategory = product?.category ?? 'Genel';
    String selectedStock = product?.stockStatus ?? 'Mevcut';

    Uint8List? localImageBytes = isEdit ? _productImageBytes[product.id] : null;
    String? localExtension =
        isEdit ? _productImageExtensions[product.id] : null;
    String? localContentType =
        isEdit ? _productImageContentTypes[product.id] : null;

    final productCategories = [
      'Genel',
      'Yeni Sezon',
      'Giyim',
      'Gıda',
      'Kozmetik',
      'Aksesuar',
      'Diğer',
    ];
    if (!productCategories.contains(selectedCategory)) {
      productCategories.add(selectedCategory);
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                isEdit ? 'Ürünü Düzenle' : 'Yeni Ürün Ekle',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: darkText,
                  fontSize: 18,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.image,
                          withData: true,
                        );
                        if (result != null && result.files.isNotEmpty) {
                          final file = result.files.first;
                          if (file.bytes != null) {
                            setDialogState(() {
                              localImageBytes = file.bytes;
                              localExtension = file.extension ?? 'jpg';
                              localContentType =
                                  file.extension == 'png'
                                      ? 'image/png'
                                      : 'image/jpeg';
                            });
                          }
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: cardBorder),
                        ),
                        child:
                            localImageBytes != null
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(
                                    localImageBytes!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                : (product?.imagePath != null &&
                                        product!.imagePath!.isNotEmpty
                                    ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        product.imagePath!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                    : const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_a_photo_outlined,
                                          color: mutedText,
                                          size: 28,
                                        ),
                                        SizedBox(height: 6),
                                        Text(
                                          'Ürün Fotoğrafı Seç',
                                          style: TextStyle(
                                            color: mutedText,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    )),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDialogField(
                      label: 'Ürün Adı *',
                      controller: nameCtrl,
                      hint: 'Örn: El Örmesi Hırka',
                    ),
                    const SizedBox(height: 12),
                    _buildDialogDropdown(
                      label: 'Ürün Kategorisi',
                      value: selectedCategory,
                      items: productCategories,
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedCategory = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildDialogField(
                      label: 'Fiyat',
                      controller: priceCtrl,
                      hint: 'Örn: 250 TL',
                    ),
                    const SizedBox(height: 12),
                    _buildDialogDropdown(
                      label: 'Stok Durumu',
                      value: selectedStock,
                      items: const ['Mevcut', 'Tükendi', 'Son birkaç adet'],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedStock = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildDialogField(
                      label: 'Kısa Açıklama',
                      controller: descCtrl,
                      hint: 'Ürün açıklaması...',
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    'İptal',
                    style: TextStyle(
                      color: mutedText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('Ürün adı boş bırakılamaz!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                    setState(() {
                      final newProduct = Product(
                        id:
                            product?.id ??
                            DateTime.now().microsecondsSinceEpoch.toString(),
                        name: name,
                        price: priceCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                        category: selectedCategory,
                        stockStatus: selectedStock,
                        imagePath: product?.imagePath,
                      );
                      if (isEdit) {
                        final idx = _products.indexWhere(
                          (p) => p.id == product.id,
                        );
                        if (idx != -1) _products[idx] = newProduct;
                      } else {
                        _products.add(newProduct);
                      }
                      if (localImageBytes != null) {
                        _productImageBytes[newProduct.id] = localImageBytes!;
                        _productImageExtensions[newProduct.id] =
                            localExtension!;
                        _productImageContentTypes[newProduct.id] =
                            localContentType!;
                      }
                    });
                    Navigator.pop(dialogContext);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Kaydet',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDialogField({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: softText,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(
            fontSize: 13,
            color: darkText,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: mutedText.withValues(alpha: 0.4),
              fontSize: 13,
            ),
            filled: true,
            fillColor: inputBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDialogDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: softText,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: inputBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(10),
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: mutedText,
                size: 20,
              ),
              items:
                  items
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(
                            item,
                            style: const TextStyle(
                              fontSize: 13,
                              color: darkText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                      .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fotoğraflar',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: darkText,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Mağazanızın profesyonel görünmesi için görselleri ekleyin.',
            style: TextStyle(fontSize: 13, color: mutedText, height: 1.4),
          ),
          const SizedBox(height: 24),

          const Text(
            'Profil / Logo Fotoğrafı',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.image,
                withData: true,
              );
              if (result != null && result.files.isNotEmpty) {
                final file = result.files.first;
                if (file.bytes != null) {
                  setState(() {
                    _logoBytes = file.bytes;
                    _logoExtension = file.extension ?? 'jpg';
                    _logoContentType =
                        file.extension == 'png' ? 'image/png' : 'image/jpeg';
                  });
                }
              }
            },
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                    border: Border.all(color: cardBorder, width: 2),
                  ),
                  child:
                      _logoBytes != null
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(36),
                            child: Image.memory(_logoBytes!, fit: BoxFit.cover),
                          )
                          : (_logoUrl != null && _logoUrl!.isNotEmpty
                              ? ClipRRect(
                                borderRadius: BorderRadius.circular(36),
                                child: Image.network(
                                  _logoUrl!,
                                  fit: BoxFit.cover,
                                ),
                              )
                              : const Icon(
                                Icons.storefront_rounded,
                                color: mutedText,
                                size: 32,
                              )),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: cardBorder),
                      ),
                      child: const Text(
                        'Logo Seç',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: darkText,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Önerilen: 500x500 kare resim.',
                      style: TextStyle(color: mutedText, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Kapak Fotoğrafı',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.image,
                withData: true,
              );
              if (result != null && result.files.isNotEmpty) {
                final file = result.files.first;
                if (file.bytes != null) {
                  setState(() {
                    _coverBytes = file.bytes;
                    _coverExtension = file.extension ?? 'jpg';
                    _coverContentType =
                        file.extension == 'png' ? 'image/png' : 'image/jpeg';
                  });
                }
              }
            },
            child: Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cardBorder),
              ),
              child:
                  _coverBytes != null
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.memory(_coverBytes!, fit: BoxFit.cover),
                      )
                      : (_coverUrl != null && _coverUrl!.isNotEmpty
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(_coverUrl!, fit: BoxFit.cover),
                          )
                          : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.landscape_rounded,
                                color: mutedText,
                                size: 36,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Kapak Fotoğrafı Seç',
                                style: TextStyle(
                                  color: darkText,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(height: 4),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20),
                                child: Text(
                                  'İpucu: Seçmezseniz, galerinizin ilk resmi kapak olarak kullanılacaktır.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: mutedText,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          )),
            ),
          ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Galeri Fotoğrafları (Maks. 5)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
              if (_setupGalleryItems.length < 5)
                IconButton(
                  icon: const Icon(
                    Icons.add_photo_alternate_rounded,
                    color: primaryColor,
                  ),
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.image,
                      withData: true,
                    );
                    if (result != null && result.files.isNotEmpty) {
                      final file = result.files.first;
                      if (file.bytes != null) {
                        setState(() {
                          _setupGalleryItems.add(
                            _SetupGalleryItem(
                              id:
                                  DateTime.now().microsecondsSinceEpoch
                                      .toString(),
                              bytes: file.bytes,
                              extension: file.extension ?? 'jpg',
                              contentType:
                                  file.extension == 'png'
                                      ? 'image/png'
                                      : 'image/jpeg',
                              title: 'Galeri Resmi',
                              description: 'Mağaza içi veya ürün reyonu.',
                            ),
                          );
                        });
                      }
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_setupGalleryItems.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cardBorder),
              ),
              child: const Column(
                children: [
                  Icon(Icons.collections_outlined, color: mutedText, size: 24),
                  SizedBox(height: 8),
                  Text(
                    'Henüz galeri fotoğrafı eklenmedi.',
                    style: TextStyle(color: mutedText, fontSize: 12),
                  ),
                ],
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemCount: _setupGalleryItems.length,
              itemBuilder: (context, index) {
                final item = _setupGalleryItems[index];
                return Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: cardBorder),
                        ),
                        child:
                            item.bytes != null
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.memory(
                                    item.bytes!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                : ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    item.imageUrl,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _setupGalleryItems.removeAt(index);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  int _calculateSetupScore() {
    int score = 0;
    if (_nameCtrl.text.trim().isNotEmpty) score += 15;
    if (_selectedCategory != null && _selectedBusinessType != null) score += 15;
    if (_waCtrl.text.trim().isNotEmpty) score += 15;
    if (_addressCtrl.text.trim().isNotEmpty && _latitude != null) score += 20;
    if (_workingHoursCtrl.text.trim().isNotEmpty) score += 15;
    if (_coverBytes != null ||
        _coverUrl != null ||
        _setupGalleryItems.isNotEmpty) {
      score += 10;
    }
    if (_products.isNotEmpty) score += 10;
    return score;
  }

  List<Map<String, dynamic>> _buildChecklist() {
    return [
      {
        'title': 'Mağaza Adı',
        'isComplete': _nameCtrl.text.trim().isNotEmpty,
        'missingText': 'Mağaza adı girilmemiş.',
      },
      {
        'title': 'Kategori ve İşletme Türü',
        'isComplete':
            _selectedCategory != null && _selectedBusinessType != null,
        'missingText': 'İşletme kategorisi veya türü seçilmemiş.',
      },
      {
        'title': 'İletişim & WhatsApp',
        'isComplete': _waCtrl.text.trim().isNotEmpty,
        'missingText': 'İletişim/WhatsApp numarası girilmemiş.',
      },
      {
        'title': 'Çalışma Saatleri',
        'isComplete': _workingHoursCtrl.text.trim().isNotEmpty,
        'missingText': 'Çalışma saatleri girilmemiş.',
      },
      {
        'title': 'Adres ve Konum (GPS)',
        'isComplete': _addressCtrl.text.trim().isNotEmpty && _latitude != null,
        'missingText': 'Adres girilmemiş veya GPS konumu alınmamış.',
      },
      {
        'title': 'Görseller & Kapak',
        'isComplete':
            _coverBytes != null ||
            _coverUrl != null ||
            _setupGalleryItems.isNotEmpty,
        'missingText': 'Logo veya kapak görseli eksik.',
      },
      {
        'title': 'Ürün Kataloğu',
        'isComplete': _products.isNotEmpty,
        'missingText':
            'Ürün kataloğu boş (Ürün eklemek mağazanızı güçlendirir).',
      },
    ];
  }

  Widget _buildStep5() {
    if (_publishedLink != null) return _buildSuccessView();
    if (_selectedCategory == null) return const SizedBox.shrink();

    final score = _calculateSetupScore();
    final checklist = _buildChecklist();
    final slug = const StorePublishPayloadBuilder().generateSlug(
      _nameCtrl.text.trim(),
    );

    Color scoreColor;
    if (score < 40) {
      scoreColor = Colors.orange;
    } else if (score < 75) {
      scoreColor = Colors.amber;
    } else {
      scoreColor = Colors.green;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Yayın Öncesi Kontrol',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: darkText,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Mağazanızı yayınlamadan önce son kontrollerinizi yapın.',
            style: TextStyle(fontSize: 13, color: mutedText),
          ),
          const SizedBox(height: 20),

          // Mağaza Skoru Kartı
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cardBorder),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.02),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: CircularProgressIndicator(
                        value: score / 100,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                        strokeWidth: 6,
                      ),
                    ),
                    Text(
                      '$score',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: darkText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mağaza Profil Skoru',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: darkText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        score < 40
                            ? 'Profiliniz zayıf görünüyor, eksikleri tamamlayın.'
                            : (score < 75
                                ? 'Profiliniz iyi durumda, biraz daha güçlendirebilirsiniz.'
                                : 'Harika! Eksiksiz bir mağaza profili oluşturdunuz.'),
                        style: const TextStyle(
                          fontSize: 11,
                          color: mutedText,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Kontrol Listesi
          const Text(
            'Yayın Öncesi Kontrol Listesi',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),
          const SizedBox(height: 10),
          ...checklist.map((item) {
            final isComplete = item['isComplete'] as bool;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color:
                    isComplete
                        ? const Color(0xFFF8FAFC)
                        : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isComplete ? cardBorder : const Color(0xFFFDE68A),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isComplete
                        ? Icons.check_circle_rounded
                        : Icons.warning_amber_rounded,
                    color: isComplete ? Colors.green : Colors.amber.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color:
                                isComplete ? darkText : Colors.amber.shade900,
                          ),
                        ),
                        if (!isComplete) ...[
                          const SizedBox(height: 2),
                          Text(
                            item['missingText'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.amber.shade800,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 20),

          // Link kutusu
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.link_rounded, color: primaryColor, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'vitrinx.app/v/$slug',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: primaryColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // CTA
          _buildPublishButton(),
          if (_existingStoreToken != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton.icon(
                onPressed: _isDeleting ? null : _showDeleteConfirmation,
                icon:
                    _isDeleting
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.redAccent,
                          ),
                        )
                        : const Icon(Icons.delete_outline_rounded, size: 20),
                label: const Text(
                  'Mağazamı Sil',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildPublishButton() {
    return GestureDetector(
      onTap: _isPublishing ? null : _publish,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 58,
        decoration: BoxDecoration(
          gradient: _isPublishing ? null : ctaGradient,
          color: _isPublishing ? const Color(0xFFE2E8F0) : null,
          borderRadius: BorderRadius.circular(18),
          boxShadow:
              _isPublishing
                  ? []
                  : [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.38),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
        ),
        child: Center(
          child:
              _isPublishing
                  ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: mutedText,
                          strokeWidth: 2.5,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Yayınlanıyor...',
                        style: TextStyle(
                          color: mutedText,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  )
                  : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.rocket_launch_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Mağazamı Yayınla',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF10B981),
              size: 48,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Mağazanız Yayında! 🎉',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: darkText,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Müşterileriniz artık mağazanızı Keşfet sayfasında görebilir.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: mutedText, height: 1.5),
          ),
          const SizedBox(height: 28),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mağaza Linkiniz',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: mutedText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _publishedLink!,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: _publishedLink!),
                          );
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Link kopyalandı!'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Color(0xFF10B981),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text(
                          'Kopyala',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: darkText,
                          side: const BorderSide(color: cardBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ExploreScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.explore_rounded, size: 16),
                        label: const Text(
                          "Keşfet'te Gör",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_existingStoreToken != null) ...[
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _isDeleting ? null : _showDeleteConfirmation,
              icon:
                  _isDeleting
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.redAccent,
                        ),
                      )
                      : const Icon(Icons.delete_outline_rounded, size: 20),
              label: const Text(
                'Mağazamı Sil',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_step > 0)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _goBack,
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text(
                    'Geri',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: darkText,
                    side: const BorderSide(color: cardBorder, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            if (_step > 0) const SizedBox(width: 12),
            if (_step < 4)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _goNext,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text(
                    'İleri',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? errorText,
    ValueChanged<String>? onChanged,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: softText.withValues(alpha: 0.78),
              ),
            ),
            if (required)
              const Text(
                ' *',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: darkText,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: mutedText, size: 18),
            suffixIcon: suffixIcon,
            hintText: hint,
            hintStyle: TextStyle(
              color: mutedText.withValues(alpha: 0.58),
              fontSize: 14,
            ),
            filled: true,
            fillColor: errorText != null ? const Color(0xFFFFF1F1) : inputBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText != null ? Colors.redAccent : cardBorder,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText != null ? Colors.redAccent : cardBorder,
                width: errorText != null ? 1.5 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color:
                    errorText != null
                        ? Colors.redAccent
                        : const Color(0x66FF4D00),
                width: 1.5,
              ),
            ),
            errorText: errorText,
            errorStyle: const TextStyle(
              color: Colors.redAccent,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Kategori Kartı ─────────────────────────────────────────────────────────
class _CategoryCard extends StatelessWidget {
  final _Category category;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color:
              selected ? category.accent.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                selected
                    ? category.accent
                    : const Color.fromRGBO(15, 23, 42, 0.10),
            width: selected ? 2 : 1,
          ),
          boxShadow:
              selected
                  ? [
                    BoxShadow(
                      color: category.accent.withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : [
                    const BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.04),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: selected ? 52 : 44,
              height: selected ? 52 : 44,
              decoration: BoxDecoration(
                color:
                    selected
                        ? category.accent.withValues(alpha: 0.15)
                        : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  category.emoji,
                  style: TextStyle(fontSize: selected ? 26 : 22),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              category.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w900 : FontWeight.bold,
                color: selected ? category.accent : const Color(0xFF334155),
              ),
            ),
            if (selected) ...[
              const SizedBox(height: 4),
              Container(
                width: 20,
                height: 3,
                decoration: BoxDecoration(
                  color: category.accent,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

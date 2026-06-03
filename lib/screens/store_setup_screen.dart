import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/screens/explore_screen.dart';
import 'package:vitrinx/screens/landing_screen.dart';
import 'package:vitrinx/services/local_storage_keys.dart';
import 'package:vitrinx/services/store_publish_payload_builder.dart';

// ─── Kategori Modeli ────────────────────────────────────────────────────────
class _Category {
  final String label;
  final String emoji;
  final Color accent;
  const _Category(this.label, this.emoji, this.accent);
}

// ─── Ana Widget ─────────────────────────────────────────────────────────────
class StoreSetupScreen extends StatefulWidget {
  const StoreSetupScreen({super.key});

  @override
  State<StoreSetupScreen> createState() => _StoreSetupScreenState();
}

class _StoreSetupScreenState extends State<StoreSetupScreen>
    with TickerProviderStateMixin {
  // ── Renkler (editor_screen.dart ile birebir aynı) ─────────────────────────
  static const Color primaryColor = Color(0xFFFF4D00);
  static const Color secondaryColor = Color(0xFFB200FF);
  static const Color bgColor = Color(0xFFF6F8FC);
  static const Color cardBorder = Color.fromRGBO(15, 23, 42, 0.10);
  static const Color inputBg = Color(0xFFF1F5F9);
  static const Color darkText = Color(0xFF111827);
  static const Color mutedText = Color(0xFF64748B);
  static const Color softText = Color(0xFF334155);
  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, secondaryColor],
  );

  // ── Adım ──────────────────────────────────────────────────────────────────
  int _step = 0; // 0 = kategori, 1 = bilgiler, 2 = özet
  bool _isPublishing = false;
  bool _isDeleting = false;
  String? _publishedLink;
  String? _existingStoreToken;

  // ── Form state ──────────────────────────────────────────────────────────
  late final PageController _pageController;
  late final AnimationController _progressController;

  _Category? _selectedCategory;
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _waCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();

  String? _nameError;
  String? _waError;

  // ── Konum & KVKK state ───────────────────────────────────────────────────
  double? _latitude;
  double? _longitude;
  double? _locationAccuracyMeters;
  DateTime? _locationConsentAt;
  String? _locationSource;
  bool _kvkkConsent = false;
  bool _isLocating = false;
  String? _locationStatusMessage;

  // ── Kategoriler ───────────────────────────────────────────────────────────
  static const List<_Category> _categories = [
    _Category('Giyim & Butik', '🛍', Color(0xFFFF5A1F)),
    _Category('Gıda & Fırın', '🍞', Color(0xFFE67E22)),
    _Category('Kozmetik', '💄', Color(0xFFE91E8C)),
    _Category('Dekorasyon', '🪴', Color(0xFF27AE60)),
    _Category('Elektronik', '📱', Color(0xFF2563EB)),
    _Category('Kırtasiye', '📚', Color(0xFF7C3AED)),
    _Category('Diğer', '🏪', Color(0xFF64748B)),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _progressController.animateTo(0.34);
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
    _nameCtrl.text = data.name;
    _descCtrl.text = data.description;
    _waCtrl.text = data.whatsapp;
    _addressCtrl.text = data.address;
    _latitude = data.latitude;
    _longitude = data.longitude;
    _locationAccuracyMeters = data.locationAccuracyMeters;
    _locationConsentAt = data.locationConsentAt;
    _locationSource = data.locationSource;
    _kvkkConsent = data.latitude != null && data.longitude != null;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _waCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  // ── Navigasyon ────────────────────────────────────────────────────────────
  void _goNext() {
    if (_step == 0) {
      if (_selectedCategory == null) {
        _showError('Lütfen bir kategori seçin.');
        return;
      }
      _toStep(1);
    } else if (_step == 1) {
      if (!_validateStep2()) return;
      _toStep(2);
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
      (step + 1) / 3,
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

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocating = true;
      _locationStatusMessage = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationStatusMessage =
              'Konum servisleri devre dışı. Lütfen cihazınızda konumu açın.';
          _isLocating = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationStatusMessage =
                'Konum izni reddedildi. Konum almak için izin vermelisiniz.';
            _isLocating = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationStatusMessage =
              'Konum izinleri kalıcı olarak reddedildi. Tarayıcı ayarlarından izin verin.';
          _isLocating = false;
        });
        return;
      }

      LocationSettings locationSettings;
      if (kIsWeb) {
        locationSettings = WebSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: const Duration(seconds: 8),
          maximumAge: Duration.zero,
        );
      } else {
        locationSettings = const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 8),
        );
      }

      // Listen to the position stream to refine coordinates over a short window
      Position? bestPosition;
      final positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      );

      final completer = Completer<Position?>();
      StreamSubscription<Position>? subscription;

      subscription = positionStream.listen(
        (pos) {
          if (bestPosition == null || pos.accuracy < bestPosition!.accuracy) {
            bestPosition = pos;
          }
          // If accuracy is highly precise, complete early
          if (pos.accuracy <= 20) {
            completer.complete(pos);
          }
        },
        onError: (err) {
          if (!completer.isCompleted) {
            completer.completeError(err);
          }
        },
      );

      // Force resolution after 4 seconds with the best position found so far
      Future.delayed(const Duration(seconds: 4), () {
        if (!completer.isCompleted) {
          completer.complete(bestPosition);
        }
      });

      Position? position;
      try {
        position = await completer.future.timeout(const Duration(seconds: 8));
      } finally {
        await subscription.cancel();
      }

      // Fallback to single-shot if stream yielded no position
      position ??= await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      setState(() {
        _latitude = position!.latitude;
        _longitude = position.longitude;
        _locationAccuracyMeters = position.accuracy;
        _locationConsentAt = DateTime.now();
        _locationSource = 'geolocator';

        final accuracyStr = position.accuracy.toStringAsFixed(0);
        if (position.accuracy > 100) {
          _locationStatusMessage =
              'Konum alındı. Hata payı: yaklaşık $accuracyStr m. Hata payı yüksek. Daha iyi sonuç için açık alanda tekrar deneyebilirsiniz.';
        } else {
          _locationStatusMessage =
              'Konum alındı. Hata payı: yaklaşık $accuracyStr m.';
        }

        _isLocating = false;

        if (_addressCtrl.text.trim().isEmpty) {
          _addressCtrl.text = 'Koordinatlarla işaretlenen konum';
        }
      });
    } catch (e) {
      setState(() {
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('timeout') || errorStr.contains('time out')) {
          _locationStatusMessage =
              'Konum alınamadı. Lütfen tekrar deneyin veya adresi elle yazın.';
        } else {
          _locationStatusMessage = 'Konum alınırken hata oluştu: $e';
        }
        _isLocating = false;
      });
    }
  }

  // ── Yayınla ───────────────────────────────────────────────────────────────
  Future<void> _publish() async {
    if (_isPublishing) return;
    setState(() => _isPublishing = true);

    try {
      final name = _nameCtrl.text.trim();
      final builder = const StorePublishPayloadBuilder();
      final slug = builder.generateSlug(name);
      final existingToken = _existingStoreToken;
      final hasExistingStoreToken =
          existingToken != null && existingToken.trim().isNotEmpty;
      final editToken =
          hasExistingStoreToken ? existingToken.trim() : _generateToken();

      final client = Supabase.instance.client;

      // ── Slug çakışma kontrolü ──────────────────────────────────────────────
      if (!hasExistingStoreToken) {
        debugPrint('[StoreSetup] Slug kontrol ediliyor: $slug');
        final existing =
            await client
                .from('stores')
                .select('slug')
                .eq('slug', slug)
                .maybeSingle();

        if (existing != null) {
          throw Exception(
            'Bu mağaza adıyla bir sayfa zaten var. Lütfen farklı bir ad deneyin.',
          );
        }
      }

      // ── Token + StoreData ─────────────────────────────────────────────────
      final storeData = StoreData(
        name: name,
        description: _descCtrl.text.trim(),
        whatsapp: _waCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        isStore: true,
        kategori: _selectedCategory!.label,
        businessType: _selectedCategory!.label,
        status: 'Açık',
        latitude: _latitude,
        longitude: _longitude,
        locationAccuracyMeters: _locationAccuracyMeters,
        locationConsentAt: _locationConsentAt,
        locationSource: _locationSource,
      );

      // ── Payload oluştur ve logla ──────────────────────────────────────────
      final payload = builder.toStoreInsertMap(storeData, slug, editToken);
      if (client.auth.currentUser != null) {
        payload['user_id'] = client.auth.currentUser!.id;
      }
      debugPrint('[StoreSetup] INSERT payload:');
      payload.forEach((k, v) => debugPrint('  $k: $v'));

      // Zorunlu alanları doğrula
      assert(payload['is_store'] == true, 'is_store eksik veya false!');
      assert(
        payload['kategori'] != null &&
            (payload['kategori'] as String).isNotEmpty,
        'kategori eksik!',
      );
      assert(payload['is_published'] == true, 'is_published eksik!');
      assert(
        payload['slug'] != null && (payload['slug'] as String).isNotEmpty,
        'slug eksik!',
      );
      assert(payload.containsKey('edit_token'), 'edit_token eksik!');

      // ── Supabase insert ───────────────────────────────────────────────────
      if (hasExistingStoreToken) {
        debugPrint('[StoreSetup] Supabase update başlıyor...');
        final existingByToken =
            await client
                .from('stores')
                .select('edit_token')
                .eq('edit_token', editToken)
                .maybeSingle();

        if (existingByToken == null) {
          debugPrint(
            '[StoreSetup] Token ile kayıt bulunamadı, insert deneniyor...',
          );
          await client.from('stores').insert(payload);
        } else {
          await client
              .from('stores')
              .update(payload)
              .eq('edit_token', editToken);
        }
        debugPrint('[StoreSetup] Supabase kayıt güncelleme başarılı ✓');
      } else {
        debugPrint('[StoreSetup] Supabase insert başlıyor...');
        await client.from('stores').insert(payload);
        debugPrint('[StoreSetup] Supabase insert başarılı ✓');
      }

      // ── Yerel kayıt ──────────────────────────────────────────────────────
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(LocalStorageKeys.storeEditToken, editToken);
      await prefs.setString(
        LocalStorageKeys.storeData,
        jsonEncode(storeData.toJson()),
      );
      final legacyData = _readSavedStoreData(
        prefs.getString(LocalStorageKeys.vitrinData),
      );
      if (legacyData != null && legacyData.isStore) {
        await prefs.remove(LocalStorageKeys.vitrinData);
      }

      final link = 'https://vitrinx.app/v/$slug';
      debugPrint('[StoreSetup] Mağaza yayınlandı: $link');
      debugPrint(
        '[StoreSetup] Keşfet kontrolü: slug=$slug, name=$name, '
        'is_store=${payload['is_store']}, '
        'is_published=${payload['is_published']}, '
        'kategori=${payload['kategori']}',
      );

      if (!mounted) return;
      setState(() {
        _publishedLink = link;
        _existingStoreToken = editToken;
      });
    } on PostgrestException catch (e) {
      debugPrint('[StoreSetup] Supabase PostgrestException:');
      debugPrint('  code   : ${e.code}');
      debugPrint('  message: ${e.message}');
      debugPrint('  details: ${e.details}');
      debugPrint('  hint   : ${e.hint}');
      if (!mounted) return;
      final msg = _supabaseErrorToTurkish(e);
      _showErrorSnackbar(msg);
    } catch (e, st) {
      debugPrint('[StoreSetup] Beklenmeyen hata: $e');
      debugPrint('$st');
      if (!mounted) return;
      final raw = e.toString().replaceAll('Exception: ', '');
      _showErrorSnackbar(raw);
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  /// Supabase hata kodunu Türkçe mesaja çevirir.
  String _supabaseErrorToTurkish(PostgrestException e) {
    final code = e.code ?? '';
    final msg = e.message.toLowerCase();

    // RLS / yetki hatası
    if (code == '42501' ||
        msg.contains('row-level security') ||
        msg.contains('permission denied')) {
      return 'Sunucu güvenlik kuralı engeli (RLS). Lütfen yöneticinizle iletişime geçin.';
    }
    // Benzersizlik ihlali (unique constraint)
    if (code == '23505' ||
        msg.contains('unique') ||
        msg.contains('duplicate')) {
      if (msg.contains('slug')) {
        return 'Bu mağaza adresi (slug) zaten kullanılıyor. Farklı bir mağaza adı deneyin.';
      }
      return 'Bu bilgilerle kayıtlı bir mağaza zaten var.';
    }
    // Zorunlu alan eksik (not-null constraint)
    if (code == '23502' ||
        msg.contains('null value') ||
        msg.contains('not-null')) {
      return 'Eksik zorunlu alan: ${e.details ?? e.message}. Lütfen tüm alanları doldurun.';
    }
    // Tablo bulunamadı
    if (code == '42P01' || msg.contains('does not exist')) {
      return '"stores" tablosu bulunamadı. Veritabanı yapılandırmasını kontrol edin.';
    }
    if (code == 'PGRST204' || msg.contains('schema cache')) {
      return 'Supabase şema güncellemesi eksik. Konum kolonları ve schema cache yenilemesi uygulanmalı.';
    }
    // Ağ / JWT hatası
    if (msg.contains('jwt') || msg.contains('token')) {
      return 'Oturum süresi dolmuş olabilir. Uygulamayı yeniden başlatın.';
    }
    // Genel hata
    return 'Sunucu hatası (${e.code}): ${e.message}';
  }

  void _showErrorSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _deleteStore() async {
    if (_isDeleting) return;
    setState(() => _isDeleting = true);

    try {
      final token = _existingStoreToken;
      if (token != null && token.isNotEmpty) {
        final client = Supabase.instance.client;
        debugPrint('[StoreSetup] Mağaza siliniyor, token: $token');
        await client.from('stores').delete().eq('edit_token', token);
        debugPrint('[StoreSetup] Mağaza veritabanından silindi ✓');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(LocalStorageKeys.storeEditToken);
      await prefs.remove(LocalStorageKeys.storeData);
      final legacyData = _readSavedStoreData(
        prefs.getString(LocalStorageKeys.vitrinData),
      );
      if (legacyData != null && legacyData.isStore) {
        await prefs.remove(LocalStorageKeys.vitrinData);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mağazanız başarıyla silindi.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF10B981),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LandingScreen()),
        (route) => false,
      );
    } catch (e) {
      debugPrint('[StoreSetup] Silme hatası: $e');
      if (!mounted) return;
      _showErrorSnackbar(
        'Mağaza silinirken bir hata oluştu. Lütfen tekrar deneyin.',
      );
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.redAccent,
                size: 24,
              ),
              SizedBox(width: 10),
              Text(
                'Mağazayı Sil',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: darkText,
                ),
              ),
            ],
          ),
          content: const Text(
            'Bu işlem geri alınamaz. Mağazanız tamamen silinecektir. Devam etmek istiyor musunuz?',
            style: TextStyle(color: softText, fontSize: 14, height: 1.5),
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Vazgeç',
                style: TextStyle(fontWeight: FontWeight.bold, color: mutedText),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteStore();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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

  String _generateToken() {
    final rand = Random.secure();
    final bytes = List<int>.generate(32, (_) => rand.nextInt(256));
    final ts = utf8.encode(DateTime.now().microsecondsSinceEpoch.toString());
    return base64Url.encode([...ts, ...bytes]).replaceAll('=', '');
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
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
              children: [_buildStep1(), _buildStep2(), _buildStep3()],
            ),
          ),
          if (_publishedLink == null) _buildBottomNav(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final titles = ['Kategori Seç', 'Mağaza Bilgileri', 'Özet & Yayınla'];
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

  // ── Step Header ──────────────────────────────────────────────────────────
  Widget _buildStepHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      child: Column(
        children: [
          // Step bullets
          Row(
            children: List.generate(3, (i) {
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
                                    fontWeight: FontWeight.w900,
                                    fontSize: active ? 14 : 12,
                                  ),
                                ),
                      ),
                    ),
                    if (i < 2)
                      Expanded(
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color:
                                i < _step
                                    ? primaryColor
                                    : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          // Progress bar
          AnimatedBuilder(
            animation: _progressController,
            builder: (_, __) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progressController.value,
                  minHeight: 5,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: const AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Adım ${_step + 1}/3',
                style: const TextStyle(
                  color: primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                ['Kategori seçin', 'Bilgileri doldurun', 'Yayınlayın'][_step],
                style: const TextStyle(
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

  // ── ADIM 1: Kategori ─────────────────────────────────────────────────────
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
          const SizedBox(height: 24),
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
                onTap: () => setState(() => _selectedCategory = cat),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── ADIM 2: Bilgiler ──────────────────────────────────────────────────────
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mağazanızı tanıtalım',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: darkText,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Müşterilerinizin sizi bulabilmesi için bu bilgileri doldurun.',
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
            label: 'Adres',
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
          if (_locationStatusMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _locationStatusMessage!,
              style: TextStyle(
                fontSize: 12,
                color:
                    _latitude != null
                        ? Colors.green.shade700
                        : Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          const SizedBox(height: 80), // nav için alan bırak
        ],
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

  // ── ADIM 3: Özet & Yayınla ───────────────────────────────────────────────
  Widget _buildStep3() {
    if (_publishedLink != null) return _buildSuccessView();
    // PageView tüm sayfaları başlatır; kategori seçilmemişse boş döndür
    if (_selectedCategory == null) return const SizedBox.shrink();

    final name = _nameCtrl.text.trim().isEmpty ? '—' : _nameCtrl.text.trim();
    final desc = _descCtrl.text.trim().isEmpty ? '—' : _descCtrl.text.trim();
    final wa = _waCtrl.text.trim().isEmpty ? '—' : _waCtrl.text.trim();
    final addr =
        _addressCtrl.text.trim().isEmpty ? '—' : _addressCtrl.text.trim();
    final slug = const StorePublishPayloadBuilder().generateSlug(
      _nameCtrl.text.trim(),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Her şey hazır!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: darkText,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Bilgilerinizi kontrol edin ve yayınlayın.',
            style: TextStyle(fontSize: 14, color: mutedText),
          ),
          const SizedBox(height: 24),

          // Kategori özet kartı
          _SummaryCard(
            icon: _selectedCategory!.emoji,
            title: 'Kategori',
            value: _selectedCategory!.label,
            accent: _selectedCategory!.accent,
          ),
          const SizedBox(height: 12),
          _SummaryCard(
            icon: '🏪',
            title: 'Mağaza Adı',
            value: name,
            accent: primaryColor,
          ),
          const SizedBox(height: 12),
          _SummaryCard(
            icon: '📝',
            title: 'Açıklama',
            value: desc,
            accent: const Color(0xFF64748B),
          ),
          const SizedBox(height: 12),
          _SummaryCard(
            icon: '📱',
            title: 'WhatsApp',
            value: wa,
            accent: const Color(0xFF25D366),
          ),
          const SizedBox(height: 12),
          _SummaryCard(
            icon: '📍',
            title: 'Adres',
            value: addr,
            accent: const Color(0xFF2563EB),
          ),
          const SizedBox(height: 16),

          // Vitrin linki önizleme
          Container(
            padding: const EdgeInsets.all(16),
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

  // ── Başarı Görünümü ───────────────────────────────────────────────────────
  Widget _buildSuccessView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          // Onay ikonu
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
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: darkText,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Müşterileriniz artık mağazanızı Keşfet sayfasında görebilir.',
            style: TextStyle(fontSize: 14, color: mutedText, height: 1.5),
          ),
          const SizedBox(height: 28),

          // Link kutusu
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

  // ── Alt Navigasyon Butonları ──────────────────────────────────────────────
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
            if (_step < 2)
              Expanded(
                flex: _step == 0 ? 1 : 1,
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

// ─── Özet Kartı ─────────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final String icon;
  final String title;
  final String value;
  final Color accent;

  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color.fromRGBO(15, 23, 42, 0.10)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

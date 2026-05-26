import 'dart:convert';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/services/store_publish_service.dart';
import 'package:vitrinx/services/store_shelf_upload_service.dart';
import 'package:vitrinx/theme/vitrin_theme_preset.dart';
import 'package:vitrinx/widgets/vitrin_view.dart';
import 'package:vitrinx/screens/preview_screen.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TabController _mobileTabController;
  final StoreData _data = StoreData(isEsnafMode: false);
  bool _isLoading = true;
  bool _isGoogleAssistantOpen = false;
  bool _isPublishing = false;
  bool _isUploadingShelf = false;
  String? _publishedLink;
  String? _publishError;
  Uint8List? _selectedShelfBytes;
  String? _selectedShelfFileName;
  String _selectedShelfExtension = 'jpg';
  String _selectedShelfContentType = 'image/jpeg';

  // Premium dark editor palette
  static const Color primaryColor = Color(0xFFFF4D00);
  static const Color secondaryColor = Color(0xFFB200FF);
  static const Color bgColor = Color(0xFF121322);
  static const Color cardBorder = Color.fromRGBO(255, 255, 255, 0.12);
  static const Color inputBg = Color.fromRGBO(255, 255, 255, 0.095);
  static const Color darkText = Color(0xFFF8FAFC);
  static const Color mutedText = Color(0xFF94A3B8);
  static const Color softText = Color(0xFFCBD5E1);
  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, secondaryColor],
  );
  static const String _editTokenPrefsKey = 'vitrin_edit_token';

  final List<String> businessTypes = const [
    'Butik',
    'İç giyim',
    'Kozmetik',
    'Hediyelik',
    'Market',
    'Telefon aksesuarı',
    'Kafe / Lokanta',
    'Kuaför',
    'Diğer',
  ];

  final List<String> themes = const [
    'Sade',
    'Premium',
    'Zarif',
    'Doğal',
    'Gece',
    'Lüks',
    'Sahil',
    'Güneş',
  ];

  final List<String> statuses = const [
    'Açık',
    'Bugün kampanya var',
    'Yeni ürünler geldi',
    'Stok sınırlı',
  ];

  final List<String> platforms = const [
    'Trendyol',
    'Hepsiburada',
    'N11',
    'Amazon',
    'Çiçeksepeti',
    'Shopier',
    'Diğer',
  ];

  @override
  void initState() {
    super.initState();
    _mobileTabController = TabController(length: 3, vsync: this);
    _loadSavedData();
  }

  @override
  void dispose() {
    _mobileTabController.dispose();
    super.dispose();
  }

  void _closeGoogleAssistant() {
    setState(() => _isGoogleAssistantOpen = false);
  }

  void _toggleGoogleAssistant() {
    if (_isGoogleAssistantOpen) {
      _closeGoogleAssistant();
      return;
    }

    setState(() => _isGoogleAssistantOpen = true);
  }

  Future<void> _loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedJson = prefs.getString('vitrin_data');
      if (savedJson != null) {
        final Map<String, dynamic> jsonData = jsonDecode(savedJson);
        final loadedData = StoreData.fromJson(jsonData);
        setState(() {
          _data.name = loadedData.name;
          _data.businessType = loadedData.businessType;
          _data.description = loadedData.description;
          _data.whatsapp = loadedData.whatsapp;
          _data.instagram = loadedData.instagram;
          _data.website = loadedData.website;
          _data.address = loadedData.address;
          _data.theme = loadedData.theme;
          _data.status = loadedData.status;
          _data.isEsnafMode = loadedData.isEsnafMode;
          _data.corporateBio = loadedData.corporateBio;
          _data.referencesLink = loadedData.referencesLink;
          _data.shelfImageUrl = loadedData.shelfImageUrl;
          _data.marketplaceLinks = loadedData.marketplaceLinks;
          _data.products = loadedData.products;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Data load error: $e');
      if (!mounted) return;

      setState(() => _isLoading = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Vitrin verileri yüklenemedi, varsayılan değerler kullanılıyor.',
            ),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      });
    }
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonData = jsonEncode(_data.toJson());
      await prefs.setString('vitrin_data', jsonData);
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.cloud_done_outlined, color: Colors.white),
                SizedBox(width: 12),
                Text('Vitrin başarıyla kaydedildi'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: primaryColor,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _publishStore() async {
    if (_isPublishing) return;

    setState(() {
      _isPublishing = true;
      _isUploadingShelf = _selectedShelfBytes != null;
      _publishedLink = null;
      _publishError = null;
    });

    var shelfUploadFailed = false;

    try {
      final selectedShelfBytes = _selectedShelfBytes;
      if (selectedShelfBytes != null) {
        try {
          final uploadedUrl = await const StoreShelfUploadService()
              .uploadShelfImage(
                selectedShelfBytes,
                _generateStoreSlug(_data.name),
                fileExtension: _selectedShelfExtension,
                contentType: _selectedShelfContentType,
              );

          _data.shelfImageUrl = uploadedUrl;
        } catch (uploadError) {
          shelfUploadFailed = true;
          _data.shelfImageUrl = '';
          debugPrint('Shelf image upload error: $uploadError');
        } finally {
          if (mounted) {
            setState(() => _isUploadingShelf = false);
          }
        }
      }

      final editToken = await _loadOrCreateEditToken();
      final publishResult = await const StorePublishService().publishStore(
        _data,
        editToken: editToken,
      );
      final publicLink = _buildFullPublicLink(publishResult.publicPath);
      if (!mounted) return;

      final publishSnackMessage =
          shelfUploadFailed
              ? 'Fotoğraf yüklenemedi, vitrin fotoğrafsız yayınlandı.'
              : publishResult.wasUpdated
              ? 'Vitrininiz güncellendi.'
              : 'Vitrin linkiniz hazırlandı.';
      setState(() => _publishedLink = publicLink);
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(publishSnackMessage),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (error) {
      debugPrint('Publish store error: $error');
      if (!mounted) return;

      final userMessage =
          error is StorePublishException
              ? error.message
              : 'Vitrin bağlantısı hazırlanamadı. Supabase ayarlarını veya izinleri kontrol edin.';
      setState(() {
        _publishError = userMessage;
      });
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userMessage),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPublishing = false;
          _isUploadingShelf = false;
        });
      }
    }
  }

  Future<void> _copyPublishedLink(String message) async {
    final link = _publishedLink;
    if (link == null || link.trim().isEmpty) return;

    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<String> _loadOrCreateEditToken() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString(_editTokenPrefsKey);
    if (savedToken != null && savedToken.trim().isNotEmpty) {
      return savedToken;
    }

    final token = _generateEditToken();
    await prefs.setString(_editTokenPrefsKey, token);
    return token;
  }

  String _generateEditToken() {
    Random random;
    try {
      random = Random.secure();
    } catch (_) {
      random = Random();
    }

    final randomBytes = List<int>.generate(32, (_) => random.nextInt(256));
    final timestampBytes = utf8.encode(
      DateTime.now().microsecondsSinceEpoch.toString(),
    );
    return base64Url
        .encode([...timestampBytes, ...randomBytes])
        .replaceAll('=', '');
  }

  Future<void> _pickShelfPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.image,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    if (file.size > 5 * 1024 * 1024) {
      _showInfoSnackBar("Fotoğraf 5 MB'tan büyük olamaz.");
      return;
    }

    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      _showInfoSnackBar('Fotoğraf okunamadı. Lütfen başka bir görsel deneyin.');
      return;
    }

    final extension = (file.extension ?? 'jpg').toLowerCase();
    final contentType = _contentTypeForShelfExtension(extension);
    if (contentType == null) {
      _showInfoSnackBar('Sadece JPG, PNG veya WEBP görsel seçebilirsiniz.');
      return;
    }

    setState(() {
      _selectedShelfBytes = bytes;
      _selectedShelfFileName = file.name;
      _selectedShelfExtension = extension == 'jpeg' ? 'jpg' : extension;
      _selectedShelfContentType = contentType;
    });
  }

  void _clearShelfPhoto() {
    setState(() {
      _selectedShelfBytes = null;
      _selectedShelfFileName = null;
      _data.shelfImageUrl = '';
    });
  }

  String? _contentTypeForShelfExtension(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return null;
    }
  }

  void _showInfoSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _addMarketplaceLink() {
    setState(() {
      _data.marketplaceLinks.add(
        MarketplaceLink(id: DateTime.now().millisecondsSinceEpoch.toString()),
      );
    });
  }

  void _removeMarketplaceLink(int index) {
    setState(() {
      _data.marketplaceLinks.removeAt(index);
    });
  }

  int _calculateVitrinScore(StoreData data) {
    final score = _buildVitrinScoreTasks(data).fold<int>(
      0,
      (total, task) => task.isComplete ? total + task.points : total,
    );

    return score.clamp(0, 100).toInt();
  }

  bool _hasCompleteMarketplaceLink(StoreData data) {
    return _completeMarketplaceLinks(data).isNotEmpty;
  }

  List<MarketplaceLink> _completeMarketplaceLinks(StoreData data) {
    return data.marketplaceLinks
        .where(
          (link) =>
              link.platform.trim().isNotEmpty && link.url.trim().isNotEmpty,
        )
        .toList();
  }

  bool _hasSupportingVitrinContent(StoreData data) {
    final hasLogo = data.logoUrl?.trim().isNotEmpty ?? false;
    final hasCorporateInfo = data.corporateBio.trim().isNotEmpty;
    final hasCatalogItem = data.products.any(
      (product) =>
          product.name.trim().isNotEmpty ||
          product.price.trim().isNotEmpty ||
          product.description.trim().isNotEmpty ||
          product.imagePath?.trim().isNotEmpty == true,
    );

    return hasLogo || hasCorporateInfo || hasCatalogItem;
  }

  List<_VitrinScoreTask> _buildVitrinScoreTasks(StoreData data) {
    final descriptionLength = data.description.trim().length;

    return [
      _VitrinScoreTask(
        points: 20,
        isComplete: data.name.trim().isNotEmpty,
        suggestion: 'Mağaza adını ekle',
      ),
      _VitrinScoreTask(
        points: 15,
        isComplete: data.whatsapp.trim().isNotEmpty,
        suggestion: 'WhatsApp numarası ekle',
      ),
      _VitrinScoreTask(
        points: 15,
        isComplete: descriptionLength >= 10,
        suggestion:
            descriptionLength == 0
                ? 'Kısa açıklama yaz'
                : 'Kısa açıklamayı güçlendir $descriptionLength/10',
      ),
      _VitrinScoreTask(
        points: 10,
        isComplete:
            data.instagram.trim().isNotEmpty || data.website.trim().isNotEmpty,
        suggestion: 'Instagram veya web sitesi ekle',
      ),
      _VitrinScoreTask(
        points: 10,
        isComplete: data.address.trim().isNotEmpty,
        suggestion: 'Adres bilgisini ekle',
      ),
      _VitrinScoreTask(
        points: 15,
        isComplete: _hasCompleteMarketplaceLink(data),
        suggestion: 'En az 1 pazaryeri linki ekle',
      ),
      _VitrinScoreTask(
        points: 10,
        isComplete: _hasSupportingVitrinContent(data),
        suggestion: 'Logo, ürün veya hakkımızda bilgisi ekle',
      ),
      _VitrinScoreTask(
        points: 5,
        isComplete: data.theme.trim().isNotEmpty && data.theme.trim() != 'Sade',
        suggestion: 'Vitrine uygun bir tema seç',
      ),
    ];
  }

  List<String> _buildVitrinScoreSuggestions(StoreData data) {
    final tasks = _buildVitrinScoreTasks(data);

    return tasks
        .where((task) => !task.isComplete)
        .map((task) => task.suggestion)
        .take(3)
        .toList();
  }

  String _vitrinScoreStatusText(int score) {
    if (score < 40) return 'Vitrinin henüz hazır değil.';
    if (score < 70) return 'Vitrinin gelişiyor.';
    if (score < 90) return 'Vitrinin iyi durumda.';
    return 'Vitrinin güçlü görünüyor.';
  }

  String _vitrinScoreBadgeText(int score) {
    if (score < 40) return 'Hazırlanıyor';
    if (score < 70) return 'Gelişiyor';
    if (score < 90) return 'İyi durumda';
    return 'Güçlü';
  }

  Color _vitrinScoreTone(int score) {
    if (score < 40) return const Color(0xFF64748B);
    if (score < 70) return const Color(0xFF475569);
    if (score < 90) return const Color(0xFF0F766E);
    return const Color(0xFF047857);
  }

  Color _mobileVitrinScoreTone(int score) {
    if (score < 40) return const Color(0xFFEA580C);
    if (score < 80) return const Color(0xFFD97706);
    return const Color(0xFF059669);
  }

  String _mobileVitrinScoreLabel(int score) {
    if (score < 40) return 'Eksik';
    if (score < 80) return 'Gelişiyor';
    return 'Güçlü';
  }

  List<String> _buildVitrinScoreSheetSuggestions() {
    final suggestions =
        _buildVitrinScoreTasks(_data)
            .where((task) => !task.isComplete)
            .map((task) => task.suggestion)
            .toList();

    final hasShelfPhoto =
        _selectedShelfBytes != null || _data.shelfImageUrl.trim().isNotEmpty;
    if (!hasShelfPhoto && !suggestions.contains('Raf / reyon fotoğrafı ekle')) {
      suggestions.add('Raf / reyon fotoğrafı ekle');
    }

    return suggestions;
  }

  void _focusMobileEditTab() {
    if (_mobileTabController.index != 0) {
      _mobileTabController.animateTo(0);
    }
  }

  void _handleScoreTaskCompleteTap() {
    Navigator.of(context).maybePop();
    _focusMobileEditTab();
  }

  Future<void> _showVitrinScoreSheet() async {
    final score = _calculateVitrinScore(_data);
    final tone = _mobileVitrinScoreTone(score);
    final suggestions = _buildVitrinScoreSheetSuggestions();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: EdgeInsets.only(
              left: 18,
              right: 18,
              top: 14,
              bottom: 18 + MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF11111A),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 32,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              tone.withValues(alpha: 0.16),
                              tone.withValues(alpha: 0.06),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: tone.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Icon(
                          Icons.workspace_premium_rounded,
                          color: tone,
                          size: 23,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Vitrin Skoru',
                              style: TextStyle(
                                color: darkText,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Vitrininizi güçlendirmek için eksik adımları tamamlayın.',
                              style: TextStyle(
                                color: softText.withValues(alpha: 0.75),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '$score/100',
                        style: const TextStyle(
                          color: darkText,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: score / 100,
                      minHeight: 5,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(tone),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _vitrinScoreStatusText(score),
                    style: TextStyle(
                      color: tone,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    suggestions.isEmpty ? 'Her şey hazır' : 'Eksik adımlar',
                    style: const TextStyle(
                      color: darkText,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (suggestions.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: const Text(
                        'Vitrinin güçlü görünüyor. Yayınla sekmesinden public linkini hazırlayabilirsin.',
                        style: TextStyle(
                          color: Color(0xFF166534),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    )
                  else
                    ...suggestions.map(
                      (suggestion) => _buildScoreSheetTaskRow(suggestion, tone),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScoreSheetTaskRow(String suggestion, Color tone) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(Icons.checklist_rounded, color: tone, size: 15),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              suggestion,
              style: TextStyle(
                color: softText.withValues(alpha: 0.9),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _handleScoreTaskCompleteTap,
            style: TextButton.styleFrom(
              foregroundColor: tone,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              minimumSize: const Size(44, 34),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Tamamla',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileVitrinScoreBadge() {
    final score = _calculateVitrinScore(_data);
    final tone = _mobileVitrinScoreTone(score);

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showVitrinScoreSheet,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 38,
            padding: const EdgeInsets.only(left: 8, right: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  tone.withValues(alpha: 0.14),
                  tone.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: tone.withValues(alpha: 0.22)),
              boxShadow: [
                BoxShadow(
                  color: tone.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.84),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    color: tone,
                    size: 15,
                  ),
                ),
                const SizedBox(width: 7),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$score/100',
                      style: const TextStyle(
                        color: darkText,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _mobileVitrinScoreLabel(score),
                      style: TextStyle(
                        color: tone,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _premiumCardDecoration({double radius = 24}) {
    return BoxDecoration(
      color: const Color.fromRGBO(31, 28, 44, 0.82),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: cardBorder, width: 1),
      boxShadow: const [
        BoxShadow(
          color: Color.fromRGBO(0, 0, 0, 0.38),
          blurRadius: 24,
          offset: Offset(0, 12),
        ),
        BoxShadow(
          color: Color.fromRGBO(178, 0, 255, 0.08),
          blurRadius: 38,
          offset: Offset(0, 0),
        ),
      ],
    );
  }

  BoxDecoration _studioFrameDecoration() {
    return BoxDecoration(
      color: const Color.fromRGBO(24, 22, 36, 0.94),
      borderRadius: BorderRadius.circular(32),
      border: Border.all(color: cardBorder),
      boxShadow: const [
        BoxShadow(
          color: Color.fromRGBO(0, 0, 0, 0.46),
          blurRadius: 34,
          offset: Offset(0, 18),
        ),
        BoxShadow(
          color: Color.fromRGBO(255, 77, 0, 0.10),
          blurRadius: 56,
          offset: Offset(-16, 0),
        ),
        BoxShadow(
          color: Color.fromRGBO(178, 0, 255, 0.10),
          blurRadius: 70,
          offset: Offset(18, 20),
        ),
      ],
    );
  }

  Widget _buildEditorBackdrop({required Widget child}) {
    return Stack(
      children: [
        const Positioned.fill(
          child: CustomPaint(painter: _EditorGridPainter()),
        ),
        Positioned(
          top: -180,
          left: -170,
          child: IgnorePointer(
            child: Container(
              width: 460,
              height: 460,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x2AFF5E1A), Colors.transparent],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: -180,
          bottom: -210,
          child: IgnorePointer(
            child: Container(
              width: 520,
              height: 520,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x22B200FF), Colors.transparent],
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }

  Widget _gradientUnderline({double width = 58}) {
    return Container(
      width: width,
      height: 4,
      decoration: BoxDecoration(
        gradient: ctaGradient,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }

  Widget _buildStudioTopBar() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Color.fromRGBO(255, 255, 255, 0.035),
        border: Border(bottom: BorderSide(color: cardBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: ctaGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: secondaryColor.withValues(alpha: 0.24),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'VX',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VitrinX Studio',
                  style: TextStyle(
                    color: darkText,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Esnaf vitrini için canlı editör',
                  style: TextStyle(
                    color: mutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: cardBorder),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome_rounded, color: primaryColor, size: 15),
                SizedBox(width: 7),
                Text(
                  'Premium vitrin oluşturucu',
                  style: TextStyle(
                    color: softText,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientButton({
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    Widget? child,
    bool expand = false,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      horizontal: 28,
      vertical: 12,
    ),
  }) {
    final content =
        child ??
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );

    final button = Opacity(
      opacity: onPressed == null ? 0.62 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: ctaGradient,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: secondaryColor.withValues(alpha: 0.22),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(40),
            child: Padding(padding: padding, child: content),
          ),
        ),
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(18, 19, 34, 0.94),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: darkText,
        shape: const Border(bottom: BorderSide(color: cardBorder)),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: darkText,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Text(
              'Vitrin Düzenle',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: darkText,
                fontSize: 18,
              ),
            ),
            if (isWide) ...[
              const Spacer(),
              Text(
                'VITRINX',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: primaryColor.withValues(alpha: 0.62),
                  fontSize: 12,
                  letterSpacing: 0,
                ),
              ),
            ],
          ],
        ),
        actions:
            isWide
                ? [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: _buildGradientButton(
                      label: 'Kaydet',
                      onPressed: _saveData,
                      icon: Icons.cloud_done_outlined,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 12.0,
                    ),
                    child: _buildGradientButton(
                      label: 'Ã–nizle & PaylaÅŸ',
                      icon: Icons.visibility_rounded,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PreviewScreen(storeData: _data),
                          ),
                        );
                      },
                      child: const Text(
                        'Önizle & Paylaş',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ]
                : [_buildMobileVitrinScoreBadge()],
      ),
      bottomNavigationBar: !isWide ? _buildMobileBottomActions() : null,
      body: _buildEditorBackdrop(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 900;

            if (!isWide) {
              return DefaultTabController(
                length: 3,
                child: Column(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        color: Color.fromRGBO(22, 22, 36, 0.88),
                        border: Border(bottom: BorderSide(color: cardBorder)),
                      ),
                      child: TabBar(
                        controller: _mobileTabController,
                        labelColor: primaryColor,
                        unselectedLabelColor: mutedText,
                        indicatorColor: primaryColor,
                        tabs: const [
                          Tab(text: 'Düzenle'),
                          Tab(text: 'Canlı Önizleme'),
                          Tab(text: 'Yayınla'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _mobileTabController,
                        children: [
                          SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 800,
                                ),
                                child: _buildForm(showScoreCard: false),
                              ),
                            ),
                          ),
                          LayoutBuilder(
                            builder: (context, previewConstraints) {
                              return Center(
                                child: _buildLivePreviewMockup(
                                  previewConstraints,
                                ),
                              );
                            },
                          ),
                          SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 800,
                                ),
                                child: _buildPublishPanel(),
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

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  width: min(constraints.maxWidth - 48, 1360),
                  height: max(0, constraints.maxHeight - 48),
                  clipBehavior: Clip.antiAlias,
                  decoration: _studioFrameDecoration(),
                  child: Column(
                    children: [
                      _buildStudioTopBar(),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(
                                  34,
                                  30,
                                  28,
                                  34,
                                ),
                                child: Center(
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      maxWidth: 780,
                                    ),
                                    child: _buildForm(
                                      showDesktopPublishCard: true,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const VerticalDivider(width: 1, color: cardBorder),
                            Expanded(
                              flex: 4,
                              child: LayoutBuilder(
                                builder: (context, previewConstraints) {
                                  return Center(
                                    child: _buildLivePreviewMockup(
                                      previewConstraints,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildForm({
    bool showDesktopPublishCard = false,
    bool showScoreCard = true,
  }) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showScoreCard) _buildVitrinScoreCard(),
          if (showDesktopPublishCard) ...[
            SizedBox(height: showScoreCard ? 16 : 0),
            _buildPublishPanel(compact: true, includeBottomSpacing: false),
          ],
          SizedBox(height: showScoreCard || showDesktopPublishCard ? 24 : 0),
          _buildEditCard(
            title: 'Mağaza Görünümü',
            headerWidget: _buildCompactStatusDropdown(),
            children: [
              _buildLogoUpload(),
              const SizedBox(height: 20),
              _buildTextField(
                'Mağaza adı',
                (v) => setState(() => _data.name = v),
                initial: _data.name,
              ),
              const SizedBox(height: 16),
              _buildDropdown(
                'İşletme türü',
                _data.businessType,
                businessTypes,
                (v) => setState(() => _data.businessType = v!),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                'Kısa açıklama (Vitrin Altı)',
                (v) => setState(() => _data.description = v),
                maxLines: 2,
                initial: _data.description,
                hintText: 'İşletmenizi kısaca anlatın',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildEditCard(
            title: 'Kurumsal Bilgiler',
            children: [
              _buildTextField(
                'Hakkımızda Metni',
                (v) => setState(() => _data.corporateBio = v),
                maxLines: 4,
                initial: _data.corporateBio,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                'Referans / yorum linki',
                (v) => setState(() => _data.referencesLink = v),
                prefixIcon: Icons.verified_rounded,
                initial: _data.referencesLink,
                hintText:
                    'Örn: Google yorumları, Instagram öne çıkanlar veya web sayfanız',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildEditCard(
            title: 'İletişim & Sosyal',
            children: [
              _buildTextField(
                'WhatsApp',
                (v) => setState(() => _data.whatsapp = v),
                prefixIcon: Icons.phone_rounded,
                initial: _data.whatsapp,
                hintText: 'Örn: 05xx xxx xx xx',
              ),
              const SizedBox(height: 12),
              _buildTextField(
                'Instagram',
                (v) => setState(() => _data.instagram = v),
                prefixIcon: Icons.camera_alt_rounded,
                initial: _data.instagram,
                hintText: 'Örn: instagram.com/magazaniz',
              ),
              const SizedBox(height: 12),
              _buildTextField(
                'Web sitesi',
                (v) => setState(() => _data.website = v),
                prefixIcon: Icons.language_rounded,
                initial: _data.website,
                hintText: 'Örn: www.magazaniz.com',
              ),
              const SizedBox(height: 12),
              _buildTextField(
                'Adres',
                (v) => setState(() => _data.address = v),
                prefixIcon: Icons.location_on_rounded,
                maxLines: 2,
                initial: _data.address,
                hintText: 'Örn: Mahalle, cadde, ilçe',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildEditCard(
            title: 'Pazaryeri Linkleri',
            onAction: _addMarketplaceLink,
            children: [
              ...List.generate(
                _data.marketplaceLinks.length,
                (index) => _buildMarketplaceLinkItem(index),
              ),
              if (_data.marketplaceLinks.isEmpty)
                Center(
                  child: Text(
                    'Henüz link eklenmedi.',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Builder(
            builder: (context) {
              final isDesktop = MediaQuery.of(context).size.width >= 800;
              final children = [_buildThemeSelector()];

              if (isDesktop) {
                return _buildEditCard(title: 'Tema Seçimi', children: children);
              }

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cardBorder),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tema Seçimi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: darkText,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildThemeSelector(limit: 2, showTitle: false),
                    Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        initiallyExpanded: false,
                        tilePadding: EdgeInsets.zero,
                        iconColor: primaryColor,
                        collapsedIconColor: Colors.grey,
                        title: const Text(
                          'Diğer Temaları Göster',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: primaryColor,
                          ),
                        ),
                        children: [
                          _buildThemeSelector(skip: 2, showTitle: false),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildVitrinScoreCard() {
    final vitrinScore = _calculateVitrinScore(_data);
    final suggestions = _buildVitrinScoreSuggestions(_data);
    final progress = vitrinScore / 100;
    final tone = _vitrinScoreTone(vitrinScore);

    return Container(
      decoration: _premiumCardDecoration(radius: 24),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cardBorder),
                ),
                child: Icon(Icons.query_stats_rounded, color: tone, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vitrin Skoru',
                      style: TextStyle(
                        color: darkText,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 7),
                    _gradientUnderline(width: 52),
                    const SizedBox(height: 2),
                    Text(
                      _vitrinScoreStatusText(vitrinScore),
                      style: TextStyle(
                        color: softText.withValues(alpha: 0.82),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: tone.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: tone.withValues(alpha: 0.18)),
                    ),
                    child: Text(
                      _vitrinScoreBadgeText(vitrinScore),
                      style: TextStyle(
                        color: tone,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$vitrinScore/100',
                    style: const TextStyle(
                      color: primaryColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 13),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(tone),
            ),
          ),
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Sıradaki 3 adım',
              style: TextStyle(
                color: softText,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Column(
              children:
                  suggestions.map((suggestion) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 7),
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: mutedText,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              suggestion,
                              style: TextStyle(
                                color: softText.withValues(alpha: 0.88),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ],
          if (vitrinScore >= 60) ...[
            const SizedBox(height: 14),
            _buildGoogleVisibilityCta(),
          ],
        ],
      ),
    );
  }

  Widget _buildPublishPanel({
    bool compact = false,
    bool includeBottomSpacing = true,
  }) {
    final checklist = _buildPublishChecklistItems();
    final panelChildren =
        compact
            ? <Widget>[
              _buildPublishCard(
                children: [
                  _buildPublishIntro(),
                  const SizedBox(height: 18),
                  _buildPublishSectionTitle('Yayın öncesi kontrol'),
                  const SizedBox(height: 10),
                  ...checklist.map(_buildPublishChecklistRow),
                  const SizedBox(height: 10),
                  _buildPublishSectionTitle('Bu link nerede kullanılabilir?'),
                  const SizedBox(height: 10),
                  _buildPublishUsageList(),
                  const SizedBox(height: 16),
                  _buildPublishActionArea(),
                ],
              ),
            ]
            : <Widget>[
              _buildPublishCard(children: [_buildPublishIntro()]),
              const SizedBox(height: 16),
              _buildPublishCard(
                children: [
                  _buildPublishSectionTitle('Yayın öncesi kontrol'),
                  const SizedBox(height: 10),
                  ...checklist.map(_buildPublishChecklistRow),
                ],
              ),
              const SizedBox(height: 16),
              _buildPublishCard(
                children: [
                  _buildPublishSectionTitle('Bu link nerede kullanılabilir?'),
                  const SizedBox(height: 10),
                  _buildPublishUsageList(),
                  const SizedBox(height: 16),
                  _buildPublishActionArea(),
                ],
              ),
            ];

    if (includeBottomSpacing) {
      panelChildren.add(const SizedBox(height: 100));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: panelChildren,
    );
  }

  String _buildFullPublicLink(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final base = Uri.base;
    final hasWebOrigin =
        (base.scheme == 'http' || base.scheme == 'https') &&
        base.host.isNotEmpty;
    final origin = hasWebOrigin ? base.origin : '';

    return '$origin$normalizedPath';
  }

  String _generateStoreSlug(String name) {
    var slug = name.trim().toLowerCase();
    if (slug.isEmpty) return 'magazaniz';

    const replacements = {
      'ç': 'c',
      'ğ': 'g',
      'ı': 'i',
      'ö': 'o',
      'ş': 's',
      'ü': 'u',
    };

    replacements.forEach((source, target) {
      slug = slug.replaceAll(source, target);
    });

    slug = slug.replaceAll(RegExp(r'[^a-z0-9\s-]'), '');
    slug = slug.replaceAll(RegExp(r'\s+'), '-');
    slug = slug.replaceAll(RegExp(r'-+'), '-');
    slug = slug.replaceAll(RegExp(r'^-|-$'), '');

    return slug.isEmpty ? 'magazaniz' : slug;
  }

  Widget _buildPublishIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vitrininizi yayınlayın',
          style: TextStyle(
            color: darkText,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        _gradientUnderline(width: 64),
        const SizedBox(height: 8),
        Text(
          'VitrinX linkiniz hazır olduğunda müşteriler bu adrese girerek canlı vitrininizi görebilecek.',
          style: TextStyle(
            color: softText.withValues(alpha: 0.8),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildPublishUsageList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPublishBulletRow('WhatsApp mesajı'),
        _buildPublishBulletRow('Instagram bio'),
        _buildPublishBulletRow('Google İşletme profili'),
        _buildPublishBulletRow('QR kart / mağaza içi afiş'),
      ],
    );
  }

  Widget _buildPublishActionArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_publishedLink != null) ...[
          _buildPublishedLinkBlock(_publishedLink!),
          const SizedBox(height: 12),
        ],
        if (_publishError != null) ...[
          _buildPublishErrorBlock(_publishError!),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isPublishing ? null : _publishStore,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 13),
              minimumSize: const Size(44, 46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            child:
                _isPublishing
                    ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _isUploadingShelf
                              ? 'Fotoğraf yükleniyor...'
                              : 'Hazırlanıyor...',
                        ),
                      ],
                    )
                    : Text(
                      _publishedLink == null
                          ? 'Vitrin linkini oluştur'
                          : 'Vitrini güncelle',
                    ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Gerçek yayınlama için sonraki aşamada Supabase bağlantısı eklenecek.',
          style: TextStyle(
            color: mutedText,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildPublishedLinkBlock(String link) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(45, 212, 191, 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color.fromRGBO(45, 212, 191, 0.26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Hazırlanan vitrin linki',
                  style: TextStyle(
                    color: const Color(0xFF5EEAD4),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _copyPublishedLink('Vitrin linki kopyalandı.'),
                tooltip: 'Linki kopyala',
                icon: Icon(
                  Icons.copy_rounded,
                  color: Colors.teal.shade800,
                  size: 17,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(255, 255, 255, 0.08),
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(32, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  side: const BorderSide(
                    color: Color.fromRGBO(45, 212, 191, 0.22),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            link,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: darkText,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          _buildPublishedQrBlock(link),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed:
                  () => _copyPublishedLink('Paylaşım için link kopyalandı.'),
              icon: const Icon(Icons.share_outlined, size: 16),
              label: const Text('Paylaş'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF5EEAD4),
                side: const BorderSide(
                  color: Color.fromRGBO(45, 212, 191, 0.32),
                ),
                padding: const EdgeInsets.symmetric(vertical: 11),
                minimumSize: const Size(44, 42),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublishedQrBlock(String link) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(31, 28, 44, 0.86),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: QrImageView(
              data: link,
              version: QrVersions.auto,
              backgroundColor: Colors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.M,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'QR ile paylaş',
                  style: TextStyle(
                    color: darkText,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Müşteriler bu kodu okutarak vitrininize ulaşabilir.',
                  style: TextStyle(
                    color: softText.withValues(alpha: 0.86),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Mağaza içine, paket üzerine veya sosyal medya görseline ekleyebilirsiniz.',
                  style: TextStyle(
                    color: mutedText,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublishErrorBlock(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 77, 0, 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color.fromRGBO(255, 77, 0, 0.28)),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: const Color(0xFFFFB085),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      ),
    );
  }

  List<_PublishChecklistItem> _buildPublishChecklistItems() {
    final hasMarketplaceLink = _hasCompleteMarketplaceLink(_data);

    return [
      _PublishChecklistItem(
        isReady: _data.name.trim().isNotEmpty,
        readyText: 'Mağaza adı hazır',
        missingText: 'Mağaza adı eksik',
      ),
      _PublishChecklistItem(
        isReady: _data.whatsapp.trim().isNotEmpty,
        readyText: 'WhatsApp iletişimi hazır',
        missingText: 'WhatsApp eklenmemiş',
      ),
      _PublishChecklistItem(
        isReady: _data.description.trim().isNotEmpty,
        readyText: 'Kısa açıklama hazır',
        missingText: 'Kısa açıklama eksik',
      ),
      _PublishChecklistItem(
        isReady: hasMarketplaceLink,
        readyText: 'Pazaryeri linki hazır',
        missingText: 'Pazaryeri linki eklenmemiş',
      ),
      _PublishChecklistItem(
        isReady: _data.address.trim().isNotEmpty,
        readyText: 'Adres bilgisi hazır',
        missingText: 'Adres bilgisi eksik',
      ),
    ];
  }

  Widget _buildPublishCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _premiumCardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildPublishSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: darkText,
        fontSize: 15,
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
    );
  }

  Widget _buildPublishChecklistRow(_PublishChecklistItem item) {
    final color = item.isReady ? const Color(0xFF2DD4BF) : mutedText;

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            item.isReady
                ? Icons.check_circle_rounded
                : Icons.info_outline_rounded,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.isReady ? item.readyText : item.missingText,
              style: TextStyle(
                color: softText.withValues(alpha: 0.88),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublishBulletRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: softText.withValues(alpha: 0.72),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: softText.withValues(alpha: 0.88),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleVisibilityCta() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.travel_explore_rounded,
                color: Color(0xFFFF4D00),
                size: 17,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'İlk içeriğini hazırlayalım',
                  style: TextStyle(
                    color: darkText,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Vitrin bilgileriniz hazır. Bu bilgilerle mağazanız için blog başlığı, Google işletme gönderisi ve sosyal medya açıklaması hazırlayabiliriz.',
            style: TextStyle(
              color: softText.withValues(alpha: 0.78),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                _toggleGoogleAssistant();
              },
              icon: Icon(
                _isGoogleAssistantOpen
                    ? Icons.expand_less_rounded
                    : Icons.auto_awesome_rounded,
                size: 16,
              ),
              label: Text(
                _isGoogleAssistantOpen ? 'Gizle' : 'İçerik taslağını hazırla',
              ),
              style: TextButton.styleFrom(
                foregroundColor: primaryColor,
                padding: EdgeInsets.zero,
                minimumSize: const Size(44, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          if (_isGoogleAssistantOpen) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: cardBorder),
            const SizedBox(height: 12),
            _buildGoogleVisibilityAssistant(),
          ],
        ],
      ),
    );
  }

  Widget _buildGoogleVisibilityAssistant() {
    final usedInfoLabels = _buildGoogleUsedInfoLabels(_data);
    final hasLocation = _data.address.trim().isNotEmpty;
    final opportunity = _buildGoogleContentOpportunity(_data);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Blog & İçerik Asistanı',
                      style: TextStyle(
                        color: darkText,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Vitrin bilgilerinizden yola çıkarak ilk içerik taslağınız için başlangıç hazırlıyoruz.',
                      style: TextStyle(
                        color: softText,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  _closeGoogleAssistant();
                },
                tooltip: 'Gizle',
                icon: Icon(Icons.close_rounded, color: mutedText, size: 17),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(30, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  side: const BorderSide(color: cardBorder),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildAssistantSectionTitle('Kullandığımız bilgiler'),
          const SizedBox(height: 8),
          if (usedInfoLabels.isEmpty)
            Text(
              'Henüz yeterli vitrin bilgisi yok. Önce mağaza adı, açıklama ve iletişim bilgilerini tamamlayın.',
              style: TextStyle(
                color: softText.withValues(alpha: 0.78),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            )
          else
            _buildUsedInfoSummary(usedInfoLabels),
          if (!hasLocation) ...[
            const SizedBox(height: 7),
            Text(
              '(konum henüz eklenmemiş)',
              style: TextStyle(
                color: mutedText,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 14),
          _buildAssistantSectionTitle('Önerilen ilk içerik'),
          const SizedBox(height: 8),
          _buildContentTitleCard(opportunity.title),
          const SizedBox(height: 14),
          _buildAssistantSectionTitle('Kullanım alanı'),
          const SizedBox(height: 8),
          _buildAssistantPlainText(opportunity.usage),
          const SizedBox(height: 14),
          _buildAssistantSectionTitle('Kısa başlangıç metni'),
          const SizedBox(height: 8),
          _buildAssistantPlainText(opportunity.introText),
          const SizedBox(height: 14),
          _buildAssistantSectionTitle('Daha iyi sonuç için'),
          const SizedBox(height: 8),
          _buildAssistantPlainText(
            'Hedef müşteri · Öne çıkan ürün/hizmet · Bulunmak istediğiniz kelimeler',
          ),
          const SizedBox(height: 12),
          _buildContentDraftStatus(),
        ],
      ),
    );
  }

  List<String> _buildGoogleUsedInfoLabels(StoreData data) {
    final labels = <String>[];
    final completeMarketplaceLinks = _completeMarketplaceLinks(data);

    void addLabel(String label, String value) {
      if (value.trim().isEmpty) return;
      labels.add(label);
    }

    addLabel('Mağaza adı', data.name);
    addLabel('Kategori', data.businessType);
    addLabel('Açıklama', data.description);
    addLabel('Konum', data.address);
    addLabel('Web sitesi', data.website);
    addLabel('Instagram', data.instagram);

    if (completeMarketplaceLinks.isNotEmpty) {
      labels.add('Pazaryeri');
    }

    return labels;
  }

  Widget _buildUsedInfoSummary(List<String> labels) {
    return Text(
      labels.join(' · '),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: softText.withValues(alpha: 0.82),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        height: 1.35,
      ),
    );
  }

  _GoogleContentOpportunity _buildGoogleContentOpportunity(StoreData data) {
    final location = _googleLocationLabel(data.address);
    final category = _contentCategoryLabel(data.businessType);
    final storeName = data.name.trim();
    final title = _buildGoogleContentTitle(
      name: storeName,
      location: location,
      category: category,
    );

    return _GoogleContentOpportunity(
      title: title,
      usage: 'Blog taslağı · Google işletme gönderisi · Instagram açıklaması',
      introText:
          'Mağazanızın sunduğu ürünleri, konumunu ve iletişim kanallarını anlatan kısa bir içerik taslağı hazırlanabilir.',
    );
  }

  String _buildGoogleContentTitle({
    required String name,
    required String location,
    required String category,
  }) {
    final safeCategory = category.isEmpty ? 'mağaza' : category;

    if (name.isNotEmpty && category.isNotEmpty) {
      return '$name için $safeCategory rehberi';
    }
    if (location.isNotEmpty && category.isNotEmpty) {
      return '$location bölgesinde $safeCategory arayanlar için kısa rehber';
    }
    if (name.isNotEmpty) {
      return '$name için içerik taslağı';
    }

    return 'Mağazanız için içerik taslağı';
  }

  String _contentCategoryLabel(String businessType) {
    switch (businessType.trim()) {
      case 'Butik':
        return 'butik mağaza';
      case 'İç giyim':
        return 'iç giyim mağazası';
      case 'Kozmetik':
        return 'kozmetik mağazası';
      case 'Hediyelik':
        return 'hediyelik mağazası';
      case 'Market':
        return 'market';
      case 'Telefon aksesuarı':
        return 'telefon aksesuarı mağazası';
      case 'Kafe / Lokanta':
        return 'kafe ve lokanta';
      case 'Kuaför':
        return 'kuaför';
      case 'Diğer':
        return 'işletme';
      default:
        return businessType.trim();
    }
  }

  Widget _buildContentTitleCard(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Text(
        title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: darkText,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          height: 1.35,
        ),
      ),
    );
  }

  Widget _buildAssistantPlainText(String text) {
    return Text(
      text,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: softText.withValues(alpha: 0.8),
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
    );
  }

  Widget _buildContentDraftStatus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Text(
        'İçerik taslağı için başlangıç hazır. Daha güçlü metin için 3 bilgiyi tamamlayabilirsiniz.',
        style: TextStyle(
          color: softText.withValues(alpha: 0.86),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      ),
    );
  }

  String _googleLocationLabel(String address) {
    final trimmedAddress = address.trim();
    if (trimmedAddress.isEmpty) return '';
    return trimmedAddress.split(',').first.trim();
  }

  Widget _buildAssistantSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: softText.withValues(alpha: 0.86),
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _buildEditCard({
    required String title,
    required List<Widget> children,
    VoidCallback? onAction,
    Widget? headerWidget,
  }) {
    final isWide = MediaQuery.of(context).size.width > 900;
    return Container(
      decoration: _premiumCardDecoration(radius: 24),
      padding: EdgeInsets.all(isWide ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: darkText,
                    letterSpacing: 0,
                  ),
                ),
              ),
              if (headerWidget != null)
                headerWidget
              else if (onAction != null)
                IconButton(
                  onPressed: onAction,
                  icon: const Icon(
                    Icons.add_circle_outline_rounded,
                    color: primaryColor,
                  ),
                  tooltip: 'Yeni Ekle',
                ),
            ],
          ),
          const SizedBox(height: 8),
          _gradientUnderline(width: 52),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildMarketplaceLinkItem(int index) {
    final link = _data.marketplaceLinks[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  'Platform',
                  link.platform,
                  platforms,
                  (v) => setState(() => link.platform = v!),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _removeMarketplaceLink(index),
                icon: const Icon(
                  Icons.remove_circle_outline_rounded,
                  color: Colors.redAccent,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(
            'Mağaza Linki',
            (v) => setState(() => link.url = v),
            prefixIcon: Icons.link_rounded,
            initial: link.url,
          ),
        ],
      ),
    );
  }

  Widget _buildLivePreviewMockup(BoxConstraints constraints) {
    final isMobilePreview = constraints.maxWidth < 520;

    if (isMobilePreview) {
      return _buildMobileLivePreview();
    }

    return _buildDesktopLivePreview(constraints);
  }

  Widget _buildPremium3DDeviceFrame({
    required Widget child,
    required double width,
    required double height,
    required bool isDarkTheme,
    bool isMobilePreview = false,
  }) {
    final statusColor =
        isDarkTheme
            ? Colors.white.withValues(alpha: 0.75)
            : Colors.black.withValues(alpha: 0.75);
    final indicatorColor =
        isDarkTheme
            ? Colors.white.withValues(alpha: 0.32)
            : Colors.black.withValues(alpha: 0.28);
    final frameRadius = isMobilePreview ? 46.0 : 52.0;
    final framePadding = isMobilePreview ? 2.2 : 3.0;
    final shellRadius = frameRadius - 3;
    final screenRadius = frameRadius - 5;
    final statusBarHeight = isMobilePreview ? 38.0 : 44.0;
    final bottomInset = isMobilePreview ? 16.0 : 20.0;
    final statusHorizontalPadding = isMobilePreview ? 20.0 : 22.0;
    final islandWidth = isMobilePreview ? 92.0 : 110.0;
    final islandHeight = isMobilePreview ? 23.0 : 26.0;
    final homeIndicatorWidth = isMobilePreview ? 92.0 : 120.0;
    // Titanium frame gradient (silver/matte like iPhone 15 Pro)
    const titaniumGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF9EA5AD), // top-left highlight
        Color(0xFF6B7480), // mid
        Color(0xFF4A5260), // shadow
        Color(0xFF7E8898), // bottom-right partial light
      ],
      stops: [0.0, 0.35, 0.65, 1.0],
    );

    return Stack(
      children: [
        // Outer titanium body with gradient border
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            gradient: titaniumGradient,
            borderRadius: BorderRadius.circular(frameRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.62),
                blurRadius: isMobilePreview ? 42 : 52,
                offset: Offset(0, isMobilePreview ? 22 : 28),
              ),
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.18),
                blurRadius: isMobilePreview ? 38 : 48,
                offset: const Offset(-12, 8),
              ),
              BoxShadow(
                color: secondaryColor.withValues(alpha: 0.22),
                blurRadius: isMobilePreview ? 48 : 60,
                offset: Offset(14, isMobilePreview ? 22 : 28),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(-2, -2),
              ),
            ],
          ),
          padding: EdgeInsets.all(framePadding),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0F),
              borderRadius: BorderRadius.circular(shellRadius),
              border: Border.all(
                color: const Color(0xFF1A1A22),
                width: isMobilePreview ? 1.1 : 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(screenRadius),
              child: Stack(
                children: [
                  // Screen background (black behind VitrinView)
                  const Positioned.fill(
                    child: ColoredBox(color: Color(0xFF000000)),
                  ),
                  // Main phone screen content
                  Positioned.fill(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: statusBarHeight,
                        bottom: bottomInset,
                      ),
                      child: child,
                    ),
                  ),

                  // Gentle inner screen depth so the mockup feels less flat.
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(screenRadius),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(
                                alpha: isMobilePreview ? 0.12 : 0.08,
                              ),
                              Colors.transparent,
                              Colors.black.withValues(
                                alpha: isMobilePreview ? 0.10 : 0.08,
                              ),
                            ],
                            stops: const [0.0, 0.18, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Glossy edge-glow reflection (left)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(screenRadius),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0.06),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.08),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Status Bar background blur
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: statusBarHeight,
                    child: Container(
                      color:
                          isDarkTheme
                              ? const Color(0xCC000000)
                              : Colors.white.withValues(alpha: 0.82),
                    ),
                  ),

                  // Status Bar content
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: statusBarHeight,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: statusHorizontalPadding,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '9:41',
                            style: TextStyle(
                              color: statusColor,
                              fontSize: isMobilePreview ? 12 : 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.signal_cellular_4_bar_rounded,
                                size: 12,
                                color: statusColor,
                              ),
                              const SizedBox(width: 3),
                              Icon(
                                Icons.wifi_rounded,
                                size: 14,
                                color: statusColor,
                              ),
                              const SizedBox(width: 4),
                              // Battery icon
                              SizedBox(
                                width: 24,
                                height: 12,
                                child: Stack(
                                  alignment: Alignment.centerLeft,
                                  children: [
                                    Container(
                                      width: 21,
                                      height: 11,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: statusColor,
                                          width: 1,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          2.5,
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(1.5),
                                      child: Container(
                                        width: 14,
                                        decoration: BoxDecoration(
                                          color: statusColor,
                                          borderRadius: BorderRadius.circular(
                                            1,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      child: Container(
                                        width: 2,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          color: statusColor,
                                          borderRadius: const BorderRadius.only(
                                            topRight: Radius.circular(1),
                                            bottomRight: Radius.circular(1),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Dynamic Island (pill-shaped, modern)
                  Positioned(
                    top: isMobilePreview ? 8 : 10,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: islandWidth,
                        height: islandHeight,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(islandHeight / 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.45),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Front camera dot
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1C1C28),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF2C2C3E),
                                  width: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Home Indicator (swipe bar)
                  Positioned(
                    bottom: 5,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: homeIndicatorWidth,
                        height: 4,
                        decoration: BoxDecoration(
                          color: indicatorColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Physical side buttons — Volume Up
        Positioned(
          left: 0,
          top: height * 0.22,
          child: Container(
            width: 4,
            height: height * 0.07,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF8A929C), Color(0xFF5A6270)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(3),
                bottomLeft: Radius.circular(3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 4,
                  offset: const Offset(-2, 0),
                ),
              ],
            ),
          ),
        ),

        // Physical side buttons — Volume Down
        Positioned(
          left: 0,
          top: height * 0.315,
          child: Container(
            width: 4,
            height: height * 0.07,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF8A929C), Color(0xFF5A6270)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(3),
                bottomLeft: Radius.circular(3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 4,
                  offset: const Offset(-2, 0),
                ),
              ],
            ),
          ),
        ),

        // Physical side buttons — Power/Lock
        Positioned(
          right: 0,
          top: height * 0.265,
          child: Container(
            width: 4,
            height: height * 0.10,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF8A929C), Color(0xFF5A6270)],
              ),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(3),
                bottomRight: Radius.circular(3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 4,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLivePreview() {
    final preset = vitrinThemePresetFor(_data.theme);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      child: Column(
        children: [
          _buildLivePreviewBadge(),
          const SizedBox(height: 16),
          Expanded(
            child: LayoutBuilder(
              builder: (context, phoneConstraints) {
                final maxPhoneWidth = min(
                  phoneConstraints.maxWidth * 0.92,
                  342.0,
                );
                final maxPhoneHeight = phoneConstraints.maxHeight;
                const targetRatio = 2.14;
                var phoneHeight = min(
                  maxPhoneHeight,
                  maxPhoneWidth * targetRatio,
                );
                var phoneWidth = phoneHeight / targetRatio;

                if (phoneWidth < 286.0 &&
                    maxPhoneWidth >= 286.0 &&
                    maxPhoneHeight >= 286.0 * targetRatio) {
                  phoneWidth = 286.0;
                  phoneHeight = phoneWidth * targetRatio;
                }

                phoneWidth = phoneWidth.clamp(260.0, maxPhoneWidth).toDouble();
                phoneHeight = min(maxPhoneHeight, phoneWidth * targetRatio);

                return Center(
                  child: _buildPremium3DDeviceFrame(
                    width: phoneWidth,
                    height: phoneHeight,
                    isDarkTheme: preset.isDark,
                    isMobilePreview: true,
                    child: VitrinView(
                      key: ValueKey(
                        'mobile_preview_${_data.name}_${_data.marketplaceLinks.length}_${_data.description}_${_data.theme}_${_data.shelfImageUrl}',
                      ),
                      storeData: _data,
                      isEmbedded: true,
                      compactEmbeddedHeader: true,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivePreviewBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.visibility_rounded, size: 14, color: primaryColor),
          SizedBox(width: 7),
          Text(
            'CANLI ÖNİZLEME',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
              color: softText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLivePreview(BoxConstraints constraints) {
    final preset = vitrinThemePresetFor(_data.theme);

    return Stack(
      children: [
        // Lighter 3D background with radial depth effects
        Positioned.fill(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E2235), // lighter navy-slate
                  Color(0xFF252842), // mid blue-slate
                  Color(0xFF1A1D30), // slightly deeper
                ],
              ),
              border: Border.all(color: Color.fromRGBO(255, 255, 255, 0.10)),
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.52),
                  blurRadius: 34,
                  offset: Offset(0, 18),
                ),
              ],
            ),
          ),
        ),
        // Radial top-left glow (accent light)
        Positioned(
          top: 24,
          left: 24,
          child: IgnorePointer(
            child: Container(
              width: 260,
              height: 260,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x22FF4D00), Colors.transparent],
                ),
              ),
            ),
          ),
        ),
        // Radial bottom-right glow (secondary light)
        Positioned(
          bottom: 24,
          right: 24,
          child: IgnorePointer(
            child: Container(
              width: 220,
              height: 220,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x1AB200FF), Colors.transparent],
                ),
              ),
            ),
          ),
        ),
        // Main content column
        Positioned.fill(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                _buildLivePreviewBadge(),
                const SizedBox(height: 12),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, phoneConstraints) {
                      // Modern 9:19.5 aspect ratio (iPhone 15 Pro-like)
                      final availableH = phoneConstraints.maxHeight;
                      final availableW = phoneConstraints.maxWidth;
                      // Fit phone to fill available space, respecting ratio
                      double phoneHeight = availableH * 0.96;
                      double phoneWidth = phoneHeight / 2.17;
                      if (phoneWidth > availableW * 0.88) {
                        phoneWidth = availableW * 0.88;
                        phoneHeight = phoneWidth * 2.17;
                      }
                      phoneWidth = max(260.0, min(phoneWidth, 390.0));
                      phoneHeight = max(520.0, min(phoneHeight, availableH));

                      return Center(
                        child: _buildPremium3DDeviceFrame(
                          width: phoneWidth,
                          height: phoneHeight,
                          isDarkTheme: preset.isDark,
                          child: VitrinView(
                            key: ValueKey(
                              'preview_${_data.name}_${_data.marketplaceLinks.length}_${_data.description}_${_data.theme}_${_data.shelfImageUrl}',
                            ),
                            storeData: _data,
                            isEmbedded: true,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoUpload() {
    final hasShelfPreview =
        _selectedShelfBytes != null || _data.shelfImageUrl.trim().isNotEmpty;

    return InkWell(
      onTap: _pickShelfPhoto,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: inputBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (hasShelfPreview) ...[
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child:
                          _selectedShelfBytes != null
                              ? Image.memory(
                                _selectedShelfBytes!,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                              : Image.network(
                                _data.shelfImageUrl.trim(),
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) => _buildShelfImageError(),
                              ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      onPressed: _clearShelfPhoto,
                      tooltip: 'Fotoğrafı kaldır',
                      icon: const Icon(Icons.close_rounded, size: 18),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: darkText,
                        minimumSize: const Size(34, 34),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.storefront_rounded,
                    size: 16,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedShelfFileName ?? 'Yayınlanmış raf fotoğrafı',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: darkText,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    'Değiştir',
                    style: TextStyle(
                      color: softText.withValues(alpha: 0.78),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            const Icon(
              Icons.add_a_photo_outlined,
              size: 26,
              color: primaryColor,
            ),
            const SizedBox(height: 10),
            const Text(
              'Anlık raf / reyon fotoğrafı',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: darkText,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Bugünkü rafınızı, kampanyalı ürünlerinizi veya yeni gelenleri müşterilere gösterin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: softText.withValues(alpha: 0.76),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: const [
                _ShelfHintChip(label: 'Bugünün vitrini'),
                _ShelfHintChip(label: 'Yeni gelenler'),
                _ShelfHintChip(label: 'Kampanya rafı'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShelfImageError() {
    return Container(
      color: inputBg,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined, color: mutedText, size: 28),
          const SizedBox(height: 8),
          Text(
            'Fotoğraf önizlenemedi',
            style: TextStyle(
              color: softText.withValues(alpha: 0.72),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector({int? skip, int? limit, bool showTitle = true}) {
    Iterable<String> displayIterable = themes;
    if (skip != null) displayIterable = displayIterable.skip(skip);
    if (limit != null) displayIterable = displayIterable.take(limit);
    final displayThemes = displayIterable.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          const Text(
            'Tema Seçimi',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),
          const SizedBox(height: 16),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth =
                constraints.maxWidth > 350
                    ? (constraints.maxWidth - 24) / 3
                    : (constraints.maxWidth - 12) / 2;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(displayThemes.length, (index) {
                final themeName = displayThemes[index];
                final isSelected = _data.theme == themeName;
                final preset = vitrinThemePresetFor(themeName);

                return _HoverThemeCard(
                  themeName: themeName,
                  preset: preset,
                  isSelected: isSelected,
                  width: constraints.maxWidth > 400 ? 90 : itemWidth,
                  onTap: () => setState(() => _data.theme = themeName),
                );
              }),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    Function(String) onChanged, {
    int maxLines = 1,
    IconData? prefixIcon,
    String? initial,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: softText.withValues(alpha: 0.78),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: initial,
          decoration: InputDecoration(
            prefixIcon:
                prefixIcon != null
                    ? Icon(prefixIcon, color: mutedText, size: 18)
                    : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: cardBorder),
            ),
            filled: true,
            fillColor: inputBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            hintText: hintText ?? label,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0x66FF4D00)),
            ),
            hintStyle: TextStyle(
              color: mutedText.withValues(alpha: 0.58),
              fontSize: 14,
            ),
          ),
          maxLines: maxLines,
          onChanged: onChanged,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: darkText,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactStatusDropdown() {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _data.status,
          icon: const Padding(
            padding: EdgeInsets.only(left: 4.0),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: primaryColor,
            ),
          ),
          isDense: true,
          alignment: Alignment.center,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: primaryColor,
          ),
          items:
              statuses
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
          onChanged: (v) => setState(() => _data.status = v!),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    void Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: softText.withValues(alpha: 0.78),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0x66FF4D00)),
            ),
            filled: true,
            fillColor: inputBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          dropdownColor: const Color(0xFF171722),
          iconEnabledColor: mutedText,
          style: const TextStyle(
            color: darkText,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          borderRadius: BorderRadius.circular(14),
          items:
              items
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(
                        t,
                        style: const TextStyle(
                          color: darkText,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                  .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildMobileBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        border: const Border(top: BorderSide(color: cardBorder)),
        boxShadow: [
          BoxShadow(
            color: secondaryColor.withValues(alpha: 0.10),
            blurRadius: 22,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: _buildGradientButton(
                label: 'Kaydet',
                onPressed: _saveData,
                icon: Icons.cloud_done_outlined,
                expand: true,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGradientButton(
                label: 'Vitrini Aç',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PreviewScreen(storeData: _data),
                    ),
                  );
                },
                icon: Icons.share_outlined,
                expand: true,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorGridPainter extends CustomPainter {
  const _EditorGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = const Color(0x14FFFFFF)
          ..strokeWidth = 0.5;

    for (double x = 0; x <= size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y <= size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ShelfHintChip extends StatelessWidget {
  final String label;

  const _ShelfHintChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _EditorScreenState.cardBorder),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _EditorScreenState.softText.withValues(alpha: 0.9),
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _VitrinScoreTask {
  final int points;
  final bool isComplete;
  final String suggestion;

  const _VitrinScoreTask({
    required this.points,
    required this.isComplete,
    required this.suggestion,
  });
}

class _GoogleContentOpportunity {
  final String title;
  final String usage;
  final String introText;

  const _GoogleContentOpportunity({
    required this.title,
    required this.usage,
    required this.introText,
  });
}

class _PublishChecklistItem {
  final bool isReady;
  final String readyText;
  final String missingText;

  const _PublishChecklistItem({
    required this.isReady,
    required this.readyText,
    required this.missingText,
  });
}

class _HoverThemeCard extends StatefulWidget {
  final String themeName;
  final VitrinThemePreset preset;
  final bool isSelected;
  final double width;
  final VoidCallback onTap;

  const _HoverThemeCard({
    required this.themeName,
    required this.preset,
    required this.isSelected,
    required this.width,
    required this.onTap,
  });

  @override
  State<_HoverThemeCard> createState() => _HoverThemeCardState();
}

class _HoverThemeCardState extends State<_HoverThemeCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final scale = widget.isSelected ? 1.03 : (_isHovered ? 1.01 : 1.0);
    final shadowOpacity = widget.isSelected ? 0.15 : (_isHovered ? 0.08 : 0.0);
    final borderColor =
        widget.isSelected
            ? widget.preset.accent.withValues(alpha: 0.95)
            : _EditorScreenState.cardBorder;
    final checkColor =
        widget.preset.accent.computeLuminance() > 0.65
            ? widget.preset.textPrimary
            : widget.preset.buttonText;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: widget.width,
            height: 116,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(14, 14, 22, 0.86),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: widget.isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.preset.accent.withValues(alpha: shadowOpacity),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          widget.preset.background,
                          widget.preset.surface,
                          widget.preset.surfaceSoft,
                          widget.preset.accent.withValues(alpha: 0.72),
                        ],
                        stops: const [0, 0.48, 0.78, 1],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          left: 10,
                          top: 10,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.preset.accent,
                              border: Border.all(
                                color: widget.preset.buttonText.withValues(
                                  alpha: 0.28,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 10,
                          right: 10,
                          bottom: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _ThemePreviewLine(
                                width: 42,
                                color: widget.preset.textPrimary,
                              ),
                              const SizedBox(height: 5),
                              _ThemePreviewLine(
                                width: 28,
                                color: widget.preset.accent,
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: 9,
                                decoration: BoxDecoration(
                                  color: widget.preset.surface.withValues(
                                    alpha: 0.72,
                                  ),
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(
                                    color: widget.preset.border.withValues(
                                      alpha: 0.48,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.isSelected)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check_circle,
                                color: checkColor,
                                size: 18,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10, left: 4, right: 4),
                  child: Text(
                    widget.themeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          widget.isSelected ? FontWeight.w800 : FontWeight.w600,
                      color:
                          widget.isSelected
                              ? widget.preset.accent
                              : _EditorScreenState.mutedText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemePreviewLine extends StatelessWidget {
  final double width;
  final Color color;

  const _ThemePreviewLine({required this.width, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 4,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}

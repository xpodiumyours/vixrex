import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/services/store_publish_service.dart';
import 'package:vitrinx/theme/vitrin_theme_preset.dart';
import 'package:vitrinx/widgets/vitrin_view.dart';
import 'package:vitrinx/screens/preview_screen.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final StoreData _data = StoreData(isEsnafMode: false);
  bool _isLoading = true;
  bool _isGoogleAssistantOpen = false;
  bool _isPublishing = false;
  String? _publishedLink;
  String? _publishError;

  // Modern Color Palette
  static const Color primaryColor = Color(0xFFFF5A1F);
  static const Color bgColor = Color(0xFFF8FAFC);
  static const Color cardBorder = Color(0xFFE5E7EB);
  static const Color inputBg = Color(0xFFF1F5F9);
  static const Color darkText = Color(0xFF111827);

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
    _loadSavedData();
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
      _publishedLink = null;
      _publishError = null;
    });

    try {
      final publicPath = await const StorePublishService().publishStore(_data);
      final publicLink = _buildFullPublicLink(publicPath);
      if (!mounted) return;

      setState(() => _publishedLink = publicLink);
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vitrin linkiniz hazırlandı.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (error) {
      debugPrint('Publish store error: $error');
      if (!mounted) return;

      setState(() {
        _publishError =
            'Vitrin bağlantısı hazırlanamadı. Supabase ayarlarını veya izinleri kontrol edin.';
      });
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vitrin yayınlanırken bir sorun oluştu.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPublishing = false);
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
        backgroundColor: Colors.white,
        elevation: 0,
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
                  color: primaryColor.withValues(alpha: 0.3),
                  fontSize: 12,
                  letterSpacing: 2,
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
                    child: TextButton.icon(
                      onPressed: _saveData,
                      icon: const Icon(Icons.cloud_done_outlined, size: 18),
                      label: const Text('Kaydet'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blueGrey.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 12.0,
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PreviewScreen(storeData: _data),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Önizle & Paylaş',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ]
                : null,
      ),
      bottomNavigationBar: !isWide ? _buildMobileBottomActions() : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;

          if (!isWide) {
            return DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  Container(
                    color: Colors.white,
                    child: const TabBar(
                      labelColor: primaryColor,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: primaryColor,
                      tabs: [
                        Tab(text: 'Düzenle'),
                        Tab(text: 'Canlı Önizleme'),
                        Tab(text: 'Yayınla'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 800),
                              child: _buildForm(),
                            ),
                          ),
                        ),
                        Container(
                          color: const Color(0xFFF1F5F9),
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
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 800),
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

          return Row(
            children: [
              Expanded(
                flex: 5,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: _buildForm(showDesktopPublishCard: true),
                    ),
                  ),
                ),
              ),
              const VerticalDivider(width: 1, color: cardBorder),
              Expanded(
                flex: 4,
                child: Container(
                  color: const Color(0xFFF1F5F9),
                  child: LayoutBuilder(
                    builder: (context, previewConstraints) {
                      return Center(
                        child: _buildLivePreviewMockup(previewConstraints),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildForm({bool showDesktopPublishCard = false}) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVitrinScoreCard(),
          if (showDesktopPublishCard) ...[
            const SizedBox(height: 16),
            _buildPublishPanel(compact: true, includeBottomSpacing: false),
          ],
          const SizedBox(height: 24),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
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
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
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
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _vitrinScoreStatusText(vitrinScore),
                      style: TextStyle(
                        color: Colors.blueGrey.shade600,
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
                      color: darkText,
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
              backgroundColor: const Color(0xFFE8EEF5),
              valueColor: AlwaysStoppedAnimation<Color>(tone),
            ),
          ),
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Sıradaki 3 adım',
              style: TextStyle(
                color: Colors.blueGrey.shade700,
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
                                color: Colors.blueGrey.shade400,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              suggestion,
                              style: TextStyle(
                                color: Colors.blueGrey.shade700,
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

  Widget _buildPublishIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vitrininizi yayınlayın',
          style: TextStyle(
            color: darkText,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'VitrinX linkiniz hazır olduğunda müşteriler bu adrese girerek canlı vitrininizi görebilecek.',
          style: TextStyle(
            color: Colors.blueGrey.shade600,
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
                    ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text('Hazırlanıyor...'),
                      ],
                    )
                    : Text(
                      _publishedLink == null
                          ? 'Vitrin linkini oluştur'
                          : 'Linki yeniden göster',
                    ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Gerçek yayınlama için sonraki aşamada Supabase bağlantısı eklenecek.',
          style: TextStyle(
            color: Colors.blueGrey.shade500,
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
        color: const Color(0xFFF0FDFA),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFF99F6E4)),
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
                    color: Colors.teal.shade800,
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
                  backgroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(32, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  side: BorderSide(color: Colors.teal.shade100),
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
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed:
                  () => _copyPublishedLink('Paylaşım için link kopyalandı.'),
              icon: const Icon(Icons.share_outlined, size: 16),
              label: const Text('Paylaş'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.teal.shade800,
                side: BorderSide(color: Colors.teal.shade200),
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

  Widget _buildPublishErrorBlock(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: Colors.orange.shade900,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
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
        fontSize: 14,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _buildPublishChecklistRow(_PublishChecklistItem item) {
    final color =
        item.isReady ? const Color(0xFF0F766E) : Colors.blueGrey.shade500;

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
                color: Colors.blueGrey.shade700,
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
                color: Colors.blueGrey.shade400,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.blueGrey.shade700,
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
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.travel_explore_rounded,
                color: Color(0xFF334155),
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
              color: Colors.blueGrey.shade700,
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
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
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
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                        color: Color(0xFF64748B),
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
                icon: Icon(
                  Icons.close_rounded,
                  color: Colors.blueGrey.shade500,
                  size: 17,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(30, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
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
                color: Colors.blueGrey.shade600,
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
                color: Colors.blueGrey.shade500,
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
        color: Colors.blueGrey.shade700,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.blueGrey.shade800,
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
        color: Colors.blueGrey.shade700,
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
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        'İçerik taslağı için başlangıç hazır. Daha güçlü metin için 3 bilgiyi tamamlayabilirsiniz.',
        style: TextStyle(
          color: Colors.blueGrey.shade800,
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
        color: Colors.blueGrey.shade800,
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
      ),
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
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: darkText,
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
        color: inputBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder.withValues(alpha: 0.5)),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'CANLI ÖNİZLEME',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: Colors.black45,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 340,
                  maxHeight: 620,
                ),
                child: AspectRatio(
                  aspectRatio: 0.50,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(44),
                      border: Border.all(color: darkText, width: 6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(38),
                      child: VitrinView(
                        key: ValueKey(
                          'preview_${_data.name}_${_data.marketplaceLinks.length}_${_data.description}_${_data.theme}',
                        ),
                        storeData: _data,
                        isEmbedded: true,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoUpload() {
    return InkWell(
      onTap: () {},
      child: Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          color: inputBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_photo_alternate_outlined,
              size: 28,
              color: Colors.black38,
            ),
            const SizedBox(height: 8),
            Text(
              'Logo veya Vitrin Görseli',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
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
                final checkColor =
                    preset.accent.computeLuminance() > 0.65
                        ? preset.textPrimary
                        : preset.buttonText;
                return GestureDetector(
                  onTap: () => setState(() => _data.theme = themeName),
                  child: AnimatedScale(
                    scale: isSelected ? 1.05 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      width: constraints.maxWidth > 400 ? 90 : itemWidth,
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? primaryColor : cardBorder,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow:
                            isSelected
                                ? [
                                  BoxShadow(
                                    color: primaryColor.withValues(alpha: 0.2),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                                : const [
                                  BoxShadow(
                                    color: Colors.transparent,
                                    blurRadius: 0,
                                  ),
                                ],
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    preset.background,
                                    preset.surfaceSoft,
                                    preset.accent.withValues(alpha: 0.85),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child:
                                  isSelected
                                      ? Center(
                                        child: Icon(
                                          Icons.check_circle,
                                          color: checkColor,
                                          size: 20,
                                        ),
                                      )
                                      : null,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              themeName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight:
                                    isSelected
                                        ? FontWeight.w900
                                        : FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: initial,
          decoration: InputDecoration(
            prefixIcon:
                prefixIcon != null
                    ? Icon(prefixIcon, color: Colors.black26, size: 18)
                    : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: inputBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            hintText: hintText ?? label,
            hintStyle: const TextStyle(color: Colors.black26, fontSize: 14),
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
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: inputBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          items:
              items
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(t, style: const TextStyle(fontSize: 14)),
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
        color: Colors.white,
        border: const Border(top: BorderSide(color: cardBorder)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _saveData,
                icon: const Icon(Icons.cloud_done_outlined, size: 18),
                label: const Text('Kaydet'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: const BorderSide(color: primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(44, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PreviewScreen(storeData: _data),
                    ),
                  );
                },
                icon: const Icon(Icons.share_outlined, size: 18),
                label: const Text('Vitrini Aç'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(44, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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

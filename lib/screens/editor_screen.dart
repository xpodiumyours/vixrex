import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitrinx/models/store_data.dart';
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

  // ignore: unused_element
  int _calculateVitrinScore(StoreData data) {
    var score = 0;

    if (data.name.trim().isNotEmpty) score += 15;
    if (data.businessType.trim().isNotEmpty) score += 10;
    if (data.description.trim().length >= 10) score += 10;
    if (data.whatsapp.trim().isNotEmpty) score += 15;
    if (data.instagram.trim().isNotEmpty || data.website.trim().isNotEmpty) {
      score += 10;
    }
    if (data.address.trim().isNotEmpty) score += 10;
    if (data.marketplaceLinks.any(
      (link) => link.platform.trim().isNotEmpty && link.url.trim().isNotEmpty,
    )) {
      score += 15;
    }
    if (statuses.contains(data.status.trim())) score += 5;
    if (themes.contains(data.theme.trim())) score += 10;

    return score.clamp(0, 100).toInt();
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
              length: 2,
              child: Column(
                children: [
                  Container(
                    color: Colors.white,
                    child: const TabBar(
                      labelColor: primaryColor,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: primaryColor,
                      tabs: [Tab(text: 'Düzenle'), Tab(text: 'Canlı Önizleme')],
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
                      child: _buildForm(),
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

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                label: const Text('Önizle'),
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

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitrinx/models/store_data.dart';
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
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonData = jsonEncode(_data.toJson());
      await prefs.setString('vitrin_data', jsonData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.cloud_done_outlined, color: Colors.white),
                SizedBox(width: 12),
                Text('Vitrininiz bu cihazda kaydedildi.'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: primaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

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
        ),
        actions: [
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
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;
          return Row(
            children: [
              Expanded(
                flex: 5,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isWide ? 32 : 20),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: _buildForm(),
                    ),
                  ),
                ),
              ),
              if (isWide) ...[
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
              ),
              const SizedBox(height: 12),
              _buildTextField(
                'Instagram',
                (v) => setState(() => _data.instagram = v),
                prefixIcon: Icons.camera_alt_rounded,
                initial: _data.instagram,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                'Web sitesi',
                (v) => setState(() => _data.website = v),
                prefixIcon: Icons.language_rounded,
                initial: _data.website,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                'Adres',
                (v) => setState(() => _data.address = v),
                prefixIcon: Icons.location_on_rounded,
                maxLines: 2,
                initial: _data.address,
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
          _buildEditCard(
            title: 'Tema & Durum',
            children: [
              _buildThemeSelector(),
              const SizedBox(height: 24),
              _buildDropdown(
                'Vitrin durumu',
                _data.status,
                statuses,
                (v) => setState(() => _data.status = v!),
              ),
            ],
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
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: darkText,
                ),
              ),
              if (onAction != null)
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

  Widget _buildThemeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tema Seçimi',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: themes.length,
            itemBuilder: (context, index) {
              final isSelected = _data.theme == themes[index];
              final themeColor = _getThemeColor(themes[index]);
              return GestureDetector(
                onTap: () => setState(() => _data.theme = themes[index]),
                child: Container(
                  width: 90,
                  margin: const EdgeInsets.only(right: 16),
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
                                color: primaryColor.withValues(alpha: 0.1),
                                blurRadius: 10,
                              ),
                            ]
                            : null,
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
                                themeColor,
                                themeColor.withValues(alpha: 0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child:
                              isSelected
                                  ? const Center(
                                    child: Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  )
                                  : null,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          themes[index],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                isSelected ? FontWeight.w900 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getThemeColor(String theme) {
    switch (theme) {
      case 'Sade':
        return Colors.white;
      case 'Premium':
        return const Color(0xFF1E293B);
      case 'Zarif':
        return const Color(0xFF9E7C66);
      case 'Doğal':
        return Colors.green.shade700;
      case 'Gece':
        return const Color(0xFF0F172A);
      case 'Lüks':
        return const Color(0xFFD4AF37);
      case 'Sahil':
        return Colors.cyan.shade600;
      case 'Güneş':
        return Colors.orange.shade700;
      default:
        return Colors.white;
    }
  }

  Widget _buildTextField(
    String label,
    Function(String) onChanged, {
    int maxLines = 1,
    IconData? prefixIcon,
    String? initial,
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
            hintText: label,
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
}

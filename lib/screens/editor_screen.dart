import 'package:flutter/material.dart';
import '../models/store_data.dart';
import '../widgets/vitrin_view.dart';
import 'preview_screen.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final StoreData _data = StoreData();

  final List<String> businessTypes = [
    'Butik', 'İç giyim', 'Kozmetik', 'Hediyelik', 'Market', 
    'Telefon aksesuarı', 'Kafe / Lokanta', 'Kuaför', 'Diğer'
  ];

  final List<String> themes = [
    'Sade', 'Premium', 'Zarif', 'Doğal', 'Gece', 'Lüks', 'Sahil', 'Güneş'
  ];

  final List<String> statuses = [
    'Açık', 'Bugün kampanya var', 'Yeni ürünler geldi', 'Stok sınırlı'
  ];

  void _addProduct() {
    setState(() {
      _data.products.add(Product(id: DateTime.now().millisecondsSinceEpoch.toString()));
    });
  }

  void _removeProduct(int index) {
    setState(() {
      _data.products.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Vitrin Düzenle', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;
          
          if (isWide) {
            return Row(
              children: [
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: _buildForm(),
                  ),
                ),
                VerticalDivider(width: 1, color: Colors.black.withValues(alpha: 0.05)),
                Expanded(
                  flex: 4,
                  child: Container(
                    color: Colors.grey.shade100,
                    child: Center(
                      child: _buildLivePreviewMockup(),
                    ),
                  ),
                ),
              ],
            );
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _buildForm(),
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
          _buildModeToggle(),
          const SizedBox(height: 32),
          
          _buildSectionTitle('Mağaza Görünümü'),
          const SizedBox(height: 16),
          _buildLogoUpload(),
          const SizedBox(height: 16),
          _buildTextField('Mağaza adı', (v) => setState(() => _data.name = v)),
          const SizedBox(height: 16),
          _buildDropdown('İşletme türü', _data.businessType, businessTypes, (v) => setState(() => _data.businessType = v!)),
          const SizedBox(height: 16),
          _buildTextField('Kısa açıklama (Vitrin Altı)', (v) => setState(() => _data.description = v), maxLines: 2),
          const SizedBox(height: 32),
          
          if (!_data.isEsnafMode) ...[
            _buildSectionTitle('Kurumsal Bilgiler'),
            const SizedBox(height: 16),
            _buildTextField('Hakkımızda Metni', (v) => setState(() => _data.corporateBio = v), maxLines: 4),
            const SizedBox(height: 32),
          ],

          _buildSectionTitle('İletişim & Sosyal'),
          const SizedBox(height: 16),
          _buildTextField('WhatsApp', (v) => setState(() => _data.whatsapp = v), prefixIcon: Icons.phone),
          const SizedBox(height: 16),
          _buildTextField('Instagram', (v) => setState(() => _data.instagram = v), prefixIcon: Icons.camera_alt),
          const SizedBox(height: 16),
          _buildTextField('Web sitesi', (v) => setState(() => _data.website = v), prefixIcon: Icons.language),
          const SizedBox(height: 16),
          _buildTextField('Satış / Pazaryeri Linki', (v) => setState(() => _data.salesLink = v), prefixIcon: Icons.shopping_bag),
          const SizedBox(height: 16),
          _buildTextField('Adres', (v) => setState(() => _data.address = v), prefixIcon: Icons.location_on, maxLines: 2),
          const SizedBox(height: 32),
          
          _buildSectionTitle('Tema & Durum'),
          const SizedBox(height: 16),
          _buildThemeSelector(),
          const SizedBox(height: 16),
          _buildDropdown('Vitrin durumu', _data.status, statuses, (v) => setState(() => _data.status = v!)),
          const SizedBox(height: 32),
          
          if (_data.isEsnafMode) ...[
            _buildSectionHeaderWithAction('Ürünler', _addProduct),
            const SizedBox(height: 16),
            ...List.generate(_data.products.length, (index) => _buildProductItem(index)),
            if (_data.products.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text('Henüz ürün eklenmedi.', style: TextStyle(color: Colors.grey.shade400)),
                ),
              ),
          ],
          
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 60,
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
                backgroundColor: Colors.blue.shade900,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
              child: const Text('Vitrini Önizle & Paylaş', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildLivePreviewMockup() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('CANLI ÖNİZLEME', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.black26)),
        const SizedBox(height: 32),
        Container(
          width: 375,
          height: 700,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.black, width: 8),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 40, offset: const Offset(0, 20))
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: VitrinView(storeData: _data, isEmbedded: true),
          ),
        ),
        const SizedBox(height: 32),
        const Text('Müşterileriniz vitrininizi bu şekilde görecek.', style: TextStyle(fontSize: 12, color: Colors.black45)),
      ],
    );
  }

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black.withValues(alpha: 0.05))),
      child: Row(
        children: [
          Expanded(
            child: _ModeTab(
              title: 'Esnaf Modu',
              isSelected: _data.isEsnafMode,
              onTap: () => setState(() => _data.isEsnafMode = true),
            ),
          ),
          Expanded(
            child: _ModeTab(
              title: 'Kurumsal Mod',
              isSelected: !_data.isEsnafMode,
              onTap: () => setState(() => _data.isEsnafMode = false),
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
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue.shade900.withValues(alpha: 0.2), style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined, size: 32, color: Colors.blue.shade900),
            const SizedBox(height: 8),
            Text('Logo veya Vitrin Görseli Yükle', style: TextStyle(color: Colors.blue.shade900, fontSize: 13, fontWeight: FontWeight.w600)),
            const Text('(Tıkla veya sürükle-bırak)', style: TextStyle(color: Colors.black38, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tema seçimi', style: TextStyle(fontSize: 14, color: Colors.black54)),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: themes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final isSelected = _data.theme == themes[index];
              return InkWell(
                onTap: () => setState(() => _data.theme = themes[index]),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: _getThemeColor(themes[index]),
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected ? Border.all(color: Colors.blue.shade900, width: 3) : Border.all(color: Colors.black12),
                        boxShadow: isSelected ? [BoxShadow(color: Colors.blue.shade900.withValues(alpha: 0.2), blurRadius: 8)] : null,
                      ),
                      child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                    ),
                    const SizedBox(height: 4),
                    Text(themes[index], style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  ],
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
      case 'Sade': return Colors.white;
      case 'Premium': return Colors.black87;
      case 'Zarif': return const Color(0xFF9E7C66);
      case 'Doğal': return Colors.green.shade700;
      case 'Gece': return const Color(0xFF0F172A);
      case 'Lüks': return const Color(0xFFD4AF37);
      case 'Sahil': return Colors.cyan.shade600;
      case 'Güneş': return Colors.orange.shade700;
      default: return Colors.white;
    }
  }

  Widget _buildProductItem(int index) {
    final product = _data.products[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black.withValues(alpha: 0.05))),
      child: Column(
        children: [
          Row(
            children: [
              _buildSmallImageUpload(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _buildSmallTextField('Ürün adı', (v) => setState(() => product.name = v), initial: product.name),
                    const SizedBox(height: 8),
                    _buildSmallTextField('Fiyat', (v) => setState(() => product.price = v), initial: product.price),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildSmallTextField('Kısa açıklama', (v) => setState(() => product.description = v), maxLines: 2, initial: product.description),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _removeProduct(index),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Sil', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallImageUpload() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black.withValues(alpha: 0.05))),
      child: const Icon(Icons.add_a_photo_outlined, size: 24, color: Colors.black26),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87));
  }

  Widget _buildSectionHeaderWithAction(String title, VoidCallback onAction) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSectionTitle(title),
        TextButton.icon(onPressed: onAction, icon: const Icon(Icons.add), label: const Text('Ekle')),
      ],
    );
  }

  Widget _buildTextField(String label, Function(String) onChanged, {int maxLines = 1, IconData? prefixIcon}) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.grey, size: 20) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      maxLines: maxLines,
      onChanged: onChanged,
    );
  }

  Widget _buildSmallTextField(String label, Function(String) onChanged, {int maxLines = 1, String initial = ''}) {
    return TextFormField(
      initialValue: initial,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      style: const TextStyle(fontSize: 13),
      maxLines: maxLines,
      onChanged: onChanged,
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, void Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: items.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
      onChanged: onChanged,
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeTab({required this.title, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade900 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          title,
          style: TextStyle(color: isSelected ? Colors.white : Colors.black54, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

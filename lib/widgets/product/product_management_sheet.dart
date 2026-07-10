import 'package:flutter/material.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/screens/bulk_product_upload_screen.dart';
import 'package:vixrex/screens/product_category_management_screen.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/widgets/product/product_editor_sheet.dart';
import 'package:vixrex/widgets/product/vixrex_catalog_assistant_section.dart';

typedef ProductCatalogChanged =
    Future<void> Function(
      List<Product> products,
      List<ProductCategory> categories,
    );

class ProductManagementSheet extends StatefulWidget {
  const ProductManagementSheet({
    super.key,
    required this.products,
    required this.categories,
    required this.storeSlug,
    required this.showMessage,
    required this.onCatalogChanged,
    required this.onOcrTap,
  });

  final List<Product> products;
  final List<ProductCategory> categories;
  final String storeSlug;
  final ValueChanged<String> showMessage;
  final ProductCatalogChanged onCatalogChanged;
  final VoidCallback onOcrTap;

  @override
  State<ProductManagementSheet> createState() => _ProductManagementSheetState();
}

class _ProductManagementSheetState extends State<ProductManagementSheet> {
  late List<Product> _products;
  late List<ProductCategory> _categories;
  final _searchController = TextEditingController();
  String _selectedCategoryId = '';

  @override
  void initState() {
    super.initState();
    _products = List.of(widget.products);
    _categories = List.of(widget.categories);
    _ensureCategories();
    _searchController.addListener(_refresh);
  }

  void _ensureCategories() {
    for (final product in _products) {
      final label = product.category.trim();
      if (label.isEmpty || label.toLowerCase() == 'tümü') continue;
      var match = _categories.where(
        (item) => item.name.trim().toLowerCase() == label.toLowerCase(),
      );
      if (match.isEmpty) {
        final category = ProductCategory(
          id:
              'category-${DateTime.now().microsecondsSinceEpoch}-${_categories.length}',
          name: label,
          sortOrder: _categories.length,
        );
        _categories.add(category);
        match = [category];
      }
      if (product.categoryId.trim().isEmpty) {
        product.categoryId = match.first.id;
      }
    }
    if (_categories.isEmpty) {
      _categories.add(
        ProductCategory(id: 'category-general', name: 'Genel', sortOrder: 0),
      );
    }
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  List<Product> get _filteredProducts {
    final query = _searchController.text.trim().toLowerCase();
    return _products.where((product) {
      final matchesCategory =
          _selectedCategoryId.isEmpty ||
          product.categoryId == _selectedCategoryId;
      final matchesQuery =
          query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.description.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  Future<void> _persist() async {
    for (var index = 0; index < _categories.length; index++) {
      _categories[index].sortOrder = index;
    }
    await widget.onCatalogChanged(List.of(_products), List.of(_categories));
  }

  Future<void> _openEditor([Product? product]) async {
    final result = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      builder:
          (_) => ProductEditorSheet(
            product: product,
            categories: _categories,
            storeSlug: widget.storeSlug,
          ),
    );
    if (result == null || !mounted) return;
    setState(() {
      final index = _products.indexWhere((item) => item.id == result.id);
      if (index < 0) {
        _products.insert(0, result);
      } else {
        _products[index] = result;
      }
    });
    await _persist();
    widget.showMessage(
      product == null ? 'Ürün taslağa eklendi.' : 'Ürün güncellendi.',
    );
  }

  Future<void> _openCategories() async {
    final result = await Navigator.push<ProductCategoryManagementResult>(
      context,
      MaterialPageRoute(
        builder:
            (_) => ProductCategoryManagementScreen(
              categories: _categories,
              products: _products,
            ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _categories = List.of(result.categories);
      _products = List.of(result.products);
      if (!_categories.any((item) => item.id == _selectedCategoryId)) {
        _selectedCategoryId = '';
      }
    });
    await _persist();
    widget.showMessage('Ürün kategorileri güncellendi.');
  }

  Future<void> _duplicate(Product product) async {
    final now = DateTime.now().microsecondsSinceEpoch.toString();
    final copy = Product(
      id: now,
      name: '${product.name} (Kopya)',
      price: product.price,
      description: product.description,
      imagePath: product.primaryImageUrl,
      imageUrls: product.displayImageUrls,
      categoryId: product.categoryId,
      category: product.category,
      stockStatus: product.stockStatus,
      isVisible: false,
      slug: null,
    );
    setState(() {
      final index = _products.indexOf(product);
      _products.insert(index < 0 ? 0 : index + 1, copy);
    });
    await _persist();
    widget.showMessage('Ürün kopyalandı ve gizli taslak olarak eklendi.');
  }

  Future<void> _delete(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Ürünü Sil'),
            content: Text('${product.name} taslaktan silinecek.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Vazgeç'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Sil'),
              ),
            ],
          ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _products.removeWhere((item) => item.id == product.id));
    await _persist();
    widget.showMessage(
      'Ürün taslaktan silindi. Değişikliği yayınlamayı unutmayın.',
    );
  }

  Future<void> _toggleVisibility(Product product, bool value) async {
    setState(() => product.isVisible = value);
    await _persist();
  }

  Future<void> _reorderProducts(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _products.removeAt(oldIndex);
      _products.insert(newIndex, item);
    });
    await _persist();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredProducts;
    final canReorder =
        _searchController.text.trim().isEmpty && _selectedCategoryId.isEmpty;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.88,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSheetHandle(),
            _buildHeader(),
            const SizedBox(height: 14),
            VixRexCatalogAssistantSection(
              onOcrTap: widget.onOcrTap,
              onSuggestionTap: () => widget.showMessage(
                'VixRex önerileri özelliği yakında aktif olacak.',
              ),
            ),
            const SizedBox(height: 14),
            _buildFilters(),
            const SizedBox(height: 10),
            Expanded(child: _buildProductList(filtered, canReorder)),
            const SizedBox(height: 12),
            _buildAddProductButton(),
            const SizedBox(height: 8),
            _buildBulkUploadButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ürün Yönetimi',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.darkText,
                ),
              ),
              Text(
                'Ürünlerini ve kategorilerini tek yerden yönet.',
                style: TextStyle(fontSize: 12, color: AppColors.mutedText),
              ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: _openCategories,
          icon: const Icon(Icons.category_outlined, size: 18),
          label: const Text('Kategoriler'),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Ürün ara...',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ChoiceChip(
                label: const Text('Tümü'),
                selected: _selectedCategoryId.isEmpty,
                onSelected: (_) => setState(() => _selectedCategoryId = ''),
              ),
              const SizedBox(width: 8),
              ..._categories.map(
                (category) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category.name),
                    selected: _selectedCategoryId == category.id,
                    onSelected:
                        (_) =>
                            setState(() => _selectedCategoryId = category.id),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductList(List<Product> filtered, bool canReorder) {
    if (_products.isEmpty) return _buildEmptyState();
    if (filtered.isEmpty) {
      return const Center(child: Text('Aramana uygun ürün bulunamadı.'));
    }
    if (canReorder) {
      return ReorderableListView.builder(
        itemCount: _products.length,
        onReorder: _reorderProducts,
        itemBuilder:
            (_, index) => Padding(
              key: ValueKey(_products[index].id),
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildProductItem(_products[index]),
            ),
      );
    }
    return ListView.separated(
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, index) => _buildProductItem(filtered[index]),
    );
  }

  Widget _buildAddProductButton() {
    return ElevatedButton.icon(
      onPressed: () => _openEditor(),
      icon: const Icon(Icons.add_rounded, size: 18),
      label: const Text(
        'Yeni Ürün Ekle',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        minimumSize: const Size.fromHeight(50),
      ),
    );
  }

  Widget _buildBulkUploadButton() {
    return OutlinedButton.icon(
      onPressed: _openBulkUpload,
      icon: const Icon(Icons.upload_file_rounded, size: 18),
      label: const Text(
        'Toplu Ürün Yükle',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.darkText,
        side: const BorderSide(color: AppColors.border),
        minimumSize: const Size.fromHeight(44),
      ),
    );
  }

  Future<void> _openBulkUpload() async {
    final result = await BulkProductUploadScreen.show(
      context: context,
      categories: _categories,
      onSaved: (products) async {
        setState(() {
          _products.insertAll(0, products);
        });
        await _persist();
      },
    );
    if (result == true && mounted) {
      widget.showMessage('Toplu yükleme tamamlandı.');
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.shopping_bag_outlined,
            color: AppColors.primary,
            size: 42,
          ),
          const SizedBox(height: 12),
          const Text(
            'Henüz ürün yok',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'İlk ürününü ekleyerek kataloğunu oluştur.',
            style: TextStyle(color: AppColors.mutedText, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(Product product) {
    final image = product.primaryImageUrl;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 58,
              height: 58,
              child:
                  image == null
                      ? _imageFallback()
                      : Image.network(
                        image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imageFallback(),
                      ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  '${product.category} • ${product.price.trim().isEmpty ? 'Fiyat belirtilmedi' : product.price}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  product.isVisible ? 'Vitrinde görünüyor' : 'Gizli taslak',
                  style: TextStyle(
                    color:
                        product.isVisible
                            ? AppColors.success
                            : AppColors.mutedText,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: product.isVisible,
            onChanged: (value) => _toggleVisibility(product, value),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') _openEditor(product);
              if (value == 'duplicate') _duplicate(product);
              if (value == 'delete') _delete(product);
            },
            itemBuilder:
                (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                  PopupMenuItem(value: 'duplicate', child: Text('Çoğalt')),
                  PopupMenuItem(value: 'delete', child: Text('Sil')),
                ],
          ),
        ],
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      color: AppColors.surface,
      child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/theme/app_colors.dart';

class ProductCategoryManagementResult {
  const ProductCategoryManagementResult({
    required this.categories,
    required this.products,
  });

  final List<ProductCategory> categories;
  final List<Product> products;
}

class ProductCategoryManagementScreen extends StatefulWidget {
  const ProductCategoryManagementScreen({
    super.key,
    required this.categories,
    required this.products,
  });

  final List<ProductCategory> categories;
  final List<Product> products;

  @override
  State<ProductCategoryManagementScreen> createState() =>
      _ProductCategoryManagementScreenState();
}

class _ProductCategoryManagementScreenState
    extends State<ProductCategoryManagementScreen> {
  late final List<ProductCategory> _categories;
  late final List<Product> _products;

  @override
  void initState() {
    super.initState();
    _categories =
        widget.categories
            .map(
              (item) => ProductCategory(
                id: item.id,
                name: item.name,
                sortOrder: item.sortOrder,
              ),
            )
            .toList();
    _products = widget.products.map((item) => item.copyWith()).toList();
  }

  Future<void> _addCategory() async {
    final name = await _showNameDialog(title: 'Yeni Kategori');
    if (name == null) return;
    setState(() {
      _categories.add(
        ProductCategory(
          id: 'category-${DateTime.now().microsecondsSinceEpoch}',
          name: name,
          sortOrder: _categories.length,
        ),
      );
    });
  }

  Future<void> _renameCategory(ProductCategory category) async {
    final name = await _showNameDialog(
      title: 'Kategoriyi Yeniden Adlandır',
      initialValue: category.name,
      excludedId: category.id,
    );
    if (name == null) return;
    setState(() {
      category.name = name;
      for (final product in _products) {
        if (product.categoryId == category.id) product.category = name;
      }
    });
  }

  Future<String?> _showNameDialog({
    required String title,
    String initialValue = '',
    String? excludedId,
  }) async {
    final controller = TextEditingController(text: initialValue);
    String? error;
    final result = await showDialog<String>(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: Text(title),
                  content: TextField(
                    controller: controller,
                    autofocus: true,
                    maxLength: 40,
                    decoration: InputDecoration(
                      labelText: 'Kategori adı',
                      errorText: error,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Vazgeç'),
                    ),
                    FilledButton(
                      onPressed: () {
                        final value = controller.text.trim();
                        if (value.isEmpty) {
                          setDialogState(
                            () => error = 'Kategori adı zorunludur.',
                          );
                          return;
                        }
                        final duplicate = _categories.any(
                          (item) =>
                              item.id != excludedId &&
                              item.name.trim().toLowerCase() ==
                                  value.toLowerCase(),
                        );
                        if (duplicate) {
                          setDialogState(
                            () => error = 'Bu kategori zaten mevcut.',
                          );
                          return;
                        }
                        Navigator.pop(dialogContext, value);
                      },
                      child: const Text('Kaydet'),
                    ),
                  ],
                ),
          ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _deleteCategory(ProductCategory category) async {
    if (_categories.length <= 1) {
      _showMessage('En az bir ürün kategorisi bulunmalıdır.');
      return;
    }
    final affected =
        _products
            .where((product) => product.categoryId == category.id)
            .toList();
    final replacements =
        _categories.where((item) => item.id != category.id).toList();
    var replacementId = replacements.first.id;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: const Text('Kategoriyi Sil'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        affected.isEmpty
                            ? '${category.name} kategorisi silinecek.'
                            : '${affected.length} ürün başka kategoriye taşınacak.',
                      ),
                      if (affected.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: replacementId,
                          decoration: const InputDecoration(
                            labelText: 'Yeni kategori',
                          ),
                          items:
                              replacements
                                  .map(
                                    (item) => DropdownMenuItem(
                                      value: item.id,
                                      child: Text(item.name),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (value) => setDialogState(
                                () => replacementId = value ?? replacementId,
                              ),
                        ),
                      ],
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Vazgeç'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text('Sil ve Taşı'),
                    ),
                  ],
                ),
          ),
    );
    if (confirmed != true || !mounted) return;
    final replacement = replacements.firstWhere(
      (item) => item.id == replacementId,
    );
    setState(() {
      for (final product in affected) {
        product.categoryId = replacement.id;
        product.category = replacement.name;
      }
      _categories.removeWhere((item) => item.id == category.id);
      _syncSortOrder();
    });
  }

  void _syncSortOrder() {
    for (var index = 0; index < _categories.length; index++) {
      _categories[index].sortOrder = index;
    }
  }

  void _finish() {
    _syncSortOrder();
    Navigator.pop(
      context,
      ProductCategoryManagementResult(
        categories: _categories,
        products: _products,
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ürün Kategorileri'),
        actions: [
          TextButton(onPressed: _finish, child: const Text('Kaydet')),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCategory,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Kategori Ekle'),
      ),
      body:
          _categories.isEmpty
              ? const Center(child: Text('Henüz kategori yok.'))
              : ReorderableListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                itemCount: _categories.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    final item = _categories.removeAt(oldIndex);
                    _categories.insert(newIndex, item);
                    _syncSortOrder();
                  });
                },
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final count =
                      _products
                          .where((product) => product.categoryId == category.id)
                          .length;
                  return Card(
                    key: ValueKey(category.id),
                    margin: const EdgeInsets.only(bottom: 10),
                    color: AppColors.surface,
                    child: ListTile(
                      leading: const Icon(
                        Icons.drag_handle_rounded,
                        color: AppColors.mutedText,
                      ),
                      title: Text(
                        category.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text('$count ürün'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'rename') _renameCategory(category);
                          if (value == 'delete') _deleteCategory(category);
                        },
                        itemBuilder:
                            (_) => const [
                              PopupMenuItem(
                                value: 'rename',
                                child: Text('Yeniden adlandır'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Sil'),
                              ),
                            ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}

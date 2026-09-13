import 'package:flutter/material.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/product_attribute_schema_service.dart';
import 'package:vixrex/services/product_category_sync_service.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/widgets/common/app_card.dart';
import 'package:vixrex/widgets/common/app_screen_scaffold.dart';

class ProductCategoryManagementResult {
  const ProductCategoryManagementResult({
    required this.categories,
    required this.products,
    this.deletions = const [],
  });

  final List<ProductCategory> categories;
  final List<Product> products;
  final List<ProductCategoryDeletion> deletions;
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
  final List<ProductCategoryDeletion> _deletions = [];
  List<ProductAttributeTemplate> _templates = const [
    ProductAttributeTemplate(
      key: 'generic',
      label: 'Genel ürün',
      itemKind: 'physical',
      attributes: [],
    ),
  ];

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
                productTemplateKey: item.productTemplateKey,
              ),
            )
            .toList();
    _products = widget.products.map((item) => item.copyWith()).toList();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    try {
      final schema = await const ProductAttributeSchemaService().load();
      if (!mounted || schema.templates.isEmpty) return;
      setState(() => _templates = schema.templates);
    } catch (_) {
      // Shared şema yüklenemezse mevcut generic davranış korunur.
    }
  }

  Future<void> _addCategory() async {
    final draft = await _showCategoryDialog(title: 'Yeni Kategori');
    if (draft == null || !mounted) return;
    setState(() {
      _categories.add(
        ProductCategory(
          id: 'category-${DateTime.now().microsecondsSinceEpoch}',
          name: draft.name,
          sortOrder: _categories.length,
          productTemplateKey: draft.templateKey,
        ),
      );
    });
  }

  Future<void> _editCategory(ProductCategory category) async {
    final draft = await _showCategoryDialog(
      title: 'Kategoriyi Düzenle',
      initialName: category.name,
      initialTemplateKey: category.productTemplateKey,
      excludedId: category.id,
    );
    if (draft == null || !mounted) return;
    setState(() {
      category.name = draft.name;
      category.productTemplateKey = draft.templateKey;
      for (final product in _products) {
        if (product.categoryId == category.id) product.category = draft.name;
      }
    });
  }

  Future<_CategoryDraft?> _showCategoryDialog({
    required String title,
    String initialName = '',
    String initialTemplateKey = 'generic',
    String? excludedId,
  }) async {
    final controller = TextEditingController(text: initialName);
    var templateKey = _templates.any((item) => item.key == initialTemplateKey)
        ? initialTemplateKey
        : 'generic';
    String? error;
    final result = await showDialog<_CategoryDraft>(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: Text(title),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: controller,
                        autofocus: true,
                        maxLength: 40,
                        decoration: InputDecoration(
                          labelText: 'Kategori adı',
                          errorText: error,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: templateKey,
                        decoration: const InputDecoration(
                          labelText: 'Ürün tipi',
                          helperText:
                              'Bu seçim, ürün eklerken hangi bilgilerin isteneceğini belirler.',
                        ),
                        items:
                            _templates
                                .map(
                                  (template) => DropdownMenuItem(
                                    value: template.key,
                                    child: Text(template.label),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (value) => setDialogState(
                              () => templateKey = value ?? 'generic',
                            ),
                      ),
                    ],
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
                        Navigator.pop(
                          dialogContext,
                          _CategoryDraft(
                            name: value,
                            templateKey: templateKey,
                          ),
                        );
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
      _deletions.add(
        ProductCategoryDeletion(
          categoryId: category.id,
          replacementCategoryId: replacement.id,
        ),
      );
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
        deletions: _deletions,
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _templateLabel(String key) {
    for (final template in _templates) {
      if (template.key == key) return template.label;
    }
    return 'Genel ürün';
  }

  @override
  Widget build(BuildContext context) {
    return AppScreenScaffold(
      title: 'Ürün Kategorileri',
      actions: [
        TextButton(onPressed: _finish, child: const Text('Kaydet')),
        const SizedBox(width: 8),
      ],
      padding: EdgeInsets.zero,
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
                  return Padding(
                    key: ValueKey(category.id),
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.drag_handle_rounded,
                            color: AppColors.mutedText,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$count ürün · ${_templateLabel(category.productTemplateKey)}',
                                  style: const TextStyle(
                                    color: AppColors.mutedText,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') _editCategory(category);
                              if (value == 'delete') _deleteCategory(category);
                            },
                            itemBuilder:
                                (_) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Düzenle'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Sil'),
                                  ),
                                ],
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

class _CategoryDraft {
  const _CategoryDraft({required this.name, required this.templateKey});

  final String name;
  final String templateKey;
}

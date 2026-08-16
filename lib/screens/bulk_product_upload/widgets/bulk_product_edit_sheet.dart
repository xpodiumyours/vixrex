import 'package:flutter/material.dart';
import 'package:vixrex/models/store_product.dart';
import 'package:vixrex/theme/app_colors.dart';

class BulkProductEditSheet extends StatefulWidget {
  final Product product;
  final List<ProductCategory> categories;

  const BulkProductEditSheet({
    super.key,
    required this.product,
    required this.categories,
  });

  @override
  State<BulkProductEditSheet> createState() => _BulkProductEditSheetState();
}

class _BulkProductEditSheetState extends State<BulkProductEditSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _descController;
  late String _categoryId;
  late String _stockStatus;

  static final _stockOptions = [
    StockStatus.available.label,
    StockStatus.lowStock.label,
    StockStatus.soldOut.label,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _priceController = TextEditingController(text: widget.product.price);
    _descController = TextEditingController(text: widget.product.description);
    _stockStatus =
        _stockOptions.contains(widget.product.stockStatus)
            ? widget.product.stockStatus
            : StockStatus.available.label;
    _categoryId = _resolveCategoryId();
  }

  String _resolveCategoryId() {
    final explicit = widget.product.categoryId.trim();
    if (widget.categories.any((c) => c.id == explicit)) return explicit;
    final label = widget.product.category.trim().toLowerCase();
    for (final c in widget.categories) {
      if (c.name.trim().toLowerCase() == label) return c.id;
    }
    return widget.categories.isEmpty ? '' : widget.categories.first.id;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ürün adı zorunludur.')));
      return;
    }
    final category = widget.categories.where((c) => c.id == _categoryId);
    Navigator.of(context).pop(
      widget.product.copyWith(
        name: name,
        price: _priceController.text.trim(),
        description: _descController.text.trim(),
        categoryId: _categoryId,
        category: category.isNotEmpty ? category.first.name : 'Genel',
        stockStatus: _stockStatus,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ürünü Düzenle',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Ürün adı *',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _priceController,
                maxLength: 30,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Fiyat (₺)',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descController,
                maxLength: 500,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              if (widget.categories.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _categoryId.isEmpty ? null : _categoryId,
                  dropdownColor: AppColors.surfaceSoft,
                  decoration: const InputDecoration(labelText: 'Kategori'),
                  items:
                      widget.categories
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _categoryId = v ?? ''),
                ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _stockStatus,
                dropdownColor: AppColors.surfaceSoft,
                decoration: const InputDecoration(labelText: 'Stok durumu'),
                items:
                    _stockOptions
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                onChanged:
                    (v) => setState(
                      () => _stockStatus = v ?? StockStatus.available.label,
                    ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text(
                  'Kaydet',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

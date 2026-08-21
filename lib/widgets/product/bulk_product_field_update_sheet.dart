import 'package:flutter/material.dart';
import 'package:vixrex/models/store_product.dart';
import 'package:vixrex/services/bulk_product_field_update_service.dart';
import 'package:vixrex/theme/app_colors.dart';

enum _BulkField { price, stockStatus, category, visibility }

/// #262: seçili ürünlere hangi TOPLU değişikliğin uygulanacağını sorar.
/// Kendisi hiçbir uzak yazma yapmaz — seçilen aksiyona göre tek bir
/// `onApply*` callback'i çağırıp kapanır; asıl hesaplama
/// [BulkProductFieldUpdateService]de, asıl kaydetme çağıranda
/// (`product_management_sheet.dart`ın zaten sahip olduğu `_persist()`).
class BulkProductFieldUpdateSheet extends StatefulWidget {
  const BulkProductFieldUpdateSheet({
    super.key,
    required this.selectedCount,
    required this.categories,
    required this.onApplyPrice,
    required this.onApplyStockStatus,
    required this.onApplyCategory,
    required this.onApplyVisibility,
  });

  final int selectedCount;
  final List<ProductCategory> categories;
  final void Function(PriceAdjustMode mode, double value) onApplyPrice;
  final ValueChanged<String> onApplyStockStatus;
  final ValueChanged<ProductCategory> onApplyCategory;
  final ValueChanged<bool> onApplyVisibility;

  @override
  State<BulkProductFieldUpdateSheet> createState() =>
      _BulkProductFieldUpdateSheetState();
}

class _BulkProductFieldUpdateSheetState
    extends State<BulkProductFieldUpdateSheet> {
  _BulkField _field = _BulkField.price;
  PriceAdjustMode _priceMode = PriceAdjustMode.increasePercent;
  final _priceValueController = TextEditingController();
  String _stockStatus = StockStatus.available.label;
  String _categoryId = '';
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    if (widget.categories.isNotEmpty) {
      _categoryId = widget.categories.first.id;
    }
  }

  @override
  void dispose() {
    _priceValueController.dispose();
    super.dispose();
  }

  void _apply() {
    switch (_field) {
      case _BulkField.price:
        final value = double.tryParse(
          _priceValueController.text.trim().replaceAll(',', '.'),
        );
        if (value == null) {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              const SnackBar(content: Text('Geçerli bir sayı gir.')),
            );
          return;
        }
        widget.onApplyPrice(_priceMode, value);
        break;
      case _BulkField.stockStatus:
        widget.onApplyStockStatus(_stockStatus);
        break;
      case _BulkField.category:
        final category = widget.categories.where(
          (item) => item.id == _categoryId,
        );
        if (category.isEmpty) return;
        widget.onApplyCategory(category.first);
        break;
      case _BulkField.visibility:
        widget.onApplyVisibility(_visible);
        break;
    }
    Navigator.of(context).pop();
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
            children: [
              Text(
                '${widget.selectedCount} ürünü toplu düzenle',
                style: const TextStyle(
                  color: AppColors.darkText,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Yalnız seçtiğin alan değişir, diğer alanlara dokunulmaz.',
                style: TextStyle(color: AppColors.mutedText, fontSize: 12),
              ),
              const SizedBox(height: 18),
              _buildFieldPicker(),
              const SizedBox(height: 16),
              _buildFieldForm(),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _apply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text(
                  'Uygula',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldPicker() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _fieldChip(_BulkField.price, 'Fiyat'),
        _fieldChip(_BulkField.stockStatus, 'Stok durumu'),
        _fieldChip(_BulkField.category, 'Kategori'),
        _fieldChip(_BulkField.visibility, 'Görünürlük'),
      ],
    );
  }

  Widget _fieldChip(_BulkField field, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _field == field,
      onSelected: (_) => setState(() => _field = field),
    );
  }

  Widget _buildFieldForm() {
    switch (_field) {
      case _BulkField.price:
        return _buildPriceForm();
      case _BulkField.stockStatus:
        return _buildStockStatusForm();
      case _BulkField.category:
        return _buildCategoryForm();
      case _BulkField.visibility:
        return _buildVisibilityForm();
    }
  }

  Widget _buildPriceForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<PriceAdjustMode>(
          value: _priceMode,
          dropdownColor: AppColors.surfaceSoft,
          decoration: const InputDecoration(labelText: 'İşlem'),
          items: const [
            DropdownMenuItem(
              value: PriceAdjustMode.increasePercent,
              child: Text('Yüzde artır (ör. %10 zam)'),
            ),
            DropdownMenuItem(
              value: PriceAdjustMode.decreasePercent,
              child: Text('Yüzde azalt (indirim)'),
            ),
            DropdownMenuItem(
              value: PriceAdjustMode.increaseAmount,
              child: Text('Sabit tutar ekle (TL)'),
            ),
            DropdownMenuItem(
              value: PriceAdjustMode.decreaseAmount,
              child: Text('Sabit tutar düş (TL)'),
            ),
            DropdownMenuItem(
              value: PriceAdjustMode.setExact,
              child: Text('Hepsini aynı tutara eşitle'),
            ),
          ],
          onChanged:
              (value) => setState(() => _priceMode = value ?? _priceMode),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _priceValueController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText:
                _priceMode == PriceAdjustMode.increasePercent ||
                        _priceMode == PriceAdjustMode.decreasePercent
                    ? 'Yüzde (ör. 10)'
                    : 'Tutar (TL)',
          ),
        ),
        if (_priceMode != PriceAdjustMode.setExact) ...[
          const SizedBox(height: 8),
          const Text(
            'Fiyatı bir sayı olarak okunamayan ürünler değiştirilmeden atlanır.',
            style: TextStyle(color: AppColors.mutedText, fontSize: 11),
          ),
        ],
      ],
    );
  }

  Widget _buildStockStatusForm() {
    return DropdownButtonFormField<String>(
      value: _stockStatus,
      dropdownColor: AppColors.surfaceSoft,
      decoration: const InputDecoration(labelText: 'Yeni stok durumu'),
      items:
          StockStatus.values
              .map(
                (status) => DropdownMenuItem(
                  value: status.label,
                  child: Text(status.label),
                ),
              )
              .toList(),
      onChanged:
          (value) => setState(() => _stockStatus = value ?? _stockStatus),
    );
  }

  Widget _buildCategoryForm() {
    if (widget.categories.isEmpty) {
      return const Text(
        'Önce en az bir kategori oluşturman gerekiyor.',
        style: TextStyle(color: AppColors.mutedText),
      );
    }
    return DropdownButtonFormField<String>(
      value: _categoryId,
      dropdownColor: AppColors.surfaceSoft,
      decoration: const InputDecoration(labelText: 'Yeni kategori'),
      items:
          widget.categories
              .map(
                (category) => DropdownMenuItem(
                  value: category.id,
                  child: Text(category.name),
                ),
              )
              .toList(),
      onChanged: (value) => setState(() => _categoryId = value ?? _categoryId),
    );
  }

  Widget _buildVisibilityForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RadioListTile<bool>(
          contentPadding: EdgeInsets.zero,
          title: const Text('Vitrinde göster'),
          value: true,
          groupValue: _visible,
          onChanged: (value) => setState(() => _visible = value ?? true),
        ),
        RadioListTile<bool>(
          contentPadding: EdgeInsets.zero,
          title: const Text('Vitrinden gizle'),
          value: false,
          groupValue: _visible,
          onChanged: (value) => setState(() => _visible = value ?? false),
        ),
      ],
    );
  }
}

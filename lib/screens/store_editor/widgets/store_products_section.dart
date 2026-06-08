import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:vitrinx/models/store_data.dart';
import '../store_editor_controller.dart';
import 'editor_ui_components.dart';
import 'package:vitrinx/services/store_shelf_upload_service.dart';

class StoreProductsSection extends StatefulWidget {
  final StoreEditorController controller;

  const StoreProductsSection({
    super.key,
    required this.controller,
  });

  @override
  State<StoreProductsSection> createState() => _StoreProductsSectionState();
}

class _StoreProductsSectionState extends State<StoreProductsSection> {
  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final products = controller.data.products;

        return EditCard(
          title: 'Ürün Kataloğu',
          onAction: () => _showProductFormDialog(context),
          children: [
            ...List.generate(
              products.length,
              (index) => _buildProductItem(context, index),
            ),
            if (products.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Henüz ürün eklenmedi.',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildProductItem(BuildContext context, int index) {
    final controller = widget.controller;
    final product = controller.data.products[index];
    const cardBorder = Color.fromRGBO(15, 23, 42, 0.10);
    const darkText = Color(0xFF111827);
    const mutedText = Color(0xFF64748B);
    const softText = Color(0xFF334155);
    const inputBg = Color(0xFFF1F5F9);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          if (product.imagePath != null && product.imagePath!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                product.imagePath!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                cacheWidth: 96,
                cacheHeight: 96,
                errorBuilder: (_, __, ___) => Container(
                  width: 48,
                  height: 48,
                  color: inputBg,
                  child: const Icon(Icons.image_not_supported_rounded, size: 20, color: mutedText),
                ),
              ),
            )
          else
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shopping_bag_outlined, size: 20, color: mutedText),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: darkText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${product.price} TL • ${product.stockStatus}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: mutedText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (product.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    product.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: softText.withAlpha((0.8 * 255).round()),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18, color: mutedText),
            onPressed: () => _showProductFormDialog(context, editIndex: index),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
            onPressed: () => controller.removeProduct(index, context),
          ),
        ],
      ),
    );
  }

  void _showProductFormDialog(BuildContext context, {int? editIndex}) {
    final controller = widget.controller;
    final isEdit = editIndex != null;
    final product = isEdit
        ? controller.data.products[editIndex]
        : Product(id: DateTime.now().microsecondsSinceEpoch.toString());

    final nameCtrl = TextEditingController(text: product.name);
    final priceCtrl = TextEditingController(text: product.price);
    final descCtrl = TextEditingController(text: product.description);
    String selectedStatus = product.stockStatus;
    String? productImagePath = product.imagePath;
    bool isUploadingImage = false;

    final productCategories = const ['Genel', 'Elbise', 'Günlük giyim', 'Ayakkabı', 'Aksesuar', 'Yiyecek & İçecek', 'Elektronik', 'Diğer'];
    String selectedCategory = productCategories.contains(product.category) ? product.category : 'Genel';

    const primaryColor = Color(0xFFFF4D00);
    const darkText = Color(0xFF111827);
    const mutedText = Color(0xFF64748B);
    const cardBorder = Color.fromRGBO(15, 23, 42, 0.10);
    const inputBg = Color(0xFFF1F5F9);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickProductImage() async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.image,
                withData: true,
              );
              if (result == null || result.files.isEmpty) return;
              
              setDialogState(() => isUploadingImage = true);
              try {
                final file = result.files.first;
                final bytes = file.bytes;
                if (bytes == null) return;
                
                final slug = controller.generateStoreSlug(controller.data.name);
                final uploadService = const StoreShelfUploadService();
                final url = await uploadService.uploadShelfImage(
                  bytes,
                  '$slug/products',
                  fileExtension: file.extension ?? 'jpg',
                );
                setDialogState(() {
                  productImagePath = url;
                  isUploadingImage = false;
                });
              } catch (e) {
                setDialogState(() => isUploadingImage = false);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Fotoğraf yüklenemedi: $e')),
                );
              }
            }

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                isEdit ? 'Ürünü Düzenle' : 'Yeni Ürün Ekle',
                style: const TextStyle(fontWeight: FontWeight.bold, color: darkText),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: isUploadingImage ? null : pickProductImage,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: inputBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: cardBorder),
                        ),
                        child: isUploadingImage
                            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                            : (productImagePath != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(productImagePath!, fit: BoxFit.cover, cacheWidth: 300, cacheHeight: 300),
                                  )
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo_rounded, color: mutedText),
                                      SizedBox(height: 4),
                                      Text('Fotoğraf', style: TextStyle(fontSize: 11, color: mutedText)),
                                    ],
                                  )),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Ürün Adı *'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Fiyat (TL)'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(labelText: 'Açıklama'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Ürün Kategorisi'),
                      items: productCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setDialogState(() => selectedCategory = v!),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: const InputDecoration(labelText: 'Stok Durumu'),
                      items: const [
                        DropdownMenuItem(value: 'Mevcut', child: Text('Mevcut')),
                        DropdownMenuItem(value: 'Son birkaç adet', child: Text('Son birkaç adet')),
                        DropdownMenuItem(value: 'Tükendi', child: Text('Tükendi')),
                      ],
                      onChanged: (v) => setDialogState(() => selectedStatus = v!),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Vazgeç', style: TextStyle(color: mutedText)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) return;
                    final newProduct = Product(
                      id: product.id,
                      name: nameCtrl.text.trim(),
                      price: priceCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      imagePath: productImagePath,
                      category: selectedCategory,
                      stockStatus: selectedStatus,
                    );
                    if (isEdit) {
                      controller.updateProduct(editIndex, newProduct, context);
                    } else {
                      controller.addProduct(newProduct, context);
                    }
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

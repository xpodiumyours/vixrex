import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vixrex/controllers/bulk_product_upload_controller.dart';
import 'package:vixrex/models/store_product.dart';
import 'package:vixrex/services/bulk_product_upload_service.dart';
import 'package:vixrex/theme/app_colors.dart';

typedef OnBulkProductsSaved = Future<void> Function(List<Product> products);

/// Toplu ürün yükleme ekranı.
/// Excel/CSV dosyasından ürünleri parse eder, kullanıcıya sunar, onay sonrası kaydeder.
class BulkProductUploadScreen extends StatefulWidget {
  final OnBulkProductsSaved onSaved;
  final List<ProductCategory> categories;

  const BulkProductUploadScreen({
    super.key,
    required this.onSaved,
    this.categories = const [],
  });

  static Future<bool?> show({
    required BuildContext context,
    required OnBulkProductsSaved onSaved,
    List<ProductCategory> categories = const [],
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      builder: (_) => BulkProductUploadScreen(
        onSaved: onSaved,
        categories: categories,
      ),
    );
  }

  @override
  State<BulkProductUploadScreen> createState() => _BulkProductUploadScreenState();
}

class _BulkProductUploadScreenState extends State<BulkProductUploadScreen> {
  final _controller = BulkProductUploadController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'csv', 'xml'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) {
      _showMessage('Dosya okunamadı.');
      return;
    }

    await _controller.parseFile(file.bytes!, fileName: file.name);
  }

  Future<void> _save() async {
    final saved = await _controller.saveProducts(
      onSave: (products) async => widget.onSaved(products),
    );
    if (saved && mounted) {
      _showMessage('${_controller.savedCount} ürün başarıyla eklendi.');
      Navigator.of(context).pop(true);
    } else if (_controller.errorMessage != null && mounted) {
      _showMessage(_controller.errorMessage!);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.92,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHandle(),
                _buildHeader(),
                const SizedBox(height: 16),
                Expanded(child: _buildBody()),
                if (_controller.state == BulkUploadState.review) ...[
                  const SizedBox(height: 12),
                  _buildBottomActions(),
                ],
                if (_controller.state == BulkUploadState.saved) ...[
                  const SizedBox(height: 12),
                  _buildSuccessActions(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
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
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.upload_file_rounded, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Toplu Ürün Yükleme',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.darkText,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Excel veya CSV dosyasından ürünleri içe aktar.',
                style: TextStyle(fontSize: 12, color: AppColors.mutedText),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    switch (_controller.state) {
      case BulkUploadState.initial:
        return _buildInitialView();
      case BulkUploadState.parsing:
        return _buildParsingView();
      case BulkUploadState.review:
        return _buildReviewView();
      case BulkUploadState.saving:
        return _buildSavingView();
      case BulkUploadState.saved:
        return _buildSavedView();
      case BulkUploadState.error:
        return _buildErrorView();
    }
  }

  // ─── BAŞLANGIÇ EKRANI ──────────────────────────────────────────

  Widget _buildInitialView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Icon(
            Icons.table_chart_rounded,
            size: 48,
            color: AppColors.primary.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Dosya seçin',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Excel (.xlsx), CSV veya XML dosyası seçerek\nürünlerinizi toplu olarak ekleyebilirsiniz.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.mutedText),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.folder_open_rounded, size: 20),
            label: const Text(
              'Dosya Seç',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: _downloadTemplate,
          icon: const Icon(Icons.download_rounded, size: 18),
          label: const Text('Şablon İndir'),
        ),
        const SizedBox(height: 20),
        _buildFormatInfo(),
      ],
    );
  }

  Widget _buildFormatInfo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Desteklenen sütunlar',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 8),
          _formatRow('Ürün Adı', 'Zorunlu', true),
          _formatRow('Fiyat', 'İsteğe bağlı', false),
          _formatRow('Açıklama', 'İsteğe bağlı', false),
          _formatRow('Kategori', 'İsteğe bağlı, varsayılan: Genel', false),
          _formatRow('Stok Durumu', 'Mevcut / Tükendi / Son birkaç adet', false),
          const SizedBox(height: 10),
          const Text(
            'Sütun başlıkları büyük/küçük harf duyarsızdır. '
            '"Ürün Adı", "ürün adı", "Name" gibi farklı formatları tanır.',
            style: TextStyle(fontSize: 11, color: AppColors.mutedText),
          ),
        ],
      ),
    );
  }

  Widget _formatRow(String label, String description, bool required) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            required ? Icons.star_rounded : Icons.circle,
            size: required ? 14 : 6,
            color: required ? AppColors.primary : AppColors.mutedText,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.darkTextAlt,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(fontSize: 11, color: AppColors.mutedText),
            ),
          ),
        ],
      ),
    );
  }

  // ─── PARSE EKRANI ──────────────────────────────────────────────

  Widget _buildParsingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text(
            'Dosya okunuyor...',
            style: TextStyle(color: AppColors.mutedText),
          ),
        ],
      ),
    );
  }

  // ─── KAYDETME EKRANI ───────────────────────────────────────────

  Widget _buildSavingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text(
            'Ürünler kaydediliyor...',
            style: TextStyle(color: AppColors.mutedText),
          ),
        ],
      ),
    );
  }

  // ─── İNCELEME EKRANI ───────────────────────────────────────────

  Widget _buildReviewView() {
    final products = _controller.products;
    return Column(
      children: [
        _buildReviewStats(products),
        const SizedBox(height: 10),
        if (_controller.parseResult?.errors.isNotEmpty == true) ...[
          _buildErrorsBanner(),
          const SizedBox(height: 10),
        ],
        Expanded(
          child: ListView.separated(
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _buildProductReviewItem(index, products[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewStats(List<Product> products) {
    final visibleCount = products.where((p) => p.isVisible).length;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _statItem('${products.length}', 'Toplam'),
          _statDivider(),
          _statItem('$visibleCount', 'Vitrinde'),
          _statDivider(),
          _statItem('${products.length - visibleCount}', 'Gizli'),
          const Spacer(),
          TextButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Yeni Dosya', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.darkText,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.mutedText),
          ),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: AppColors.border,
    );
  }

  Widget _buildErrorsBanner() {
    final errors = _controller.parseResult!.errors;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${errors.length} satırda hata bulundu. Bu satırlar atlandı.',
              style: const TextStyle(fontSize: 12, color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductReviewItem(int index, Product product) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: product.isVisible ? AppColors.border : AppColors.border.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Görsel placeholder
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: product.primaryImageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      product.primaryImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _productIcon(),
                    ),
                  )
                : _productIcon(),
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
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      product.price.isEmpty ? 'Fiyat yok' : '${product.price} ₺',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: product.price.isEmpty ? AppColors.mutedText : AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      product.category,
                      style: const TextStyle(fontSize: 11, color: AppColors.mutedText),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Düzenle butonu
          IconButton(
            onPressed: () => _editProduct(index, product),
            icon: const Icon(Icons.edit_rounded, size: 18),
            color: AppColors.mutedText,
            tooltip: 'Düzenle',
          ),
          // Görünürlük switch'i
          Switch.adaptive(
            value: product.isVisible,
            onChanged: (val) {
              product.isVisible = val;
              _controller.updateProduct(index, product);
            },
          ),
          // Sil butonu
          IconButton(
            onPressed: () => _controller.removeProduct(index),
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            color: AppColors.error,
            tooltip: 'Kaldır',
          ),
        ],
      ),
    );
  }

  Widget _productIcon() {
    return const Center(
      child: Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 22),
    );
  }

  Future<void> _editProduct(int index, Product product) async {
    final result = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      builder: (_) => _BulkProductEditSheet(
        product: product,
        categories: widget.categories,
      ),
    );
    if (result != null) {
      _controller.updateProduct(index, result);
    }
  }

  // ─── KAYIT BAŞARILI ────────────────────────────────────────────

  Widget _buildSavedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${_controller.savedCount} ürün eklendi',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ürünleriniz vitrininize eklendi.\nDeğişiklikleri yayınlamayı unutmayın.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.mutedText),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              _controller.reset();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.darkText,
              side: const BorderSide(color: AppColors.border),
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Yeni Dosya Yükle'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Tamam', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ),
      ],
    );
  }

  // ─── HATA EKRANI ───────────────────────────────────────────────

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Bir hata oluştu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _controller.errorMessage ?? 'Bilinmeyen hata',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.mutedText),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              _controller.reset();
              _pickFile();
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Tekrar Dene'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  // ─── ALT BUTONLAR ──────────────────────────────────────────────

  Widget _buildBottomActions() {
    final products = _controller.products;
    final visibleCount = products.where((p) => p.isVisible).length;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: products.isEmpty ? null : _showBulkActionsSheet,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.darkText,
              side: const BorderSide(color: AppColors.border),
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Toplu İşlem'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: visibleCount > 0 ? _save : null,
            icon: const Icon(Icons.check_rounded, size: 18),
            label: Text(
              '$visibleCount Ürünü Ekle',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ),
      ],
    );
  }

  void _showBulkActionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Toplu İşlemler',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.visibility_rounded, color: AppColors.success),
              title: const Text('Tümünü Vitrinde Göster'),
              onTap: () {
                Navigator.pop(context);
                _controller.approveAll();
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility_off_rounded, color: AppColors.mutedText),
              title: const Text('Tümünü Gizle'),
              onTap: () {
                Navigator.pop(context);
                _controller.hideAll();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadTemplate() async {
    final bytes = const BulkProductUploadService().generateTemplateCsv();
    const fileName = 'vixrex_urun_sablonu.csv';

    try {
      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'CSV şablonunu kaydet',
        fileName: fileName,
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: const ['csv'],
      );
      if (savedPath != null) {
        if (!mounted) return;
        _showMessage('Şablon kaydedildi.');
        return;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('_downloadTemplate saveFile: $e');
    }

    try {
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              bytes,
              mimeType: 'text/csv',
              name: fileName,
            ),
          ],
          subject: 'Vixrex ürün CSV şablonu',
          text: 'Ürün Adı, Fiyat, Açıklama, Kategori, Stok Durumu sütunlarını doldurun.',
        ),
      );
      if (result.status == ShareResultStatus.unavailable) {
        if (!mounted) return;
        _showMessage('Şablon paylaşımı bu cihazda açılamadı. Tekrar deneyin.');
        return;
      }
      if (!mounted) return;
      if (result.status == ShareResultStatus.success) {
        _showMessage('Şablon paylaşıldı.');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('_downloadTemplate share: $e');
      if (!mounted) return;
      _showMessage('Şablon indirilemedi. Lütfen tekrar deneyin.');
    }
  }
}

// ─── ÜRÜN DÜZENLEME SAYFASI ────────────────────────────────────

class _BulkProductEditSheet extends StatefulWidget {
  final Product product;
  final List<ProductCategory> categories;

  const _BulkProductEditSheet({
    required this.product,
    required this.categories,
  });

  @override
  State<_BulkProductEditSheet> createState() => _BulkProductEditSheetState();
}

class _BulkProductEditSheetState extends State<_BulkProductEditSheet> {
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
    _stockStatus = _stockOptions.contains(widget.product.stockStatus)
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ürün adı zorunludur.')),
      );
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
                decoration: const InputDecoration(labelText: 'Ürün adı *', counterText: ''),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _priceController,
                maxLength: 30,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Fiyat (₺)', counterText: ''),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descController,
                maxLength: 500,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Açıklama', counterText: ''),
              ),
              const SizedBox(height: 12),
              if (widget.categories.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _categoryId.isEmpty ? null : _categoryId,
                  dropdownColor: AppColors.surfaceSoft,
                  decoration: const InputDecoration(labelText: 'Kategori'),
                  items: widget.categories
                      .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                      .toList(),
                  onChanged: (v) => setState(() => _categoryId = v ?? ''),
                ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _stockStatus,
                dropdownColor: AppColors.surfaceSoft,
                decoration: const InputDecoration(labelText: 'Stok durumu'),
                items: _stockOptions
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _stockStatus = v ?? StockStatus.available.label),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text('Kaydet', style: TextStyle(fontWeight: FontWeight.w900)),
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

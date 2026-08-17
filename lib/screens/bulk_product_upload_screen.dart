import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vixrex/controllers/bulk_product_upload_controller.dart';
import 'package:vixrex/models/store_product.dart';
import 'package:vixrex/screens/bulk_product_upload/widgets/bulk_upload_initial_view.dart';
import 'package:vixrex/screens/bulk_product_upload/widgets/bulk_upload_parsing_view.dart';
import 'package:vixrex/screens/bulk_product_upload/widgets/bulk_upload_saving_view.dart';
import 'package:vixrex/screens/bulk_product_upload/widgets/bulk_upload_saved_view.dart';
import 'package:vixrex/screens/bulk_product_upload/widgets/bulk_upload_error_view.dart';
import 'package:vixrex/screens/bulk_product_upload/widgets/bulk_upload_review_view.dart';
import 'package:vixrex/screens/bulk_product_upload/widgets/bulk_product_edit_sheet.dart';
import 'package:vixrex/services/bulk_product_upload_service.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/theme/app_text_styles.dart';
import 'package:vixrex/widgets/xml_upload_dialog.dart';

typedef OnBulkProductsSaved = Future<void> Function(List<Product> products);

/// Toplu ürün yükleme ekranı.
/// Excel/CSV dosyasından ürünleri parse eder, kullanıcıya sunar, onay sonrası kaydeder.
class BulkProductUploadScreen extends StatefulWidget {
  final OnBulkProductsSaved onSaved;
  final List<ProductCategory> categories;
  final String storeId;
  final String editToken;

  const BulkProductUploadScreen({
    super.key,
    required this.onSaved,
    this.categories = const [],
    this.storeId = '',
    this.editToken = '',
  });

  static Future<bool?> show({
    required BuildContext context,
    required OnBulkProductsSaved onSaved,
    List<ProductCategory> categories = const [],
    String storeId = '',
    String editToken = '',
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      builder:
          (_) => BulkProductUploadScreen(
            onSaved: onSaved,
            categories: categories,
            storeId: storeId,
            editToken: editToken,
          ),
    );
  }

  @override
  State<BulkProductUploadScreen> createState() =>
      _BulkProductUploadScreenState();
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
      allowedExtensions: ['xlsx', 'csv'],
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
            borderRadius: BorderRadius.circular(AppColors.radius10),
          ),
          child: const Icon(
            Icons.upload_file_rounded,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Toplu Ürün Yükleme',
                style: AppTextStyles.sectionTitle,
              ),
              SizedBox(height: 2),
              Text(
                'Excel veya CSV dosyasından ürünleri içe aktar.',
                style: AppTextStyles.caption,
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
    return BulkUploadInitialView(
      onPickFile: _pickFile,
      onDownloadTemplate: _downloadTemplate,
      onOpenXmlUpload: _openXmlUpload,
    );
  }

  // ─── PARSE EKRANI ──────────────────────────────────────────────

  Widget _buildParsingView() {
    return const BulkUploadParsingView();
  }

  // ─── KAYDETME EKRANI ───────────────────────────────────────────

  Widget _buildSavingView() {
    return const BulkUploadSavingView();
  }

  Widget _buildReviewView() {
    return BulkUploadReviewView(
      products: _controller.products,
      errorCount: _controller.parseResult?.errors.length ?? 0,
      onPickFile: _pickFile,
      onEditProduct: _editProduct,
      onRemoveProduct: _controller.removeProduct,
    );
  }

  // ─── KAYIT BAŞARILI ────────────────────────────────────────────

  Widget _buildSavedView() {
    return BulkUploadSavedView(
      savedCount: _controller.savedCount,
      onReset: _controller.reset,
      onDismiss: () => Navigator.of(context).pop(true),
    );
  }

  Widget _buildSuccessActions() {
    return BulkUploadSavedView.successActions(
      onReset: _controller.reset,
      onDismiss: () => Navigator.of(context).pop(true),
    );
  }

  // ─── HATA EKRANI ───────────────────────────────────────────────

  Widget _buildErrorView() {
    return BulkUploadErrorView(
      errorMessage: _controller.errorMessage,
      onRetry: () {
        _controller.reset();
        _pickFile();
      },
    );
  }

  Future<void> _editProduct(int index, Product product) async {
    final result = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      builder:
          (_) => BulkProductEditSheet(
            product: product,
            categories: widget.categories,
          ),
    );
    if (result != null) {
      _controller.updateProduct(index, result);
    }
  }

  // ─── ALT BUTONLAR ──────────────────────────────────────────────

  Widget _buildBottomActions() {
    final products = _controller.products;
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
            onPressed: products.isNotEmpty ? _save : null,
            icon: const Icon(Icons.check_rounded, size: 18),
            label: Text(
              '${products.length} Ürünü Ekle',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
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
      builder:
          (_) => SafeArea(
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
                  leading: const Icon(
                    Icons.delete_sweep_rounded,
                    color: AppColors.error,
                  ),
                  title: const Text('Tümünü listeden kaldır'),
                  onTap: () {
                    Navigator.pop(context);
                    _controller.clearAllProducts();
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
          files: [XFile.fromData(bytes, mimeType: 'text/csv', name: fileName)],
          subject: 'Vixrex ürün CSV şablonu',
          text:
              'Ürün Adı, Fiyat, Açıklama, Kategori, Stok Durumu sütunlarını doldurun.',
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

  void _openXmlUpload() {
    if (widget.storeId.isEmpty || widget.editToken.isEmpty) {
      _showMessage('Önce vitrininizi yayınlayın.');
      return;
    }
    XmlUploadDialog.show(
      context: context,
      storeId: widget.storeId,
      editToken: widget.editToken,
      onUploaded: () {
        if (mounted) setState(() {});
      },
    );
  }
}

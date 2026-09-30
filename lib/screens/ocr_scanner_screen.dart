import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:vixrex/controllers/ocr_controller.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/widgets/common/app_card.dart';
import 'package:vixrex/widgets/common/app_screen_scaffold.dart';
import 'package:vixrex/widgets/ocr/ocr_scanner_widget.dart';
import 'package:vixrex/widgets/ocr/ocr_result_list.dart';

/// OCR tarama ekranı.
class OcrScannerScreen extends StatefulWidget {
  final OcrController ocrController;

  const OcrScannerScreen({super.key, required this.ocrController});

  @override
  State<OcrScannerScreen> createState() => _OcrScannerScreenState();
}

class _OcrScannerScreenState extends State<OcrScannerScreen> {
  bool _allowPop = false;
  bool _leaving = false;
  bool get _busy =>
      widget.ocrController.isSaving ||
      widget.ocrController.isProcessing ||
      widget.ocrController.isPublishing;
  @override
  void initState() {
    super.initState();
    widget.ocrController.addListener(_onStateChanged);
    if (widget.ocrController.scanMode == 'invoice') {
      widget.ocrController.loadInvoiceHistory();
    }
  }

  @override
  void dispose() {
    widget.ocrController.removeListener(_onStateChanged);
    // Controller'i olusturan taraf dispose etmeli
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.ocrController.scanMode != 'invoice' || _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _leave();
      },
      child: AppScreenScaffold(
        title:
            widget.ocrController.scanMode == 'invoice'
                ? 'Faturadan Ürün Çıkar'
                : 'Fotoğraftan Ürün Çıkar',
        actions: [
          if (widget.ocrController.scanMode == 'invoice')
            TextButton(
              onPressed: _busy ? null : _showHistory,
              child: const Text('Faturalarım'),
            ),
          if (widget.ocrController.hasResult)
            TextButton(
              onPressed: _busy ? null : _saveProducts,
              child: const Text(
                'Kaydet',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
        ],
        padding: EdgeInsets.zero,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tarama Modu Seçici
              if (!widget.ocrController.hasResult) ...[
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment<String>(
                      value: 'receipt',
                      label: Text('Fiş'),
                      icon: Icon(Icons.receipt_long_rounded),
                    ),
                    ButtonSegment<String>(
                      value: 'invoice',
                      label: Text('Fatura'),
                      icon: Icon(Icons.description_outlined),
                    ),
                    ButtonSegment<String>(
                      value: 'shelf_label',
                      label: Text('Raf/Etiket'),
                      icon: Icon(Icons.label_outline_rounded),
                    ),
                  ],
                  selected: {widget.ocrController.scanMode},
                  onSelectionChanged:
                      _busy
                          ? null
                          : (Set<String> newSelection) {
                            setState(() {
                              widget.ocrController.scanMode =
                                  newSelection.first;
                              if (newSelection.first == 'invoice') {
                                widget.ocrController.loadInvoiceHistory();
                              }
                            });
                          },
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: AppColors.primary,
                    selectedForegroundColor: Colors.white,
                    backgroundColor: AppColors.surface,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Tarama widget'ı
              if (!widget.ocrController.hasResult)
                OcrScannerWidget(
                  onImageSelected: _analyzeImage,
                  scanMode: widget.ocrController.scanMode,
                ),

              // Hata mesajı
              if (widget.ocrController.errorMessage != null)
                _buildErrorMessage(),

              // Yükleme göstergesi
              if (widget.ocrController.isProcessing) _buildProgressIndicator(),

              // Fatura taslakları sunucuya yazıldıktan sonraki özet ve yayın
              if (widget.ocrController.faturaKaydiSonucu != null)
                _buildFaturaKaydiBolumu(),

              // Sonuç listesi
              if (widget.ocrController.hasResult) _buildResultSection(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _leave() async {
    if (_busy || _leaving) return;
    _leaving = true;
    final saved = await widget.ocrController.persistInvoiceState();
    if (!mounted || !saved) {
      _leaving = false;
      return;
    }
    setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.of(context).pop();
    _leaving = false;
  }

  Future<void> _showHistory() async {
    await widget.ocrController.loadInvoiceHistory();
    if (!mounted) return;
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder:
          (ctx) => SafeArea(
            child:
                widget.ocrController.invoiceHistory.isEmpty
                    ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Henüz kaydedilmiş fatura yok.'),
                    )
                    : ListView(
                      shrinkWrap: true,
                      children: [
                        for (final item in widget.ocrController.invoiceHistory)
                          ListTile(
                            title: Text(
                              (item['tedarikci'] ?? 'Fatura').toString(),
                            ),
                            subtitle: Text(
                              '${item['satirSayisi'] ?? 0} ürün • ${item['olusturma'] ?? ''}',
                            ),
                            onTap:
                                () => Navigator.of(
                                  ctx,
                                ).pop((item['islemKimligi'] ?? '').toString()),
                          ),
                      ],
                    ),
          ),
    );
    if (selected != null && selected.isNotEmpty && mounted) {
      await widget.ocrController.resumeInvoice(selected);
    }
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppColors.radius12),
        border: Border.all(color: AppColors.error),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.ocrController.errorMessage!,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: widget.ocrController.clearError,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Ürünler analiz ediliyor...',
            style: TextStyle(color: AppColors.mutedText),
          ),
        ],
      ),
    );
  }

  Widget _buildFaturaKaydiBolumu() {
    final kayit = widget.ocrController.faturaKaydiSonucu!;
    final yayin = widget.ocrController.faturaYayinSonucu;
    final bekleyen = kayit.yayinlanabilirTaslakIdleri.length;
    final yayinlaniyor = widget.ocrController.isPublishing;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ürünler kaydedildi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${kayit.taslak + kayit.yayinda} ürün kaydedildi. '
              'Yayınlamadan vitrinde görünmez.',
              style: const TextStyle(color: AppColors.mutedText),
            ),
            if (kayit.hatali > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${kayit.hatali} satır eklenemedi.',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            for (final satir in kayit.satirlar.where(
              (s) => s.durum != 'yayinda' && s.sebep.isNotEmpty,
            ))
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${satir.ad} — ${satir.sebep}',
                  style: const TextStyle(color: AppColors.mutedText),
                ),
              ),
            if (yayin != null) ...[
              const SizedBox(height: 12),
              Text(
                yayin.tuketiciDogrulandi
                    ? '${yayin.yayinda} ürün vitrinde görünüyor, ${yayin.taslak} ürün taslak kaldı.'
                    : 'Yayın kaydı alındı. Tüketici görünümü doğrulanamadı; ${yayin.taslak} ürün taslak kaldı.',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color:
                      yayin.taslak == 0
                          ? AppColors.success
                          : AppColors.darkText,
                ),
              ),
              for (final satir in yayin.satirlar.where(
                (s) => !s.yayinda && s.sebep.isNotEmpty,
              ))
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    satir.sebep,
                    style: const TextStyle(color: AppColors.mutedText),
                  ),
                ),
            ],
            const SizedBox(height: 12),
            if (bekleyen > 0)
              ElevatedButton(
                onPressed:
                    yayinlaniyor || _busy
                        ? null
                        : widget.ocrController.publishSavedInvoiceDrafts,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  yayinlaniyor ? 'Yayınlanıyor…' : '$bekleyen taslağı yayınla',
                ),
              ),
            OutlinedButton(
              onPressed: widget.ocrController.clearFaturaSonucu,
              child: const Text('Kapat'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection() {
    final result = widget.ocrController.result!;
    final approved = result.approvedProducts.length;
    final total = result.products.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Durum özeti
        AppCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$total ürün bulundu',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText,
                ),
              ),
              Text(
                '$approved onaylandı',
                style: TextStyle(
                  color:
                      approved == total
                          ? AppColors.success
                          : AppColors.mutedText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Hızlı aksiyonlar
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.ocrController.approveAll,
                child: const Text('Tümünü Onayla'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: widget.ocrController.rejectAll,
                child: const Text('Tümünü Reddet'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Ürün listesi
        OcrResultList(
          products: result.products,
          invoiceDrafts: result.invoiceDrafts,
          onApprove: widget.ocrController.approveProduct,
          onReject: widget.ocrController.rejectProduct,
          onEdit: _editProduct,
          // Faturadaki adet öneridir; esnaf bu düğmeyle stoğu onaylar.
          onConfirmStock: widget.ocrController.confirmInvoiceStock,
        ),
        const SizedBox(height: 16),
        // Kaydet butonu
        ElevatedButton(
          onPressed: approved > 0 && !_busy ? _saveProducts : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppColors.radius12),
            ),
          ),
          child: Text(
            widget.ocrController.scanMode == 'invoice'
                ? '$approved Taslak Ürünü Hazırla'
                : '$approved Ürünü Vitrine Ekle',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  void _analyzeImage(List<int> imageBytes) {
    widget.ocrController.analyzeImage(Uint8List.fromList(imageBytes));
  }

  Future<void> _editInvoiceProduct(int index) async {
    final product = widget.ocrController.result!.products[index];
    final price = TextEditingController(text: product.price?.toString() ?? '');
    final stock = TextEditingController(text: product.quantity.toString());
    final name = TextEditingController(text: product.name);
    final model = TextEditingController(text: product.sku ?? '');
    final barcode = TextEditingController(text: product.barcode ?? '');
    final brand = TextEditingController(text: product.brand);
    String? category = widget.ocrController.categoryFor(index);
    final categories = widget.ocrController.invoiceCategories;
    if (!categories.any((item) => item.id == category)) category = null;
    final saved = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setDialogState) => AlertDialog(
                  title: const Text('Ürünü kontrol et'),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: price,
                            decoration: const InputDecoration(
                              labelText: 'Satış fiyatı (₺)',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                          TextField(
                            controller: stock,
                            decoration: const InputDecoration(
                              labelText: 'Satış stoğu',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          if (categories.isNotEmpty)
                            DropdownButtonFormField<String>(
                              initialValue: category,
                              decoration: const InputDecoration(
                                labelText: 'Ürün kategorisi',
                              ),
                              items: [
                                for (final item in categories)
                                  DropdownMenuItem(
                                    value: item.id,
                                    child: Text(item.name),
                                  ),
                              ],
                              onChanged:
                                  (value) =>
                                      setDialogState(() => category = value),
                            ),
                          const SizedBox(height: 12),
                          ExpansionTile(
                            title: const Text('Okunan ürün bilgisini düzelt'),
                            children: [
                              TextField(
                                controller: name,
                                decoration: const InputDecoration(
                                  labelText: 'Ürün adı',
                                ),
                              ),
                              TextField(
                                controller: model,
                                decoration: const InputDecoration(
                                  labelText: 'Model kodu',
                                ),
                              ),
                              TextField(
                                controller: barcode,
                                decoration: const InputDecoration(
                                  labelText: 'Barkod',
                                ),
                              ),
                              TextField(
                                controller: brand,
                                decoration: const InputDecoration(
                                  labelText: 'Marka',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('İptal'),
                    ),
                    FilledButton(
                      onPressed: () {
                        final amount = _parseDecimal(price.text);
                        final quantity = int.tryParse(stock.text.trim());
                        if ((price.text.trim().isNotEmpty &&
                                (amount == null || amount <= 0)) ||
                            quantity == null ||
                            quantity < 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Fiyatı ve stoğu kontrol et.'),
                            ),
                          );
                          return;
                        }
                        Navigator.of(ctx).pop(true);
                      },
                      child: const Text('Kaydet'),
                    ),
                  ],
                ),
          ),
    );
    if (saved == true && mounted) {
      final identityChanged =
          name.text.trim() != product.name ||
          model.text.trim() != (product.sku ?? '') ||
          barcode.text.trim() != (product.barcode ?? '') ||
          brand.text.trim() != product.brand;
      final stockChanged = product.quantity != int.parse(stock.text.trim());
      product.price = _parseDecimal(price.text);
      product.quantity = int.parse(stock.text.trim());
      widget.ocrController.updateProduct(
        index,
        product,
        stockChanged: stockChanged,
      );
      if (category != null) {
        widget.ocrController.setInvoiceCategory(index, category!);
      }
      if (identityChanged) {
        await widget.ocrController.correctInvoiceRow(
          index,
          ad: name.text.trim(),
          model: model.text.trim(),
          barkod: barcode.text.trim(),
          marka: brand.text.trim(),
        );
      } else {
        await widget.ocrController.persistInvoiceState();
      }
    }
    for (final controller in [price, stock, name, model, barcode, brand]) {
      controller.dispose();
    }
  }

  void _editProduct(int index) {
    if (_busy) return;
    if (widget.ocrController.result!.products[index].isInvoiceSource) {
      _editInvoiceProduct(index);
      return;
    }
    final product = widget.ocrController.result!.products[index];
    final nameController = TextEditingController(text: product.name);
    final priceController = TextEditingController(
      text: product.price?.toStringAsFixed(2) ?? '',
    );

    final modelController = TextEditingController(text: product.sku ?? '');
    final barcodeController = TextEditingController(
      text: product.barcode ?? '',
    );
    final variantController = TextEditingController(
      text: product.variant ?? '',
    );
    final sizeController = TextEditingController(text: product.size ?? '');
    final quantityController = TextEditingController(
      text: product.documentQuantity?.toString() ?? '',
    );
    final purchaseController = TextEditingController(
      text: product.purchaseUnitPrice?.toStringAsFixed(2) ?? '',
    );
    final lineTotalController = TextEditingController(
      text: product.lineTotal?.toStringAsFixed(2) ?? '',
    );

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text(
              'Ürünü Düzenle',
              style: TextStyle(color: AppColors.darkText),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Ürün Adı',
                        labelStyle: TextStyle(color: AppColors.mutedText),
                      ),
                      style: const TextStyle(color: AppColors.darkText),
                    ),
                    if (product.isInvoiceSource) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: modelController,
                        decoration: const InputDecoration(
                          labelText: 'Model / SKU',
                          labelStyle: TextStyle(color: AppColors.mutedText),
                        ),
                        style: const TextStyle(color: AppColors.darkText),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: barcodeController,
                        decoration: const InputDecoration(
                          labelText: 'Barkod',
                          labelStyle: TextStyle(color: AppColors.mutedText),
                        ),
                        style: const TextStyle(color: AppColors.darkText),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: variantController,
                        decoration: const InputDecoration(
                          labelText: 'Varyant / Renk',
                          labelStyle: TextStyle(color: AppColors.mutedText),
                        ),
                        style: const TextStyle(color: AppColors.darkText),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: sizeController,
                        decoration: const InputDecoration(
                          labelText: 'Beden',
                          labelStyle: TextStyle(color: AppColors.mutedText),
                        ),
                        style: const TextStyle(color: AppColors.darkText),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: quantityController,
                        decoration: const InputDecoration(
                          labelText: 'Adet',
                          labelStyle: TextStyle(color: AppColors.mutedText),
                        ),
                        style: const TextStyle(color: AppColors.darkText),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: purchaseController,
                        decoration: const InputDecoration(
                          labelText: 'Alış fiyatı (faturadaki)',
                          labelStyle: TextStyle(color: AppColors.mutedText),
                        ),
                        style: const TextStyle(color: AppColors.darkText),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: lineTotalController,
                        decoration: const InputDecoration(
                          labelText: 'Satır toplamı',
                          labelStyle: TextStyle(color: AppColors.mutedText),
                        ),
                        style: const TextStyle(color: AppColors.darkText),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceController,
                      decoration: InputDecoration(
                        labelText:
                            product.isInvoiceSource
                                ? 'Satış Fiyatı (₺)'
                                : 'Fiyat (₺)',
                        labelStyle: const TextStyle(color: AppColors.mutedText),
                      ),
                      style: const TextStyle(color: AppColors.darkText),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () {
                  product.name = nameController.text.trim();
                  product.price = _parseDecimal(priceController.text);

                  if (product.isInvoiceSource) {
                    product.sku = _cleanOptional(modelController.text);
                    product.barcode = _cleanOptional(barcodeController.text);
                    product.variant = _cleanOptional(variantController.text);
                    product.size = _cleanOptional(sizeController.text);
                    product.documentQuantity = int.tryParse(
                      quantityController.text.trim(),
                    );
                    if (product.documentQuantity != null) {
                      product.quantity = product.documentQuantity!;
                    }
                    product.purchaseUnitPrice = _parseDecimal(
                      purchaseController.text,
                    );
                    product.lineTotal = _parseDecimal(lineTotalController.text);
                  }

                  widget.ocrController.updateProduct(index, product);
                  Navigator.pop(ctx);
                },
                child: const Text('Kaydet'),
              ),
            ],
          ),
    );
  }

  String? _cleanOptional(String value) {
    final clean = value.trim();
    return clean.isEmpty ? null : clean;
  }

  double? _parseDecimal(String value) {
    var clean = value.trim().replaceAll(RegExp(r'[^0-9,.-]'), '');
    if (clean.isEmpty) return null;
    if (clean.contains(',')) {
      clean = clean.replaceAll('.', '').replaceAll(',', '.');
    }
    return double.tryParse(clean);
  }

  Future<void> _saveProducts() async {
    try {
      await widget.ocrController.saveApprovedProducts();
      if (!mounted) return;

      final error = widget.ocrController.errorMessage;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.error),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.ocrController.scanMode == 'invoice'
                ? 'Taslak ürünler hazırlandı.'
                : 'Ürünler vitrine eklendi!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      if (widget.ocrController.scanMode != 'invoice') {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kaydetme hatası: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

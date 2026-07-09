import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:vixrex/controllers/ocr_controller.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/widgets/ocr/ocr_scanner_widget.dart';
import 'package:vixrex/widgets/ocr/ocr_result_list.dart';

/// OCR tarama ekranı.
class OcrScannerScreen extends StatefulWidget {
  final OcrController ocrController;

  const OcrScannerScreen({
    super.key,
    required this.ocrController,
  });

  @override
  State<OcrScannerScreen> createState() => _OcrScannerScreenState();
}

class _OcrScannerScreenState extends State<OcrScannerScreen> {
  @override
  void initState() {
    super.initState();
    widget.ocrController.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    widget.ocrController.removeListener(_onStateChanged);
    widget.ocrController.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fotoğraftan Ürün Çıkar'),
        actions: [
          if (widget.ocrController.hasResult)
            TextButton(
              onPressed: _saveProducts,
              child: const Text(
                'Kaydet',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
        ],
      ),
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
                    label: Text('Fiş/Fatura Modu'),
                    icon: Icon(Icons.receipt_long_rounded),
                  ),
                  ButtonSegment<String>(
                    value: 'shelf_label',
                    label: Text('Raf/Etiket Modu'),
                    icon: Icon(Icons.label_outline_rounded),
                  ),
                ],
                selected: {widget.ocrController.scanMode},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    widget.ocrController.scanMode = newSelection.first;
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
            if (widget.ocrController.isProcessing)
              _buildProgressIndicator(),

            // Sonuç listesi
            if (widget.ocrController.hasResult)
              _buildResultSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
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

  Widget _buildResultSection() {
    final result = widget.ocrController.result!;
    final approved = result.approvedProducts.length;
    final total = result.products.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Durum özeti
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
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
                  color: approved == total ? AppColors.success : AppColors.mutedText,
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
          onApprove: widget.ocrController.approveProduct,
          onReject: widget.ocrController.rejectProduct,
        ),
        const SizedBox(height: 16),
        // Kaydet butonu
        ElevatedButton(
          onPressed: approved > 0 ? _saveProducts : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            '$approved Ürünü Vitrine Ekle',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  void _analyzeImage(List<int> imageBytes) {
    widget.ocrController.analyzeImage(Uint8List.fromList(imageBytes));
  }

  Future<void> _saveProducts() async {
    try {
      await widget.ocrController.saveApprovedProducts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ürünler vitrine eklendi!'),
            backgroundColor: AppColors.success,
          ),
        );
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

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vixrex/theme/app_colors.dart';

/// OCR tarama widget'ı - kamera/galeri seçimi.
class OcrScannerWidget extends StatelessWidget {
  final Function(Uint8List imageBytes) onImageSelected;
  final String scanMode;

  const OcrScannerWidget({
    super.key,
    required this.onImageSelected,
    this.scanMode = 'receipt',
  });

  @override
  Widget build(BuildContext context) {
    final isShelf = scanMode == 'shelf_label';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(
            isShelf ? Icons.label_outline_rounded : Icons.receipt_long_rounded,
            size: 48,
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          Text(
            isShelf ? 'Raf veya Fiyat Etiketi Çekin' : 'Fotoğraf veya Fatura Çekin',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isShelf
                ? 'Sarı/beyaz etiketler ve ürünler eşleştirilecek'
                : 'Ürünler ve fiyatlar faturadan otomatik tanınacak',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.mutedText,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildButton(
                  icon: Icons.camera_alt_rounded,
                  label: 'Fotoğraf Çek',
                  onTap: () => _pickImage(context, ImageSource.camera),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildButton(
                  icon: Icons.photo_library_rounded,
                  label: 'Galeriden Seç',
                  onTap: () => _pickImage(context, ImageSource.gallery),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        onImageSelected(bytes);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fotoğraf seçilirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

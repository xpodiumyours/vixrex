import 'package:flutter/material.dart';
import 'package:vixrex/theme/app_colors.dart';

typedef OnPickFile = Future<void> Function();
typedef OnDownloadTemplate = Future<void> Function();
typedef OnOpenXmlUpload = void Function();

class BulkUploadInitialView extends StatelessWidget {
  final OnPickFile onPickFile;
  final OnDownloadTemplate onDownloadTemplate;
  final OnOpenXmlUpload onOpenXmlUpload;

  const BulkUploadInitialView({
    super.key,
    required this.onPickFile,
    required this.onDownloadTemplate,
    required this.onOpenXmlUpload,
  });

  @override
  Widget build(BuildContext context) {
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
          'Excel (.xlsx) veya CSV dosyası seçerek\nürünlerinizi toplu olarak ekleyebilirsiniz.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.mutedText),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onPickFile,
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
          onPressed: onDownloadTemplate,
          icon: const Icon(Icons.download_rounded, size: 18),
          label: const Text('Şablon İndir'),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: onOpenXmlUpload,
          icon: const Icon(Icons.link_rounded, size: 18),
          label: const Text('XML ile Yükle'),
        ),
        const SizedBox(height: 20),
        const _BulkUploadFormatInfo(),
      ],
    );
  }
}

class _BulkUploadFormatInfo extends StatelessWidget {
  const _BulkUploadFormatInfo();

  @override
  Widget build(BuildContext context) {
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
          const _FormatRow('Ürün Adı', 'Zorunlu', true),
          const _FormatRow('Fiyat', 'İsteğe bağlı', false),
          const _FormatRow('Açıklama', 'İsteğe bağlı', false),
          const _FormatRow('Kategori', 'İsteğe bağlı, varsayılan: Genel', false),
          const _FormatRow(
            'Stok Durumu',
            'Mevcut / Tükendi / Son birkaç adet',
            false,
          ),
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
}

class _FormatRow extends StatelessWidget {
  final String label;
  final String description;
  final bool required;

  const _FormatRow(this.label, this.description, this.required);

  @override
  Widget build(BuildContext context) {
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
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vixrex/services/product_conversation_logger.dart';
import 'package:vixrex/services/xml_product_upload_service.dart';
import 'package:vixrex/theme/app_colors.dart';

typedef OnXmlProductsUploaded = Future<void> Function();

/// XML ile toplu ürün yükleme dialogu.
/// Kullanıcı XML linkini yapıştırır, sistem Product CORE batch upsert uygular.
class XmlUploadDialog extends StatefulWidget {
  final String storeId;
  final String editToken;
  final String storeSlug;
  final OnXmlProductsUploaded? onUploaded;

  const XmlUploadDialog({
    super.key,
    required this.storeId,
    required this.editToken,
    this.storeSlug = '',
    this.onUploaded,
  });

  static Future<void> show({
    required BuildContext context,
    required String storeId,
    required String editToken,
    String storeSlug = '',
    OnXmlProductsUploaded? onUploaded,
  }) {
    return showDialog(
      context: context,
      builder:
          (_) => XmlUploadDialog(
            storeId: storeId,
            editToken: editToken,
            storeSlug: storeSlug,
            onUploaded: onUploaded,
          ),
    );
  }

  @override
  State<XmlUploadDialog> createState() => _XmlUploadDialogState();
}

class _XmlUploadDialogState extends State<XmlUploadDialog> {
  final _urlController = TextEditingController();
  final _service = XmlProductUploadService();
  bool _isLoading = false;
  String? _errorMessage;
  XmlUploadResult? _result;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _upload() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _errorMessage = 'XML linki girin.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _result = null;
    });

    final result = await _service.fetchAndSave(
      xmlUrl: url,
      storeId: widget.storeId,
      editToken: widget.editToken,
    );
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _result = result;
    });

    final accepted = result.changed + result.unchanged;
    if (result.isSuccess && accepted > 0) {
      if (result.changed > 0) {
        unawaited(
          ProductConversationLogger.log(
            count: result.changed,
            source: 'xml',
            scope: widget.storeSlug.isNotEmpty ? widget.storeSlug : null,
            extra:
                '${result.inserted} eklendi, ${result.updated} güncellendi',
          ),
        );
      }
      await widget.onUploaded?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final completeFailure =
        result != null &&
        result.isSuccess &&
        result.changed == 0 &&
        result.unchanged == 0 &&
        result.errors > 0;
    final visualSuccess = result?.isSuccess == true && !completeFailure;

    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text(
        'XML ile Ürün Yükle',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Tedarikçinizin XML linkini yapıştırın. Ürünler mevcut Product CORE üzerinden eklenir veya eşleşen kayıtlar güncellenir.',
              style: TextStyle(color: AppColors.mutedText, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: 'https://tedarikci.com/feed.xml',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.link),
              ),
              enabled: !_isLoading,
              onSubmitted: (_) => _upload(),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.error, fontSize: 12),
              ),
            ],
            if (result != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      visualSuccess
                          ? Colors.green.withOpacity(0.1)
                          : AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  !result.isSuccess
                      ? result.errorMessage ?? 'XML ürünleri kaydedilemedi.'
                      : completeFailure
                      ? 'Hiçbir ürün kaydedilemedi · ${result.errors} hatalı'
                      : '${result.inserted} eklendi · ${result.updated} güncellendi · ${result.unchanged} değişmedi · ${result.errors} hatalı',
                  style: TextStyle(
                    color: visualSuccess ? Colors.green : AppColors.error,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _upload,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child:
              _isLoading
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Yükle'),
        ),
      ],
    );
  }
}

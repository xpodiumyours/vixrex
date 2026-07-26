import 'package:flutter/material.dart';
import 'package:vixrex/services/xml_product_upload_service.dart';
import 'package:vixrex/theme/app_colors.dart';

/// XML ile toplu ürün yükleme dialogu.
/// Kullanıcı XML linkini yapıştırır, sistem otomatik yükler.
class XmlUploadDialog extends StatefulWidget {
  final String storeId;
  final String editToken;
  final VoidCallback? onUploaded;

  const XmlUploadDialog({
    super.key,
    required this.storeId,
    required this.editToken,
    this.onUploaded,
  });

  static Future<void> show({
    required BuildContext context,
    required String storeId,
    required String editToken,
    VoidCallback? onUploaded,
  }) {
    return showDialog(
      context: context,
      builder: (_) => XmlUploadDialog(
        storeId: storeId,
        editToken: editToken,
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

    setState(() {
      _isLoading = false;
      _result = result;
    });

    if (result.isSuccess && mounted) {
      widget.onUploaded?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
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
              'Tedarikçinizin XML linkini yapıştırın. Sistem otomatik olarak ürünleri vitrine ekleyecek.',
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
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
            if (_result != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _result!.isSuccess
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _result!.isSuccess
                      ? '${_result!.inserted} ürün eklendi. ${_result!.errors > 0 ? '${_result!.errors} hata.' : ''}'
                      : _result!.errorMessage!,
                  style: TextStyle(
                    color: _result!.isSuccess ? Colors.green : Colors.red,
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
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
          ),
          child: _isLoading
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

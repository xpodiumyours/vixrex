import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/theme/vitrin_theme_preset.dart';
import 'package:vitrinx/utils/whatsapp_link_helper.dart';
import 'package:vitrinx/widgets/vitrin_view.dart';

class PreviewScreen extends StatelessWidget {
  final StoreData storeData;
  final List<VitrinGalleryPreviewItem>? previewGalleryItems;

  const PreviewScreen({
    super.key,
    required this.storeData,
    this.previewGalleryItems,
  });

  Future<void> _openWhatsApp(BuildContext context) async {
    final url = WhatsAppLinkHelper.buildGeneralUrl(
      number: storeData.whatsapp,
      storeName: storeData.name,
    );
    if (url == null) {
      _showMessage(context, 'Geçerli bir WhatsApp numarası ekleyin.');
      return;
    }

    try {
      final didLaunch = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!didLaunch && context.mounted) {
        _showMessage(context, 'WhatsApp açılamadı. Lütfen tekrar deneyin.');
      }
    } catch (_) {
      if (context.mounted) {
        _showMessage(context, 'WhatsApp açılamadı. Lütfen tekrar deneyin.');
      }
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = storeData.theme;
    final isDark = vitrinThemePresetFor(theme).isDark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: isDark ? Colors.white10 : const Color(0x0D000000),
            child: BackButton(color: isDark ? Colors.white : Colors.black87),
          ),
        ),
      ),
      body: VitrinView(
        storeData: storeData,
        previewGalleryItems: previewGalleryItems,
      ),
      floatingActionButton:
          storeData.isEsnafMode
              ? FloatingActionButton.extended(
                onPressed: () => _openWhatsApp(context),
                backgroundColor: const Color(0xFF25D366),
                elevation: 10,
                icon: const Icon(Icons.chat, color: Colors.white),
                label: const Text(
                  'WhatsApp Sipariş',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
              : FloatingActionButton(
                onPressed: () {},
                backgroundColor: isDark ? Colors.white : Colors.black,
                child: Icon(
                  Icons.share,
                  color: isDark ? Colors.black : Colors.white,
                ),
              ),
    );
  }
}

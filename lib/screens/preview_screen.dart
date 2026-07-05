import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vixrex/config/business_category_config.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/models/vitrin_gallery_preview_item.dart';
import 'package:vixrex/theme/vitrin_theme_preset.dart';
import 'package:vixrex/utils/whatsapp_link_helper.dart';
import 'package:vixrex/widgets/vitrin_view.dart';

class PreviewScreen extends StatelessWidget {
  final StoreData storeData;
  final List<VitrinGalleryPreviewItem>? previewGalleryItems;
  final bool isDemo;

  const PreviewScreen({
    super.key,
    required this.storeData,
    this.previewGalleryItems,
    this.isDemo = false,
  });

  Future<void> _openWhatsApp(BuildContext context) async {
    final rawNumber = storeData.whatsapp;
    if (!WhatsAppLinkHelper.isValidTurkeyMobile(rawNumber)) {
      _showMessage(
        context,
        'Geçerli bir Türkiye cep telefonu numarası girin. Örn: 0555 123 45 67',
      );
      return;
    }

    if (isDemo) {
      _showMessage(
        context,
        "Müşterileriniz bu butona bastığında '$rawNumber' numaralı WhatsApp hattınıza yönlendirilir.",
      );
    } else {
      final config = BusinessCategoryConfig.fromCategoryLabel(storeData.kategori);
      final url = WhatsAppLinkHelper.buildCategoryGeneralUrl(
        number: rawNumber,
        storeName: storeData.name,
        categoryId: config.id,
      );

      if (url != null) {
        final uri = Uri.tryParse(url);
        if (uri != null) {
          try {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } catch (_) {
            if (context.mounted) {
              _showMessage(context, 'WhatsApp bağlantısı açılamadı.');
            }
          }
        }
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

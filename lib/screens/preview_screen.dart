import 'package:flutter/material.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/theme/vitrin_theme_preset.dart';
import 'package:vitrinx/widgets/vitrin_view.dart';

class PreviewScreen extends StatelessWidget {
  final StoreData storeData;
  final List<VitrinGalleryPreviewItem>? previewGalleryItems;

  const PreviewScreen({
    super.key,
    required this.storeData,
    this.previewGalleryItems,
  });

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
                onPressed:
                    () {}, // Handled inside VitrinView mockup if needed, or here for full screen
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

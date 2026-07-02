import 'package:flutter/material.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/models/vitrin_gallery_preview_item.dart';
import 'package:vitrinx/services/seo_helper.dart';
import 'package:vitrinx/theme/app_colors.dart';
import 'package:vitrinx/theme/vitrin_theme_preset.dart';
import 'package:vitrinx/widgets/vitrin_view/vitrin_content_sections.dart';

class VitrinView extends StatelessWidget {
  final StoreData storeData;
  final bool isEmbedded;
  final bool publicMode;
  final bool compactEmbeddedHeader;
  final List<VitrinGalleryPreviewItem>? previewGalleryItems;
  final String? publicLink;

  const VitrinView({
    super.key,
    required this.storeData,
    this.isEmbedded = false,
    this.publicMode = false,
    this.compactEmbeddedHeader = false,
    this.previewGalleryItems,
    this.publicLink,
  });

  @override
  Widget build(BuildContext context) {
    if (publicMode) {
      injectStoreJsonLd(storeData, publicUrl: publicLink);
    }

    final preset = vitrinThemePresetFor(storeData.theme);
    final content = _buildContent(preset);

    return Theme(
      data: _buildThemeData(preset),
      child:
          publicMode
              ? Material(color: preset.background, child: content)
              : isEmbedded
              ? Material(
                color: preset.background,
                child: SizedBox.expand(child: content),
              )
              : Scaffold(
                backgroundColor: preset.background,
                extendBodyBehindAppBar: true,
                body: content,
              ),
    );
  }

  Widget _buildContent(VitrinThemePreset preset) {
    final galleryItems = _effectiveGalleryItems();

    if (publicMode && !isEmbedded) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return VitrinPublicLayoutSection(
            storeData: storeData,
            preset: preset,
            isEmbedded: isEmbedded,
            publicLink: publicLink,
            galleryItems: galleryItems,
            isDesktop: constraints.maxWidth >= 860,
          );
        },
      );
    }

    return VitrinDefaultContentSection(
      storeData: storeData,
      preset: preset,
      isEmbedded: isEmbedded,
      publicMode: publicMode,
      compactEmbeddedHeader: compactEmbeddedHeader,
      publicLink: publicLink,
      radius: isEmbedded ? AppColors.radius24 : AppColors.radius40,
      galleryItems: galleryItems,
    );
  }

  ThemeData _buildThemeData(VitrinThemePreset preset) {
    return ThemeData(
      useMaterial3: true,
      brightness: preset.isDark ? Brightness.dark : Brightness.light,
      primaryColor: preset.accent,
      scaffoldBackgroundColor: preset.background,
      fontFamily: 'Inter',
      colorScheme: ColorScheme.fromSeed(
        seedColor: preset.accent,
        brightness: preset.isDark ? Brightness.dark : Brightness.light,
      ).copyWith(
        primary: preset.accent,
        onPrimary: preset.buttonText,
        surface: preset.surface,
        onSurface: preset.textPrimary,
        outline: preset.border,
      ),
      textTheme: ThemeData(
        brightness: preset.isDark ? Brightness.dark : Brightness.light,
      ).textTheme.apply(
        bodyColor: preset.textPrimary,
        displayColor: preset.textPrimary,
      ),
    );
  }

  List<VitrinGalleryPreviewItem> _effectiveGalleryItems() {
    final previewItems =
        previewGalleryItems?.where((item) => item.hasImage).take(12).toList();
    if (previewItems != null && previewItems.isNotEmpty) {
      return previewItems;
    }

    return storeData.displayGalleryItems
        .map(VitrinGalleryPreviewItem.fromStoreItem)
        .toList();
  }
}

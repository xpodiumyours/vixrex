import 'package:flutter/material.dart';
import 'package:vixrex/controllers/store_editor_controller.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/widgets/editor/marketplace_links_section.dart';

class FormMarketplaceLinks extends StatelessWidget {
  final StoreEditorController controller;
  final List<String> platformOptions;

  const FormMarketplaceLinks({
    super.key,
    required this.controller,
    required this.platformOptions,
  });

  @override
  Widget build(BuildContext context) {
    return MarketplaceLinksSection(
      links: controller.marketplaceLinks,
      customPlatformLinkIds: controller.customPlatformLinkIds,
      platformOptions: platformOptions,
      onAddLink: () => controller.addMarketplaceLink(
        MarketplaceLink(id: DateTime.now().millisecondsSinceEpoch.toString()),
      ),
      onRemoveLink: controller.removeMarketplaceLink,
      onPlatformChanged: (index, value) {
        final link = controller.marketplaceLinks[index];
        if (value == 'Özel...') {
          link.platform = 'Özel...';
          controller.toggleCustomPlatformLinkId(link.id, true);
        } else {
          link.platform = value ?? '';
          controller.toggleCustomPlatformLinkId(link.id, false);
        }
      },
      onUrlChanged: (index, value) => controller.marketplaceLinks[index].url = value,
      onCustomPlatformChanged: (index, value) =>
          controller.marketplaceLinks[index].platform = value.trim(),
      onSubtitleChanged: (index, value) =>
          controller.marketplaceLinks[index].subtitle = value.trim(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:vixrex/config/business_category_config.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/utils/whatsapp_link_helper.dart';
import 'package:vixrex/widgets/vitrin_view/vitrin_action_button_widgets.dart';
import 'package:vixrex/widgets/vitrin_view/vitrin_view_actions.dart';

List<Widget> buildVitrinVisibleActions({
  required BuildContext context,
  required StoreData storeData,
  required bool publicMode,
  required bool isCompact,
  required String? publicLink,
  required Future<void> Function(BuildContext, String?) onOpenExternalUrl,
  Color? actionColor,
}) {
  final config = BusinessCategoryConfig.fromCategoryLabel(storeData.kategori);
  final ctaLabel = config.ctaLabel;
  final profileActionColor = actionColor ?? AppColors.primary;

  return publicMode
      ? buildPublicActionButtons(
        context: context,
        storeData: storeData,
        isCompact: isCompact,
        publicLink: publicLink,
        profileActionColor: profileActionColor,
        config: config,
        ctaLabel: ctaLabel,
        onOpenExternalUrl: onOpenExternalUrl,
      )
      : buildPreviewActionButtons(
        context: context,
        storeData: storeData,
        isCompact: isCompact,
        profileActionColor: profileActionColor,
        ctaLabel: ctaLabel,
      );
}

List<Widget> buildPreviewActionButtons({
  required BuildContext context,
  required StoreData storeData,
  required bool isCompact,
  required Color profileActionColor,
  required String ctaLabel,
}) {
  final actions = <_PreviewActionSpec>[
    _PreviewActionSpec(
      label: ctaLabel,
      icon: Icons.chat_bubble_rounded,
      message:
          "Müşteriler bu butona bastığında WhatsApp'tan '$ctaLabel' talebi gönderir.",
    ),
    const _PreviewActionSpec(
      label: 'Instagram',
      icon: Icons.camera_rounded,
      message:
          "Müşteriler bu butona bastığında Instagram profilinize yönlendirilir.",
    ),
    if (storeData.website.trim().isNotEmpty)
      const _PreviewActionSpec(
        label: 'Web Sitesi',
        icon: Icons.language_rounded,
        message:
            "Müşteriler bu butona bastığında web sitenize yönlendirilir.",
      ),
    const _PreviewActionSpec(
      label: 'Yol Tarifi',
      icon: Icons.location_on_rounded,
      message:
          "Müşteriler bu butona bastığında Google Haritalar'dan yol tarifi alır.",
    ),
    if (storeData.googleBusinessLink.trim().isNotEmpty)
      const _PreviewActionSpec(
        label: 'Google\'da Yorum Yap',
        icon: Icons.star_rate_rounded,
        message:
            "Müşteriler bu butona bastığında Google yorum sayfanıza yönlendirilir.",
      ),
  ];

  return actions
      .map(
        (action) => _buildActionButton(
          label: action.label,
          icon: action.icon,
          color: profileActionColor,
          compact: isCompact,
          onTap: () => _showPreviewActionInfo(context, action.message),
        ),
      )
      .toList();
}

List<Widget> buildPublicActionButtons({
  required BuildContext context,
  required StoreData storeData,
  required bool isCompact,
  required String? publicLink,
  required Color profileActionColor,
  required BusinessCategoryConfig config,
  required String ctaLabel,
  required Future<void> Function(BuildContext, String?) onOpenExternalUrl,
}) {
  final websiteUrl = VitrinViewActions.publicWebsiteActionUrl(
    storeData: storeData,
    publicLink: publicLink,
    publicMode: true,
  );
  final instagramUrl = VitrinViewActions.buildInstagramUrl(storeData.instagram);
  final reviewUrl = VitrinViewActions.normalizeExternalUrl(
    storeData.googleBusinessLink,
  );
  final mapsUrl = VitrinViewActions.buildMapsUrl(storeData, storeData.address);

  final buttons = <Widget?>[
    WhatsAppLinkHelper.isValidTurkeyMobile(storeData.whatsapp)
        ? _buildActionButton(
          label: ctaLabel,
          icon: Icons.chat_bubble_rounded,
          color: profileActionColor,
          compact: isCompact,
          emphasis: true,
          onTap: () {
            final url = WhatsAppLinkHelper.buildCategoryGeneralUrl(
              number: storeData.whatsapp,
              storeName: storeData.name,
              categoryId: config.id,
            );
            if (url != null) {
              onOpenExternalUrl(context, url);
            }
          },
        )
        : null,
    storeData.instagram.trim().isNotEmpty && instagramUrl.isNotEmpty
        ? _buildActionButton(
          label: 'Instagram',
          icon: Icons.camera_rounded,
          color: profileActionColor,
          compact: isCompact,
          onTap: () => onOpenExternalUrl(context, instagramUrl),
        )
        : null,
    websiteUrl.isNotEmpty
        ? _buildActionButton(
          label: 'Web Sitesi',
          icon: Icons.language_rounded,
          color: profileActionColor,
          compact: isCompact,
          onTap: () => onOpenExternalUrl(context, websiteUrl),
        )
        : null,
    reviewUrl.isNotEmpty
        ? _buildActionButton(
          label: 'Google\'da Yorum Yap',
          icon: Icons.star_rate_rounded,
          color: profileActionColor,
          compact: isCompact,
          onTap: () => onOpenExternalUrl(context, reviewUrl),
        )
        : null,
    (storeData.address.trim().isNotEmpty ||
            (storeData.latitude != null && storeData.longitude != null))
        ? _buildActionButton(
          label: 'Yol Tarifi',
          icon: Icons.location_on_rounded,
          color: profileActionColor,
          compact: isCompact,
          onTap: () => onOpenExternalUrl(context, mapsUrl),
        )
        : null,
  ];

  return buttons.whereType<Widget>().toList();
}

Widget _buildActionButton({
  required String label,
  required IconData icon,
  required Color color,
  required bool compact,
  required VoidCallback onTap,
  bool emphasis = false,
}) {
  return VitrinActionIconButton(
    label: label,
    icon: icon,
    color: color,
    compact: compact,
    emphasis: emphasis,
    onTap: onTap,
  );
}

void _showPreviewActionInfo(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
}

class _PreviewActionSpec {
  final String label;
  final IconData icon;
  final String message;

  const _PreviewActionSpec({
    required this.label,
    required this.icon,
    required this.message,
  });
}

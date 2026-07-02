import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/theme/vitrin_theme_preset.dart';
import 'package:vitrinx/utils/whatsapp_link_helper.dart';
import 'package:vitrinx/widgets/vitrin_view/vitrin_view_content.dart';

class VitrinViewActions {
  static bool hasVCardData(StoreData storeData) {
    if (storeData.name.trim().isEmpty) return false;
    return WhatsAppLinkHelper.isValidTurkeyMobile(storeData.whatsapp) ||
        storeData.instagram.trim().isNotEmpty ||
        storeData.website.trim().isNotEmpty ||
        storeData.address.trim().isNotEmpty;
  }

  static Future<void> copyVCardToClipboard(
    BuildContext context,
    StoreData storeData,
  ) async {
    await Clipboard.setData(
      ClipboardData(text: VitrinViewContent.buildVCardContactText(storeData)),
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'İletişim bilgileri kopyalandı.',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  static Future<void> downloadVCard(
    BuildContext context,
    StoreData storeData,
  ) async {
    final uri = Uri.dataFromString(
      VitrinViewContent.buildVCardFileContent(storeData),
      mimeType: 'text/vcard',
      parameters: {'charset': 'utf-8'},
    );

    try {
      final didLaunch = await launchUrl(uri, mode: LaunchMode.platformDefault);
      if (!didLaunch && context.mounted) {
        await copyVCardToClipboard(context, storeData);
      }
    } catch (_) {
      if (context.mounted) {
        await copyVCardToClipboard(context, storeData);
      }
    }
  }

  static IconData getPlatformIcon(String platform) {
    final p = platform.toLowerCase().trim();
    if (p == 'trendyol') return Icons.shopping_bag_rounded;
    if (p == 'hepsiburada') return Icons.shopping_cart_rounded;
    if (p == 'n11') return Icons.store_rounded;
    if (p == 'amazon') return Icons.cloud_done_rounded;
    if (p == 'shopier') return Icons.sell_rounded;
    if (p.contains('çiçeksepeti')) return Icons.local_florist_rounded;
    if (p.contains('instagram')) return Icons.camera_alt_rounded;
    if (p.contains('whatsapp')) return Icons.chat_bubble_rounded;
    if (p.contains('google')) return Icons.verified_rounded;
    if (p.contains('youtube')) return Icons.play_circle_rounded;
    if (p.contains('facebook') || p.contains('meta')) {
      return Icons.people_alt_rounded;
    }
    if (p.contains('tiktok')) return Icons.music_note_rounded;
    if (p.contains('twitter') || p.contains('x.com')) {
      return Icons.alternate_email_rounded;
    }
    if (p.contains('randevu')) return Icons.event_available_rounded;
    if (p.contains('menü') || p.contains('menu') || p.contains('günün')) {
      return Icons.local_dining_rounded;
    }
    if (p.contains('paket') || p.contains('teslimat') || p.contains('servis')) {
      return Icons.delivery_dining_rounded;
    }
    if (p.contains('teknik') || p.contains('onarım') || p.contains('tamir')) {
      return Icons.construction_rounded;
    }
    if (p.contains('hizmet') || p.contains('bakım')) return Icons.spa_rounded;
    if (p.contains('katalog') || p.contains('catalog') || p.contains('ürün')) {
      return Icons.auto_stories_rounded;
    }
    if (p.contains('konum') || p.contains('adres') || p.contains('harita')) {
      return Icons.location_on_rounded;
    }
    if (p.contains('web') || p.contains('site')) return Icons.language_rounded;
    if (p.contains('telefon') || p.contains('ara') || p.contains('call')) {
      return Icons.phone_rounded;
    }
    if (p.contains('e-posta') || p.contains('mail') || p.contains('e‑posta')) {
      return Icons.email_rounded;
    }
    return Icons.link_rounded;
  }

  static Future<void> openExternalUrl(BuildContext context, String? url) async {
    final trimmed = (url ?? '').trim();
    if (trimmed.isEmpty) return;

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return;

    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') return;

    try {
      final didLaunch = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!didLaunch && context.mounted) {
        _showLinkError(context);
      }
    } catch (_) {
      if (context.mounted) {
        _showLinkError(context);
      }
    }
  }

  static String normalizeExternalUrl(String value) {
    final text = value.trim();
    if (text.isEmpty) return '';

    final uri = Uri.tryParse(text);
    if (uri == null) return '';

    if (uri.hasScheme) {
      final scheme = uri.scheme.toLowerCase();
      if (scheme == 'http' || scheme == 'https') {
        return text;
      }
      return '';
    }

    if (!text.contains('.')) return '';
    return 'https://$text';
  }

  static String buildInstagramUrl(String value) {
    final text = value.trim();
    if (text.contains('instagram.com')) return normalizeExternalUrl(text);

    final username = text.replaceFirst('@', '').replaceAll('/', '').trim();
    return 'https://instagram.com/$username';
  }

  static String buildMapsUrl(StoreData storeData, String address) {
    if (storeData.latitude != null && storeData.longitude != null) {
      return Uri.https('www.google.com', '/maps/dir/', {
        'api': '1',
        'destination': '${storeData.latitude},${storeData.longitude}',
      }).toString();
    }
    return Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': address.trim(),
    }).toString();
  }

  static Future<void> shareVitrin(
    BuildContext context, {
    required StoreData storeData,
    required String shareUrl,
    required VitrinThemePreset preset,
  }) async {
    final renderBox = context.findRenderObject() as RenderBox?;
    final shareOrigin =
        renderBox == null
            ? null
            : renderBox.localToGlobal(Offset.zero) & renderBox.size;
    final storeName = storeData.name.trim();
    final shareText =
        storeName.isEmpty
            ? 'VitrinX vitrini\n$shareUrl'
            : '$storeName vitrini\n$shareUrl';

    try {
      final result = await SharePlus.instance.share(
        ShareParams(
          text: shareText,
          title: storeName.isEmpty ? 'VitrinX' : storeName,
          sharePositionOrigin: shareOrigin,
        ),
      );
      if (result.status != ShareResultStatus.unavailable) return;
    } catch (_) {
      // Paylaşım desteklenmiyorsa kopyalama yedeğine düşer.
    }

    await Clipboard.setData(ClipboardData(text: shareUrl));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Paylaşım desteklenmedi, bağlantı kopyalandı.'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: preset.accent,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  static String publicWebsiteActionUrl({
    required StoreData storeData,
    required String? publicLink,
    required bool publicMode,
  }) {
    final normalizedPublicLink = normalizeExternalUrl(publicLink?.trim() ?? '');
    if (publicMode && normalizedPublicLink.isNotEmpty) {
      return normalizedPublicLink;
    }
    return normalizeExternalUrl(storeData.website);
  }

  static bool hasVisibleActions(
    StoreData storeData, {
    required bool publicMode,
    required String? publicLink,
  }) {
    if (!publicMode) return true;

    return WhatsAppLinkHelper.isValidTurkeyMobile(storeData.whatsapp) ||
        storeData.instagram.trim().isNotEmpty ||
        publicWebsiteActionUrl(
          storeData: storeData,
          publicLink: publicLink,
          publicMode: publicMode,
        ).isNotEmpty ||
        storeData.googleBusinessLink.trim().isNotEmpty ||
        storeData.address.trim().isNotEmpty ||
        (storeData.latitude != null && storeData.longitude != null);
  }

  static void _showLinkError(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          content: Text('Bağlantı açılamadı. Lütfen tekrar deneyin.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

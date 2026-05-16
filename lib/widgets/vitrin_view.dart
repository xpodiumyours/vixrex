import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/theme/vitrin_theme_preset.dart';
import 'package:vitrinx/widgets/status_chip.dart';

class VitrinView extends StatelessWidget {
  final StoreData storeData;
  final bool isEmbedded;
  final bool publicMode;

  const VitrinView({
    super.key,
    required this.storeData,
    this.isEmbedded = false,
    this.publicMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final preset = vitrinThemePresetFor(storeData.theme);
    final themeData = _getThemeData(preset);
    final radius = isEmbedded ? 24.0 : 40.0;
    final children = <Widget>[
      _buildModernHeader(preset, radius),
      SizedBox(height: isEmbedded ? 16 : 26),
      if (_hasVisibleActions()) ...[
        _buildPremiumActionButtons(radius),
        SizedBox(height: isEmbedded ? 16 : 30),
      ],
      if (publicMode && storeData.description.trim().isNotEmpty) ...[
        _buildAboutCard(preset),
        SizedBox(height: isEmbedded ? 16 : 30),
      ] else if (!publicMode) ...[
        _buildProfessionalBio(preset),
        SizedBox(height: isEmbedded ? 16 : 48),
      ],
      _buildModernLinkHub(preset, radius),
      SizedBox(
        height:
            isEmbedded
                ? 18
                : publicMode
                ? 32
                : 64,
      ),
      if (!publicMode) ...[
        _buildPremiumIdentityCard(context, preset, radius),
        SizedBox(height: isEmbedded ? 18 : 64),
      ],
      _buildModernFooter(preset),
      SizedBox(
        height:
            isEmbedded
                ? 36
                : publicMode
                ? 48
                : 120,
      ),
    ];

    final content =
        isEmbedded
            ? ListView(
              padding: EdgeInsets.zero,
              physics: const ClampingScrollPhysics(),
              children: children,
            )
            : publicMode
            ? Column(children: children)
            : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(children: children),
            );

    return Theme(
      data: themeData,
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

  ThemeData _getThemeData(VitrinThemePreset preset) {
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

  Widget _buildModernHeader(VitrinThemePreset preset, double radius) {
    final headerHeight =
        isEmbedded
            ? 150.0
            : publicMode
            ? 218.0
            : 260.0;
    final topPadding =
        isEmbedded
            ? 28.0
            : publicMode
            ? 42.0
            : 80.0;
    final avatarRadius =
        isEmbedded
            ? 32.0
            : publicMode
            ? 42.0
            : 54.0;
    final avatarIconSize =
        isEmbedded
            ? 30.0
            : publicMode
            ? 38.0
            : 48.0;
    final titleSize =
        isEmbedded
            ? 22.0
            : publicMode
            ? 28.0
            : 34.0;

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Container(
          height: headerHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                preset.accent.withValues(alpha: preset.isDark ? 0.24 : 0.16),
                preset.surfaceSoft.withValues(
                  alpha: preset.isDark ? 0.32 : 0.8,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(24, topPadding, 24, 0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: preset.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 40,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: avatarRadius,
                  backgroundColor: preset.accent.withValues(alpha: 0.14),
                  child: Icon(
                    Icons.business_center_rounded,
                    size: avatarIconSize,
                    color: preset.accent,
                  ),
                ),
              ),
              SizedBox(height: isEmbedded ? 14 : 24),
              Text(
                storeData.name.isEmpty ? 'Dijital Vitrin' : storeData.name,
                maxLines: publicMode ? 2 : null,
                overflow: publicMode ? TextOverflow.ellipsis : null,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w900,
                  color: preset.textPrimary,
                  letterSpacing: -1.2,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isEmbedded ? 8 : 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: preset.accent.withValues(
                    alpha: preset.isDark ? 0.18 : 0.12,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: preset.accent.withValues(alpha: 0.18),
                  ),
                ),
                child: Text(
                  storeData.businessType.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    color: preset.accent,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.8,
                  ),
                ),
              ),
              SizedBox(height: isEmbedded ? 12 : 20),
              StatusChip(status: storeData.status),
              if (!publicMode && storeData.description.isNotEmpty) ...[
                SizedBox(height: isEmbedded ? 10 : 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    storeData.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: preset.textSecondary,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumActionButtons(double radius) {
    final isCompact = isEmbedded;
    final actions = _buildVisibleActions(radius, isCompact);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 18 : 24),
      child: Wrap(
        spacing: isCompact ? 8 : 12,
        runSpacing: isCompact ? 8 : 12,
        alignment: WrapAlignment.center,
        children: actions,
      ),
    );
  }

  bool _hasVisibleActions() {
    if (!publicMode) return true;

    return storeData.whatsapp.trim().isNotEmpty ||
        storeData.instagram.trim().isNotEmpty ||
        storeData.website.trim().isNotEmpty ||
        storeData.address.trim().isNotEmpty;
  }

  List<Widget> _buildVisibleActions(double radius, bool isCompact) {
    if (!publicMode) {
      return [
        _ActionIconBtn(
          label: 'WhatsApp',
          icon: Icons.chat_bubble_rounded,
          color: const Color(0xFF25D366),
          radius: radius,
          compact: isCompact,
        ),
        _ActionIconBtn(
          label: 'Instagram',
          icon: Icons.camera_rounded,
          color: const Color(0xFFE1306C),
          radius: radius,
          compact: isCompact,
        ),
        if (storeData.website.isNotEmpty)
          _ActionIconBtn(
            label: 'Web',
            icon: Icons.language_rounded,
            color: Colors.blue.shade600,
            radius: radius,
            compact: isCompact,
          ),
        _ActionIconBtn(
          label: 'Adres',
          icon: Icons.location_on_rounded,
          color: Colors.red.shade500,
          radius: radius,
          compact: isCompact,
        ),
      ];
    }

    return [
      if (storeData.whatsapp.trim().isNotEmpty)
        _ActionIconBtn(
          label: 'WhatsApp',
          icon: Icons.chat_bubble_rounded,
          color: const Color(0xFF25D366),
          radius: radius,
          compact: isCompact,
          onTap: () => _openExternalUrl(_buildWhatsAppUrl(storeData.whatsapp)),
        ),
      if (storeData.instagram.trim().isNotEmpty)
        _ActionIconBtn(
          label: 'Instagram',
          icon: Icons.camera_rounded,
          color: const Color(0xFFE1306C),
          radius: radius,
          compact: isCompact,
          onTap:
              () => _openExternalUrl(_buildInstagramUrl(storeData.instagram)),
        ),
      if (storeData.website.trim().isNotEmpty)
        _ActionIconBtn(
          label: 'Web',
          icon: Icons.language_rounded,
          color: Colors.blue.shade600,
          radius: radius,
          compact: isCompact,
          onTap:
              () => _openExternalUrl(_normalizeExternalUrl(storeData.website)),
        ),
      if (storeData.address.trim().isNotEmpty)
        _ActionIconBtn(
          label: 'Adres',
          icon: Icons.location_on_rounded,
          color: Colors.red.shade500,
          radius: radius,
          compact: isCompact,
          onTap: () => _openExternalUrl(_buildMapsUrl(storeData.address)),
        ),
    ];
  }

  Widget _buildAboutCard(VitrinThemePreset preset) {
    final isCompact = isEmbedded;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 18 : 24),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isCompact ? 16 : 18),
        decoration: BoxDecoration(
          color: preset.surface,
          borderRadius: BorderRadius.circular(isCompact ? 16 : 20),
          border: Border.all(color: preset.border, width: isCompact ? 1 : 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: preset.isDark ? 0.1 : 0.04),
              blurRadius: isCompact ? 12 : 20,
              offset: Offset(0, isCompact ? 3 : 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hakkımızda',
              style: TextStyle(
                color: preset.textPrimary,
                fontSize: isCompact ? 14 : 16,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              storeData.description.trim(),
              style: TextStyle(
                color: preset.textSecondary,
                fontSize: isCompact ? 12 : 13,
                fontWeight: FontWeight.w500,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalBio(VitrinThemePreset preset) {
    final isCompact = isEmbedded;
    final bioText =
        storeData.corporateBio.trim().isNotEmpty
            ? storeData.corporateBio.trim()
            : storeData.description.trim().isNotEmpty
            ? storeData.description.trim()
            : 'Tüm bilgileriniz, linkleriniz ve iletişim kanallarınız tek yerde.';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 28 : 40),
      child: Column(
        children: [
          Icon(
            Icons.format_quote_rounded,
            color: preset.accent.withValues(alpha: preset.isDark ? 0.28 : 0.18),
            size: isCompact ? 38 : 54,
          ),
          SizedBox(height: isCompact ? 4 : 8),
          Text(
            bioText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isCompact ? 13 : 16,
              height: isCompact ? 1.55 : 1.8,
              color: preset.textSecondary,
              fontStyle: FontStyle.italic,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernLinkHub(VitrinThemePreset preset, double radius) {
    final isCompact = isEmbedded;
    final visibleMarketplaceLinks =
        publicMode
            ? storeData.marketplaceLinks
                .where(
                  (link) =>
                      link.platform.trim().isNotEmpty &&
                      link.url.trim().isNotEmpty,
                )
                .toList()
            : storeData.marketplaceLinks;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 18 : 24),
      child: Column(
        children: [
          ...visibleMarketplaceLinks.map(
            (link) => _ModernLinkItem(
              icon: _getPlatformIcon(link.platform),
              title: link.platform,
              subtitle: link.url.isEmpty ? 'Mağazamızı ziyaret edin' : link.url,
              color: _getPlatformColor(link.platform),
              radius: radius,
              compact: isCompact,
              preset: preset,
              onTap:
                  publicMode
                      ? () => _openExternalUrl(_normalizeExternalUrl(link.url))
                      : null,
            ),
          ),

          if (!publicMode && storeData.marketplaceLinks.isEmpty)
            _ModernLinkItem(
              icon: Icons.auto_stories_rounded,
              title: 'Dijital Katalog',
              subtitle: 'Geniş ürün ve hizmet yelpazesi',
              color: Colors.blueGrey,
              radius: radius,
              compact: isCompact,
              preset: preset,
            ),

          if (!publicMode) ...[
            _ModernLinkItem(
              icon: Icons.verified_rounded,
              title: 'Referanslarımız',
              subtitle: 'Güçlü çözüm ortaklıklarımız',
              color: Colors.indigo.shade400,
              radius: radius,
              compact: isCompact,
              preset: preset,
            ),
            _ModernLinkItem(
              icon: Icons.qr_code_rounded,
              title: 'vCard Kaydet',
              subtitle: 'Hızlı iletişim için rehbere ekle',
              color: Colors.teal.shade500,
              radius: radius,
              compact: isCompact,
              preset: preset,
            ),
          ],
        ],
      ),
    );
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform) {
      case 'Trendyol':
        return Icons.shopping_bag_rounded;
      case 'Hepsiburada':
        return Icons.shopping_cart_rounded;
      case 'N11':
        return Icons.store_rounded;
      case 'Amazon':
        return Icons.cloud_done_rounded;
      case 'Shopier':
        return Icons.sell_rounded;
      default:
        return Icons.link_rounded;
    }
  }

  Color _getPlatformColor(String platform) {
    switch (platform) {
      case 'Trendyol':
        return const Color(0xFFF27A1A);
      case 'Hepsiburada':
        return const Color(0xFFFF6000);
      case 'N11':
        return const Color(0xFFE11D48);
      case 'Amazon':
        return const Color(0xFF232F3E);
      case 'Shopier':
        return const Color(0xFFDB2777);
      default:
        return const Color(0xFF4B5563);
    }
  }

  Widget _buildPremiumIdentityCard(
    BuildContext context,
    VitrinThemePreset preset,
    double radius,
  ) {
    final isCompact = isEmbedded;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 18 : 24),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isCompact ? 18 : 28),
        decoration: BoxDecoration(
          color: preset.qrBackground,
          borderRadius: BorderRadius.circular(isCompact ? 20 : radius),
          border: Border.all(
            color: preset.qrForeground.withValues(alpha: 0.14),
            width: isCompact ? 1.5 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: isCompact ? 24 : 40,
              offset: Offset(0, isCompact ? 8 : 15),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isCompact ? 10 : 14),
                  decoration: BoxDecoration(
                    color: preset.qrForeground.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
                  ),
                  child: Icon(
                    Icons.qr_code_2_rounded,
                    size: isCompact ? 34 : 54,
                    color: preset.qrForeground,
                  ),
                ),
                SizedBox(width: isCompact ? 14 : 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        storeData.name.isEmpty
                            ? 'VitrinX Kart'
                            : storeData.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: isCompact ? 16 : 20,
                          color: preset.qrForeground,
                          letterSpacing: -0.8,
                        ),
                      ),
                      SizedBox(height: isCompact ? 4 : 6),
                      Text(
                        'TÜM BİLGİLERİM TEK QR İLE BURADA',
                        style: TextStyle(
                          fontSize: isCompact ? 8 : 10,
                          color: preset.qrForeground.withValues(alpha: 0.72),
                          fontWeight: FontWeight.w900,
                          letterSpacing: isCompact ? 0.8 : 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: isCompact ? 18 : 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: Icon(Icons.share_rounded, size: isCompact ? 16 : 20),
                label: Text(
                  'PROFİLİ PAYLAŞ',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: isCompact ? 11 : 13,
                    letterSpacing: isCompact ? 1 : 1.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: preset.accent,
                  foregroundColor: preset.buttonText,
                  padding: EdgeInsets.symmetric(vertical: isCompact ? 12 : 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernFooter(VitrinThemePreset preset) {
    return Column(
      children: [
        Text(
          publicMode
              ? 'Bu vitrin VitrinX ile oluşturuldu'
              : 'vitrinx.app/${storeData.name.toLowerCase().replaceAll(' ', '-')}',
          style: TextStyle(
            fontSize: publicMode ? 12 : 14,
            fontWeight: FontWeight.w800,
            color: preset.textSecondary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 48),
        Container(height: 1, width: 50, color: preset.border),
        const SizedBox(height: 24),
        if (!publicMode)
          Text(
            'BU BİR VITRINX DİJİTAL KİMLİĞİDİR',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: preset.textSecondary.withValues(alpha: 0.72),
              letterSpacing: 4,
            ),
          ),
      ],
    );
  }

  Future<void> _openExternalUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (error) {
      debugPrint('External link open error: $error');
    }
  }

  String _normalizeExternalUrl(String value) {
    final text = value.trim();
    if (text.startsWith('http://') || text.startsWith('https://')) {
      return text;
    }

    return 'https://$text';
  }

  String _buildInstagramUrl(String value) {
    final text = value.trim();
    if (text.contains('instagram.com')) return _normalizeExternalUrl(text);

    final username = text.replaceFirst('@', '').replaceAll('/', '').trim();
    return 'https://instagram.com/$username';
  }

  String _buildWhatsAppUrl(String value) {
    var number = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (number.startsWith('0') && number.length == 11) {
      number = '90${number.substring(1)}';
    } else if (number.startsWith('5') && number.length == 10) {
      number = '90$number';
    }

    return 'https://wa.me/$number';
  }

  String _buildMapsUrl(String address) {
    return Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': address.trim(),
    }).toString();
  }
}

class _ActionIconBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final double radius;
  final bool compact;
  final VoidCallback? onTap;

  const _ActionIconBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.radius,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final buttonRadius = compact ? 12.0 : 16.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.09),
        borderRadius: BorderRadius.circular(buttonRadius),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.22 : 0.12),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(buttonRadius),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 20,
              vertical: compact ? 9 : 14,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: compact ? 15 : 20, color: color),
                SizedBox(width: compact ? 7 : 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: compact ? 11 : 13,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModernLinkItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final double radius;
  final bool compact;
  final VitrinThemePreset preset;
  final VoidCallback? onTap;

  const _ModernLinkItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.radius,
    required this.preset,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        preset.isDark && color.computeLuminance() < 0.35
            ? preset.accent
            : color;

    return Container(
      margin: EdgeInsets.only(bottom: compact ? 10 : 16),
      decoration: BoxDecoration(
        color: preset.surface,
        borderRadius: BorderRadius.circular(compact ? 16 : 20),
        border: Border.all(color: preset.border, width: compact ? 1 : 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: preset.isDark ? 0.12 : 0.04),
            blurRadius: compact ? 12 : 20,
            offset: Offset(0, compact ? 3 : 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(compact ? 16 : 20),
          child: Padding(
            padding: EdgeInsets.all(compact ? 13 : 18),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(compact ? 9 : 12),
                  decoration: BoxDecoration(
                    color: effectiveColor.withValues(
                      alpha: preset.isDark ? 0.18 : 0.1,
                    ),
                    borderRadius: BorderRadius.circular(compact ? 11 : 14),
                  ),
                  child: Icon(
                    icon,
                    color: effectiveColor,
                    size: compact ? 18 : 22,
                  ),
                ),
                SizedBox(width: compact ? 12 : 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: compact ? 14 : 16,
                          color: preset.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: compact ? 2 : 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: preset.textSecondary,
                          fontSize: compact ? 10.5 : 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: preset.textSecondary.withValues(alpha: 0.75),
                  size: compact ? 11 : 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

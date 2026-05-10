import 'package:flutter/material.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/widgets/status_chip.dart';

class VitrinView extends StatelessWidget {
  final StoreData storeData;
  final bool isEmbedded;

  const VitrinView({
    super.key,
    required this.storeData,
    this.isEmbedded = false,
  });

  // Modern Brand Colors
  static const Color primaryBrandColor = Color(0xFFFF5A1F);

  @override
  Widget build(BuildContext context) {
    final themeData = _getThemeData();
    final radius = isEmbedded ? 24.0 : 40.0;
    final children = <Widget>[
      _buildModernHeader(themeData, radius),
      SizedBox(height: isEmbedded ? 16 : 32),
      _buildPremiumActionButtons(radius),
      SizedBox(height: isEmbedded ? 16 : 48),
      _buildProfessionalBio(themeData),
      SizedBox(height: isEmbedded ? 16 : 48),
      _buildModernLinkHub(radius),
      SizedBox(height: isEmbedded ? 18 : 64),
      _buildPremiumIdentityCard(context, themeData, radius),
      SizedBox(height: isEmbedded ? 18 : 64),
      _buildModernFooter(themeData),
      SizedBox(height: isEmbedded ? 36 : 120),
    ];

    final content =
        isEmbedded
            ? ListView(
              padding: EdgeInsets.zero,
              physics: const ClampingScrollPhysics(),
              children: children,
            )
            : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(children: children),
            );

    return Theme(
      data: themeData,
      child:
          isEmbedded
              ? Material(
                color: themeData.scaffoldBackgroundColor,
                child: SizedBox.expand(child: content),
              )
              : Scaffold(
                backgroundColor: themeData.scaffoldBackgroundColor,
                extendBodyBehindAppBar: true,
                body: content,
              ),
    );
  }

  ThemeData _getThemeData() {
    final isDarkTheme = ['Premium', 'Gece', 'Lüks'].contains(storeData.theme);
    final themeColor = _getThemeColor(storeData.theme);

    return ThemeData(
      useMaterial3: true,
      brightness: isDarkTheme ? Brightness.dark : Brightness.light,
      primaryColor: themeColor,
      scaffoldBackgroundColor:
          isDarkTheme ? const Color(0xFF0F172A) : Colors.white,
      fontFamily: 'Inter',
      colorScheme: ColorScheme.fromSeed(
        seedColor: themeColor,
        brightness: isDarkTheme ? Brightness.dark : Brightness.light,
        primary: themeColor,
      ),
    );
  }

  Color _getThemeColor(String theme) {
    switch (theme) {
      case 'Premium':
        return const Color(0xFF1E293B);
      case 'Zarif':
        return const Color(0xFF9E7C66);
      case 'Doğal':
        return const Color(0xFF15803D);
      case 'Gece':
        return const Color(0xFF0F172A);
      case 'Lüks':
        return const Color(0xFFB45309);
      case 'Sahil':
        return const Color(0xFF0891B2);
      case 'Güneş':
        return const Color(0xFFEA580C);
      default:
        return primaryBrandColor;
    }
  }

  Widget _buildModernHeader(ThemeData themeData, double radius) {
    final isDark = themeData.brightness == Brightness.dark;
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Container(
          height: isEmbedded ? 150 : 260,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                themeData.primaryColor.withValues(alpha: 0.15),
                themeData.primaryColor.withValues(alpha: 0.05),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(24, isEmbedded ? 28 : 80, 24, 0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
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
                  radius: isEmbedded ? 32 : 54,
                  backgroundColor: themeData.primaryColor.withValues(
                    alpha: 0.05,
                  ),
                  child: Icon(
                    Icons.business_center_rounded,
                    size: isEmbedded ? 30 : 48,
                    color: themeData.primaryColor,
                  ),
                ),
              ),
              SizedBox(height: isEmbedded ? 14 : 24),
              Text(
                storeData.name.isEmpty ? 'Dijital Vitrin' : storeData.name,
                style: TextStyle(
                  fontSize: isEmbedded ? 22 : 34,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF111827),
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
                  color: themeData.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  storeData.businessType.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    color: themeData.primaryColor,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.8,
                  ),
                ),
              ),
              SizedBox(height: isEmbedded ? 12 : 20),
              StatusChip(status: storeData.status),
              if (storeData.description.isNotEmpty) ...[
                SizedBox(height: isEmbedded ? 10 : 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    storeData.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white60 : Colors.black54,
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

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 18 : 24),
      child: Wrap(
        spacing: isCompact ? 8 : 12,
        runSpacing: isCompact ? 8 : 12,
        alignment: WrapAlignment.center,
        children: [
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
        ],
      ),
    );
  }

  Widget _buildProfessionalBio(ThemeData themeData) {
    final isDark = themeData.brightness == Brightness.dark;
    final isCompact = isEmbedded;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 28 : 40),
      child: Column(
        children: [
          Icon(
            Icons.format_quote_rounded,
            color: themeData.primaryColor.withValues(alpha: 0.15),
            size: isCompact ? 38 : 54,
          ),
          SizedBox(height: isCompact ? 4 : 8),
          Text(
            storeData.corporateBio.isEmpty
                ? 'Tüm bilgileriniz, linkleriniz ve iletişim kanallarınız tek yerde.'
                : storeData.corporateBio,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isCompact ? 13 : 16,
              height: isCompact ? 1.55 : 1.8,
              color: isDark ? Colors.white70 : Colors.black54,
              fontStyle: FontStyle.italic,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernLinkHub(double radius) {
    final isCompact = isEmbedded;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 18 : 24),
      child: Column(
        children: [
          ...storeData.marketplaceLinks.map(
            (link) => _ModernLinkItem(
              icon: _getPlatformIcon(link.platform),
              title: link.platform,
              subtitle: link.url.isEmpty ? 'Mağazamızı ziyaret edin' : link.url,
              color: _getPlatformColor(link.platform),
              radius: radius,
              compact: isCompact,
            ),
          ),

          if (storeData.marketplaceLinks.isEmpty)
            _ModernLinkItem(
              icon: Icons.auto_stories_rounded,
              title: 'Dijital Katalog',
              subtitle: 'Geniş ürün ve hizmet yelpazesi',
              color: Colors.blueGrey,
              radius: radius,
              compact: isCompact,
            ),

          _ModernLinkItem(
            icon: Icons.verified_rounded,
            title: 'Referanslarımız',
            subtitle: 'Güçlü çözüm ortaklıklarımız',
            color: Colors.indigo.shade400,
            radius: radius,
            compact: isCompact,
          ),
          _ModernLinkItem(
            icon: Icons.qr_code_rounded,
            title: 'vCard Kaydet',
            subtitle: 'Hızlı iletişim için rehbere ekle',
            color: Colors.teal.shade500,
            radius: radius,
            compact: isCompact,
          ),
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
    ThemeData themeData,
    double radius,
  ) {
    final isDark = themeData.brightness == Brightness.dark;
    final isCompact = isEmbedded;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 18 : 24),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isCompact ? 18 : 28),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(isCompact ? 20 : radius),
          border: Border.all(
            color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
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
                    color: themeData.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
                  ),
                  child: Icon(
                    Icons.qr_code_2_rounded,
                    size: isCompact ? 34 : 54,
                    color: themeData.primaryColor,
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
                          letterSpacing: -0.8,
                        ),
                      ),
                      SizedBox(height: isCompact ? 4 : 6),
                      Text(
                        'TÜM BİLGİLERİM TEK QR İLE BURADA',
                        style: TextStyle(
                          fontSize: isCompact ? 8 : 10,
                          color: themeData.primaryColor,
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
                  backgroundColor: themeData.primaryColor,
                  foregroundColor: Colors.white,
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

  Widget _buildModernFooter(ThemeData themeData) {
    final isDark = themeData.brightness == Brightness.dark;
    return Column(
      children: [
        Text(
          'vitrinx.app/${storeData.name.toLowerCase().replaceAll(' ', '-')}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: themeData.primaryColor.withValues(alpha: 0.5),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 48),
        Container(
          height: 1,
          width: 50,
          color: themeData.primaryColor.withValues(alpha: 0.2),
        ),
        const SizedBox(height: 24),
        Text(
          'BU BİR VITRINX DİJİTAL KİMLİĞİDİR',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white10 : const Color(0xFFCBD5E1),
            letterSpacing: 4,
          ),
        ),
      ],
    );
  }
}

class _ActionIconBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final double radius;
  final bool compact;

  const _ActionIconBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.radius,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonRadius = compact ? 12.0 : 16.0;

    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(buttonRadius),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
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

  const _ModernLinkItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.radius,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(compact ? 13 : 18),
      margin: EdgeInsets.only(bottom: compact ? 10 : 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(compact ? 16 : 20),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
          width: compact ? 1 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: compact ? 12 : 20,
            offset: Offset(0, compact ? 3 : 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(compact ? 9 : 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(compact ? 11 : 14),
            ),
            child: Icon(icon, color: color, size: compact ? 18 : 22),
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
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: compact ? 2 : 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black45,
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
            color: const Color(0xFFCBD5E1),
            size: compact ? 11 : 14,
          ),
        ],
      ),
    );
  }
}

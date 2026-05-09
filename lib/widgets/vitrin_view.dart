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

  @override
  Widget build(BuildContext context) {
    final themeData = _getThemeData();
    final radius = isEmbedded ? 16.0 : 32.0;

    return Theme(
      data: themeData,
      child: Scaffold(
        backgroundColor: themeData.scaffoldBackgroundColor,
        extendBodyBehindAppBar: true,
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildModernHeader(themeData, radius),
              const SizedBox(height: 24),
              _buildPremiumActionButtons(radius),
              const SizedBox(height: 40),
              
              // Unified Professional Layout
              _buildProfessionalBio(themeData),
              const SizedBox(height: 40),
              _buildModernLinkHub(radius),
              
              const SizedBox(height: 60),
              _buildPremiumIdentityCard(context, themeData, radius),
              const SizedBox(height: 60),
              _buildModernFooter(themeData),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  ThemeData _getThemeData() {
    final isDarkTheme = ['Premium', 'Gece', 'Lüks'].contains(storeData.theme);
    final primaryColor = _getThemeColor(storeData.theme);

    return ThemeData(
      useMaterial3: true,
      brightness: isDarkTheme ? Brightness.dark : Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: isDarkTheme ? const Color(0xFF0F172A) : Colors.white,
      fontFamily: 'Inter',
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: isDarkTheme ? Brightness.dark : Brightness.light,
        primary: primaryColor,
      ),
    );
  }

  Color _getThemeColor(String theme) {
    switch (theme) {
      case 'Premium': return const Color(0xFF1E293B);
      case 'Zarif': return const Color(0xFF9E7C66);
      case 'Doğal': return Colors.green.shade700;
      case 'Gece': return const Color(0xFF0F172A);
      case 'Lüks': return const Color(0xFFD4AF37);
      case 'Sahil': return Colors.cyan.shade600;
      case 'Güneş': return Colors.orange.shade700;
      default: return Colors.blue.shade900;
    }
  }

  Widget _buildModernHeader(ThemeData themeData, double radius) {
    final isDark = themeData.brightness == Brightness.dark;
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: isEmbedded ? 200 : 280,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                themeData.primaryColor.withValues(alpha: 0.1),
                themeData.primaryColor.withValues(alpha: 0.02),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(24, isEmbedded ? 40 : 80, 24, 0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 30, offset: Offset(0, 10))],
                ),
                child: CircleAvatar(
                  radius: isEmbedded ? 36 : 48,
                  backgroundColor: themeData.primaryColor.withValues(alpha: 0.05),
                  child: Icon(Icons.business_center_rounded, size: isEmbedded ? 32 : 40, color: themeData.primaryColor),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                storeData.name.isEmpty ? 'Dijital Vitrin' : storeData.name,
                style: TextStyle(
                  fontSize: isEmbedded ? 24 : 32, 
                  fontWeight: FontWeight.w900, 
                  color: isDark ? Colors.white : Colors.black87, 
                  letterSpacing: -1,
                  height: 1.1
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: themeData.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  storeData.businessType.toUpperCase(),
                  style: TextStyle(fontSize: 10, color: themeData.primaryColor, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                ),
              ),
              const SizedBox(height: 16),
              StatusChip(status: storeData.status),
              if (storeData.description.isNotEmpty) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    storeData.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white60 : Colors.black45,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: [
          _ActionIconBtn(label: 'WhatsApp', icon: Icons.chat_bubble_rounded, color: const Color(0xFF25D366), radius: radius),
          _ActionIconBtn(label: 'Instagram', icon: Icons.camera_rounded, color: const Color(0xFFE1306C), radius: radius),
          if (storeData.website.isNotEmpty)
            _ActionIconBtn(label: 'Web', icon: Icons.language_rounded, color: Colors.blue.shade700, radius: radius),
          _ActionIconBtn(label: 'Adres', icon: Icons.location_on_rounded, color: Colors.red.shade600, radius: radius),
        ],
      ),
    );
  }

  Widget _buildProfessionalBio(ThemeData themeData) {
    final isDark = themeData.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Icon(Icons.format_quote_rounded, color: themeData.primaryColor.withValues(alpha: 0.1), size: 48),
          Text(
            storeData.corporateBio.isEmpty ? 'Tüm bilgileriniz, linkleriniz ve iletişim kanallarınız tek yerde.' : storeData.corporateBio,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16, 
              height: 1.7, 
              color: isDark ? Colors.white70 : Colors.black54,
              fontStyle: FontStyle.italic
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernLinkHub(double radius) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Dynamic Marketplace Links
          ...storeData.marketplaceLinks.map((link) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ModernLinkItem(
              icon: _getPlatformIcon(link.platform),
              title: link.platform,
              subtitle: link.url.isEmpty ? 'Mağazamızı ziyaret edin' : link.url,
              color: _getPlatformColor(link.platform),
              radius: radius,
            ),
          )),
          
          if (storeData.marketplaceLinks.isEmpty)
             _ModernLinkItem(
              icon: Icons.auto_stories_rounded,
              title: 'Dijital Katalog',
              subtitle: 'Geniş ürün ve hizmet yelpazesi',
              color: Colors.blueGrey,
              radius: radius,
            ),

          const SizedBox(height: 12),
          _ModernLinkItem(icon: Icons.verified_rounded, title: 'Referanslarımız', subtitle: 'Güçlü çözüm ortaklıklarımız', color: Colors.indigo, radius: radius),
          const SizedBox(height: 12),
          _ModernLinkItem(icon: Icons.qr_code_rounded, title: 'vCard Kaydet', subtitle: 'Hızlı iletişim için rehbere ekle', color: Colors.teal, radius: radius),
        ],
      ),
    );
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform) {
      case 'Trendyol': return Icons.shopping_bag_rounded;
      case 'Hepsiburada': return Icons.shopping_cart_rounded;
      case 'N11': return Icons.store_rounded;
      case 'Amazon': return Icons.cloud_done_rounded;
      case 'Shopier': return Icons.sell_rounded;
      default: return Icons.link_rounded;
    }
  }

  Color _getPlatformColor(String platform) {
    switch (platform) {
      case 'Trendyol': return Colors.orange.shade800;
      case 'Hepsiburada': return Colors.orange.shade700;
      case 'N11': return Colors.red.shade700;
      case 'Amazon': return Colors.blueGrey.shade900;
      case 'Shopier': return Colors.pink.shade700;
      default: return Colors.indigo;
    }
  }

  Widget _buildPremiumIdentityCard(BuildContext context, ThemeData themeData, double radius) {
    final isDark = themeData.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0x0DFFFFFF) : Colors.white,
          borderRadius: BorderRadius.circular(radius > 20 ? 20 : radius),
          border: Border.all(color: isDark ? Colors.white10 : const Color(0x0D000000)),
          boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 40, offset: Offset(0, 10))],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: themeData.primaryColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.qr_code_2_rounded, size: 48, color: themeData.primaryColor),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(storeData.name.isEmpty ? 'VitrinX Kart' : storeData.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
                      const SizedBox(height: 4),
                      Text('TÜM BİLGİLERİM TEK QR İLE BURADA', style: TextStyle(fontSize: 9, color: themeData.primaryColor, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showMvpInfo(context),
                icon: const Icon(Icons.share_rounded, size: 18),
                label: const Text('PROFİLİ PAYLAŞ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeData.primaryColor,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius > 12 ? 12 : radius)),
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
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: themeData.primaryColor.withValues(alpha: 0.4), letterSpacing: -0.5)
        ),
        const SizedBox(height: 48),
        Container(
          height: 1,
          width: 40,
          color: themeData.primaryColor.withValues(alpha: 0.1),
        ),
        const SizedBox(height: 20),
        Text('BU BİR VITRINX DİJİTAL KİMLİĞİDİR', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: isDark ? Colors.white10 : const Color(0x1A000000), letterSpacing: 3)),
      ],
    );
  }

  void _showMvpInfo(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bu özellik MVP aşamasındadır.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _ActionIconBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final double radius;

  const _ActionIconBtn({required this.label, required this.icon, required this.color, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(radius > 16 ? 16 : radius),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(radius > 16 ? 16 : radius),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
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

  const _ModernLinkItem({required this.icon, required this.title, required this.subtitle, required this.color, required this.radius});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0x0AFFFFFF) : Colors.white,
        borderRadius: BorderRadius.circular(radius > 16 ? 16 : radius),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0x0D000000)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: -0.3)), 
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)
              ]
            )
          ),
          Icon(Icons.arrow_forward_ios_rounded, color: const Color(0x1A000000), size: 14),
        ],
      ),
    );
  }
}

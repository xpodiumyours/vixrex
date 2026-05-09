import 'package:flutter/material.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/widgets/status_chip.dart';
import 'package:vitrinx/widgets/vitrin_product_card.dart';

class VitrinView extends StatelessWidget {
  final StoreData storeData;
  final bool isEmbedded;

  const VitrinView({
    super.key, 
    required this.storeData, 
    this.isEmbedded = false
  });

  ThemeData _getThemeData() {
    switch (storeData.theme) {
      case 'Premium':
        return ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFF8FAFC),
          primaryColor: const Color(0xFF0F172A),
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF0F172A), 
            secondary: Color(0xFF334155),
            surface: Colors.white,
          ),
          textTheme: const TextTheme(
            headlineMedium: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -1.5),
          ),
        );
      case 'Zarif':
        return ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFFAF9F6),
          primaryColor: const Color(0xFF7C2D12),
          colorScheme: const ColorScheme.light(primary: Color(0xFF7C2D12), secondary: Color(0xFF9A3412)),
          cardTheme: CardTheme(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        );
      case 'Doğal':
        return ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFF7FEE7),
          primaryColor: const Color(0xFF166534),
          colorScheme: const ColorScheme.light(primary: Color(0xFF166534), secondary: Color(0xFF3F6212)),
          cardTheme: CardTheme(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32))),
        );
      case 'Gece':
        return ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF020617),
          primaryColor: const Color(0xFF38BDF8),
          colorScheme: const ColorScheme.dark(primary: Color(0xFF38BDF8), secondary: Color(0xFF818CF8)),
          cardTheme: CardTheme(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
        );
      case 'Lüks':
        return ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0C0A09),
          primaryColor: const Color(0xFFD4AF37),
          colorScheme: const ColorScheme.dark(primary: Color(0xFFD4AF37), secondary: Color(0xFF78350F)),
          cardTheme: CardTheme(shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
        );
      case 'Sahil':
        return ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFF0F9FF),
          primaryColor: const Color(0xFF0369A1),
          colorScheme: const ColorScheme.light(primary: Color(0xFF0369A1), secondary: Color(0xFF0891B2)),
          cardTheme: CardTheme(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40))),
        );
      case 'Güneş':
        return ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFFFF7ED),
          primaryColor: const Color(0xFF9A3412),
          colorScheme: const ColorScheme.light(primary: Color(0xFF9A3412), secondary: Color(0xFFEA580C)),
          cardTheme: CardTheme(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        );
      case 'Sade':
      default:
        return ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: Colors.white,
          primaryColor: Colors.black,
          colorScheme: const ColorScheme.light(primary: Colors.black),
          cardTheme: CardTheme(shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
        );
    }
  }

  double _getBorderRadius() {
    switch (storeData.theme) {
      case 'Lüks': return 0.0;
      case 'Sahil': return 40.0;
      case 'Premium': return 16.0;
      case 'Gece': return 20.0;
      case 'Zarif': return 12.0;
      case 'Doğal': return 32.0;
      case 'Güneş': return 8.0;
      case 'Sade': return 0.0;
      default: return 12.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeData = _getThemeData();
    final radius = _getBorderRadius();

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
              if (storeData.isEsnafMode) ...[
                _buildModernCategoryTabs(themeData, radius),
                const SizedBox(height: 24),
                _buildProductGrid(context, themeData, radius),
              ] else ...[
                _buildProfessionalBio(themeData),
                const SizedBox(height: 40),
                _buildModernLinkHub(radius),
              ],
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
                  child: Icon(storeData.isEsnafMode ? Icons.storefront_rounded : Icons.business_center_rounded, size: isEmbedded ? 32 : 40, color: themeData.primaryColor),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                storeData.name.isEmpty ? (storeData.isEsnafMode ? 'Mağaza İsmi' : 'Kurumsal Kimlik') : storeData.name,
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

  Widget _buildModernCategoryTabs(ThemeData themeData, double radius) {
    const categories = ['TÜM ÜRÜNLER', 'YENİLER', 'EN ÇOK SATANLAR'];
    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = index == 0;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? themeData.primaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(radius > 16 ? 16 : radius),
              border: Border.all(color: isSelected ? themeData.primaryColor : themeData.primaryColor.withValues(alpha: 0.1)),
            ),
            child: Text(
              categories[index],
              style: TextStyle(
                color: isSelected ? Colors.white : themeData.primaryColor.withValues(alpha: 0.6), 
                fontWeight: FontWeight.w900, 
                fontSize: 10,
                letterSpacing: 0.5
              ),
            ),
          );
        },
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
            storeData.corporateBio.isEmpty ? 'Profesyonel çözümler ve güvenilir hizmet anlayışıyla yanınızdayız.' : storeData.corporateBio,
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

  Widget _buildProductGrid(BuildContext context, ThemeData themeData, double radius) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.65,
        ),
        itemCount: storeData.products.length,
        itemBuilder: (context, index) {
          final p = storeData.products[index];
          return VitrinProductCard(
            name: p.name.isEmpty ? 'İsimsiz Ürün' : p.name,
            price: p.price.isEmpty ? 'Sorunuz' : p.price,
            category: p.category,
            description: p.description,
            imagePath: p.imagePath,
            stockStatus: p.stockStatus,
            onWhatsAppTap: () => _openWhatsApp(context, "Merhaba, '${p.name}' hakkında bilgi alabilir miyim?"),
          );
        },
      ),
    );
  }

  Widget _buildModernLinkHub(double radius) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _ModernLinkItem(icon: Icons.auto_stories_rounded, title: 'Dijital Katalog', subtitle: 'Geniş ürün ve hizmet yelpazesi', color: Colors.blueGrey, radius: radius),
          const SizedBox(height: 12),
          _ModernLinkItem(icon: Icons.verified_rounded, title: 'Referanslarımız', subtitle: 'Güçlü çözüm ortaklıklarımız', color: Colors.indigo, radius: radius),
          const SizedBox(height: 12),
          _ModernLinkItem(icon: Icons.qr_code_rounded, title: 'vCard Kaydet', subtitle: 'Hızlı iletişim için rehbere ekle', color: Colors.teal, radius: radius),
        ],
      ),
    );
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

  void _openWhatsApp(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('WhatsApp Simülasyonu: $message'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF25D366),
      ),
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
                Text(subtitle, style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 11))
              ]
            )
          ),
          Icon(Icons.arrow_forward_ios_rounded, color: const Color(0x1A000000), size: 14),
        ],
      ),
    );
  }
}

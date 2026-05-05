import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/store_data.dart';
import '../widgets/status_chip.dart';
import '../widgets/vitrin_product_card.dart';

class PreviewScreen extends StatelessWidget {
  final StoreData storeData;

  const PreviewScreen({super.key, required this.storeData});

  ThemeData _getThemeData() {
    switch (storeData.theme) {
      case 'Premium':
        return ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFFDFDFD),
          primaryColor: const Color(0xFF1A1A1A),
          colorScheme: const ColorScheme.light(primary: Color(0xFF1A1A1A), secondary: Color(0xFFE67E22)),
          cardTheme: CardTheme(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
        );
      case 'Zarif':
        return ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFFAF9F6),
          primaryColor: const Color(0xFF9E7C66),
          colorScheme: const ColorScheme.light(primary: Color(0xFF9E7C66)),
          cardTheme: CardTheme(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        );
      case 'Doğal':
        return ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFF0FDF4),
          primaryColor: Colors.green.shade800,
          colorScheme: ColorScheme.light(primary: Colors.green.shade800),
          cardTheme: CardTheme(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
        );
      case 'Gece':
        return ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0F172A),
          primaryColor: Colors.white,
          colorScheme: const ColorScheme.dark(primary: Colors.white, secondary: Colors.blueAccent),
          cardTheme: CardTheme(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
        );
      case 'Lüks':
        return ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF1C1917),
          primaryColor: const Color(0xFFD4AF37),
          colorScheme: const ColorScheme.dark(primary: Color(0xFFD4AF37)),
          cardTheme: CardTheme(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
        );
      case 'Sahil':
        return ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFECFEFF),
          primaryColor: Colors.cyan.shade800,
          colorScheme: ColorScheme.light(primary: Colors.cyan.shade800),
          cardTheme: CardTheme(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40))),
        );
      case 'Güneş':
        return ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFFFF7ED),
          primaryColor: Colors.orange.shade900,
          colorScheme: ColorScheme.light(primary: Colors.orange.shade900),
          cardTheme: CardTheme(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
      case 'Lüks': return 4.0;
      case 'Sahil': return 40.0;
      case 'Premium':
      case 'Gece': return 24.0;
      case 'Zarif': return 16.0;
      case 'Doğal': return 20.0;
      case 'Güneş': return 12.0;
      case 'Sade': return 0.0;
      default: return 16.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeData = _getThemeData();
    final isDark = themeData.brightness == Brightness.dark;
    final radius = _getBorderRadius();

    return Theme(
      data: themeData,
      child: Scaffold(
        backgroundColor: themeData.scaffoldBackgroundColor,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
              child: BackButton(color: isDark ? Colors.white : Colors.black87),
            ),
          ),
        ),
        floatingActionButton: storeData.isEsnafMode 
          ? FloatingActionButton.extended(
              onPressed: () {},
              backgroundColor: const Color(0xFF25D366),
              elevation: 10,
              icon: const Icon(Icons.chat, color: Colors.white),
              label: const Text('WhatsApp Sipariş', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : FloatingActionButton(
              onPressed: () {},
              backgroundColor: themeData.primaryColor,
              child: const Icon(Icons.share, color: Colors.white),
            ),
        body: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                children: [
                  _buildPremiumHeader(themeData, radius),
                  const SizedBox(height: 32),
                  _buildActionButtons(themeData, radius),
                  const SizedBox(height: 48),
                  if (storeData.isEsnafMode) ...[
                    _buildCategoryTabs(themeData, radius),
                    const SizedBox(height: 24),
                    _buildProductSection(themeData, radius),
                  ] else ...[
                    _buildCorporateBio(themeData, radius),
                    const SizedBox(height: 32),
                    _buildCorporateStats(themeData, radius),
                    const SizedBox(height: 48),
                    _buildCorporateSection(themeData, radius),
                  ],
                  const SizedBox(height: 80),
                  _buildFooter(themeData, radius),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumHeader(ThemeData themeData, double radius) {
    final isDark = themeData.brightness == Brightness.dark;
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: 250,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                themeData.primaryColor.withValues(alpha: 0.05),
                themeData.scaffoldBackgroundColor,
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 100, 24, 0),
          child: Column(
            children: [
              Hero(
                tag: 'vitrinx_logo',
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(radius * 1.2),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 30, offset: const Offset(0, 10))
                    ],
                  ),
                  child: Icon(storeData.isEsnafMode ? Icons.storefront : Icons.business, size: 60, color: themeData.primaryColor),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                storeData.name.isEmpty ? (storeData.isEsnafMode ? 'Mağaza Adı' : 'Firma Adı') : storeData.name,
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, letterSpacing: -1),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                storeData.businessType.toUpperCase(),
                style: TextStyle(fontSize: 13, color: themeData.primaryColor.withValues(alpha: 0.6), fontWeight: FontWeight.w800, letterSpacing: 2),
              ),
              const SizedBox(height: 24),
              StatusChip(status: storeData.status),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTabs(ThemeData themeData, double radius) {
    final categories = ['Tümü', 'Yeni Gelenler', 'Popüler', 'İndirimli'];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final isSelected = index == 0;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? themeData.primaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: isSelected ? themeData.primaryColor : themeData.primaryColor.withValues(alpha: 0.1)),
            ),
            child: Text(
              categories[index],
              style: TextStyle(color: isSelected ? Colors.white : themeData.primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCorporateBio(ThemeData themeData, double radius) {
    final isDark = themeData.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            'Hakkımızda',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87),
          ),
          const SizedBox(height: 16),
          Text(
            storeData.description.isEmpty ? 'Vizyonumuz ve misyonumuzla geleceği inşa ediyoruz.' : storeData.description,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, height: 1.6, color: isDark ? Colors.white70 : Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildCorporateStats(ThemeData themeData, double radius) {
    final isDark = themeData.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _StatItem(title: '10+', subtitle: 'Yıl Deneyim', themeData: themeData, radius: radius),
          const SizedBox(width: 12),
          _StatItem(title: '500+', subtitle: 'Müşteri', themeData: themeData, radius: radius),
          const SizedBox(width: 12),
          _StatItem(title: '24/7', subtitle: 'Destek', themeData: themeData, radius: radius),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData themeData, double radius) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: [
          _ActionBtn(icon: Icons.chat, label: 'WhatsApp', color: const Color(0xFF25D366), radius: radius),
          _ActionBtn(icon: Icons.camera_alt, label: 'Instagram', color: const Color(0xFFE1306C), radius: radius),
          if (storeData.website.isNotEmpty)
            _ActionBtn(icon: Icons.language, label: 'Web Sitesi', color: Colors.blue, radius: radius),
          _ActionBtn(icon: Icons.map, label: 'Yol Tarifi', color: Colors.blueAccent, radius: radius),
        ],
      ),
    );
  }

  Widget _buildProductSection(ThemeData themeData, double radius) {
    final isDark = themeData.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text('Günün Vitrini', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, letterSpacing: -0.5)),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemCount: storeData.products.length,
            itemBuilder: (context, index) {
              final p = storeData.products[index];
              return VitrinProductCard(
                name: p.name.isEmpty ? 'İsimsiz Ürün' : p.name,
                price: p.price.isEmpty ? 'Fiyat Yok' : p.price,
                category: p.category,
                description: p.description,
                imagePath: p.imagePath,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCorporateSection(ThemeData themeData, double radius) {
    final isDark = themeData.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dijital Varlıklar', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 20),
          _CorporateLinkItem(icon: Icons.description_outlined, title: 'Katalog / Broşür', subtitle: 'Kurumsal kataloğumuzu PDF olarak indirin', color: Colors.red, radius: radius),
          const SizedBox(height: 12),
          _CorporateLinkItem(icon: Icons.star_outline, title: 'Referanslarımız', subtitle: 'Başarı hikayelerimiz ve çözüm ortaklarımız', color: Colors.blue, radius: radius),
          const SizedBox(height: 12),
          _CorporateLinkItem(icon: Icons.contact_page_outlined, title: 'vCard İndir', subtitle: 'Rehberinize tek tıkla kaydedin', color: Colors.green, radius: radius),
          const SizedBox(height: 40),
          _buildAddressCard(themeData, radius),
        ],
      ),
    );
  }

  Widget _buildAddressCard(ThemeData themeData, double radius) {
    final isDark = themeData.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(radius)),
      child: Row(
        children: [
          Icon(Icons.location_on, color: themeData.primaryColor, size: 28),
          const SizedBox(width: 20),
          Expanded(child: Text(storeData.address.isEmpty ? 'Adres bilgisi girilmemiş' : storeData.address, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, height: 1.5, fontSize: 15))),
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeData themeData, double radius) {
    final isDark = themeData.brightness == Brightness.dark;
    return Column(
      children: [
        Icon(Icons.qr_code_2, size: 80, color: isDark ? Colors.white24 : Colors.black12),
        const SizedBox(height: 24),
        Text('vitrinx.app/${storeData.name.toLowerCase().replaceAll(' ', '-')}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: themeData.primaryColor, letterSpacing: -0.5)),
        const SizedBox(height: 48),
        Text('POWERED BY VITRINX', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.1), letterSpacing: 3)),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final ThemeData themeData;
  final double radius;

  const _StatItem({required this.title, required this.subtitle, required this.themeData, required this.radius});

  @override
  Widget build(BuildContext context) {
    final isDark = themeData.brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: themeData.primaryColor.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: themeData.primaryColor)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black45, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final double radius;

  const _ActionBtn({required this.icon, required this.label, required this.color, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(radius), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 5))]),
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.1),
          foregroundColor: color,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
        ),
      ),
    );
  }
}

class _CorporateLinkItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final double radius;

  const _CorporateLinkItem({required this.icon, required this.title, required this.subtitle, required this.color, required this.radius});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 24)),
          const SizedBox(width: 20),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.5)), Text(subtitle, style: const TextStyle(color: Colors.black38, fontSize: 12))])),
          const Icon(Icons.chevron_right, color: Colors.black26),
        ],
      ),
    );
  }
}

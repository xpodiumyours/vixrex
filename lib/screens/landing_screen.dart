import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:vitrinx/screens/editor_screen.dart';
import 'package:vitrinx/screens/preview_screen.dart';
import 'package:vitrinx/models/store_data.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  // Modern Color Palette
  static const Color brandOrange = Color(0xFFFF5A1F);
  static const Color darkAccent = Color(0xFF0F172A);
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color mint = Color(0xFF10B981);
  static const Color blueAccent = Color(0xFF2563EB);
  static const Color pinkAccent = Color(0xFFFB7185);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _navigateToEditor() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditorScreen()),
    );
  }

  void _navigateToPreview() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PreviewScreen(storeData: StoreData.dummy()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: brandOrange,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroSection(context),
            _buildFeaturesSection(context),
            _buildStepsSection(context),
            _buildBottomCTA(context),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFBF7), Color(0xFFF6F8FF)],
        ),
      ),
      child: Stack(
        children: [
          // Ambient Mesh Glows
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                final sinVal = math.sin(_animController.value * math.pi * 2);
                final cosVal = math.cos(_animController.value * math.pi * 2);
                return Stack(
                  children: [
                    Positioned(
                      top: 100 + sinVal * 30,
                      left: -100 + cosVal * 40,
                      child: _buildMeshGlow(
                        brandOrange.withValues(alpha: 0.3),
                        300,
                      ),
                    ),
                    Positioned(
                      bottom: 50 + cosVal * 30,
                      right: -50 + sinVal * 40,
                      child: _buildMeshGlow(
                        blueAccent.withValues(alpha: 0.25),
                        400,
                      ),
                    ),
                    Positioned(
                      top: 200 - sinVal * 20,
                      right: 150 + cosVal * 20,
                      child: _buildMeshGlow(
                        pinkAccent.withValues(alpha: 0.2),
                        250,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 900;
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: isDesktop ? 120 : 60,
                      ),
                      child:
                          isDesktop
                              ? Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: _buildHeroContent(isDesktop: true),
                                  ),
                                  const SizedBox(width: 40),
                                  Expanded(flex: 5, child: _buildHeroMockup()),
                                ],
                              )
                              : Column(
                                children: [
                                  _buildHeroContent(isDesktop: false),
                                  const SizedBox(height: 60),
                                  _buildHeroMockup(),
                                ],
                              ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeshGlow(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildHeroContent({required bool isDesktop}) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween<double>(begin: 0, end: 1),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment:
            isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: brandOrange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: brandOrange.withValues(alpha: 0.3)),
            ),
            child: const Text(
              '✨ YENİ NESİL DİJİTAL VİTRİN',
              style: TextStyle(
                color: brandOrange,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Esnafın dijital vitrini',
            textAlign: isDesktop ? TextAlign.left : TextAlign.center,
            style: TextStyle(
              color: darkAccent,
              fontSize: isDesktop ? 64 : 42,
              fontWeight: FontWeight.w900,
              height: 1.1,
              letterSpacing: -2,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Mağaza bilgilerinizi, ürün linklerinizi, sosyal medya hesaplarınızı ve QR kodunuzu tek paylaşılabilir vitrin sayfasında toplayın.',
            textAlign: isDesktop ? TextAlign.left : TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 18,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 48),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: isDesktop ? WrapAlignment.start : WrapAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: brandOrange.withValues(
                            alpha:
                                0.3 +
                                0.2 *
                                    math.sin(
                                      _animController.value * math.pi * 2,
                                    ),
                          ),
                          blurRadius:
                              20 +
                              10 *
                                  math.sin(_animController.value * math.pi * 2),
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _navigateToEditor,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandOrange,
                        foregroundColor: darkAccent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Vitrinimi Oluştur',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                },
              ),
              OutlinedButton(
                onPressed: _navigateToPreview,
                style: OutlinedButton.styleFrom(
                  foregroundColor: darkAccent,
                  side: const BorderSide(color: Color(0x33111827), width: 2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 24,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text(
                  'Örnek Vitrine Bak',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroMockup() {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final floatOffset = math.sin(_animController.value * math.pi * 2) * 8;
        return Transform(
          transform:
              Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(-0.1)
                ..rotateX(0.05)
                ..translate(0.0, floatOffset, 0.0),
          alignment: Alignment.center,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              const _PhoneMockup(),
              Positioned(
                right: -40,
                top:
                    100 +
                    math.sin((_animController.value + 0.3) * math.pi * 2) * 10,
                child: _buildFloatingBadge(
                  Icons.favorite_rounded,
                  pinkAccent,
                  'Referanslar',
                ),
              ),
              Positioned(
                left: -30,
                bottom:
                    120 +
                    math.sin((_animController.value + 0.6) * math.pi * 2) * 10,
                child: _buildFloatingBadge(
                  Icons.shopping_bag_rounded,
                  brandOrange,
                  'Pazaryeri',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFloatingBadge(IconData icon, Color color, String text) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 12),
              Text(
                text,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: Color(0xFFF8FAFC),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesSection(BuildContext context) {
    return Container(
      width: double.infinity,
      color: lightBg,
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              const Text(
                'Bir link, tüm mağaza',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: darkAccent,
                  letterSpacing: -1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                'WhatsApp, Instagram, pazaryeri linkleri, referanslar ve QR kod tek vitrinde.',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black54,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 64),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 700;
                  return Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    alignment: WrapAlignment.center,
                    children:
                        [
                              _HoverFeatureCard(
                                icon: Icons.link_rounded,
                                color: blueAccent,
                                title: 'Tek linkte mağaza',
                                desc:
                                    'Müşteri tüm bilgilerinize tek bağlantıdan ulaşır.',
                              ),
                              _HoverFeatureCard(
                                icon: Icons.qr_code_2_rounded,
                                color: brandOrange,
                                title: 'QR ile paylaş',
                                desc:
                                    'Mağaza içine, paket üzerine veya sosyal medyaya ekleyin.',
                              ),
                              _HoverFeatureCard(
                                icon: Icons.chat_bubble_rounded,
                                color: mint,
                                title: 'Sosyal medya ve WhatsApp',
                                desc: 'Müşteri size doğrudan ulaşabilsin.',
                              ),
                              _HoverFeatureCard(
                                icon: Icons.shopping_cart_rounded,
                                color: pinkAccent,
                                title: 'Pazaryeri ve referanslar',
                                desc:
                                    'Trendyol, Hepsiburada, yorum ve referans linklerinizi toplayın.',
                              ),
                            ]
                            .map(
                              (widget) => SizedBox(
                                width:
                                    isDesktop
                                        ? (constraints.maxWidth - 24) / 2
                                        : constraints.maxWidth,
                                child: widget,
                              ),
                            )
                            .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepsSection(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Color(0xFFF8FAFC),
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              const Text(
                'Dakikalar içinde yayına hazır',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: darkAccent,
                  letterSpacing: -1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 80),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 800;
                  final steps = [
                    _buildStepTimeline(1, 'Bilgilerini ekle'),
                    _buildStepTimeline(2, 'Vitrin linkini oluştur'),
                    _buildStepTimeline(3, 'QR veya sosyal medya ile paylaş'),
                  ];

                  if (isDesktop) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: steps.map((e) => Expanded(child: e)).toList(),
                    );
                  }
                  return Column(
                    children:
                        steps.map((e) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 40),
                            child: e,
                          );
                        }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepTimeline(int step, String title) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: brandOrange.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: brandOrange.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '$step',
            style: const TextStyle(
              color: brandOrange,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: darkAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomCTA(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), brandOrange],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              const Text(
                'Mağazanız için paylaşılabilir bir dijital vitrin hazırlayın.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFF8FAFC),
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Linkinizi müşterilerinize gönderin, QR kodunuzu mağazada kullanın, tüm kanallarınızı tek yerde toplayın.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 18,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: _navigateToEditor,
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 24,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 10,
                ),
                child: const Text(
                  'Vitrinimi Oluştur',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      color: Color(0xFFF8FAFC),
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Text(
            'VITRINX',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 8,
              color: brandOrange.withValues(alpha: 0.8),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Dijital Dünyadaki Yeni Eviniz',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhoneMockup extends StatelessWidget {
  const _PhoneMockup();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: 640,
      decoration: BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white24, width: 8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
          BoxShadow(
            color: const Color(0xFFFF5A1F).withValues(alpha: 0.2),
            blurRadius: 80,
            offset: const Offset(-20, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            children: [
              // Mockup Header
              Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFF1F5F9),
                      const Color(0xFFFF5A1F).withValues(alpha: 0.1),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.store_rounded,
                        size: 32,
                        color: Color(0xFFFF5A1F),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Butik Mağaza',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'AÇIK',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Action buttons mock
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildMockIconButton(
                      Icons.chat_bubble,
                      const Color(0xFF25D366),
                    ),
                    const SizedBox(width: 12),
                    _buildMockIconButton(
                      Icons.camera_alt,
                      const Color(0xFFE1306C),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Mock Links
              _buildMockLinkItem(
                'Trendyol',
                'Mağazamızı ziyaret edin',
                const Color(0xFFF27A1A),
                Icons.shopping_bag,
              ),
              _buildMockLinkItem(
                'Referanslarımız',
                'Müşteri yorumları',
                Colors.indigo.shade400,
                Icons.verified,
              ),
              _buildMockLinkItem(
                'vCard Kaydet',
                'İletişim bilgilerini kopyala',
                Colors.teal.shade500,
                Icons.contact_page,
              ),
              const SizedBox(height: 20),
              // QR code mock
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Vitrin QR kodu',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Icon(
                      Icons.qr_code_2_rounded,
                      size: 80,
                      color: Colors.black87,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Bu vitrin VitrinX ile oluşturuldu',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black45,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMockIconButton(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildMockLinkItem(
    String title,
    String subtitle,
    Color color,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 20, right: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.black54, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HoverFeatureCard extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String desc;

  const _HoverFeatureCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.desc,
  });

  @override
  State<_HoverFeatureCard> createState() => _HoverFeatureCardState();
}

class _HoverFeatureCardState extends State<_HoverFeatureCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _isHovered ? -8 : 0, 0),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: _isHovered ? 0.15 : 0.05),
              blurRadius: _isHovered ? 30 : 10,
              offset: Offset(0, _isHovered ? 15 : 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(widget.icon, color: widget.color, size: 28),
            ),
            const SizedBox(height: 20),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: _LandingScreenState.darkAccent,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.desc,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

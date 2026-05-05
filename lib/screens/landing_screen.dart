import 'package:flutter/material.dart';
import 'editor_screen.dart';
import 'preview_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroSection(context),
            _buildModeComparisonSection(),
            _buildStepsSection(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade900,
            const Color(0xFF0F172A),
          ],
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Text(
              '✨ YENİ NESİL DİJİTAL VİTRİN',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'İşletmenizi Tek Linkle\nDünyaya Açın',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w900,
              height: 1.1,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Ürünlerinizi sergileyin, sipariş alın veya kurumsal kimliğinizi\nprofesyonel bir QR kod ile paylaşın. Hepsi tek bir platformda.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const EditorScreen()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue.shade900,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 20,
                  shadowColor: Colors.black.withValues(alpha: 0.5),
                ),
                child: const Text('VİTRİNİNİ ŞİMDİ OLUŞTUR', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeComparisonSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          const Text(
            'Hangi VitrinX Size Uygun?',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1),
          ),
          const SizedBox(height: 12),
          const Text('İhtiyacınıza göre özelleştirilmiş iki farklı deneyim.', style: TextStyle(color: Colors.black45)),
          const SizedBox(height: 60),
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: 24,
                runSpacing: 24,
                alignment: WrapAlignment.center,
                children: [
                  _buildModeCard(
                    title: 'Esnaf Modu',
                    subtitle: 'Ürün Odaklı Satış',
                    icon: Icons.storefront_rounded,
                    features: ['Sınırsız Ürün Listeleme', 'WhatsApp Sipariş Hattı', 'Kategori Yönetimi', 'Fiyat Bilgisi'],
                    color: Colors.blue.shade900,
                  ),
                  _buildModeCard(
                    title: 'Kurumsal Mod',
                    subtitle: 'Kimlik ve Link Hub',
                    icon: Icons.business_center_rounded,
                    features: ['Profesyonel Hakkımızda', 'Dijital Katalog Linkleri', 'Tek Tıkla vCard Kaydı', 'Referans Yönetimi'],
                    color: const Color(0xFF1E293B),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard({required String title, required String subtitle, required IconData icon, required List<String> features, required Color color}) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 40, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 24),
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          Text(subtitle, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 32),
          ...features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, size: 18, color: color),
                const SizedBox(width: 12),
                Text(f, style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildStepsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: Column(
        children: [
          const Text('3 Adımda Yayına Geçin', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1)),
          const SizedBox(height: 48),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStep(1, 'Bilgileri Girin', 'Mağaza adı ve iletişim.'),
                _buildStep(2, 'Tema Seçin', 'Size en uygun tarzı bulun.'),
                _buildStep(3, 'QR Paylaşın', 'Müşterilerinizle buluşun.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(int number, String title, String desc) {
    return Container(
      width: 200,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.blue.shade900,
            child: Text('$number', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 8),
          Text(desc, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black38, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Text('VITRINX', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4, color: Colors.blue.shade900)),
          const SizedBox(height: 8),
          const Text('Dijital Dünyadaki Yeni Eviniz', style: TextStyle(color: Colors.black26, fontSize: 11)),
        ],
      ),
    );
  }
}

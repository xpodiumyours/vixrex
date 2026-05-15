import 'package:flutter/material.dart';
import 'package:vitrinx/screens/editor_screen.dart';

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
      decoration: const BoxDecoration(color: Color(0xFF0F172A)),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 120),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5A1F).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: const Color(0xFFFF5A1F).withValues(alpha: 0.3),
                  ),
                ),
                child: const Text(
                  '✨ YENİ NESİL DİJİTAL VİTRİN',
                  style: TextStyle(
                    color: Color(0xFFFF5A1F),
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'İşletmenizi Tek Linkle\nDünyaya Açın',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Ürünlerinizi sergileyin, sipariş alın veya kurumsal kimliğinizi\nprofesyonel bir QR kod ile paylaşın. Hepsi tek bir platformda.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 64),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EditorScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5A1F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 26,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'VİTRİNİNİ ŞİMDİ OLUŞTUR',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 100),
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          const Text(
            '3 Adımda Yayına Geçin',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 64),
          Wrap(
            spacing: 32,
            runSpacing: 32,
            alignment: WrapAlignment.center,
            children: [
              _buildStep(
                1,
                'Bilgileri Girin',
                'Mağaza adı ve iletişim bilgilerini hızlıca ekleyin.',
              ),
              _buildStep(
                2,
                'Tema Seçin',
                'İşletmenize en uygun profesyonel görünümü seçin.',
              ),
              _buildStep(
                3,
                'QR Paylaşın',
                'Dijital vitrininizi QR kod ile anında müşterilerle buluşun.',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep(int number, String title, String desc) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFFFF5A1F).withValues(alpha: 0.1),
            child: Text(
              '$number',
              style: const TextStyle(
                color: Color(0xFFFF5A1F),
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(
        children: [
          Text(
            'VITRINX',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 8,
              color: const Color(0xFFFF5A1F).withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Dijital Dünyadaki Yeni Eviniz',
            style: TextStyle(
              color: Colors.black26,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

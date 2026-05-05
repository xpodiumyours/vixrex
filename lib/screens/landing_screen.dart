import 'dart:ui';
import 'package:flutter/material.dart';
import 'editor_screen.dart';
import 'preview_screen.dart';
import '../models/store_data.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildCompactHero(context),
            _buildInteractiveShowcase(context),
            _buildSimplifiedSteps(),
            _buildModernFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactHero(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade900, Colors.blueAccent.shade700],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 60),
      child: Column(
        children: [
          Hero(
            tag: 'vitrinx_logo',
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.auto_awesome, size: 40, color: Colors.white),
            ),
          ),
          const SizedBox(height: 24),
          const Text('VitrinX', style: TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -2)),
          const Text('Dijital Kimlik & Vitrin Merkezi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w300, color: Colors.white70, letterSpacing: 2)),
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CTAButton(
                text: 'Hemen Başla',
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditorScreen())),
                isPrimary: true,
              ),
              const SizedBox(width: 12),
              _CTAButton(
                text: 'Örneği Gör',
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PreviewScreen(storeData: StoreData.dummy()))),
                isPrimary: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveShowcase(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Column(
        children: [
          const Text('İki Katmanlı Güç', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1)),
          const SizedBox(height: 12),
          const Text('İster esnaf olun, ister kurumsal bir firma.', style: TextStyle(color: Colors.black54, fontSize: 16)),
          const SizedBox(height: 60),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              return Wrap(
                spacing: 24,
                runSpacing: 24,
                alignment: WrapAlignment.center,
                children: [
                  _ModeShowcaseCard(
                    title: 'Esnaf Modu',
                    icon: Icons.storefront,
                    color: Colors.orange,
                    features: ['Ürün Vitrini', 'WhatsApp Sipariş', 'Kategoriler'],
                  ),
                  _ModeShowcaseCard(
                    title: 'Kurumsal Mod',
                    icon: Icons.business,
                    color: Colors.blueAccent,
                    features: ['Link Hub', 'Katalog / PDF', 'vCard Paylaşımı'],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSimplifiedSteps() {
    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Column(
        children: [
          const Text('3 Adımda Yayındasın', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 60),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SimpleStep(num: '1', title: 'Bilgileri Gir'),
              _Arrow(),
              _SimpleStep(num: '2', title: 'Temanı Seç'),
              _Arrow(),
              _SimpleStep(num: '3', title: 'Linkini Paylaş'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernFooter() {
    return Container(
      padding: const EdgeInsets.all(60),
      color: const Color(0xFF0F172A),
      width: double.infinity,
      child: Column(
        children: [
          const Text('VitrinX', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('Türkiye\'nin Dijital Vitrin Platformu', style: TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 40),
          const Text('© 2026 Tüm Hakları Saklıdır.', style: TextStyle(color: Colors.white24, fontSize: 11)),
        ],
      ),
    );
  }
}

class _CTAButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isPrimary;

  const _CTAButton({required this.text, required this.onPressed, required this.isPrimary});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? Colors.white : Colors.white10,
        foregroundColor: isPrimary ? Colors.blue.shade900 : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
    );
  }
}

class _ModeShowcaseCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<String> features;

  const _ModeShowcaseCard({required this.title, required this.icon, required this.color, required this.features});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 30, offset: const Offset(0, 15))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: color, size: 28)),
          const SizedBox(height: 24),
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 20),
          ...features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [Icon(Icons.check_circle, size: 16, color: color), const SizedBox(width: 8), Text(f, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600))]),
          )),
        ],
      ),
    );
  }
}

class _SimpleStep extends StatelessWidget {
  final String num;
  final String title;

  const _SimpleStep({required this.num, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(radius: 20, backgroundColor: Colors.blue.shade900, child: Text(num, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }
}

class _Arrow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey.shade300));
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class GoogleBusinessGuideCard extends StatelessWidget {
  final String publishedLink;

  const GoogleBusinessGuideCard({super.key, required this.publishedLink});

  Future<void> _launchGoogleBusiness(BuildContext context) async {
    final url = Uri.parse('https://business.google.com/');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google Business sayfası açılamadı.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _copyLink(BuildContext context) {
    Clipboard.setData(ClipboardData(text: publishedLink));
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vitrin linkiniz kopyalandı!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color orangeAccent = Color(0xFFFF9900);
    const Color blueAccent = Color(0xFF4285F4);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E293B), // Slate 800
            Color(0xFF0F172A), // Slate 900
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with Orange Glowing Badge
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: orangeAccent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: orangeAccent.withValues(alpha: 0.2),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.store_mall_directory_rounded,
                    color: orangeAccent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Google Haritalar\'da Öne Çıkın',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Yerel aramalarda 2 kat daha fazla müşteri kazanın',
                        style: TextStyle(
                          color: Color(0xFF94A3B8), // Slate 400
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Divider
          Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
          // Content Steps
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStepItem(
                  '1. Adım: Vitrin Linkinizi Kopyalayın',
                  'Google profilinize eklemek üzere hazırlanan vitrin adresinizi hafızaya alın.',
                  trailing: TextButton.icon(
                    onPressed: () => _copyLink(context),
                    icon: const Icon(
                      Icons.copy_all_rounded,
                      size: 14,
                      color: orangeAccent,
                    ),
                    label: const Text('Kopyala'),
                    style: TextButton.styleFrom(
                      foregroundColor: orangeAccent,
                      textStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildStepItem(
                  '2. Adım: Google Benim İşletmem\'i Açın',
                  'Aşağıdaki "Google İşletme Paneline Git" butonuna tıklayarak profil yönetim ekranınıza gidin.',
                ),
                const SizedBox(height: 16),
                _buildStepItem(
                  '3. Adım: Web Sitesi Alanına Yapıştırın',
                  'Profil Ayarları > İletişim > Web Sitesi adımına kopyaladığınız linki yapıştırıp kaydedin.',
                ),
              ],
            ),
          ),
          // Call To Action Button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ElevatedButton.icon(
              onPressed: () => _launchGoogleBusiness(context),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('Google İşletme Paneline Git'),
              style: ElevatedButton.styleFrom(
                backgroundColor: blueAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(String title, String desc, {Widget? trailing}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          child: const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF10B981), // Emerald 500
            size: 15,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (trailing != null) trailing,
                ],
              ),
              const SizedBox(height: 3),
              Text(
                desc,
                style: const TextStyle(
                  color: Color(0xFF94A3B8), // Slate 400
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

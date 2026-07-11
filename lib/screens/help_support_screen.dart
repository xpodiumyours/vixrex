import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vixrex/config/legal_config.dart';
import 'package:vixrex/theme/app_colors.dart';

/// Kullanım bilgisi, SSS ve iletişim — etiket=içerik (Legal yaması yok).
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const _faqs = <({String q, String a})>[
    (
      q: 'Vitrin nasıl yayınlanır?',
      a:
          'Vitrinim sekmesinde işletme bilgilerinizi doldurun, yasal onayları işaretleyin ve Yayınla butonuna basın. Yayın sonrası size özel web linki oluşur.',
    ),
    (
      q: 'Ürünleri nasıl eklerim?',
      a:
          'Vitrinim içinde Ürün Yönetimi’nden tek tek ekleyebilir, fotoğraftan OCR ile çıkarabilir veya CSV/Excel ile toplu yükleyebilirsiniz.',
    ),
    (
      q: 'Müşteriler vitrinimi nasıl görür?',
      a:
          'Yayınlanan vitrin herkese açık web linki ve QR kod ile paylaşılır. Keşfet sekmesinde yayınlı vitrinler listelenir.',
    ),
    (
      q: 'Randevu sistemi nasıl çalışır?',
      a:
          'Kuaför ve benzeri kategorilerde randevu ayarlarını açabilirsiniz. Gelen talepleri Randevu Yönetimi’nden onaylayıp WhatsApp ile bilgilendirebilirsiniz.',
    ),
    (
      q: 'Verilerimi nasıl silebilirim?',
      a:
          'Gizlilik sayfasındaki veri silme talebi veya hesap silme işlemi ile kişisel verilerinizin silinmesini talep edebilirsiniz.',
    ),
  ];

  Future<void> _openMail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: LegalConfig.privacyEmail,
      queryParameters: {'subject': 'VixRex Destek'},
    );
    try {
      final launched = await launchUrl(uri);
      if (!launched && context.mounted) {
        await Clipboard.setData(
          ClipboardData(text: LegalConfig.privacyEmail),
        );
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('E-posta adresi panoya kopyalandı.'),
          ),
        );
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: LegalConfig.privacyEmail));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('E-posta adresi panoya kopyalandı.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgEditor,
      appBar: AppBar(
        title: const Text(
          'Kullanım & Destek',
          style: TextStyle(
            color: AppColors.darkText,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.bgEditor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkText),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          const Text(
            'Sıkça sorulan sorular',
            style: TextStyle(
              color: AppColors.darkText,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          ..._faqs.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                backgroundColor: AppColors.surface,
                collapsedBackgroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.border),
                ),
                collapsedShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.border),
                ),
                title: Text(
                  item.q,
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                children: [
                  Text(
                    item.a,
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 12,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'İletişim',
            style: TextStyle(
              color: AppColors.darkText,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sorunuz SSS’de yoksa bize yazın. Yanıt için ${LegalConfig.privacyEmail} adresini kullanıyoruz.',
            style: const TextStyle(
              color: AppColors.mutedText,
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => _openMail(context),
            icon: const Icon(Icons.mail_outline_rounded),
            label: const Text('E-posta gönder'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }
}

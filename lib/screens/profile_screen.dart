import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vixrex/config/app_router.dart';
import 'package:vixrex/config/public_site_config.dart';
import 'package:vixrex/screens/app_settings_screen.dart';
import 'package:vixrex/screens/help_support_screen.dart';
import 'package:vixrex/screens/legal_screen.dart';
import 'package:vixrex/services/auth_service.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/theme/app_text_styles.dart';
import 'package:vixrex/widgets/common/app_card.dart';
import 'package:vixrex/widgets/common/app_screen_scaffold.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    this.publicLink,
    this.storeName,
    this.onShowQr,
    this.onCopyLink,
  });

  final String? publicLink;
  final String? storeName;
  final VoidCallback? onShowQr;
  final VoidCallback? onCopyLink;

  bool get _hasLink => publicLink != null && publicLink!.trim().isNotEmpty;

  String get _displayLink {
    if (!_hasLink) return 'Henüz yayınlanmamış';
    return PublicSiteConfig.repairPublicLink(
      publicLink!,
    ).replaceFirst(RegExp(r'^https?://'), '');
  }

  String get _userLabel {
    final email = const AuthService().currentUser?.email;
    if (email != null && email.isNotEmpty) return email;
    final name = storeName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return 'Vixrex Kullanıcısı';
  }

  Future<void> _copyLink(BuildContext context) async {
    if (!_hasLink) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link kopyalamak için önce vitrininizi yayınlayın.'),
        ),
      );
      return;
    }
    if (onCopyLink != null) {
      onCopyLink!();
      return;
    }
    final link = PublicSiteConfig.repairPublicLink(publicLink!);
    await Clipboard.setData(ClipboardData(text: link));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Vitrin linki kopyalandı.')));
  }

  void _openQr(BuildContext context) {
    if (onShowQr != null) {
      onShowQr!();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('QR kodu göstermek için önce vitrininizi yayınlayın.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScreenScaffold(
      title: 'Profil',
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _accountCard(),
            const SizedBox(height: 16),
            _linkCard(context),
            const SizedBox(height: 12),
            _qrCard(context),
            const SizedBox(height: 20),
            _option(
              Icons.settings_outlined,
              'Uygulama Ayarları',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AppSettingsScreen()),
              ),
            ),
            const SizedBox(height: 10),
            _option(
              Icons.help_outline_rounded,
              'Kullanım Bilgisi & Destek',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
              ),
            ),
            const SizedBox(height: 10),
            _option(
              Icons.shield_outlined,
              'Gizlilik ve Güvenlik politikası',
              () => AppRouter.navigateToLegal(context, LegalPageType.privacy),
            ),
          ],
        ),
      ),
    );
  }

  Widget _accountCard() {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: AppColors.surfaceSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_userLabel, style: AppTextStyles.subTitle),
                const SizedBox(height: 2),
                Text(
                  _hasLink ? 'Vitrininiz yayında' : 'Hesabınız aktif',
                  style: AppTextStyles.labelSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _linkCard(BuildContext context) {
    return AppCard(
      onTap: () => _copyLink(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vitrin Bağlantısı',
            style: AppTextStyles.labelBold,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.link_rounded,
                  color: AppColors.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _displayLink,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: _hasLink ? AppColors.darkText : AppColors.mutedText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_hasLink)
                  const Icon(
                    Icons.copy_rounded,
                    color: AppColors.mutedText,
                    size: 16,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _qrCard(BuildContext context) {
    return AppCard(
      onTap: () => _openQr(context),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.qr_code_2_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hızlı QR Kod Paylaşımı',
                  style: AppTextStyles.labelBold,
                ),
                SizedBox(height: 2),
                Text(
                  'Vitrin QR kodunuza hızlıca ulaşın.',
                  style: AppTextStyles.labelSmall,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            color: AppColors.mutedText,
            size: 12,
          ),
        ],
      ),
    );
  }

  Widget _option(IconData icon, String title, VoidCallback onTap) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: AppColors.mutedText, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text(title, style: AppTextStyles.labelBold),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            color: AppColors.mutedText,
            size: 12,
          ),
        ],
      ),
    );
  }
}

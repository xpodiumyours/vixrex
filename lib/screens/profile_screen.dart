import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vixrex/config/app_router.dart';
import 'package:vixrex/config/public_site_config.dart';
import 'package:vixrex/screens/app_settings_screen.dart';
import 'package:vixrex/screens/help_support_screen.dart';
import 'package:vixrex/screens/legal_screen.dart';
import 'package:vixrex/services/auth_service.dart';
import 'package:vixrex/theme/app_colors.dart';

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

  bool get _hasLink =>
      publicLink != null && publicLink!.trim().isNotEmpty;

  String get _displayLink {
    if (!_hasLink) return 'Henüz yayınlanmamış';
    return PublicSiteConfig.repairPublicLink(publicLink!)
        .replaceFirst(RegExp(r'^https?://'), '');
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
          content: Text(
            'Link kopyalamak için önce vitrininizi yayınlayın.',
          ),
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vitrin linki kopyalandı.')),
    );
  }

  void _openQr(BuildContext context) {
    if (onShowQr != null) {
      onShowQr!();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'QR kodu göstermek için önce vitrininizi yayınlayın.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgEditor,
      appBar: AppBar(
        title: const Text(
          'Profil',
          style: TextStyle(
            color: AppColors.darkText,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.bgEditor,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _accountCard(),
              const SizedBox(height: 20),
              _linkCard(context),
              const SizedBox(height: 12),
              _qrCard(context),
              const SizedBox(height: 20),
              _option(
                Icons.settings_outlined,
                'Uygulama Ayarları',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AppSettingsScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _option(
                Icons.help_outline_rounded,
                'Kullanım Bilgisi & Destek',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HelpSupportScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _option(
                Icons.shield_outlined,
                'Gizlilik ve Güvenlik politikası',
                () => AppRouter.navigateToLegal(
                  context,
                  LegalPageType.privacy,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _accountCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
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
                Text(
                  _userLabel,
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _hasLink ? 'Vitrininiz yayında' : 'Hesabınız aktif',
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _linkCard(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _copyLink(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Vitrin Bağlantısı',
                style: TextStyle(
                  color: AppColors.darkText,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(10),
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
                        style: TextStyle(
                          color: _hasLink
                              ? AppColors.darkText
                              : AppColors.mutedText,
                          fontSize: 12,
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
        ),
      ),
    );
  }

  Widget _qrCard(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _openQr(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
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
                      style: TextStyle(
                        color: AppColors.darkText,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Vitrin QR kodunuza hızlıca ulaşın.',
                      style: TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
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
        ),
      ),
    );
  }

  Widget _option(IconData icon, String title, VoidCallback onTap) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.mutedText, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.mutedText,
                size: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

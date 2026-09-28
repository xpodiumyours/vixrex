import 'package:flutter/material.dart';
import 'package:vixrex/config/app_router.dart';
import 'package:vixrex/services/auth_service.dart';
import 'package:vixrex/services/owner_bootstrap_service.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/widgets/common/app_card.dart';
import 'package:vixrex/widgets/common/app_screen_scaffold.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoading = false;

  Future<void> _googleIleDevamEt() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final authService = const AuthService();
    final mevcut = authService.currentUser;

    if (mevcut != null && mevcut.isAnonymous) {
      final result = await authService.hesabiGoogleaBagla();
      if (!mounted) return;
      if (result.isFailure) {
        setState(() => _isLoading = false);
        if (!result.failure!.message.contains('iptal')) {
          _showError(result.failure!.message);
        }
        return;
      }
      await _handlePostAuthentication();
    } else {
      final result = await authService.signInWithGoogle();
      if (!mounted) return;
      if (result.isFailure) {
        setState(() => _isLoading = false);
        if (!result.failure!.message.contains('iptal') &&
            !result.failure!.message.contains('yönlendiriliyor')) {
          _showError(result.failure!.message);
        }
        return;
      }
      await _handlePostAuthentication();
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handlePostAuthentication() async {
    final authService = const AuthService();

    final claimMesaji = (await authService.claimDeviceStore())?.kullaniciMesaji;

    final stateResult = await authService.getOwnerState();
    final state = stateResult.when(
      success: (value) => value,
      failure: (_) => null,
    );

    var korunanYerelTaslak = false;
    if (state != null && state.hasStore) {
      final uygulama = await const OwnerBootstrapService().cihazaUygula(state);
      korunanYerelTaslak = uygulama.korunanYerelTaslak;
    }

    if (!mounted) return;

    final mesaj =
        korunanYerelTaslak
            ? 'Bu cihazdaki düzenlemeniz daha yeni olduğu için korundu.'
            : claimMesaji;
    if (mesaj != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mesaj),
          backgroundColor:
              korunanYerelTaslak ? AppColors.warning : Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    if (state == null || !state.hasStore || state.isStoreMode) {
      AppRouter.navigateToLanding(context);
      return;
    }

    AppRouter.navigateToHomeShell(context, initialIndex: 0);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScreenScaffold(
      title: 'Hesabını Koru',
      padding: EdgeInsets.zero,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: AppCard(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.storefront_rounded,
                        color: AppColors.brandOrange,
                        size: 30,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Vixrex',
                        style: TextStyle(
                          color: AppColors.darkText,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Google ile kalıcı erişim',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.darkText,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '14 günlük ücretsiz vitrin denemesi için Google gerekmez. '
                    'Hazır vitrini seçip hemen özelleştirebilirsin. '
                    'Google yalnız vitrini kalıcı hesabına bağlamak ve başka '
                    'cihazlardan erişmek için gerekir.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _googleIleDevamEt,
                    icon: const Icon(Icons.account_circle_outlined),
                    label: Text(
                      _isLoading ? 'Google açılıyor…' : 'Google ile Devam Et',
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed:
                        _isLoading
                            ? null
                            : () => AppRouter.navigateToHomeShell(
                              context,
                              initialIndex: 1,
                            ),
                    child: const Text('14 Gün Ücretsiz Vitrin Dene'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

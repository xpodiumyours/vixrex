import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vixrex/config/app_router.dart';
import 'package:vixrex/screens/legal_screen.dart';
import 'package:vixrex/screens/notifications_screen.dart';
import 'package:vixrex/services/auth_service.dart';
import 'package:vixrex/services/notification_preferences_service.dart';
import 'package:vixrex/theme/app_colors.dart';

/// Uygulama ayarları — bildirim tercihi + hesap. Tema ayrı state uydurulmaz (app dark-first).
class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  final _prefsService = const NotificationPreferencesService();
  final _auth = const AuthService();
  bool _loading = true;
  bool _bookingPushEnabled = true;
  bool _signingOut = false;
  bool _deletingAccount = false;
  bool _exportingData = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final enabled = await _prefsService.isBookingPushEnabled();
      if (!mounted) return;
      setState(() {
        _bookingPushEnabled = enabled;
        _loading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('AppSettingsScreen._load: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _setBookingPush(bool value) async {
    setState(() => _bookingPushEnabled = value);
    try {
      await _prefsService.setBookingPushEnabled(value);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Randevu bildirimleri açıldı.'
                : 'Randevu bildirimleri kapatıldı.',
          ),
        ),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('AppSettingsScreen._setBookingPush: $e');
      if (!mounted) return;
      setState(() => _bookingPushEnabled = !value);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tercih kaydedilemedi. Tekrar deneyin.'),
        ),
      );
    }
  }

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    final result = await _auth.signOut();
    if (!mounted) return;
    setState(() => _signingOut = false);
    result.when(
      success: (_) {
        AppRouter.navigateToLanding(context);
      },
      failure: (f) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.message)),
        );
      },
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Hesabı kalıcı sil'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Vitrininiz, ürünleriniz ve hesabınız silinir. Bu işlem geri alınamaz.',
              ),
              const SizedBox(height: 16),
              const Text('Onaylamak için SİL yazın:'),
              const SizedBox(height: 8),
              TextField(
                controller: confirmCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'SİL',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Vazgeç'),
            ),
            TextButton(
              onPressed: () {
                if (!AuthService.isDeleteConfirmationValid(confirmCtrl.text)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Onay için tam olarak SİL yazmalısınız.'),
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx, true);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Hesabı sil'),
            ),
          ],
        );
      },
    );
    confirmCtrl.dispose();
    if (confirmed != true || !mounted) return;

    setState(() => _deletingAccount = true);
    final result = await _auth.deleteAccount();
    if (!mounted) return;
    setState(() => _deletingAccount = false);

    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hesabınız silindi.')),
        );
        AppRouter.navigateToLanding(context);
      },
      failure: (f) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.message)),
        );
      },
    );
  }

  Future<void> _exportMyData() async {
    setState(() => _exportingData = true);
    final result = await _auth.exportMyData();
    if (!mounted) return;

    if (result.isFailure) {
      setState(() => _exportingData = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.failure!.message)),
      );
      return;
    }

    final payload = result.data!;
    final jsonText = const JsonEncoder.withIndent('  ').convert(payload);
    final bytes = utf8.encode(jsonText);
    final stamp = DateTime.now().toUtc().toIso8601String().split('T').first;
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              bytes,
              mimeType: 'application/json',
              name: 'vixrex-verilerim-$stamp.json',
            ),
          ],
          subject: 'VixRex veri dışa aktarımı',
          text: 'VixRex hesap verileriniz (JSON).',
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verileriniz dışa aktarıldı.')),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('AppSettingsScreen._exportMyData: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Paylaşım açılamadı. Bir sorun oluştu, lütfen tekrar deneyin.',
          ),
        ),
      );
    }

    if (mounted) setState(() => _exportingData = false);
  }

  @override
  Widget build(BuildContext context) {
    final email = _auth.currentUser?.email;

    return Scaffold(
      backgroundColor: AppColors.bgEditor,
      appBar: AppBar(
        title: const Text(
          'Uygulama Ayarları',
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              children: [
                _sectionTitle('Bildirimler'),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: SwitchListTile(
                    value: _bookingPushEnabled,
                    onChanged: _setBookingPush,
                    title: const Text(
                      'Randevu bildirimleri',
                      style: TextStyle(
                        color: AppColors.darkText,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: const Text(
                      'Randevu onay, red ve hatırlatma push bildirimleri',
                      style: TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    activeThumbColor: Colors.black,
                    activeTrackColor: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                _linkTile(
                  'Bildirim geçmişi',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _sectionTitle('Hesap'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        email == null || email.isEmpty
                            ? 'Misafir oturum (giriş yapılmamış)'
                            : email,
                        style: const TextStyle(
                          color: AppColors.darkText,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (email != null && email.isNotEmpty) ...[
                        OutlinedButton(
                          onPressed: _signingOut ||
                                  _deletingAccount ||
                                  _exportingData
                              ? null
                              : _signOut,
                          child: _signingOut
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Çıkış yap'),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: _signingOut ||
                                  _deletingAccount ||
                                  _exportingData
                              ? null
                              : _exportMyData,
                          child: _exportingData
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Verilerimi dışa aktar'),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _signingOut ||
                                  _deletingAccount ||
                                  _exportingData
                              ? null
                              : _confirmDeleteAccount,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                          ),
                          child: _deletingAccount
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Hesabı kalıcı sil'),
                        ),
                      ] else
                        FilledButton(
                          onPressed: () => AppRouter.navigateToAuth(context),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('Giriş yap'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _sectionTitle('Yasal'),
                const SizedBox(height: 8),
                _linkTile(
                  'Gizlilik politikası',
                  () => AppRouter.navigateToLegal(
                    context,
                    LegalPageType.privacy,
                  ),
                ),
                const SizedBox(height: 8),
                _linkTile(
                  'Kullanım koşulları',
                  () => AppRouter.navigateToLegal(
                    context,
                    LegalPageType.terms,
                  ),
                ),
                const SizedBox(height: 8),
                _linkTile(
                  'Veri silme talebi',
                  () => AppRouter.navigateToLegal(
                    context,
                    LegalPageType.dataDeletion,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.darkText,
        fontSize: 14,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _linkTile(String title, VoidCallback onTap) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
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

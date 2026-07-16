import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vixrex/config/legal_config.dart';
import 'package:vixrex/services/auth_service.dart';
import 'package:vixrex/services/local_storage_keys.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/config/app_router.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  static const Color brandOrange = AppColors.brandOrange;
  static const Color darkAccent = AppColors.darkTextAlt;
  static const Color lightBg = AppColors.bgLight;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final authService = const AuthService();

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    final result = _isLogin
        ? await authService.signIn(email, password)
        : await authService.signUp(email, password);

    result.when(
      success: (authResponse) async {
        // E-posta onayı açıksa signup session döndürmez; giriş çalışmaz.
        if (!_isLogin && authResponse.session == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Hesap oluşturuldu. Giriş için e-postanızdaki Vixrex doğrulama bağlantısına tıklayın.',
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 6),
            ),
          );
          setState(() => _isLogin = true);
          return;
        }
        await _handlePostAuthentication();
      },
      failure: (failure) {
        if (!mounted) return;
        _showError(failure.message);
      },
    );

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _resetPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty ||
        !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showError('Şifre sıfırlamak için geçerli bir e-posta girin.');
      return;
    }

    setState(() => _isLoading = true);
    final result = await const AuthService().resetPassword(email);
    if (!mounted) return;
    setState(() => _isLoading = false);

    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Şifre sıfırlama bağlantısı e-postanıza gönderildi. Gelen kutunuzu kontrol edin.',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      failure: (failure) => _showError(failure.message),
    );
  }

  Future<void> _handlePostAuthentication() async {
    final authService = const AuthService();
    final prefs = await SharedPreferences.getInstance();

    // 1. Check for local edit tokens and link them if present.
    // Publish writes last_published_edit_token (+ mirrored vitrin/store keys).
    final localTokenCandidates = <String>[
      prefs.getString(LocalStorageKeys.lastPublishedEditToken) ?? '',
      prefs.getString(LocalStorageKeys.vitrinEditToken) ?? '',
      prefs.getString(LocalStorageKeys.storeEditToken) ?? '',
    ];
    final localEditToken = localTokenCandidates
        .map((t) => t.trim())
        .firstWhere((t) => t.isNotEmpty, orElse: () => '');

    bool linked = false;
    if (localEditToken.isNotEmpty) {
      final linkResult = await authService.linkAnonymousStore(localEditToken);
      linkResult.when(
        success: (value) => linked = value,
        failure: (_) {},
      );
    }

    if (!mounted) return;

    if (linked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Mevcut vitrininiz hesabınızla başarıyla ilişkilendirildi!',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    // 2. Fetch the store owned by the authenticated user
    final storeResult = await authService.getStoreForCurrentUser();

    storeResult.when(
      success: (store) async {
        if (!mounted) return;

        if (store != null) {
          if (store.isStore) {
            await prefs.setString(
              LocalStorageKeys.storeData,
              jsonEncode(store.toJson()),
            );

            if (!mounted) return;

            final tokenResult = await authService.getEditTokenForCurrentUser();
            tokenResult.when(
              success: (editToken) async {
                if (editToken != null) {
                  await prefs.setString(
                    LocalStorageKeys.storeEditToken,
                    editToken,
                  );
                  await prefs.setString(
                    LocalStorageKeys.lastPublishedEditToken,
                    editToken,
                  );
                  if (store.slug.isNotEmpty) {
                    await prefs.setString(
                      LocalStorageKeys.lastPublishedSlug,
                      store.slug,
                    );
                  }
                }
              },
              failure: (_) {},
            );

            if (!mounted) return;

            AppRouter.navigateToLanding(context);
          } else {
            await prefs.setString(
              LocalStorageKeys.vitrinData,
              jsonEncode(store.toJson()),
            );

            if (!mounted) return;

            final tokenResult = await authService.getEditTokenForCurrentUser();
            tokenResult.when(
              success: (editToken) async {
                if (editToken != null) {
                  await prefs.setString(
                    LocalStorageKeys.vitrinEditToken,
                    editToken,
                  );
                  await prefs.setString(
                    LocalStorageKeys.lastPublishedEditToken,
                    editToken,
                  );
                  if (store.slug.isNotEmpty) {
                    await prefs.setString(
                      LocalStorageKeys.lastPublishedSlug,
                      store.slug,
                    );
                  }
                }
              },
              failure: (_) {},
            );

            if (!mounted) return;

            AppRouter.navigateToHomeShell(context, initialIndex: 0);
          }
        } else {
          AppRouter.navigateToLanding(context);
        }
      },
      failure: (_) {
        if (!mounted) return;
        AppRouter.navigateToLanding(context);
      },
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        title: Text(
          _isLogin ? 'Giriş Yap' : 'Kayıt Ol',
          style: const TextStyle(
            color: darkAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: darkAccent),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 4,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // App logo or title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: brandOrange.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.storefront_rounded,
                              color: brandOrange,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Vixrex',
                            style: TextStyle(
                              color: darkAccent,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Title Text
                      Text(
                        _isLogin
                            ? 'Hesabınıza Giriş Yapın'
                            : 'Yeni Hesap Oluşturun',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: darkAccent,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isLogin
                            ? 'Vitrinlerinizi yönetmek için bilgilerinizi girin.'
                            : 'Mağazanıza her cihazdan erişmek için kayıt olun.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Email input
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'E-posta Adresi',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: brandOrange,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'E-posta adresi boş bırakılamaz';
                          }
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(value.trim())) {
                            return 'Geçersiz e-posta adresi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password input
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Şifre',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: brandOrange,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Şifre boş bırakılamaz';
                          }
                          if (value.length < 6) {
                            return 'Şifre en az 6 karakter olmalıdır';
                          }
                          return null;
                        },
                      ),
                      if (_isLogin) ...[
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _isLoading ? null : _resetPassword,
                            child: const Text(
                              'Şifremi unuttum',
                              style: TextStyle(
                                color: brandOrange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ] else
                        const SizedBox(height: 24),

                      // Submit button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child:
                            _isLoading
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : Text(
                                  _isLogin ? 'Giriş Yap' : 'Kayıt Ol',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),
                      const SizedBox(height: 16),

                      // Toggle between signin/signup
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLogin = !_isLogin;
                            _formKey.currentState?.reset();
                          });
                        },
                        child: Text(
                          _isLogin
                              ? 'Hesabınız yok mu? Hemen kayıt olun'
                              : 'Zaten hesabınız var mı? Giriş yapın',
                          style: const TextStyle(
                            color: brandOrange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _isLogin
                            ? 'Giriş yapmadan önce Kullanım Şartları ve KVKK aydınlatma metnini inceleyebilirsiniz.'
                            : 'Kayıt olmadan önce Kullanım Şartları ve KVKK aydınlatma metnini inceleyebilirsiniz.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 4,
                        runSpacing: 0,
                        children: [
                          _buildLegalLink(
                            'KVKK/Gizlilik',
                            LegalConfig.privacyPath,
                          ),
                          _buildLegalLink('Şartlar', LegalConfig.termsPath),
                          _buildLegalLink(
                            'Veri Silme',
                            LegalConfig.dataDeletionPath,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegalLink(String label, String routePath) {
    return TextButton(
      onPressed: () => AppRouter.push(context, routePath),
      style: TextButton.styleFrom(
        foregroundColor: brandOrange,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: const Size(0, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
      ),
    );
  }
}

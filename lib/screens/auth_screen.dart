import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitrinx/config/legal_config.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/services/auth_service.dart';
import 'package:vitrinx/services/local_storage_keys.dart';
import 'package:vitrinx/theme/app_colors.dart';
import 'package:vitrinx/config/app_router.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _isLogin = false; // Varsayılan: Hesap Oluştur
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _showConfirmationScreen = false;
  String _confirmationEmail = '';
  bool _isResending = false;

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

    try {
      final email = _emailCtrl.text.trim();
      final password = _passwordCtrl.text;

      if (_isLogin) {
        await authService.signIn(email, password);
        // Handle post-auth routing and linking
        await _handlePostAuthentication();
      } else {
        final response = await authService.signUp(email, password);
        // E-posta onayı gerekiyor mu kontrol et
        if (response.session == null && response.user != null) {
          // Onay e-postası gönderildi — onay ekranını göster
          if (mounted) {
            setState(() {
              _showConfirmationScreen = true;
              _confirmationEmail = email;
            });
          }
          return;
        }
        // Otomatik giriş yapıldıysa (email onayı kapalıysa)
        await _handlePostAuthentication();
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      _showError(_translateAuthError(e));
    } catch (e) {
      if (!mounted) return;
      _showError('Beklenmeyen bir hata oluştu: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendConfirmationEmail() async {
    if (_isResending) return;
    setState(() => _isResending = true);

    try {
      await Supabase.instance.client.auth.resend(
        email: _confirmationEmail,
        type: OtpType.signup,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Onay e-postası tekrar gönderildi.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('E-posta tekrar gönderilemedi: $e');
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _handlePostAuthentication() async {
    final authService = const AuthService();
    final prefs = await SharedPreferences.getInstance();

    // 1. Check for local edit tokens and link them if present
    final localStoreToken = prefs.getString(LocalStorageKeys.storeEditToken);
    final localVitrinToken = prefs.getString(LocalStorageKeys.vitrinEditToken);

    bool linked = false;
    if (localStoreToken != null && localStoreToken.isNotEmpty) {
      linked = await authService.linkAnonymousStore(localStoreToken);
    } else if (localVitrinToken != null && localVitrinToken.isNotEmpty) {
      linked = await authService.linkAnonymousStore(localVitrinToken);
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
    final StoreData? store = await authService.getStoreForCurrentUser();

    if (!mounted) return;

    if (store != null) {
      // Cache details in SharedPreferences and redirect to the appropriate editor screen
      if (store.isStore) {
        // isStore: true olan hesaplar için Store editor ekranı
        // planlanmaktadır. Şimdilik token kaydedilip LandingScreen'e
        // yönlendirilmektedir.
        await prefs.setString(
          LocalStorageKeys.storeData,
          jsonEncode(store.toJson()),
        );

        if (!mounted) return;

        // Fetch and cache the edit token for the store to ensure smooth editor integration
        final editToken = await authService.getEditTokenForCurrentUser();

        if (!mounted) return;

        if (editToken != null) {
          await prefs.setString(
            LocalStorageKeys.storeEditToken,
            editToken,
          );
          // Controller'ın okuyacağı key'lere de yaz
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

        if (!mounted) return;

        AppRouter.navigateToLanding(context);
      } else {
        await prefs.setString(
          LocalStorageKeys.vitrinData,
          jsonEncode(store.toJson()),
        );

        if (!mounted) return;

        final editToken = await authService.getEditTokenForCurrentUser();

        if (!mounted) return;

        if (editToken != null) {
          await prefs.setString(
            LocalStorageKeys.vitrinEditToken,
            editToken,
          );
          // Controller'ın okuyacağı key'lere de yaz
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

        if (!mounted) return;

        AppRouter.navigateToHomeShell(context, initialIndex: 1);
      }
    } else {
      // No store found, go back to LandingScreen which will let them create one
      AppRouter.navigateToLanding(context);
    }
  }

  String _translateAuthError(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials')) {
      return 'E-posta adresi veya şifre hatalı. E-postanızı onayladıysanız tekrar deneyin.';
    }
    if (msg.contains('user already exists')) {
      return 'Bu e-posta adresiyle kayıtlı bir kullanıcı zaten var.';
    }
    if (msg.contains('invalid email')) {
      return 'Geçersiz bir e-posta adresi girdiniz.';
    }
    if (msg.contains('password is too short')) {
      return 'Şifre en az 6 karakter olmalıdır.';
    }
    if (msg.contains('email not confirmed') || msg.contains('not confirmed')) {
      return 'E-posta adresiniz henüz onaylanmadı. Lütfen gelen kutunuzu kontrol edin.';
    }
    return 'Giriş yapılamadı: ${e.message}';
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

  Widget _buildConfirmationScreen() {
    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        title: const Text(
          'E-posta Onayı',
          style: TextStyle(
            color: darkAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: darkAccent),
          onPressed: () => setState(() {
            _showConfirmationScreen = false;
            _isLogin = true;
          }),
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // E-posta ikonu
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: brandOrange.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mark_email_read_rounded,
                        color: brandOrange,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Başlık
                    const Text(
                      'E-postanızı kontrol edin',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: darkAccent,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Açıklama
                    Text(
                      'Hesabınızı onaylamak için $_confirmationEmail adresine bir e-posta gönderdik.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'E-postadaki onay bağlantısına tıklayarak giriş yapabilirsiniz.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Tekrar gönder butonu
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isResending ? null : _resendConfirmationEmail,
                        icon: _isResending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.refresh_rounded, size: 20),
                        label: Text(
                          _isResending ? 'Gönderiliyor...' : 'E-postayı tekrar gönder',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Giriş yap butonu
                    TextButton(
                      onPressed: () => setState(() {
                        _showConfirmationScreen = false;
                        _isLogin = true;
                      }),
                      child: const Text(
                        'Giriş yap sayfasına dön',
                        style: TextStyle(
                          color: darkAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Onay ekranı gösteriliyorsa
    if (_showConfirmationScreen) {
      return _buildConfirmationScreen();
    }

    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        title: Text(
          _isLogin ? 'Giriş Yap' : 'Hesap Oluştur',
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
                            'VitrinX',
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
                                  _isLogin ? 'Giriş Yap' : 'Hesap Oluştur',
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
                              ? 'Hesabınız yok mu? Hemen oluşturun'
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
                            : 'Hesap oluşturmadan önce Kullanım Şartları ve KVKK aydınlatma metnini inceleyebilirsiniz.',
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

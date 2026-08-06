import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:vixrex/config/public_site_config.dart';
import 'package:vixrex/services/recaptcha_token_bridge_stub.dart'
    if (dart.library.html) 'package:vixrex/services/recaptcha_token_bridge_web.dart';

class RecaptchaService {
  static final RecaptchaService instance = RecaptchaService._();
  RecaptchaService._();

  final Map<String, ({String token, DateTime expiresAt})> _cache = {};

  Future<String?> getToken({String action = 'submit'}) async {
    if (!kIsWeb) return null;

    final normalizedAction = action.trim();
    if (normalizedAction.isEmpty) return null;

    final cached = _cache[normalizedAction];
    if (cached != null && DateTime.now().isBefore(cached.expiresAt)) {
      return cached.token;
    }

    try {
      // İKİNCİ EMNİYET. Asıl süre sınırı web/index.html içindeki köprüde
      // (3 sn). Burası köprünün kendisi hiç cevap vermezse devreye girer —
      // fiş alma işlemi giriş akışının önünde ASLA duramaz.
      final token = await requestRecaptchaToken(normalizedAction).timeout(
        const Duration(seconds: 4),
        onTimeout: () => null,
      );
      if (token != null && token.isNotEmpty) {
        _cache[normalizedAction] = (
          token: token,
          expiresAt: DateTime.now().add(const Duration(minutes: 1)),
        );
        return token;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[reCAPTCHA] Token alınamadı: $e');
      }
    }
    return null;
  }

  void clearCache() {
    _cache.clear();
  }

  static Future<bool> verifyOnBackend(
    String token, {
    String action = 'submit',
  }) async {
    try {
      final response = await http.post(
        Uri.parse(PublicSiteConfig.buildPublicLink('/api/verify-recaptcha')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token, 'action': action}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[reCAPTCHA] Backend doğrulama hatası: $e');
      }
    }
    return false;
  }
}

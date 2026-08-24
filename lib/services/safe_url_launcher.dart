import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Güvenli URL açma — yalnız izinli scheme'leri geçirir.
///
/// V-49 Fix: Flutter web'de `javascript:` URI'leri çalıştırılabiliyordu.
/// Bu fonksiyon scheme'i doğrular, sadece güvenli scheme'leri geçirir.
enum LaunchScheme {
  http('http'),
  https('https'),
  mailto('mailto'),
  tel('tel'),
  sms('sms'),
  geo('geo'),
  intent('intent'); // Android

  const LaunchScheme(this.value);
  final String value;

  static const Set<String> allowed = {
    'http',
    'https',
    'mailto',
    'tel',
    'sms',
    'geo',
    'intent',
  };

  static bool isAllowed(String scheme) {
    return allowed.contains(scheme.toLowerCase());
  }
}

/// URL'i güvenli şekilde açar.
/// - Scheme kontrolü yapar (javascript:, data:, vb. engeller)
/// - Platform uygun modda açar (web: externalApplication, mobil: platformDefault)
/// - Hata durumunda sessizce başarısız olur (throw etmez)
Future<bool> safeLaunchUrl(
  String url, {
  LaunchMode? webMode,
  LaunchMode? nativeMode,
}) async {
  final uri = Uri.tryParse(url);
  if (uri == null) {
    if (kDebugMode) debugPrint('[safeLaunchUrl] Invalid URI: $url');
    return false;
  }

  // Scheme validation — javascript:, data:, file:, vb. engelle
  if (!LaunchScheme.isAllowed(uri.scheme)) {
    if (kDebugMode) debugPrint('[safeLaunchUrl] Blocked scheme: ${uri.scheme} for $url');
    return false;
  }

  // URL validation — localhost/private IP engelle (SSRF koruması)
  if (uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https')) {
    if (!_isSafeHost(uri.host)) {
      if (kDebugMode) debugPrint('[safeLaunchUrl] Blocked unsafe host: ${uri.host}');
      return false;
    }
  }

  try {
    final mode = kIsWeb
        ? (webMode ?? LaunchMode.externalApplication)
        : (nativeMode ?? LaunchMode.platformDefault);

    return await launchUrl(uri, mode: mode);
  } catch (e) {
    if (kDebugMode) debugPrint('[safeLaunchUrl] Launch failed: $e');
    return false;
  }
}

/// Host güvenlik kontrolü — localhost/private IP engelle
bool _isSafeHost(String host) {
  final lower = host.toLowerCase();

  // Localhost variations
  if (lower == 'localhost' || lower == 'localhost.localdomain') return false;
  if (lower.startsWith('127.')) return false; // 127.0.0.0/8
  if (lower == '::1') return false; // IPv6 localhost

  // Private IP ranges (RFC 1918)
  if (lower.startsWith('10.')) return false; // 10.0.0.0/8
  if (lower.startsWith('172.') &&
      (int.tryParse(lower.split('.')[1]) ?? 0) >= 16 &&
      (int.tryParse(lower.split('.')[1]) ?? 0) <= 31) {
    return false; // 172.16.0.0/12
  }
  if (lower.startsWith('192.168.')) return false; // 192.168.0.0/16

  // Link-local (169.254.0.0/16)
  if (lower.startsWith('169.254.')) return false;

  // Private IPv6 (fc00::/7)
  if (lower.startsWith('fc') || lower.startsWith('fd')) return false;

  return true;
}

/// Eski kodla uyumluluk için — aynı imza, güvenli versiyon
Future<void> openChatUrl(String url) async {
  await safeLaunchUrl(url);
}
import 'dart:math';

/// VitrinX için güvenli edit token üreteci.
///
/// Token'lar 24 karakterlik küçük harf + rakam dizisidir.
/// Hem store hem vitrin akışlarında kullanılır.
abstract final class TokenGenerator {
  static const int _tokenLength = 24;
  static const String _chars =
      'abcdefghijklmnopqrstuvwxyz0123456789';

  /// 24 karakterlik rastgele bir edit token üretir.
  ///
  /// Örnek: `'k3pqx7mznb9c2rwtf8hyvd4j'`
  static String generate() {
    final random = Random.secure();
    return List.generate(
      _tokenLength,
      (_) => _chars[random.nextInt(_chars.length)],
    ).join();
  }
}

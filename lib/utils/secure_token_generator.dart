import 'dart:math';

/// Güvenli, rastgele 24+ karakterlik token üretir.
/// Supabase RPC'nin minimum 24 karakter şartını karşılar.
class SecureTokenGenerator {
  static final _random = Random.secure();

  /// UUID formatında 36 karakterlik token üretir.
  /// Örnek: "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
  static String generateUuid() {
    return '${_hex(8)}-${_hex(4)}-4${_hex(3)}-${_variantHex()}-${_hex(12)}';
  }

  /// Basit 24 karakterlik token (UUID yerine alternatif).
  static String generateSimple() {
    return _hex(24);
  }

  static String _hex(int length) {
    const chars = '0123456789abcdef';
    return List.generate(length, (_) => chars[_random.nextInt(16)]).join();
  }

  static String _variantHex() {
    const chars = '89ab';
    return '${chars[_random.nextInt(4)]}${_hex(3)}';
  }
}

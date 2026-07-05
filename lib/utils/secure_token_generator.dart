import 'dart:math';

/// Guvenli, rastgele 24+ karakterlik token uretir.
/// Supabase RPC'nin minimum 24 karakter sartin karsilar.
class SecureTokenGenerator {
  static final _random = Random.secure();

  /// UUID formatinda 36 karakterlik token uretir.
  /// Ornek: "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
  static String generateUuid() {
    return '${_hex(8)}-${_hex(4)}-4${_hex(3)}-${_variantHex()}-${_hex(12)}';
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

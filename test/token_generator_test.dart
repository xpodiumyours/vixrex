import 'package:flutter_test/flutter_test.dart';
import 'package:vitrinx/utils/token_generator.dart';

void main() {
  group('TokenGenerator', () {
    test('generate() returns 24-character string', () {
      final token = TokenGenerator.generate();
      expect(token.length, 24);
    });

    test('generate() contains only lowercase letters and digits', () {
      final token = TokenGenerator.generate();
      final validChars = RegExp(r'^[a-z0-9]+$');
      expect(validChars.hasMatch(token), isTrue,
          reason: 'Token "$token" içinde geçersiz karakter var');
    });

    test('generate() produces different tokens each call', () {
      final tokens = List.generate(20, (_) => TokenGenerator.generate());
      final unique = tokens.toSet();
      // 20 çağrıda en az 18 benzersiz token olmalı
      expect(unique.length, greaterThan(18));
    });

    test('generate() never produces empty string', () {
      for (var i = 0; i < 10; i++) {
        expect(TokenGenerator.generate().isNotEmpty, isTrue);
      }
    });
  });
}

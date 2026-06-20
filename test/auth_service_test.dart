import 'package:flutter_test/flutter_test.dart';
import 'package:vitrinx/services/auth_service.dart';

void main() {
  group('AuthService hesap silme doğrulaması', () {
    test('yalnızca tam SİL metnini kabul eder', () {
      expect(AuthService.isDeleteConfirmationValid('SİL'), isTrue);
      expect(AuthService.isDeleteConfirmationValid('  SİL  '), isTrue);
      expect(AuthService.isDeleteConfirmationValid('sil'), isFalse);
      expect(AuthService.isDeleteConfirmationValid('SIL'), isFalse);
      expect(AuthService.isDeleteConfirmationValid(''), isFalse);
    });

    test('aktif oturum yoksa hesap silme başarısız olur', () async {
      await expectLater(
        const AuthService().deleteAccount(),
        throwsA(isA<StateError>()),
      );
    });
  });
}

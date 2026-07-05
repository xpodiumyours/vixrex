import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/utils/app_error_guard.dart';

void main() {
  group('AppErrorGuard.run', () {
    test('returns correct value on successful action', () async {
      final result = await AppErrorGuard.run<int>(
        action: () async => 42,
        fallback: 0,
        label: 'test_success',
      );

      expect(result, 42);
    });

    test('returns fallback value on failing action', () async {
      final result = await AppErrorGuard.run<int>(
        action: () async => throw Exception('Some DB error'),
        fallback: 100,
        label: 'test_failure',
      );

      expect(result, 100);
    });

    test('calls onError callback on exception', () async {
      Object? capturedError;
      StackTrace? capturedStack;

      final result = await AppErrorGuard.run<String>(
        action: () async => throw StateError('Failed state'),
        fallback: 'fallback_val',
        label: 'test_onerror',
        onError: (err, stack) {
          capturedError = err;
          capturedStack = stack;
        },
      );

      expect(result, 'fallback_val');
      expect(capturedError, isA<StateError>());
      expect(capturedStack, isNotNull);
    });

    test('completes safely with void action', () async {
      var executed = false;
      await AppErrorGuard.run<void>(
        action: () async {
          executed = true;
          throw Exception('Void action error');
        },
        fallback: null,
        label: 'test_void',
      );

      expect(executed, isTrue);
    });
  });
}

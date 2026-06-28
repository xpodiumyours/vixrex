import 'package:flutter/foundation.dart';

class AppErrorGuard {
  const AppErrorGuard._();

  static Future<T> run<T>({
    required Future<T> Function() action,
    required T fallback,
    String? label,
    void Function(Object error, StackTrace stack)? onError,
  }) async {
    try {
      return await action();
    } catch (error, stack) {
      debugPrint('[AppErrorGuard] Error in ${label ?? 'action'}: $error');
      if (onError != null) {
        onError(error, stack);
      }
      return fallback;
    }
  }
}

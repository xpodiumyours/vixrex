import 'package:flutter/foundation.dart';

class Failure implements Exception {
  final String message;
  final StackTrace? stackTrace;
  final DateTime timestamp;

  Failure(this.message, {this.stackTrace}) : timestamp = DateTime.now() {
    if (kDebugMode) {
      // Automatic debug telemetry logger
      print('--- FAILURE LOG ---');
      print('Timestamp: $timestamp');
      print('Error: $message');
      if (stackTrace != null) {
        print('StackTrace:\n$stackTrace');
      }
      print('--------------------');
    }
  }

  @override
  String toString() => message;
}

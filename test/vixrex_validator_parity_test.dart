import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_field_validator.dart';

void main() {
  final raw =
      jsonDecode(
            File(
              'shared/vixrex_validator_parity_fixtures.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final fixtures = (raw['validator'] as List).cast<Map<String, dynamic>>();

  group('Vixrex validator shared parity fixtures — Flutter', () {
    for (final fixture in fixtures) {
      test(fixture['id'] as String, () {
        final result = VixrexFieldValidator.validateByKey(
          fixture['fieldKey'] as String,
          fixture['input'],
        );

        expect(result.ok, fixture['expectedOk'] as bool);
        if (fixture['expectedOk'] == true) {
          expect(result.normalizedDeger, fixture['expectedValue']);
        }
      });
    }
  });
}

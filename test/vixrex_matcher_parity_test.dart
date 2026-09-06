import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_intent_resolver.dart';

void main() {
  final raw =
      jsonDecode(
            File('shared/vixrex_motor_parity_fixtures.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
  final fixtures = (raw['matcher'] as List).cast<Map<String, dynamic>>();
  const resolver = VixrexIntentResolver();

  group('Vixrex matcher shared parity fixtures — Flutter', () {
    for (final fixture in fixtures) {
      test(fixture['id'] as String, () {
        final matches = resolver.resolveMatches(fixture['input'] as String);
        final expectedFields =
            (fixture['expectedFieldKeys'] as List).cast<String>();
        final expectedClasses =
            (fixture['expectedMatchClasses'] as List).cast<String>();

        expect(
          matches.map((match) => match.alan.anahtar).toList(),
          expectedFields,
        );
        expect(
          matches.map((match) => match.matchClass).toList(),
          expectedClasses,
        );
      });
    }
  });
}

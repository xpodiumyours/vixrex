import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/services/vixrex_blog_intent.dart';

void main() {
  final raw = jsonDecode(
    File('shared/vixrex_blog_intent_fixtures.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final fixtures = (raw['cases'] as List).cast<Map<String, dynamic>>();

  String domainName(VixrexAssistantDomain domain) => domain.name;

  group('Vixrex Blog domain shared parity fixtures — Flutter', () {
    for (final fixture in fixtures) {
      test(fixture['id'] as String, () {
        final result = routeVixrexAssistantDomain(fixture['input'] as String);
        expect(domainName(result.domain), fixture['domain']);
        final expectedIntent = fixture['intent'] as String?;
        expect(
          result.intent == null ? null : vixrexBlogIntentWireName(result.intent!),
          expectedIntent,
        );
      });
    }
  });
}

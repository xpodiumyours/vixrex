import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/models/assistant_handoff.dart';

void main() {
  test(
    'assistant_handoff_v1 yalnız sınırlı ve güvenli görünür özeti taşır',
    () {
      final handoff = AssistantHandoffV1(
        completedSteps: const [
          AssistantHandoffStep.name,
          AssistantHandoffStep.name,
          AssistantHandoffStep.category,
          AssistantHandoffStep.done,
        ],
        nextStep: AssistantHandoffStep.done,
        messages: [
          const AssistantHandoffMessage.user('   '),
          const AssistantHandoffMessage.user('ocode=bu-mesaj-gitmemeli'),
          for (var index = 0; index < 30; index++)
            AssistantHandoffMessage.user('Görünür mesaj $index'),
          AssistantHandoffMessage.assistant('a' * 520),
        ],
      );

      final json = handoff.toJson();
      final messages = json['messages']! as List<Map<String, String>>;

      expect(json['version'], 1);
      expect(json['completed_steps'], ['name', 'category']);
      expect(json['next_step'], 'done');
      expect(messages, hasLength(24));
      expect(messages.first['text'], 'Görünür mesaj 7');
      expect(messages.last['text'], 'a' * 500);
      expect(
        messages.any((message) => message['text']!.contains('ocode=')),
        isFalse,
      );
      expect(
        messages.every((message) => message['text']!.length <= 500),
        isTrue,
      );
    },
  );

  test('çok baytlı mesajlarda CORE 16 KiB sınırını aşmaz', () {
    final handoff = AssistantHandoffV1(
      completedSteps: const [AssistantHandoffStep.name],
      nextStep: AssistantHandoffStep.category,
      messages: [
        for (var index = 0; index < 24; index++)
          AssistantHandoffMessage.user('🧿' * 500),
      ],
    );

    final encodedSize = utf8.encode(jsonEncode(handoff.toJson())).length;

    expect(encodedSize, lessThanOrEqualTo(16384));
    expect(handoff.messages, isNotEmpty);
  });
}

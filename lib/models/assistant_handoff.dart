import 'dart:convert';

enum AssistantHandoffStep {
  name,
  category,
  whatsapp,
  location,
  legal,
  publishing,
  done,
}

enum AssistantHandoffRole { assistant, user }

class AssistantHandoffMessage {
  const AssistantHandoffMessage.assistant(this.text)
    : role = AssistantHandoffRole.assistant;

  const AssistantHandoffMessage.user(this.text)
    : role = AssistantHandoffRole.user;

  const AssistantHandoffMessage._normalized(this.role, this.text);

  final AssistantHandoffRole role;
  final String text;

  Map<String, String> toJson() => {'role': role.name, 'text': text};
}

class AssistantHandoffV1 {
  static const _clientEnvelopeLimitBytes = 14 * 1024;

  AssistantHandoffV1({
    required List<AssistantHandoffStep> completedSteps,
    required this.nextStep,
    required List<AssistantHandoffMessage> messages,
  }) : completedSteps = List.unmodifiable(
         _normalizeCompletedSteps(completedSteps),
       ),
       messages = List.unmodifiable(_normalizeMessages(messages));

  factory AssistantHandoffV1.completedOnboarding({
    required Iterable<AssistantHandoffMessage> visibleMessages,
  }) {
    final messages = visibleMessages.toList();
    final recentMessages =
        messages.length <= 6 ? messages : messages.sublist(messages.length - 6);
    return AssistantHandoffV1(
      completedSteps: const [
        AssistantHandoffStep.name,
        AssistantHandoffStep.category,
        AssistantHandoffStep.whatsapp,
        AssistantHandoffStep.location,
        AssistantHandoffStep.legal,
        AssistantHandoffStep.publishing,
      ],
      nextStep: AssistantHandoffStep.done,
      messages: recentMessages,
    );
  }

  final List<AssistantHandoffStep> completedSteps;
  final AssistantHandoffStep nextStep;
  final List<AssistantHandoffMessage> messages;

  Map<String, Object?> toJson() => {
    'version': 1,
    'completed_steps': completedSteps.map((step) => step.name).toList(),
    'next_step': nextStep.name,
    'messages': messages.map((message) => message.toJson()).toList(),
  };

  static List<AssistantHandoffStep> _normalizeCompletedSteps(
    Iterable<AssistantHandoffStep> input,
  ) {
    final normalized = <AssistantHandoffStep>[];
    for (final step in input) {
      if (step == AssistantHandoffStep.done || normalized.contains(step)) {
        continue;
      }
      normalized.add(step);
      if (normalized.length == 6) break;
    }
    return normalized;
  }

  static List<AssistantHandoffMessage> _normalizeMessages(
    Iterable<AssistantHandoffMessage> input,
  ) {
    final normalized = <AssistantHandoffMessage>[];
    for (final message in input) {
      final text = message.text.trim();
      if (text.isEmpty || _forbiddenSecretPattern.hasMatch(text)) continue;
      normalized.add(
        AssistantHandoffMessage._normalized(
          message.role,
          String.fromCharCodes(text.runes.take(500)),
        ),
      );
    }
    final bounded =
        normalized.length <= 24
            ? List<AssistantHandoffMessage>.of(normalized)
            : normalized.sublist(normalized.length - 24);
    // CORE 16 KiB sınırına varmadan durur; PostgreSQL jsonb metin
    // serileştirmesindeki olası boşluklar için 2 KiB güvenlik payı bırakır.
    while (bounded.isNotEmpty &&
        _maximumEnvelopeSize(bounded) > _clientEnvelopeLimitBytes) {
      bounded.removeAt(0);
    }
    return bounded;
  }

  static int _maximumEnvelopeSize(List<AssistantHandoffMessage> messages) {
    final envelope = <String, Object?>{
      'version': 1,
      'completed_steps': const [
        'name',
        'category',
        'whatsapp',
        'location',
        'legal',
        'publishing',
      ],
      'next_step': 'publishing',
      'messages': messages.map((message) => message.toJson()).toList(),
    };
    return utf8.encode(jsonEncode(envelope)).length;
  }
}

final RegExp _forbiddenSecretPattern = RegExp(
  r'(edit_token|session_token|ocode)\s*[:=]',
  caseSensitive: false,
);

import 'package:flutter/material.dart';

/// Xrex chatbot mesaj modeli.
class ChatMessage {
  final String id;
  final String text;
  final bool isBot;
  final DateTime timestamp;
  final List<QuickReply> quickReplies;
  final ChatMessageType type;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isBot,
    required this.timestamp,
    this.quickReplies = const [],
    this.type = ChatMessageType.text,
  });

  factory ChatMessage.bot(
    String text, {
    List<QuickReply> quickReplies = const [],
    ChatMessageType type = ChatMessageType.text,
  }) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isBot: true,
      timestamp: DateTime.now(),
      quickReplies: quickReplies,
      type: type,
    );
  }

  factory ChatMessage.user(String text) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isBot: false,
      timestamp: DateTime.now(),
    );
  }
}

enum ChatMessageType { text, loading, system }

/// Hızlı cevap butonu modeli.
@immutable
class QuickReply {
  final String label;
  final String payload;

  const QuickReply({required this.label, required this.payload});
}

import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/models/chat_message.dart';

/// Flutter ve Next.js'in kullandığı tek Vixrex konuşmasının veri sınırı.
/// SharedPreferences yalnız çevrimdışı önbellektir; kanonik geçmiş Supabase'tir.
class VixrexConversationRepository {
  const VixrexConversationRepository({SupabaseClient? client})
    : _client = client;

  final SupabaseClient? _client;

  SupabaseClient? get _resolvedClient {
    if (_client != null) return _client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  SupabaseClient? get _persistentAccountClient {
    final client = _resolvedClient;
    final user = client?.auth.currentUser;
    if (user == null || user.isAnonymous) return null;
    return client;
  }

  bool get canSync => _persistentAccountClient != null;

  Future<Map<String, dynamic>?> _conversation() async {
    final client = _persistentAccountClient;
    if (client == null) return null;
    final raw = await client.rpc('get_assistant_conversation');
    if (raw is! Map) return null;
    return Map<String, dynamic>.from(raw);
  }

  /// Kanonik pending state'i doğrudan mevcut güvenli RPC'den okur.
  /// Anonymous/oturumsuz Flutter hesapları remote pending kullanmaz.
  Future<Map<String, dynamic>?> loadPendingSlot() async {
    final client = _persistentAccountClient;
    if (client == null) return null;
    final raw = await client.rpc('get_assistant_pending_slot');
    if (raw == null) return null;
    if (raw is! Map) {
      throw const FormatException('INVALID_PENDING_SLOT_RESPONSE');
    }
    return Map<String, dynamic>.from(raw);
  }

  /// Kanonik pending state'i yazar. `null` remote pending'i temizler.
  Future<void> savePendingSlot(Map<String, dynamic>? slot) async {
    final client = _persistentAccountClient;
    if (client == null) {
      throw StateError('PERSISTENT_ACCOUNT_REQUIRED');
    }
    await client.rpc('set_assistant_pending_slot', params: {'p_slot': slot});
  }

  Future<List<ChatMessage>> loadMessages() async {
    final conversation = await _conversation();
    final rawMessages = conversation?['messages'];
    if (rawMessages is! List) return [];

    return rawMessages
        .whereType<Map>()
        .map((raw) => _messageFromRow(Map<String, dynamic>.from(raw)))
        .toList(growable: false);
  }

  ChatMessage _messageFromRow(Map<String, dynamic> row) {
    final snapshot = row['catalog_snapshot'];
    if (snapshot is String && snapshot.trimLeft().startsWith('{')) {
      try {
        final decoded = jsonDecode(snapshot);
        if (decoded is Map) {
          return ChatMessage.fromJson(Map<String, dynamic>.from(decoded));
        }
      } catch (_) {
        // Next.js metin snapshot'ları veya eski kayıtlar aşağıda normalize edilir.
      }
    }

    final createdAt = DateTime.tryParse('${row['created_at'] ?? ''}');
    final clientMessageId = row['client_message_id']?.toString().trim();
    return ChatMessage(
      id:
          clientMessageId == null || clientMessageId.isEmpty
              ? row['id'].toString()
              : clientMessageId,
      text: row['message_text']?.toString() ?? '',
      isBot: row['role'] == 'assistant',
      timestamp: createdAt ?? DateTime.now(),
      snapshotStateKey: row['message_key']?.toString(),
    );
  }

  Future<void> syncMessages(List<ChatMessage> messages) async {
    final client = _persistentAccountClient;
    if (client == null || messages.isEmpty) return;
    final conversation = await _conversation();
    final conversationId = conversation?['id']?.toString();
    if (conversationId == null || conversationId.isEmpty) return;

    for (final message in messages) {
      final clientMessageId =
          message.id.startsWith('next-') || message.id.startsWith('flutter-')
              ? message.id
              : 'flutter-${message.id}';
      await client.rpc(
        'append_assistant_message',
        params: {
          'p_conversation_id': conversationId,
          'p_client_message_id': clientMessageId,
          'p_role': message.isBot ? 'assistant' : 'user',
          'p_message_key': message.snapshotStateKey,
          'p_message_text': message.text,
          'p_catalog_snapshot': jsonEncode(message.toJson()),
        },
      );
    }
  }
}

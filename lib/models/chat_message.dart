import 'package:flutter/material.dart';

/// VixRex chatbot mesaj modeli.
class ChatMessage {
  final String id;
  final String text;
  final bool isBot;
  final DateTime timestamp;
  final List<QuickReply> quickReplies;
  final ChatMessageType type;

  /// Snapshot tabanlı mesajsa durumu tutar (gereksiz tekrarları önlemek için).
  final String? snapshotStateKey;

  /// Geriye uyumluluk için eski puan.
  final int? snapshotScore;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isBot,
    required this.timestamp,
    this.quickReplies = const [],
    this.type = ChatMessageType.text,
    this.snapshotStateKey,
    this.snapshotScore,
  });

  factory ChatMessage.bot(
    String text, {
      List<QuickReply> quickReplies = const [],
      ChatMessageType type = ChatMessageType.text,
      String? snapshotStateKey,
      int? snapshotScore,
    }) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isBot: true,
      timestamp: DateTime.now(),
      quickReplies: quickReplies,
      type: type,
      snapshotStateKey: snapshotStateKey,
      snapshotScore: snapshotScore,
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'isBot': isBot,
        'timestamp': timestamp.toIso8601String(),
        'type': type.name,
        'snapshotStateKey': snapshotStateKey,
        'snapshotScore': snapshotScore,
        'quickReplies': quickReplies.map((r) => r.toJson()).toList(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final repliesJson = json['quickReplies'] as List<dynamic>? ?? [];
    return ChatMessage(
      id: json['id'] as String,
      text: json['text'] as String,
      isBot: json['isBot'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: ChatMessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ChatMessageType.text,
      ),
      snapshotStateKey: json['snapshotStateKey'] as String?,
      snapshotScore: json['snapshotScore'] as int?,
      quickReplies: repliesJson
          .map((r) => QuickReply.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}

enum ChatMessageType { text, loading, system }

// ─── Type-safe VixRex Aksiyonları ──────────────────────────────────────────────
/// Quick Reply butonlarının tetikleyebileceği navigasyon aksiyonları.
enum VixRexAction {
  openVitrim,           // Vitrinim sekmesine git
  copyLink,             // Public linki panoya kopyala
  shareWhatsapp,        // WhatsApp paylaşım ekranı
  showQr,               // QR bottom sheet
  openExplore,          // Keşfet sekmesi
  scrollToCover,        // Kapak fotoğrafına git
  scrollToGallery,      // Galeriye git
  scrollToName,         // İşletme adına git
  scrollToWhatsapp,     // WhatsApp alanına git
  scrollToAddress,      // Adrese git
  scrollToLegal,        // Yasal onaylara git
  scrollToDesc,         // Açıklamaya git
  scrollToProducts,     // Ürün/Hizmet alanına git
  scrollToCategory,     // Kategori seçim alanına git
  openCoverTemplatePicker, // Hazır kapak şablonu seç
  openOcrScanner,      // OCR tarama ekranını aç
  none,                      // Sadece mesaj tetikler, navigasyon yok
}

/// Hızlı cevap butonu modeli.
@immutable
class QuickReply {
  final String label;
  final String payload;

  /// Aksiyona yönlendirme için type-safe alan.
  /// Default [VixRexAction.none] — geriye uyumlu.
  final VixRexAction action;

  const QuickReply({
    required this.label,
    required this.payload,
    this.action = VixRexAction.none,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'payload': payload,
        'action': action.name,
      };

  factory QuickReply.fromJson(Map<String, dynamic> json) {
    return QuickReply(
      label: json['label'] as String,
      payload: json['payload'] as String,
      action: VixRexAction.values.firstWhere(
        (e) => e.name == json['action'],
        orElse: () => VixRexAction.none,
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Xrex chatbot mesaj modeli.
class ChatMessage {
  final String id;
  final String text;
  final bool isBot;
  final DateTime timestamp;
  final List<QuickReply> quickReplies;
  final ChatMessageType type;

  /// Snapshot tabanlı mesajsa skor çubuğu gösterilir.
  final int? snapshotScore;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isBot,
    required this.timestamp,
    this.quickReplies = const [],
    this.type = ChatMessageType.text,
    this.snapshotScore,
  });

  factory ChatMessage.bot(
    String text, {
    List<QuickReply> quickReplies = const [],
    ChatMessageType type = ChatMessageType.text,
    int? snapshotScore,
  }) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isBot: true,
      timestamp: DateTime.now(),
      quickReplies: quickReplies,
      type: type,
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
}

enum ChatMessageType { text, loading, system }

// ─── Type-safe Xrex Aksiyonları ──────────────────────────────────────────────
/// Quick Reply butonlarının tetikleyebileceği navigasyon aksiyonları.
enum XrexAction {
  openVitrim,       // Vitrinim sekmesine git
  copyLink,         // Public linki panoya kopyala
  shareWhatsapp,    // WhatsApp paylaşım ekranı
  showQr,           // QR bottom sheet
  openExplore,      // Keşfet sekmesi
  scrollToCover,    // Kapak fotoğrafına git
  scrollToGallery,  // Galeriye git
  scrollToName,     // İşletme adına git
  scrollToWhatsapp, // WhatsApp alanına git
  scrollToAddress,  // Adrese git
  scrollToDesc,     // Açıklamaya git
  scrollToProducts, // Ürün/Hizmet alanına git
  none,             // Sadece mesaj tetikler, navigasyon yok
}

/// Hızlı cevap butonu modeli.
@immutable
class QuickReply {
  final String label;
  final String payload;

  /// Aksiyona yönlendirme için type-safe alan.
  /// Default [XrexAction.none] — geriye uyumlu.
  final XrexAction action;

  const QuickReply({
    required this.label,
    required this.payload,
    this.action = XrexAction.none,
  });
}

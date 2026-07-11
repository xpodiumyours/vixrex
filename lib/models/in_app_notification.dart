import 'dart:convert';

/// Uygulama içi bildirim kaydı (randevu olayları).
class InAppNotification {
  final String id;
  final String title;
  final String body;
  final String? storeSlug;
  final String type;
  final DateTime createdAt;
  final bool read;

  const InAppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.storeSlug,
    this.type = 'booking',
    this.read = false,
  });

  InAppNotification copyWith({bool? read}) {
    return InAppNotification(
      id: id,
      title: title,
      body: body,
      storeSlug: storeSlug,
      type: type,
      createdAt: createdAt,
      read: read ?? this.read,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'storeSlug': storeSlug,
        'type': type,
        'createdAt': createdAt.toIso8601String(),
        'read': read,
      };

  factory InAppNotification.fromJson(Map<String, dynamic> json) {
    return InAppNotification(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      storeSlug: json['storeSlug']?.toString(),
      type: (json['type'] ?? 'booking').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      read: json['read'] == true,
    );
  }

  static String encodeList(List<InAppNotification> items) =>
      jsonEncode(items.map((e) => e.toJson()).toList());

  static List<InAppNotification> decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map>()
          .map((e) => InAppNotification.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }
}

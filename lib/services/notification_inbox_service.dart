import 'package:shared_preferences/shared_preferences.dart';
import 'package:vixrex/models/in_app_notification.dart';

/// Yerel bildirim geçmişi (son N kayıt).
class NotificationInboxService {
  const NotificationInboxService();

  static const _inboxKey = 'in_app_notifications_v1';
  static const _seenPendingKeyPrefix = 'seen_pending_appts_';
  static const _maxItems = 50;

  Future<List<InAppNotification>> list() async {
    final prefs = await SharedPreferences.getInstance();
    final items = InAppNotification.decodeList(prefs.getString(_inboxKey));
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<void> add(InAppNotification notification) async {
    final prefs = await SharedPreferences.getInstance();
    final items = InAppNotification.decodeList(prefs.getString(_inboxKey));
    items.insert(0, notification);
    while (items.length > _maxItems) {
      items.removeLast();
    }
    await prefs.setString(_inboxKey, InAppNotification.encodeList(items));
  }

  Future<void> markRead(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final items = InAppNotification.decodeList(prefs.getString(_inboxKey));
    final updated = items
        .map((e) => e.id == id ? e.copyWith(read: true) : e)
        .toList();
    await prefs.setString(_inboxKey, InAppNotification.encodeList(updated));
  }

  Future<void> markAllRead() async {
    final prefs = await SharedPreferences.getInstance();
    final items = InAppNotification.decodeList(prefs.getString(_inboxKey));
    final updated = items.map((e) => e.copyWith(read: true)).toList();
    await prefs.setString(_inboxKey, InAppNotification.encodeList(updated));
  }

  Future<Set<String>> getSeenPendingIds(String storeSlug) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('$_seenPendingKeyPrefix$storeSlug') ?? [];
    return raw.toSet();
  }

  Future<void> setSeenPendingIds(String storeSlug, Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      '$_seenPendingKeyPrefix$storeSlug',
      ids.toList(),
    );
  }
}

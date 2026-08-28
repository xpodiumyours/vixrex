import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/models/in_app_notification.dart';

/// Hesaba bağlı ortak bildirim kutusu (Flutter + web).
///
/// SharedPreferences yalnız eski sürüm kayıtlarını bir kez taşımak ve ağ
/// hatasında veri kaybetmemek için yedektir; asıl kaynak notification_inbox.
class NotificationInboxService {
  const NotificationInboxService();

  static const _inboxKey = 'in_app_notifications_v1';
  static const _seenPendingKeyPrefix = 'seen_pending_appts_';
  static const _maxItems = 50;

  Future<List<InAppNotification>> list() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return _legacyList();
    try {
      await _migrateLegacy(userId);
      final rows = await Supabase.instance.client
          .from('notification_inbox')
          .select('id,title,body,store_slug,type,created_at,read_at')
          .order('created_at', ascending: false)
          .limit(_maxItems);
      return rows.map(_fromRow).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('NotificationInboxService.list: $e');
      return _legacyList();
    }
  }

  Future<void> add(InAppNotification notification) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      try {
        await _migrateLegacy(userId);
        await Supabase.instance.client
            .from('notification_inbox')
            .upsert(_toRow(notification, userId), onConflict: 'user_id,id');
        return;
      } catch (e) {
        if (kDebugMode) debugPrint('NotificationInboxService.add: $e');
      }
    }
    await _addLegacy(notification);
  }

  Future<void> markRead(String id) async {
    try {
      await Supabase.instance.client
          .from('notification_inbox')
          .update({'read_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', id);
    } catch (e) {
      if (kDebugMode) debugPrint('NotificationInboxService.markRead: $e');
      await _markLegacy(id: id);
    }
  }

  Future<void> markAllRead() async {
    final now = DateTime.now().toUtc().toIso8601String();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      await _markLegacy();
      return;
    }
    try {
      await Supabase.instance.client
          .from('notification_inbox')
          .update({'read_at': now})
          .eq('user_id', userId)
          .isFilter('read_at', null);
    } catch (e) {
      if (kDebugMode) debugPrint('NotificationInboxService.markAllRead: $e');
      await _markLegacy();
    }
  }

  Future<List<InAppNotification>> _legacyList() async {
    final prefs = await SharedPreferences.getInstance();
    final items = InAppNotification.decodeList(prefs.getString(_inboxKey));
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<void> _addLegacy(InAppNotification notification) async {
    final prefs = await SharedPreferences.getInstance();
    final items = InAppNotification.decodeList(prefs.getString(_inboxKey));
    items.removeWhere((item) => item.id == notification.id);
    items.insert(0, notification);
    if (items.length > _maxItems) items.removeRange(_maxItems, items.length);
    await prefs.setString(_inboxKey, InAppNotification.encodeList(items));
  }

  Future<void> _markLegacy({String? id}) async {
    final prefs = await SharedPreferences.getInstance();
    final items = InAppNotification.decodeList(prefs.getString(_inboxKey));
    final updated =
        items
            .map(
              (item) =>
                  id == null || item.id == id
                      ? item.copyWith(read: true)
                      : item,
            )
            .toList();
    await prefs.setString(_inboxKey, InAppNotification.encodeList(updated));
  }

  Future<void> _migrateLegacy(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final legacy = InAppNotification.decodeList(prefs.getString(_inboxKey));
    if (legacy.isEmpty) return;
    await Supabase.instance.client
        .from('notification_inbox')
        .upsert(
          legacy.map((item) => _toRow(item, userId)).toList(),
          onConflict: 'user_id,id',
        );
    await prefs.remove(_inboxKey);
  }

  Map<String, dynamic> _toRow(InAppNotification item, String userId) => {
    'user_id': userId,
    'id': item.id,
    'title': item.title,
    'body': item.body,
    'store_slug': item.storeSlug,
    'type': item.type,
    'created_at': item.createdAt.toUtc().toIso8601String(),
    'read_at': item.read ? item.createdAt.toUtc().toIso8601String() : null,
  };

  InAppNotification _fromRow(Map<String, dynamic> row) => InAppNotification(
    id: row['id']?.toString() ?? '',
    title: row['title']?.toString() ?? '',
    body: row['body']?.toString() ?? '',
    storeSlug: row['store_slug']?.toString(),
    type: row['type']?.toString() ?? 'booking',
    createdAt:
        DateTime.tryParse(row['created_at']?.toString() ?? '') ??
        DateTime.now(),
    read: row['read_at'] != null,
  );

  Future<Set<String>> getSeenPendingIds(String storeSlug) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('$_seenPendingKeyPrefix$storeSlug') ?? [];
    return raw.toSet();
  }

  Future<void> setSeenPendingIds(String storeSlug, Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('$_seenPendingKeyPrefix$storeSlug', ids.toList());
  }
}

import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/models/in_app_notification.dart';
import 'package:vixrex/services/notification_inbox_service.dart';
import 'package:vixrex/services/notification_preferences_service.dart';
import 'package:vixrex/services/notification_templates.dart';

typedef NotificationDeepLinkHandler = void Function({
  required String type,
  required String storeSlug,
});

/// OneSignal kimlik + deep link + inbox + sunucu push (Edge Function).
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final _prefs = const NotificationPreferencesService();
  final _inbox = const NotificationInboxService();
  NotificationDeepLinkHandler? _deepLinkHandler;
  bool _clickListenerAttached = false;

  void setDeepLinkHandler(NotificationDeepLinkHandler? handler) {
    _deepLinkHandler = handler;
  }

  void attachClickListener() {
    if (_clickListenerAttached) return;
    _clickListenerAttached = true;
    try {
      OneSignal.Notifications.addClickListener((event) {
        final data = event.notification.additionalData;
        if (data == null) return;
        final type = (data['type'] ?? 'booking').toString();
        final slug = (data['storeSlug'] ?? data['slug'] ?? '').toString();
        if (slug.isEmpty) return;
        _deepLinkHandler?.call(type: type, storeSlug: slug);
      });
    } catch (e) {
      if (kDebugMode) debugPrint('PushNotificationService.clickListener: $e');
    }
  }

  Future<void> loginUser(String userId) async {
    if (userId.trim().isEmpty) return;
    try {
      await OneSignal.login(userId.trim());
    } catch (e) {
      if (kDebugMode) debugPrint('PushNotificationService.loginUser: $e');
    }
  }

  Future<void> logoutUser() async {
    try {
      await OneSignal.logout();
    } catch (e) {
      if (kDebugMode) debugPrint('PushNotificationService.logoutUser: $e');
    }
  }

  /// Randevu durumu değişince inbox + tercihe göre uzak push.
  Future<void> recordBookingStatusChange({
    required String storeSlug,
    required String customerName,
    required String action,
  }) async {
    if (!await _prefs.isBookingPushEnabled()) return;

    final tpl = NotificationTemplates.forBookingAction(
      action: action,
      customerName: customerName,
      storeSlug: storeSlug,
    );

    await _inbox.add(
      InAppNotification(
        id: 'booking-${DateTime.now().microsecondsSinceEpoch}',
        title: tpl.title,
        body: tpl.body,
        storeSlug: storeSlug,
        type: 'booking',
        createdAt: DateTime.now(),
      ),
    );

    await _invokeRemotePush(
      title: tpl.title,
      body: tpl.body,
      storeSlug: storeSlug,
    );
  }

  /// Yeni bekleyen randevular → inbox + push.
  Future<void> recordNewPendingAppointments({
    required String storeSlug,
    required List<Map<String, dynamic>> newAppointments,
  }) async {
    if (newAppointments.isEmpty) return;
    if (!await _prefs.isBookingPushEnabled()) return;

    for (final appt in newAppointments) {
      final name = (appt['customer_name'] ?? 'Müşteri').toString();
      final id = (appt['id'] ?? DateTime.now().microsecondsSinceEpoch)
          .toString();
      final tpl = NotificationTemplates.forBookingAction(
        action: 'pending',
        customerName: name,
        storeSlug: storeSlug,
      );
      await _inbox.add(
        InAppNotification(
          id: 'pending-$id',
          title: tpl.title,
          body: tpl.body,
          storeSlug: storeSlug,
          type: 'booking',
          createdAt: DateTime.now(),
        ),
      );
      await _invokeRemotePush(
        title: tpl.title,
        body: tpl.body,
        storeSlug: storeSlug,
      );
    }
  }

  /// Edge Function `send-booking-push` — REST key sunucuda.
  Future<void> _invokeRemotePush({
    required String title,
    required String body,
    required String storeSlug,
  }) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null || userId.isEmpty) return;

      await Supabase.instance.client.functions.invoke(
        'send-booking-push',
        body: {
          'externalUserId': userId,
          'title': title,
          'body': body,
          'storeSlug': storeSlug,
          'type': 'booking',
        },
      );
    } catch (e) {
      // Fonksiyon deploy edilmemiş / secret yok → inbox yine çalışır
      if (kDebugMode) {
        debugPrint('PushNotificationService._invokeRemotePush: $e');
      }
    }
  }
}

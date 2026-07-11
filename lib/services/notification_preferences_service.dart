import 'package:shared_preferences/shared_preferences.dart';

/// Bildirim tercihleri — Profil Ayarları ve OneSignal akışı ortak kullanır.
class NotificationPreferencesService {
  const NotificationPreferencesService();

  static const bookingPushKey = 'booking_push_enabled';

  Future<bool> isBookingPushEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(bookingPushKey) ?? true;
  }

  Future<void> setBookingPushEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(bookingPushKey, enabled);
  }
}

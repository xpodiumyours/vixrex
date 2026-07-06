import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Randevu ile ilgili tüm Supabase RPC işlemlerini merkezileştirir.
class BookingService {
  final SupabaseClient? _client;

  const BookingService({SupabaseClient? client}) : _client = client;

  SupabaseClient get _resolveClient => _client ?? Supabase.instance.client;

  // ─── Management (store owner) ─────────────────────────────────────────────

  /// Mağazanın tüm randevularını getirir.
  Future<List<dynamic>> fetchAppointments(String storeSlug) async {
    final res = await _resolveClient
        .from('appointments')
        .select('*, appointment_reschedule_requests(*)')
        .eq('store_slug', storeSlug)
        .order('appointment_time', ascending: true);
    return res as List<dynamic>;
  }

  /// Randevuya yanıt verir (kabul/reddet/değişiklik).
  Future<void> respondToAppointment({
    required String appointmentId,
    String? action,
    String? rescheduleAction,
  }) async {
    await _resolveClient.rpc('respond_to_appointment', params: {
      'p_appointment_id': appointmentId,
      'p_action': action,
      'p_reschedule_action': rescheduleAction,
    });
  }

  // ─── Public (customer) ────────────────────────────────────────────────────

  /// Token ile randevu detayı getirir.
  Future<dynamic> getAppointmentByToken(String token) async {
    return await _resolveClient.rpc('get_appointment_by_token', params: {
      'p_token': token,
    });
  }

  /// Randevuyu iptal eder.
  Future<void> cancelAppointmentByToken(String token) async {
    await _resolveClient.rpc('cancel_appointment_by_token', params: {
      'p_token': token,
    });
  }

  /// Belirli bir tarih için müsait slotları getirir.
  Future<List<dynamic>> getAvailableSlots({
    required String storeSlug,
    required DateTime date,
  }) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final res = await _resolveClient.rpc('get_public_booking_slots', params: {
      'p_store_slug': storeSlug,
      'p_date': dateStr,
    });
    return res as List<dynamic>;
  }

  /// Randevu değişiklik talebi gönderir.
  Future<void> requestReschedule({
    required String token,
    required DateTime newTime,
  }) async {
    await _resolveClient.rpc('request_appointment_reschedule', params: {
      'p_token': token,
      'p_new_time': newTime.toUtc().toIso8601String(),
    });
  }

  /// Yeni randevu talebi oluşturur.
  Future<Map<String, dynamic>> createAppointmentRequest({
    required String storeSlug,
    required String customerName,
    required String customerPhone,
    required String customerNotes,
    required String serviceTitle,
    required String servicePrice,
    required int serviceDuration,
    required String appointmentTime,
  }) async {
    final res = await _resolveClient.rpc('create_appointment_request', params: {
      'p_store_slug': storeSlug,
      'p_customer_name': customerName,
      'p_customer_phone': customerPhone,
      'p_customer_notes': customerNotes,
      'p_service_title': serviceTitle,
      'p_service_price': servicePrice,
      'p_service_duration': serviceDuration,
      'p_appointment_time': appointmentTime,
    });
    return res as Map<String, dynamic>;
  }

  /// Randevu tokenını yerel hafızaya kaydeder.
  Future<void> saveAppointmentTokenLocally({
    required String appointmentId,
    required String token,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final savedTokens = prefs.getStringList('booking_tokens') ?? [];
    savedTokens.add('$appointmentId:$token');
    await prefs.setStringList('booking_tokens', savedTokens);
  }
}

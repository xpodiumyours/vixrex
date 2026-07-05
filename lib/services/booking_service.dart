import 'package:supabase_flutter/supabase_flutter.dart';

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
}

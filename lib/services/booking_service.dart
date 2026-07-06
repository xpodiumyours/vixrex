import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vixrex/core/result.dart';
import 'package:vixrex/utils/failure.dart';

/// Randevu ile ilgili tüm Supabase RPC işlemlerini merkezileştirir.
class BookingService {
  final SupabaseClient? _client;

  const BookingService({SupabaseClient? client}) : _client = client;

  SupabaseClient get _resolveClient => _client ?? Supabase.instance.client;

  // ─── Management (store owner) ─────────────────────────────────────────────

  /// Mağazanın tüm randevularını getirir.
  Future<Result<List<dynamic>>> fetchAppointments(String storeSlug) async {
    try {
      final res = await _resolveClient
          .from('appointments')
          .select('*, appointment_reschedule_requests(*)')
          .eq('store_slug', storeSlug)
          .order('appointment_time', ascending: true);
      return Result.success(res as List<dynamic>);
    } catch (e, s) {
      return Result.failure(Failure('Randevular yüklenirken bağlantı hatası oluştu.', stackTrace: s));
    }
  }

  /// Randevuya yanıt verir (kabul/reddet/değişiklik).
  Future<Result<void>> respondToAppointment({
    required String appointmentId,
    String? action,
    String? rescheduleAction,
  }) async {
    try {
      await _resolveClient.rpc('respond_to_appointment', params: {
        'p_appointment_id': appointmentId,
        'p_action': action,
        'p_reschedule_action': rescheduleAction,
      });
      return const Result.success(null);
    } catch (e, s) {
      return Result.failure(Failure('Randevu durumu güncellenemedi. Lütfen internetinizi kontrol edin.', stackTrace: s));
    }
  }

  // ─── Public (customer) ────────────────────────────────────────────────────

  /// Token ile randevu detayı getirir.
  Future<Result<dynamic>> getAppointmentByToken(String token) async {
    try {
      final res = await _resolveClient.rpc('get_appointment_by_token', params: {
        'p_token': token,
      });
      return Result.success(res);
    } catch (e, s) {
      return Result.failure(Failure('Randevu bilgileri alınamadı. Kod geçersiz olabilir.', stackTrace: s));
    }
  }

  /// Randevuyu iptal eder.
  Future<Result<void>> cancelAppointmentByToken(String token) async {
    try {
      await _resolveClient.rpc('cancel_appointment_by_token', params: {
        'p_token': token,
      });
      return const Result.success(null);
    } catch (e, s) {
      return Result.failure(Failure('Randevu iptal edilemedi.', stackTrace: s));
    }
  }

  /// Belirli bir tarih için müsait slotları getirir.
  Future<Result<List<dynamic>>> getAvailableSlots({
    required String storeSlug,
    required DateTime date,
  }) async {
    try {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final res = await _resolveClient.rpc('get_public_booking_slots', params: {
        'p_store_slug': storeSlug,
        'p_date': dateStr,
      });
      return Result.success(res as List<dynamic>);
    } catch (e, s) {
      return Result.failure(Failure('Müsait randevu saatleri alınamadı.', stackTrace: s));
    }
  }

  /// Randevu değişiklik talebi gönderir.
  Future<Result<void>> requestReschedule({
    required String token,
    required DateTime newTime,
  }) async {
    try {
      await _resolveClient.rpc('request_appointment_reschedule', params: {
        'p_token': token,
        'p_new_time': newTime.toUtc().toIso8601String(),
      });
      return const Result.success(null);
    } catch (e, s) {
      if (e is PostgrestException && e.message.contains('dolu')) {
        return Result.failure(Failure('Seçtiğiniz randevu saati dolu.', stackTrace: s));
      }
      return Result.failure(Failure('Tarih güncelleme talebi gönderilemedi.', stackTrace: s));
    }
  }

  /// Yeni randevu talebi oluşturur.
  Future<Result<Map<String, dynamic>>> createAppointmentRequest({
    required String storeSlug,
    required String customerName,
    required String customerPhone,
    required String customerNotes,
    required String serviceTitle,
    required String servicePrice,
    required int serviceDuration,
    required String appointmentTime,
  }) async {
    try {
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
      return Result.success(res as Map<String, dynamic>);
    } catch (e, s) {
      if (e is PostgrestException && e.message.contains('dolu')) {
        return Result.failure(Failure('Seçilen saat dolmuştur, lütfen başka bir saat seçin.', stackTrace: s));
      }
      return Result.failure(Failure('Randevu talebi oluşturulurken hata oluştu.', stackTrace: s));
    }
  }

  /// Randevu tokenını yerel hafızaya kaydeder.
  Future<void> saveAppointmentTokenLocally({
    required String appointmentId,
    required String token,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTokens = prefs.getStringList('booking_tokens') ?? [];
      savedTokens.add('$appointmentId:$token');
      await prefs.setStringList('booking_tokens', savedTokens);
    } catch (_) {
      // Local token failure is non-blocking for user booking flow.
    }
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/core/result.dart';
import 'package:vixrex/core/supabase_error_mapper.dart';

/// Kullanıcı düzeltmelerini (Active Learning veri seti) Supabase'e kaydeden servis.
class OcrFeedbackService {
  final SupabaseClient? _client;

  const OcrFeedbackService({SupabaseClient? client}) : _client = client;

  SupabaseClient get _resolveClient => _client ?? Supabase.instance.client;

  /// Kullanıcının yaptığı OCR düzeltmelerini kaydeder.
  Future<Result<void>> saveFeedback({
    required String rawOcrText,
    required List<Map<String, dynamic>> correctedProducts,
    required String scanMode,
  }) async {
    try {
      final userId = _resolveClient.auth.currentUser?.id;

      await _resolveClient.from('ocr_feedback_dataset').insert({
        if (userId != null) 'user_id': userId,
        'raw_ocr_text': rawOcrText,
        'corrected_products': correctedProducts,
        'scan_mode': scanMode,
        'is_verified': false,
      });

      return const Result.success(null);
    } catch (e, s) {
      return Result.failure(SupabaseErrorMapper.map(e, s));
    }
  }
}

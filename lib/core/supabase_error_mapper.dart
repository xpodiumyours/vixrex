import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/utils/failure.dart';

class SupabaseErrorMapper {
  const SupabaseErrorMapper._();

  static Failure map(Object error, [StackTrace? stackTrace]) {
    // 1. Connection & Socket issues
    if (error is SocketException || error is HttpException) {
      return Failure(
        'İnternet bağlantınız kesildi. Lütfen ağınızı kontrol edip tekrar deneyin.',
        stackTrace: stackTrace,
      );
    }

    // 2. Supabase Database Exceptions (PostgrestException)
    if (error is PostgrestException) {
      final code = error.code ?? '';
      final message = error.message.toLowerCase();
      final details = error.details?.toString().toLowerCase() ?? '';
      final searchableText = '$message $code $details';

      // Specific business / authorization constraints from store publisher
      if (searchableText.contains('edit_token_mismatch') ||
          searchableText.contains('edit token mismatch') ||
          searchableText.contains('invalid_edit_token') ||
          searchableText.contains('store_update_not_allowed')) {
        return Failure(
          'Bu vitrin/mağaza başka bir cihazdan oluşturulmuş olabilir. Lütfen yetkinizi kontrol edin.',
          stackTrace: stackTrace,
        );
      }

      if (searchableText.contains('privacy_notice_required') || 
          searchableText.contains('privacy_notice_version_invalid')) {
        return Failure(
          'Güncel Aydınlatma Metni hakkında bilgilendirildiğinizi onaylamalısınız.',
          stackTrace: stackTrace,
        );
      }

      if (searchableText.contains('terms_acceptance_required') || 
          searchableText.contains('terms_version_invalid')) {
        return Failure(
          'Güncel Kullanım Şartları’nı kabul etmelisiniz.',
          stackTrace: stackTrace,
        );
      }

      if (searchableText.contains('publication_consent_required') || 
          searchableText.contains('publication_consent_version_invalid')) {
        return Failure(
          'Vitrininizi yayınlamak için güncel açık rıza beyanını onaylamalısınız.',
          stackTrace: stackTrace,
        );
      }

      if (searchableText.contains('update_store_with_token') || 
          searchableText.contains('could not find the function')) {
        return Failure(
          'Güncelleme altyapısı Supabase tarafında henüz kurulmamış.',
          stackTrace: stackTrace,
        );
      }

      // Postgres code match (23505 = unique_violation, e.g. duplicate slug or record)
      if (code == '23505' || message.contains('duplicate key') || message.contains('already exists') || message.contains('stores_slug_key')) {
        return Failure(
          'Bu isim veya slug zaten kullanımda. Lütfen başka bir ad belirleyin.',
          stackTrace: stackTrace,
        );
      }

      // Postgres code match (42501 = insufficient_privilege, e.g. RLS failure)
      if (code == '42501' || message.contains('row-level security') || message.contains('permission denied') || message.contains('violates row-level security')) {
        return Failure(
          'Vitrin güncelleme izni Supabase tarafında eksik görünüyor (Erişim reddedildi).',
          stackTrace: stackTrace,
        );
      }

      // Specific business triggers inside DB
      if (message.contains('daily_limit_exceeded')) {
        return Failure(
          'Günlük işlem sınırına ulaştınız. Lütfen yarın tekrar deneyin.',
          stackTrace: stackTrace,
        );
      }
      if (message.contains('capacity_full') || message.contains('dolu')) {
        return Failure(
          'Seçtiğiniz saat diliminde yer kalmadı. Lütfen başka bir saat seçin.',
          stackTrace: stackTrace,
        );
      }

      return Failure(
        'Veritabanı işlemi gerçekleştirilemedi: ${error.message}',
        stackTrace: stackTrace,
      );
    }

    // 3. Supabase Storage Exceptions (StorageException)
    if (error is StorageException) {
      final message = error.message.toLowerCase();
      if (message.contains('object not found')) {
        return Failure(
          'Dosya bulunamadı.',
          stackTrace: stackTrace,
        );
      }
      if (message.contains('payload too large')) {
        return Failure(
          'Yüklemeye çalıştığınız dosya boyutu çok büyük.',
          stackTrace: stackTrace,
        );
      }
      return Failure(
        'Dosya işlemi sırasında hata oluştu: ${error.message}',
        stackTrace: stackTrace,
      );
    }

    // 4. Supabase Auth Exceptions (AuthException)
    if (error is AuthException) {
      final message = error.message.toLowerCase();
      if (message.contains('invalid login credentials')) {
        return Failure(
          'Giriş bilgileri hatalı. E-posta/şifreyi kontrol edin veya doğrulama mailindeki bağlantıya tıklayın.',
          stackTrace: stackTrace,
        );
      }
      if (message.contains('email not confirmed')) {
        return Failure(
          'E-posta henüz doğrulanmadı. Gelen kutunuzdaki bağlantıya tıklayın, sonra tekrar giriş yapın.',
          stackTrace: stackTrace,
        );
      }
      return Failure(
        'Kimlik doğrulama hatası: ${error.message}',
        stackTrace: stackTrace,
      );
    }

    // Supabase Initialization checks
    final searchableText = error.toString().toLowerCase();
    if (searchableText.contains('supabase') &&
        (searchableText.contains('initialize') ||
            searchableText.contains('not initialized') ||
            searchableText.contains('has not been initialized') ||
            searchableText.contains('instance'))) {
      return Failure(
        'Supabase bağlantı bilgileri eksik. Uygulamayı SUPABASE_URL ve SUPABASE_PUBLISHABLE_KEY değerleriyle başlatın.',
        stackTrace: stackTrace,
      );
    }

    // 5. Fallback for custom Failure or general Exceptions
    if (error is Failure) {
      return error;
    }

    return Failure(
      'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.',
      stackTrace: stackTrace,
    );
  }
}

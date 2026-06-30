import 'package:supabase_flutter/supabase_flutter.dart';

class PublishErrorTranslator {
  const PublishErrorTranslator();

  String messageForPostgrestError(PostgrestException error, bool isStore) {
    final searchableText = _buildSearchableText([
      error.message,
      error.code,
      error.details?.toString(),
      error.hint,
      error.toString(),
    ]);

    if (searchableText.contains('edit_token_mismatch') ||
        searchableText.contains('edit token mismatch')) {
      return isStore
          ? 'Bu mağaza başka bir cihazdan oluşturulmuş olabilir.'
          : 'Bu vitrin başka bir cihazdan oluşturulmuş olabilir.';
    }

    if (searchableText.contains('privacy_notice_required') ||
        searchableText.contains('privacy_notice_version_invalid')) {
      return 'Güncel Aydınlatma Metni hakkında bilgilendirildiğinizi onaylamalısınız.';
    }
    if (searchableText.contains('terms_acceptance_required') ||
        searchableText.contains('terms_version_invalid')) {
      return 'Güncel Kullanım Şartları’nı kabul etmelisiniz.';
    }
    if (searchableText.contains('publication_consent_required') ||
        searchableText.contains('publication_consent_version_invalid')) {
      return 'Vitrininizi yayınlamak için güncel açık rıza beyanını onaylamalısınız.';
    }

    if (searchableText.contains('update_store_with_token') ||
        searchableText.contains('could not find the function')) {
      return 'Güncelleme altyapısı Supabase tarafında henüz kurulmamış.';
    }

    if (searchableText.contains('row-level security') ||
        searchableText.contains('permission denied') ||
        searchableText.contains('violates row-level security')) {
      return isStore
          ? 'Mağaza güncelleme izni Supabase tarafında eksik görünüyor.'
          : 'Vitrin güncelleme izni Supabase tarafında eksik görünüyor.';
    }

    return isStore
        ? 'Mağaza yayınlanamadı: ${error.message}'
        : 'Vitrin yayınlanamadı: ${error.message}';
  }

  String messageForUnexpectedError(Object error, bool isStore) {
    final searchableText = _buildSearchableText([error.toString()]);

    if (searchableText.contains('supabase') &&
        (searchableText.contains('initialize') ||
            searchableText.contains('not initialized') ||
            searchableText.contains('has not been initialized') ||
            searchableText.contains('instance'))) {
      return 'Supabase bağlantı bilgileri eksik. Uygulamayı SUPABASE_URL ve SUPABASE_PUBLISHABLE_KEY değerleriyle başlatın.';
    }

    return isStore
        ? 'Mağaza yayınlanamadı: $error'
        : 'Vitrin yayınlanamadı: $error';
  }

  bool isDuplicateSlugError(PostgrestException error) {
    final searchableText = _buildSearchableText([
      error.message,
      error.code,
      error.details?.toString(),
      error.hint,
      error.toString(),
    ]);

    return searchableText.contains('stores_slug_key') ||
        searchableText.contains('duplicate key') ||
        searchableText.contains('23505') ||
        searchableText.contains('409');
  }

  String _buildSearchableText(List<String?> parts) {
    return parts.whereType<String>().join(' ').toLowerCase();
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/core/result.dart';
import 'package:vixrex/core/supabase_error_mapper.dart';
import 'package:vixrex/models/legal_document.dart';
import 'package:vixrex/utils/failure.dart';

class LegalDocumentService {
  final SupabaseClient? supabaseClient;

  const LegalDocumentService({this.supabaseClient});

  SupabaseClient get _client => supabaseClient ?? Supabase.instance.client;

  Future<Result<LegalDocument>> loadActiveDocument(String documentType) async {
    try {
      // effective_at null olan kayıtlarda order sorun çıkarmasın
      final response =
          await _client
              .from('legal_documents')
              .select(
                'document_type, version, title, subtitle, sections, '
                'content_hash, effective_at',
              )
              .eq('document_type', documentType)
              .eq('is_active', true)
              .limit(1)
              .maybeSingle();

      if (response == null) {
        return Result.failure(
          Failure('$documentType için aktif yasal belge bulunamadı.'),
        );
      }

      final document = LegalDocument.fromJson(response);
      if (!document.isUsable) {
        return Result.failure(
          Failure('$documentType yasal belgesi eksik veya geçersiz.'),
        );
      }
      return Result.success(document);
    } catch (e, s) {
      return Result.failure(SupabaseErrorMapper.map(e, s));
    }
  }

  Future<Result<PublishingLegalDocuments>> loadPublishingDocuments() async {
    final privacyResult = await loadActiveDocument('privacy');
    final termsResult = await loadActiveDocument('terms');
    final consentResult = await loadActiveDocument('consent');

    // İlk hatayı döndür
    if (privacyResult.isFailure) return Result.failure(privacyResult.failure!);
    if (termsResult.isFailure) return Result.failure(termsResult.failure!);
    if (consentResult.isFailure) return Result.failure(consentResult.failure!);

    return Result.success(PublishingLegalDocuments(
      privacy: privacyResult.data!,
      terms: termsResult.data!,
      consent: consentResult.data!,
    ));
  }
}

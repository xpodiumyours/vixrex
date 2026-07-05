import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/models/legal_document.dart';

class LegalDocumentException implements Exception {
  final String message;

  const LegalDocumentException(this.message);

  @override
  String toString() => message;
}

class LegalDocumentService {
  final SupabaseClient? supabaseClient;

  const LegalDocumentService({this.supabaseClient});

  SupabaseClient get _client => supabaseClient ?? Supabase.instance.client;

  Future<LegalDocument> loadActiveDocument(String documentType) async {
    final response =
        await _client
            .from('legal_documents')
            .select(
              'document_type, version, title, subtitle, sections, '
              'content_hash, effective_at',
            )
            .eq('document_type', documentType)
            .eq('is_active', true)
            .order('effective_at', ascending: false)
            .limit(1)
            .maybeSingle();

    if (response == null) {
      throw LegalDocumentException(
        '$documentType için aktif yasal belge bulunamadı.',
      );
    }

    final document = LegalDocument.fromJson(response);
    if (!document.isUsable) {
      throw LegalDocumentException(
        '$documentType yasal belgesi eksik veya geçersiz.',
      );
    }
    return document;
  }

  Future<PublishingLegalDocuments> loadPublishingDocuments() async {
    final documents = await Future.wait([
      loadActiveDocument('privacy'),
      loadActiveDocument('terms'),
      loadActiveDocument('consent'),
    ]);

    return PublishingLegalDocuments(
      privacy: documents[0],
      terms: documents[1],
      consent: documents[2],
    );
  }
}

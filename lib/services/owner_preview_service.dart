import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/config/public_site_config.dart';
import 'package:vixrex/models/assistant_handoff.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/store_local_storage_service.dart';
import 'package:vixrex/services/store_publish_service.dart';

typedef OwnerPreviewClientProvider = SupabaseClient? Function();
typedef DraftEditTokenProvider = Future<String> Function();

class OwnerPreviewResult {
  const OwnerPreviewResult({
    required this.url,
    required this.slug,
    this.versionConflict = false,
  });

  final String url;
  final String slug;
  final bool versionConflict;
}

/// Taslak/yayın ayrımını, çalışma taslağını ve kısa süreli sahip oturumunu
/// tek bir küçük arayüz arkasında toplar. Controller yalnız editör state'ini
/// senkronlayıp bu modüle delege eder.
class OwnerPreviewService {
  const OwnerPreviewService({
    required OwnerPreviewClientProvider clientProvider,
    required DraftEditTokenProvider draftEditTokenProvider,
    required StorePublishService publishService,
  }) : _clientProvider = clientProvider,
       _draftEditTokenProvider = draftEditTokenProvider,
       _publishService = publishService;

  final OwnerPreviewClientProvider _clientProvider;
  final DraftEditTokenProvider _draftEditTokenProvider;
  final StorePublishService _publishService;

  Future<OwnerPreviewResult> open({
    required StoreData storeData,
    required PublishedVitrinInfo? publishedInfo,
    AssistantHandoffV1? assistantHandoff,
  }) async {
    final publishedSlug = publishedInfo?.slug.trim() ?? '';
    final isPublished =
        publishedInfo != null &&
        publishedInfo.isComplete &&
        publishedSlug.isNotEmpty;

    final String slug;
    final String editToken;
    var versionConflict = false;

    if (isPublished) {
      editToken = publishedInfo.editToken.trim();
      final draft = await _ensureWorkingDraft(publishedSlug, editToken);
      slug = draft.slug;
      versionConflict = draft.versionConflict;
    } else {
      final draft = await _saveDraft(storeData);
      slug = draft.slug;
      editToken = draft.editToken;
    }

    final code = await _createOwnerSession(
      slug,
      editToken,
      assistantHandoff: assistantHandoff,
    );
    return OwnerPreviewResult(
      url: PublicSiteConfig.buildOwnerSessionEntryLink(slug, code),
      slug: slug,
      versionConflict: versionConflict,
    );
  }

  Future<StoreDraftResult> _saveDraft(StoreData storeData) async {
    final editToken = await _draftEditTokenProvider();
    final result = await _publishService.saveDraft(
      storeData,
      editToken: editToken,
    );
    if (result.isFailure) {
      throw StorePublishException(result.failure!.message);
    }
    return result.data!;
  }

  Future<_WorkingDraftResult> _ensureWorkingDraft(
    String slug,
    String editToken,
  ) async {
    final client = _requireClient('Çalışma taslağı oluşturulamadı.');
    try {
      final response = await client.rpc(
        'get_or_create_working_draft',
        params: {'p_slug': slug, 'p_edit_token': editToken},
      );
      if (response is! Map) {
        throw const StorePublishException(
          'Çalışma taslağı oluşturulamadı. Lütfen tekrar deneyin.',
        );
      }
      return _WorkingDraftResult(
        slug: (response['slug'] ?? slug).toString().trim(),
        versionConflict: response['version_conflict'] == true,
      );
    } on PostgrestException catch (error) {
      throw StorePublishException(_mapRpcError(error));
    }
  }

  Future<String> _createOwnerSession(
    String slug,
    String editToken, {
    AssistantHandoffV1? assistantHandoff,
  }) async {
    final client = _requireClient('Sahip oturumu oluşturulamadı.');
    try {
      final hasHandoff = assistantHandoff != null;
      final response = await client.rpc(
        hasHandoff
            ? 'create_owner_session_with_handoff'
            : 'create_owner_session',
        params: {
          'p_slug': slug,
          'p_edit_token': editToken,
          if (hasHandoff) 'p_assistant_handoff': assistantHandoff.toJson(),
        },
      );
      final code =
          (response is Map ? response['code'] : null)?.toString().trim() ?? '';
      if (code.isEmpty) {
        throw const StorePublishException(
          'Sahip oturumu oluşturulamadı. Lütfen tekrar deneyin.',
        );
      }
      return code;
    } on PostgrestException catch (error) {
      throw StorePublishException(_mapRpcError(error));
    }
  }

  SupabaseClient _requireClient(String message) {
    final client = _clientProvider();
    if (client == null) {
      throw StorePublishException('$message Lütfen tekrar deneyin.');
    }
    return client;
  }

  String _mapRpcError(PostgrestException error) {
    final searchable =
        [
          error.message,
          error.code,
          error.details?.toString(),
          error.hint,
        ].whereType<String>().join(' ').toLowerCase();

    if (searchable.contains('demo_store_immutable') ||
        searchable.contains('is_demo')) {
      return 'Örnek vitrinler düzenlenemez.';
    }
    if (searchable.contains('owner_authorization_required') ||
        searchable.contains('store_not_found')) {
      return 'Bu vitrin için düzenleme yetkiniz yok.';
    }
    if (searchable.contains('invalid_slug')) {
      return 'Vitrin adresi geçersiz.';
    }
    // Tanınmayan hata: eskiden burada sabit, teknik detaysız bir cümle
    // dönüyordu — Postgres'in gerçekte söylediği kod (örn.
    // INVALID_ASSISTANT_HANDOFF_STEP) tamamen kayboluyordu, teşhis
    // imkansızdı (2026-08-12 bulgusu). Sır içermez: sanitize_assistant_handoff
    // sırları handoff'a girmeden reddediyor, bu yalnız bizim kendi hata
    // kodlarımız.
    return 'Önizleme hazırlanamadı: ${error.message}';
  }
}

class _WorkingDraftResult {
  const _WorkingDraftResult({
    required this.slug,
    required this.versionConflict,
  });

  final String slug;
  final bool versionConflict;
}

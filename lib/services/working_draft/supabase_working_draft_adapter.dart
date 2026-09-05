import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/core/result.dart';
import 'package:vixrex/core/supabase_error_mapper.dart';
import 'package:vixrex/services/working_draft/working_draft_port.dart';
import 'package:vixrex/utils/failure.dart';

/// Supabase adaptörü — doğrudan RPC zinciri.
///
/// Not: Realtime sinyali payload taşımaz, yalnız `draft_version`
/// bildirir (plan § Working Draft modülü).
class SupabaseWorkingDraftAdapter implements WorkingDraftPort {
  const SupabaseWorkingDraftAdapter({SupabaseClient? client}) : _client = client;
  final SupabaseClient? _client;

  SupabaseClient? get _supabase {
    if (_client != null) return _client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Result<WorkingDraftSnapshot>> yukle({required String sessionToken}) async {
    final c = _supabase;
    if (c == null) return Result.failure(Failure('NO_CLIENT'));
    try {
      final raw = await c.rpc('get_working_draft_for_session', params: {'p_session_token': sessionToken});
      final m = Map<String, dynamic>.from(raw as Map);
      return Result.success(WorkingDraftSnapshot(
        slug: (m['slug'] as String?) ?? '',
        draftData: Map<String, dynamic>.from((m['draft_data'] as Map?) ?? const {}),
        draftVersion: (m['draft_version'] as num?)?.toInt() ?? 1,
        baseLiveVersion: (m['base_live_version'] as num?)?.toInt() ?? 1,
        atlananAlanlar: List<String>.from((m['atlanan_alanlar'] as List?) ?? const []),
      ));
    } catch (e, s) {
      return Result.failure(SupabaseErrorMapper.map(e, s));
    }
  }

  @override
  Future<Result<WorkingDraftPatchResult>> yamaUygula({
    required String sessionToken,
    required String anahtar,
    required dynamic deger,
    int? beklenenSurum,
    String? clientId,
  }) async {
    final c = _supabase;
    if (c == null) return Result.failure(Failure('NO_CLIENT'));
    try {
      final raw = await c.rpc('update_working_draft_field', params: {
        'p_session_token': sessionToken,
        'p_key': anahtar,
        'p_value': deger,
      });
      final m = Map<String, dynamic>.from(raw as Map);
      return Result.success(
        WorkingDraftPatchResult.succeeded(
          draftVersion: (m['draft_version'] as num?)?.toInt() ?? 1,
        ),
      );
    } catch (e, s) {
      return Result.failure(SupabaseErrorMapper.map(e, s));
    }
  }

  @override
  Future<Result<WorkingDraftAssistantPatchResult>> akilliMotorYamasiUygula({
    String? sessionToken,
    required String anahtar,
    required dynamic deger,
    required int beklenenSurum,
    required String actionId,
    required String commandId,
    String? clientId,
  }) async {
    final c = _supabase;
    if (c == null) return Result.failure(Failure('NO_CLIENT'));

    final normalizedSession = sessionToken?.trim() ?? '';
    if (normalizedSession.isEmpty) {
      final user = c.auth.currentUser;
      if (user == null || user.isAnonymous) {
        return Result.failure(Failure('OWNER_AUTHORIZATION_REQUIRED'));
      }
    }

    if (beklenenSurum < 1 || actionId.trim().isEmpty || commandId.trim().isEmpty) {
      return Result.failure(Failure('INVALID_ACTION_PRECONDITION'));
    }

    try {
      final raw = await c.rpc(
        'vixrex_apply_storefront_action',
        params: {
          'p_session_token': normalizedSession.isEmpty ? null : normalizedSession,
          'p_field_key': anahtar,
          'p_value': deger,
          'p_expected_draft_version': beklenenSurum,
          'p_action_id': actionId,
          'p_command_id': commandId,
        },
      );
      if (raw is! Map) {
        return Result.failure(Failure('UNKNOWN_MUTATION_OUTCOME'));
      }
      final m = Map<String, dynamic>.from(raw);
      final draftVersion = (m['draft_version'] as num?)?.toInt();
      if (m['ok'] != true || draftVersion == null || draftVersion < 1) {
        return Result.failure(Failure('UNKNOWN_MUTATION_OUTCOME'));
      }

      return Result.success(
        WorkingDraftAssistantPatchResult.succeeded(
          actionId: actionId,
          commandId: commandId,
          fieldKey: (m['field_key'] ?? anahtar).toString(),
          normalizedValue: m.containsKey('new_value') ? m['new_value'] : deger,
          draftVersion: draftVersion,
          idempotentReplay: m['replayed'] == true,
        ),
      );
    } catch (e, s) {
      return Result.failure(SupabaseErrorMapper.map(e, s));
    }
  }

  @override
  Future<Result<WorkingDraftPublishResult>> yayinla({required String sessionToken}) async {
    final c = _supabase;
    if (c == null) return Result.failure(Failure('NO_CLIENT'));
    try {
      final raw = await c.rpc('publish_working_draft', params: {'p_session_token': sessionToken});
      final m = Map<String, dynamic>.from(raw as Map);
      return Result.success(WorkingDraftPublishResult(
        liveVersion: (m['live_version'] as num?)?.toInt() ?? 1,
      ));
    } catch (e, s) {
      return Result.failure(SupabaseErrorMapper.map(e, s));
    }
  }

  @override
  Stream<int> degisimSinyali({required String slug}) {
    final c = _supabase;
    if (c == null) return const Stream.empty();
    final ctrl = StreamController<int>.broadcast();
    final ch = c.channel('draft:$slug');
    ch.onBroadcast(event: 'alan_guncellendi', callback: (payload) {
      final v = (payload['draft_version'] as num?)?.toInt();
      if (v != null) ctrl.add(v);
    }).subscribe();
    ctrl.onCancel = () async {
      await c.removeChannel(ch);
      await ctrl.close();
    };
    return ctrl.stream;
  }
}

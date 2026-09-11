import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:vixrex/config/vixrex_niyet_sozlugu.g.dart';

/// Flutter Vixrex Assistant'ın kanonik çalışma-taslağı yazma sınırı.
///
/// - Kalıcı hesap varsa: Next.js ile aynı storefront command çekirdeğine
///   TEK batch/transaction yazar.
/// - Her yazım benzersiz commandId taşır; DB receipt/idempotency/undo kaydını
///   aynı transaction içinde üretir.
/// - Anonim veya Supabase başlatılmamışsa: `notAvailable`; çağıran mevcut
///   yerel davranışı koruyabilir.
/// - Uzak yazım denenip hata alırsa: `failed`; çağıran başarı mesajı üretmez.
enum VixrexCanonicalWriteState { written, notAvailable, failed }

class VixrexCanonicalWriteResult {
  final VixrexCanonicalWriteState state;
  final String? error;
  final String? commandId;

  const VixrexCanonicalWriteResult(this.state, {this.error, this.commandId});
}

class VixrexCanonicalDraftWriter {
  const VixrexCanonicalDraftWriter({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;
  static const _uuid = Uuid();

  SupabaseClient? get _resolvedClient {
    if (_client != null) return _client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<VixrexCanonicalWriteResult> write({
    required List<VixrexNiyetAlan> alanlar,
    required List<Object?> degerler,
  }) async {
    if (alanlar.isEmpty || alanlar.length != degerler.length) {
      return const VixrexCanonicalWriteResult(
        VixrexCanonicalWriteState.failed,
        error: 'INVALID_CHANGES',
      );
    }

    final client = _resolvedClient;
    final user = client?.auth.currentUser;
    if (client == null || user == null || user.isAnonymous) {
      return const VixrexCanonicalWriteResult(
        VixrexCanonicalWriteState.notAvailable,
      );
    }

    final changes = <String, Object?>{};
    for (var i = 0; i < alanlar.length; i++) {
      final kolon = alanlar[i].kolon.trim();
      if (kolon.isEmpty || changes.containsKey(kolon)) {
        return const VixrexCanonicalWriteResult(
          VixrexCanonicalWriteState.failed,
          error: 'INVALID_FIELD_KEY',
        );
      }
      changes[kolon] = degerler[i];
    }

    final commandId = _uuid.v4();
    try {
      final raw = await client.rpc(
        'apply_owned_working_draft_command',
        params: {'p_command_id': commandId, 'p_changes': changes},
      );
      final returnedCommandId =
          raw is Map ? raw['command_id']?.toString().trim() : null;
      if (returnedCommandId != commandId) {
        return const VixrexCanonicalWriteResult(
          VixrexCanonicalWriteState.failed,
          error: 'COMMAND_RECEIPT_MISMATCH',
        );
      }
      return VixrexCanonicalWriteResult(
        VixrexCanonicalWriteState.written,
        commandId: commandId,
      );
    } on PostgrestException catch (error) {
      return VixrexCanonicalWriteResult(
        VixrexCanonicalWriteState.failed,
        error: error.message,
      );
    } catch (_) {
      return const VixrexCanonicalWriteResult(
        VixrexCanonicalWriteState.failed,
        error: 'CANONICAL_WRITE_FAILED',
      );
    }
  }
}

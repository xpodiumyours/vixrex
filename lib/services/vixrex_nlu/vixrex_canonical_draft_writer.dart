import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/config/vixrex_niyet_sozlugu.g.dart';

/// Flutter Vixrex Assistant'ın kanonik çalışma-taslağı yazma sınırı.
///
/// - Kalıcı hesap varsa: aynı `store_working_drafts` kaydına Supabase RPC ile
///   TEK batch/transaction yazar.
/// - Anonim veya Supabase başlatılmamışsa: `notAvailable`; çağıran mevcut
///   yerel davranışı koruyabilir.
/// - Uzak yazım denenip hata alırsa: `failed`; çağıran başarı mesajı üretmez.
enum VixrexCanonicalWriteState { written, notAvailable, failed }

class VixrexCanonicalWriteResult {
  final VixrexCanonicalWriteState state;
  final String? error;

  const VixrexCanonicalWriteResult(this.state, {this.error});
}

class VixrexCanonicalDraftWriter {
  const VixrexCanonicalDraftWriter({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;

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

    try {
      await client.rpc(
        'update_owned_working_draft_fields',
        params: {'p_changes': changes},
      );
      return const VixrexCanonicalWriteResult(
        VixrexCanonicalWriteState.written,
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

import 'dart:convert';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/repositories/vitrin_view_repository.dart';
import 'package:vixrex/services/secure_kv_storage.dart';

/// SharedPreferences ve RPC ile VitrinViewRepository implementasyonu.
class SupabaseVitrinViewRepository implements VitrinViewRepository {
  final SupabaseClient _client;

  SupabaseVitrinViewRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  @override
  Future<void> recordView({
    required String slug,
    required String source,
  }) async {
    final sessionKey = await _loadOrCreateSessionKey();
    await _client.rpc(
      'record_vitrin_view',
      params: {
        'p_store_slug': slug.trim(),
        'p_session_key': sessionKey,
        'p_source': _normalizeSource(source),
      },
    );
  }

  @override
  Future<int> fetchTodayViewCount({
    required String slug,
    required String editToken,
  }) async {
    if (slug.trim().isEmpty || editToken.trim().isEmpty) return 0;

    final response = await _client.rpc(
      'get_today_vitrin_view_count',
      params: {'p_slug': slug.trim(), 'p_edit_token': editToken.trim()},
    );

    if (response is int) return response;
    if (response is num) return response.toInt();
    return int.tryParse(response.toString()) ?? 0;
  }

  Future<String> _loadOrCreateSessionKey() async {
    final savedKey = await SecureKVStorage.getString('vitrin_view_session_key');
    if (savedKey != null && savedKey.isNotEmpty) return savedKey;

    final newKey = base64UrlEncode(
      List<int>.generate(16, (_) => Random.secure().nextInt(256)),
    );
    await SecureKVStorage.setString('vitrin_view_session_key', newKey);
    return newKey;
  }

  String _normalizeSource(String source) {
    final trimmed = source.trim().toLowerCase();
    if (trimmed.isEmpty) return 'direct';
    return trimmed;
  }
}

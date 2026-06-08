import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VitrinViewService {
  final SupabaseClient? supabaseClient;

  const VitrinViewService({this.supabaseClient});

  static const String _sessionKeyPrefsKey = 'vitrin_view_session_key';

  // ── Singleton Pattern for SharedPreferences ────────────────────────────

  static final Future<SharedPreferences> _prefsFuture =
      SharedPreferences.getInstance();

  Future<SharedPreferences> get _prefs => _prefsFuture;

  Future<void> recordView({
    required String slug,
    required String source,
  }) async {
    try {
      final sessionKey = await _loadOrCreateSessionKey();
      final client = supabaseClient ?? Supabase.instance.client;
      await client.rpc(
        'record_vitrin_view',
        params: {
          'p_store_slug': slug.trim(),
          'p_session_key': sessionKey,
          'p_source': _normalizeSource(source),
        },
      );
    } catch (error) {
      debugPrint('Vitrin view record error: $error');
    }
  }

  Future<int> fetchTodayViewCount({
    required String slug,
    required String editToken,
  }) async {
    try {
      if (slug.trim().isEmpty || editToken.trim().isEmpty) return 0;

      final client = supabaseClient ?? Supabase.instance.client;
      final response = await client.rpc(
        'get_today_vitrin_view_count',
        params: {'p_slug': slug.trim(), 'p_edit_token': editToken.trim()},
      );

      if (response is int) return response;
      if (response is num) return response.toInt();
      return int.tryParse(response.toString()) ?? 0;
    } catch (error) {
      debugPrint('Vitrin view count error: $error');
      return 0;
    }
  }

  Future<String> _loadOrCreateSessionKey() async {
    final prefs = await _prefs;
    final savedKey = prefs.getString(_sessionKeyPrefsKey);

    if (savedKey != null && savedKey.trim().length >= 16) {
      return savedKey.trim();
    }

    final key = _generateSessionKey();
    await prefs.setString(_sessionKeyPrefsKey, key);
    return key;
  }

  String _generateSessionKey() {
    Random random;
    try {
      random = Random.secure();
    } catch (_) {
      random = Random();
    }

    final randomBytes = List<int>.generate(32, (_) => random.nextInt(256));
    final timestampBytes = utf8.encode(
      DateTime.now().microsecondsSinceEpoch.toString(),
    );

    return base64Url
        .encode([...timestampBytes, ...randomBytes])
        .replaceAll('=', '');
  }

  String _normalizeSource(String source) {
    final normalized = source.trim().toLowerCase();

    if (normalized == 'direct' || normalized == 'qr' || normalized == 'share') {
      return normalized;
    }

    return 'unknown';
  }
}

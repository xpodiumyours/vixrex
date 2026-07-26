import 'package:supabase_flutter/supabase_flutter.dart';

class FeatureFlagService {
  final SupabaseClient _client;
  final Map<String, bool> _cache = {};
  final Map<String, String> _targetUsers = {};
  bool _loaded = false;

  FeatureFlagService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  Future<void> loadFlags() async {
    try {
      final res = await _client.rpc('get_feature_flags');
      if (res is List) {
        for (final row in res) {
          final key = row['flag_key'] as String;
          _cache[key] = row['is_enabled'] as bool;
          _targetUsers[key] = row['target_users'] as String? ?? 'all';
        }
      }
      _loaded = true;
    } catch (e) {
      _loaded = false;
    }
  }

  bool isEnabled(String key, {bool defaultValue = false}) {
    if (!_loaded) return defaultValue;
    return _cache[key] ?? defaultValue;
  }

  bool isEnabledForUser(
    String key, {
    required bool isPremium,
    bool defaultValue = false,
  }) {
    if (!_loaded) return defaultValue;
    final enabled = _cache[key] ?? false;
    if (!enabled) return false;
    final target = _targetUsers[key] ?? 'all';
    switch (target) {
      case 'all':
        return true;
      case 'premium':
        return isPremium;
      case 'free':
        return !isPremium;
      default:
        return false;
    }
  }

  bool get isLoaded => _loaded;

  void dispose() {
    _cache.clear();
    _targetUsers.clear();
    _loaded = false;
  }
}

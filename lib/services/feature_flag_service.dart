import 'package:supabase_flutter/supabase_flutter.dart';

const String vixrexSmartEngineFlag = 'vixrex_smart_engine_enabled';
const String vixrexSmartEngineStorefrontFlag =
    'vixrex_smart_engine_storefront_enabled';

bool smartEngineStorefrontEnabledFromMap(
  Map<String, bool> flags, {
  required bool loaded,
}) {
  if (!loaded) return false;
  return flags[vixrexSmartEngineFlag] == true &&
      flags[vixrexSmartEngineStorefrontFlag] == true;
}

class FeatureFlagService {
  final SupabaseClient? _injectedClient;
  final Map<String, bool> _cache = {};
  final Map<String, String> _targetUsers = {};
  bool _loaded = false;

  FeatureFlagService({SupabaseClient? client}) : _injectedClient = client;

  /// Supabase'e KURUCUDA değil, ilk gerçek kullanımda erişilir.
  ///
  /// NEDEN: bu servis widget state'lerinde (ör. VixRexCompanionChat)
  /// doğrudan kuruluyor. Kurucuda `Supabase.instance` okunursa, Supabase
  /// henüz hazır değilken widget hiç oluşamıyor ve ekran boş kalıyor —
  /// widget testlerinde de canlıda erken açılışta da aynı çökme oluyordu.
  SupabaseClient get _client => _injectedClient ?? Supabase.instance.client;

  Future<void> loadFlags() async {
    try {
      final res = await _client.rpc('get_feature_flags');
      _cache.clear();
      _targetUsers.clear();
      if (res is List) {
        for (final row in res) {
          if (row is! Map) continue;
          final key = row['flag_key'];
          final enabled = row['is_enabled'];
          if (key is! String || enabled is! bool) continue;
          _cache[key] = enabled;
          _targetUsers[key] = row['target_users'] as String? ?? 'all';
        }
      }
      _loaded = true;
    } catch (_) {
      // Fail-closed: ağ/RPC/auth hatası eski true cache'ini kullanmaz.
      _cache.clear();
      _targetUsers.clear();
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

  bool get isSmartEngineStorefrontEnabled =>
      smartEngineStorefrontEnabledFromMap(_cache, loaded: _loaded);

  bool get isLoaded => _loaded;

  void dispose() {
    _cache.clear();
    _targetUsers.clear();
    _loaded = false;
  }
}

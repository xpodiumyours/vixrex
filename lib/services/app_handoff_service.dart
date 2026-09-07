import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_handoff_url_stub.dart'
    if (dart.library.js_interop) 'app_handoff_url_web.dart';

/// Next.js public web yuzeyinden Flutter Web uygulama kabuguna gelen
/// tek kullanimlik Supabase oturumunu devralir.
///
/// Normal Flutter Google/OAuth akisinin PKCE ayari degistirilmez. Yalniz
/// callback URL'sindeki implicit token fragment'i ayri, gecici bir istemciyle
/// okunur; sonra ana Supabase istemcisinde yeni oturum kurulur.
class AppHandoffService {
  const AppHandoffService._();

  static Future<bool> devral({
    required String supabaseUrl,
    required String publishableKey,
  }) async {
    if (!kIsWeb) return false;

    final uri = Uri.base;
    final fragment = uri.fragment;
    final handoffVar =
        fragment.contains('access_token=') &&
        fragment.contains('refresh_token=') &&
        fragment.contains('token_type=');
    if (!handoffVar) return false;

    SupabaseClient? geciciClient;
    try {
      geciciClient = SupabaseClient(
        supabaseUrl,
        publishableKey,
        authOptions: const AuthClientOptions(
          autoRefreshToken: false,
          authFlowType: AuthFlowType.implicit,
        ),
      );

      final response = await geciciClient.auth.getSessionFromUrl(
        uri,
        storeSession: false,
      );
      final session = response.session;
      if (session == null) return false;

      await Supabase.instance.client.auth.setSession(
        session.refreshToken,
        accessToken: session.accessToken,
      );

      if (kDebugMode) debugPrint('[OK] Web uygulama oturumu devralindi');
      return true;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[WARN] Web uygulama oturumu devralinamadi: $error');
      }
      return false;
    } finally {
      // Tokenlar basarili ya da basarisiz denemeden sonra adres cubugunda
      // tutulmaz. Normal query/path korunur; yalniz fragment temizlenir.
      temizleAppHandoffAdresi();
      await geciciClient?.dispose();
    }
  }
}

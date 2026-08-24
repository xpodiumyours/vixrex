import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:vixrex/config/app_router.dart';
import 'package:vixrex/l10n/app_localizations.dart';
import 'package:vixrex/services/push_notification_service.dart';
import 'package:vixrex/services/sohbet_gecmisi_gocu.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Path URL strategy: /app panel; müşteri /v/* Next.js'e yönlendirilir (PublicSiteRedirectScreen).
  if (kIsWeb) {
    usePathUrlStrategy();
  }
  SystemChrome.setSystemUIOverlayStyle(_systemUiOverlayStyle);
  _setupGlobalErrorHandler();
  await _initializeSupabase();
  _initializeOneSignal();
  // Tek Asistan planı, Faz C: eski sohbet geçmişi anahtarlarını tek v3
  // desenine bir kez taşır. Sessiz başarısızlık — bir kapı değil, temizlik.
  await SohbetGecmisiGocu.calistir();

  await SentryFlutter.init((options) {
    options.dsn = const String.fromEnvironment('SENTRY_DSN');
    options.tracesSampleRate = 0.2;
  });

  runApp(const VixRexApp());
}

const SystemUiOverlayStyle _systemUiOverlayStyle = SystemUiOverlayStyle(
  statusBarColor: AppColors.bgEditor,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
  systemNavigationBarColor: AppColors.bgEditor,
  systemNavigationBarDividerColor: AppColors.bgEditor,
  systemNavigationBarIconBrightness: Brightness.light,
  systemStatusBarContrastEnforced: false,
  systemNavigationBarContrastEnforced: false,
);

void _setupGlobalErrorHandler() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      debugPrint(
        '[GlobalError] Captured Flutter Error: ${details.exceptionAsString()}',
      );
    }
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    if (kDebugMode) {
      debugPrint('[GlobalError] Captured Platform/Async Error: $error');
    }
    return true;
  };
}

Future<void> _initializeSupabase() async {
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  if (supabaseUrl.isEmpty || supabasePublishableKey.isEmpty) {
    if (kDebugMode) {
      debugPrint(
        '[FATAL] Supabase config missing - SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY must be provided via --dart-define',
      );
    }
    return;
  }

  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabasePublishableKey,
    );
    if (kDebugMode) debugPrint('[OK] Supabase initialized successfully');
    await _oturumuGuvenceyeAl();
  } catch (error) {
    if (kDebugMode) debugPrint('[FATAL] Supabase initialize failed: $error');
  }
}

/// Her kullanıcı ilk saniyeden itibaren bir hesaba sahip olur.
///
/// NEDEN VAR (docs/kok-neden-arastirmasi.md — kimlik kökü):
/// 2026-08-07 sayımında buluttaki 128 vitrinin 128'i SAHİPSİZDİ
/// (`user_id` boş). Veritabanındaki sahiplik politikaları doğru yazılmıştı
/// ama hiç eşleşmiyordu; bu yüzden her işlem RLS'i atlayan 25 fonksiyondan
/// ve elden ele taşınan bir anahtardan geçiyordu. Kimlik gerçekte
/// tarayıcının hafızasında duruyordu — silinen vitrin uygulamada görünmeye
/// devam ediyor, silinemiyordu.
///
/// NEDEN ANONİM: esnafa form göstermeden kimlik vermek için. "45 saniyede
/// vitrin" vaadi bozulmaz, kayıt ekranı yok. Vitrin ilk andan itibaren
/// sahipli olur; `create_store_with_token` içindeki `auth.uid()` dolar.
/// Esnaf sonra hesabını Google'a bağlar — AYNI hesap kalır, veri taşınmaz.
///
/// SESSİZ BAŞARISIZLIK: oturum kurulamazsa uygulama eskisi gibi çalışır.
/// Bu adım bir kapı değil, bir kolaylık.
Future<void> _oturumuGuvenceyeAl() async {
  try {
    final auth = Supabase.instance.client.auth;
    if (auth.currentSession != null) return;
    await auth.signInAnonymously();
    if (kDebugMode) debugPrint('[OK] Anonim oturum kuruldu');
  } catch (error) {
    if (kDebugMode) debugPrint('[WARN] Anonim oturum kurulamadı: $error');
  }
}

void _initializeOneSignal() {
  const oneSignalAppId = String.fromEnvironment('ONESIGNAL_APP_ID');
  if (oneSignalAppId.isEmpty) {
    if (kDebugMode) debugPrint('[WARN] OneSignal App ID not set');
    return;
  }

  OneSignal.initialize(oneSignalAppId);
  OneSignal.Notifications.requestPermission(true);
  PushNotificationService.instance.attachClickListener();
  PushNotificationService.instance.setDeepLinkHandler(({
    required String type,
    required String storeSlug,
  }) {
    if (type == 'booking' || type.isEmpty) {
      AppRouter.openBookingFromNotification(storeSlug);
    }
  });

  try {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null && userId.isNotEmpty) {
      PushNotificationService.instance.loginUser(userId);
    }
  } catch (e) {
    if (kDebugMode) debugPrint('[WARN] OneSignal login skipped: $e');
  }
}

class VixRexApp extends StatelessWidget {
  const VixRexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Vixrex',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('tr', 'TR'), Locale('en', 'US')],
      theme: AppTheme.dark(_systemUiOverlayStyle),
      routerConfig: AppRouter.router,
    );
  }
}

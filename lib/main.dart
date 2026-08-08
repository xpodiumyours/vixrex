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
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/theme/app_text_styles.dart';

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
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        // TEK YAZI TİPİ — tüm ekranlar buradan miras alır.
        //
        // 'Helvetica' yazıyordu ama o yazı tipi uygulamayla gelmiyordu;
        // her cihaz kendi bulduğuna düşüyordu. Vitrin tarafı Outfit
        // kullanıyor; iki yüzey iki ayrı marka gibi görünüyordu.
        // Ekranlar kendi yazı tipini BELİRLEMEZ, buradan alır.
        fontFamily: 'Outfit',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          onPrimary: AppColors.onPrimary,
          onSecondary: AppColors.onPrimary,
          shadow: Colors.black12,
        ),
        scaffoldBackgroundColor: AppColors.bgEditor,
        disabledColor: AppColors.disabled,
        textTheme: const TextTheme(
          displayLarge: AppTextStyles.displayTitle,
          titleLarge: AppTextStyles.sectionTitle,
          titleMedium: AppTextStyles.subTitle,
          titleSmall: AppTextStyles.formLabel,
          bodyMedium: AppTextStyles.body,
          bodySmall: AppTextStyles.caption,
          labelLarge: AppTextStyles.labelBold,
          labelSmall: AppTextStyles.labelSmall,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.bgEditor,
          foregroundColor: AppColors.darkText,
          elevation: 0,
          systemOverlayStyle: _systemUiOverlayStyle,
          titleTextStyle: TextStyle(
            color: AppColors.darkText,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          fillColor: AppColors.inputBg,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.focusedBorder,
              width: 1.5,
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            disabledBackgroundColor: AppColors.surfaceSoft,
            disabledForegroundColor: AppColors.mutedText,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            disabledForegroundColor: AppColors.disabled,
            side: const BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.primary,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.surfaceSoft,
          selectedColor: AppColors.primary,
          secondarySelectedColor: AppColors.primary,
          labelStyle: const TextStyle(color: AppColors.darkText),
          secondaryLabelStyle: const TextStyle(color: AppColors.onPrimary),
          checkmarkColor: AppColors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.border),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          indicatorColor: AppColors.turquoiseSurface,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: AppColors.primary);
            }
            return const IconThemeData(color: AppColors.mutedText);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              );
            }
            return const TextStyle(color: AppColors.mutedText, fontSize: 12);
          }),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.surfaceSoft;
            }
            if (states.contains(WidgetState.selected)) {
              return AppColors.primary;
            }
            return AppColors.surfaceSoft;
          }),
          checkColor: const WidgetStatePropertyAll(AppColors.onPrimary),
          side: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: AppColors.darkText,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
          contentTextStyle: TextStyle(
            color: AppColors.darkTextAlt,
            fontSize: 14,
            height: 1.45,
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.surface,
          modalBackgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          dragHandleColor: AppColors.mutedText,
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.border,
          thickness: 1,
        ),
      ),
      routerConfig: AppRouter.router,
    );
  }
}

import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vixrex/config/app_router.dart';
import 'package:vixrex/config/public_site_config.dart';
import 'package:vixrex/services/push_notification_service.dart';
import 'package:vixrex/theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Path URL: müşteri linki /v/slug tarayıcıda PublicVitrinScreen açar (hash /#/app değil).
  if (kIsWeb) {
    usePathUrlStrategy();
  }
  SystemChrome.setSystemUIOverlayStyle(_systemUiOverlayStyle);
  _setupGlobalErrorHandler();
  await _initializeSupabase();
  _initializeOneSignal();

  await SentryFlutter.init(
    (options) {
      options.dsn = const String.fromEnvironment('SENTRY_DSN');
      options.tracesSampleRate = 1.0;
    },
    appRunner: () => runApp(const VixRexApp()),
  );
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
    if (kDebugMode) debugPrint('[GlobalError] Captured Platform/Async Error: $error');
    return true;
  };
}

Future<void> _initializeSupabase() async {
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  if (supabaseUrl.isEmpty || supabasePublishableKey.isEmpty) {
    if (kDebugMode) debugPrint('[FATAL] Supabase config missing - SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY must be provided via --dart-define');
    return;
  }

  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabasePublishableKey,
    );
    if (kDebugMode) debugPrint('[OK] Supabase initialized successfully');
  } catch (error) {
    if (kDebugMode) debugPrint('[FATAL] Supabase initialize failed: $error');
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
      if (kIsWeb) {
        // WEB: Next.js public vitrine yönlendir
        final url = PublicSiteConfig.buildBookingTrackerLink(storeSlug, '');
        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        // MOBIL: Flutter içinde aç
        AppRouter.openBookingFromNotification(storeSlug);
      }
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
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        fontFamily: 'Helvetica',
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
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.bgEditor,
          foregroundColor: AppColors.darkText,
          elevation: 0,
          systemOverlayStyle: _systemUiOverlayStyle,
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

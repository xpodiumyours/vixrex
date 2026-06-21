import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitrinx/config/public_vitrin_route_config.dart';
import 'package:vitrinx/screens/home_shell_screen.dart';
import 'package:vitrinx/screens/landing_screen.dart';
import 'package:vitrinx/screens/legal_screen.dart';
import 'package:vitrinx/screens/public_vitrin_screen.dart';
import 'package:vitrinx/theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeSupabase();
  runApp(const VitrinXApp());
}

Future<void> _initializeSupabase() async {
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  if (supabaseUrl.isEmpty || supabasePublishableKey.isEmpty) {
    debugPrint('Supabase config missing');
    return;
  }

  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabasePublishableKey,
    );
  } catch (error) {
    debugPrint('Supabase initialize failed: $error');
  }
}

class VitrinXApp extends StatelessWidget {
  const VitrinXApp({super.key});

  @override
  Widget build(BuildContext context) {
    final initialHome = _buildInitialHome();

    return MaterialApp(
      title: 'VitrinX',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Helvetica',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          shadow: Colors.black12,
        ),
        scaffoldBackgroundColor: AppColors.bgEditor,
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
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.border),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          indicatorColor: AppColors.turquoiseSurface,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: AppColors.primaryDark);
            }
            return const IconThemeData(color: AppColors.mutedText);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              );
            }
            return const TextStyle(color: AppColors.mutedText, fontSize: 12);
          }),
        ),
      ),
      home: initialHome,
      onGenerateRoute: _generateRoute,
    );
  }

  Widget _buildInitialHome() {
    final legalType = LegalScreen.typeFromRoute(Uri.base.path);
    if (legalType != null) {
      return LegalScreen(type: legalType);
    }

    final slug = PublicVitrinRouteConfig.publicSlugFromUri(Uri.base);

    if (slug != null) {
      return PublicVitrinScreen(slug: slug);
    }

    if (_isHomeShellRoute(Uri.base.path)) {
      return const HomeShellScreen();
    }

    return const LandingScreen();
  }

  Route<dynamic> _generateRoute(RouteSettings settings) {
    final routeName = settings.name ?? '/';
    final legalType = LegalScreen.typeFromRoute(routeName);
    if (legalType != null) {
      return MaterialPageRoute(
        builder: (_) => LegalScreen(type: legalType),
        settings: settings,
      );
    }

    final slug = PublicVitrinRouteConfig.publicSlugFromUri(
      Uri.parse(routeName),
    );

    if (slug != null) {
      return MaterialPageRoute(
        builder: (_) => PublicVitrinScreen(slug: slug),
        settings: settings,
      );
    }

    if (_isHomeShellRoute(routeName)) {
      return MaterialPageRoute(
        builder: (_) => const HomeShellScreen(),
        settings: settings,
      );
    }

    return MaterialPageRoute(
      builder: (_) => const LandingScreen(),
      settings: settings,
    );
  }

  bool _isHomeShellRoute(String routeName) {
    final path = Uri.tryParse(routeName)?.path ?? routeName;
    return path == '/app' || path == '/home';
  }
}

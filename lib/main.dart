import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitrinx/screens/landing_screen.dart';
import 'package:vitrinx/screens/public_vitrin_screen.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
        fontFamily: 'Helvetica', // Basic font since no GoogleFonts
      ),
      home: initialHome,
      onGenerateRoute: _generateRoute,
    );
  }

  Widget _buildInitialHome() {
    final slug = _publicSlugFromUri(Uri.base);

    if (slug != null) {
      return PublicVitrinScreen(slug: slug);
    }

    return const LandingScreen();
  }

  Route<dynamic> _generateRoute(RouteSettings settings) {
    final routeName = settings.name ?? '/';
    final slug = _publicSlugFromUri(Uri.parse(routeName));

    if (slug != null) {
      return MaterialPageRoute(
        builder: (_) => PublicVitrinScreen(slug: slug),
        settings: settings,
      );
    }

    return MaterialPageRoute(
      builder: (_) => const LandingScreen(),
      settings: settings,
    );
  }

  String? _publicSlugFromUri(Uri uri) {
    if (uri.pathSegments.length != 2 || uri.pathSegments.first != 'v') {
      return null;
    }

    final slug = uri.pathSegments.last.trim();
    return slug.isEmpty ? null : slug;
  }
}

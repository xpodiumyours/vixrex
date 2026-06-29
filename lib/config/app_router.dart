import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vitrinx/screens/appointment_tracker_screen.dart';
import 'package:vitrinx/screens/auth_screen.dart';
import 'package:vitrinx/screens/blog_editor_screen.dart';
import 'package:vitrinx/screens/booking_management_screen.dart';
import 'package:vitrinx/screens/home_shell_screen.dart';
import 'package:vitrinx/screens/landing_screen.dart';
import 'package:vitrinx/screens/legal_screen.dart';
import 'package:vitrinx/screens/public_vitrin_screen.dart';
import 'package:vitrinx/config/legal_config.dart';

class AppRouter {
  static const String landing = '/';
  static const String app = '/app';
  static const String home = '/home';
  static const String auth = '/auth';
  static const String consent = LegalConfig.consentPath;

  static final GoRouter router = GoRouter(
    initialLocation: landing,
    errorBuilder: (context, state) => const LandingScreen(),
    routes: [
      GoRoute(
        path: landing,
        builder: (context, state) {
          // Parse initial path for deep link checking
          final uri = state.uri;
          final legalType = LegalScreen.typeFromRoute(uri.path);
          if (legalType != null) {
            return LegalScreen(type: legalType);
          }
          
          final slugPath = uri.path;
          if (slugPath.startsWith('/v/')) {
            final slug = Uri.decodeComponent(slugPath.substring(3));
            if (slug.isNotEmpty) {
              return PublicVitrinScreen(slug: slug);
            }
          }

          if (uri.path == app || uri.path == home) {
            final index = uri.path == app ? 1 : 0;
            return HomeShellScreen(initialIndex: index);
          }

          return const LandingScreen();
        },
      ),
      GoRoute(
        path: auth,
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: app,
        builder: (context, state) => const HomeShellScreen(initialIndex: 1),
      ),
      GoRoute(
        path: home,
        builder: (context, state) => const HomeShellScreen(initialIndex: 0),
      ),
      GoRoute(
        path: '/v/:slug',
        builder: (context, state) {
          final slug = state.pathParameters['slug'] ?? '';
          return PublicVitrinScreen(slug: slug);
        },
      ),
      GoRoute(
        path: LegalConfig.privacyPath,
        builder:
            (context, state) => const LegalScreen(type: LegalPageType.privacy),
      ),
      GoRoute(
        path: LegalConfig.termsPath,
        builder:
            (context, state) => const LegalScreen(type: LegalPageType.terms),
      ),
      GoRoute(
        path: LegalConfig.consentPath,
        builder:
            (context, state) => const LegalScreen(type: LegalPageType.consent),
      ),
      GoRoute(
        path: LegalConfig.dataDeletionPath,
        builder:
            (context, state) =>
                const LegalScreen(type: LegalPageType.dataDeletion),
      ),
      GoRoute(
        path: '/legal/:type',
        builder: (context, state) {
          final typeParam = state.pathParameters['type'] ?? '';
          final routePath = '/legal/$typeParam';
          final type = LegalScreen.typeFromRoute(routePath) ?? LegalPageType.privacy;
          return LegalScreen(type: type);
        },
      ),
    ],
  );

  // Centralized Navigators using GoRouter with standard Navigator fallbacks for isolated testing
  static void navigateToLanding(BuildContext context) {
    try {
      context.go(landing);
    } catch (_) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LandingScreen()),
        (route) => false,
      );
    }
  }

  static void navigateToHomeShell(BuildContext context,
      {int initialIndex = 1, String? initialVitrinName}) {
    if (initialVitrinName != null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => HomeShellScreen(
            initialIndex: initialIndex,
            initialVitrinName: initialVitrinName,
          ),
        ),
        (route) => false,
      );
      return;
    }

    try {
      if (initialIndex == 0) {
        context.go(home);
      } else {
        context.go(app);
      }
    } catch (_) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => HomeShellScreen(
            initialIndex: initialIndex,
            initialVitrinName: initialVitrinName,
          ),
        ),
        (route) => false,
      );
    }
  }

  static Future<dynamic> navigateToAuth(BuildContext context) {
    try {
      return context.push(auth);
    } catch (_) {
      return Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    }
  }

  static Future<dynamic> navigateToLegal(
    BuildContext context,
    LegalPageType type,
  ) {
    try {
      return context.push(type.routePath);
    } catch (_) {
      return Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LegalScreen(type: type)),
      );
    }
  }

  static Future<dynamic> navigateToBlogEditor(BuildContext context,
      {required String slug, Map<String, dynamic>? article}) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlogEditorScreen(
          storeSlug: slug,
          initialArticle: article,
        ),
      ),
    );
  }

  static Future<dynamic> navigateToBookingManagement(BuildContext context,
      {required String slug}) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingManagementScreen(storeSlug: slug),
      ),
    );
  }

  static Future<bool?> navigateToAppointmentTracker(BuildContext context,
      {required String slug, required String token}) {
    return Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AppointmentTrackerScreen(storeSlug: slug, token: token),
      ),
    );
  }

  static void navigateToPublicVitrin(BuildContext context, String slug) {
    try {
      context.push('/v/$slug');
    } catch (_) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PublicVitrinScreen(slug: slug)),
      );
    }
  }

  static void push(BuildContext context, String path) {
    try {
      context.push(path);
    } catch (_) {
      // Fallback for isolated testing/errors
    }
  }
}

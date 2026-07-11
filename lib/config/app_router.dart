import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vixrex/config/legal_config.dart';
import 'package:vixrex/config/public_site_config.dart';
import 'package:vixrex/screens/appointment_tracker_screen.dart';
import 'package:vixrex/screens/auth_screen.dart';
import 'package:vixrex/screens/blog_editor_screen.dart';
import 'package:vixrex/screens/booking_management_screen.dart';
import 'package:vixrex/screens/home_shell_screen.dart';
import 'package:vixrex/screens/landing_screen.dart';
import 'package:vixrex/screens/legal_screen.dart';
import 'package:vixrex/screens/public_booking_screen.dart';
import 'package:vixrex/screens/public_vitrin_screen.dart';
import 'package:vixrex/screens/public_product_screen.dart';

class AppRouter {
  static const String landing = '/';
  static const String app = '/app';
  static const String home = '/home';
  static const String auth = '/auth';
  static const String consent = LegalConfig.consentPath;

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: landing,
    errorBuilder: (context, state) {
      final slug = PublicSiteConfig.resolveVitrinSlugFromPath(state.uri.path);
      if (slug != null) {
        return PublicVitrinScreen(slug: slug);
      }
      return const LandingScreen();
    },
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
            final index = uri.path == app ? 0 : 1;
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
        builder: (context, state) => const HomeShellScreen(initialIndex: 0),
      ),
      GoRoute(
        path: home,
        builder: (context, state) => const HomeShellScreen(initialIndex: 1),
      ),
      GoRoute(
        path: '/bookings/:slug',
        builder: (context, state) {
          final slug = state.pathParameters['slug'] ?? '';
          return BookingManagementScreen(storeSlug: slug);
        },
      ),
      GoRoute(
        path: '/v/:slug/randevu/:token',
        builder: (context, state) {
          return AppointmentTrackerScreen(
            storeSlug: state.pathParameters['slug'] ?? '',
            token: state.pathParameters['token'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/v/:slug/randevu',
        builder: (context, state) {
          return PublicBookingScreen(
            slug: state.pathParameters['slug'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/v/:slug/urun/:productSlug',
        builder: (context, state) {
          return PublicProductScreen(
            storeSlug: state.pathParameters['slug'] ?? '',
            productSlug: state.pathParameters['productSlug'] ?? '',
          );
        },
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

  /// Ana kabuk. [initialIndex]: 0=Vitrinim, 1=Keşfet, 2=VixRex, 3=Profil.
  static void navigateToHomeShell(BuildContext context,
      {int initialIndex = 0, String? initialVitrinName}) {
    if (initialVitrinName != null || initialIndex > 1) {
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
      if (initialIndex == 1) {
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

  /// Public vitrinden "Düzenle": her zaman Vitrinim sekmesine taze shell açar.
  static void navigateToMyVitrin(
    BuildContext context, {
    String? initialVitrinName,
  }) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => HomeShellScreen(
          initialIndex: 0,
          initialVitrinName: initialVitrinName,
        ),
      ),
      (_) => false,
    );
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
    try {
      return context.push('/bookings/$slug');
    } catch (_) {
      return Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookingManagementScreen(storeSlug: slug),
        ),
      );
    }
  }

  /// OneSignal / bildirim tıklamasından randevu yönetimine gider.
  static void openBookingFromNotification(String slug) {
    final trimmed = slug.trim();
    if (trimmed.isEmpty) return;
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    navigateToBookingManagement(ctx, slug: trimmed);
  }

  static Future<bool?> navigateToAppointmentTracker(BuildContext context,
      {required String slug, required String token}) {
    final path = PublicSiteConfig.buildBookingTrackerPath(slug, token);
    try {
      return context.push<bool>(path);
    } catch (_) {
      return Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) =>
              AppointmentTrackerScreen(storeSlug: slug, token: token),
        ),
      );
    }
  }

  static Future<dynamic> navigateToPublicBooking(
    BuildContext context, {
    required String slug,
  }) {
    final path = PublicSiteConfig.buildBookingPath(slug);
    try {
      return context.push(path);
    } catch (_) {
      return Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PublicBookingScreen(slug: slug),
        ),
      );
    }
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

  static void navigateToPublicProduct(
    BuildContext context, {
    required String storeSlug,
    required String productSlug,
  }) {
    final path = '/v/$storeSlug/urun/$productSlug';
    try {
      context.push(path);
    } catch (_) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PublicProductScreen(
            storeSlug: storeSlug,
            productSlug: productSlug,
          ),
        ),
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

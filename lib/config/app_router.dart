import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vixrex/config/legal_config.dart';
import 'package:vixrex/config/public_site_config.dart';
import 'package:vixrex/models/chat_message.dart';
import 'package:vixrex/screens/auth_screen.dart';
import 'package:vixrex/screens/blog_editor_screen.dart';
import 'package:vixrex/screens/booking_management_screen.dart';
import 'package:vixrex/screens/home_shell_screen.dart';
import 'package:vixrex/screens/landing_screen.dart';
import 'package:vixrex/screens/legal_screen.dart';
import 'package:vixrex/screens/public_site_redirect_screen.dart';
import 'package:vixrex/screens/vixrex_onboarding_chat_screen.dart';

class AppRouter {
  static const String landing = '/';
  static const String app = '/app';
  static const String home = '/home';
  static const String auth = '/auth';
  static const String onboardingChat = '/onboarding-chat';
  static const String consent = LegalConfig.consentPath;

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: landing,
    errorBuilder: (context, state) {
      final path = state.uri.path;
      if (path.startsWith('/v/')) {
        return PublicSiteRedirectScreen.fromPath(path);
      }
      final slug = PublicSiteConfig.resolveVitrinSlugFromPath(path);
      if (slug != null) {
        return PublicSiteRedirectScreen.fromPath('/v/$slug');
      }
      return const LandingScreen();
    },
    routes: [
      GoRoute(
        path: landing,
        builder: (context, state) {
          final uri = state.uri;
          final legalType = LegalScreen.typeFromRoute(uri.path);
          if (legalType != null) {
            return LegalScreen(type: legalType);
          }

          final slugPath = uri.path;
          if (slugPath.startsWith('/v/')) {
            return PublicSiteRedirectScreen.fromPath(slugPath);
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
        path: onboardingChat,
        builder: (context, state) {
          final initialName =
              state.extra is String ? state.extra as String : null;
          return VixRexOnboardingChatScreen(initialName: initialName);
        },
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
      // Müşteri yüzü tek kaynak: Next.js. Flutter /v/* sadece yönlendirir.
      GoRoute(
        path: '/v/:slug/randevu/:token',
        builder: (context, state) {
          return PublicSiteRedirectScreen.fromPath(state.uri.path);
        },
      ),
      GoRoute(
        path: '/v/:slug/randevu',
        builder: (context, state) {
          return PublicSiteRedirectScreen.fromPath(state.uri.path);
        },
      ),
      GoRoute(
        path: '/v/:slug/urun/:productSlug',
        builder: (context, state) {
          return PublicSiteRedirectScreen.fromPath(state.uri.path);
        },
      ),
      GoRoute(
        path: '/v/:slug',
        builder: (context, state) {
          return PublicSiteRedirectScreen.fromPath(state.uri.path);
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
          final type =
              LegalScreen.typeFromRoute(routePath) ?? LegalPageType.privacy;
          return LegalScreen(type: type);
        },
      ),
    ],
  );

  /// Müşteri Next.js URL'sini dış tarayıcıda açar (web + native).
  static Future<bool> openPublicUrl(
    BuildContext? context,
    String url, {
    String failureMessage = 'Müşteri vitrini açılamadı.',
  }) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return false;

    var launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }

    if (!launched && context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failureMessage)),
      );
    }
    return launched;
  }

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

  static void navigateToOnboardingChat(
    BuildContext context, {
    String? initialName,
  }) {
    final name = initialName?.trim();
    final extra = (name != null && name.isNotEmpty) ? name : null;
    try {
      context.go(onboardingChat, extra: extra);
    } catch (_) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => VixRexOnboardingChatScreen(initialName: extra),
        ),
        (route) => false,
      );
    }
  }

  /// Ana kabuk. [initialIndex]: 0=Vitrinim, 1=Keşfet, 2=VixRex, 3=Profil.
  static void navigateToHomeShell(
    BuildContext context, {
    int initialIndex = 0,
    String? initialVitrinName,
    VixRexAction? initialVixRexAction,
  }) {
    final needsFreshShell = initialVitrinName != null ||
        initialIndex > 1 ||
        initialVixRexAction != null;
    if (needsFreshShell) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => HomeShellScreen(
            initialIndex: initialIndex,
            initialVitrinName: initialVitrinName,
            initialVixRexAction: initialVixRexAction,
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
            initialVixRexAction: initialVixRexAction,
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

  static Future<void> navigateToAppointmentTracker(
    BuildContext context, {
    required String slug,
    required String token,
  }) {
    return openPublicUrl(
      context,
      PublicSiteConfig.buildBookingTrackerLink(slug, token),
      failureMessage: 'Randevu takip sayfası açılamadı.',
    );
  }

  static Future<void> navigateToPublicBooking(
    BuildContext context, {
    required String slug,
  }) {
    return openPublicUrl(
      context,
      PublicSiteConfig.buildBookingLink(slug),
      failureMessage: 'Randevu sayfası açılamadı.',
    );
  }

  /// Müşteri vitrini: her platformda Next.js public URL.
  static Future<void> navigateToPublicVitrin(
    BuildContext context,
    String slug,
  ) async {
    final normalizedSlug = slug.trim();
    if (normalizedSlug.isEmpty) return;

    await openPublicUrl(
      context,
      PublicSiteConfig.buildVitrinLink(normalizedSlug),
      failureMessage: 'Public vitrin yeni sekmede açılamadı.',
    );
  }

  static Future<void> navigateToPublicProduct(
    BuildContext context, {
    required String storeSlug,
    required String productSlug,
  }) {
    return openPublicUrl(
      context,
      PublicSiteConfig.buildProductLink(storeSlug, productSlug),
      failureMessage: 'Ürün sayfası açılamadı.',
    );
  }

  static void push(BuildContext context, String path) {
    try {
      context.push(path);
    } catch (_) {
      // Fallback for isolated testing/errors
    }
  }
}

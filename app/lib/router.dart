import 'package:go_router/go_router.dart';

import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/main_navigation.dart';
import 'presentation/screens/onboarding/onboarding_flow.dart';
import 'state/session_controller.dart';

abstract final class Routes {
  static const home = '/';
  static const login = '/giris';
  static const onboarding = '/karsilama';

  /// Ana sayfada belirli bir sekmeyi açar: `Routes.tab(MainTab.collections)`.
  static String tab(MainTab tab) => '/?sekme=${tab.slug}';
}

/// Oturum durumuna göre yönlendirir: oturum yoksa giriş, karşılama akışı
/// bitmediyse karşılama, ikisi de tamamsa ana sayfa.
GoRouter buildRouter(SessionController session) => GoRouter(
  initialLocation: Routes.home,
  refreshListenable: session,
  redirect: (context, state) {
    final location = state.matchedLocation;
    final user = session.user;
    if (user == null) return location == Routes.login ? null : Routes.login;
    if (!user.onboarded) {
      return location == Routes.onboarding ? null : Routes.onboarding;
    }
    if (location == Routes.login || location == Routes.onboarding) {
      return Routes.home;
    }
    return null;
  },
  routes: [
    GoRoute(
      path: Routes.home,
      builder: (context, state) => MainNavigation(
        initialTab: MainTab.fromSlug(state.uri.queryParameters['sekme']),
      ),
    ),
    GoRoute(
      path: Routes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: Routes.onboarding,
      builder: (context, state) => const OnboardingFlow(),
    ),
  ],
);

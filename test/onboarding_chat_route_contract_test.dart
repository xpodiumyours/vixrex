import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/config/app_router.dart';

void main() {
  test('onboarding chat route is single dedicated path', () {
    expect(AppRouter.onboardingChat, '/onboarding-chat');
    expect(AppRouter.onboardingChat, isNot(AppRouter.home));
    expect(AppRouter.onboardingChat, isNot(AppRouter.app));
    expect(AppRouter.onboardingChat, isNot(AppRouter.auth));
  });
}

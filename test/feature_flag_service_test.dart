import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/services/feature_flag_service.dart';

void main() {
  group('Akıllı Motor runtime kill-switch', () {
    test('iki flag de açıkken storefront motoru açılır', () {
      expect(
        smartEngineStorefrontEnabledFromMap(
          {
            vixrexSmartEngineFlag: true,
            vixrexSmartEngineStorefrontFlag: true,
          },
          loaded: true,
        ),
        isTrue,
      );
    });

    test('eksik, kapalı veya yüklenmemiş flag fail-closed', () {
      expect(
        smartEngineStorefrontEnabledFromMap(
          {vixrexSmartEngineFlag: true},
          loaded: true,
        ),
        isFalse,
      );
      expect(
        smartEngineStorefrontEnabledFromMap(
          {
            vixrexSmartEngineFlag: true,
            vixrexSmartEngineStorefrontFlag: false,
          },
          loaded: true,
        ),
        isFalse,
      );
      expect(
        smartEngineStorefrontEnabledFromMap(
          {
            vixrexSmartEngineFlag: true,
            vixrexSmartEngineStorefrontFlag: true,
          },
          loaded: false,
        ),
        isFalse,
      );
    });
  });
}

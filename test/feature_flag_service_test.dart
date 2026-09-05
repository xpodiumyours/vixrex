import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/services/feature_flag_service.dart';

void main() {
  group('Akıllı Motor kill-switch', () {
    test('iki flag açıkken motor açılır', () {
      final flags = <String, bool>{
        vixrexSmartEngineFlag: true,
        vixrexSmartEngineStorefrontFlag: true,
      };
      final result = smartEngineStorefrontEnabledFromMap(flags, loaded: true);
      expect(result, isTrue);
    });

    test('eksik flag fail-closed', () {
      final flags = <String, bool>{vixrexSmartEngineFlag: true};
      final result = smartEngineStorefrontEnabledFromMap(flags, loaded: true);
      expect(result, isFalse);
    });

    test('kapalı storefront flag fail-closed', () {
      final flags = <String, bool>{
        vixrexSmartEngineFlag: true,
        vixrexSmartEngineStorefrontFlag: false,
      };
      final result = smartEngineStorefrontEnabledFromMap(flags, loaded: true);
      expect(result, isFalse);
    });

    test('yüklenmemiş flags fail-closed', () {
      final flags = <String, bool>{
        vixrexSmartEngineFlag: true,
        vixrexSmartEngineStorefrontFlag: true,
      };
      final result = smartEngineStorefrontEnabledFromMap(flags, loaded: false);
      expect(result, isFalse);
    });
  });
}

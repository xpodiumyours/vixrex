import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/services/feature_flag_service.dart';

void main() {
  test('Blog capability is fail-closed', () {
    expect(
      smartEngineBlogEnabledFromMap(<String, bool>{}, loaded: false),
      isFalse,
    );
    expect(
      smartEngineBlogEnabledFromMap(
        <String, bool>{vixrexSmartEngineFlag: true},
        loaded: true,
      ),
      isFalse,
    );
    expect(
      smartEngineBlogEnabledFromMap(
        <String, bool>{
          vixrexSmartEngineFlag: true,
          vixrexSmartEngineBlogFlag: true,
        },
        loaded: true,
      ),
      isTrue,
    );
  });

  test('Blog OFF does not disable storefront capability', () {
    final flags = <String, bool>{
      vixrexSmartEngineFlag: true,
      vixrexSmartEngineStorefrontFlag: true,
      vixrexSmartEngineBlogFlag: false,
    };
    expect(smartEngineStorefrontEnabledFromMap(flags, loaded: true), isTrue);
    expect(smartEngineBlogEnabledFromMap(flags, loaded: true), isFalse);
  });
}

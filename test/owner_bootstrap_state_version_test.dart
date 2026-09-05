import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/models/owner_bootstrap_state.dart';

void main() {
  group('OwnerBootstrapState draft version', () {
    test('bootstrap RPC draft_version ve base_live_version değerlerini korur', () {
      final state = OwnerBootstrapState.fromJson({
        'has_store': true,
        'reason': 'OK',
        'slug': 'ornek-vitrin',
        'live_version': 9,
        'has_draft': true,
        'draft_version': 14,
        'base_live_version': 9,
        'draft_stale': false,
      });

      expect(state.hasStore, true);
      expect(state.liveVersion, 9);
      expect(state.draftVersion, 14);
      expect(state.baseLiveVersion, 9);
    });

    test('string gelen sürüm değerlerini de güvenli tamsayıya çevirir', () {
      final state = OwnerBootstrapState.fromJson({
        'has_store': true,
        'reason': 'OK',
        'draft_version': '21',
        'base_live_version': '18',
      });

      expect(state.draftVersion, 21);
      expect(state.baseLiveVersion, 18);
    });

    test('vitrin yoksa sürümler sıfırdır', () {
      final state = OwnerBootstrapState.fromJson({
        'has_store': false,
        'reason': 'NO_STORE',
      });

      expect(state.draftVersion, 0);
      expect(state.baseLiveVersion, 0);
    });
  });
}

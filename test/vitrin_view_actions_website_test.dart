import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/widgets/vitrin_view/vitrin_view_actions.dart';

void main() {
  group('publicWebsiteActionUrl', () {
    test('publicMode gerçek website döner, publicLink değil', () {
      final store = StoreData(
        name: 'Test',
        website: 'https://ornek.com',
      );
      final url = VitrinViewActions.publicWebsiteActionUrl(
        storeData: store,
        publicLink: 'https://vixrex-public.vercel.app/v/test',
        publicMode: true,
      );
      expect(url, contains('ornek.com'));
      expect(url, isNot(contains('vixrex-public.vercel.app')));
    });

    test('website boşsa publicMode boş URL', () {
      final store = StoreData(name: 'Test', website: '');
      final url = VitrinViewActions.publicWebsiteActionUrl(
        storeData: store,
        publicLink: 'https://vixrex-public.vercel.app/v/test',
        publicMode: true,
      );
      expect(url, isEmpty);
    });
  });
}

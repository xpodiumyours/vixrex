import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// implementation_plan.md Commit 1 + Commit 2: "Önizle" ekranının artık
/// taslak/yayın ayrımını kendisi yapmadığını, bu ayrımın
/// StoreEditorController.openOwnerPreview() arkasına taşındığını kilitler.
/// Davranışsal doğrulama (hangi URL üretiliyor) için bkz.
/// test/store_editor_controller_test.dart.
void main() {
  group('Önizle ekranı — taslak/yayın ayrımını kendisi yapmaz', () {
    final formSectionSource =
        File(
          'lib/screens/my_vitrin/sections/vitrin_form_section.dart',
        ).readAsStringSync();
    final openInAppPreview = formSectionSource.substring(
      formSectionSource.indexOf('Future<void> _openInAppPreview'),
      formSectionSource.indexOf(
        'Future<void> _copyDisplayLink',
        formSectionSource.indexOf('Future<void> _openInAppPreview'),
      ),
    );

    test('tek giriş noktası controller.openOwnerPreview() çağırır', () {
      expect(
        openInAppPreview,
        contains('final owner = await controller.openOwnerPreview();'),
      );
      expect(openInAppPreview, contains('AppRouter.openPublicUrl('));
    });

    test('ekran artık isLive/canEditRemote dallanması içermez', () {
      expect(openInAppPreview, isNot(contains('isLive')));
      expect(openInAppPreview, isNot(contains('canEditRemote')));
      expect(openInAppPreview, isNot(contains('navigateToPublicVitrin')));
    });
  });

  group('OwnerPreviewLink — taslak/yayın ayrımı controller içinde', () {
    final controllerSource =
        File('lib/controllers/store_editor_controller.dart').readAsStringSync();
    final openOwnerPreview = controllerSource.substring(
      controllerSource.indexOf('Future<OwnerPreviewLink> openOwnerPreview'),
    );
    final ownerPreviewMethod = openOwnerPreview.substring(
      0,
      openOwnerPreview.indexOf('\n  }') + 4,
    );

    test(
      'yayınlanmış vitrin için bugün hâlâ sahip bağlamı olmayan düz müşteri linkini döndürür (Commit 3/4 sonrası değişecek geçici uyumluluk)',
      () {
        expect(ownerPreviewMethod, contains('if (isLive)'));
        expect(
          ownerPreviewMethod,
          contains('PublicSiteConfig.buildVitrinLink(slug)'),
        );
        expect(ownerPreviewMethod, isNot(contains('preview_token')));
        expect(ownerPreviewMethod, isNot(contains('buildVitrinPreviewLink')));
      },
    );

    test(
      'taslak için previewDraftLink() üzerinden preview_token linki üretir',
      () {
        expect(ownerPreviewMethod, contains('await previewDraftLink()'));
      },
    );
  });
}

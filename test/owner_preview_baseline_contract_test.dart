import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// implementation_plan.md Commit 1 + Commit 2 + Commit 5: "Önizle" ekranının
/// taslak/yayın ayrımını kendisi yapmadığını, bu ayrımın
/// StoreEditorController.openOwnerPreview() arkasına taşındığını kilitler.
/// Commit 5 sonrası openOwnerPreview her iki durumda da Next.js sahip giriş
/// adresini (/api/owner-session) üretir; kalıcı edit_token veya preview_token
/// URL'ye yazılmaz. Davranışsal doğrulama (hangi URL üretiliyor) için bkz.
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

  group('OwnerPreviewLink — taslak/yayın ayrımı sahip önizleme modülünde', () {
    final controllerSource =
        File('lib/controllers/store_editor_controller.dart').readAsStringSync();
    final serviceSource =
        File('lib/services/owner_preview_service.dart').readAsStringSync();
    final openOwnerPreview = controllerSource.substring(
      controllerSource.indexOf('Future<OwnerPreviewLink> openOwnerPreview'),
    );
    final ownerPreviewMethod = openOwnerPreview.substring(
      0,
      openOwnerPreview.indexOf('\n  }') + 4,
    );

    test('her iki durumda da sahip oturumu akışından giriş adresi üretir', () {
      expect(ownerPreviewMethod, contains('_ownerPreviewService.open('));
      expect(serviceSource, contains('_createOwnerSession'));
      expect(serviceSource, contains('buildOwnerSessionEntryLink'));
      expect(ownerPreviewMethod, isNot(contains('buildVitrinLink')));
    });

    test('kalıcı edit_token veya preview_token asla URL\'ye yazılmaz', () {
      expect(ownerPreviewMethod, isNot(contains('preview_token')));
      expect(ownerPreviewMethod, isNot(contains('buildVitrinPreviewLink')));
      expect(ownerPreviewMethod, isNot(contains('await previewDraftLink()')));
    });

    test('yayınlanmış vitrin canlı link yerine sahip oturumu oluşturur', () {
      expect(serviceSource, contains('publishedInfo.isComplete'));
      expect(serviceSource, contains('_ensureWorkingDraft'));
      expect(serviceSource, isNot(contains('canEditRemote')));
      expect(
        serviceSource,
        isNot(contains('OwnerPreviewLink(PublicSiteConfig.buildVitrinLink(')),
      );
    });
  });

  group('PublicLinkCard — yalnız Önizle sahip moduna girer', () {
    final formSectionSource =
        File(
          'lib/screens/my_vitrin/sections/vitrin_form_section.dart',
        ).readAsStringSync();
    final buildPublicLinkCard = formSectionSource.substring(
      formSectionSource.indexOf('Widget _buildPublicLinkCard'),
      formSectionSource.indexOf('// Taslak/yayın ayrımı controller'),
    );

    test('Önizle tek girişi controller.openOwnerPreview() üzerinden yapar', () {
      expect(
        buildPublicLinkCard,
        contains('onPreview: () => _openInAppPreview'),
      );
    });

    test('Kopyala/Paylaş/Canlıyı Aç müşteri bağlantısında kalır', () {
      expect(buildPublicLinkCard, contains('onCopyLink:'));
      expect(
        buildPublicLinkCard,
        contains('onShareLink: hasPublished ? () => _shareLink(context)'),
      );
      expect(
        buildPublicLinkCard,
        contains('onOpenLiveLink: hasPublished ? () => _openLink(context)'),
      );
    });
  });
}

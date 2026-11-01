import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/widgets/editor/legal_consent_section.dart';

void main() {
  testWidgets('Aydınlatma ve açık rıza bağımsız işaretlenir', (tester) async {
    final events = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LegalConsentSection(
              canAccept: true,
              isLoading: false,
              errorText: null,
              privacyNoticeAcknowledged: false,
              termsAccepted: false,
              publicationConsentAccepted: false,
              onPrivacyChanged: (value) => events.add('privacy:$value'),
              onTermsChanged: (value) => events.add('terms:$value'),
              onPublicationChanged: (value) => events.add('publication:$value'),
              onReloadDocuments: () {},
              onOpenLegalPage: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('privacy-notice-checkbox')));
    expect(events, ['privacy:true']);

    await tester.tap(find.byKey(const ValueKey('terms-acceptance-checkbox')));
    expect(events, ['privacy:true', 'terms:true']);

    await tester.tap(find.byKey(const ValueKey('publication-consent-checkbox')));
    expect(events, ['privacy:true', 'terms:true', 'publication:true']);
  });

  testWidgets(
    'Aydınlatma yüklenirken hiçbir onay değiştirilemez',
    (tester) async {
    var changed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LegalConsentSection(
              canAccept: false,
              isLoading: true,
              errorText: null,
              privacyNoticeAcknowledged: false,
              termsAccepted: false,
              publicationConsentAccepted: false,
              onPrivacyChanged: (_) => changed = true,
              onTermsChanged: (_) => changed = true,
              onPublicationChanged: (_) => changed = true,
              onReloadDocuments: () {},
              onOpenLegalPage: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('privacy-notice-checkbox')));
      expect(changed, isFalse);
    },
  );
}

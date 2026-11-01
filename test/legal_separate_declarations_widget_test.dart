import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/widgets/editor/legal_consent_section.dart';

void main() {
  testWidgets('Üç beyan bağımsızdır', (tester) async {
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

    Future<void> tapCheckbox(String key) async {
      final checkbox = find.descendant(
        of: find.byKey(ValueKey(key)),
        matching: find.byType(Checkbox),
      );
      await tester.ensureVisible(checkbox);
      await tester.pumpAndSettle();
      await tester.tap(checkbox);
      await tester.pump();
    }

    await tapCheckbox('privacy-notice-checkbox');
    expect(events, ['privacy:true']);

    await tapCheckbox('terms-acceptance-checkbox');
    expect(events, ['privacy:true', 'terms:true']);

    await tapCheckbox('publication-consent-checkbox');
    expect(events, ['privacy:true', 'terms:true', 'publication:true']);
  });

  testWidgets('Yüklenirken değişiklik engellenir', (tester) async {
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

    final checkbox = find.descendant(
      of: find.byKey(const ValueKey('privacy-notice-checkbox')),
      matching: find.byType(Checkbox),
    );
    await tester.tap(checkbox);
    expect(changed, isFalse);
  });
}

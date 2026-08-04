import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/widgets/editor/public_link_card.dart';

/// implementation_plan.md Commit 5: Kopyala/Paylaş/Canlıyı Aç düğmeleri
/// müşteri bağlantısında kalır; yalnız "Önizle" sahip moduna girer.
void main() {
  int copyCalls = 0;
  int previewCalls = 0;
  int shareCalls = 0;
  int liveCalls = 0;
  int publishCalls = 0;

  setUp(() {
    copyCalls = 0;
    previewCalls = 0;
    shareCalls = 0;
    liveCalls = 0;
    publishCalls = 0;
  });

  Future<void> pumpCard(
    WidgetTester tester, {
    required bool isLive,
    bool withShare = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PublicLinkCard(
            displayLink: 'https://vixrex-public.vercel.app/v/ornek',
            isLive: isLive,
            onCopyLink: () => copyCalls++,
            onPreview: () => previewCalls++,
            onShareLink: withShare ? () => shareCalls++ : null,
            onOpenLiveLink: isLive ? () => liveCalls++ : null,
            onScrollToPublish: isLive ? null : () => publishCalls++,
          ),
        ),
      ),
    );
  }

  testWidgets('taslak durumda Kopyala/Önizle/Yayına al vardır, Paylaş yoktur', (
    WidgetTester tester,
  ) async {
    await pumpCard(tester, isLive: false, withShare: false);

    expect(find.text('Kopyala'), findsOneWidget);
    expect(find.text('Önizle'), findsOneWidget);
    expect(find.text('Yayına al'), findsOneWidget);
    expect(find.text('Paylaş'), findsNothing);
    expect(find.text('Canlı'), findsNothing);
    expect(find.text('Yayından sonra tarayıcıda açılır.'), findsOneWidget);

    await tester.tap(find.text('Önizle'));
    await tester.tap(find.text('Kopyala'));
    await tester.tap(find.text('Yayına al'));
    await tester.tap(find.byTooltip('Önizlemeyi aç'));

    expect(previewCalls, 2);
    expect(copyCalls, 1);
    expect(publishCalls, 1);
    expect(shareCalls, 0);
    expect(liveCalls, 0);
  });

  testWidgets(
    'yayın durumunda Kopyala/Önizle/Paylaş vardır ve Canlıyı Aç canlı linki açar',
    (WidgetTester tester) async {
      await pumpCard(tester, isLive: true);

      expect(find.text('Kopyala'), findsOneWidget);
      expect(find.text('Önizle'), findsOneWidget);
      expect(find.text('Paylaş'), findsOneWidget);
      expect(find.text('Yayına al'), findsNothing);
      expect(find.text('Canlı'), findsOneWidget);

      await tester.tap(find.text('Önizle'));
      await tester.tap(find.text('Kopyala'));
      await tester.tap(find.text('Paylaş'));
      await tester.tap(find.byTooltip('Canlı vitrin linkini aç'));

      expect(previewCalls, 1);
      expect(copyCalls, 1);
      expect(shareCalls, 1);
      expect(liveCalls, 1);
      expect(publishCalls, 0);
    },
  );

  testWidgets(
    'Canlıyı Aç yalnız canlı durumda onOpenLiveLink\'e gider, Önizle değil',
    (WidgetTester tester) async {
      await pumpCard(tester, isLive: true);

      final liveButton = find.byTooltip('Canlı vitrin linkini aç');
      expect(liveButton, findsOneWidget);

      await tester.tap(liveButton);
      expect(liveCalls, 1);
      expect(previewCalls, 0);
    },
  );
}

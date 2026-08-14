import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/widgets/editor/qr_code_bottom_sheet.dart';
import 'package:vixrex/widgets/shell/shell_sidebar.dart';
import 'package:vixrex/widgets/shell/shell_status_bar.dart';

void main() {
  testWidgets('masaüstü menüsü seçim ve arama olaylarını dışarı taşır', (
    tester,
  ) async {
    final searchController = TextEditingController();
    addTearDown(searchController.dispose);
    var selectedIndex = -1;
    var changedQuery = '';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 220,
            height: 600,
            child: ShellSidebar(
              items: const [
                ShellSidebarItem(
                  icon: Icons.storefront_outlined,
                  selectedIcon: Icons.storefront,
                  label: 'Vitrinim',
                ),
                ShellSidebarItem(
                  icon: Icons.explore_outlined,
                  selectedIcon: Icons.explore,
                  label: 'Keşfet',
                ),
              ],
              selectedIndex: 0,
              onSelected: (index) => selectedIndex = index,
              searchController: searchController,
              onSearchSubmitted: (_) {},
              onSearchChanged: (value) => changedQuery = value,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Keşfet'));
    await tester.enterText(find.byType(TextField), 'kahve');

    expect(selectedIndex, 1);
    expect(changedQuery, 'kahve');
  });

  testWidgets('durum şeridi yayın durumuna uygun aksiyonları gösterir', (
    tester,
  ) async {
    var publishCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShellStatusBar(
            isPublished: false,
            onPublish: () => publishCount++,
          ),
        ),
      ),
    );

    expect(find.text('Yayında değil'), findsOneWidget);
    expect(find.text('Vitrini yayınla'), findsOneWidget);
    expect(find.text('Kopyala'), findsNothing);

    await tester.tap(find.text('Vitrini yayınla'));
    expect(publishCount, 1);
  });

  testWidgets('yayındaki uzun vitrin adresi masaüstü şeridini taşırmaz', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 680,
            child: ShellStatusBar(
              isPublished: true,
              publicLink:
                  'vixrex.example/v/cok-uzun-bir-vitrin-adresi-'
                  'tasirma-olusturmamali',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Yayında'), findsOneWidget);
    expect(find.text('Kopyala'), findsOneWidget);
    expect(find.text('QR'), findsOneWidget);
    expect(find.text('Vitrini aç'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ortak QR sheet aynı QR bileşenini kullanır', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: QrCodeBottomSheet(
            title: 'Vitrin QR Kodunuz',
            link: 'https://example.com/v/deneme',
          ),
        ),
      ),
    );

    expect(find.text('Vitrin QR Kodunuz'), findsOneWidget);
    expect(find.text('https://example.com/v/deneme'), findsOneWidget);
  });
}

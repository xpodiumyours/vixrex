import 'package:flutter_test/flutter_test.dart';
import 'package:vitrinx/main.dart';

void main() {
  testWidgets('VitrinX giriş ekranı testleri', (WidgetTester tester) async {
    await tester.pumpWidget(const VitrinXApp());
    await tester.pumpAndSettle();

    expect(find.text('VitrinX'), findsAtLeastNWidgets(1));
    expect(find.textContaining('Vitrin Merkezi'), findsOneWidget);
    expect(find.text('Hemen Başla'), findsOneWidget);
    expect(find.text('Örneği Gör'), findsOneWidget);
  });
}

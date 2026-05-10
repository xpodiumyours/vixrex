import 'package:flutter_test/flutter_test.dart';
import 'package:vitrinx/main.dart';

void main() {
  testWidgets('VitrinX giriş ekranı testleri', (WidgetTester tester) async {
    await tester.pumpWidget(const VitrinXApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('VITRINX'), findsAtLeastNWidgets(1));
    expect(find.text('VİTRİNİNİ ŞİMDİ OLUŞTUR'), findsOneWidget);
    expect(find.text('3 Adımda Yayına Geçin'), findsOneWidget);
  });
}

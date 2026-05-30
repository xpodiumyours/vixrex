import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitrinx/main.dart';
import 'package:vitrinx/screens/landing_screen.dart';

void main() {
  testWidgets('VitrinX giriş ekranı testleri', (WidgetTester tester) async {
    await tester.pumpWidget(const VitrinXApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('VITRINX'), findsAtLeastNWidgets(1));
    expect(find.text('Vitrinimi Oluştur'), findsAtLeastNWidgets(1));
    expect(find.text('Dakikalar içinde yayına hazır'), findsOneWidget);
  });

  testWidgets('Geçersiz route giriş ekranına düşer', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const VitrinXApp());
    await tester.pump();

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamed('/gecersiz-route');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(LandingScreen), findsAtLeastNWidgets(1));
  });
}

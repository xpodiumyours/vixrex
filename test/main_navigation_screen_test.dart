import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitrinx/screens/profile_screen.dart';
import 'package:vitrinx/screens/xrex_screen.dart';

void main() {
  testWidgets('X-rex ekranı Türkçe başlıkları gösterir', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: XrexScreen()));

    expect(find.text('X-rex Yapay Zekâ'), findsOneWidget);
    expect(find.text('VitrinX Yapay Zekâ Asistanı'), findsOneWidget);
  });

  testWidgets('Profil ekranı Türkçe başlığı gösterir', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));

    expect(find.text('Profil'), findsOneWidget);
    expect(find.text('VitrinX Kullanıcısı'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/widgets/unsaved_changes_dialog.dart';

void main() {
  testWidgets('kaydedilmemiş değişiklik diyaloğu ekranda kalmayı destekler', (
    tester,
  ) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder:
              (context) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    result = await showUnsavedChangesDialog(context);
                  },
                  child: const Text('Çık'),
                ),
              ),
        ),
      ),
    );

    await tester.tap(find.text('Çık'));
    await tester.pumpAndSettle();
    expect(find.text('Değişiklikler kaydedilmedi'), findsOneWidget);

    await tester.tap(find.text('Düzenlemeye Devam Et'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });
}

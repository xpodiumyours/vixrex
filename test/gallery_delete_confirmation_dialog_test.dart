import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitrinx/widgets/gallery_delete_confirmation_dialog.dart';

void main() {
  testWidgets('kapak fotoğrafı silme onay ister', (tester) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await showGalleryDeleteConfirmationDialog(
                    context,
                    isCover: true,
                  );
                },
                child: const Text('Galeriden sil'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Galeriden sil'));
    await tester.pumpAndSettle();

    expect(find.text('Kapak fotoğrafını sil?'), findsOneWidget);
    expect(find.textContaining('sıradaki fotoğraf kapak olur'), findsOneWidget);

    await tester.tap(find.text('İptal'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });

  testWidgets('silme onaylandığında true döner', (tester) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await showGalleryDeleteConfirmationDialog(
                    context,
                    isCover: false,
                  );
                },
                child: const Text('Galeriden sil'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Galeriden sil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sil'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });
}

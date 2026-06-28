import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitrinx/models/legal_document.dart';
import 'package:vitrinx/screens/legal_screen.dart';
import 'package:vitrinx/services/legal_document_service.dart';

class FakeLegalDocumentService extends LegalDocumentService {
  final LegalDocument? document;
  final Object? error;

  const FakeLegalDocumentService({this.document, this.error});

  @override
  Future<LegalDocument> loadActiveDocument(String documentType) async {
    if (error != null) throw error!;
    return document!;
  }
}

void main() {
  const document = LegalDocument(
    type: 'privacy',
    version: 'privacy-v1',
    title: 'Gizlilik ve KVKK Politikası',
    subtitle: 'Test açıklaması',
    contentHash: 'hash-v1',
    sections: [
      LegalDocumentSection(title: 'Dinamik Başlık', body: 'Dinamik içerik'),
    ],
  );

  testWidgets('LegalScreen aktif sürümlü belgeyi gösterir', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LegalScreen(
          type: LegalPageType.privacy,
          documentService: FakeLegalDocumentService(document: document),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Dinamik Başlık'), findsOneWidget);
    expect(find.text('Dinamik içerik'), findsOneWidget);
    expect(find.text('Sürüm: privacy-v1'), findsOneWidget);
  });

  testWidgets('LegalScreen yükleme hatasında eski metne düşmez', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LegalScreen(
          type: LegalPageType.privacy,
          documentService: FakeLegalDocumentService(
            error: LegalDocumentException('test error'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Tekrar Dene'), findsOneWidget);
    expect(find.text('Ürün Sahibi'), findsNothing);
  });

  test('legal route eşleştirmesi kısa ve uyumluluk yollarını çözer', () {
    expect(LegalScreen.typeFromRoute('/consent'), LegalPageType.consent);
    expect(LegalScreen.typeFromRoute('/legal/consent'), LegalPageType.consent);
  });
}

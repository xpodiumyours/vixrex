import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/core/result.dart';
import 'package:vixrex/models/legal_document.dart';
import 'package:vixrex/screens/legal_screen.dart';
import 'package:vixrex/services/legal_document_service.dart';
import 'package:vixrex/utils/failure.dart';

class FakeLegalDocumentService extends LegalDocumentService {
  final LegalDocument? document;
  final Failure? failure;

  const FakeLegalDocumentService({this.document, this.failure});

  @override
  Future<Result<LegalDocument>> loadActiveDocument(String documentType) async {
    if (failure != null) return Result.failure(failure!);
    return Result.success(document!);
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
      MaterialApp(
        home: LegalScreen(
          type: LegalPageType.privacy,
          documentService: FakeLegalDocumentService(
            failure: Failure('test error'),
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
  });
}

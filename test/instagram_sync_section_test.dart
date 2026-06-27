import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/services/instagram_sync_service.dart';
import 'package:vitrinx/widgets/instagram_sync_section.dart';

class _FakeInstagramSyncService extends InstagramSyncService {
  final InstagramConnectionStatus status;

  const _FakeInstagramSyncService(this.status);

  @override
  Future<InstagramConnectionStatus> getStatus({
    required String storeSlug,
    required String editToken,
  }) async => status;
}

Widget _buildSubject(InstagramConnectionStatus status) {
  return MaterialApp(
    home: Scaffold(
      body: InstagramSyncSection(
        storeSlug: 'aymira-butik',
        editToken: 'secret-token',
        defaultCategory: 'Giyim & Butik',
        service: _FakeInstagramSyncService(status),
        onProductImported: (Product _) {},
        onMessage: (_) {},
      ),
    ),
  );
}

void main() {
  testWidgets('bağlı olmayan hesap için bağlama aksiyonunu gösterir', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildSubject(
        const InstagramConnectionStatus(
          connected: false,
          status: 'not_connected',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Instagram’a Bağla'), findsOneWidget);
    expect(find.text('Fotoğraf Seç'), findsNothing);
  });

  testWidgets(
    'bağlı hesap için kullanıcı adı ve fotoğraf aksiyonunu gösterir',
    (tester) async {
      await tester.pumpWidget(
        _buildSubject(
          const InstagramConnectionStatus(
            connected: true,
            status: 'connected',
            username: 'aymira',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('@aymira bağlı'), findsOneWidget);
      expect(find.text('Fotoğraf Seç'), findsOneWidget);
    },
  );
}

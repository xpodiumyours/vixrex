import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vitrinx/services/instagram_sync_service.dart';

void main() {
  group('InstagramSyncService', () {
    test('bağlantı durumunu POST ile güvenli gövdeden okur', () async {
      late http.Request capturedRequest;
      final service = InstagramSyncService(
        originOverride: 'https://vitrinx.app',
        httpClient: MockClient((request) async {
          capturedRequest = request;
          return http.Response(
            jsonEncode({
              'connected': true,
              'status': 'connected',
              'username': 'aymira',
              'accountType': 'BUSINESS',
              'expiresAt': '2026-08-01T12:00:00.000Z',
            }),
            200,
          );
        }),
      );

      final status = await service.getStatus(
        storeSlug: 'aymira-butik',
        editToken: 'secret-token',
      );

      expect(capturedRequest.method, 'POST');
      expect(capturedRequest.url.path, '/api/instagram/status');
      expect(capturedRequest.url.query, isEmpty);
      expect(jsonDecode(capturedRequest.body), {
        'storeSlug': 'aymira-butik',
        'editToken': 'secret-token',
      });
      expect(status.connected, isTrue);
      expect(status.username, 'aymira');
    });

    test('aktarılmış ürünü Product modeline dönüştürür', () async {
      final service = InstagramSyncService(
        originOverride: 'https://vitrinx.app',
        httpClient: MockClient((request) async {
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'product': {
                  'id': 'ig-123',
                  'slug': 'triko-hirka',
                  'name': 'Triko Hırka',
                  'price': '1250 TL',
                  'description': 'Yeni sezon triko hırka.',
                  'imagePath': 'https://example.com/triko.jpg',
                  'category': 'Giyim & Butik',
                  'stockStatus': 'Mevcut',
                  'source': 'instagram',
                  'sourceMediaId': '123',
                },
              }),
            ),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );

      final product = await service.importProduct(
        storeSlug: 'aymira-butik',
        editToken: 'secret-token',
        mediaId: '123',
        price: '1250 TL',
        category: 'Giyim & Butik',
      );

      expect(product.name, 'Triko Hırka');
      expect(product.slug, 'triko-hirka');
      expect(product.source, 'instagram');
      expect(product.sourceMediaId, '123');
    });

    test('sunucu hata kodunu kullanıcı mesajına dönüştürür', () async {
      final service = InstagramSyncService(
        originOverride: 'https://vitrinx.app',
        httpClient: MockClient(
          (_) async => http.Response(
            jsonEncode({'message': 'INSTAGRAM_TOKEN_EXPIRED'}),
            409,
          ),
        ),
      );

      expect(
        () => service.listMedia(
          storeSlug: 'aymira-butik',
          editToken: 'secret-token',
        ),
        throwsA(
          isA<InstagramSyncException>().having(
            (error) => error.userMessage,
            'userMessage',
            contains('süresi dolmuş'),
          ),
        ),
      );
    });
  });
}

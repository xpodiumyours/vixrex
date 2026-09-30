import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vixrex/controllers/ocr_controller.dart';
import 'package:vixrex/controllers/store_editor_controller.dart';
import 'package:vixrex/core/result.dart';
import 'package:vixrex/models/detected_product.dart';
import 'package:vixrex/models/ocr_catalog_result.dart';
import 'package:vixrex/models/store_product.dart';
import 'package:vixrex/services/invoice_catalog/fatura_yayinla_servisi.dart';
import 'package:vixrex/services/ocr/ocr_service.dart';

// B2 (telefon yayın bağı): `yayınlaOnaylilar` önce mevcut saveApprovedProducts
// ile lokal kaydeder, SADECE sunucu UUID'si eldeki ürünler için
// FaturaYayinlaServisi.yayinla çağırır. Lokal `ocr_` ID ile ağa çıkılmaz.

/// Lokal yazma: `ocr_` ID aynen kalır (uzak yazma yokken editor.addProduct
/// davranışı — store_editor_controller.dart:735).
class _YerelEditor extends StoreEditorController {
  final List<Product> kalan = [];

  @override
  List<Product> get products => kalan;

  @override
  Future<Result<void>> addProduct(Product p) async {
    kalan.add(p);
    return const Result.success(null);
  }
}

/// Uzak yazma: ProductCatalogSyncService.addProduct sunucu UUID'sini ürünün
/// üstüne yazar (product_catalog_sync_service.dart:182). Bu taklit aynı şeyi
/// yapar; uydurma ID üretilmez, sabit fikstür kullanılır.
class _SunucuEditor extends StoreEditorController {
  final List<Product> kalan = [];
  final String uuid;

  _SunucuEditor(this.uuid);

  @override
  List<Product> get products => kalan;

  @override
  Future<Result<void>> addProduct(Product p) async {
    p.id = uuid;
    kalan.add(p);
    return const Result.success(null);
  }
}

DetectedProduct _onayliUrun() => DetectedProduct(
  id: 'ocr_invoice_1',
  name: 'Test Ürünü',
  source: 'ocr',
  price: 49.90,
  isApproved: true,
);

OcrController _denetleyici(StoreEditorController? editor) {
  final denetleyici = OcrController(
    ocrService: const OcrService(),
    editorController: editor,
  );
  denetleyici.scanMode = 'invoice';
  denetleyici.testSonucuYukle(
    OcrCatalogResult(
      rawText: '',
      products: [_onayliUrun()],
      confidence: 0.9,
    ),
  );
  return denetleyici;
}

void main() {
  // saveApprovedProducts içindeki ProductConversationLogger yerel geçmişe
  // yazar; testte platform kanalını sessize almak için bellek önbelleği.
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('OcrController.yayinlaOnaylilar — telefon yayın bağı', () {
    test('editör yoksa yayın çağrısı yapmaz', () async {
      var cagrildi = false;
      final servis = FaturaYayinlaServisi(
        httpClient: MockClient((request) async {
          cagrildi = true;
          return http.Response('{}', 200);
        }),
      );

      final sonuc = await _denetleyici(
        null,
      ).yayinlaOnaylilar(
        storeSlug: 'deneme-vitrin',
        editToken: 'token-1',
        yayinlaServisi: servis,
      );

      expect(sonuc.isFailure, isTrue);
      expect(cagrildi, isFalse);
    });

    test('onaylı ürün yoksa yayın çağrısı yapmaz', () async {
      var cagrildi = false;
      final servis = FaturaYayinlaServisi(
        httpClient: MockClient((request) async {
          cagrildi = true;
          return http.Response('{}', 200);
        }),
      );
      final editor = _YerelEditor();
      final denetleyici = OcrController(
        ocrService: const OcrService(),
        editorController: editor,
      );
      denetleyici.scanMode = 'invoice';
      denetleyici.testSonucuYukle(
        OcrCatalogResult(rawText: '', products: [], confidence: 0),
      );

      final sonuc = await denetleyici.yayinlaOnaylilar(
        storeSlug: 'deneme-vitrin',
        editToken: 'token-1',
        yayinlaServisi: servis,
      );

      expect(sonuc.isFailure, isTrue);
      expect(cagrildi, isFalse);
      expect(editor.kalan, isEmpty);
    });

    test('lokal ocr_ ID ile yayın çağrısı YAPILMAZ; kaydet akışı korunur',
        () async {
      var cagrildi = false;
      final servis = FaturaYayinlaServisi(
        httpClient: MockClient((request) async {
          cagrildi = true;
          return http.Response('{}', 200);
        }),
      );
      final editor = _YerelEditor();

      final sonuc = await _denetleyici(
        editor,
      ).yayinlaOnaylilar(
        storeSlug: 'deneme-vitrin',
        editToken: 'token-1',
        yayinlaServisi: servis,
      );

      expect(sonuc.isFailure, isTrue);
      expect(sonuc.failure?.message, contains('sunucu karşılığı'));
      expect(cagrildi, isFalse);
      // Mevcut kaydet akışı bozulmadı: ürün lokal editöre yazıldı.
      expect(editor.kalan, hasLength(1));
      expect(editor.kalan.first.id, startsWith('ocr_'));
    });

    test('sunucu UUIDsi varsa SADECE o ID ile /api/fatura-yayinla çağrılır',
        () async {
      const uuid = '123e4567-e89b-12d3-a456-426614174000';
      late http.BaseRequest yakalanan;
      final servis = FaturaYayinlaServisi(
        originOverride: 'https://vixrex-test.local',
        httpClient: MockClient((request) async {
          yakalanan = request;
          return http.Response(
            jsonEncode({
              'tamam': true,
              'yayinda': 1,
              'taslak': 0,
              'satirlar': [
                {'id': uuid, 'durum': 'yayinda'},
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      final editor = _SunucuEditor(uuid);

      final sonuc = await _denetleyici(
        editor,
      ).yayinlaOnaylilar(
        storeSlug: 'deneme-vitrin',
        editToken: 'token-1',
        yayinlaServisi: servis,
      );

      expect(sonuc.isSuccess, isTrue);
      expect(sonuc.data!.yayinda, 1);
      expect(yakalanan.method, 'POST');
      expect(yakalanan.url.path, '/api/fatura-yayinla');
      final govde = jsonDecode((yakalanan as http.Request).body) as Map;
      expect(govde['productIds'], [uuid]);
      expect(
        (govde['productIds'] as List).every(
          (e) => !(e as String).startsWith('ocr_'),
        ),
        isTrue,
      );
    });

    test('slug/jeton boşsa sunucu ID olsa bile ağa çıkılmaz', () async {
      const uuid = '123e4567-e89b-12d3-a456-426614174000';
      var cagrildi = false;
      final servis = FaturaYayinlaServisi(
        httpClient: MockClient((request) async {
          cagrildi = true;
          return http.Response('{}', 200);
        }),
      );

      final sonuc = await _denetleyici(
        _SunucuEditor(uuid),
      ).yayinlaOnaylilar(
        storeSlug: '',
        editToken: '',
        yayinlaServisi: servis,
      );

      expect(sonuc.isFailure, isTrue);
      expect(cagrildi, isFalse);
    });
  });
}

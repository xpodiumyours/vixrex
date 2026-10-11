import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vixrex/controllers/ocr_controller.dart';
import 'package:vixrex/controllers/store_editor_controller.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/models/invoice_product_draft.dart';
import 'package:vixrex/services/store_local_storage_service.dart';
import 'package:vixrex/services/invoice_catalog/fatura_islem_servisi.dart';
import 'package:vixrex/services/invoice_catalog/fatura_urun_kaydi_servisi.dart';
import 'package:vixrex/services/invoice_catalog/fatura_oku_servisi.dart';
import 'package:vixrex/widgets/ocr/ocr_result_list.dart';

Map<String, dynamic> _invoice() => {
  'islemKimligi': 'job-1',
  'satirlar': [
    {
      'ad': 'Peynir',
      'adet': 2.5,
      'sonuc': 'kanitli',
      'katalog': {
        'resmiAd': 'Üreticinin peyniri',
        'kategori': 'Şarküteri ve peynir',
        'kaynak': 'https://uretici.example/peynir',
        'ozellikler': [
          {'key': 'weight', 'label': 'Ambalaj ağırlığı', 'value': '2,5 KG'},
          {'key': 'milk', 'label': 'Süt türü', 'value': 'Keçi'},
        ],
        'urunVaryantlari': [
          {
            'id': 'peynir-keci',
            'secenekler': [
              {'key': 'milk', 'value': 'Keçi'},
              {'key': 'package', 'value': 'Teneke'},
            ],
            'barkod': '8681234567890',
            'gorseller': <String>[],
          },
        ],
        'gorseller': <String>[],
      },
      'sahipDurumu': {'onayli': true, 'satisFiyati': '150'},
    },
  ],
};

class _DelayedClient extends http.BaseClient {
  final Duration headerDelay;
  final Duration bodyDelay;
  _DelayedClient({
    this.headerDelay = Duration.zero,
    this.bodyDelay = Duration.zero,
  });

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    await Future<void>.delayed(headerDelay);
    return http.StreamedResponse(
      Stream.fromFuture(
        Future.delayed(bodyDelay, () => utf8.encode(jsonEncode(_invoice()))),
      ),
      200,
    );
  }
}

class _EmptyCategoryEditor extends StoreEditorController {
  _EmptyCategoryEditor() : super(initialData: StoreData(productCategories: []));

  @override
  PublishedVitrinInfo get publishedInfo => const PublishedVitrinInfo(
    slug: 'vitrin',
    publicLink: 'https://vixrex-test.local/vitrin',
    name: 'Vitrin',
    editToken: 'token',
  );

  @override
  Future<void> reloadRemoteProducts() async {}
}

void main() {
  test('Luna kategori, özellik ve varyantları kayıpsız taşınır', () {
    final result = const FaturaOkuServisi().cozumle(_invoice()).data!;
    final product = result.products.single;
    final draft = result.invoiceDrafts.single;
    final catalog =
        ((_invoice()['satirlar'] as List).single as Map)['katalog'] as Map;
    expect(product.category, catalog['kategori']);
    expect(draft.catalogAttributes, catalog['ozellikler']);
    expect(draft.catalogVariants, catalog['urunVaryantlari']);
    expect(
      draft.copyWith(salePrice: 200).catalogVariants,
      draft.catalogVariants,
    );
    expect(draft.toJson()['catalog_attributes'], catalog['ozellikler']);
  });
  test('Yalnız ham satırı okunan ürünün kaynak metni kartta korunur', () {
    final invoice = _invoice();
    final row = (invoice['satirlar'] as List).single as Map;
    row.remove('katalog');
    row['ad'] = '';
    row['model'] = '';
    row['barkod'] = '';
    row['hamSatir'] = 'Peynir teneke 2,5 KG';
    row['sonuc'] = 'eksik';
    final result = const FaturaOkuServisi().cozumle(invoice).data!;
    expect(result.products.single.name, row['hamSatir']);
    expect(result.invoiceDrafts.single.rawSourceLine, row['hamSatir']);
    expect(result.invoiceDrafts.single.etkinKartDurumu, KartDurumu.eksik);
  });

  test('Kesirli fatura miktarı stok adedine çevrilmez, onayı düşürmez', () {
    final result = const FaturaOkuServisi().cozumle(_invoice()).data!;
    expect(result.products.single.documentQuantity, isNull);
    expect(result.invoiceDrafts.single.quantity?.value, 2.5);
    expect(result.invoiceDrafts.single.stockQuantity, 2.5);
    expect(result.products.single.isApproved, isTrue);
    expect(result.invoiceDrafts.single.merchantApproved, isTrue);
  });

  test('Kayıtlı kesirli stok faturanın tam adedine geri çevrilmez', () {
    final invoice = _invoice();
    final row = (invoice['satirlar'] as List).single as Map;
    row['adet'] = 8;
    (row['sahipDurumu'] as Map)['stok'] = '3,75';
    final result = const FaturaOkuServisi().cozumle(invoice).data!;
    expect(result.invoiceDrafts.single.stockQuantity, 3.75);
    expect(result.products.single.documentQuantity, 8);
  });

  testWidgets('45 saniyeyi aşan araştırma yanıtı beklenir', (tester) async {
    var completed = false;
    var success = false;
    FaturaOkuServisi(
      originOverride: 'https://vixrex-test.local',
      httpClient: _DelayedClient(headerDelay: const Duration(seconds: 50)),
    ).oku(imageBytes: [1], storeSlug: 'vitrin', editToken: 'token').then((
      result,
    ) {
      completed = true;
      success = result.isSuccess;
    });
    await tester.pump();
    await tester.pump(const Duration(seconds: 46));
    expect(completed, isFalse);
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    expect(completed, isTrue);
    expect(success, isTrue);
  });

  testWidgets('İstek ve gövde okuması tek toplam bekleme süresini paylaşır', (
    tester,
  ) async {
    bool? success;
    FaturaOkuServisi(
      originOverride: 'https://vixrex-test.local',
      requestTimeout: const Duration(seconds: 60),
      httpClient: _DelayedClient(
        headerDelay: const Duration(seconds: 50),
        bodyDelay: const Duration(seconds: 20),
      ),
    ).oku(imageBytes: [1], storeSlug: 'vitrin', editToken: 'token').then((
      result,
    ) {
      success = result.isSuccess;
    });
    await tester.pump();
    await tester.pump(const Duration(seconds: 50));
    await tester.pump(const Duration(seconds: 9));
    expect(success, isNull);
    await tester.pump(const Duration(seconds: 1));
    expect(success, isFalse);
    await tester.pump(const Duration(seconds: 10));
  });

  test(
    'Kategori olmayan vitrinde Luna taslağı kayıt API çağrısına ulaşır',
    () async {
      final editor = _EmptyCategoryEditor();
      Map<String, dynamic>? saved;
      final savedRequest = Completer<void>();
      final invoice = _invoice();
      final invoiceRow = (invoice['satirlar'] as List).single as Map;
      (invoiceRow['sahipDurumu'] as Map)['onayli'] = false;
      final controller = OcrController(
        editorController: editor,
        faturaOkuServisi: FaturaOkuServisi(
          originOverride: 'https://vixrex-test.local',
          httpClient: MockClient(
            (_) async => http.Response(
              jsonEncode(invoice),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            ),
          ),
        ),
        faturaIslemServisi: FaturaIslemServisi(
          originOverride: 'https://vixrex-test.local',
          httpClient: MockClient((request) async {
            final state = jsonDecode(request.body) as Map;
            final row = (state['satirlar'] as List).single as Map;
            expect((row['sahipDurumu'] as Map)['stok'], '2.5');
            return http.Response('{"tamam":true}', 200);
          }),
        ),
        faturaKaydiServisi: FaturaUrunKaydiServisi(
          originOverride: 'https://vixrex-test.local',
          httpClient: MockClient((request) async {
            saved = Map<String, dynamic>.from(
              (jsonDecode(request.body)['products'] as List).single as Map,
            );
            if (!savedRequest.isCompleted) savedRequest.complete();
            return http.Response(
              jsonEncode({
                'tamam': true,
                'taslak': 1,
                'satirlar': [
                  {'sira': 0, 'durum': 'taslak', 'id': 'product-1'},
                ],
              }),
              200,
            );
          }),
        ),
      );
      await controller.analyzeImage(Uint8List.fromList([1]));
      await savedRequest.future.timeout(const Duration(seconds: 2));
      await Future<void>.delayed(Duration.zero);
      expect(saved, isNotNull);
      expect(saved!['categoryId'], '');
      expect(saved!['stockQuantity'], isNull);
      expect(saved!['yayinIstegi'], isFalse);
      expect(controller.errorMessage, isNull);
      controller.dispose();
      editor.dispose();
    },
  );

  testWidgets(
    'Telefon kartında Luna kategori, özellik ve varyantları görünür',
    (tester) async {
      final result = const FaturaOkuServisi().cozumle(_invoice()).data!;
      final cardKey = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RepaintBoundary(
              key: cardKey,
              child: OcrResultList(
                products: result.products,
                invoiceDrafts: result.invoiceDrafts,
                onApprove: (_) {},
                onReject: (_) {},
              ),
            ),
          ),
        ),
      );
      expect(find.text('Şarküteri ve peynir'), findsOneWidget);
      expect(find.text('Ambalaj ağırlığı: 2,5 KG'), findsOneWidget);
      expect(find.text('Süt türü: Keçi'), findsOneWidget);
      expect(
        find.text(
          'peynir-keci · milk: Keçi · package: Teneke · Barkod: 8681234567890',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final boundary =
            cardKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '${Directory.systemTemp.path}/vixrex-luna-flutter-card.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    },
  );
}
